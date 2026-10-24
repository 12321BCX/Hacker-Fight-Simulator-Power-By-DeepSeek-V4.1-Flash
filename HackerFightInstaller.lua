--[[
	HACKER FIGHT SIMULATOR - one-paste installer
	=============================================
	HOW TO USE (Roblox Studio):
	  1. Open your place, stay in EDIT mode (do not press Play).
	  2. Open the Command Bar: View tab -> Command Bar.
	  3. Click inside it and paste this ENTIRE file (it is ~190 KB).
	  4. Press Enter. If Enter only adds a new line, click the Execute /
	     Run button on the right side of the command bar instead. You can
	     also enable Studio Settings -> Studio -> Command Bar ->
	     "Execute command with Return".
	  5. Wait for "[HackerFight Installer] SUCCESS" in the Output window.

	Everything is created for you: folders, ModuleScripts, server scripts,
	LocalScripts, RemoteEvents, RemoteFunctions, the arena, teams, the weapon
	and the GUI. Re-running is safe: the old install is replaced.

	The installer itself is not part of the game. Nothing here needs editing.
--]]

local SOURCES = {
	["shared/Config"] = [===[
--[[
	Config (ModuleScript)
	Location: ReplicatedStorage/HackerFight/Config

	Every balance number, cooldown, limit and theme lives here so the whole
	project can be re-balanced from one file. The SERVER is the only side that
	enforces these numbers; the client only reads them to draw the UI.
--]]

local Config = {}

Config.Version = "1.0.0"
Config.GameName = "HACKER FIGHT SIMULATOR"

----------------------------------------------------------------------
-- COMBAT
----------------------------------------------------------------------
Config.BaseDamage = 12
Config.AttackCooldown = 0.45 -- seconds between accepted attacks (server enforced)
Config.MinReach = 5
Config.MaxReach = 20
Config.DefaultReach = 9
Config.MinDamageMultiplier = 1
Config.MaxDamageMultiplier = 1.5
Config.KillAuraInterval = 0.45
Config.TargetLockRange = 250

----------------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------------
Config.MinWalkSpeed = 16
Config.MaxWalkSpeed = 80
Config.MinJumpPower = 50
Config.MaxJumpPower = 200
Config.FlySpeedMin = 20
Config.FlySpeedMax = 90
Config.FlySpeedDefault = 55
Config.DashDistance = 24
Config.DashCooldown = 3
Config.TpWalkMaxStep = 14
Config.TpWalkClientDelay = 0.3
Config.NoclipMaxDuration = 30
Config.JumpRequestRateLimit = 6 -- max jump requests per second before cooldown

----------------------------------------------------------------------
-- TELEPORT
----------------------------------------------------------------------
Config.TeleportCooldown = 4
Config.MaxTeleportDistance = 900
Config.WaypointLimit = 5
Config.WorldBounds = {
	Min = Vector3.new(-400, -50, -400),
	Max = Vector3.new(400, 400, 400),
}

----------------------------------------------------------------------
-- ABILITIES (server enforced)
----------------------------------------------------------------------
Config.Abilities = {
	fly = { Cooldown = 6 },
	godmode = { Cooldown = 30, Duration = 5 },
	shield = { Cooldown = 25, Duration = 8, Absorb = 60 },
	invis = { Cooldown = 30, Duration = 6 },
	heal = { Cooldown = 15, Amount = 35 },
	antiknock = { Cooldown = 20, Duration = 6 },
	escape = { Cooldown = 20 },
	dash = { Cooldown = 3 },
}

Config.Modes = {
	{ id = "ffa", name = "Free-for-All", teamBased = false, duration = 150, arena = false, abilityOnly = false, training = false },
	{ id = "tdm", name = "Team Deathmatch", teamBased = true, duration = 180, arena = false, abilityOnly = false, training = false },
	{ id = "arena", name = "Hacker Battle Arena", teamBased = false, duration = 120, arena = true, abilityOnly = false, training = false },
	{ id = "ability", name = "Ability-Only Combat", teamBased = true, duration = 150, arena = false, abilityOnly = true, training = false },
	{ id = "training", name = "Training Grounds", teamBased = false, duration = 300, arena = false, abilityOnly = false, training = true },
}

Config.IntermissionTime = 10
Config.SpawnProtection = 4
Config.PostRoundTime = 6
Config.ScoreToWin = 25

----------------------------------------------------------------------
-- SETTINGS SCHEMA
-- The server validates every incoming setting against this table. Unknown
-- keys, wrong types and out-of-range numbers are rejected.
----------------------------------------------------------------------
Config.Settings = {
	-- combat
	killaura = { type = "boolean", default = false },
	autoattack = { type = "boolean", default = false },
	aimbot = { type = "boolean", default = false },
	combatenabled = { type = "boolean", default = true },
	reach = { type = "number", default = 9, min = 5, max = 20 },
	dmgmult = { type = "number", default = 1, min = 1, max = 1.5 },
	-- movement
	fly = { type = "boolean", default = false },
	flyspeed = { type = "number", default = 55, min = 20, max = 90 },
	tpwalk = { type = "boolean", default = false },
	speed = { type = "number", default = 16, min = 16, max = 80 },
	jump = { type = "number", default = 50, min = 50, max = 200 },
	infjump = { type = "boolean", default = false },
	doublejump = { type = "boolean", default = false },
	noclip = { type = "boolean", default = false },
	-- visuals
	esp_player = { type = "boolean", default = true },
	esp_name = { type = "boolean", default = true },
	esp_dist = { type = "boolean", default = true },
	esp_health = { type = "boolean", default = true },
	esp_box = { type = "boolean", default = false },
	esp_skeleton = { type = "boolean", default = false },
	esp_tracer = { type = "boolean", default = false },
	loscheck = { type = "boolean", default = false },
	teamfilter = { type = "string", default = "everyone", choices = { "everyone", "enemies", "allies" } },
	colorpreset = { type = "number", default = 1, min = 1, max = 4 },
	crosshair = { type = "boolean", default = true },
	-- teleport / misc
	safetp = { type = "boolean", default = true },
	sounds = { type = "boolean", default = true },
	killfeed = { type = "boolean", default = true },
	performance = { type = "boolean", default = false },
	keybind = { type = "string", default = "RightShift", maxLength = 32 },
	theme = { type = "string", default = "matrix", choices = { "matrix", "cyan", "purple", "blood" } },
	uiscale = { type = "number", default = 1, min = 0.7, max = 1.3 },
}

----------------------------------------------------------------------
-- THEMES
----------------------------------------------------------------------
Config.Themes = {
	matrix = {
		name = "Matrix",
		bg = Color3.fromRGB(8, 10, 9),
		panel = Color3.fromRGB(16, 20, 18),
		panelAlt = Color3.fromRGB(22, 28, 25),
		border = Color3.fromRGB(45, 70, 55),
		accent = Color3.fromRGB(0, 255, 140),
		accent2 = Color3.fromRGB(0, 200, 255),
		accent3 = Color3.fromRGB(170, 0, 255),
		text = Color3.fromRGB(225, 255, 240),
		dim = Color3.fromRGB(110, 140, 125),
		danger = Color3.fromRGB(255, 70, 90),
	},
	cyan = {
		name = "Cyan Ice",
		bg = Color3.fromRGB(6, 10, 14),
		panel = Color3.fromRGB(14, 22, 30),
		panelAlt = Color3.fromRGB(20, 32, 43),
		border = Color3.fromRGB(38, 70, 92),
		accent = Color3.fromRGB(0, 220, 255),
		accent2 = Color3.fromRGB(0, 255, 200),
		accent3 = Color3.fromRGB(120, 120, 255),
		text = Color3.fromRGB(225, 245, 255),
		dim = Color3.fromRGB(110, 140, 165),
		danger = Color3.fromRGB(255, 80, 80),
	},
	purple = {
		name = "Violet Grid",
		bg = Color3.fromRGB(11, 8, 16),
		panel = Color3.fromRGB(22, 16, 32),
		panelAlt = Color3.fromRGB(30, 22, 44),
		border = Color3.fromRGB(70, 45, 105),
		accent = Color3.fromRGB(180, 90, 255),
		accent2 = Color3.fromRGB(0, 230, 255),
		accent3 = Color3.fromRGB(255, 90, 200),
		text = Color3.fromRGB(240, 230, 255),
		dim = Color3.fromRGB(150, 130, 175),
		danger = Color3.fromRGB(255, 70, 110),
	},
	blood = {
		name = "Redline",
		bg = Color3.fromRGB(10, 6, 6),
		panel = Color3.fromRGB(22, 12, 12),
		panelAlt = Color3.fromRGB(32, 16, 16),
		border = Color3.fromRGB(90, 40, 40),
		accent = Color3.fromRGB(255, 60, 60),
		accent2 = Color3.fromRGB(255, 170, 0),
		accent3 = Color3.fromRGB(200, 0, 255),
		text = Color3.fromRGB(255, 235, 235),
		dim = Color3.fromRGB(170, 120, 120),
		danger = Color3.fromRGB(255, 0, 40),
	},
}

----------------------------------------------------------------------
-- REMOTE NAMES (installer creates these exact instances)
----------------------------------------------------------------------
Config.Remotes = {
	Events = {
		"Attack",
		"Ability",
		"Teleport",
		"Settings",
		"State",
		"AbilityState",
		"Feedback",
		"KillFeed",
		"CombatFX",
	},
	Functions = {
		"GetRoster",
		"GetSettings",
		"GetRound",
	},
}

return Config
]===],
	["shared/Util"] = [===[
--[[
	Util (ModuleScript)
	Location: ReplicatedStorage/HackerFight/Util

	Small shared helpers used by both the server and the client.
--]]

local Util = {}

function Util.clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	elseif value > maxValue then
		return maxValue
	end
	return value
end

function Util.round(value, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

function Util.deepCopy(source)
	local copy = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			copy[key] = Util.deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

function Util.formatTime(seconds)
	local total = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", math.floor(total / 60), total % 60)
end

function Util.isAlive(player)
	local character = player and player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	return character:FindFirstChild("HumanoidRootPart") ~= nil
end

function Util.getRoot(player)
	local character = player and player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

function Util.getHumanoid(player)
	local character = player and player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

-- Returns every BasePart that belongs to a character (handles accessories).
function Util.getCharacterParts(character)
	local parts = {}
	if not character then
		return parts
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			parts[#parts + 1] = descendant
		end
	end
	return parts
end

function Util.findPlayerByName(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local lower = string.lower(name)
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if string.lower(player.Name) == lower or string.lower(player.DisplayName) == lower then
			return player
		end
	end
	return nil
end

function Util.distance(a, b)
	return (a - b).Magnitude
end

-- A safe wrapper so one failing tween / raycast never kills an ability loop.
function Util.try(fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok then
		return nil, tostring(result)
	end
	return result
end

return Util
]===],
	["shared/Features"] = [===[
--[[
	Features (ModuleScript)
	Location: ReplicatedStorage/HackerFight/Features

	Single source of truth for the GUI: tab order and every row. The client
	builder reads this table and creates real, working widgets, so adding a
	feature here automatically creates its UI. The server still decides whether
	each requested action is allowed.
--]]

local Features = {}

Features.Tabs = {
	{ id = "player", label = "PLAYER", glyph = "P" },
	{ id = "combat", label = "COMBAT", glyph = "C" },
	{ id = "movement", label = "MOVE", glyph = "M" },
	{ id = "teleport", label = "TELEPORT", glyph = "T" },
	{ id = "visuals", label = "VISUALS", glyph = "V" },
	{ id = "defense", label = "DEFENSE", glyph = "D" },
	{ id = "misc", label = "MISC", glyph = "X" },
	{ id = "settings", label = "CONFIG", glyph = "S" },
}

-- kind: header | toggle | slider | button | cycle | keybind | playerlist |
--       waypoints | history | info | stats
Features.Rows = {
	---------------- PLAYER ----------------
	{ tab = "player", kind = "header", label = "YOUR AGENT" },
	{ tab = "player", kind = "stats", id = "stats_your", label = "Kills / Deaths / Score" },
	{ tab = "player", kind = "header", label = "LOBBY ROSTER" },
	{ tab = "player", kind = "playerlist", id = "roster", label = "Players (tap to target)" },
	{ tab = "player", kind = "info", id = "team_info", label = "Team", text = "No team" },

	---------------- COMBAT ----------------
	{ tab = "combat", kind = "header", label = "MASTER SWITCH" },
	{ id = "combatenabled", tab = "combat", kind = "toggle", label = "Combat Abilities", hint = "Turns every offensive feature on or off at once" },
	{ tab = "combat", kind = "header", label = "OFFENSIVE" },
	{ id = "killaura", tab = "combat", kind = "toggle", label = "Kill Aura", hint = "Auto attacks the closest enemy inside Reach" },
	{ id = "autoattack", tab = "combat", kind = "toggle", label = "Auto Attack", hint = "Attacks automatically when a target is in range" },
	{ id = "aimbot", tab = "combat", kind = "toggle", label = "Target Lock", hint = "Locks your camera on the selected / nearest enemy" },
	{ tab = "combat", kind = "header", label = "TUNING" },
	{ id = "reach", tab = "combat", kind = "slider", label = "Reach", min = 5, max = 20, step = 1, suffix = " studs" },
	{ id = "dmgmult", tab = "combat", kind = "slider", label = "Damage Multiplier", min = 1, max = 1.5, step = 0.05, suffix = "x" },
	{ tab = "combat", kind = "info", id = "combat_status", label = "Status", text = "Idle" },

	---------------- MOVEMENT ----------------
	{ tab = "movement", kind = "header", label = "FLIGHT" },
	{ id = "fly", tab = "movement", kind = "toggle", label = "Fly", hint = "Server grants a flight window; move with WASD + Space / Ctrl" },
	{ id = "flyspeed", tab = "movement", kind = "slider", label = "Flight Speed", min = 20, max = 90, step = 1, suffix = " studs/s" },
	{ tab = "movement", kind = "header", label = "GROUND" },
	{ id = "speed", tab = "movement", kind = "slider", label = "Walk Speed", min = 16, max = 80, step = 1, suffix = " studs/s" },
	{ id = "jump", tab = "movement", kind = "slider", label = "Jump Power", min = 50, max = 200, step = 5, suffix = "" },
	{ id = "infjump", tab = "movement", kind = "toggle", label = "Infinite Jump", hint = "Jump again at any time while airborne" },
	{ id = "doublejump", tab = "movement", kind = "toggle", label = "Double Jump", hint = "One extra jump while airborne" },
	{ id = "tpwalk", tab = "movement", kind = "toggle", label = "TP Walk", hint = "Short server validated blinks while moving" },
	{ id = "noclip", tab = "movement", kind = "toggle", label = "Noclip", hint = "Server clears collisions on your character" },
	{ tab = "movement", kind = "header", label = "BURST" },
	{ tab = "movement", kind = "button", id = "dash", label = "Dash Forward", cooldown = "dash" },

	---------------- TELEPORT ----------------
	{ tab = "teleport", kind = "header", label = "TARGET" },
	{ tab = "teleport", kind = "playerlist", id = "tp_playerlist", label = "Teleport to player" },
	{ tab = "teleport", kind = "button", id = "tp_spawn", label = "Teleport to Spawn" },
	{ tab = "teleport", kind = "header", label = "WAYPOINTS" },
	{ tab = "teleport", kind = "button", id = "wp_save", label = "Save Current Position" },
	{ tab = "teleport", kind = "waypoints", id = "waypointlist", label = "Saved Waypoints" },
	{ tab = "teleport", kind = "history", id = "historylist", label = "Teleport History" },
	{ tab = "teleport", kind = "header", label = "OPTIONS" },
	{ id = "safetp", tab = "teleport", kind = "toggle", label = "Safe Teleport", hint = "Server raycasts the destination before moving you" },
	{ tab = "teleport", kind = "info", id = "tp_cooldown", label = "Cooldown", text = "Ready" },

	---------------- VISUALS ----------------
	{ tab = "visuals", kind = "header", label = "PLAYER ESP" },
	{ id = "esp_player", tab = "visuals", kind = "toggle", label = "Player ESP", hint = "Neon highlight on every valid target" },
	{ id = "esp_box", tab = "visuals", kind = "toggle", label = "Box ESP", hint = "Outline box around characters" },
	{ id = "esp_name", tab = "visuals", kind = "toggle", label = "Name ESP", hint = "Name tag above the character" },
	{ id = "esp_dist", tab = "visuals", kind = "toggle", label = "Distance ESP", hint = "Studs between you and the target" },
	{ id = "esp_health", tab = "visuals", kind = "toggle", label = "Health ESP", hint = "Health bar above the character" },
	{ tab = "visuals", kind = "header", label = "OVERLAYS" },
	{ id = "esp_skeleton", tab = "visuals", kind = "toggle", label = "Skeleton ESP", hint = "Simplified bone lines" },
	{ id = "esp_tracer", tab = "visuals", kind = "toggle", label = "Tracer ESP", hint = "Line from screen bottom to each target" },
	{ id = "loscheck", tab = "visuals", kind = "toggle", label = "Visibility Check", hint = "Hide targets behind walls" },
	{ id = "crosshair", tab = "visuals", kind = "toggle", label = "Custom Crosshair", hint = "Neon crosshair + target readout" },
	{ tab = "visuals", kind = "header", label = "FILTER + COLOR" },
	{ id = "teamfilter", tab = "visuals", kind = "cycle", label = "Team Filter", options = { "everyone", "enemies", "allies" } },
	{ id = "colorpreset", tab = "visuals", kind = "cycle", label = "Color Preset", options = { "1", "2", "3", "4" } },
	{ id = "performance", tab = "visuals", kind = "toggle", label = "Performance Mode", hint = "Slower ESP updates for low end devices" },

	---------------- DEFENSE ----------------
	{ tab = "defense", kind = "header", label = "SERVER GRANTED ABILITIES" },
	{ tab = "defense", kind = "button", id = "godmode", label = "God Mode (5s)", cooldown = "godmode" },
	{ tab = "defense", kind = "button", id = "shield", label = "Shield (8s)", cooldown = "shield" },
	{ tab = "defense", kind = "button", id = "heal", label = "Heal +35 HP", cooldown = "heal" },
	{ tab = "defense", kind = "button", id = "invis", label = "Invisibility (6s)", cooldown = "invis" },
	{ tab = "defense", kind = "button", id = "antiknock", label = "Anti Knockback (6s)", cooldown = "antiknock" },
	{ tab = "defense", kind = "button", id = "escape", label = "Emergency Escape", cooldown = "escape" },
	{ tab = "defense", kind = "info", id = "defense_status", label = "Active", text = "None" },

	---------------- MISC ----------------
	{ tab = "misc", kind = "header", label = "INTERFACE" },
	{ id = "sounds", tab = "misc", kind = "toggle", label = "UI Sounds", hint = "Clicks and notifications" },
	{ id = "killfeed", tab = "misc", kind = "toggle", label = "Kill Feed", hint = "Show eliminations on screen" },
	{ tab = "misc", kind = "button", id = "reset_stats", label = "Reset My Session Stats" },
	{ tab = "misc", kind = "info", id = "round_info", label = "Match", text = "..." },

	---------------- SETTINGS ----------------
	{ tab = "settings", kind = "header", label = "CONTROLS" },
	{ tab = "settings", kind = "keybind", id = "keybind", label = "GUI Toggle Key" },
	{ tab = "settings", kind = "header", label = "APPEARANCE" },
	{ id = "theme", tab = "settings", kind = "cycle", label = "Theme", options = { "matrix", "cyan", "purple", "blood" } },
	{ id = "uiscale", tab = "settings", kind = "slider", label = "UI Scale", min = 0.7, max = 1.3, step = 0.05, suffix = "x" },
	{ tab = "settings", kind = "header", label = "DATA" },
	{ tab = "settings", kind = "button", id = "save_settings", label = "Save Settings" },
	{ tab = "settings", kind = "button", id = "reset_settings", label = "Reset All Settings" },
	{ tab = "settings", kind = "info", id = "data_status", label = "Storage", text = "Loading..." },
}

Features.byId = {}
for _, row in ipairs(Features.Rows) do
	if row.id then
		Features.byId[row.id] = row
	end
end

return Features
]===],
	["shared/Remotes"] = [===[
--[[
	Remotes (ModuleScript)
	Location: ReplicatedStorage/HackerFight/Remotes

	Every RemoteEvent / RemoteFunction is created by the installer. This module
	only keeps the lookup in one place so a missing instance produces a clear
	error instead of a random nil index.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local root = ReplicatedStorage:WaitForChild("HackerFight", 20)
local folder = root and root:WaitForChild("Net", 20)

local function get(name)
	local instance = folder and folder:FindFirstChild(name)
	if not instance then
		warn("[HackerFight] Missing remote: " .. tostring(name) .. ". Run the installer again.")
	end
	return instance
end

function Remotes.event(name)
	return get(name)
end

function Remotes.func(name)
	return get(name)
end

return Remotes
]===],
	["server/DataService"] = [===[
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
]===],
	["server/RoundService"] = [===[
--[[
	RoundService (ModuleScript)
	Location: ServerScriptService/HackerFight/Services/RoundService

	Match flow: Intermission -> Active round -> Post round -> next mode.
	Also owns: teams, leaderstats, spawn protection, scores, kill feed and the
	training dummies. Everything a client can see about the match comes from
	the State remote, never from a client claim.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Config"))
local Util = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Util"))
local Remotes = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Remotes"))

local RoundService = {}

RoundService.RoundNumber = 0
RoundService.Phase = "Intermission"
RoundService.Mode = Config.Modes[1]

local protectedUntil = {}
local roundScores = {}
local roundEndsAt = 0
local winnerAnnounced = false
local dummiesFolder = nil

local function now()
	return os.clock()
end

local function arena()
	return workspace:FindFirstChild("HackerFightArena")
end

local function feedbackToAll(message, kind)
	local remote = Remotes.event("Feedback")
	if remote then
		remote:FireAllClients(message, kind or "info")
	end
end

local function getSpawns(useArena)
	local folder = nil
	local root = arena()
	if root then
		if useArena then
			folder = root:FindFirstChild("ArenaSpawns") or root:FindFirstChild("Spawns")
		else
			folder = root:FindFirstChild("Spawns")
		end
	end
	local points = {}
	if folder then
		for _, pad in ipairs(folder:GetChildren()) do
			if pad:IsA("BasePart") then
				points[#points + 1] = pad.Position + Vector3.new(0, 4, 0)
			end
		end
	end
	if #points == 0 then
		points[1] = Vector3.new(0, 8, 0)
	end
	return points
end

local function teamNameOf(player)
	if player.Team then
		return player.Team.Name
	end
	return "FFA"
end

function RoundService.GetTeamName(player)
	return teamNameOf(player)
end

function RoundService.GetMode()
	return RoundService.Mode
end

function RoundService.GetPhase()
	return RoundService.Phase
end

function RoundService.IsCombatEnabled()
	return RoundService.Phase == "Active"
end

function RoundService.IsProtected(player)
	local untilTime = protectedUntil[player]
	return untilTime ~= nil and now() < untilTime
end

function RoundService.Protect(player, seconds)
	if not player or not player.Parent then
		return
	end
	protectedUntil[player] = now() + (seconds or Config.SpawnProtection)
	local character = player.Character
	if character then
		local old = character:FindFirstChildOfClass("ForceField")
		if old then
			old:Destroy()
		end
		local field = Instance.new("ForceField")
		field.Visible = true
		field.Parent = character
		task.delay(seconds or Config.SpawnProtection, function()
			if field and field.Parent then
				field:Destroy()
			end
		end)
	end
end

local function makeLeaderstats(player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = folder

	local deaths = Instance.new("IntValue")
	deaths.Name = "Deaths"
	deaths.Value = 0
	deaths.Parent = folder

	local score = Instance.new("IntValue")
	score.Name = "Score"
	score.Value = 0
	score.Parent = folder

	folder.Parent = player
end

local function assignTeam(player)
	local mode = RoundService.Mode
	if not mode or not mode.teamBased then
		player.Team = nil
		return
	end
	local teams = game:GetService("Teams")
	local hackers = teams:FindFirstChild("Hackers")
	local daemons = teams:FindFirstChild("Daemons")
	if not hackers or not daemons then
		player.Team = nil
		return
	end
	local countHackers, countDaemons = 0, 0
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Team == hackers then
			countHackers = countHackers + 1
		elseif other.Team == daemons then
			countDaemons = countDaemons + 1
		end
	end
	if countHackers <= countDaemons then
		player.Team = hackers
	else
		player.Team = daemons
	end
	player.Neutral = false
end

local function spawnCharacterAt(player, position)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	character:PivotTo(CFrame.new(position))
end

local function resetRoundScores()
	roundScores = { ffa = 0 }
	local teams = game:GetService("Teams")
	for _, team in ipairs(teams:GetChildren()) do
		roundScores[team.Name] = 0
	end
end

local function visibleScores()
	local mode = RoundService.Mode
	local result = {}
	if mode and mode.teamBased then
		for key, value in pairs(roundScores) do
			if key ~= "ffa" then
				result[key] = value
			end
		end
	else
		result.ffa = roundScores.ffa or 0
	end
	return result
end

local function broadcastState()
	local mode = RoundService.Mode
	local payload = {
		modeId = mode and mode.id or "ffa",
		modeName = mode and mode.name or "Free-for-All",
		teamBased = mode and mode.teamBased or false,
		phase = RoundService.Phase,
		timeLeft = math.max(0, roundEndsAt - now()),
		roundNumber = RoundService.RoundNumber,
		scoreToWin = Config.ScoreToWin,
		scores = visibleScores(),
	}
	local remote = Remotes.event("State")
	if remote then
		remote:FireAllClients(payload)
	end
end

function RoundService.BroadcastState()
	broadcastState()
end

function RoundService.GetRoster()
	local roster = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = Util.getHumanoid(player)
		local kills, deaths, score = 0, 0, 0
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			kills = stats:FindFirstChild("Kills") and stats.Kills.Value or 0
			deaths = stats:FindFirstChild("Deaths") and stats.Deaths.Value or 0
			score = stats:FindFirstChild("Score") and stats.Score.Value or 0
		end
		roster[#roster + 1] = {
			name = player.Name,
			displayName = player.DisplayName,
			userId = player.UserId,
			health = humanoid and math.floor(humanoid.Health) or 0,
			maxHealth = humanoid and math.floor(humanoid.MaxHealth) or 100,
			team = teamNameOf(player),
			alive = Util.isAlive(player),
			kills = kills,
			deaths = deaths,
			score = score,
			protected = RoundService.IsProtected(player),
		}
	end
	table.sort(roster, function(a, b)
		if a.kills == b.kills then
			return a.name < b.name
		end
		return a.kills > b.kills
	end)
	return roster
end

function RoundService.RegisterKill(killer, victim)
	if not victim then
		return
	end
	local victimStats = victim:FindFirstChild("leaderstats")
	if victimStats then
		local deaths = victimStats:FindFirstChild("Deaths")
		if deaths then
			deaths.Value = deaths.Value + 1
		end
	end

	local killerName = "The Arena"
	if killer and killer ~= victim then
		local killerStats = killer:FindFirstChild("leaderstats")
		if killerStats then
			local kills = killerStats:FindFirstChild("Kills")
			if kills then
				kills.Value = kills.Value + 1
			end
			local score = killerStats:FindFirstChild("Score")
			if score then
				score.Value = score.Value + 1
			end
		end
		local mode = RoundService.Mode
		local key = mode and mode.teamBased and teamNameOf(killer) or "ffa"
		roundScores[key] = (roundScores[key] or 0) + 1
		killerName = killer.DisplayName
	end

	local feed = Remotes.event("KillFeed")
	if feed then
		feed:FireAllClients(killerName, victim.DisplayName)
	end
	broadcastState()
end

local function createDummy(position, index)
	local model = Instance.new("Model")
	model.Name = "TrainingDummy_" .. tostring(index)

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = position + Vector3.new(0, 2, 0)
	torso.Anchored = true
	torso.Color = Color3.fromRGB(255, 120, 60)
	torso.Material = Enum.Material.Neon
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Position = torso.Position + Vector3.new(0, 1.7, 0)
	head.Anchored = true
	head.Color = Color3.fromRGB(255, 180, 80)
	head.Material = Enum.Material.Neon
	head.Parent = model

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.Position = torso.Position
	root.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 150
	humanoid.Health = 150
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthTag"
	billboard.Size = UDim2.fromOffset(120, 34)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = head
	billboard.Parent = model

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.BackgroundTransparency = 0.35
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Code
	label.TextColor3 = Color3.fromRGB(255, 180, 80)
	label.TextScaled = true
	label.Text = "TRAINING DUMMY"
	label.Parent = billboard

	humanoid.Died:Connect(function()
		task.delay(2.5, function()
			if model.Parent then
				model:Destroy()
			end
			local mode = RoundService.Mode
			if mode and mode.training and RoundService.Phase == "Active" then
				createDummy(position, index)
			end
		end)
	end)

	model.PrimaryPart = torso
	model.Parent = dummiesFolder
	return model
end

function RoundService.ClearDummies()
	if dummiesFolder then
		for _, child in ipairs(dummiesFolder:GetChildren()) do
			child:Destroy()
		end
	end
end

local function spawnDummies()
	RoundService.ClearDummies()
	local points = getSpawns(true)
	for index = 1, 3 do
		local base = points[((index - 1) % #points) + 1]
		createDummy(base + Vector3.new(index * 6, 0, 8), index)
	end
end

local function teleportEveryone()
	local mode = RoundService.Mode
	local points = getSpawns(mode and mode.arena)
	for index, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			if not Util.isAlive(player) then
				local ok = pcall(function()
					player:LoadCharacter()
				end)
				if not ok then
					return
				end
				local waited = 0
				while not Util.isAlive(player) and waited < 6 do
					task.wait(0.1)
					waited = waited + 0.1
				end
			end
			local character = player.Character
			if character and character.PrimaryPart then
				spawnCharacterAt(player, points[((index - 1) % #points) + 1])
				RoundService.Protect(player, Config.SpawnProtection)
			end
		end)
	end
end

local function startRound(modeIndex)
	local mode = Config.Modes[modeIndex]
	RoundService.Mode = mode
	RoundService.RoundNumber = RoundService.RoundNumber + 1
	RoundService.Phase = "Active"
	roundEndsAt = now() + mode.duration
	winnerAnnounced = false
	resetRoundScores()

	for _, player in ipairs(Players:GetPlayers()) do
		assignTeam(player)
	end
	RoundService.ClearDummies()
	if mode.training then
		spawnDummies()
	end
	teleportEveryone()
	feedbackToAll("ROUND " .. tostring(RoundService.RoundNumber) .. " - " .. mode.name, "round")
	broadcastState()

	task.spawn(function()
		while RoundService.Phase == "Active" and now() < roundEndsAt do
			local won = false
			for _, value in pairs(visibleScores()) do
				if value >= Config.ScoreToWin then
					won = true
				end
			end
			if won then
				break
			end
			task.wait(0.5)
		end
		if RoundService.Phase ~= "Active" then
			return
		end
		RoundService.Phase = "Post"
		roundEndsAt = now() + Config.PostRoundTime
		local bestTeam, bestScore = nil, -1
		for key, value in pairs(visibleScores()) do
			if value > bestScore then
				bestTeam, bestScore = key, value
			end
		end
		if bestTeam and bestScore > 0 then
			local label = bestTeam == "ffa" and "Arena winner decided by eliminations" or (tostring(bestTeam) .. " wins")
			feedbackToAll("ROUND OVER - " .. label, "round")
		else
			feedbackToAll("ROUND OVER - no eliminations", "round")
		end
		RoundService.ClearDummies()
		broadcastState()
	end)
end

local function nextModeIndex(current)
	local index = current + 1
	if index > #Config.Modes then
		index = 1
	end
	return index
end

local function watchPlayer(player)
	if not player:FindFirstChild("leaderstats") then
		makeLeaderstats(player)
	end
	assignTeam(player)

	local function onCharacter()
		task.wait(0.2)
		RoundService.Protect(player, Config.SpawnProtection)
		RoundService.BroadcastState()
	end

	player.CharacterAdded:Connect(function()
		task.spawn(onCharacter)
	end)
	if player.Character then
		task.spawn(onCharacter)
	end
	task.delay(1, function()
		RoundService.BroadcastState()
	end)
end

function RoundService.Start()
	local root = arena()
	if root then
		dummiesFolder = root:FindFirstChild("Dummies")
	end
	if not dummiesFolder then
		dummiesFolder = Instance.new("Folder")
		dummiesFolder.Name = "Dummies"
		dummiesFolder.Parent = root or workspace
	end

	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(function(player)
		protectedUntil[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end

	resetRoundScores()
	RoundService.Phase = "Intermission"
	roundEndsAt = now() + Config.IntermissionTime
	broadcastState()
	feedbackToAll("Welcome to " .. Config.GameName, "info")

	task.spawn(function()
		-- Start() already opened the first intermission.
		task.wait(Config.IntermissionTime)
		local modeIndex = 1
		while true do
			startRound(modeIndex)
			task.wait(Config.PostRoundTime + 0.5)
			modeIndex = nextModeIndex(modeIndex)
			RoundService.Phase = "Intermission"
			roundEndsAt = now() + Config.IntermissionTime
			feedbackToAll("Next mode: " .. Config.Modes[modeIndex].name, "info")
			broadcastState()
			task.wait(Config.IntermissionTime)
		end
	end)
end

return RoundService
]===],
	["server/TeleportService"] = [===[
--[[
	TeleportService (ModuleScript)
	Location: ServerScriptService/HackerFight/Services/TeleportService

	All teleportation is executed by the server. The client only names a
	destination; the server checks cooldown, world bounds, line of sight to a
	floor and (optionally) a safe landing before moving the character.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Config"))
local Util = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Util"))
local Remotes = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local TeleportService = {}

local lastUse = {}

local function now()
	return os.clock()
end

local function feedback(player, message, kind)
	local remote = Remotes.event("Feedback")
	if remote and player then
		remote:FireClient(player, message, kind or "info")
	end
end

local function insideBounds(position)
	local bounds = Config.WorldBounds
	return position.X >= bounds.Min.X and position.X <= bounds.Max.X
		and position.Y >= bounds.Min.Y and position.Y <= bounds.Max.Y
		and position.Z >= bounds.Min.Z and position.Z <= bounds.Max.Z
end

function TeleportService.SafeLanding(position, character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if character then
		params.FilterDescendantsInstances = { character }
	end
	params.IgnoreWater = true

	local origin = Vector3.new(position.X, position.Y + 40, position.Z)
	local result = workspace:Raycast(origin, Vector3.new(0, -200, 0), params)
	if result and result.Normal.Y > 0.55 then
		return result.Position + Vector3.new(0, 3.5, 0)
	end
	return nil
end

function TeleportService.MoveCharacter(player, position, requireSafe)
	local character = player.Character
	local root = Util.getRoot(player)
	if not character or not root then
		return false
	end
	if not insideBounds(position) then
		feedback(player, "Destination is outside the arena", "warn")
		return false
	end
	local destination = position
	if requireSafe then
		local landing = TeleportService.SafeLanding(position, character)
		if not landing then
			feedback(player, "Unsafe landing - teleport cancelled", "warn")
			return false
		end
		destination = landing
	end
	local ok = pcall(function()
		character:PivotTo(CFrame.new(destination))
	end)
	if not ok then
		feedback(player, "Teleport failed", "warn")
		return false
	end
	if root and root.Parent then
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end
	return true
end

local function spawnPoints()
	local points = {}
	local arena = workspace:FindFirstChild("HackerFightArena")
	local folder = arena and arena:FindFirstChild("Spawns")
	if folder then
		for _, pad in ipairs(folder:GetChildren()) do
			if pad:IsA("BasePart") then
				points[#points + 1] = pad.Position + Vector3.new(0, 4, 0)
			end
		end
	end
	if #points == 0 then
		points[1] = Vector3.new(0, 8, 0)
	end
	return points
end

function TeleportService.NearestSpawn(player)
	local root = Util.getRoot(player)
	local points = spawnPoints()
	local best = points[1]
	local bestDistance = math.huge
	for _, point in ipairs(points) do
		local distance = 0
		if root then
			distance = (point - root.Position).Magnitude
		end
		if distance < bestDistance then
			bestDistance = distance
			best = point
		end
	end
	return best
end

function TeleportService.FindEscapePoint(player)
	local root = Util.getRoot(player)
	if not root then
		return nil
	end
	local best, bestScore = nil, -1
	for _, point in ipairs(spawnPoints()) do
		local closestEnemy = math.huge
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player and Util.isAlive(other) then
				local otherRoot = Util.getRoot(other)
				if otherRoot then
					local distance = (otherRoot.Position - point).Magnitude
					if distance < closestEnemy then
						closestEnemy = distance
					end
				end
			end
		end
		if closestEnemy == math.huge then
			closestEnemy = (point - root.Position).Magnitude
		end
		if closestEnemy > bestScore then
			bestScore = closestEnemy
			best = point
		end
	end
	if best then
		local landing = TeleportService.SafeLanding(best, player.Character)
		return landing or best
	end
	return nil
end

local function checkCooldown(player)
	local untilTime = lastUse[player] or 0
	if now() < untilTime then
		return false, untilTime - now()
	end
	return true, 0
end

local function markUsed(player)
	lastUse[player] = now() + Config.TeleportCooldown
end

function TeleportService.GetCooldown(player)
	local untilTime = lastUse[player] or 0
	return math.max(0, untilTime - now())
end

local function handleTeleport(player, kind, data)
	if type(kind) ~= "string" then
		return
	end
	if not Util.isAlive(player) then
		feedback(player, "You are downed", "warn")
		return
	end
	local ready, remaining = checkCooldown(player)
	if not ready then
		feedback(player, string.format("Teleport ready in %.1fs", remaining), "warn")
		return
	end
	local settings = DataService.GetSettings(player)
	local requireSafe = settings.safetp ~= false
	local root = Util.getRoot(player)
	if not root then
		return
	end

	if kind == "player" then
		local targetName = data and data.target
		local target = Util.findPlayerByName(targetName)
		if not target or target == player then
			feedback(player, "Target not found", "warn")
			return
		end
		if not Util.isAlive(target) then
			feedback(player, "That player is downed", "warn")
			return
		end
		local targetRoot = Util.getRoot(target)
		if not targetRoot then
			return
		end
		local position = targetRoot.Position + targetRoot.CFrame.LookVector * -4 + Vector3.new(0, 1, 0)
		if not insideBounds(position) then
			position = targetRoot.Position + Vector3.new(0, 4, 0)
		end
		if (position - root.Position).Magnitude > Config.MaxTeleportDistance then
			feedback(player, "Target is too far away", "warn")
			return
		end
		local moved = TeleportService.MoveCharacter(player, position, false)
		if moved then
			markUsed(player)
			feedback(player, "Teleported to " .. target.DisplayName, "success")
		end
	elseif kind == "spawn" then
		local position = TeleportService.NearestSpawn(player)
		if TeleportService.MoveCharacter(player, position, true) then
			markUsed(player)
			feedback(player, "Returned to spawn", "success")
		end
	elseif kind == "coords" then
		local position = data and data.position
		if typeof(position) ~= "Vector3" then
			return
		end
		if (position - root.Position).Magnitude > Config.MaxTeleportDistance then
			feedback(player, "Destination is too far away", "warn")
			return
		end
		if TeleportService.MoveCharacter(player, position, requireSafe) then
			markUsed(player)
			feedback(player, "Waypoint reached", "success")
		end
	end
end

function TeleportService.Start()
	local remote = Remotes.event("Teleport")
	if remote then
		remote.OnServerEvent:Connect(function(player, kind, data)
			local ok, err = pcall(handleTeleport, player, kind, data)
			if not ok then
				warn("[HackerFight][Teleport] " .. tostring(err))
			end
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
	end)
end

return TeleportService
]===],
	["server/AbilityService"] = [===[
--[[
	AbilityService (ModuleScript)
	Location: ServerScriptService/HackerFight/Services/AbilityService

	Server authority for movement + defensive abilities. The client can only
	ASK; every grant, limit, duration and cooldown is decided here.

	Honest design note: Roblox always lets the owner of a character move it, so
	"fly" is a server-granted, server-timed window that the server monitors for
	abusive speeds. Everything else (speed, jump power, collisions, dash,
	invisibility, healing, invulnerability, shields) is applied by the server.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Config"))
local Util = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Util"))
local Remotes = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Remotes"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local TeleportService = require(script.Parent:WaitForChild("TeleportService"))

local AbilityService = {}

local FLY_WINDOW = 12
local states = {}

local function now()
	return os.clock()
end

local function newState()
	return {
		cooldowns = {},
		fly = false,
		flyUntil = 0,
		noclip = false,
		noclipUntil = 0,
		godUntil = 0,
		shieldUntil = 0,
		shieldHP = 0,
		invisUntil = 0,
		antiknockUntil = 0,
		jumpRequests = 0,
		jumpWindowStart = 0,
		lastStep = 0,
		restoreCollide = {},
		restoreTransparency = {},
		effects = {},
	}
end

local function getState(player)
	local state = states[player]
	if not state then
		state = newState()
		states[player] = state
	end
	return state
end

local function feedback(player, message, kind)
	local remote = Remotes.event("Feedback")
	if remote and player then
		remote:FireClient(player, message, kind or "info")
	end
end

local function pushState(player, ability, active, remaining, cooldownReadyIn)
	local remote = Remotes.event("AbilityState")
	if remote then
		remote:FireClient(player, ability, active, remaining or 0, cooldownReadyIn or 0)
	end
end

local function cooldownRemaining(state, key)
	local untilTime = state.cooldowns[key]
	if untilTime and now() < untilTime then
		return untilTime - now()
	end
	return 0
end

local function startCooldown(state, key, seconds)
	state.cooldowns[key] = now() + seconds
end

local function addEffect(character, color, name)
	if not character then
		return nil
	end
	local highlight = Instance.new("Highlight")
	highlight.Name = "AbilityFX_" .. tostring(name or "fx")
	highlight.FillColor = color
	highlight.FillTransparency = 0.75
	highlight.OutlineColor = color
	highlight.OutlineTransparency = 0.1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = character
	highlight.Parent = character
	return highlight
end

local function clearEffect(highlight)
	if highlight and highlight.Parent then
		highlight:Destroy()
	end
end

local function setAttribute(player, name, value)
	local character = player.Character
	if character then
		character:SetAttribute(name, value)
	end
end

local function applyMovement(player)
	local humanoid = Util.getHumanoid(player)
	if not humanoid then
		return
	end
	local settings = DataService.GetSettings(player)
	humanoid.WalkSpeed = math.clamp(settings.speed or Config.MinWalkSpeed, Config.MinWalkSpeed, Config.MaxWalkSpeed)
	humanoid.UseJumpPower = true
	humanoid.JumpPower = math.clamp(settings.jump or Config.MinJumpPower, Config.MinJumpPower, Config.MaxJumpPower)
end

function AbilityService.ApplyMovement(player)
	applyMovement(player)
end

local function restoreCollisions(state)
	for part, value in pairs(state.restoreCollide) do
		if part and part.Parent then
			pcall(function()
				part.CanCollide = value
			end)
		end
	end
	state.restoreCollide = {}
end

local function setNoclip(player, enabled)
	local state = getState(player)
	local character = player.Character
	if not character then
		return false
	end
	state.noclip = enabled
	if enabled then
		state.noclipUntil = now() + Config.NoclipMaxDuration
		for _, part in ipairs(Util.getCharacterParts(character)) do
			if state.restoreCollide[part] == nil then
				state.restoreCollide[part] = part.CanCollide
			end
			part.CanCollide = false
		end
		setAttribute(player, "HackerNoclip", true)
	else
		restoreCollisions(state)
		state.noclipUntil = 0
		setAttribute(player, "HackerNoclip", false)
	end
	return true
end

local function setFly(player, enabled)
	local state = getState(player)
	if enabled then
		local remaining = cooldownRemaining(state, "fly")
		if remaining > 0 then
			feedback(player, string.format("Fly is on cooldown (%.1fs)", remaining), "warn")
			return false
		end
		if not Util.isAlive(player) then
			return false
		end
		state.fly = true
		state.flyUntil = now() + FLY_WINDOW
		startCooldown(state, "fly", Config.Abilities.fly.Cooldown)
		setAttribute(player, "HackerFlying", true)
		pushState(player, "fly", true, FLY_WINDOW, Config.Abilities.fly.Cooldown)
		feedback(player, "Flight granted for " .. tostring(FLY_WINDOW) .. "s", "success")
	else
		state.fly = false
		state.flyUntil = 0
		setAttribute(player, "HackerFlying", false)
		pushState(player, "fly", false, 0, cooldownRemaining(state, "fly"))
	end
	return true
end

local function setInvisible(player, state, enabled)
	local character = player.Character
	if not character then
		return
	end
	state.invis = enabled
	if enabled then
		state.invisUntil = now() + Config.Abilities.invis.Duration
		for _, part in ipairs(Util.getCharacterParts(character)) do
			if state.restoreTransparency[part] == nil then
				state.restoreTransparency[part] = part.Transparency
			end
			part.Transparency = 1
		end
		setAttribute(player, "HackerInvisible", true)
	else
		for part, value in pairs(state.restoreTransparency) do
			if part and part.Parent and part.Transparency == 1 then
				part.Transparency = value
			end
		end
		state.restoreTransparency = {}
		setAttribute(player, "HackerInvisible", false)
	end
end

local function runAbility(player, ability)
	local state = getState(player)
	local definition = Config.Abilities[ability]
	if not definition then
		return
	end
	if not Util.isAlive(player) then
		feedback(player, "You cannot use that while downed", "warn")
		return
	end
	local remaining = cooldownRemaining(state, ability)
	if remaining > 0 then
		feedback(player, string.format("%s ready in %.1fs", ability, remaining), "warn")
		return
	end

	if ability == "godmode" then
		state.godUntil = now() + definition.Duration
		state.effects.god = addEffect(player.Character, Color3.fromRGB(255, 220, 60), "god")
		startCooldown(state, ability, definition.Cooldown)
		pushState(player, ability, true, definition.Duration, definition.Cooldown)
		feedback(player, "GOD MODE active", "success")
	elseif ability == "shield" then
		state.shieldUntil = now() + definition.Duration
		state.shieldHP = definition.Absorb
		state.effects.shield = addEffect(player.Character, Color3.fromRGB(60, 160, 255), "shield")
		startCooldown(state, ability, definition.Cooldown)
		pushState(player, ability, true, definition.Duration, definition.Cooldown)
		feedback(player, "Shield online (" .. tostring(definition.Absorb) .. " absorb)", "success")
	elseif ability == "heal" then
		local humanoid = Util.getHumanoid(player)
		if humanoid then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + definition.Amount)
		end
		startCooldown(state, ability, definition.Cooldown)
		pushState(player, ability, true, 0, definition.Cooldown)
		feedback(player, "Repaired +" .. tostring(definition.Amount) .. " HP", "success")
	elseif ability == "invis" then
		setInvisible(player, state, true)
		startCooldown(state, ability, definition.Cooldown)
		pushState(player, ability, true, definition.Duration, definition.Cooldown)
		feedback(player, "Stealth field engaged", "success")
		task.delay(definition.Cooldown, function()
			if states[player] == state then
				pushState(player, ability, false, 0, 0)
			end
		end)
	elseif ability == "antiknock" then
		state.antiknockUntil = now() + definition.Duration
		startCooldown(state, ability, definition.Cooldown)
		pushState(player, ability, true, definition.Duration, definition.Cooldown)
		feedback(player, "Anchor field active", "success")
	elseif ability == "escape" then
		local destination = TeleportService.FindEscapePoint(player)
		if not destination then
			feedback(player, "No safe escape point right now", "warn")
			return
		end
		startCooldown(state, ability, definition.Cooldown)
		TeleportService.MoveCharacter(player, destination, false)
		pushState(player, ability, true, 0, definition.Cooldown)
		feedback(player, "Emergency escape executed", "success")
	elseif ability == "dash" then
		local root = Util.getRoot(player)
		if not root then
			return
		end
		local humanoid = Util.getHumanoid(player)
		local direction = root.CFrame.LookVector
		if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
			direction = humanoid.MoveDirection
		end
		local target = root.Position + direction.Unit * Config.DashDistance
		startCooldown(state, ability, definition.Cooldown)
		TeleportService.MoveCharacter(player, target, true)
		pushState(player, ability, true, 0, definition.Cooldown)
		feedback(player, "Dash", "success")
	end
end

local function handleJumpRequest(player, kind)
	local state = getState(player)
	if kind == "doublejump" and not DataService.GetSettings(player).doublejump then
		return
	end
	if kind == "infjump" and not DataService.GetSettings(player).infjump then
		return
	end
	if now() - state.jumpWindowStart > 1 then
		state.jumpWindowStart = now()
		state.jumpRequests = 0
	end
	state.jumpRequests = state.jumpRequests + 1
	if state.jumpRequests > Config.JumpRequestRateLimit then
		feedback(player, "Jump requests throttled", "warn")
		return
	end
	pushState(player, "airjump", true, 0, 0)
end

local function handleTpWalkStep(player, direction)
	local state = getState(player)
	if not DataService.GetSettings(player).tpwalk or not state.tpwalk then
		return
	end
	if now() - state.lastStep < 0.2 then
		return
	end
	if type(direction) ~= "Vector3" then
		return
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.05 then
		return
	end
	local root = Util.getRoot(player)
	if not root then
		return
	end
	state.lastStep = now()
	local step = math.min(Config.TpWalkMaxStep, flat.Magnitude * Config.TpWalkMaxStep)
	local target = root.Position + flat.Unit * step
	TeleportService.MoveCharacter(player, target, false)
end

local function handleAction(player, action, value)
	if type(action) ~= "string" then
		return
	end
	local state = getState(player)

	if action == "speed" then
		local ok = DataService.SetSetting(player, "speed", tonumber(value))
		if ok then
			applyMovement(player)
			pushState(player, "speed", true, 0, 0)
		end
	elseif action == "jump" then
		local ok = DataService.SetSetting(player, "jump", tonumber(value))
		if ok then
			applyMovement(player)
			pushState(player, "jump", true, 0, 0)
		end
	elseif action == "fly" then
		setFly(player, value == true)
	elseif action == "flyspeed" then
		DataService.SetSetting(player, "flyspeed", tonumber(value))
	elseif action == "noclip" then
		if value == true then
			if not Util.isAlive(player) then
				return
			end
			setNoclip(player, true)
		else
			setNoclip(player, false)
		end
	elseif action == "tpwalk" then
		state.tpwalk = value == true
		if state.tpwalk then
			DataService.SetSetting(player, "tpwalk", true)
		end
		feedback(player, state.tpwalk and "TP Walk enabled" or "TP Walk disabled", "info")
	elseif action == "tpwalk_step" then
		handleTpWalkStep(player, value)
	elseif action == "airjump" then
		handleJumpRequest(player, value)
	elseif action == "dash" or action == "godmode" or action == "shield" or action == "heal"
		or action == "invis" or action == "antiknock" or action == "escape" then
		runAbility(player, action)
	elseif action == "sync" then
		-- The client lost its state (respawn / rejoin): resend everything.
		applyMovement(player)
		if state.fly then
			pushState(player, "fly", true, math.max(0, state.flyUntil - now()), cooldownRemaining(state, "fly"))
		end
		if state.noclip then
			pushState(player, "noclip", true, math.max(0, state.noclipUntil - now()), 0)
		end
	end
end

function AbilityService.IsInvulnerable(player)
	local state = states[player]
	if not state then
		return false
	end
	return now() < state.godUntil
end

function AbilityService.GetShield(player)
	local state = states[player]
	if not state then
		return 0
	end
	if now() >= state.shieldUntil then
		state.shieldHP = 0
	end
	return state.shieldHP
end

function AbilityService.AbsorbShield(player, damage)
	local state = states[player]
	if not state then
		return damage
	end
	if now() >= state.shieldUntil or state.shieldHP <= 0 then
		return damage
	end
	local absorbed = math.min(state.shieldHP, damage)
	state.shieldHP = state.shieldHP - absorbed
	if state.shieldHP <= 0 then
		clearEffect(state.effects.shield)
		state.effects.shield = nil
		feedback(player, "Shield depleted", "warn")
	end
	return damage - absorbed
end

function AbilityService.BreakInvisibility(player)
	local state = states[player]
	if state and now() < state.invisUntil then
		state.invisUntil = 0
		setInvisible(player, state, false)
		feedback(player, "Stealth broken by attack", "warn")
	end
end

function AbilityService.IsInvisible(player)
	local state = states[player]
	return state ~= nil and now() < state.invisUntil
end

function AbilityService.HasAntiKnockback(player)
	local state = states[player]
	return state ~= nil and now() < state.antiknockUntil
end

function AbilityService.ResetPlayer(player)
	local state = states[player]
	if state then
		restoreCollisions(state)
		for _, effect in pairs(state.effects) do
			clearEffect(effect)
		end
	end
	states[player] = newState()
end

local function monitor()
	while true do
		task.wait(1)
		for player, state in pairs(states) do
			if player.Parent == nil then
				states[player] = nil
			else
				local root = Util.getRoot(player)
				if root then
					local flatSpeed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
					if state.fly and flatSpeed > Config.FlySpeedMax * 1.8 then
						setFly(player, false)
						feedback(player, "Flight cancelled: speed limit exceeded", "warn")
					end
					if state.fly and now() > state.flyUntil then
						setFly(player, false)
					end
					if state.noclip and now() > state.noclipUntil then
						setNoclip(player, false)
						pushState(player, "noclip", false, 0, 0)
						feedback(player, "Noclip timed out", "warn")
					end
					if now() > state.godUntil and state.effects.god then
						clearEffect(state.effects.god)
						state.effects.god = nil
					end
					if now() > state.shieldUntil and state.effects.shield then
						clearEffect(state.effects.shield)
						state.effects.shield = nil
						state.shieldHP = 0
					end
					local character = player.Character
					local flaggedInvisible = character and character:GetAttribute("HackerInvisible") == true
					if now() > state.invisUntil and flaggedInvisible then
						setInvisible(player, state, false)
					end
				end
			end
		end
	end
end

local function watchPlayer(player)
	getState(player)

	local function onCharacter(character)
		states[player] = newState()
		character:SetAttribute("HackerFlying", false)
		character:SetAttribute("HackerNoclip", false)
		character:SetAttribute("HackerInvisible", false)
		task.wait(0.3)
		applyMovement(player)
	end

	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacter, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

function AbilityService.Start()
	local remote = Remotes.event("Ability")
	if remote then
		remote.OnServerEvent:Connect(function(player, action, value)
			local ok, err = pcall(handleAction, player, action, value)
			if not ok then
				warn("[HackerFight][Ability] " .. tostring(err))
			end
		end)
	end

	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	task.spawn(monitor)
end

return AbilityService
]===],
	["server/CombatService"] = [===[
--[[
	CombatService (ModuleScript)
	Location: ServerScriptService/HackerFight/Services/CombatService

	Every attack is resolved here. The client never sends damage, a position,
	a victim or a hit result - it only asks "attack" (optionally naming a
	preferred target). The server picks the real target, clamps reach and the
	damage multiplier, checks teams, cooldowns, spawn protection and god mode.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Config"))
local Util = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Util"))
local Remotes = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Remotes"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))
local AbilityService = require(script.Parent:WaitForChild("AbilityService"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local CombatService = {}

local lastAttack = {}
local lastAttacker = {}
local LATENCY_TOLERANCE = 4

local function now()
	return os.clock()
end

local function feedback(player, message, kind)
	local remote = Remotes.event("Feedback")
	if remote and player then
		remote:FireClient(player, message, kind or "info")
	end
end

local function isEnemy(a, b)
	if a == b then
		return false
	end
	if a.Team and b.Team then
		return a.Team ~= b.Team
	end
	return true
end

local function effectiveReach(player)
	local settings = DataService.GetSettings(player)
	local reach = tonumber(settings.reach) or Config.DefaultReach
	return math.clamp(reach, Config.MinReach, Config.MaxReach)
end

local function targetDistance(attacker, target)
	local a = Util.getRoot(attacker)
	local b = Util.getRoot(target)
	if not a or not b then
		return math.huge
	end
	return (a.Position - b.Position).Magnitude
end

local function damageFor(attacker)
	local settings = DataService.GetSettings(attacker)
	local multiplier = tonumber(settings.dmgmult) or 1
	multiplier = math.clamp(multiplier, Config.MinDamageMultiplier, Config.MaxDamageMultiplier)
	local mode = RoundService.GetMode()
	if mode and mode.abilityOnly then
		multiplier = 1
	end
	return Config.BaseDamage * multiplier
end

-- Training dummies are Models (not Players) so they need their own lookup.
function CombatService.FindNearestDummy(attacker, reach)
	local arena = workspace:FindFirstChild("HackerFightArena")
	local folder = arena and arena:FindFirstChild("Dummies")
	local root = Util.getRoot(attacker)
	if not folder or not root then
		return nil, math.huge
	end
	local best, bestDistance = nil, math.huge
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local primary = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and primary then
				local distance = (primary.Position - root.Position).Magnitude
				if distance <= reach + LATENCY_TOLERANCE and distance < bestDistance then
					best, bestDistance = model, distance
				end
			end
		end
	end
	return best, bestDistance
end

local function validTarget(attacker, target, reach)
	if not target or target == attacker then
		return false
	end
	if not Util.isAlive(target) then
		return false
	end
	if not isEnemy(attacker, target) then
		return false
	end
	if RoundService.IsProtected(target) then
		return false
	end
	if targetDistance(attacker, target) > reach + LATENCY_TOLERANCE then
		return false
	end
	return true
end

function CombatService.FindNearestTarget(attacker, reach)
	local best, bestDistance = nil, math.huge
	for _, other in ipairs(Players:GetPlayers()) do
		if validTarget(attacker, other, reach) then
			local distance = targetDistance(attacker, other)
			if distance < bestDistance then
				bestDistance = distance
				best = other
			end
		end
	end
	return best, bestDistance
end

local function resolveTarget(attacker, requestedName, reach)
	if type(requestedName) == "string" and requestedName ~= "" then
		local requested = Util.findPlayerByName(requestedName)
		if requested and validTarget(attacker, requested, reach) then
			return requested, targetDistance(attacker, requested)
		end
	end
	return CombatService.FindNearestTarget(attacker, reach)
end

function CombatService.Attack(attacker, requestedName)
	if not attacker or not attacker.Parent then
		return
	end
	if not RoundService.IsCombatEnabled() then
		feedback(attacker, "Combat is closed during intermission", "warn")
		return
	end
	if not Util.isAlive(attacker) then
		return
	end
	if RoundService.IsProtected(attacker) then
		feedback(attacker, "Spawn protection: attacks disabled", "warn")
		return
	end

	local readyAt = lastAttack[attacker] or 0
	if now() < readyAt then
		return
	end

	local settings = DataService.GetSettings(attacker)
	if settings.combatenabled == false then
		return
	end

	local reach = effectiveReach(attacker)
	local baseDamage = damageFor(attacker)
	local target = resolveTarget(attacker, requestedName, reach)

	if not target then
		local dummy = CombatService.FindNearestDummy(attacker, reach)
		if dummy then
			lastAttack[attacker] = now() + Config.AttackCooldown
			local dummyHumanoid = dummy:FindFirstChildOfClass("Humanoid")
			if dummyHumanoid then
				dummyHumanoid:TakeDamage(baseDamage)
			end
			local dummyFx = Remotes.event("CombatFX")
			if dummyFx then
				dummyFx:FireAllClients(attacker.Name, dummy.Name, "hit")
			end
			return
		end
		feedback(attacker, "No valid target in range", "warn")
		return
	end
	lastAttack[attacker] = now() + Config.AttackCooldown

	local humanoid = Util.getHumanoid(target)
	if not humanoid then
		return
	end

	if AbilityService.IsInvulnerable(target) then
		feedback(attacker, "Target is in God Mode", "warn")
		local fx = Remotes.event("CombatFX")
		if fx then
			fx:FireAllClients(attacker.Name, target.Name, "blocked")
		end
		return
	end

	local damage = AbilityService.AbsorbShield(target, baseDamage)

	if AbilityService.IsInvisible(attacker) then
		AbilityService.BreakInvisibility(attacker)
	end

	if damage > 0 then
		humanoid:TakeDamage(damage)
		lastAttacker[target] = attacker
	end

	local fx = Remotes.event("CombatFX")
	if fx then
		fx:FireAllClients(attacker.Name, target.Name, "hit")
	end
end

local function watchCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		local killer = lastAttacker[player]
		lastAttacker[player] = nil
		RoundService.RegisterKill(killer, player)
		if killer then
			feedback(killer, "Eliminated " .. player.DisplayName, "success")
		end
	end)
end

function CombatService.Start()
	local remote = Remotes.event("Attack")
	if remote then
		remote.OnServerEvent:Connect(function(player, requestedName)
			local ok, err = pcall(CombatService.Attack, player, requestedName)
			if not ok then
				warn("[HackerFight][Combat] " .. tostring(err))
			end
		end)
	end

	local function trackPlayer(player)
		lastAttack[player] = nil
		lastAttacker[player] = nil
		player.CharacterAdded:Connect(function(character)
			watchCharacter(player, character)
		end)
		if player.Character then
			watchCharacter(player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(trackPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		trackPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastAttack[player] = nil
		lastAttacker[player] = nil
	end)
end

return CombatService
]===],
	["server/Main"] = [===[
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
]===],
	["client/Settings"] = [===[
--[[
	Settings (ModuleScript)
	Location: StarterPlayer/StarterPlayerScripts/HackerFight/Modules/Settings

	Client copy of the saved settings. The server holds the real copy; this
	module keeps the UI responsive and forwards every change to the server,
	which validates and persists it.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:WaitForChild("HackerFight")
local Config = require(root:WaitForChild("Config"))
local Remotes = require(root:WaitForChild("Remotes"))

local Settings = {}

Settings.values = {}
Settings.waypoints = {}
Settings.persistent = false
Settings.onChanged = nil
Settings.onWaypoints = nil
Settings.loaded = false

local function schemaOf(key)
	return Config.Settings[key]
end

function Settings.clampValue(key, value)
	local schema = schemaOf(key)
	if not schema then
		return nil
	end
	if schema.type == "number" then
		local number = tonumber(value)
		if number == nil or number ~= number then
			return nil
		end
		return math.clamp(number, schema.min, schema.max)
	elseif schema.type == "boolean" then
		if type(value) ~= "boolean" then
			return nil
		end
		return value
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

function Settings.get(key)
	local value = Settings.values[key]
	if value == nil then
		local schema = schemaOf(key)
		if schema then
			return schema.default
		end
	end
	return value
end

function Settings.set(key, value)
	local clean = Settings.clampValue(key, value)
	if clean == nil then
		return false
	end
	Settings.values[key] = clean
	if Settings.onChanged then
		local ok, err = pcall(Settings.onChanged, key, clean)
		if not ok then
			warn("[HackerFight][Settings] onChanged error: " .. tostring(err))
		end
	end
	return true
end

local lastPush = {}

function Settings.push(key)
	-- Sliders fire on every pixel of movement; keep the remote traffic sane.
	local now = os.clock()
	if lastPush[key] and now - lastPush[key] < 0.2 then
		return
	end
	lastPush[key] = now
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("set", key, Settings.get(key))
	end
end

function Settings.apply(key, value, save)
	if not Settings.set(key, value) then
		return false
	end
	if save then
		Settings.push(key)
	end
	return true
end

function Settings.save()
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("save")
	end
end

function Settings.resetAll()
	for key, schema in pairs(Config.Settings) do
		Settings.values[key] = schema.default
	end
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("reset")
	end
	if Settings.onChanged then
		for key in pairs(Config.Settings) do
			pcall(Settings.onChanged, key, Settings.get(key))
		end
	end
end

function Settings.Init(ctx)
	for key, schema in pairs(Config.Settings) do
		Settings.values[key] = schema.default
	end
	Settings.ctx = ctx

	local getter = Remotes.func("GetSettings")
	if getter then
		local ok, data = pcall(function()
			return getter:InvokeServer()
		end)
		if ok and type(data) == "table" and type(data.settings) == "table" then
			for key, value in pairs(data.settings) do
				Settings.set(key, value)
			end
			Settings.persistent = data.persistent == true
			if type(data.waypoints) == "table" then
				Settings.waypoints = data.waypoints
			end
		else
			warn("[HackerFight][Settings] could not load saved settings")
		end
	end
	Settings.loaded = true

	local remote = Remotes.event("Settings")
	if remote then
		remote.OnClientEvent:Connect(function(action, a, b, c)
			if action == "sync" and type(a) == "table" then
				for key, value in pairs(a) do
					Settings.set(key, value)
				end
				if ctx and ctx.notify then
					ctx.notify("Settings reloaded from server", "success")
				end
			elseif action == "saved" then
				if ctx and ctx.notify then
					if a then
						ctx.notify("Settings saved", "success")
					else
						ctx.notify("Could not save: " .. tostring(b or "unknown"), "warn")
					end
				end
			elseif action == "rejected" then
				if ctx and ctx.notify then
					ctx.notify("Server rejected setting: " .. tostring(a), "warn")
				end
			elseif action == "waypoints" then
				if type(a) == "table" then
					Settings.waypoints = a
				end
				if Settings.onWaypoints then
					Settings.onWaypoints(a, b, c)
				end
			end
		end)
	end
end

return Settings
]===],
	["client/UI"] = [===[
--[[
	UI (ModuleScript)
	Location: StarterPlayer/StarterPlayerScripts/HackerFight/Modules/UI

	Builds and controls the whole hacker interface at runtime:
	- draggable / minimizable / maximizable window with a toggle key
	- tab pages generated from ReplicatedStorage.HackerFight.Features
	- search filter, toggles, sliders, cycle buttons, keybind capture
	- live player / waypoint / history lists
	- theme, UI scale, notifications and UI sounds

	Every control is wired to ctx.dispatch(featureId, value). Nothing is a
	mock: a toggle calls the matching client module, which talks to the server.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local root = ReplicatedStorage:WaitForChild("HackerFight")
local Config = require(root:WaitForChild("Config"))
local Features = require(root:WaitForChild("Features"))

local UI = {}

UI.ctx = nil
UI.screen = nil
UI.window = nil
UI.containers = {}
UI.widgets = {}
UI.themed = {}
UI.themeId = "matrix"
UI.theme = Config.Themes.matrix
UI.open = true
UI.minimized = false
UI.maximized = false
UI.normalSize = nil
UI.cooldowns = {}
UI.silent = true
UI.drag = nil
UI.listeningKey = false
UI.scale = 1

local THEME = UI.theme
local IsTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

----------------------------------------------------------------------
-- small builders
----------------------------------------------------------------------
local function make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function ensure(parent, name, className, props)
	local existing = parent:FindFirstChild(name)
	if existing and not existing:IsA(className) then
		existing:Destroy()
		existing = nil
	end
	local instance = existing
	if not instance then
		instance = Instance.new(className)
		instance.Name = name
	end
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function corner(object, radius)
	local existing = object:FindFirstChildOfClass("UICorner")
	local uiCorner = existing or Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, radius or 6)
	uiCorner.Parent = object
	return uiCorner
end

local function stroke(object, color, thickness, transparency)
	local existing = object:FindFirstChildOfClass("UIStroke")
	local uiStroke = existing or Instance.new("UIStroke")
	uiStroke.Color = color or THEME.border
	uiStroke.Thickness = thickness or 1
	uiStroke.Transparency = transparency or 0.4
	uiStroke.Parent = object
	return uiStroke
end

local function themeColor(object, property, role)
	UI.themed[#UI.themed + 1] = { obj = object, prop = property, role = role }
	object[property] = UI.theme[role]
end

local function tween(object, seconds, goals)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local animation = TweenService:Create(object, info, goals)
	animation:Play()
	return animation
end

local function isClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function playSound(soundId, volume)
	if not UI.ctx or UI.ctx.modules.Settings.get("sounds") ~= true then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.3
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(4, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

----------------------------------------------------------------------
-- notifications
----------------------------------------------------------------------
function UI.notify(message, kind)
	local area = UI.containers.notifications
	if not area then
		return
	end
	local color = UI.theme.accent
	if kind == "warn" then
		color = UI.theme.danger
	elseif kind == "success" then
		color = UI.theme.accent2
	elseif kind == "combat" then
		color = UI.theme.accent3
	elseif kind == "round" then
		color = UI.theme.accent
	end

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = UI.theme.panelAlt,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = area,
	}, area)
	corner(holder, 5)
	local bar = make("Frame", {
		Size = UDim2.new(0, 3, 1, -8),
		Position = UDim2.new(0, 4, 0, 4),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, holder)
	corner(bar, 2)
	local label = make("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = UI.theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = tostring(message),
	}, holder)

	holder.BackgroundTransparency = 0.15
	tween(holder, 0.15, { BackgroundTransparency = 0.15 })
	label.TextTransparency = 0
	label.TextColor3 = color
	task.delay(3.4, function()
		if holder and holder.Parent then
			tween(holder, 0.25, { BackgroundTransparency = 1 })
			tween(label, 0.25, { TextTransparency = 1 })
			task.wait(0.3)
			if holder and holder.Parent then
				holder:Destroy()
			end
		end
	end)

	local children = area:GetChildren()
	local count = 0
	for _, child in ipairs(children) do
		if child:IsA("Frame") then
			count = count + 1
		end
	end
	if count > 4 then
		for _, child in ipairs(children) do
			if child:IsA("Frame") then
				child:Destroy()
				break
			end
		end
	end
end

function UI.click()
	if UI.silent then
		return
	end
	playSound("rbxasset://sounds/clickfast.wav", 0.15)
end

----------------------------------------------------------------------
-- tabs, search
----------------------------------------------------------------------
local pages = {}
local tabButtons = {}
local activeTab = "combat"

local function setTab(tabId)
	activeTab = tabId
	for id, page in pairs(pages) do
		page.Visible = id == tabId
	end
	for id, button in pairs(tabButtons) do
		button.TextColor3 = id == tabId and UI.theme.accent or UI.theme.dim
		local underline = button:FindFirstChild("Underline")
		if underline then
			underline.Visible = id == tabId
		end
	end
	UI.click()
end

local function rowMatches(row, query)
	if query == "" then
		return true
	end
	local text = row:GetAttribute("SearchText")
	if type(text) ~= "string" then
		text = ""
	end
	return string.find(text, query, 1, true) ~= nil
end

local function applySearch(query)
	local lower = string.lower(query or "")
	local matchedAnywhere = false
	local tabHas = {}
	for tabId, page in pairs(pages) do
		local anyVisible = false
		for _, child in ipairs(page:GetChildren()) do
			if child:IsA("GuiObject") and child.Name ~= "Layout" and child.Name ~= "Padding" then
				if child:GetAttribute("IsHeader") == true then
					child.Visible = lower == ""
				else
					local match = rowMatches(child, lower)
					child.Visible = match
					if match then
						anyVisible = true
					end
				end
			end
		end
		tabHas[tabId] = anyVisible
		if anyVisible then
			matchedAnywhere = true
		end
	end
	if lower ~= "" and not tabHas[activeTab] then
		for _, tab in ipairs(Features.Tabs) do
			if tabHas[tab.id] then
				setTab(tab.id)
				break
			end
		end
	end
	for id, button in pairs(tabButtons) do
		if lower ~= "" and not tabHas[id] then
			button.TextTransparency = 0.65
		else
			button.TextTransparency = 0
		end
	end
	UI.containers.footer.Text = lower == ""
		and "HACKERFIGHT // READY"
		or ("SEARCH: " .. tostring(query) .. (matchedAnywhere and "" or "  (no matches)"))
end

----------------------------------------------------------------------
-- rows
----------------------------------------------------------------------
local function baseRow(page, feature, order, height)
	local row = make("Frame", {
		Name = "Row_" .. tostring(feature.id or feature.label),
		Size = UDim2.new(1, -6, 0, height),
		BackgroundColor3 = UI.theme.panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Active = true,
		LayoutOrder = order,
	}, page)
	corner(row, 6)
	local uiStroke = stroke(row, UI.theme.border, 1, 0.55)
	themeColor(row, "BackgroundColor3", "panel")
	UI.themed[#UI.themed + 1] = { obj = uiStroke, prop = "Color", role = "border" }
	row:SetAttribute("SearchText", string.lower(feature.label or ""))
	row.MouseEnter:Connect(function()
		tween(row, 0.12, { BackgroundTransparency = 0.02 })
	end)
	row.MouseLeave:Connect(function()
		tween(row, 0.12, { BackgroundTransparency = 0.15 })
	end)
	return row
end

local function labelText(parent, text, size, position, colorRole, fontWeight)
	local label = make("TextLabel", {
		Size = size,
		Position = position,
		BackgroundTransparency = 1,
		Font = fontWeight or Enum.Font.Code,
		TextSize = 14,
		TextColor3 = UI.theme[colorRole or "text"],
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	}, parent)
	UI.themed[#UI.themed + 1] = { obj = label, prop = "TextColor3", role = colorRole or "text" }
	return label
end

local function buildHeader(page, feature, order)
	local holder = make("Frame", {
		Size = UDim2.new(1, -6, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, page)
	holder.Name = "Header_" .. tostring(order)
	holder:SetAttribute("IsHeader", true)
	holder:SetAttribute("SearchText", string.lower(feature.label or ""))
	UI.allHeaders = UI.allHeaders or {}
	UI.allHeaders[#UI.allHeaders + 1] = holder
	local label = make("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = UI.theme.accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(feature.label or ""),
	}, holder)
	UI.themed[#UI.themed + 1] = { obj = label, prop = "TextColor3", role = "accent" }
	local line = make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = UI.theme.border,
		BorderSizePixel = 0,
	}, holder)
	UI.themed[#UI.themed + 1] = { obj = line, prop = "BackgroundColor3", role = "border" }
	return holder
end

local function buildToggle(page, feature, order)
	local row = baseRow(page, feature, order, 42)
	local title = labelText(row, feature.label, UDim2.new(1, -90, 0, 20), UDim2.new(0, 10, 0, 6), "text")
	local hint = labelText(row, feature.hint or "", UDim2.new(1, -90, 0, 12), UDim2.new(0, 10, 0, 24), "dim")
	hint.TextSize = 11

	local track = make("Frame", {
		Size = UDim2.new(0, 42, 0, 22),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundColor3 = UI.theme.panelAlt,
		BorderSizePixel = 0,
	}, row)
	corner(track, 11)
	local knob = make("Frame", {
		Size = UDim2.new(0, 16, 0, 16),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		BackgroundColor3 = UI.theme.dim,
		BorderSizePixel = 0,
	}, track)
	corner(knob, 8)

	local enabled = false

	local function render(value, animate)
		enabled = value == true
		local goals = {
			Position = enabled and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = enabled and UI.theme.accent or UI.theme.dim,
		}
		local trackGoals = { BackgroundColor3 = enabled and UI.theme.accent2 or UI.theme.panelAlt }
		if animate then
			tween(knob, 0.15, goals)
			tween(track, 0.15, trackGoals)
		else
			knob.Position = goals.Position
			knob.BackgroundColor3 = goals.BackgroundColor3
			track.BackgroundColor3 = trackGoals.BackgroundColor3
		end
		track.BackgroundTransparency = enabled and 0.55 or 0
		title.TextColor3 = enabled and UI.theme.accent or UI.theme.text
	end

	local function onInput(input)
		if not isClick(input) then
			return
		end
		render(not enabled, true)
		UI.click()
		if UI.ctx then
			UI.ctx.dispatch(feature.id, enabled)
		end
	end

	row.InputBegan:Connect(onInput)
	track.InputBegan:Connect(onInput)
	knob.InputBegan:Connect(onInput)
	UI.widgets[feature.id] = { kind = "toggle", set = render }
	render(false, false)
	return row
end

local function buildSlider(page, feature, order)
	local row = baseRow(page, feature, order, 50)
	local title = labelText(row, feature.label, UDim2.new(1, -110, 0, 18), UDim2.new(0, 10, 0, 4), "text")
	local valueLabel = make("TextLabel", {
		Size = UDim2.new(0, 100, 0, 18),
		Position = UDim2.new(1, -108, 0, 4),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = UI.theme.accent2,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
	}, row)
	UI.themed[#UI.themed + 1] = { obj = valueLabel, prop = "TextColor3", role = "accent2" }

	local track = make("Frame", {
		Size = UDim2.new(1, -20, 0, 8),
		Position = UDim2.new(0, 10, 0, 30),
		BackgroundColor3 = UI.theme.panelAlt,
		BorderSizePixel = 0,
		Active = true,
	}, row)
	corner(track, 4)
	local fill = make("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = UI.theme.accent,
		BorderSizePixel = 0,
	}, track)
	corner(fill, 4)
	themeColor(fill, "BackgroundColor3", "accent")
	local knob = make("Frame", {
		Size = UDim2.new(0, 14, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = UI.theme.text,
		BorderSizePixel = 0,
	}, track)
	corner(knob, 7)
	UI.themed[#UI.themed + 1] = { obj = knob, prop = "BackgroundColor3", role = "text" }

	local minValue = feature.min or 0
	local maxValue = feature.max or 100
	local step = feature.step or 1
	local suffix = feature.suffix or ""
	local value = minValue

	local function format(number)
		if step >= 1 then
			return string.format("%d%s", math.floor(number + 0.5), suffix)
		end
		return string.format("%.2f%s", number, suffix)
	end

	local function render(number, fire)
		number = math.clamp(number, minValue, maxValue)
		number = math.floor((number - minValue) / step + 0.5) * step + minValue
		value = number
		local alpha = (number - minValue) / (maxValue - minValue)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = format(number)
		if fire and UI.ctx then
			UI.ctx.dispatch(feature.id, number)
		end
	end

	local dragging = false
	local function applyFromInput(input)
		local alpha = (input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X)
		alpha = math.clamp(alpha, 0, 1)
		render(minValue + (maxValue - minValue) * alpha, true)
	end

	track.InputBegan:Connect(function(input)
		if not isClick(input) then
			return
		end
		dragging = true
		applyFromInput(input)
		UI.click()
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			applyFromInput(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isClick(input) then
			dragging = false
		end
	end)

	UI.widgets[feature.id] = { kind = "slider", set = function(number) render(number, false) end }
	render(feature.default or Config.Settings[feature.id] and Config.Settings[feature.id].default or minValue, false)
	return row
end

local function buildButton(page, feature, order)
	local row = make("Frame", {
		Size = UDim2.new(1, -6, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, page)
	row:SetAttribute("SearchText", string.lower(feature.label or ""))

	local button = make("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = UI.theme.panelAlt,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.Code,
		TextSize = 14,
		TextColor3 = UI.theme.text,
		Text = feature.label,
	}, row)
	corner(button, 6)
	local uiStroke = stroke(button, UI.theme.border, 1, 0.5)
	themeColor(button, "BackgroundColor3", "panelAlt")

	local bar = make("Frame", {
		Size = UDim2.new(0, 0, 0, 3),
		Position = UDim2.new(0, 4, 1, -5),
		BackgroundColor3 = UI.theme.accent2,
		BorderSizePixel = 0,
	}, button)
	corner(bar, 2)

	button.MouseEnter:Connect(function()
		tween(button, 0.12, { BackgroundTransparency = 0 })
		uiStroke.Transparency = 0.1
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.12, { BackgroundTransparency = 0 })
		uiStroke.Transparency = 0.5
	end)
	button.MouseButton1Click:Connect(function()
		UI.click()
		if UI.ctx then
			UI.ctx.dispatch(feature.id, true)
		end
	end)

	local widget = {
		kind = "button",
		button = button,
		bar = bar,
		cooldownKey = feature.cooldown,
		label = feature.label,
		untilTime = 0,
		duration = 1,
		setCooldown = function(remaining, total)
			widget.untilTime = os.clock() + remaining
			widget.duration = math.max(total or 1, 0.1)
			bar.Size = UDim2.new(math.clamp(remaining / widget.duration, 0, 1), 0, 0, 3)
		end,
	}
	UI.widgets[feature.id] = widget
	return row
end

local function buildCycle(page, feature, order)
	local row = baseRow(page, feature, order, 42)
	local title = labelText(row, feature.label, UDim2.new(1, -140, 1, 0), UDim2.new(0, 10, 0, 0), "text")
	local options = feature.options or { "option" }
	local index = 1

	local button = make("TextButton", {
		Size = UDim2.new(0, 120, 0, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundColor3 = UI.theme.panelAlt,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = UI.theme.accent2,
		Text = options[index],
	}, row)
	corner(button, 5)
	stroke(button, UI.theme.border, 1, 0.4)

	local function render(value)
		button.Text = tostring(value)
	end

	button.MouseButton1Click:Connect(function()
		index = index + 1
		if index > #options then
			index = 1
		end
		render(options[index])
		UI.click()
		if UI.ctx then
			UI.ctx.dispatch(feature.id, options[index])
		end
	end)

	UI.widgets[feature.id] = {
		kind = "cycle",
		set = function(value)
			for position, option in ipairs(options) do
				if tostring(option) == tostring(value) then
					index = position
					render(option)
				end
			end
		end,
	}
	return row
end

local function buildKeybind(page, feature, order)
	local row = baseRow(page, feature, order, 42)
	labelText(row, feature.label, UDim2.new(1, -160, 1, 0), UDim2.new(0, 10, 0, 0), "text")
	local button = make("TextButton", {
		Size = UDim2.new(0, 140, 0, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundColor3 = UI.theme.panelAlt,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = UI.theme.accent,
		Text = "RightShift",
	}, row)
	corner(button, 5)
	stroke(button, UI.theme.border, 1, 0.4)

	button.MouseButton1Click:Connect(function()
		UI.listeningKey = true
		button.Text = "PRESS A KEY..."
		UI.click()
	end)

	UI.widgets[feature.id] = {
		kind = "keybind",
		set = function(value)
			button.Text = tostring(value)
		end,
		cancel = function()
			UI.listeningKey = false
			button.Text = tostring(UI.ctx.modules.Settings.get("keybind"))
		end,
	}
	return row
end

local function buildInfo(page, feature, order)
	local row = baseRow(page, feature, order, 34)
	row.BackgroundTransparency = 0.45
	labelText(row, feature.label, UDim2.new(0.5, -10, 1, 0), UDim2.new(0, 10, 0, 0), "dim")
	local value = make("TextLabel", {
		Size = UDim2.new(0.5, -14, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = UI.theme.text,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = feature.text or "",
	}, row)
	UI.widgets[feature.id] = {
		kind = "info",
		set = function(text, kind)
			value.Text = tostring(text)
			if kind == "success" then
				value.TextColor3 = UI.theme.accent
			elseif kind == "warn" then
				value.TextColor3 = UI.theme.danger
			elseif kind == "accent" then
				value.TextColor3 = UI.theme.accent2
			else
				value.TextColor3 = UI.theme.text
			end
		end,
	}
	return row
end

local function buildStats(page, feature, order)
	local row = baseRow(page, feature, order, 64)
	labelText(row, "KILLS", UDim2.new(0.33, 0, 0, 16), UDim2.new(0, 12, 0, 8), "dim")
	labelText(row, "DEATHS", UDim2.new(0.33, 0, 0, 16), UDim2.new(0.33, 0, 0, 8), "dim")
	labelText(row, "SCORE", UDim2.new(0.33, 0, 0, 16), UDim2.new(0.66, 0, 0, 8), "dim")
	local killValue = labelText(row, "0", UDim2.new(0.33, 0, 0, 26), UDim2.new(0, 12, 0, 26), "accent")
	local deathValue = labelText(row, "0", UDim2.new(0.33, 0, 0, 26), UDim2.new(0.33, 0, 0, 26), "danger")
	local scoreValue = labelText(row, "0", UDim2.new(0.33, 0, 0, 26), UDim2.new(0.66, 0, 0, 26), "accent2")
	for _, label in ipairs({ killValue, deathValue, scoreValue }) do
		label.TextSize = 22
	end
	UI.widgets[feature.id] = {
		kind = "stats",
		set = function(kills, deaths, score)
			killValue.Text = tostring(kills or 0)
			deathValue.Text = tostring(deaths or 0)
			scoreValue.Text = tostring(score or 0)
		end,
	}
	return row
end

local function buildList(page, feature, order)
	local row = make("Frame", {
		Size = UDim2.new(1, -6, 0, 60),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, page)
	row.Name = "List_" .. tostring(feature.id)
	row:SetAttribute("SearchText", string.lower(feature.label or ""))

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.theme.panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, row)
	corner(holder, 6)
	local padding = make("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
	}, holder)
	local layout = make("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)

	local widget = {
		kind = "list",
		holder = holder,
		layout = layout,
		padding = padding,
		items = {},
		onClick = nil,
		onDelete = nil,
		isPlayers = feature.kind == "playerlist",
	}
	UI.widgets[feature.id] = widget
	return row
end

----------------------------------------------------------------------
-- list rendering
----------------------------------------------------------------------
local function clearList(widget)
	for _, child in ipairs(widget.holder:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function emptyLabel(widget, text)
	local label = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = UI.theme.dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "  " .. text,
	}, widget.holder)
	UI.themed[#UI.themed + 1] = { obj = label, prop = "TextColor3", role = "dim" }
end

function UI.setList(id, items, onClick, onDelete)
	local widget = UI.widgets[id]
	if not widget or widget.kind ~= "list" then
		return
	end
	widget.onClick = onClick
	widget.onDelete = onDelete
	clearList(widget)
	if #items == 0 then
		emptyLabel(widget, widget.isPlayers and "No players online" or "Nothing saved yet")
		return
	end
	for index, item in ipairs(items) do
		local rowButton = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = UI.theme.panelAlt,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Enum.Font.Code,
			TextSize = 12,
			TextColor3 = UI.theme.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "  " .. tostring(item.text or ""),
			LayoutOrder = index,
		}, widget.holder)
		corner(rowButton, 4)
		-- List rows are rebuilt often; set colours directly instead of
		-- registering theme targets so this cannot grow without bound.
		rowButton.BackgroundColor3 = UI.theme.panelAlt
		rowButton.TextColor3 = UI.theme.text
		if item.sub then
			rowButton.Text = "  " .. tostring(item.text) .. "   [" .. tostring(item.sub) .. "]"
		end
		if onDelete then
			local deleteButton = make("TextButton", {
				Size = UDim2.new(0, 26, 0, 22),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -4, 0.5, 0),
				BackgroundColor3 = UI.theme.danger,
				BackgroundTransparency = 0.75,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Font = Enum.Font.Code,
				TextSize = 14,
				TextColor3 = UI.theme.danger,
				Text = "x",
			}, rowButton)
			corner(deleteButton, 4)
			deleteButton.MouseButton1Click:Connect(function()
				UI.click()
				onDelete(item)
			end)
			rowButton.Size = UDim2.new(1, -32, 0, 30)
		end
		rowButton.MouseEnter:Connect(function()
			tween(rowButton, 0.1, { BackgroundTransparency = 0 })
		end)
		rowButton.MouseLeave:Connect(function()
			tween(rowButton, 0.1, { BackgroundTransparency = 0.2 })
		end)
		rowButton.MouseButton1Click:Connect(function()
			UI.click()
			if widget.onClick then
				widget.onClick(item)
			end
		end)
	end
end

function UI.setPlayerList(id, roster, onClick)
	local items = {}
	for _, entry in ipairs(roster) do
		local tag = entry.team or "FFA"
		items[#items + 1] = {
			text = string.format("%s  |  %s  |  %d HP  |  %dK/%dD", entry.displayName or entry.name, tag, entry.health or 0, entry.kills or 0, entry.deaths or 0),
			action = "select",
			name = entry.name,
			health = entry.health,
			maxHealth = entry.maxHealth,
		}
	end
	UI.setList(id, items, onClick)
end

----------------------------------------------------------------------
-- chrome
----------------------------------------------------------------------
local function buildWindow(ctx)
	local gui = ensure(ctx.player.PlayerGui, "HackerFightUI", "ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
	})
	UI.screen = gui

	local window = ensure(gui, "Window", "Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = IsTouch and UDim2.fromScale(0.95, 0.86) or UDim2.fromScale(0.66, 0.74),
		BackgroundColor3 = UI.theme.bg,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
		ZIndex = 2,
	})
	corner(window, 10)
	local frameStroke = stroke(window, UI.theme.border, 1.5, 0.25)
	themeColor(window, "BackgroundColor3", "bg")
	UI.themed[#UI.themed + 1] = { obj = frameStroke, prop = "Color", role = "border" }
	window.Visible = true
	UI.window = window
	UI.normalSize = window.Size

	local uiScale = ensure(window, "UIScale", "UIScale", { Scale = 1 })
	UI.windowScale = uiScale

	local titleBar = ensure(window, "TitleBar", "Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = UI.theme.panel,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Active = true,
	})
	themeColor(titleBar, "BackgroundColor3", "panel")

	local title = ensure(titleBar, "TitleLabel", "TextLabel", {
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 15,
		TextColor3 = UI.theme.accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "HACKER FIGHT  //  v" .. Config.Version,
	})
	UI.themed[#UI.themed + 1] = { obj = title, prop = "TextColor3", role = "accent" }

	local function titleButton(name, text, xOffset, danger)
		local button = ensure(titleBar, name, "TextButton", {
			Size = UDim2.new(0, 26, 0, 22),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			BackgroundColor3 = UI.theme.panelAlt,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Enum.Font.Code,
			TextSize = 14,
			TextColor3 = danger and UI.theme.danger or UI.theme.text,
			Text = text,
		})
		corner(button, 4)
		return button
	end

	local minButton = titleButton("MinBtn", "-", -8, false)
	local maxButton = titleButton("MaxBtn", "o", -38, false)
	local closeButton = titleButton("CloseBtn", "x", -68, true)

	local tabBar = ensure(window, "TabBar", "ScrollingFrame", {
		Position = UDim2.new(0, 6, 0, 34),
		Size = UDim2.new(1, -12, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
	})
	local tabLayout = ensure(tabBar, "Layout", "UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	tabLayout.Parent = tabBar

	local search = ensure(window, "Search", "TextBox", {
		Position = UDim2.new(0, 12, 0, 74),
		Size = UDim2.new(1, -24, 0, 26),
		BackgroundColor3 = UI.theme.panel,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Font = Enum.Font.Code,
		TextSize = 13,
		PlaceholderText = "search features...",
		PlaceholderColor3 = UI.theme.dim,
		TextColor3 = UI.theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Text = "",
	})
	corner(search, 5)
	stroke(search, UI.theme.border, 1, 0.5)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}, search)
	UI.themed[#UI.themed + 1] = { obj = search, prop = "TextColor3", role = "text" }
	UI.themed[#UI.themed + 1] = { obj = search, prop = "BackgroundColor3", role = "panel" }
	UI.themed[#UI.themed + 1] = { obj = search, prop = "PlaceholderColor3", role = "dim" }

	local content = ensure(window, "Content", "Frame", {
		Position = UDim2.new(0, 12, 0, 106),
		Size = UDim2.new(1, -24, 1, -134),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
	UI.containers.content = content

	local footer = ensure(window, "Footer", "TextLabel", {
		Position = UDim2.new(0, 12, 1, -24),
		Size = UDim2.new(1, -24, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 11,
		TextColor3 = UI.theme.dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "HACKERFIGHT // READY",
	})
	UI.themed[#UI.themed + 1] = { obj = footer, prop = "TextColor3", role = "dim" }
	UI.containers.footer = footer

	return {
		window = window,
		titleBar = titleBar,
		tabBar = tabBar,
		search = search,
		content = content,
		footer = footer,
		minButton = minButton,
		maxButton = maxButton,
		closeButton = closeButton,
	}
end

local function buildOverlays(ctx)
	local gui = UI.screen
	local hud = ensure(gui, "HUD", "Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1,
	})
	hud.Active = false
	local effects = ensure(gui, "Effects", "Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
	})
	effects.Active = false
	local notifications = ensure(gui, "Notifications", "Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 0, 160),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 10,
	})
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, notifications)
	local openButton = ensure(gui, "OpenButton", "TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = UI.theme.panel,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.Code,
		TextSize = 20,
		TextColor3 = UI.theme.accent,
		Text = "H",
		Visible = false,
		ZIndex = 11,
	})
	corner(openButton, 23)
	stroke(openButton, UI.theme.border, 1, 0.2)
	themeColor(openButton, "BackgroundColor3", "panel")
	UI.themed[#UI.themed + 1] = { obj = openButton, prop = "TextColor3", role = "accent" }
	openButton.MouseButton1Click:Connect(function()
		UI.show()
	end)

	local attackButton = ensure(gui, "AttackButton", "TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(86, 86),
		BackgroundColor3 = UI.theme.accent3,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.Code,
		TextSize = 18,
		TextColor3 = UI.theme.text,
		Text = "HIT",
		Visible = IsTouch,
		ZIndex = 11,
	})
	corner(attackButton, 43)
	stroke(attackButton, UI.theme.accent3, 2, 0.1)
	attackButton.MouseButton1Click:Connect(function()
		UI.click()
		if UI.ctx then
			UI.ctx.dispatch("attack", true)
		end
	end)

	UI.containers.hud = hud
	UI.containers.effects = effects
	UI.containers.notifications = notifications
	UI.containers.openButton = openButton
	UI.containers.attackButton = attackButton
end

----------------------------------------------------------------------
-- window behaviour
----------------------------------------------------------------------
local function setWindowVisible(visible)
	UI.open = visible
	UI.window.Visible = visible
	UI.containers.openButton.Visible = not visible
end

local function minimize()
	UI.minimized = not UI.minimized
	if UI.minimized then
		UI.normalSize = UI.window.Size
		UI.window.Size = UDim2.new(UI.normalSize.X.Scale, UI.normalSize.X.Offset, 0, 34)
	else
		UI.window.Size = UI.normalSize or UDim2.fromScale(0.66, 0.74)
	end
	for _, child in ipairs(UI.window:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "TitleBar" and child.Name ~= "UIScale" then
			child.Visible = not UI.minimized
		end
	end
	UI.click()
end

local function maximize()
	UI.maximized = not UI.maximized
	if UI.maximized then
		UI.normalSize = UI.window.Size
		tween(UI.window, 0.18, {
			Size = UDim2.fromScale(0.97, 0.94),
			Position = UDim2.fromScale(0.5, 0.5),
		})
	else
		tween(UI.window, 0.18, {
			Size = UI.normalSize or UDim2.fromScale(0.66, 0.74),
			Position = UDim2.fromScale(0.5, 0.5),
		})
	end
	UI.click()
end

local function bindDrag(titleBar)
	local dragging = false
	local startInput = nil
	local startPosition = nil

	titleBar.InputBegan:Connect(function(input)
		if not isClick(input) then
			return
		end
		local target = input.Target
		if target and target:IsA("TextButton") then
			return
		end
		dragging = true
		startInput = input.Position
		startPosition = UI.window.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local delta = input.Position - startInput
		local newX = startPosition.X.Offset + delta.X
		local newY = startPosition.Y.Offset + delta.Y
		UI.window.Position = UDim2.new(startPosition.X.Scale, newX, startPosition.Y.Scale, newY)
	end)
end

function UI.show()
	UI.window.Visible = true
	UI.containers.openButton.Visible = false
	UI.open = true
end

function UI.hide()
	UI.window.Visible = false
	UI.containers.openButton.Visible = true
	UI.open = false
end

function UI.toggle()
	if UI.window.Visible then
		UI.hide()
	else
		UI.show()
	end
end

function UI.setInfo(id, text, kind)
	local widget = UI.widgets[id]
	if widget and widget.kind == "info" then
		widget.set(text, kind)
	end
end

function UI.setToggle(id, value)
	local widget = UI.widgets[id]
	if widget and widget.kind == "toggle" then
		widget.set(value, true)
	end
end

function UI.setSlider(id, value)
	local widget = UI.widgets[id]
	if widget and widget.kind == "slider" then
		widget.set(value)
	end
end

function UI.setStats(kills, deaths, score)
	local widget = UI.widgets["stats_your"]
	if widget and widget.kind == "stats" then
		widget.set(kills, deaths, score)
	end
end

function UI.applyTheme(themeId)
	local chosen = Config.Themes[themeId] or Config.Themes.matrix
	UI.themeId = themeId
	UI.theme = chosen
	THEME = chosen
	local alive = {}
	for _, entry in ipairs(UI.themed) do
		if entry.obj and entry.obj.Parent then
			entry.obj[entry.prop] = chosen[entry.role]
			alive[#alive + 1] = entry
		end
	end
	UI.themed = alive
	setTab(activeTab)
end

function UI.setScale(scale)
	UI.scale = scale
	local windowScale = UI.window and UI.window:FindFirstChild("UIScale")
	if windowScale then
		windowScale.Scale = scale
	end
	if UI.containers.hud then
		local hudScale = UI.containers.hud:FindFirstChild("UIScale") or Instance.new("UIScale")
		hudScale.Parent = UI.containers.hud
		hudScale.Scale = scale
	end
end

function UI.setAbilityCooldown(key, remaining, total)
	if not key then
		return
	end
	UI.cooldowns[key] = {
		untilTime = os.clock() + math.max(0, remaining),
		total = math.max(tonumber(total) or 1, 0.1),
	}
end

----------------------------------------------------------------------
-- init
----------------------------------------------------------------------
local function buildPages(content)
	for _, tab in ipairs(Features.Tabs) do
		local page = make("ScrollingFrame", {
			Name = "Page_" .. tab.id,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = UI.theme.accent,
			CanvasSize = UDim2.new(1, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Visible = tab.id == activeTab,
		}, content)
		make("UIListLayout", {
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, page)
		make("UIPadding", {
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 4),
		}, page)
		pages[tab.id] = page
	end
end

function UI.Init(ctx)
	UI.ctx = ctx
	local settings = ctx.modules.Settings
	UI.theme = Config.Themes[settings.get("theme")] or Config.Themes.matrix
	UI.themeId = settings.get("theme")

	local chrome = buildWindow(ctx)
	buildOverlays(ctx)
	buildPages(chrome.content)

	for _, tab in ipairs(Features.Tabs) do
		local button = make("TextButton", {
			Size = UDim2.fromOffset(88, 28),
			BackgroundColor3 = UI.theme.panelAlt,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Enum.Font.Code,
			TextSize = 12,
			TextColor3 = UI.theme.dim,
			Text = tab.label,
			LayoutOrder = 1,
		}, chrome.tabBar)
		corner(button, 4)
		UI.themed[#UI.themed + 1] = { obj = button, prop = "BackgroundColor3", role = "panelAlt" }
		local underline = make("Frame", {
			Name = "Underline",
			Size = UDim2.new(1, -8, 0, 2),
			Position = UDim2.new(0, 4, 1, -3),
			BackgroundColor3 = UI.theme.accent,
			BorderSizePixel = 0,
			Visible = false,
		}, button)
		UI.themed[#UI.themed + 1] = { obj = underline, prop = "BackgroundColor3", role = "accent" }
		button.MouseButton1Click:Connect(function()
			setTab(tab.id)
			applySearch(chrome.search.Text)
		end)
		tabButtons[tab.id] = button
	end

	for _, tab in ipairs(Features.Tabs) do
		local page = pages[tab.id]
		local order = 0
		for _, feature in ipairs(Features.Rows) do
			if feature.tab == tab.id then
				order = order + 1
				if feature.kind == "header" then
					buildHeader(page, feature, order)
				elseif feature.kind == "toggle" then
					buildToggle(page, feature, order)
				elseif feature.kind == "slider" then
					buildSlider(page, feature, order)
				elseif feature.kind == "button" then
					buildButton(page, feature, order)
				elseif feature.kind == "cycle" then
					buildCycle(page, feature, order)
				elseif feature.kind == "keybind" then
					buildKeybind(page, feature, order)
				elseif feature.kind == "info" then
					buildInfo(page, feature, order)
				elseif feature.kind == "stats" then
					buildStats(page, feature, order)
				elseif feature.kind == "playerlist" or feature.kind == "waypoints" or feature.kind == "history" then
					buildList(page, feature, order)
				end
			end
		end
	end

	setTab(activeTab)
	chrome.search:GetPropertyChangedSignal("Text"):Connect(function()
		applySearch(chrome.search.Text)
	end)

	chrome.minButton.MouseButton1Click:Connect(minimize)
	chrome.maxButton.MouseButton1Click:Connect(maximize)
	chrome.closeButton.MouseButton1Click:Connect(function()
		UI.hide()
		UI.click()
	end)
	bindDrag(chrome.titleBar)

	-- window toggle key + keybind capture
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if UI.listeningKey then
			if input.KeyCode == Enum.KeyCode.Escape then
				UI.listeningKey = false
				local widget = UI.widgets["keybind"]
				if widget and widget.cancel then
					widget.cancel()
				end
				return
			end
			UI.listeningKey = false
			UI.ctx.dispatch("keybind", input.KeyCode.Name)
			return
		end
		local bindName = tostring(UI.ctx.modules.Settings.get("keybind"))
		if input.KeyCode.Name == bindName then
			UI.toggle()
		end
	end)

	-- cooldown ticker for ability buttons
	task.spawn(function()
		while true do
			task.wait(0.1)
			if UI.window and UI.window.Parent then
				for key, entry in pairs(UI.cooldowns) do
					local remaining = entry.untilTime - os.clock()
					for _, widget in pairs(UI.widgets) do
						if widget.kind == "button" and widget.cooldownKey == key then
							local ratio = math.clamp(remaining / entry.total, 0, 1)
							widget.bar.Size = UDim2.new(ratio, 0, 0, 3)
							if remaining > 0.05 then
								widget.button.Text = string.format("%s  (%.1fs)", widget.label, remaining)
							else
								widget.button.Text = widget.label
							end
						end
					end
					if remaining <= 0 then
						UI.cooldowns[key] = nil
					end
				end
			end
		end
	end)

	UI.applyTheme(settings.get("theme"))
	UI.setScale(settings.get("uiscale") or 1)
	UI.widgets["keybind"]:set(settings.get("keybind"))
	UI.setInfo("data_status", ctx.modules.Settings.persistent and "Cloud save ON" or "Studio API OFF", ctx.modules.Settings.persistent and "success" or "warn")

	UI.silent = false
	ctx.ui = UI
	return UI
end

return UI
]===],
	["client/HUD"] = [===[
--[[
	HUD (ModuleScript)
	Location: StarterPlayer/StarterPlayerScripts/HackerFight/Modules/HUD

	Everything drawn outside the main window: match banner + timer, health bar,
	kill feed, ability cooldowns, crosshair and target readout. Purely visual -
	the server owns all of the numbers shown here.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local root = ReplicatedStorage:WaitForChild("HackerFight")
local Config = require(root:WaitForChild("Config"))
local Util = require(root:WaitForChild("Util"))

local HUD = {}

local ctx = nil
local ui = nil
local elements = {}
local cooldownEnds = {}
local killLines = {}
local IsTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function themed(object, property, role)
	ui.themed[#ui.themed + 1] = { obj = object, prop = property, role = role }
	object[property] = ui.theme[role]
end

local function corner(object, radius)
	local uiCorner = object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, radius or 4)
	uiCorner.Parent = object
end

local function buildMatchBanner(container)
	local frame = make("Frame", {
		Name = "MatchBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(330, 58),
		BackgroundColor3 = ui.theme.bg,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	}, container)
	corner(frame, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = ui.theme.border
	stroke.Transparency = 0.2
	stroke.Thickness = 1
	stroke.Parent = frame
	themed(frame, "BackgroundColor3", "bg")
	ui.themed[#ui.themed + 1] = { obj = stroke, prop = "Color", role = "border" }

	local mode = make("TextLabel", {
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0, 8, 0, 5),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "FREE-FOR-ALL",
	}, frame)
	themed(mode, "TextColor3", "accent")

	local timer = make("TextLabel", {
		Size = UDim2.new(0, 70, 0, 20),
		Position = UDim2.new(1, -78, 0, 5),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "2:30",
	}, frame)
	themed(timer, "TextColor3", "accent2")

	local score = make("TextLabel", {
		Size = UDim2.new(1, -16, 0, 24),
		Position = UDim2.new(0, 8, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Waiting for round...",
	}, frame)
	themed(score, "TextColor3", "dim")

	elements.mode = mode
	elements.timer = timer
	elements.score = score
	elements.banner = frame
end

local function buildHealth(container)
	local frame = make("Frame", {
		Name = "HealthBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(280, 30),
		BackgroundColor3 = ui.theme.bg,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
	}, container)
	corner(frame, 6)
	themed(frame, "BackgroundColor3", "bg")
	local fill = make("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = ui.theme.accent,
		BorderSizePixel = 0,
	}, frame)
	corner(fill, 6)
	themed(fill, "BackgroundColor3", "accent")
	local text = make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 13,
		Text = "100 / 100 HP",
	}, frame)
	themed(text, "TextColor3", "text")
	elements.healthFill = fill
	elements.healthText = text
	elements.healthFrame = frame
end

local function buildStats(container)
	local frame = make("Frame", {
		Name = "MiniStats",
		Position = UDim2.new(0, 14, 0, 12),
		Size = UDim2.fromOffset(140, 54),
		BackgroundColor3 = ui.theme.bg,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, container)
	corner(frame, 6)
	themed(frame, "BackgroundColor3", "bg")
	local text = make("TextLabel", {
		Size = UDim2.new(1, -12, 1, -8),
		Position = UDim2.new(0, 8, 0, 4),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "KILLS 0\nDEATHS 0\nSCORE 0",
	}, frame)
	themed(text, "TextColor3", "text")
	elements.stats = text
end

local function buildKillFeed(container)
	local frame = make("Frame", {
		Name = "KillFeed",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -58),
		Size = UDim2.fromOffset(300, 128),
		BackgroundTransparency = 1,
	}, container)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame)
	elements.killFeed = frame
end

local function buildCooldowns(container)
	local frame = make("Frame", {
		Name = "Cooldowns",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 12),
		Size = UDim2.fromOffset(150, 196),
		BackgroundTransparency = 1,
	}, container)
	make("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame)
	elements.chips = {}
	local order = 0
	for key in pairs(Config.Abilities) do
		order = order + 1
		local chip = make("Frame", {
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundColor3 = ui.theme.bg,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			LayoutOrder = order,
		}, frame)
		corner(chip, 3)
		themed(chip, "BackgroundColor3", "bg")
		local label = make("TextLabel", {
			Size = UDim2.new(1, -8, 1, 0),
			Position = UDim2.new(0, 6, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Code,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.upper(key),
		}, chip)
		themed(label, "TextColor3", "dim")
		elements.chips[key] = { frame = chip, label = label }
		cooldownEnds[key] = 0
	end
end

local function buildCrosshair(effects)
	local holder = make("Frame", {
		Name = "Crosshair",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
	}, effects)
	elements.crosshair = holder
	local lines = {}
	for index = 1, 4 do
		local line = make("Frame", {
			BackgroundColor3 = ui.theme.accent,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(2, 9),
			Position = UDim2.new(0.5, -1, 0.5, -4.5),
		}, holder)
		themed(line, "BackgroundColor3", "accent")
		lines[index] = line
	end
	lines[1].Position = UDim2.new(0.5, -1, 0, 0)
	lines[2].Position = UDim2.new(0.5, -1, 1, -9)
	lines[3].Position = UDim2.new(0, 0, 0.5, -4.5)
	lines[3].Size = UDim2.fromOffset(9, 2)
	lines[4].Position = UDim2.new(1, -9, 0.5, -4.5)
	lines[4].Size = UDim2.fromOffset(9, 2)
	local dot = make("Frame", {
		BackgroundColor3 = ui.theme.accent2,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(3, 3),
	}, holder)
	corner(dot, 2)
	themed(dot, "BackgroundColor3", "accent2")

	local target = make("TextLabel", {
		Size = UDim2.new(0, 320, 0, 18),
		Position = UDim2.new(0.5, -160, 1, 10),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 11,
		Text = "",
	}, holder)
	themed(target, "TextColor3", "danger")
	elements.targetLabel = target
end

local function addKillLine(text)
	local frame = make("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundColor3 = ui.theme.bg,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, elements.killFeed)
	corner(frame, 3)
	local label = make("TextLabel", {
		Size = UDim2.new(1, -8, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	}, frame)
	themed(label, "TextColor3", "text")
	killLines[#killLines + 1] = frame
	while #killLines > 5 do
		local oldest = table.remove(killLines, 1)
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end
	task.delay(6, function()
		if frame and frame.Parent then
			local fade = TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
			fade:Play()
			local textFade = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 })
			textFade:Play()
			task.wait(0.45)
			if frame and frame.Parent then
				frame:Destroy()
			end
		end
	end)
end

local function watchHealth(character)
	local humanoid = character and character:WaitForChild("Humanoid", 8)
	if not humanoid then
		return
	end
	local function render()
		local maxHealth = math.max(1, humanoid.MaxHealth)
		local ratio = math.clamp(humanoid.Health / maxHealth, 0, 1)
		if elements.healthFill then
			elements.healthFill.Size = UDim2.fromScale(ratio, 1)
			elements.healthFill.BackgroundColor3 = ratio > 0.5 and ui.theme.accent or (ratio > 0.25 and ui.theme.accent2 or ui.theme.danger)
		end
		if elements.healthText then
			elements.healthText.Text = string.format("%d / %d HP", math.floor(humanoid.Health), math.floor(maxHealth))
		end
	end
	humanoid.HealthChanged:Connect(render)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(render)
	render()
end

function HUD.Init(context)
	ctx = context
	ui = context.ui
	local hud = ui.containers.hud
	local effects = ui.containers.effects

	buildMatchBanner(hud)
	buildHealth(hud)
	buildStats(hud)
	buildKillFeed(hud)
	buildCooldowns(hud)
	buildCrosshair(effects)

	if IsTouch then
		elements.crosshair.Visible = false
	end

	local player = Players.LocalPlayer
	if player.Character then
		watchHealth(player.Character)
	end
	player.CharacterAdded:Connect(watchHealth)

	-- attack feedback from the server (own hits are rate limited so the feed
	-- stays readable while kill aura is running)
	local fx = context.remotes.event("CombatFX")
	local lastOwnHit = 0
	if fx then
		fx.OnClientEvent:Connect(function(attackerName, targetName, kind)
			if targetName == player.Name then
				addKillLine("! " .. tostring(attackerName) .. " HIT YOU")
			elseif attackerName == player.Name and os.clock() - lastOwnHit > 1.2 then
				lastOwnHit = os.clock()
				addKillLine("> HIT " .. tostring(targetName))
			end
		end)
	end

	local feed = context.remotes.event("KillFeed")
	if feed then
		feed.OnClientEvent:Connect(function(killerName, victimName)
			if context.modules.Settings.get("killfeed") ~= true then
				return
			end
			addKillLine(string.format("%s  >>  %s", tostring(killerName), tostring(victimName)))
		end)
	end

	task.spawn(function()
		while true do
			task.wait(0.2)
			for key, chip in pairs(elements.chips) do
				local remaining = (cooldownEnds[key] or 0) - os.clock()
				if remaining > 0 then
					chip.label.Text = string.upper(key) .. "  " .. string.format("%.1fs", remaining)
					chip.label.TextColor3 = ui.theme.danger
				else
					chip.label.Text = string.upper(key) .. "  READY"
					chip.label.TextColor3 = ui.theme.dim
				end
			end
			if elements.crosshair then
				elements.crosshair.Visible = context.modules.Settings.get("crosshair") == true
					and not IsTouch
					and not (ui.open == true)
			end
		end
	end)
end

function HUD.setRound(state)
	if type(state) ~= "table" or not elements.mode then
		return
	end
	elements.mode.Text = string.upper(tostring(state.modeName or "Free-for-All"))
	elements.timer.Text = Util.formatTime(state.timeLeft or 0)
	local parts = {}
	if state.phase == "Intermission" then
		parts[#parts + 1] = "NEXT ROUND IN " .. Util.formatTime(state.timeLeft or 0)
	elseif state.phase == "Post" then
		parts[#parts + 1] = "ROUND OVER"
	else
		parts[#parts + 1] = "ROUND " .. tostring(state.roundNumber or 1)
	end
	if state.teamBased then
		local scores = state.scores or {}
		local keys = {}
		for key in pairs(scores) do
			keys[#keys + 1] = key
		end
		table.sort(keys)
		for _, key in ipairs(keys) do
			if key ~= "ffa" then
				parts[#parts + 1] = string.upper(tostring(key)) .. ": " .. tostring(scores[key])
			end
		end
	else
		parts[#parts + 1] = "FIRST TO " .. tostring(state.scoreToWin or 25) .. " KILLS"
	end
	elements.score.Text = table.concat(parts, "   |   ")
end

function HUD.setCooldown(key, remaining, total)
	if not key then
		return
	end
	cooldownEnds[key] = os.clock() + math.max(0, remaining)
	if ui then
		ui.setAbilityCooldown(key, remaining, total)
	end
end

function HUD.setTarget(name, distance)
	if not elements.targetLabel then
		return
	end
	if name then
		elements.targetLabel.Text = string.format("LOCK: %s  [%d studs]", tostring(name), math.floor(distance or 0))
		elements.targetLabel.TextColor3 = ui.theme.accent2
	else
		elements.targetLabel.Text = ""
	end
end

function HUD.setStats(kills, deaths, score)
	if elements.stats then
		elements.stats.Text = string.format("KILLS %d\nDEATHS %d\nSCORE %d", kills or 0, deaths or 0, score or 0)
	end
end

function HUD.notifyCombat(text)
	addKillLine(text)
end

return HUD
]===],
	["client/Abilities"] = [===[
--[[
	Abilities (ModuleScript)
	Location: StarterPlayer/StarterPlayerScripts/HackerFight/Modules/Abilities

	Client half of the movement system. Roblox always lets a character's owner
	drive movement, so the client applies flight and air jumps - but only after
	the server grants them (AbilityState). Speed, jump power, collisions and
	dash are applied by the server and simply mirrored here.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local root = ReplicatedStorage:WaitForChild("HackerFight")
local Config = require(root:WaitForChild("Config"))
local Remotes = require(root:WaitForChild("Remotes"))

local Abilities = {}

local ctx = nil
local player = nil
local flying = false
local flyRig = nil
local usedDoubleJump = false
local lastStep = 0
local airJumpPending = false
local antiKnockUntil = 0

local function settingsModule()
	return ctx.modules.Settings
end

local function humanoid()
	if not player.Character then
		return nil
	end
	return player.Character:FindFirstChildOfClass("Humanoid")
end

local function characterRoot()
	if not player.Character then
		return nil
	end
	return player.Character:FindFirstChild("HumanoidRootPart")
end

local function destroyFlyRig()
	if flyRig then
		for _, instance in pairs(flyRig) do
			if instance and instance.Parent then
				instance:Destroy()
			end
		end
		flyRig = nil
	end
end

local function createFlyRig()
	local hrp = characterRoot()
	if not hrp then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "HackerFlyAttachment"
	attachment.Parent = hrp

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Attachment0 = attachment
	alignPosition.Position = hrp.Position
	alignPosition.MaxForce = 200000
	alignPosition.Responsiveness = 30
	alignPosition.ApplyAtCenterOfMass = true
	alignPosition.Parent = hrp

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.MaxTorque = 200000
	alignOrientation.Responsiveness = 30
	alignOrientation.Parent = hrp

	flyRig = { position = alignPosition, orientation = alignOrientation, attachment = attachment }
end

local function setFlying(enabled)
	local hum = humanoid()
	if enabled then
		if flying or not hum then
			return
		end
		flying = true
		hum.PlatformStand = true
		createFlyRig()
		if ctx.notify then
			ctx.notify("Flight engaged (WASD + Space / Ctrl)", "success")
		end
	else
		if not flying then
			return
		end
		flying = false
		destroyFlyRig()
		if hum then
			hum.PlatformStand = false
		end
		local remote = Remotes.event("Ability")
		if remote then
			remote:FireServer("sync")
		end
		if ctx.notify then
			ctx.notify("Flight disengaged", "info")
		end
	end
	if ctx.ui then
		ctx.ui.setToggle("fly", flying)
	end
	settingsModule().values.fly = flying
end

local function applyAirJump()
	local hum = humanoid()
	local hrp = characterRoot()
	if not hum or not hrp then
		airJumpPending = false
		return
	end
	local power = tonumber(settingsModule().get("jump")) or Config.MinJumpPower
	local velocity = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, math.max(velocity.Y, power * 0.85), velocity.Z)
	airJumpPending = false
end

local function requestAirJump(kind)
	if airJumpPending then
		return
	end
	local remote = Remotes.event("Ability")
	if remote then
		airJumpPending = true
		remote:FireServer("airjump", kind)
		task.delay(0.6, function()
			airJumpPending = false
		end)
	end
end

local function isAirborne(hum)
	local state = hum:GetState()
	return state == Enum.HumanoidStateType.Freefall
		or state == Enum.HumanoidStateType.Jumping
		or state == Enum.HumanoidStateType.Flying
end

local function onJumpRequest()
	local hum = humanoid()
	if not hum or hum.Health <= 0 then
		return
	end
	if not isAirborne(hum) then
		return
	end
	local settings = settingsModule()
	if settings.get("doublejump") == true and not usedDoubleJump then
		usedDoubleJump = true
		requestAirJump("doublejump")
	elseif settings.get("infjump") == true then
		requestAirJump("infjump")
	end
end

local function updateFly(delta)
	if not flying or not flyRig then
		return
	end
	local hrp = characterRoot()
	local hum = humanoid()
	if not hrp or not hum then
		setFlying(false)
		return
	end
	local camera = workspace.CurrentCamera
	local move = hum.MoveDirection
	local horizontal = Vector3.new(move.X, 0, move.Z)
	local direction = horizontal
	if direction.Magnitude > 0.05 then
		direction = direction.Unit
	else
		direction = Vector3.new(0, 0, 0)
	end
	if camera then
		local forward = camera.CFrame.LookVector
		local right = camera.CFrame.RightVector
		if move.Magnitude > 0.05 then
			local flatCamera = Vector3.new(forward.X, 0, forward.Z).Unit
			local flatRight = Vector3.new(right.X, 0, right.Z).Unit
			direction = (flatCamera * -move.Z + flatRight * move.X)
			if direction.Magnitude > 1 then
				direction = direction.Unit
			end
		end
	end

	local vertical = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump then
		vertical = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		vertical = -1
	end

	local speed = tonumber(settingsModule().get("flyspeed")) or Config.FlySpeedDefault
	speed = math.clamp(speed, Config.FlySpeedMin, Config.FlySpeedMax)
	local step = math.clamp(delta or 0.016, 0.001, 0.1)
	local target = hrp.Position + (direction * speed + Vector3.new(0, vertical * speed, 0)) * step
	flyRig.position.Position = target
	flyRig.orientation.CFrame = CFrame.new(hrp.Position, hrp.Position + (camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1)))
	hum.WalkSpeed = 0
end

local function stepTpWalk()
	if settingsModule().get("tpwalk") ~= true then
		return
	end
	local hum = humanoid()
	if not hum or hum.MoveDirection.Magnitude < 0.1 then
		return
	end
	local remote = Remotes.event("Ability")
	if remote then
		remote:FireServer("tpwalk_step", hum.MoveDirection)
	end
end

local function resetForCharacter()
	flying = false
	destroyFlyRig()
	usedDoubleJump = false
	airJumpPending = false
	local remote = Remotes.event("Ability")
	if remote then
		task.delay(0.5, function()
			remote:FireServer("sync")
		end)
	end
	if ctx.ui then
		ctx.ui.setToggle("fly", false)
	end
end

local pendingAbility = {}
local abilityScheduled = {}

-- Sliders dispatch many times per second; coalesce them into one send per key.
local function sendAbility(kind, payload)
	pendingAbility[kind] = payload
	if abilityScheduled[kind] then
		return
	end
	abilityScheduled[kind] = true
	task.delay(0.1, function()
		abilityScheduled[kind] = false
		local value = pendingAbility[kind]
		pendingAbility[kind] = nil
		local remote = Remotes.event("Ability")
		if remote then
			remote:FireServer(kind, value)
		end
	end)
end

local handlers = {}

handlers.fly = function(value)
	local remote = Remotes.event("Ability")
	if remote then
		remote:FireServer("fly", value == true)
	end
end

handlers.flyspeed = function(value)
	settingsModule().apply("flyspeed", value, true)
	sendAbility("flyspeed", value)
end

handlers.speed = function(value)
	settingsModule().apply("speed", value, true)
	sendAbility("speed", value)
end

handlers.jump = function(value)
	settingsModule().apply("jump", value, true)
	sendAbility("jump", value)
end

handlers.tpwalk = function(value)
	settingsModule().apply("tpwalk", value, true)
	local remote = Remotes.event("Ability")
	if remote then
		remote:FireServer("tpwalk", value == true)
	end
end

handlers.noclip = function(value)
	settingsModule().apply("noclip", value, true)
	local remote = Remotes.event("Ability")
	if remote then
		remote:FireServer("noclip", value == true)
	end
end

handlers.infjump = function(value)
	settingsModule().apply("infjump", value, true)
end

handlers.doublejump = function(value)
	settingsModule().apply("doublejump", value, true)
end

handlers.dash = function()
	local remote = Remotes.event("Ability")
	if remote then
		remote:FireServer("dash")
	else
		return
	end
	ctx.hud.setCooldown("dash", Config.DashCooldown, Config.DashCooldown)
end

-- Defensive abilities are simple request buttons; the server decides whether
-- the cooldown is actually ready and reports back through AbilityState.
local function castAbility(ability)
	local remote = Remotes.event("Ability")
	if remote then
		remote:FireServer(ability)
	end
end

handlers.godmode = function()
	castAbility("godmode")
end

handlers.shield = function()
	castAbility("shield")
end

handlers.heal = function()
	castAbility("heal")
end

handlers.invis = function()
	castAbility("invis")
end

handlers.antiknock = function()
	castAbility("antiknock")
end

handlers.escape = function()
	castAbility("escape")
end

Abilities.handlers = handlers

function Abilities.Init(context)
	ctx = context
	player = Players.LocalPlayer

	local abilityState = Remotes.event("AbilityState")
	if abilityState then
		abilityState.OnClientEvent:Connect(function(ability, active, remaining, cooldown)
			if ability == "fly" then
				setFlying(active == true)
				if cooldown and cooldown > 0 then
					ctx.hud.setCooldown("fly", cooldown, Config.Abilities.fly.Cooldown)
				end
			elseif ability == "airjump" then
				applyAirJump()
			elseif ability == "noclip" then
				if active ~= true then
					settingsModule().values.noclip = false
					ctx.ui.setToggle("noclip", false)
				end
			elseif Config.Abilities[ability] then
				if cooldown and cooldown > 0 then
					ctx.hud.setCooldown(ability, cooldown, Config.Abilities[ability].Cooldown)
				end
				if ability == "antiknock" and active == true then
					antiKnockUntil = os.clock() + (remaining or Config.Abilities.antiknock.Duration)
				end
				if ctx.ui then
					if active == true then
						ctx.ui.setInfo("defense_status", string.upper(ability) .. (remaining and remaining > 0 and string.format(" %ds", math.floor(remaining)) or " active"), "success")
					else
						ctx.ui.setInfo("defense_status", "Ready", "accent")
					end
				end
			end
		end)
	end

	UserInputService.JumpRequest:Connect(onJumpRequest)

	player.CharacterAdded:Connect(function(character)
		resetForCharacter()
		task.wait(0.6)
		local hum = humanoid()
		if hum then
			hum.StateChanged:Connect(function(_, newState)
				if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
					usedDoubleJump = false
				end
			end)
		end
	end)

	if player.Character then
		local hum = humanoid()
		if hum then
			hum.StateChanged:Connect(function(_, newState)
				if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
					usedDoubleJump = false
				end
			end)
		end
	end

	RunService.Heartbeat:Connect(function(delta)
		if os.clock() < antiKnockUntil then
			local hrp = characterRoot()
			if hrp then
				local velocity = hrp.AssemblyLinearVelocity
				local flat = Vector3.new(velocity.X, 0, velocity.Z)
				if flat.Magnitude > 26 then
					local capped = flat.Unit * 26
					hrp.AssemblyLinearVelocity = Vector3.new(capped.X, velocity.Y, capped.Z)
				end
			end
		end
		if flying then
			local ok, err = pcall(updateFly, delta)
			if not ok then
				warn("[HackerFight][Fly] " .. tostring(err))
				setFlying(false)
			end
		else
			local now = os.clock()
			if now - lastStep >= Config.TpWalkClientDelay then
				lastStep = now
				stepTpWalk()
			end
		end
	end)
end

return Abilities
]===],
	["client/Combat"] = [===[
--[[
	Combat (ModuleScript)
	Location: StarterPlayer/StarterPlayerScripts/HackerFight/Modules/Combat

	Client half of combat. It picks candidates and sends "attack" requests.
	Damage, reach, teams, cooldowns and spawn protection are all re-checked by
	the server, so nothing here can deal damage the server did not allow.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local root = ReplicatedStorage:WaitForChild("HackerFight")
local Config = require(root:WaitForChild("Config"))
local Util = require(root:WaitForChild("Util"))
local Remotes = require(root:WaitForChild("Remotes"))

local Combat = {}

local ctx = nil
local player = nil
local selectedTarget = nil
local nextAttackAt = 0
local aimTarget = nil
local aimCheckAt = 0
local originalCameraType = nil
local toolConnections = {}

local function settingsModule()
	return ctx.modules.Settings
end

local function isEnemy(other)
	if other == player then
		return false
	end
	if player.Team and other.Team then
		return player.Team ~= other.Team
	end
	return true
end

local function rootOf(other)
	return Util.getRoot(other)
end

local function teamFilterAllows(other)
	local filter = settingsModule().get("teamfilter")
	local enemy = isEnemy(other)
	if filter == "enemies" then
		return enemy
	elseif filter == "allies" then
		return not enemy
	end
	return true
end

local function nearestEnemy(maxDistance)
	local myRoot = rootOf(player)
	if not myRoot then
		return nil, math.huge
	end
	local best, bestDistance = nil, math.huge
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and Util.isAlive(other) then
			local otherRoot = rootOf(other)
			if otherRoot then
				local distance = (otherRoot.Position - myRoot.Position).Magnitude
				if distance < bestDistance and (not maxDistance or distance <= maxDistance) then
					best, bestDistance = other, distance
				end
			end
		end
	end
	return best, bestDistance
end

local function selectedPlayer()
	if not selectedTarget then
		return nil
	end
	local other = Util.findPlayerByName(selectedTarget)
	if other and Util.isAlive(other) then
		return other
	end
	return nil
end

local function canAttack()
	if settingsModule().get("combatenabled") ~= true then
		return false
	end
	if not Util.isAlive(player) then
		return false
	end
	return true
end

local function sendAttack(targetName)
	local now = os.clock()
	if now < nextAttackAt then
		return
	end
	nextAttackAt = now + Config.AttackCooldown
	local remote = Remotes.event("Attack")
	if remote then
		remote:FireServer(targetName)
	end
end

function Combat.attack()
	if not canAttack() then
		if ctx.notify then
			ctx.notify("Combat is disabled", "warn")
		end
		return
	end
	local chosen = selectedPlayer()
	if not chosen then
		chosen = nearestEnemy(Config.MaxReach + 4)
	end
	sendAttack(chosen and chosen.Name or nil)
end

local function lockCamera(target)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if originalCameraType == nil then
		originalCameraType = camera.CameraType
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local targetRoot = target and target.Character and target.Character:FindFirstChild("Head")
	if not targetRoot then
		return
	end
	local myRoot = rootOf(player)
	if not myRoot then
		return
	end
	local look = CFrame.lookAt(camera.CFrame.Position, targetRoot.Position)
	camera.CFrame = camera.CFrame:Lerp(look, 0.22)
	if myRoot then
		local flat = Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z)
		if (flat - myRoot.Position).Magnitude > 0.5 then
			myRoot.CFrame = CFrame.lookAt(myRoot.Position, flat)
		end
	end
end

local function releaseCamera()
	local camera = workspace.CurrentCamera
	if camera and originalCameraType then
		camera.CameraType = originalCameraType
	end
	originalCameraType = nil
end

local handlers = {}

handlers.killaura = function(value)
	settingsModule().apply("killaura", value, true)
end

handlers.autoattack = function(value)
	settingsModule().apply("autoattack", value, true)
end

handlers.aimbot = function(value)
	settingsModule().apply("aimbot", value, true)
	if value ~= true then
		releaseCamera()
	end
end

handlers.combatenabled = function(value)
	settingsModule().apply("combatenabled", value, true)
	if value ~= true and ctx.ui then
		ctx.ui.setInfo("combat_status", "Offline", "warn")
	end
end

handlers.reach = function(value)
	settingsModule().apply("reach", value, true)
end

handlers.dmgmult = function(value)
	settingsModule().apply("dmgmult", value, true)
end

handlers.attack = function()
	Combat.attack()
end

Combat.handlers = handlers

function Combat.setTarget(name)
	selectedTarget = name
	if ctx.hud then
		ctx.hud.setTarget(name, 0)
	end
	if ctx.notify then
		ctx.notify("Target locked: " .. tostring(name), "success")
	end
	if ctx.ui then
		ctx.ui.setInfo("combat_status", "Target: " .. tostring(name), "accent")
	end
end

function Combat.getSelected()
	return selectedTarget
end

function Combat.Init(context)
	ctx = context
	player = Players.LocalPlayer

	local function bindTool(tool)
		if not tool:IsA("Tool") then
			return
		end
		local connection = tool.Activated:Connect(function()
			Combat.attack()
		end)
		toolConnections[tool] = connection
	end

	local function bindCharacter(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				bindTool(child)
			end
		end)
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				bindTool(child)
			end
		end
	end

	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		bindCharacter(player.Character)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			Combat.attack()
		elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.E then
			Combat.attack()
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.2)
			if settingsModule().get("killaura") == true and canAttack() then
				local target, distance = nearestEnemy(settingsModule().get("reach") or Config.DefaultReach)
				if target and distance <= (settingsModule().get("reach") or Config.DefaultReach) then
					sendAttack(target.Name)
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.AttackCooldown)
			if settingsModule().get("autoattack") == true and canAttack() then
				local target, distance = nearestEnemy(settingsModule().get("reach") or Config.DefaultReach)
				if target and distance <= (settingsModule().get("reach") or Config.DefaultReach) then
					sendAttack(target.Name)
				end
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		local enabled = settingsModule().get("aimbot") == true
		if not enabled then
			if originalCameraType ~= nil then
				releaseCamera()
			end
			return
		end
		local now = os.clock()
		if now - aimCheckAt > 0.35 then
			aimCheckAt = now
			aimTarget = selectedPlayer() or nearestEnemy(Config.TargetLockRange)
			if ctx.hud then
				if aimTarget then
					local myRoot = rootOf(player)
					local otherRoot = aimTarget.Character and aimTarget.Character:FindFirstChild("HumanoidRootPart")
					local distance = 0
					if myRoot and otherRoot then
						distance = (myRoot.Position - otherRoot.Position).Magnitude
					end
					ctx.hud.setTarget(aimTarget.DisplayName, distance)
				else
					ctx.hud.setTarget(nil)
				end
			end
		end
		lockCamera(aimTarget)
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			if ctx.ui then
				if settingsModule().get("combatenabled") == true then
					ctx.ui.setInfo(
						"combat_status",
						string.format("KA %s | AA %s | DMG %.2fx", settingsModule().get("killaura") and "ON" or "off", settingsModule().get("autoattack") and "ON" or "off", settingsModule().get("dmgmult") or 1),
						"success"
					)
				end
			end
		end
	end)
end

return Combat
]===],
	["client/Visuals"] = [===[
--[[
	Visuals (ModuleScript)
	Location: StarterPlayer/StarterPlayerScripts/HackerFight/Modules/Visuals

	Client-only ESP built from real Roblox instances (Highlight, SelectionBox,
	BillboardGui and ScreenGui lines). Nothing here changes gameplay state; the
	server is not told what you can see, and invisible players stay hidden.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = ReplicatedStorage:WaitForChild("HackerFight")
local Util = require(root:WaitForChild("Util"))

local Visuals = {}

local ctx = nil
local player = nil
local espFolder = nil
local cache = {}
local updateAt = 0

local TEAM_COLORS = {
	{ enemy = Color3.fromRGB(255, 70, 90), ally = Color3.fromRGB(0, 255, 140) },
	{ enemy = Color3.fromRGB(180, 90, 255), ally = Color3.fromRGB(0, 220, 255) },
	{ enemy = Color3.fromRGB(255, 150, 40), ally = Color3.fromRGB(70, 150, 255) },
	{ enemy = Color3.fromRGB(255, 70, 200), ally = Color3.fromRGB(160, 255, 70) },
}

local function settings()
	return ctx.modules.Settings
end

local function isEnemy(other)
	if player.Team and other.Team then
		return player.Team ~= other.Team
	end
	return true
end

local function colorsFor(other)
	local preset = TEAM_COLORS[math.clamp(settings().get("colorpreset") or 1, 1, #TEAM_COLORS)]
	if isEnemy(other) then
		return preset.enemy
	end
	return preset.ally
end

local function visibleByFilter(other)
	local filter = settings().get("teamfilter")
	if filter == "enemies" then
		return isEnemy(other)
	elseif filter == "allies" then
		return not isEnemy(other)
	end
	return true
end

local function visibleByLineOfSight(other)
	if settings().get("loscheck") ~= true then
		return true
	end
	local camera = workspace.CurrentCamera
	local character = other.Character
	local head = character and character:FindFirstChild("Head")
	if not camera or not head then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { character }
	if player.Character then
		ignore[#ignore + 1] = player.Character
	end
	params.FilterDescendantsInstances = ignore
	local result = workspace:Raycast(camera.CFrame.Position, head.Position - camera.CFrame.Position, params)
	return result == nil
end

local function createEsp(other)
	local entry = {
		highlight = nil,
		box = nil,
		billboard = nil,
		nameLabel = nil,
		distanceLabel = nil,
		healthBack = nil,
		healthFill = nil,
		skeleton = {},
		tracer = nil,
	}

	local highlight = Instance.new("Highlight")
	highlight.Name = "HF_ESP_" .. other.Name
	highlight.FillColor = colorsFor(other)
	highlight.FillTransparency = 0.72
	highlight.OutlineColor = colorsFor(other)
	highlight.OutlineTransparency = 0.15
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = other.Character
	highlight.Parent = espFolder
	entry.highlight = highlight

	local box = Instance.new("SelectionBox")
	box.Name = "HF_BOX_" .. other.Name
	box.Adornee = other.Character
	box.LineThickness = 0.045
	box.SurfaceTransparency = 1
	box.Color3 = colorsFor(other)
	box.Parent = workspace.CurrentCamera
	entry.box = box

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HF_TAG_" .. other.Name
	billboard.Size = UDim2.fromOffset(180, 62)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 600
	billboard.Parent = other.Character
	entry.billboard = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.Font = Enum.Font.Code
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = colorsFor(other)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Text = other.DisplayName
	nameLabel.Parent = billboard
	entry.nameLabel = nameLabel

	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Size = UDim2.new(1, 0, 0, 14)
	distanceLabel.Position = UDim2.new(0, 0, 0, 18)
	distanceLabel.Font = Enum.Font.Code
	distanceLabel.TextSize = 11
	distanceLabel.TextColor3 = Color3.fromRGB(220, 240, 230)
	distanceLabel.TextStrokeTransparency = 0.5
	distanceLabel.Text = "0m"
	distanceLabel.Parent = billboard
	entry.distanceLabel = distanceLabel

	local healthBack = Instance.new("Frame")
	healthBack.BackgroundColor3 = Color3.fromRGB(15, 20, 18)
	healthBack.BackgroundTransparency = 0.25
	healthBack.BorderSizePixel = 0
	healthBack.Size = UDim2.new(0.8, 0, 0, 5)
	healthBack.Position = UDim2.new(0.1, 0, 0, 36)
	healthBack.Parent = billboard
	entry.healthBack = healthBack

	local healthFill = Instance.new("Frame")
	healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
	healthFill.BorderSizePixel = 0
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.Parent = healthBack
	entry.healthFill = healthFill

	cache[other] = entry
	return entry
end

local function ensureSkeleton(entry, effects)
	for index = 1, 5 do
		if not entry.skeleton[index] or not entry.skeleton[index].Parent then
			local line = Instance.new("Frame")
			line.Name = "SkeletonLine"
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
			line.BorderSizePixel = 0
			line.Size = UDim2.fromOffset(0, 2)
			line.ZIndex = 5
			line.Parent = effects
			entry.skeleton[index] = line
		end
	end
end

local function destroyEntry(other)
	local entry = cache[other]
	if not entry then
		return
	end
	for _, key in ipairs({ "highlight", "box", "billboard" }) do
		local instance = entry[key]
		if instance and instance.Parent then
			instance:Destroy()
		end
	end
	for _, line in ipairs(entry.skeleton) do
		if line and line.Parent then
			line:Destroy()
		end
	end
	if entry.tracer and entry.tracer.Parent then
		entry.tracer:Destroy()
	end
	cache[other] = nil
end

local function jointsOf(character)
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local head = character:FindFirstChild("Head")
	local leftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
	local rightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
	local leftLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg")
	local rightLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
	return torso, head, leftArm, rightArm, leftLeg, rightLeg
end

local function project(camera, part)
	if not part then
		return nil
	end
	local screenPosition, onScreen = camera:WorldToViewportPoint(part.Position)
	if not onScreen then
		return nil
	end
	return Vector2.new(screenPosition.X, screenPosition.Y), screenPosition.Z
end

local function drawLine(frame, a, b, thickness, color)
	local delta = b - a
	local length = delta.Magnitude
	if length < 2 then
		frame.Visible = false
		return
	end
	frame.Visible = true
	frame.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	frame.Size = UDim2.fromOffset(length, thickness)
	frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	frame.BackgroundColor3 = color
end

local function updatePlayer(other, camera, effects, performance)
	local character = other.Character
	if not character or not other.Parent then
		destroyEntry(other)
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		destroyEntry(other)
		return
	end
	if character:GetAttribute("HackerInvisible") == true then
		destroyEntry(other)
		return
	end
	if not visibleByFilter(other) then
		destroyEntry(other)
		return
	end
	if not visibleByLineOfSight(other) then
		destroyEntry(other)
		return
	end

	local entry = cache[other]
	if not entry then
		entry = createEsp(other)
	end
	if entry.highlight then
		entry.highlight.Adornee = character
		entry.highlight.FillColor = colorsFor(other)
		entry.highlight.OutlineColor = colorsFor(other)
		entry.highlight.Enabled = settings().get("esp_player") == true
	end
	if entry.box then
		entry.box.Adornee = character
		entry.box.Color3 = colorsFor(other)
		entry.box.Visible = settings().get("esp_box") == true
	end

	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local distance = 0
	if myRoot then
		local otherRoot = character:FindFirstChild("HumanoidRootPart")
		if otherRoot then
			distance = (otherRoot.Position - myRoot.Position).Magnitude
		end
	end

	local showName = settings().get("esp_name") == true
	local showDistance = settings().get("esp_dist") == true
	local showHealth = settings().get("esp_health") == true
	if entry.billboard then
		entry.nameLabel.Visible = showName
		entry.distanceLabel.Visible = showDistance
		entry.healthBack.Visible = showHealth
		entry.nameLabel.Text = other.DisplayName
		entry.nameLabel.TextColor3 = colorsFor(other)
		entry.distanceLabel.Text = string.format("%d studs", math.floor(distance))
		if showHealth then
			local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
			entry.healthFill.Size = UDim2.fromScale(ratio, 1)
			entry.healthFill.BackgroundColor3 = ratio > 0.5 and Color3.fromRGB(0, 255, 140)
				or (ratio > 0.25 and Color3.fromRGB(255, 190, 60) or Color3.fromRGB(255, 70, 90))
		end
		entry.billboard.Enabled = showName or showDistance or showHealth
	end

	if performance then
		for _, line in ipairs(entry.skeleton) do
			if line and line.Parent then
				line.Visible = false
			end
		end
		if entry.tracer then
			entry.tracer.Visible = false
		end
		return
	end

	-- Skeleton overlay
	if settings().get("esp_skeleton") == true then
		ensureSkeleton(entry, effects)
		local torso, head, leftArm, rightArm, leftLeg, rightLeg = jointsOf(character)
		local points = {
			project(camera, head),
			project(camera, torso),
			project(camera, leftArm),
			project(camera, rightArm),
			project(camera, leftLeg),
			project(camera, rightLeg),
		}
		local pairsList = {
			{ 1, 2 },
			{ 2, 3 },
			{ 2, 4 },
			{ 2, 5 },
			{ 2, 6 },
		}
		for index, pair in ipairs(pairsList) do
			local line = entry.skeleton[index]
			local a = points[pair[1]]
			local b = points[pair[2]]
			if line and a and b then
				drawLine(line, a, b, 2, colorsFor(other))
			elseif line then
				line.Visible = false
			end
		end
	else
		for _, line in ipairs(entry.skeleton) do
			if line and line.Parent then
				line.Visible = false
			end
		end
	end

	-- Tracer overlay
	if settings().get("esp_tracer") == true then
		local head = character:FindFirstChild("Head")
		local targetPoint = project(camera, head)
		if not entry.tracer or not entry.tracer.Parent then
			local tracer = Instance.new("Frame")
			tracer.Name = "Tracer"
			tracer.AnchorPoint = Vector2.new(0.5, 0.5)
			tracer.BorderSizePixel = 0
			tracer.BackgroundColor3 = colorsFor(other)
			tracer.ZIndex = 4
			tracer.Parent = effects
			entry.tracer = tracer
		end
		if targetPoint then
			local viewport = camera.ViewportSize
			drawLine(entry.tracer, Vector2.new(viewport.X / 2, viewport.Y), targetPoint, 1.5, colorsFor(other))
		else
			entry.tracer.Visible = false
		end
	elseif entry.tracer then
		entry.tracer.Visible = false
	end
end

local function clearAll()
	for other in pairs(cache) do
		destroyEntry(other)
	end
end

local handlers = {}

local function toggle(id)
	handlers[id] = function(value)
		settings().apply(id, value, true)
		if value ~= true and (id == "esp_player" or id == "esp_box" or id == "esp_skeleton" or id == "esp_tracer") then
			clearAll()
		end
	end
end

toggle("esp_player")
toggle("esp_box")
toggle("esp_name")
toggle("esp_dist")
toggle("esp_health")
toggle("esp_skeleton")
toggle("esp_tracer")
toggle("loscheck")
toggle("performance")
toggle("crosshair")

handlers.teamfilter = function(value)
	settings().apply("teamfilter", value, true)
	clearAll()
end

handlers.colorpreset = function(value)
	settings().apply("colorpreset", tonumber(value) or 1, true)
	clearAll()
end

Visuals.handlers = handlers

function Visuals.Init(context)
	ctx = context
	player = Players.LocalPlayer
	espFolder = Instance.new("Folder")
	espFolder.Name = "HackerFightESP"
	-- Created on this client only: it never replicates, so other players never
	-- see your ESP objects.
	espFolder.Parent = workspace

	local effects = ctx.ui.containers.effects

	Players.PlayerRemoving:Connect(function(other)
		destroyEntry(other)
	end)

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local interval = settings().get("performance") == true and 0.2 or 0.05
		if now < updateAt then
			return
		end
		updateAt = now + interval
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local active = {}
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				active[other] = true
				local ok, err = pcall(updatePlayer, other, camera, effects, settings().get("performance") == true)
				if not ok then
					warn("[HackerFight][ESP] " .. tostring(err))
					destroyEntry(other)
				end
			end
		end
		for other in pairs(cache) do
			if not active[other] or not other.Parent then
				destroyEntry(other)
			end
		end
	end)
end

return Visuals
]===],
	["client/Teleport"] = [===[
--[[
	Teleport (ModuleScript)
	Location: StarterPlayer/StarterPlayerScripts/HackerFight/Modules/Teleport

	The client never moves itself here: it asks the server, and the server
	validates cooldown, bounds and landing safety. This module keeps the local
	history, the waypoint list and the cooldown readout in sync.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:WaitForChild("HackerFight")
local Config = require(root:WaitForChild("Config"))
local Remotes = require(root:WaitForChild("Remotes"))

local Teleport = {}

Teleport.history = {}
Teleport.cooldownUntil = 0
Teleport.ctx = nil

local HISTORY_LIMIT = 8

local function pushHistory(label, position)
	table.insert(Teleport.history, 1, { label = label, position = position })
	while #Teleport.history > HISTORY_LIMIT do
		table.remove(Teleport.history)
	end
end

local function startCooldown()
	Teleport.cooldownUntil = os.clock() + Config.TeleportCooldown
end

function Teleport.remaining()
	return math.max(0, Teleport.cooldownUntil - os.clock())
end

function Teleport.toPlayer(name)
	local remote = Remotes.event("Teleport")
	if not remote or type(name) ~= "string" then
		return
	end
	remote:FireServer("player", { target = name })
	pushHistory("Player: " .. name, nil)
	startCooldown()
end

function Teleport.toSpawn()
	local remote = Remotes.event("Teleport")
	if remote then
		remote:FireServer("spawn", {})
		pushHistory("Spawn", nil)
		startCooldown()
	end
end

function Teleport.toPosition(position, label)
	local remote = Remotes.event("Teleport")
	if not remote or typeof(position) ~= "Vector3" then
		return
	end
	remote:FireServer("coords", { position = position })
	pushHistory(label or "Waypoint", position)
	startCooldown()
end

function Teleport.saveWaypoint()
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("wp_add")
	end
end

function Teleport.deleteWaypoint(index)
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("wp_del", index)
	end
end

Teleport.handlers = {
	tp_spawn = function()
		Teleport.toSpawn()
	end,
	wp_save = function()
		Teleport.saveWaypoint()
	end,
}

function Teleport.Init(ctx)
	Teleport.ctx = ctx
	local settings = ctx.modules.Settings

	local function refreshLists()
		if not ctx.ui then
			return
		end
		local waypointItems = {}
		for index, position in ipairs(settings.waypoints) do
			waypointItems[#waypointItems + 1] = {
				text = string.format("WP %d  (%.0f, %.0f, %.0f)", index, position.X, position.Y, position.Z),
				action = "go",
				position = position,
				index = index,
			}
		end
		ctx.ui.setList("waypointlist", waypointItems, function(item)
			if item.action == "go" then
				Teleport.toPosition(item.position, "Waypoint " .. tostring(item.index))
			end
		end, function(item)
			Teleport.deleteWaypoint(item.index)
		end)

		local historyItems = {}
		for index, entry in ipairs(Teleport.history) do
			historyItems[#historyItems + 1] = {
				text = entry.label,
				sub = entry.position and string.format("%.0f, %.0f, %.0f", entry.position.X, entry.position.Y, entry.position.Z) or "player",
				action = "go",
				position = entry.position,
				index = index,
			}
		end
		ctx.ui.setList("historylist", historyItems, function(item)
			if item.action == "go" and item.position then
				Teleport.toPosition(item.position, "History: " .. tostring(item.text))
			end
		end)
	end

	settings.onWaypoints = function(_, ok, err)
		if ok == false and err and ctx.notify then
			ctx.notify("Waypoint rejected: " .. tostring(err), "warn")
		elseif ok then
			ctx.notify("Waypoint saved", "success")
			ctx.ui.click()
		end
		refreshLists()
	end

	Teleport.refreshLists = refreshLists
	refreshLists()

	task.spawn(function()
		while true do
			task.wait(0.5)
			if ctx.ui then
				local remaining = Teleport.remaining()
				if remaining > 0 then
					ctx.ui.setInfo("tp_cooldown", string.format("%.1fs", remaining), "warn")
				else
					ctx.ui.setInfo("tp_cooldown", "Ready", "success")
				end
			end
		end
	end)
end

return Teleport
]===],
	["client/Main"] = [===[
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
]===],
}

local VERSION = "1.0.0"

local function log(message)
	print("[HackerFight Installer] " .. tostring(message))
end

local function clearChild(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

local function instance(class, name, parent, props)
	local object = Instance.new(class)
	object.Name = name
	for key, value in pairs(props or {}) do
		object[key] = value
	end
	if parent then
		object.Parent = parent
	end
	return object
end

local function withSource(object, key)
	local source = SOURCES[key]
	if not source then
		error("installer package is missing source: " .. tostring(key))
	end
	object.Source = source
	return object
end

local function installShared(replicatedStorage)
	clearChild(replicatedStorage, "HackerFight")
	local folder = instance("Folder", "HackerFight", replicatedStorage)
	withSource(instance("ModuleScript", "Config", folder), "shared/Config")
	withSource(instance("ModuleScript", "Util", folder), "shared/Util")
	withSource(instance("ModuleScript", "Features", folder), "shared/Features")
	withSource(instance("ModuleScript", "Remotes", folder), "shared/Remotes")

	local remotesFolder = instance("Folder", "Net", folder)
	local events = {
		"Attack",
		"Ability",
		"Teleport",
		"Settings",
		"State",
		"AbilityState",
		"Feedback",
		"KillFeed",
		"CombatFX",
	}
	for _, name in ipairs(events) do
		instance("RemoteEvent", name, remotesFolder)
	end
	local functions = { "GetRoster", "GetSettings", "GetRound" }
	for _, name in ipairs(functions) do
		instance("RemoteFunction", name, remotesFolder)
	end
	return folder
end

local function installServer(serverScriptService)
	clearChild(serverScriptService, "HackerFight")
	local folder = instance("Folder", "HackerFight", serverScriptService)
	local services = instance("Folder", "Services", folder)
	local modules = {
		{ "DataService", "server/DataService" },
		{ "RoundService", "server/RoundService" },
		{ "TeleportService", "server/TeleportService" },
		{ "AbilityService", "server/AbilityService" },
		{ "CombatService", "server/CombatService" },
	}
	for _, entry in ipairs(modules) do
		withSource(instance("ModuleScript", entry[1], services), entry[2])
	end
	local main = instance("Script", "Main", folder)
	withSource(main, "server/Main")
	main.Disabled = false
	return folder
end

local function installClient(starterPlayerScripts)
	clearChild(starterPlayerScripts, "HackerFight")
	local folder = instance("Folder", "HackerFight", starterPlayerScripts)
	local modulesFolder = instance("Folder", "Modules", folder)
	local modules = {
		{ "Settings", "client/Settings" },
		{ "UI", "client/UI" },
		{ "HUD", "client/HUD" },
		{ "Abilities", "client/Abilities" },
		{ "Combat", "client/Combat" },
		{ "Visuals", "client/Visuals" },
		{ "Teleport", "client/Teleport" },
	}
	for _, entry in ipairs(modules) do
		withSource(instance("ModuleScript", entry[1], modulesFolder), entry[2])
	end
	local main = instance("LocalScript", "Main", folder)
	withSource(main, "client/Main")
	return folder
end

local function installTool(starterPack)
	clearChild(starterPack, "DataBlade")
	local tool = instance("Tool", "DataBlade", nil, {
		RequiresHandle = true,
		CanBeDropped = false,
		ToolTip = "Left click / tap to attack",
	})
	local handle = instance("Part", "Handle", tool, {
		Size = Vector3.new(0.4, 3.6, 0.4),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(0, 255, 140),
		CanCollide = false,
	})
	local blade = instance("Part", "Blade", tool, {
		Size = Vector3.new(0.15, 2.4, 0.8),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(0, 210, 255),
		CanCollide = false,
		Massless = true,
	})
	handle.CFrame = CFrame.new(0, 0, 0)
	blade.CFrame = CFrame.new(0, -0.6, -0.5)
	instance("WeldConstraint", "BladeWeld", blade, {
		Part0 = handle,
		Part1 = blade,
	})
	instance("PointLight", "Glow", handle, {
		Color = Color3.fromRGB(0, 255, 140),
		Brightness = 1.4,
		Range = 8,
	})
	local grip = instance("Attachment", "Grip", handle)
	grip.CFrame = CFrame.new(0, 0.6, 0)
	tool.Grip = grip.CFrame
	tool.Parent = starterPack
	return tool
end

local function installTeams()
	local teams = game:GetService("Teams")
	local hackers = teams:FindFirstChild("Hackers")
	if not hackers then
		hackers = instance("Team", "Hackers", teams)
	end
	hackers.TeamColor = BrickColor.new("Bright green")
	hackers.AutoAssignable = false

	local daemons = teams:FindFirstChild("Daemons")
	if not daemons then
		daemons = instance("Team", "Daemons", teams)
	end
	daemons.TeamColor = BrickColor.new("Bright violet")
	daemons.AutoAssignable = false
end

local function buildArena(workspaceService)
	clearChild(workspaceService, "HackerFightArena")
	local arena = instance("Folder", "HackerFightArena", workspaceService)

	local function part(name, size, position, color, material, parent)
		return instance("Part", name, parent or arena, {
			Size = size,
			Position = position,
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
			Anchored = true,
			TopSurface = Enum.SurfaceType.Smooth,
			BottomSurface = Enum.SurfaceType.Smooth,
		})
	end

	part("Floor", Vector3.new(360, 2, 360), Vector3.new(0, -1, 0), Color3.fromRGB(18, 22, 20), Enum.Material.Concrete)
	for index = -3, 3 do
		part("GridX" .. tostring(index), Vector3.new(360, 0.2, 0.6), Vector3.new(0, 0.06, index * 45), Color3.fromRGB(0, 120, 80), Enum.Material.Neon)
		part("GridZ" .. tostring(index), Vector3.new(0.6, 0.2, 360), Vector3.new(index * 45, 0.06, 0), Color3.fromRGB(0, 90, 70), Enum.Material.Neon)
	end

	local walls = {
		{ "WallNorth", Vector3.new(360, 30, 2), Vector3.new(0, 15, -180) },
		{ "WallSouth", Vector3.new(360, 30, 2), Vector3.new(0, 15, 180) },
		{ "WallEast", Vector3.new(2, 30, 360), Vector3.new(180, 15, 0) },
		{ "WallWest", Vector3.new(2, 30, 360), Vector3.new(-180, 15, 0) },
	}
	for _, wall in ipairs(walls) do
		local body = part(wall[1], wall[2], wall[3], Color3.fromRGB(28, 32, 36), Enum.Material.Metal)
		body.CanCollide = true
	end

	part("TrimNorth", Vector3.new(360, 0.5, 0.5), Vector3.new(0, 30, -179), Color3.fromRGB(0, 190, 255), Enum.Material.Neon)
	part("TrimSouth", Vector3.new(360, 0.5, 0.5), Vector3.new(0, 30, 179), Color3.fromRGB(0, 190, 255), Enum.Material.Neon)

	local spawns = instance("Folder", "Spawns", arena)
	for index = 1, 6 do
		local angle = (index - 1) * (math.pi * 2 / 6)
		local x = math.cos(angle) * 60
		local z = math.sin(angle) * 60
		local pad = instance("SpawnLocation", "Spawn" .. tostring(index), spawns, {
			Size = Vector3.new(10, 1, 10),
			Position = Vector3.new(x, 1, z),
			Neutral = true,
			Enabled = true,
			Duration = 0,
			AllowTeamChangeOnTouch = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(0, 180, 120),
			TopSurface = Enum.SurfaceType.Smooth,
			BottomSurface = Enum.SurfaceType.Smooth,
			CanCollide = true,
		})
		pad.Anchored = true
	end

	local arenaSpawns = instance("Folder", "ArenaSpawns", arena)
	for index = 1, 4 do
		local angle = (index - 1) * (math.pi * 2 / 4)
		instance("Part", "ArenaSpawn" .. tostring(index), arenaSpawns, {
			Size = Vector3.new(6, 1, 6),
			Position = Vector3.new(math.cos(angle) * 22, 1, math.sin(angle) * 22),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(150, 0, 255),
			Anchored = true,
			TopSurface = Enum.SurfaceType.Smooth,
			BottomSurface = Enum.SurfaceType.Smooth,
		})
	end

	instance("Folder", "Dummies", arena)

	for index = 1, 4 do
		local angle = (index - 1) * (math.pi * 2 / 4) + math.pi / 4
		part(
			"Pillar" .. tostring(index),
			Vector3.new(4, 22, 4),
			Vector3.new(math.cos(angle) * 110, 11, math.sin(angle) * 110),
			Color3.fromRGB(26, 30, 34),
			Enum.Material.Metal
		)
		part(
			"PillarGlow" .. tostring(index),
			Vector3.new(4.4, 0.5, 4.4),
			Vector3.new(math.cos(angle) * 110, 22, math.sin(angle) * 110),
			Color3.fromRGB(160, 0, 255),
			Enum.Material.Neon
		)
	end

	workspaceService.FallenPartsDestroyHeight = -150
	return arena
end

local function installGui(starterGui)
	clearChild(starterGui, "HackerFightUI")
	local screen = instance("ScreenGui", "HackerFightUI", starterGui, {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 20,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local window = instance("Frame", "Window", screen, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.66, 0.74),
		BackgroundColor3 = Color3.fromRGB(10, 14, 12),
		BorderSizePixel = 0,
	})
	instance("Frame", "TitleBar", window, {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Color3.fromRGB(18, 24, 21),
		BorderSizePixel = 0,
	})
	instance("TextLabel", "TitleLabel", window:FindFirstChild("TitleBar"), {
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(0, 255, 140),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "HACKER FIGHT  //  v" .. VERSION,
	})
	instance("ScrollingFrame", "TabBar", window, {
		Position = UDim2.new(0, 6, 0, 34),
		Size = UDim2.new(1, -12, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})
	instance("TextBox", "Search", window, {
		Position = UDim2.new(0, 12, 0, 74),
		Size = UDim2.new(1, -24, 0, 26),
		BackgroundColor3 = Color3.fromRGB(20, 28, 24),
		BorderSizePixel = 0,
		Font = Enum.Font.Code,
		TextSize = 13,
		PlaceholderText = "search features...",
		Text = "",
	})
	instance("Frame", "Content", window, {
		Position = UDim2.new(0, 12, 0, 106),
		Size = UDim2.new(1, -24, 1, -134),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
	instance("TextLabel", "Footer", window, {
		Position = UDim2.new(0, 12, 1, -24),
		Size = UDim2.new(1, -24, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(110, 140, 125),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "HACKERFIGHT // READY",
	})
	return screen
end

local function installLighting()
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(62, 72, 68)
	lighting.Brightness = 2
	lighting.ClockTime = 15
	lighting.GlobalShadows = true
	lighting.EnvironmentDiffuseScale = 0.4
	lighting.EnvironmentSpecularScale = 0.3
	lighting.FogColor = Color3.fromRGB(12, 18, 16)
	lighting.FogEnd = 900
	pcall(function()
		lighting.Technology = Enum.Technology.Future
	end)
	clearChild(lighting, "HackerFightAtmosphere")
	instance("Atmosphere", "HackerFightAtmosphere", lighting, {
		Density = 0.28,
		Offset = 0.1,
		Color = Color3.fromRGB(150, 190, 180),
		Decay = Color3.fromRGB(30, 40, 38),
		Glare = 0,
		Haze = 1.2,
	})
end

local function install()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local StarterPlayer = game:GetService("StarterPlayer")
	local StarterGui = game:GetService("StarterGui")
	local StarterPack = game:GetService("StarterPack")
	local workspaceService = game:GetService("Workspace")

	local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	if not starterPlayerScripts then
		error("StarterPlayer.StarterPlayerScripts was not found")
	end

	installShared(ReplicatedStorage)
	installServer(ServerScriptService)
	installClient(starterPlayerScripts)
	installTool(StarterPack)
	installTeams()
	buildArena(workspaceService)
	installGui(StarterGui)
	installLighting()

	workspaceService:SetAttribute("HackerFightVersion", VERSION)
	ReplicatedStorage.HackerFight:SetAttribute("Version", VERSION)
end

local ok, err = pcall(install)
if not ok then
	warn("[HackerFight Installer] FAILED: " .. tostring(err))
	warn("[HackerFight Installer] Make sure you run this in EDIT mode from the Command Bar, then try again.")
	return
end

log("SUCCESS - Hacker Fight Simulator v" .. VERSION .. " installed.")
log("Created: ReplicatedStorage.HackerFight, ServerScriptService.HackerFight, StarterPlayerScripts.HackerFight, StarterGui.HackerFightUI, Workspace.HackerFightArena, StarterPack.DataBlade, Teams.Hackers/Daemons.")
log("Next: press Play. The hacker window opens; press RightShift to hide it. Left click / E / the HIT button attacks.")
log("Tip: to save settings while testing in Studio, enable File > Studio Settings > Security > 'Enable Studio Access to API Services'.")

-- If this file was pasted into a Script instead of the command bar, remove it.
local hasScript, selfScript = pcall(function()
	return script
end)
if hasScript and selfScript and typeof(selfScript) == "Instance" then
	pcall(function()
		selfScript:Destroy()
	end)
end
