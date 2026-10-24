-- Minimal Roblox API mock. Only enough surface for the installer to run so we
-- can prove the generated tree is complete before handing it to a user.

local M = {}

local methods = {}

local Object = {}

Object.__index = function(self, key)
	if _G.HF_OBJECT_HOOK then
		local hooked = _G.HF_OBJECT_HOOK(self, key)
		if hooked ~= nil then
			return hooked
		end
	end
	local method = methods[key]
	if method then
		return method
	end
	local children = rawget(self, "Children")
	if children then
		for _, child in ipairs(children) do
			if rawget(child, "Name") == key then
				return child
			end
		end
	end
	return nil
end

Object.__newindex = function(self, key, value)
	if key == "Parent" then
		local old = rawget(self, "Parent")
		if old then
			local siblings = rawget(old, "Children")
			for index, child in ipairs(siblings) do
				if child == self then
					table.remove(siblings, index)
					break
				end
			end
		end
		rawset(self, "Parent", value)
		if value then
			local siblings = rawget(value, "Children")
			if siblings then
				siblings[#siblings + 1] = self
			end
		end
		return
	end
	rawset(self, key, value)
end

function M.new(className)
	local object = setmetatable({
		ClassName = className,
		Name = className,
		Children = {},
		Attributes = {},
		Parent = nil,
	}, Object)
	return object
end

function methods.FindFirstChild(self, name)
	for _, child in ipairs(rawget(self, "Children")) do
		if rawget(child, "Name") == name then
			return child
		end
	end
	return nil
end

function methods.FindFirstChildOfClass(self, class)
	for _, child in ipairs(rawget(self, "Children")) do
		if rawget(child, "ClassName") == class then
			return child
		end
	end
	return nil
end

function methods.GetChildren(self)
	return rawget(self, "Children")
end

function methods.GetDescendants(self)
	local result = {}
	local function walk(parent)
		for _, child in ipairs(rawget(parent, "Children")) do
			result[#result + 1] = child
			walk(child)
		end
	end
	walk(self)
	return result
end

function methods.Destroy(self)
	self.Parent = nil
	rawset(self, "Destroyed", true)
end

function methods.SetAttribute(self, key, value)
	rawget(self, "Attributes")[key] = value
end

function methods.GetAttribute(self, key)
	return rawget(self, "Attributes")[key]
end

local guiClasses = {
	Frame = true,
	ScrollingFrame = true,
	TextLabel = true,
	TextButton = true,
	TextBox = true,
	ImageLabel = true,
	ImageButton = true,
	ViewportFrame = true,
}

local basePartClasses = {
	Part = true,
	SpawnLocation = true,
	MeshPart = true,
	WedgePart = true,
}

function methods.IsA(self, class)
	local own = rawget(self, "ClassName")
	if own == class then
		return true
	end
	if class == "GuiObject" and guiClasses[own] then
		return true
	end
	if class == "BasePart" and basePartClasses[own] then
		return true
	end
	if class == "Instance" then
		return true
	end
	return false
end

function methods.WaitForChild(self, name)
	return methods.FindFirstChild(self, name)
end

function methods.Clone(self)
	local copy = M.new(rawget(self, "ClassName"))
	rawset(copy, "Name", rawget(self, "Name"))
	for key, value in pairs(self) do
		if key ~= "Children" and key ~= "Parent" and key ~= "Attributes" then
			rawset(copy, key, value)
		end
	end
	for _, child in ipairs(rawget(self, "Children")) do
		local childCopy = methods.Clone(child)
		childCopy.Parent = copy
	end
	return copy
end

_G.Instance = {}
function _G.Instance.new(className, parent)
	local object = M.new(className)
	if parent then
		object.Parent = parent
	end
	return object
end

----------------------------------------------------------------------
-- datatypes
----------------------------------------------------------------------
local Vector3Meta = {}

local function vector3(x, y, z)
	local v = setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3Meta)
	local length = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	rawset(v, "Magnitude", length)
	if length > 0 then
		local unit = setmetatable({ X = v.X / length, Y = v.Y / length, Z = v.Z / length }, Vector3Meta)
		rawset(unit, "Magnitude", 1)
		rawset(unit, "Unit", unit)
		rawset(v, "Unit", unit)
	else
		rawset(v, "Unit", v)
	end
	return v
end

Vector3Meta.__index = Vector3Meta

function Vector3Meta.__sub(a, b)
	return vector3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end

function Vector3Meta.__add(a, b)
	return vector3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end

function Vector3Meta.__mul(a, b)
	if type(b) == "number" then
		return vector3(a.X * b, a.Y * b, a.Z * b)
	end
	return vector3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end

_G.Vector3 = { new = vector3 }
_G.Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0 } end }

_G.UDim = { new = function(scale, offset) return { Scale = scale or 0, Offset = offset or 0 } end }
_G.UDim2 = {
	new = function(xs, xo, ys, yo)
		return { X = { Scale = xs or 0, Offset = xo or 0 }, Y = { Scale = ys or 0, Offset = yo or 0 } }
	end,
	fromScale = function(x, y)
		return { X = { Scale = x or 0, Offset = 0 }, Y = { Scale = y or 0, Offset = 0 } }
	end,
	fromOffset = function(x, y)
		return { X = { Scale = 0, Offset = x or 0 }, Y = { Scale = 0, Offset = y or 0 } }
	end,
}

_G.Color3 = {
	new = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0 } end,
	fromRGB = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0 } end,
}

_G.BrickColor = { new = function(name) return { Name = name } end }

_G.TweenInfo = {
	new = function(duration, style, direction, repeatCount, reverses, delayTime)
		return {
			Time = duration or 0,
			EasingStyle = style,
			EasingDirection = direction,
			RepeatCount = repeatCount or 0,
			Reverses = reverses or false,
			DelayTime = delayTime or 0,
		}
	end,
}

_G.CFrame = {
	new = function(x, y, z)
		if type(x) == "table" then
			return { Position = x, LookVector = vector3(0, 0, -1) }
		end
		return { Position = vector3(x, y, z), LookVector = vector3(0, 0, -1) }
	end,
	lookAt = function(from, to)
		return { Position = from, LookVector = vector3(0, 0, -1) }
	end,
}

_G.Enum = setmetatable({}, {
	__index = function(enumTable, enumName)
		local enum = setmetatable({}, {
			__index = function(itemTable, itemName)
				local item = { Name = itemName, Value = 0, EnumType = enumName }
				rawset(itemTable, itemName, item)
				return item
			end,
		})
		rawset(enumTable, enumName, enum)
		return enum
	end,
})

function _G.typeof(value)
	if type(value) == "table" and rawget(value, "ClassName") then
		return "Instance"
	end
	if type(value) == "table" and rawget(value, "X") and rawget(value, "Y") and rawget(value, "Z") then
		return "Vector3"
	end
	return type(value)
end

----------------------------------------------------------------------
-- game / services
----------------------------------------------------------------------
local GAME = M.new("DataModel")
rawset(GAME, "Name", "Game")

local services = {}

local function service(className, name)
	local object = M.new(className)
	rawset(object, "Name", name)
	services[name] = object
	return object
end

service("ReplicatedStorage", "ReplicatedStorage")
service("ServerScriptService", "ServerScriptService")
service("ServerStorage", "ServerStorage")
service("StarterGui", "StarterGui")
service("StarterPack", "StarterPack")
service("Lighting", "Lighting")
service("Teams", "Teams")
service("Players", "Players")
service("SoundService", "SoundService")
service("RunService", "RunService")
service("TweenService", "TweenService")
service("UserInputService", "UserInputService")
service("Workspace", "Workspace")

local starterPlayer = M.new("StarterPlayer")
rawset(starterPlayer, "Name", "StarterPlayer")
local starterPlayerScripts = M.new("StarterPlayerScripts")
rawset(starterPlayerScripts, "Name", "StarterPlayerScripts")
starterPlayerScripts.Parent = starterPlayer
services.StarterPlayer = starterPlayer

local getService = function(self, name)
	local found = services[name]
	if not found then
		found = service(name, name)
	end
	return found
end

rawset(GAME, "GetService", getService)

_G.game = GAME
_G.workspace = services.Workspace

M.services = services
M.GAME = GAME

_G.print = print
_G.warn = function(...)
	local parts = {}
	for index = 1, select("#", ...) do
		parts[#parts + 1] = tostring(select(index, ...))
	end
	io.stderr:write("WARN: " .. table.concat(parts, " ") .. "\n")
end

return M
