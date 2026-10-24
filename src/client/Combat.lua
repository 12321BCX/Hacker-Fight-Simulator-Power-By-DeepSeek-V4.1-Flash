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
