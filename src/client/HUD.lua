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
