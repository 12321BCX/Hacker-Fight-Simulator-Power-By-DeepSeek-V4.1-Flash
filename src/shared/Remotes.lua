--[[
	Remotes (ModuleScript)
	Location: ReplicatedStorage/HackerFight/Remotes

	Every RemoteEvent / RemoteFunction is created by the installer. This module
	only keeps the lookup in one place so a missing instance produces a clear
	error instead of a random nil index.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local root = ReplicatedStorage:WaitForChild("HackerFight", 20)
local folder = root and root:WaitForChild("Net", 20)

local function get(name)
	local instance = folder and folder:FindFirstChild(name)
	if not instance then
		warn("[HackerFight] Missing remote: " .. tostring(name) .. ". Run the installer again.")
	end
	return instance
end

function Remotes.event(name)
	return get(name)
end

function Remotes.func(name)
	return get(name)
end

return Remotes
