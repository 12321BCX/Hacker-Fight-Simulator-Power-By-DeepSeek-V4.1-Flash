-- Client-side additions to the Roblox mock: signals, services and task shims.
-- Loaded once; the base mock is dofile'd here and returned as `rob`.

local rob = dofile("tools/mock_roblox.lua")

local M = {}

----------------------------------------------------------------------
-- signals
----------------------------------------------------------------------
local Signal = {}
Signal.__index = Signal

function Signal.new(name)
	return setmetatable({ name = name, handlers = {} }, Signal)
end

function Signal:Connect(callback)
	self.handlers[#self.handlers + 1] = callback
	return {
		Disconnect = function()
			for index, item in ipairs(self.handlers) do
				if item == callback then
					table.remove(self.handlers, index)
					break
				end
			end
		end,
	}
end

function Signal:Once(callback)
	return self:Connect(callback)
end

function Signal:Wait()
	return nil
end

function Signal:Fire(...)
	local snapshot = {}
	for _, handler in ipairs(self.handlers) do
		snapshot[#snapshot + 1] = handler
	end
	for _, handler in ipairs(snapshot) do
		local ok, err = pcall(handler, ...)
		if not ok then
			_G.HF_ERRORS = _G.HF_ERRORS or {}
			table.insert(_G.HF_ERRORS, tostring(err))
		end
	end
end

M.Signal = Signal

_G.HF_WARNINGS = {}
local originalWarn = _G.warn
_G.warn = function(...)
	local parts = {}
	for index = 1, select("#", ...) do
		parts[#parts + 1] = tostring(select(index, ...))
	end
	local message = table.concat(parts, " ")
	table.insert(_G.HF_WARNINGS, message)
	originalWarn(message)
end

_G.RaycastParams = {
	new = function()
		return { FilterDescendantsInstances = {}, FilterType = nil, IgnoreWater = false }
	end,
}

math.clamp = math.clamp or function(value, minimum, maximum)
	if value < minimum then
		return minimum
	elseif value > maximum then
		return maximum
	end
	return value
end

----------------------------------------------------------------------
-- instance hook: events + extra methods for every mock instance
----------------------------------------------------------------------
local eventNames = {
	MouseEnter = true,
	MouseLeave = true,
	InputBegan = true,
	InputChanged = true,
	InputEnded = true,
	MouseButton1Click = true,
	MouseButton2Click = true,
	TouchLongPress = true,
	Activated = true,
	Died = true,
	HealthChanged = true,
	StateChanged = true,
	Ended = true,
	PlayerAdded = true,
	PlayerRemoving = true,
	CharacterAdded = true,
	CharacterRemoving = true,
	ChildAdded = true,
	ChildRemoved = true,
	DescendantAdded = true,
	Changed = true,
	JumpRequest = true,
	RenderStepped = true,
	Heartbeat = true,
	Stepped = true,
}

local signals = setmetatable({}, { __mode = "k" })

local function signalFor(object, name)
	local bucket = signals[object]
	if not bucket then
		bucket = {}
		signals[object] = bucket
	end
	if not bucket[name] then
		bucket[name] = Signal.new(name)
	end
	return bucket[name]
end

M.signalFor = signalFor

local clientMethods = {}

function clientMethods.GetPropertyChangedSignal(self, name)
	return signalFor(self, "prop:" .. tostring(name))
end

function clientMethods.Play(self)
	signalFor(self, "Played"):Fire()
end

function clientMethods.Stop(self) end
function clientMethods.TweenPosition(self) end
function clientMethods.PivotTo(self) end
function clientMethods.LoadCharacter(self) end

_G.HF_OBJECT_HOOK = function(object, key)
	local method = clientMethods[key]
	if method then
		return method
	end
	if eventNames[key] then
		return signalFor(object, key)
	end
	return nil
end

----------------------------------------------------------------------
-- services
----------------------------------------------------------------------
local services = rob.services

rawset(services.TweenService, "Create", function(self, object, info, goals)
	return {
		Play = function()
			for key, value in pairs(goals) do
				pcall(function()
					object[key] = value
				end)
			end
		end,
		Cancel = function() end,
	}
end)

local userInput = services.UserInputService
rawset(userInput, "TouchEnabled", false)
rawset(userInput, "KeyboardEnabled", true)
rawset(userInput, "MouseEnabled", true)
rawset(userInput, "IsKeyDown", function()
	return false
end)
rawset(userInput, "GetFocusedTextBox", function()
	return nil
end)

rawset(services.RunService, "IsStudio", function()
	return true
end)

local players = services.Players
local localPlayer = rob.new("Player")
rawset(localPlayer, "Name", "TestPlayer")
rawset(localPlayer, "DisplayName", "TestPlayer")
rawset(localPlayer, "UserId", 1)
rawset(localPlayer, "Team", nil)
local playerGui = rob.new("PlayerGui")
rawset(playerGui, "Name", "PlayerGui")
playerGui.Parent = localPlayer
rawset(localPlayer, "PlayerGui", playerGui)
rawset(localPlayer, "Character", nil)

rawset(players, "LocalPlayer", localPlayer)
rawset(players, "GetPlayers", function()
	return { localPlayer }
end)

local camera = rob.new("Camera")
rawset(camera, "Name", "Camera")
rawset(camera, "CameraType", "Custom")
rawset(camera, "CFrame", {
	Position = { X = 0, Y = 10, Z = 20 },
	LookVector = { X = 0, Y = 0, Z = -1 },
	RightVector = { X = 1, Y = 0, Z = 0 },
})
rawset(camera, "ViewportSize", { X = 1280, Y = 720 })
rawset(camera, "WorldToViewportPoint", function()
	return { X = 640, Y = 360, Z = 10 }, true
end)
camera.Parent = services.Workspace
rawset(services.Workspace, "CurrentCamera", camera)
rawset(services.Workspace, "Raycast", function(self, origin, direction, params)
	return {
		Position = Vector3.new(origin.X, 0, origin.Z),
		Normal = Vector3.new(0, 1, 0),
		Instance = nil,
	}
end)

----------------------------------------------------------------------
-- task shims
----------------------------------------------------------------------
_G.task = {
	spawn = function(fn, ...)
		local co = coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			_G.HF_ERRORS = _G.HF_ERRORS or {}
			table.insert(_G.HF_ERRORS, tostring(err))
		end
	end,
	delay = function(_, fn)
		return nil
	end,
	wait = function()
		coroutine.yield()
	end,
	defer = function(fn)
		return nil
	end,
}

----------------------------------------------------------------------
-- module loader
----------------------------------------------------------------------
local moduleCache = {}

local function requireModule(instance)
	if type(instance) ~= "table" then
		error("require() expected a ModuleScript, got " .. tostring(instance))
	end
	if moduleCache[instance] then
		return moduleCache[instance]
	end
	local source = rawget(instance, "Source")
	if not source then
		error("no Source on required instance " .. tostring(rawget(instance, "Name")))
	end
	local previous = _G.script
	_G.script = instance
	local fn, loadError = load(source, rawget(instance, "Name") or "module")
	if not fn then
		_G.script = previous
		error("module load failed: " .. tostring(loadError))
	end
	local ok, value = pcall(fn)
	_G.script = previous
	if not ok then
		error("module error: " .. tostring(value))
	end
	moduleCache[instance] = value
	return value
end

_G.require = requireModule

function M.runScript(instance)
	local source = rawget(instance, "Source")
	local previous = _G.script
	_G.script = instance
	local fn, loadError = load(source, rawget(instance, "Name") or "script")
	if not fn then
		_G.script = previous
		error("load failed: " .. tostring(loadError))
	end
	local ok, err = pcall(fn)
	_G.script = previous
	if not ok then
		error("run failed: " .. tostring(err))
	end
	return true
end

-- remote plumbing so the client can talk to a fake server
function M.wireRemotes(recorded)
	local shared = services.ReplicatedStorage:FindFirstChild("HackerFight")
	local net = shared and shared:FindFirstChild("Net")
	if not net then
		return
	end
	for _, remote in ipairs(net:GetChildren()) do
		local name = rawget(remote, "Name")
		rawset(remote, "OnClientEvent", signalFor(remote, "OnClientEvent"))
		rawset(remote, "OnServerEvent", signalFor(remote, "OnServerEvent"))
		rawset(remote, "FireServer", function(_, ...)
			recorded[#recorded + 1] = { remote = name, args = { ... } }
		end)
		rawset(remote, "FireAllClients", function(self, ...)
			signalFor(self, "OnClientEvent"):Fire(...)
		end)
		rawset(remote, "FireClient", function(self, _, ...)
			signalFor(self, "OnClientEvent"):Fire(...)
		end)
		rawset(remote, "InvokeServer", function()
			if name == "GetSettings" then
				return { settings = {}, waypoints = {}, persistent = false }
			elseif name == "GetRound" then
				return { phase = "Active", modeName = "Free-for-All", modeId = "ffa", roundNumber = 1 }
			elseif name == "GetRoster" then
				return {
					{ name = "TestPlayer", displayName = "TestPlayer", health = 100, maxHealth = 100, team = "FFA", kills = 2, deaths = 1, score = 2 },
				}
			end
			return nil
		end)
	end
end

M.localPlayer = localPlayer
M.playerGui = playerGui
M.services = services
M.rob = rob

return M
