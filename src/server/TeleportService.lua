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
