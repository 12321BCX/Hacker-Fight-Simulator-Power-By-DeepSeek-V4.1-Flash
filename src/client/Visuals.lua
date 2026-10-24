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
