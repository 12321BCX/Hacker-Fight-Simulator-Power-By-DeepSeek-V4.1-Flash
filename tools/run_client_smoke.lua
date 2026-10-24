-- Headless smoke test: install with the mock, boot the real client Main script,
-- then click real GUI elements and assert the remotes receive the right calls.

local mock = dofile("tools/client_mock.lua")

local installerFile = assert(io.open("HackerFightInstaller.lua", "rb"))
local installerCode = installerFile:read("*a")
installerFile:close()
local installerChunk = assert(load(installerCode, "HackerFightInstaller"))
installerChunk()

local recorded = {}
mock.wireRemotes(recorded)

local failures = {}
local checks = 0

local function check(condition, message)
	checks = checks + 1
	if not condition then
		failures[#failures + 1] = message
	end
end

local function findAll(root, predicate, out)
	out = out or {}
	for _, child in ipairs(root:GetChildren()) do
		if predicate(child) then
			out[#out + 1] = child
		end
		findAll(child, predicate, out)
	end
	return out
end

local function findText(root, text)
	local found = findAll(root, function(item)
		return rawget(item, "Text") == text
	end)
	return found[1]
end

local services = mock.services
local starterPlayerScripts = services.StarterPlayer:FindFirstChild("StarterPlayerScripts")
local clientFolder = assert(starterPlayerScripts:FindFirstChild("HackerFight"), "client folder missing")
local mainScript = assert(clientFolder:FindFirstChild("Main"), "client Main missing")

local ok, err = pcall(function()
	mock.runScript(mainScript)
end)
if not ok then
	print("CLIENT BOOT FAIL: " .. tostring(err))
	os.exit(1)
end

local modules = clientFolder:FindFirstChild("Modules")
local UI = require(modules:FindFirstChild("UI"))
local HUD = require(modules:FindFirstChild("HUD"))
local Settings = require(modules:FindFirstChild("Settings"))

check(mock.playerGui:FindFirstChild("HackerFightUI") ~= nil, "ScreenGui not created")
local screen = mock.playerGui:FindFirstChild("HackerFightUI")
local window = screen and screen:FindFirstChild("Window")
check(window ~= nil and window.Visible == true, "window missing or hidden")

local content = window and window:FindFirstChild("Content")
check(content ~= nil, "content frame missing")
local pageCount = content and #content:GetChildren() or 0
check(pageCount == 8, "expected 8 tab pages, found " .. tostring(pageCount))
local function page(tabId)
	return content and content:FindFirstChild("Page_" .. tabId)
end

check(page("combat") ~= nil, "combat page missing")

local widgetCount = 0
for _ in pairs(UI.widgets) do
	widgetCount = widgetCount + 1
end
check(widgetCount >= 40, "expected 40+ widgets, found " .. tostring(widgetCount))

-- tab switching -------------------------------------------------------
local visualsTab = findText(window, "VISUALS")
check(visualsTab ~= nil, "VISUALS tab button missing")
if visualsTab then
	visualsTab.MouseButton1Click:Fire()
	local visualsPage = page("visuals")
	local combatPage = page("combat")
	check(visualsPage and visualsPage.Visible == true, "visuals page did not open")
	check(combatPage and combatPage.Visible == false, "combat page stayed visible")
end

-- toggle wiring -------------------------------------------------------
local fakeInput = {
	UserInputType = Enum.UserInputType.MouseButton1,
	UserInputState = Enum.UserInputState.Begin,
	Position = Vector2.new(10, 10),
}

local combatPage = page("combat")
local killauraRow = combatPage and combatPage:FindFirstChild("Row_killaura")
check(killauraRow ~= nil, "kill aura row missing")
if killauraRow then
	killauraRow.InputBegan:Fire(fakeInput)
end

local function recordedCall(remoteName, action)
	for _, entry in ipairs(recorded) do
		if entry.remote == remoteName and entry.args[1] == action then
			return entry
		end
	end
	return nil
end

local killauraCall = recordedCall("Settings", "set")
check(killauraCall ~= nil and killauraCall.args[2] == "killaura" and killauraCall.args[3] == true,
	"kill aura toggle did not reach the settings remote")

local movePage = page("movement")
local flyRow = movePage and movePage:FindFirstChild("Row_fly")
check(flyRow ~= nil, "fly row missing")
if flyRow then
	flyRow.InputBegan:Fire(fakeInput)
end
local flyCall = recordedCall("Ability", "fly")
check(flyCall ~= nil and flyCall.args[2] == true, "fly toggle did not reach the ability remote")

-- button wiring -------------------------------------------------------
local dashButton = findText(movePage, "Dash Forward")
check(dashButton ~= nil, "dash button missing")
if dashButton then
	dashButton.MouseButton1Click:Fire()
end
check(recordedCall("Ability", "dash") ~= nil, "dash button did not send a dash request")

local godButton = findText(window, "God Mode (5s)")
check(godButton ~= nil, "god mode button missing")
if godButton then
	godButton.MouseButton1Click:Fire()
end
check(recordedCall("Ability", "godmode") ~= nil, "god mode button did not send a request")

-- teleport buttons ----------------------------------------------------
local spawnButton = findText(window, "Teleport to Spawn")
check(spawnButton ~= nil, "teleport to spawn button missing")
if spawnButton then
	spawnButton.MouseButton1Click:Fire()
end
check(recordedCall("Teleport", "spawn") ~= nil, "spawn teleport did not reach the server remote")

-- search filter -------------------------------------------------------
local search = window:FindFirstChild("Search")
check(search ~= nil, "search box missing")
if search and combatPage then
	search.Text = "esp"
	search:GetPropertyChangedSignal("Text"):Fire()
	local espRow = page("visuals"):FindFirstChild("Row_esp_player")
	check(espRow ~= nil and espRow.Visible == true, "search did not show the esp row")
	check(combatPage:FindFirstChild("Row_killaura").Visible == false, "search did not hide non matching rows")
	search.Text = ""
	search:GetPropertyChangedSignal("Text"):Fire()
end

-- dynamic lists -------------------------------------------------------
UI.setPlayerList("roster", {
	{ name = "TestPlayer", displayName = "TestPlayer", health = 90, maxHealth = 100, team = "FFA", kills = 1, deaths = 0 },
}, function() end)
local rosterWidget = UI.widgets["roster"]
local rosterRows = rosterWidget and #rosterWidget.holder:GetChildren() or 0
check(rosterRows >= 3, "roster list did not render (children: " .. tostring(rosterRows) .. ")")

UI.setList("historylist", {
	{ text = "Test waypoint", sub = "10, 4, 10", action = "go", index = 1 },
}, function() end)
check(#UI.widgets["historylist"].holder:GetChildren() >= 3, "history list did not render")

-- HUD ----------------------------------------------------------------
HUD.setRound({
	modeName = "Team Deathmatch",
	phase = "Active",
	timeLeft = 42,
	roundNumber = 2,
	teamBased = true,
	scores = { Hackers = 4, Daemons = 2 },
	scoreToWin = 25,
})
local hudFrame = screen:FindFirstChild("HUD")
local hackersLabel = findAll(hudFrame, function(item)
	return type(rawget(item, "Text")) == "string" and string.find(rawget(item, "Text"), "HACKERS", 1, true) ~= nil
end)
check(#hackersLabel > 0, "HUD did not render the team score")
HUD.setCooldown("godmode", 12, 30)
check(UI.cooldowns["godmode"] ~= nil, "cooldown was not registered")

-- settings persistence plumbing --------------------------------------
check(Settings.get("theme") == "matrix", "settings did not load defaults")
Settings.apply("theme", "cyan", true)
check(UI.themeId == "cyan", "theme change did not reach the UI")
check(recordedCall("Settings", "set") ~= nil, "settings were not pushed to the server")

-- no runtime errors / warnings ---------------------------------------
if _G.HF_ERRORS then
	for _, message in ipairs(_G.HF_ERRORS) do
		failures[#failures + 1] = "runtime error: " .. tostring(message)
	end
end
for _, message in ipairs(_G.HF_WARNINGS or {}) do
	failures[#failures + 1] = "warning: " .. tostring(message)
end

print(string.format("client smoke: %d checks, %d remote calls recorded", checks, #recorded))
if #failures > 0 then
	for _, failure in ipairs(failures) do
		print("SMOKE FAIL: " .. tostring(failure))
	end
	os.exit(1)
end
print("client smoke: OK")
os.exit(0)
