-- Server smoke test: boot the real server Main against the mock, then drive
-- Remotes directly to prove validation, damage, cooldowns and teleports work.

local mock = dofile("tools/client_mock.lua")
local rob = mock.rob
local services = mock.services

local installerFile = assert(io.open("HackerFightInstaller.lua", "rb"))
local installerCode = installerFile:read("*a")
installerFile:close()
assert(load(installerCode, "HackerFightInstaller"))()
mock.wireRemotes({})

----------------------------------------------------------------------
-- extra services the server expects
----------------------------------------------------------------------
local dataStoreService = rob.new("DataStoreService")
rawset(dataStoreService, "GetDataStore", function()
	return {
		GetAsync = function()
			return nil
		end,
		SetAsync = function()
			return true
		end,
	}
end)
services.DataStoreService = dataStoreService
rawset(rob.GAME, "BindToClose", function() end)

----------------------------------------------------------------------
-- players + characters
----------------------------------------------------------------------
local playerA = mock.localPlayer
rawset(playerA, "Name", "Alpha")
rawset(playerA, "DisplayName", "Alpha")
rawset(playerA, "Team", nil)

local playerB = rob.new("Player")
rawset(playerB, "Name", "Enemy")
rawset(playerB, "DisplayName", "Enemy")
rawset(playerB, "UserId", 2)
rawset(playerB, "Team", nil)

playerA.Parent = services.Players
playerB.Parent = services.Players

local playerList = { playerA, playerB }
rawset(services.Players, "GetPlayers", function()
	return playerList
end)

local function makeHumanoid(maxHealth)
	local humanoid = rob.new("Humanoid")
	rawset(humanoid, "MaxHealth", maxHealth)
	rawset(humanoid, "Health", maxHealth)
	rawset(humanoid, "WalkSpeed", 16)
	rawset(humanoid, "JumpPower", 50)
	rawset(humanoid, "UseJumpPower", false)
	rawset(humanoid, "PlatformStand", false)
	rawset(humanoid, "Jump", false)
	rawset(humanoid, "MoveDirection", Vector3.new(0, 0, 0))
	rawset(humanoid, "TakeDamage", function(self, amount)
		self.Health = math.max(0, self.Health - amount)
	end)
	rawset(humanoid, "GetState", function()
		return Enum.HumanoidStateType.Running
	end)
	rawset(humanoid, "ChangeState", function() end)
	rawset(humanoid, "SetStateEnabled", function() end)
	return humanoid
end

local function makeCharacter(position)
	local model = rob.new("Model")
	rawset(model, "Name", "Character")
	local root = rob.new("Part")
	rawset(root, "Name", "HumanoidRootPart")
	rawset(root, "Position", position)
	rawset(root, "CFrame", CFrame.new(position))
	rawset(root, "AssemblyLinearVelocity", Vector3.new(0, 0, 0))
	root.Parent = model
	local humanoid = makeHumanoid(100)
	humanoid.Parent = model
	rawset(model, "PrimaryPart", root)
	rawset(model, "PivotTo", function() end)
	return model, humanoid
end

----------------------------------------------------------------------
-- boot the server
----------------------------------------------------------------------
local serverScripts = services.ServerScriptService
local serverFolder = assert(serverScripts:FindFirstChild("HackerFight"), "server folder missing")
local mainScript = assert(serverFolder:FindFirstChild("Main"), "server Main missing")
mock.runScript(mainScript)

local shared = services.ReplicatedStorage:FindFirstChild("HackerFight")
local net = shared:FindFirstChild("Net")

local failures = {}
local checks = 0
local function check(condition, message)
	checks = checks + 1
	if not condition then
		failures[#failures + 1] = message
	end
end

local feedbackLog = {}
local feedback = net:FindFirstChild("Feedback")
rawset(feedback, "FireClient", function(_, target, message, kind)
	feedbackLog[#feedbackLog + 1] = { target = target, message = tostring(message), kind = kind }
end)
rawset(feedback, "FireAllClients", function(_, message, kind)
	feedbackLog[#feedbackLog + 1] = { target = "all", message = tostring(message), kind = kind }
end)

local combatFxCount = 0
local combatFx = net:FindFirstChild("CombatFX")
rawset(combatFx, "FireAllClients", function()
	combatFxCount = combatFxCount + 1
end)

local function findFeedback(pattern)
	for _, entry in ipairs(feedbackLog) do
		if string.find(entry.message, pattern, 1, true) then
			return entry
		end
	end
	return nil
end

-- characters (assigned without firing CharacterAdded so no spawn protection)
local characterA, humanoidA = makeCharacter(Vector3.new(0, 5, 0))
local characterB, humanoidB = makeCharacter(Vector3.new(10, 5, 0))
rawset(playerA, "Character", characterA)
rawset(playerB, "Character", characterB)

local roundService = require(serverFolder:FindFirstChild("Services"):FindFirstChild("RoundService"))
local dataService = require(serverFolder:FindFirstChild("Services"):FindFirstChild("DataService"))
roundService.Phase = "Active" -- skip the intermission countdown

----------------------------------------------------------------------
-- quest: normal attack
----------------------------------------------------------------------
local attack = net:FindFirstChild("Attack")
attack.OnServerEvent:Fire(playerA, "Enemy")
check(humanoidB.Health == 88, "attack should deal 12 damage, health is " .. tostring(humanoidB.Health))
check(combatFxCount > 0, "no CombatFX broadcast for a successful hit")

----------------------------------------------------------------------
-- out of range attack is rejected
----------------------------------------------------------------------
rawset(playerB.Character:FindFirstChild("HumanoidRootPart"), "Position", Vector3.new(200, 5, 0))
local start = os.clock()
while os.clock() - start < 0.5 do
end
attack.OnServerEvent:Fire(playerA, "Enemy")
check(humanoidB.Health == 88, "out of range attack changed health")
check(findFeedback("No valid target") ~= nil, "out of range attack was not rejected")
rawset(playerB.Character:FindFirstChild("HumanoidRootPart"), "Position", Vector3.new(10, 5, 0))

----------------------------------------------------------------------
-- god mode blocks damage
----------------------------------------------------------------------
local ability = net:FindFirstChild("Ability")
ability.OnServerEvent:Fire(playerB, "godmode")
start = os.clock()
while os.clock() - start < 0.5 do
end
attack.OnServerEvent:Fire(playerA, "Enemy")
check(humanoidB.Health == 88, "god mode did not block damage")
check(findFeedback("God Mode") ~= nil, "god mode block was not reported")

----------------------------------------------------------------------
-- spawn protection blocks damage
----------------------------------------------------------------------
roundService.Protect(playerB, 2)
start = os.clock()
while os.clock() - start < 0.5 do
end
attack.OnServerEvent:Fire(playerA, "Enemy")
check(humanoidB.Health == 88, "spawn protection did not block damage")

----------------------------------------------------------------------
-- speed clamps on the server
----------------------------------------------------------------------
ability.OnServerEvent:Fire(playerA, "speed", 500)
local settings = dataService.GetSettings(playerA)
check(settings.speed == 80, "speed was not clamped to 80, got " .. tostring(settings.speed))

----------------------------------------------------------------------
-- teleport validation
----------------------------------------------------------------------
local teleport = net:FindFirstChild("Teleport")
teleport.OnServerEvent:Fire(playerA, "coords", { position = Vector3.new(5000, 5, 5000) })
check(findFeedback("too far") ~= nil or findFeedback("outside the arena") ~= nil, "out of bounds teleport was not rejected")

teleport.OnServerEvent:Fire(playerA, "spawn", {})
check(findFeedback("Returned to spawn") ~= nil, "spawn teleport failed")

----------------------------------------------------------------------
-- waypoints persist through DataService
----------------------------------------------------------------------
local settingsRemote = net:FindFirstChild("Settings")
local waypointLog = {}
rawset(settingsRemote, "FireClient", function(_, target, action, points)
	if action == "waypoints" then
		waypointLog[#waypointLog + 1] = points
	end
end)
settingsRemote.OnServerEvent:Fire(playerA, "wp_add")
check(#dataService.GetWaypoints(playerA) == 1, "waypoint was not stored")
check(#waypointLog == 1, "waypoint list was not sent back to the client")

----------------------------------------------------------------------
-- RemoteFunctions
----------------------------------------------------------------------
local getSettings = net:FindFirstChild("GetSettings")
local payload = getSettings.OnServerInvoke(playerA)
check(type(payload) == "table" and payload.settings.reach == 9, "GetSettings returned bad data")

local getRoster = net:FindFirstChild("GetRoster")
local roster = getRoster.OnServerInvoke(playerA)
check(type(roster) == "table" and #roster == 2, "GetRoster returned " .. tostring(#roster) .. " entries")
check(roster[1].health ~= nil, "roster entry has no health")

----------------------------------------------------------------------
-- result
----------------------------------------------------------------------
if _G.HF_ERRORS then
	for _, message in ipairs(_G.HF_ERRORS) do
		failures[#failures + 1] = "runtime error: " .. tostring(message)
	end
end
for _, message in ipairs(_G.HF_WARNINGS or {}) do
	failures[#failures + 1] = "warning: " .. tostring(message)
end

print(string.format("server smoke: %d checks", checks))
if #failures > 0 then
	for _, failure in ipairs(failures) do
		print("SMOKE FAIL: " .. tostring(failure))
	end
	os.exit(1)
end
print("server smoke: OK")
