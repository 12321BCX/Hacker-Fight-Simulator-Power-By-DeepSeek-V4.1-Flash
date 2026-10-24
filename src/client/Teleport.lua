--[[
	Teleport (ModuleScript)
	Location: StarterPlayer/StarterPlayerScripts/HackerFight/Modules/Teleport

	The client never moves itself here: it asks the server, and the server
	validates cooldown, bounds and landing safety. This module keeps the local
	history, the waypoint list and the cooldown readout in sync.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:WaitForChild("HackerFight")
local Config = require(root:WaitForChild("Config"))
local Remotes = require(root:WaitForChild("Remotes"))

local Teleport = {}

Teleport.history = {}
Teleport.cooldownUntil = 0
Teleport.ctx = nil

local HISTORY_LIMIT = 8

local function pushHistory(label, position)
	table.insert(Teleport.history, 1, { label = label, position = position })
	while #Teleport.history > HISTORY_LIMIT do
		table.remove(Teleport.history)
	end
end

local function startCooldown()
	Teleport.cooldownUntil = os.clock() + Config.TeleportCooldown
end

function Teleport.remaining()
	return math.max(0, Teleport.cooldownUntil - os.clock())
end

function Teleport.toPlayer(name)
	local remote = Remotes.event("Teleport")
	if not remote or type(name) ~= "string" then
		return
	end
	remote:FireServer("player", { target = name })
	pushHistory("Player: " .. name, nil)
	startCooldown()
end

function Teleport.toSpawn()
	local remote = Remotes.event("Teleport")
	if remote then
		remote:FireServer("spawn", {})
		pushHistory("Spawn", nil)
		startCooldown()
	end
end

function Teleport.toPosition(position, label)
	local remote = Remotes.event("Teleport")
	if not remote or typeof(position) ~= "Vector3" then
		return
	end
	remote:FireServer("coords", { position = position })
	pushHistory(label or "Waypoint", position)
	startCooldown()
end

function Teleport.saveWaypoint()
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("wp_add")
	end
end

function Teleport.deleteWaypoint(index)
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("wp_del", index)
	end
end

Teleport.handlers = {
	tp_spawn = function()
		Teleport.toSpawn()
	end,
	wp_save = function()
		Teleport.saveWaypoint()
	end,
}

function Teleport.Init(ctx)
	Teleport.ctx = ctx
	local settings = ctx.modules.Settings

	local function refreshLists()
		if not ctx.ui then
			return
		end
		local waypointItems = {}
		for index, position in ipairs(settings.waypoints) do
			waypointItems[#waypointItems + 1] = {
				text = string.format("WP %d  (%.0f, %.0f, %.0f)", index, position.X, position.Y, position.Z),
				action = "go",
				position = position,
				index = index,
			}
		end
		ctx.ui.setList("waypointlist", waypointItems, function(item)
			if item.action == "go" then
				Teleport.toPosition(item.position, "Waypoint " .. tostring(item.index))
			end
		end, function(item)
			Teleport.deleteWaypoint(item.index)
		end)

		local historyItems = {}
		for index, entry in ipairs(Teleport.history) do
			historyItems[#historyItems + 1] = {
				text = entry.label,
				sub = entry.position and string.format("%.0f, %.0f, %.0f", entry.position.X, entry.position.Y, entry.position.Z) or "player",
				action = "go",
				position = entry.position,
				index = index,
			}
		end
		ctx.ui.setList("historylist", historyItems, function(item)
			if item.action == "go" and item.position then
				Teleport.toPosition(item.position, "History: " .. tostring(item.text))
			end
		end)
	end

	settings.onWaypoints = function(_, ok, err)
		if ok == false and err and ctx.notify then
			ctx.notify("Waypoint rejected: " .. tostring(err), "warn")
		elseif ok then
			ctx.notify("Waypoint saved", "success")
			ctx.ui.click()
		end
		refreshLists()
	end

	Teleport.refreshLists = refreshLists
	refreshLists()

	task.spawn(function()
		while true do
			task.wait(0.5)
			if ctx.ui then
				local remaining = Teleport.remaining()
				if remaining > 0 then
					ctx.ui.setInfo("tp_cooldown", string.format("%.1fs", remaining), "warn")
				else
					ctx.ui.setInfo("tp_cooldown", "Ready", "success")
				end
			end
		end
	end)
end

return Teleport
