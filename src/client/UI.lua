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
