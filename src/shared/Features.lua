--[[
	Features (ModuleScript)
	Location: ReplicatedStorage/HackerFight/Features

	Single source of truth for the GUI: tab order and every row. The client
	builder reads this table and creates real, working widgets, so adding a
	feature here automatically creates its UI. The server still decides whether
	each requested action is allowed.
--]]

local Features = {}

Features.Tabs = {
	{ id = "player", label = "PLAYER", glyph = "P" },
	{ id = "combat", label = "COMBAT", glyph = "C" },
	{ id = "movement", label = "MOVE", glyph = "M" },
	{ id = "teleport", label = "TELEPORT", glyph = "T" },
	{ id = "visuals", label = "VISUALS", glyph = "V" },
	{ id = "defense", label = "DEFENSE", glyph = "D" },
	{ id = "misc", label = "MISC", glyph = "X" },
	{ id = "settings", label = "CONFIG", glyph = "S" },
}

-- kind: header | toggle | slider | button | cycle | keybind | playerlist |
--       waypoints | history | info | stats
Features.Rows = {
	---------------- PLAYER ----------------
	{ tab = "player", kind = "header", label = "YOUR AGENT" },
	{ tab = "player", kind = "stats", id = "stats_your", label = "Kills / Deaths / Score" },
	{ tab = "player", kind = "header", label = "LOBBY ROSTER" },
	{ tab = "player", kind = "playerlist", id = "roster", label = "Players (tap to target)" },
	{ tab = "player", kind = "info", id = "team_info", label = "Team", text = "No team" },

	---------------- COMBAT ----------------
	{ tab = "combat", kind = "header", label = "MASTER SWITCH" },
	{ id = "combatenabled", tab = "combat", kind = "toggle", label = "Combat Abilities", hint = "Turns every offensive feature on or off at once" },
	{ tab = "combat", kind = "header", label = "OFFENSIVE" },
	{ id = "killaura", tab = "combat", kind = "toggle", label = "Kill Aura", hint = "Auto attacks the closest enemy inside Reach" },
	{ id = "autoattack", tab = "combat", kind = "toggle", label = "Auto Attack", hint = "Attacks automatically when a target is in range" },
	{ id = "aimbot", tab = "combat", kind = "toggle", label = "Target Lock", hint = "Locks your camera on the selected / nearest enemy" },
	{ tab = "combat", kind = "header", label = "TUNING" },
	{ id = "reach", tab = "combat", kind = "slider", label = "Reach", min = 5, max = 20, step = 1, suffix = " studs" },
	{ id = "dmgmult", tab = "combat", kind = "slider", label = "Damage Multiplier", min = 1, max = 1.5, step = 0.05, suffix = "x" },
	{ tab = "combat", kind = "info", id = "combat_status", label = "Status", text = "Idle" },

	---------------- MOVEMENT ----------------
	{ tab = "movement", kind = "header", label = "FLIGHT" },
	{ id = "fly", tab = "movement", kind = "toggle", label = "Fly", hint = "Server grants a flight window; move with WASD + Space / Ctrl" },
	{ id = "flyspeed", tab = "movement", kind = "slider", label = "Flight Speed", min = 20, max = 90, step = 1, suffix = " studs/s" },
	{ tab = "movement", kind = "header", label = "GROUND" },
	{ id = "speed", tab = "movement", kind = "slider", label = "Walk Speed", min = 16, max = 80, step = 1, suffix = " studs/s" },
	{ id = "jump", tab = "movement", kind = "slider", label = "Jump Power", min = 50, max = 200, step = 5, suffix = "" },
	{ id = "infjump", tab = "movement", kind = "toggle", label = "Infinite Jump", hint = "Jump again at any time while airborne" },
	{ id = "doublejump", tab = "movement", kind = "toggle", label = "Double Jump", hint = "One extra jump while airborne" },
	{ id = "tpwalk", tab = "movement", kind = "toggle", label = "TP Walk", hint = "Short server validated blinks while moving" },
	{ id = "noclip", tab = "movement", kind = "toggle", label = "Noclip", hint = "Server clears collisions on your character" },
	{ tab = "movement", kind = "header", label = "BURST" },
	{ tab = "movement", kind = "button", id = "dash", label = "Dash Forward", cooldown = "dash" },

	---------------- TELEPORT ----------------
	{ tab = "teleport", kind = "header", label = "TARGET" },
	{ tab = "teleport", kind = "playerlist", id = "tp_playerlist", label = "Teleport to player" },
	{ tab = "teleport", kind = "button", id = "tp_spawn", label = "Teleport to Spawn" },
	{ tab = "teleport", kind = "header", label = "WAYPOINTS" },
	{ tab = "teleport", kind = "button", id = "wp_save", label = "Save Current Position" },
	{ tab = "teleport", kind = "waypoints", id = "waypointlist", label = "Saved Waypoints" },
	{ tab = "teleport", kind = "history", id = "historylist", label = "Teleport History" },
	{ tab = "teleport", kind = "header", label = "OPTIONS" },
	{ id = "safetp", tab = "teleport", kind = "toggle", label = "Safe Teleport", hint = "Server raycasts the destination before moving you" },
	{ tab = "teleport", kind = "info", id = "tp_cooldown", label = "Cooldown", text = "Ready" },

	---------------- VISUALS ----------------
	{ tab = "visuals", kind = "header", label = "PLAYER ESP" },
	{ id = "esp_player", tab = "visuals", kind = "toggle", label = "Player ESP", hint = "Neon highlight on every valid target" },
	{ id = "esp_box", tab = "visuals", kind = "toggle", label = "Box ESP", hint = "Outline box around characters" },
	{ id = "esp_name", tab = "visuals", kind = "toggle", label = "Name ESP", hint = "Name tag above the character" },
	{ id = "esp_dist", tab = "visuals", kind = "toggle", label = "Distance ESP", hint = "Studs between you and the target" },
	{ id = "esp_health", tab = "visuals", kind = "toggle", label = "Health ESP", hint = "Health bar above the character" },
	{ tab = "visuals", kind = "header", label = "OVERLAYS" },
	{ id = "esp_skeleton", tab = "visuals", kind = "toggle", label = "Skeleton ESP", hint = "Simplified bone lines" },
	{ id = "esp_tracer", tab = "visuals", kind = "toggle", label = "Tracer ESP", hint = "Line from screen bottom to each target" },
	{ id = "loscheck", tab = "visuals", kind = "toggle", label = "Visibility Check", hint = "Hide targets behind walls" },
	{ id = "crosshair", tab = "visuals", kind = "toggle", label = "Custom Crosshair", hint = "Neon crosshair + target readout" },
	{ tab = "visuals", kind = "header", label = "FILTER + COLOR" },
	{ id = "teamfilter", tab = "visuals", kind = "cycle", label = "Team Filter", options = { "everyone", "enemies", "allies" } },
	{ id = "colorpreset", tab = "visuals", kind = "cycle", label = "Color Preset", options = { "1", "2", "3", "4" } },
	{ id = "performance", tab = "visuals", kind = "toggle", label = "Performance Mode", hint = "Slower ESP updates for low end devices" },

	---------------- DEFENSE ----------------
	{ tab = "defense", kind = "header", label = "SERVER GRANTED ABILITIES" },
	{ tab = "defense", kind = "button", id = "godmode", label = "God Mode (5s)", cooldown = "godmode" },
	{ tab = "defense", kind = "button", id = "shield", label = "Shield (8s)", cooldown = "shield" },
	{ tab = "defense", kind = "button", id = "heal", label = "Heal +35 HP", cooldown = "heal" },
	{ tab = "defense", kind = "button", id = "invis", label = "Invisibility (6s)", cooldown = "invis" },
	{ tab = "defense", kind = "button", id = "antiknock", label = "Anti Knockback (6s)", cooldown = "antiknock" },
	{ tab = "defense", kind = "button", id = "escape", label = "Emergency Escape", cooldown = "escape" },
	{ tab = "defense", kind = "info", id = "defense_status", label = "Active", text = "None" },

	---------------- MISC ----------------
	{ tab = "misc", kind = "header", label = "INTERFACE" },
	{ id = "sounds", tab = "misc", kind = "toggle", label = "UI Sounds", hint = "Clicks and notifications" },
	{ id = "killfeed", tab = "misc", kind = "toggle", label = "Kill Feed", hint = "Show eliminations on screen" },
	{ tab = "misc", kind = "button", id = "reset_stats", label = "Reset My Session Stats" },
	{ tab = "misc", kind = "info", id = "round_info", label = "Match", text = "..." },

	---------------- SETTINGS ----------------
	{ tab = "settings", kind = "header", label = "CONTROLS" },
	{ tab = "settings", kind = "keybind", id = "keybind", label = "GUI Toggle Key" },
	{ tab = "settings", kind = "header", label = "APPEARANCE" },
	{ id = "theme", tab = "settings", kind = "cycle", label = "Theme", options = { "matrix", "cyan", "purple", "blood" } },
	{ id = "uiscale", tab = "settings", kind = "slider", label = "UI Scale", min = 0.7, max = 1.3, step = 0.05, suffix = "x" },
	{ tab = "settings", kind = "header", label = "DATA" },
	{ tab = "settings", kind = "button", id = "save_settings", label = "Save Settings" },
	{ tab = "settings", kind = "button", id = "reset_settings", label = "Reset All Settings" },
	{ tab = "settings", kind = "info", id = "data_status", label = "Storage", text = "Loading..." },
}

Features.byId = {}
for _, row in ipairs(Features.Rows) do
	if row.id then
		Features.byId[row.id] = row
	end
end

return Features
