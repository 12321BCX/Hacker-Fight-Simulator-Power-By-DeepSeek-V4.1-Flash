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
