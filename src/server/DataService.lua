--[[
	DataService (ModuleScript)
	Location: ServerScriptService/HackerFight/Services/DataService

	Owns per-player saved settings and session stats.
	- Every value sent by a client is validated against Config.Settings.
	- DataStore failures never break gameplay: the player keeps in-memory
	  settings and is told that nothing could be saved.
--]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Config"))

local DataService = {}

local STORE_NAME = "HackerFightSettings_v1"
local SAVE_INTERVAL = 60
local store = nil
local apiAvailable = false
local profiles = {}

local function log(message)
	print("[HackerFight][Data] " .. tostring(message))
end

local function defaultSettings()
	local settings = {}
	for key, schema in pairs(Config.Settings) do
		settings[key] = schema.default
	end
	return settings
end

local function sanitize(key, value)
	local schema = Config.Settings[key]
	if not schema then
		return nil
	end
	if schema.type == "boolean" then
		if type(value) ~= "boolean" then
			return nil
		end
		return value
	elseif schema.type == "number" then
		if type(value) ~= "number" or value ~= value then
			return nil
		end
		return math.clamp(value, schema.min, schema.max)
	elseif schema.type == "string" then
		if type(value) ~= "string" then
			return nil
		end
		if schema.maxLength and #value > schema.maxLength then
			return nil
		end
		if schema.choices then
			local allowed = false
			for _, choice in ipairs(schema.choices) do
				if choice == value then
					allowed = true
				end
			end
			if not allowed then
				return nil
			end
		end
		return value
	end
	return nil
end

local function sanitizeAll(raw)
	local settings = defaultSettings()
	if type(raw) == "table" then
		for key, value in pairs(raw) do
			local clean = sanitize(key, value)
			if clean ~= nil then
				settings[key] = clean
			end
		end
	end
	return settings
end

local function loadProfile(player)
	local profile = {
		userId = player.UserId,
		settings = defaultSettings(),
		waypoints = {},
		dirty = false,
	}
	profiles[player] = profile
	if not store then
		return profile
	end
	local ok, result = pcall(function()
		return store:GetAsync("player_" .. tostring(player.UserId))
	end)
	if ok and type(result) == "table" then
		profile.settings = sanitizeAll(result)
		if type(result.waypoints) == "table" then
			for _, point in ipairs(result.waypoints) do
				if type(point) == "table" and tonumber(point.x) and tonumber(point.y) and tonumber(point.z) then
					profile.waypoints[#profile.waypoints + 1] = Vector3.new(point.x, point.y, point.z)
				end
			end
		end
	elseif not ok then
		log("GetAsync failed for " .. player.Name .. ": " .. tostring(result))
	end
	return profile
end

local function writeProfile(player)
	local profile = profiles[player]
	if not profile or not store or not apiAvailable then
		return false
	end
	local points = {}
	for _, point in ipairs(profile.waypoints) do
		points[#points + 1] = { x = point.X, y = point.Y, z = point.Z }
	end
	local payload = {
		settings = profile.settings,
		waypoints = points,
		version = Config.Version,
	}
	local ok, err = pcall(function()
		store:SetAsync("player_" .. tostring(player.UserId), payload)
	end)
	if not ok then
		log("SetAsync failed for " .. player.Name .. ": " .. tostring(err))
		return false
	end
	profile.dirty = false
	return true
end

function DataService.Start()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok and result then
		store = result
		apiAvailable = true
	else
		store = nil
		apiAvailable = false
		log("DataStore unavailable (enable Studio API access to save settings).")
	end

	local function onPlayerAdded(player)
		loadProfile(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		writeProfile(player)
		profiles[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(SAVE_INTERVAL)
			for player, profile in pairs(profiles) do
				if profile.dirty and player.Parent then
					writeProfile(player)
				end
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() then
			task.wait(0.2)
		end
		for player in pairs(profiles) do
			writeProfile(player)
		end
	end)
end

function DataService.Get(player)
	return profiles[player]
end

function DataService.GetSettings(player)
	local profile = profiles[player]
	if not profile then
		return defaultSettings()
	end
	return profile.settings
end

function DataService.SetSetting(player, key, value)
	local profile = profiles[player]
	if not profile then
		return false, "profile not loaded"
	end
	local clean = sanitize(key, value)
	if clean == nil then
		return false, "invalid value"
	end
	profile.settings[key] = clean
	profile.dirty = true
	return true, clean
end

function DataService.Reset(player)
	local profile = profiles[player]
	if not profile then
		return false
	end
	profile.settings = defaultSettings()
	profile.dirty = true
	writeProfile(player)
	return true
end

function DataService.Save(player)
	local profile = profiles[player]
	if not profile then
		return false
	end
	if not apiAvailable then
		return false, "studio API access is off"
	end
	return writeProfile(player)
end

function DataService.GetWaypoints(player)
	local profile = profiles[player]
	if not profile then
		return {}
	end
	return profile.waypoints
end

function DataService.AddWaypoint(player, position)
	local profile = profiles[player]
	if not profile or typeof(position) ~= "Vector3" then
		return false, "invalid position"
	end
	if #profile.waypoints >= Config.WaypointLimit then
		return false, "waypoint limit reached"
	end
	local bounds = Config.WorldBounds
	if position.X < bounds.Min.X or position.X > bounds.Max.X
		or position.Y < bounds.Min.Y or position.Y > bounds.Max.Y
		or position.Z < bounds.Min.Z or position.Z > bounds.Max.Z then
		return false, "outside the arena"
	end
	profile.waypoints[#profile.waypoints + 1] = position
	profile.dirty = true
	return true
end

function DataService.RemoveWaypoint(player, index)
	local profile = profiles[player]
	if not profile then
		return false
	end
	local position = tonumber(index)
	if not position or position < 1 or position > #profile.waypoints then
		return false
	end
	table.remove(profile.waypoints, position)
	profile.dirty = true
	return true
end

function DataService.IsPersistent()
	return apiAvailable
end

return DataService
