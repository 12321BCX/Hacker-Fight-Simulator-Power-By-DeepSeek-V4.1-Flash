--[[
	Settings (ModuleScript)
	Location: StarterPlayer/StarterPlayerScripts/HackerFight/Modules/Settings

	Client copy of the saved settings. The server holds the real copy; this
	module keeps the UI responsive and forwards every change to the server,
	which validates and persists it.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:WaitForChild("HackerFight")
local Config = require(root:WaitForChild("Config"))
local Remotes = require(root:WaitForChild("Remotes"))

local Settings = {}

Settings.values = {}
Settings.waypoints = {}
Settings.persistent = false
Settings.onChanged = nil
Settings.onWaypoints = nil
Settings.loaded = false

local function schemaOf(key)
	return Config.Settings[key]
end

function Settings.clampValue(key, value)
	local schema = schemaOf(key)
	if not schema then
		return nil
	end
	if schema.type == "number" then
		local number = tonumber(value)
		if number == nil or number ~= number then
			return nil
		end
		return math.clamp(number, schema.min, schema.max)
	elseif schema.type == "boolean" then
		if type(value) ~= "boolean" then
			return nil
		end
		return value
	elseif schema.type == "string" then
		if type(value) ~= "string" then
			return nil
		end
		if schema.maxLength and #value > schema.maxLength then
			return nil
		end
		if schema.choices then
			local allowed = false
			for _, choice in ipairs(schema.choices) do
				if choice == value then
					allowed = true
				end
			end
			if not allowed then
				return nil
			end
		end
		return value
	end
	return nil
end

function Settings.get(key)
	local value = Settings.values[key]
	if value == nil then
		local schema = schemaOf(key)
		if schema then
			return schema.default
		end
	end
	return value
end

function Settings.set(key, value)
	local clean = Settings.clampValue(key, value)
	if clean == nil then
		return false
	end
	Settings.values[key] = clean
	if Settings.onChanged then
		local ok, err = pcall(Settings.onChanged, key, clean)
		if not ok then
			warn("[HackerFight][Settings] onChanged error: " .. tostring(err))
		end
	end
	return true
end

local lastPush = {}

function Settings.push(key)
	-- Sliders fire on every pixel of movement; keep the remote traffic sane.
	local now = os.clock()
	if lastPush[key] and now - lastPush[key] < 0.2 then
		return
	end
	lastPush[key] = now
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("set", key, Settings.get(key))
	end
end

function Settings.apply(key, value, save)
	if not Settings.set(key, value) then
		return false
	end
	if save then
		Settings.push(key)
	end
	return true
end

function Settings.save()
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("save")
	end
end

function Settings.resetAll()
	for key, schema in pairs(Config.Settings) do
		Settings.values[key] = schema.default
	end
	local remote = Remotes.event("Settings")
	if remote then
		remote:FireServer("reset")
	end
	if Settings.onChanged then
		for key in pairs(Config.Settings) do
			pcall(Settings.onChanged, key, Settings.get(key))
		end
	end
end

function Settings.Init(ctx)
	for key, schema in pairs(Config.Settings) do
		Settings.values[key] = schema.default
	end
	Settings.ctx = ctx

	local getter = Remotes.func("GetSettings")
	if getter then
		local ok, data = pcall(function()
			return getter:InvokeServer()
		end)
		if ok and type(data) == "table" and type(data.settings) == "table" then
			for key, value in pairs(data.settings) do
				Settings.set(key, value)
			end
			Settings.persistent = data.persistent == true
			if type(data.waypoints) == "table" then
				Settings.waypoints = data.waypoints
			end
		else
			warn("[HackerFight][Settings] could not load saved settings")
		end
	end
	Settings.loaded = true

	local remote = Remotes.event("Settings")
	if remote then
		remote.OnClientEvent:Connect(function(action, a, b, c)
			if action == "sync" and type(a) == "table" then
				for key, value in pairs(a) do
					Settings.set(key, value)
				end
				if ctx and ctx.notify then
					ctx.notify("Settings reloaded from server", "success")
				end
			elseif action == "saved" then
				if ctx and ctx.notify then
					if a then
						ctx.notify("Settings saved", "success")
					else
						ctx.notify("Could not save: " .. tostring(b or "unknown"), "warn")
					end
				end
			elseif action == "rejected" then
				if ctx and ctx.notify then
					ctx.notify("Server rejected setting: " .. tostring(a), "warn")
				end
			elseif action == "waypoints" then
				if type(a) == "table" then
					Settings.waypoints = a
				end
				if Settings.onWaypoints then
					Settings.onWaypoints(a, b, c)
				end
			end
		end)
	end
end

return Settings
