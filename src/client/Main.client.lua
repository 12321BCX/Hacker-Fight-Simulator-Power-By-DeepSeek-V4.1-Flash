--[[
	Main (LocalScript)
	Location: StarterPlayer/StarterPlayerScripts/HackerFight/Main

	Loads the client modules in a safe order and routes every UI feature to the
	module that implements it. No feature exists only in the UI: every control
	has a handler here.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local root = ReplicatedStorage:WaitForChild("HackerFight", 30)
if not root then
	warn("[HackerFight] ReplicatedStorage.HackerFight missing - run the installer.")
	return
end

local Config = require(root:WaitForChild("Config"))
local Features = require(root:WaitForChild("Features"))
local Remotes = require(root:WaitForChild("Remotes"))
local Util = require(root:WaitForChild("Util"))

local moduleFolder = script.Parent:WaitForChild("Modules")
local Settings = require(moduleFolder:WaitForChild("Settings"))
local UI = require(moduleFolder:WaitForChild("UI"))
local HUD = require(moduleFolder:WaitForChild("HUD"))
local Abilities = require(moduleFolder:WaitForChild("Abilities"))
local Combat = require(moduleFolder:WaitForChild("Combat"))
local Visuals = require(moduleFolder:WaitForChild("Visuals"))
local Teleport = require(moduleFolder:WaitForChild("Teleport"))

local ctx = {
	player = player,
	config = Config,
	features = Features,
	remotes = Remotes,
	util = Util,
	modules = {
		Settings = Settings,
		UI = UI,
		HUD = HUD,
		Abilities = Abilities,
		Combat = Combat,
		Visuals = Visuals,
		Teleport = Teleport,
	},
}

function ctx.notify(message, kind)
	UI.notify(message, kind)
end

local handlers = {}

local function merge(moduleHandlers)
	for id, handler in pairs(moduleHandlers or {}) do
		handlers[id] = handler
	end
end

merge(Abilities.handlers)
merge(Combat.handlers)
merge(Visuals.handlers)
merge(Teleport.handlers)

-- settings-only toggles ------------------------------------------------
handlers.sounds = function(value)
	Settings.apply("sounds", value, true)
end

handlers.killfeed = function(value)
	Settings.apply("killfeed", value, true)
end

handlers.safetp = function(value)
	Settings.apply("safetp", value, true)
end

handlers.theme = function(value)
	Settings.apply("theme", value, true)
	UI.applyTheme(value)
end

handlers.uiscale = function(value)
	Settings.apply("uiscale", value, true)
	UI.setScale(value)
end

handlers.keybind = function(value)
	Settings.apply("keybind", value, true)
	UI.widgets["keybind"]:set(value)
	UI.notify("GUI toggle key: " .. tostring(value), "success")
end

handlers.save_settings = function()
	Settings.save()
end

local lastReset = 0

handlers.reset_settings = function()
	if os.clock() - lastReset > 4 then
		lastReset = os.clock()
		UI.notify("Click RESET ALL again within 4s to confirm", "warn")
		return
	end
	lastReset = 0
	Settings.resetAll()
	for id, row in pairs(Features.byId) do
		if row.kind == "toggle" then
			UI.setToggle(id, Settings.get(id) == true)
		elseif row.kind == "slider" then
			UI.setSlider(id, Settings.get(id))
		elseif row.kind == "cycle" and UI.widgets[id] then
			UI.widgets[id].set(Settings.get(id))
		end
	end
	UI.applyTheme(Settings.get("theme"))
	UI.setScale(Settings.get("uiscale"))
	UI.notify("All settings reset", "success")
end

local lastStatReset = 0

handlers.reset_stats = function()
	if os.clock() - lastStatReset > 4 then
		lastStatReset = os.clock()
		UI.notify("Click again within 4s to reset your session stats", "warn")
		return
	end
	lastStatReset = 0
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("resetstats")
	end
	UI.notify("Session stats reset", "success")
end

function ctx.dispatch(id, value)
	local handler = handlers[id]
	if handler then
		local ok, err = pcall(handler, value)
		if not ok then
			warn("[HackerFight][Dispatch:" .. tostring(id) .. "] " .. tostring(err))
			UI.notify("Action failed: " .. tostring(id), "warn")
		end
	end
end

----------------------------------------------------------------------
-- boot
----------------------------------------------------------------------
Settings.Init(ctx)
UI.Init(ctx)
HUD.Init(ctx)
Abilities.Init(ctx)
Combat.Init(ctx)
Visuals.Init(ctx)
Teleport.Init(ctx)

ctx.hud = HUD
ctx.ui = UI

-- mirror saved values into the freshly built widgets
for id, row in pairs(Features.byId) do
	if row.kind == "toggle" then
		UI.setToggle(id, Settings.get(id) == true)
	elseif row.kind == "slider" then
		UI.setSlider(id, Settings.get(id))
	elseif row.kind == "cycle" and UI.widgets[id] then
		UI.widgets[id].set(Settings.get(id))
	end
end

Settings.onChanged = function(key, value)
	if UI.silent then
		return
	end
	if key == "theme" then
		UI.applyTheme(value)
	elseif key == "uiscale" then
		UI.setScale(value)
	end
	local row = Features.byId[key]
	if not row then
		return
	end
	if row.kind == "toggle" then
		UI.setToggle(key, value == true)
	elseif row.kind == "slider" then
		UI.setSlider(key, value)
	elseif row.kind == "cycle" and UI.widgets[key] then
		UI.widgets[key].set(value)
	elseif row.kind == "keybind" and UI.widgets[key] then
		UI.widgets[key].set(value)
	end
end

----------------------------------------------------------------------
-- server feedback
----------------------------------------------------------------------
local feedback = Remotes.event("Feedback")
if feedback then
	feedback.OnClientEvent:Connect(function(message, kind)
		if kind == "combat" then
			HUD.notifyCombat(message)
		else
			UI.notify(message, kind)
			if kind == "round" or kind == "success" then
				HUD.notifyCombat("[ " .. tostring(message) .. " ]")
			end
		end
	end)
end

local stateRemote = Remotes.event("State")
if stateRemote then
	stateRemote.OnClientEvent:Connect(function(state)
		HUD.setRound(state)
		if type(state) == "table" then
			ctx.roundState = state
			UI.setInfo(
				"round_info",
				string.format("%s | %s | %s", tostring(state.modeName), tostring(state.phase), Util.formatTime(state.timeLeft or 0)),
				"accent"
			)
		end
	end)
end

----------------------------------------------------------------------
-- roster / stats refresh
----------------------------------------------------------------------
local getRoster = Remotes.func("GetRoster")
task.spawn(function()
	while true do
		task.wait(2.5)
		if getRoster then
			local ok, roster = pcall(function()
				return getRoster:InvokeServer()
			end)
			if ok and type(roster) == "table" then
				UI.setPlayerList("roster", roster, function(item)
					Combat.setTarget(item.name)
				end)
				UI.setPlayerList("tp_playerlist", roster, function(item)
					Teleport.toPlayer(item.name)
				end)
				for _, entry in ipairs(roster) do
					if entry.name == player.Name then
						UI.setStats(entry.kills, entry.deaths, entry.score)
						HUD.setStats(entry.kills, entry.deaths, entry.score)
						UI.setInfo("team_info", entry.team or "FFA", entry.team == "FFA" and "accent" or "success")
					end
				end
			end
		end
	end
end)

----------------------------------------------------------------------
-- waypoint / history list refresh when settings change
----------------------------------------------------------------------
local originalWaypoints = Settings.onWaypoints
Settings.onWaypoints = function(points, ok, err)
	if originalWaypoints then
		originalWaypoints(points, ok, err)
	end
	if Teleport.refreshLists then
		Teleport.refreshLists()
	end
end

task.spawn(function()
	task.wait(1)
	if Teleport.refreshLists then
		Teleport.refreshLists()
	end
end)

UI.notify("Hacker Fight ready - press " .. tostring(Settings.get("keybind")), "success")

print(string.format("[HackerFight] Client ready v%s", Config.Version))
