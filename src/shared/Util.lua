--[[
	Util (ModuleScript)
	Location: ReplicatedStorage/HackerFight/Util

	Small shared helpers used by both the server and the client.
--]]

local Util = {}

function Util.clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	elseif value > maxValue then
		return maxValue
	end
	return value
end

function Util.round(value, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

function Util.deepCopy(source)
	local copy = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			copy[key] = Util.deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

function Util.formatTime(seconds)
	local total = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", math.floor(total / 60), total % 60)
end

function Util.isAlive(player)
	local character = player and player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	return character:FindFirstChild("HumanoidRootPart") ~= nil
end

function Util.getRoot(player)
	local character = player and player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

function Util.getHumanoid(player)
	local character = player and player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

-- Returns every BasePart that belongs to a character (handles accessories).
function Util.getCharacterParts(character)
	local parts = {}
	if not character then
		return parts
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			parts[#parts + 1] = descendant
		end
	end
	return parts
end

function Util.findPlayerByName(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local lower = string.lower(name)
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if string.lower(player.Name) == lower or string.lower(player.DisplayName) == lower then
			return player
		end
	end
	return nil
end

function Util.distance(a, b)
	return (a - b).Magnitude
end

-- A safe wrapper so one failing tween / raycast never kills an ability loop.
function Util.try(fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok then
		return nil, tostring(result)
	end
	return result
end

return Util
