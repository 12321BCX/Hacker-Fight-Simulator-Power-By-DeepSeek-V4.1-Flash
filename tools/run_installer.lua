-- Dry-run the generated installer against the Roblox mock, verify the tree,
-- and dump every created script source so Python can diff it against src/.

dofile("tools/mock_roblox.lua")

local installerFile = assert(io.open("HackerFightInstaller.lua", "rb"))
local code = installerFile:read("*a")
installerFile:close()

local chunk, loadError = load(code, "HackerFightInstaller")
if not chunk then
	io.stderr:write("LOAD FAIL: " .. tostring(loadError) .. "\n")
	os.exit(1)
end

local ok, callError = pcall(chunk)
if not ok then
	io.stderr:write("RUN FAIL: " .. tostring(callError) .. "\n")
	os.exit(1)
end

local function services(name)
	return game:GetService(name)
end

local failures = {}
local checked = 0

local function child(parent, name)
	if not parent then
		return nil
	end
	for _, item in ipairs(parent:GetChildren()) do
		if rawget(item, "Name") == name then
			return item
		end
	end
	return nil
end

local function expect(parent, name, class, label)
	checked = checked + 1
	local found = child(parent, name)
	if not found then
		failures[#failures + 1] = "missing " .. label
		return nil
	end
	if class and rawget(found, "ClassName") ~= class then
		failures[#failures + 1] = label .. " is " .. tostring(rawget(found, "ClassName")) .. " not " .. class
	end
	return found
end

local replicated = services("ReplicatedStorage")
local serverScripts = services("ServerScriptService")
local starterPlayer = services("StarterPlayer")
local starterPlayerScripts = child(starterPlayer, "StarterPlayerScripts")
local starterGui = services("StarterGui")
local starterPack = services("StarterPack")
local workspaceService = services("Workspace")
local teams = services("Teams")

local shared = expect(replicated, "HackerFight", "Folder", "ReplicatedStorage.HackerFight")
for _, name in ipairs({ "Config", "Util", "Features", "Remotes" }) do
	expect(shared, name, "ModuleScript", "shared module " .. name)
end
local remotes = expect(shared, "Net", "Folder", "Net folder")
local eventNames = { "Attack", "Ability", "Teleport", "Settings", "State", "AbilityState", "Feedback", "KillFeed", "CombatFX" }
for _, name in ipairs(eventNames) do
	expect(remotes, name, "RemoteEvent", "RemoteEvent " .. name)
end
for _, name in ipairs({ "GetRoster", "GetSettings", "GetRound" }) do
	expect(remotes, name, "RemoteFunction", "RemoteFunction " .. name)
end

local server = expect(serverScripts, "HackerFight", "Folder", "ServerScriptService.HackerFight")
expect(server, "Main", "Script", "server Main")
local serverServices = expect(server, "Services", "Folder", "server Services")
for _, name in ipairs({ "DataService", "RoundService", "TeleportService", "AbilityService", "CombatService" }) do
	expect(serverServices, name, "ModuleScript", "server module " .. name)
end

local client = expect(starterPlayerScripts, "HackerFight", "Folder", "client folder")
expect(client, "Main", "LocalScript", "client Main")
local clientModules = expect(client, "Modules", "Folder", "client Modules")
for _, name in ipairs({ "Settings", "UI", "HUD", "Abilities", "Combat", "Visuals", "Teleport" }) do
	expect(clientModules, name, "ModuleScript", "client module " .. name)
end

local tool = expect(starterPack, "DataBlade", "Tool", "StarterPack.DataBlade")
expect(tool, "Handle", "Part", "DataBlade handle")

expect(teams, "Hackers", "Team", "Team Hackers")
expect(teams, "Daemons", "Team", "Team Daemons")

local arena = expect(workspaceService, "HackerFightArena", "Folder", "arena")
local spawns = expect(arena, "Spawns", "Folder", "arena spawns")
local spawnCount = spawns and #spawns:GetChildren() or 0
checked = checked + 1
if spawnCount ~= 6 then
	failures[#failures + 1] = "expected 6 spawns, found " .. tostring(spawnCount)
end
local arenaSpawns = expect(arena, "ArenaSpawns", "Folder", "arena spawns 2")
local arenaCount = arenaSpawns and #arenaSpawns:GetChildren() or 0
checked = checked + 1
if arenaCount ~= 4 then
	failures[#failures + 1] = "expected 4 arena spawns, found " .. tostring(arenaCount)
end
expect(arena, "Dummies", "Folder", "dummies folder")
expect(arena, "Floor", "Part", "arena floor")

local gui = expect(starterGui, "HackerFightUI", "ScreenGui", "ScreenGui")
expect(gui, "Window", "Frame", "GUI window")

----------------------------------------------------------------------
-- dump every script source
----------------------------------------------------------------------
local sourceCount = 0
local function dumpScripts()
	local folders = {
		{ shared, "shared" },
		{ server, "server" },
		{ serverServices, "server" },
		{ client, "client" },
		{ clientModules, "client" },
	}
	local written = {}
	for _, entry in ipairs(folders) do
		local parent = entry[1]
		for _, item in ipairs(parent:GetChildren()) do
			local class = rawget(item, "ClassName")
			if class == "ModuleScript" or class == "Script" or class == "LocalScript" then
				local name = rawget(item, "Name")
				local source = rawget(item, "Source")
				if source and #source > 100 then
					local key = entry[2] .. "/" .. name
					if not written[key] then
						written[key] = true
						sourceCount = sourceCount + 1
						local path = "tools/out/" .. string.gsub(key, "/", "_") .. ".lua"
						local file = assert(io.open(path, "wb"))
						file:write(source)
						file:close()
					end
				else
					failures[#failures + 1] = "empty source: " .. tostring(name)
				end
			end
		end
	end
	return written
end

local written = dumpScripts()

-- map dumped files back onto the expected source keys
local expected = {
	"shared/Config", "shared/Util", "shared/Features", "shared/Remotes",
	"server/DataService", "server/RoundService", "server/TeleportService",
	"server/AbilityService", "server/CombatService", "server/Main",
	"client/Settings", "client/UI", "client/HUD", "client/Abilities",
	"client/Combat", "client/Visuals", "client/Teleport", "client/Main",
}
for _, key in ipairs(expected) do
	checked = checked + 1
	if not written[key] then
		failures[#failures + 1] = "no source dumped for " .. key
	end
end

-- duplicate sibling names would break WaitForChild lookups
local function checkDuplicates(parent, label)
	local seen = {}
	for _, item in ipairs(parent:GetChildren()) do
		local name = rawget(item, "Name")
		checked = checked + 1
		if seen[name] then
			failures[#failures + 1] = "duplicate child name in " .. label .. ": " .. tostring(name)
		end
		seen[name] = true
	end
end

for _, entry in ipairs({
	{ shared, "ReplicatedStorage.HackerFight" },
	{ server, "ServerScriptService.HackerFight" },
	{ client, "StarterPlayerScripts.HackerFight" },
	{ arena, "Workspace.HackerFightArena" },
	{ gui, "StarterGui.HackerFightUI" },
}) do
	if entry[1] then
		checkDuplicates(entry[1], entry[2])
	end
end

print(string.format("checked %d expectations, dumped %d script sources", checked, sourceCount))
if #failures > 0 then
	for _, failure in ipairs(failures) do
		print("CHECK FAIL: " .. failure)
	end
	os.exit(1)
end
print("installer dry-run: OK")
