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
