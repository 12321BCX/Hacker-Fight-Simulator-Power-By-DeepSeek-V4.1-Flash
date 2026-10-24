--[[
	Main (Script)
	Location: ServerScriptService/HackerFight/Main

	Boots every server service, then answers the three RemoteFunctions and the
	settings RemoteEvent. Order matters: data -> rounds -> abilities ->
	teleport -> combat.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:WaitForChild("HackerFight", 30)
if not root then
	warn("[HackerFight] ReplicatedStorage.HackerFight is missing. Run the installer again.")
	return
end

local Config = require(root:WaitForChild("Config"))
local Remotes = require(root:WaitForChild("Remotes"))

local servicesFolder = script.Parent:WaitForChild("Services")
local DataService = require(servicesFolder:WaitForChild("DataService"))
local RoundService = require(servicesFolder:WaitForChild("RoundService"))
local AbilityService = require(servicesFolder:WaitForChild("AbilityService"))
local TeleportService = require(servicesFolder:WaitForChild("TeleportService"))
local CombatService = require(servicesFolder:WaitForChild("CombatService"))

local missing = {}
for _, name in ipairs(Config.Remotes.Events) do
	if not Remotes.event(name) then
		missing[#missing + 1] = name
	end
end
for _, name in ipairs(Config.Remotes.Functions) do
	if not Remotes.func(name) then
		missing[#missing + 1] = name
	end
end
if #missing > 0 then
	warn("[HackerFight] Missing remotes: " .. table.concat(missing, ", ") .. " - run the installer again.")
end

DataService.Start()
RoundService.Start()
AbilityService.Start()
TeleportService.Start()
CombatService.Start()

-- RemoteFunctions -------------------------------------------------------
local getRoster = Remotes.func("GetRoster")
if getRoster then
	getRoster.OnServerInvoke = function(player)
		if not player or not player.Parent then
			return {}
		end
		return RoundService.GetRoster()
	end
end

local getSettings = Remotes.func("GetSettings")
if getSettings then
	getSettings.OnServerInvoke = function(player)
		return {
			settings = DataService.GetSettings(player),
			waypoints = DataService.GetWaypoints(player),
			persistent = DataService.IsPersistent(),
		}
	end
end

local getRound = Remotes.func("GetRound")
if getRound then
	getRound.OnServerInvoke = function()
		local mode = RoundService.GetMode()
		return {
			phase = RoundService.GetPhase(),
			modeName = mode and mode.name or "Free-for-All",
			modeId = mode and mode.id or "ffa",
			roundNumber = RoundService.RoundNumber,
			scoreToWin = Config.ScoreToWin,
		}
	end
end

-- Settings RemoteEvent ------------------------------------------------
local settingsRemote = Remotes.event("Settings")
if settingsRemote then
	settingsRemote.OnServerEvent:Connect(function(player, action, key, value)
		if type(action) ~= "string" then
			return
		end
		if action == "set" then
			local ok, result = DataService.SetSetting(player, key, value)
			if not ok then
				settingsRemote:FireClient(player, "rejected", key, value)
			end
		elseif action == "save" then
			local ok, err = DataService.Save(player)
			settingsRemote:FireClient(player, "saved", ok, err)
		elseif action == "reset" then
			DataService.Reset(player)
			settingsRemote:FireClient(player, "sync", DataService.GetSettings(player))
			AbilityService.ApplyMovement(player)
		elseif action == "wp_add" then
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if not rootPart then
				return
			end
			local ok, err = DataService.AddWaypoint(player, rootPart.Position)
			settingsRemote:FireClient(player, "waypoints", DataService.GetWaypoints(player), ok, err)
		elseif action == "wp_del" then
			DataService.RemoveWaypoint(player, key)
			settingsRemote:FireClient(player, "waypoints", DataService.GetWaypoints(player))
		elseif action == "resetstats" then
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				for _, name in ipairs({ "Kills", "Deaths", "Score" }) do
					local value = stats:FindFirstChild(name)
					if value then
						value.Value = 0
					end
				end
			end
			RoundService.BroadcastState()
		end
	end)
end

print("[HackerFight] Server ready - v" .. Config.Version)
