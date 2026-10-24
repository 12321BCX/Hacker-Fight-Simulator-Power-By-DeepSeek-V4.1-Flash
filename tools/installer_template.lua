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

--@SOURCES@

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
