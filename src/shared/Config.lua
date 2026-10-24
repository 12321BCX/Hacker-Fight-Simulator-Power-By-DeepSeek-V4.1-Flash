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
