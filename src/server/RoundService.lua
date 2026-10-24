--[[
	RoundService (ModuleScript)
	Location: ServerScriptService/HackerFight/Services/RoundService

	Match flow: Intermission -> Active round -> Post round -> next mode.
	Also owns: teams, leaderstats, spawn protection, scores, kill feed and the
	training dummies. Everything a client can see about the match comes from
	the State remote, never from a client claim.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Config"))
local Util = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Util"))
local Remotes = require(ReplicatedStorage:WaitForChild("HackerFight"):WaitForChild("Remotes"))

local RoundService = {}

RoundService.RoundNumber = 0
RoundService.Phase = "Intermission"
RoundService.Mode = Config.Modes[1]

local protectedUntil = {}
local roundScores = {}
local roundEndsAt = 0
local winnerAnnounced = false
local dummiesFolder = nil

local function now()
	return os.clock()
end

local function arena()
	return workspace:FindFirstChild("HackerFightArena")
end

local function feedbackToAll(message, kind)
	local remote = Remotes.event("Feedback")
	if remote then
		remote:FireAllClients(message, kind or "info")
	end
end

local function getSpawns(useArena)
	local folder = nil
	local root = arena()
	if root then
		if useArena then
			folder = root:FindFirstChild("ArenaSpawns") or root:FindFirstChild("Spawns")
		else
			folder = root:FindFirstChild("Spawns")
		end
	end
	local points = {}
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

local function teamNameOf(player)
	if player.Team then
		return player.Team.Name
	end
	return "FFA"
end

function RoundService.GetTeamName(player)
	return teamNameOf(player)
end

function RoundService.GetMode()
	return RoundService.Mode
end

function RoundService.GetPhase()
	return RoundService.Phase
end

function RoundService.IsCombatEnabled()
	return RoundService.Phase == "Active"
end

function RoundService.IsProtected(player)
	local untilTime = protectedUntil[player]
	return untilTime ~= nil and now() < untilTime
end

function RoundService.Protect(player, seconds)
	if not player or not player.Parent then
		return
	end
	protectedUntil[player] = now() + (seconds or Config.SpawnProtection)
	local character = player.Character
	if character then
		local old = character:FindFirstChildOfClass("ForceField")
		if old then
			old:Destroy()
		end
		local field = Instance.new("ForceField")
		field.Visible = true
		field.Parent = character
		task.delay(seconds or Config.SpawnProtection, function()
			if field and field.Parent then
				field:Destroy()
			end
		end)
	end
end

local function makeLeaderstats(player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = folder

	local deaths = Instance.new("IntValue")
	deaths.Name = "Deaths"
	deaths.Value = 0
	deaths.Parent = folder

	local score = Instance.new("IntValue")
	score.Name = "Score"
	score.Value = 0
	score.Parent = folder

	folder.Parent = player
end

local function assignTeam(player)
	local mode = RoundService.Mode
	if not mode or not mode.teamBased then
		player.Team = nil
		return
	end
	local teams = game:GetService("Teams")
	local hackers = teams:FindFirstChild("Hackers")
	local daemons = teams:FindFirstChild("Daemons")
	if not hackers or not daemons then
		player.Team = nil
		return
	end
	local countHackers, countDaemons = 0, 0
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Team == hackers then
			countHackers = countHackers + 1
		elseif other.Team == daemons then
			countDaemons = countDaemons + 1
		end
	end
	if countHackers <= countDaemons then
		player.Team = hackers
	else
		player.Team = daemons
	end
	player.Neutral = false
end

local function spawnCharacterAt(player, position)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	character:PivotTo(CFrame.new(position))
end

local function resetRoundScores()
	roundScores = { ffa = 0 }
	local teams = game:GetService("Teams")
	for _, team in ipairs(teams:GetChildren()) do
		roundScores[team.Name] = 0
	end
end

local function visibleScores()
	local mode = RoundService.Mode
	local result = {}
	if mode and mode.teamBased then
		for key, value in pairs(roundScores) do
			if key ~= "ffa" then
				result[key] = value
			end
		end
	else
		result.ffa = roundScores.ffa or 0
	end
	return result
end

local function broadcastState()
	local mode = RoundService.Mode
	local payload = {
		modeId = mode and mode.id or "ffa",
		modeName = mode and mode.name or "Free-for-All",
		teamBased = mode and mode.teamBased or false,
		phase = RoundService.Phase,
		timeLeft = math.max(0, roundEndsAt - now()),
		roundNumber = RoundService.RoundNumber,
		scoreToWin = Config.ScoreToWin,
		scores = visibleScores(),
	}
	local remote = Remotes.event("State")
	if remote then
		remote:FireAllClients(payload)
	end
end

function RoundService.BroadcastState()
	broadcastState()
end

function RoundService.GetRoster()
	local roster = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = Util.getHumanoid(player)
		local kills, deaths, score = 0, 0, 0
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			kills = stats:FindFirstChild("Kills") and stats.Kills.Value or 0
			deaths = stats:FindFirstChild("Deaths") and stats.Deaths.Value or 0
			score = stats:FindFirstChild("Score") and stats.Score.Value or 0
		end
		roster[#roster + 1] = {
			name = player.Name,
			displayName = player.DisplayName,
			userId = player.UserId,
			health = humanoid and math.floor(humanoid.Health) or 0,
			maxHealth = humanoid and math.floor(humanoid.MaxHealth) or 100,
			team = teamNameOf(player),
			alive = Util.isAlive(player),
			kills = kills,
			deaths = deaths,
			score = score,
			protected = RoundService.IsProtected(player),
		}
	end
	table.sort(roster, function(a, b)
		if a.kills == b.kills then
			return a.name < b.name
		end
		return a.kills > b.kills
	end)
	return roster
end

function RoundService.RegisterKill(killer, victim)
	if not victim then
		return
	end
	local victimStats = victim:FindFirstChild("leaderstats")
	if victimStats then
		local deaths = victimStats:FindFirstChild("Deaths")
		if deaths then
			deaths.Value = deaths.Value + 1
		end
	end

	local killerName = "The Arena"
	if killer and killer ~= victim then
		local killerStats = killer:FindFirstChild("leaderstats")
		if killerStats then
			local kills = killerStats:FindFirstChild("Kills")
			if kills then
				kills.Value = kills.Value + 1
			end
			local score = killerStats:FindFirstChild("Score")
			if score then
				score.Value = score.Value + 1
			end
		end
		local mode = RoundService.Mode
		local key = mode and mode.teamBased and teamNameOf(killer) or "ffa"
		roundScores[key] = (roundScores[key] or 0) + 1
		killerName = killer.DisplayName
	end

	local feed = Remotes.event("KillFeed")
	if feed then
		feed:FireAllClients(killerName, victim.DisplayName)
	end
	broadcastState()
end

local function createDummy(position, index)
	local model = Instance.new("Model")
	model.Name = "TrainingDummy_" .. tostring(index)

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = position + Vector3.new(0, 2, 0)
	torso.Anchored = true
	torso.Color = Color3.fromRGB(255, 120, 60)
	torso.Material = Enum.Material.Neon
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Position = torso.Position + Vector3.new(0, 1.7, 0)
	head.Anchored = true
	head.Color = Color3.fromRGB(255, 180, 80)
	head.Material = Enum.Material.Neon
	head.Parent = model

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.Position = torso.Position
	root.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 150
	humanoid.Health = 150
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthTag"
	billboard.Size = UDim2.fromOffset(120, 34)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = head
	billboard.Parent = model

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.BackgroundTransparency = 0.35
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Code
	label.TextColor3 = Color3.fromRGB(255, 180, 80)
	label.TextScaled = true
	label.Text = "TRAINING DUMMY"
	label.Parent = billboard

	humanoid.Died:Connect(function()
		task.delay(2.5, function()
			if model.Parent then
				model:Destroy()
			end
			local mode = RoundService.Mode
			if mode and mode.training and RoundService.Phase == "Active" then
				createDummy(position, index)
			end
		end)
	end)

	model.PrimaryPart = torso
	model.Parent = dummiesFolder
	return model
end

function RoundService.ClearDummies()
	if dummiesFolder then
		for _, child in ipairs(dummiesFolder:GetChildren()) do
			child:Destroy()
		end
	end
end

local function spawnDummies()
	RoundService.ClearDummies()
	local points = getSpawns(true)
	for index = 1, 3 do
		local base = points[((index - 1) % #points) + 1]
		createDummy(base + Vector3.new(index * 6, 0, 8), index)
	end
end

local function teleportEveryone()
	local mode = RoundService.Mode
	local points = getSpawns(mode and mode.arena)
	for index, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			if not Util.isAlive(player) then
				local ok = pcall(function()
					player:LoadCharacter()
				end)
				if not ok then
					return
				end
				local waited = 0
				while not Util.isAlive(player) and waited < 6 do
					task.wait(0.1)
					waited = waited + 0.1
				end
			end
			local character = player.Character
			if character and character.PrimaryPart then
				spawnCharacterAt(player, points[((index - 1) % #points) + 1])
				RoundService.Protect(player, Config.SpawnProtection)
			end
		end)
	end
end

local function startRound(modeIndex)
	local mode = Config.Modes[modeIndex]
	RoundService.Mode = mode
	RoundService.RoundNumber = RoundService.RoundNumber + 1
	RoundService.Phase = "Active"
	roundEndsAt = now() + mode.duration
	winnerAnnounced = false
	resetRoundScores()

	for _, player in ipairs(Players:GetPlayers()) do
		assignTeam(player)
	end
	RoundService.ClearDummies()
	if mode.training then
		spawnDummies()
	end
	teleportEveryone()
	feedbackToAll("ROUND " .. tostring(RoundService.RoundNumber) .. " - " .. mode.name, "round")
	broadcastState()

	task.spawn(function()
		while RoundService.Phase == "Active" and now() < roundEndsAt do
			local won = false
			for _, value in pairs(visibleScores()) do
				if value >= Config.ScoreToWin then
					won = true
				end
			end
			if won then
				break
			end
			task.wait(0.5)
		end
		if RoundService.Phase ~= "Active" then
			return
		end
		RoundService.Phase = "Post"
		roundEndsAt = now() + Config.PostRoundTime
		local bestTeam, bestScore = nil, -1
		for key, value in pairs(visibleScores()) do
			if value > bestScore then
				bestTeam, bestScore = key, value
			end
		end
		if bestTeam and bestScore > 0 then
			local label = bestTeam == "ffa" and "Arena winner decided by eliminations" or (tostring(bestTeam) .. " wins")
			feedbackToAll("ROUND OVER - " .. label, "round")
		else
			feedbackToAll("ROUND OVER - no eliminations", "round")
		end
		RoundService.ClearDummies()
		broadcastState()
	end)
end

local function nextModeIndex(current)
	local index = current + 1
	if index > #Config.Modes then
		index = 1
	end
	return index
end

local function watchPlayer(player)
	if not player:FindFirstChild("leaderstats") then
		makeLeaderstats(player)
	end
	assignTeam(player)

	local function onCharacter()
		task.wait(0.2)
		RoundService.Protect(player, Config.SpawnProtection)
		RoundService.BroadcastState()
	end

	player.CharacterAdded:Connect(function()
		task.spawn(onCharacter)
	end)
	if player.Character then
		task.spawn(onCharacter)
	end
	task.delay(1, function()
		RoundService.BroadcastState()
	end)
end

function RoundService.Start()
	local root = arena()
	if root then
		dummiesFolder = root:FindFirstChild("Dummies")
	end
	if not dummiesFolder then
		dummiesFolder = Instance.new("Folder")
		dummiesFolder.Name = "Dummies"
		dummiesFolder.Parent = root or workspace
	end

	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(function(player)
		protectedUntil[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end

	resetRoundScores()
	RoundService.Phase = "Intermission"
	roundEndsAt = now() + Config.IntermissionTime
	broadcastState()
	feedbackToAll("Welcome to " .. Config.GameName, "info")

	task.spawn(function()
		-- Start() already opened the first intermission.
		task.wait(Config.IntermissionTime)
		local modeIndex = 1
		while true do
			startRound(modeIndex)
			task.wait(Config.PostRoundTime + 0.5)
			modeIndex = nextModeIndex(modeIndex)
			RoundService.Phase = "Intermission"
			roundEndsAt = now() + Config.IntermissionTime
			feedbackToAll("Next mode: " .. Config.Modes[modeIndex].name, "info")
			broadcastState()
			task.wait(Config.IntermissionTime)
		end
	end)
end

return RoundService
