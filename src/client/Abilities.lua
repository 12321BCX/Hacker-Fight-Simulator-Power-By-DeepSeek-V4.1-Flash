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
