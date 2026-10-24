# START HERE - Hacker Fight Simulator

You only have to paste **one thing, once**. The installer creates every folder,
script, remote, weapon, arena and GUI object for you. You never create a script
by hand.

---

## Step 1 - Open Roblox Studio

1. Open **Roblox Studio**.
2. Create a new place: **File -> New -> Baseplate** (or open any empty place).
3. Stay in the normal **EDIT** view. Do **not** press Play yet.

## Step 2 - Open the Command Bar

1. In the top menu click **View**.
2. Click **Command Bar**.
3. A wide text box appears at the bottom of Studio.

## Step 3 - Paste the installer (this is the whole installation)

1. Open the file **`HackerFightInstaller.lua`** (it is in this project folder).
2. Select **all** of it: click inside it, press **Ctrl + A**, then **Ctrl + C**.
3. Click inside the **Command Bar** and press **Ctrl + V**.
4. Press **Enter** once.
   * If Enter only adds a new line, click the **Execute / Run button** on the
     right side of the Command Bar instead.
   * You can also make Enter execute commands: **File -> Studio Settings ->
     Studio -> Command Bar -> "Execute command with Return"**.

## Step 4 - Check that it worked

Look at the **Output** window (View -> Output). You should see:

```
[HackerFight Installer] SUCCESS - Hacker Fight Simulator v1.0.0 installed.
```

If you see `FAILED`, copy the red text and read the "Troubleshooting" part of
[README.md](README.md).

## Step 5 - Play it

1. Press **Play** (the blue triangle).
2. The hacker window opens automatically.
3. Controls:
   * **RightShift** - show / hide the hacker window
   * **W A S D** - move, **Space** - jump
   * **Left click** or **E** - attack
   * **H** button on the left edge - reopen the window after closing it
   * On a phone: tap the **HIT** button to attack, tap **H** to open the menu
4. Try the tabs: Combat, Move, Teleport, Visuals, Defense, Misc, Config. Every
   switch, slider and button is already connected.

## Step 6 - Save it

1. **File -> Save to File** (saves a local `.rbxl` copy), or
2. **File -> Publish to Roblox** to put it online (see below).

---

## Publish the game so other people can play

1. **File -> Publish to Roblox**.
2. Type a name (for example `Hacker Fight Simulator`) and a description.
3. Choose **Create new experience** (first time) or select the existing one.
4. Click **Publish**.
5. Open <https://create.roblox.com/dashboard/creations>, select your experience
   and click **Play** / **Public** to make it available.

Settings and waypoints are stored with **DataStoreService**. That works
automatically in a published game. Inside Studio it is off by default - see
"Turn on saved settings" in [README.md](README.md) if you want to test saving
before publishing.

---

## Starting over

Run the installer again. It replaces the previous install cleanly. It only
removes the objects it created:

* `ReplicatedStorage/HackerFight`
* `ServerScriptService/HackerFight`
* `StarterPlayer/StarterPlayerScripts/HackerFight`
* `StarterGui/HackerFightUI`
* `Workspace/HackerFightArena`
* `StarterPack/DataBlade`
* the `Hackers` and `Daemons` teams

Nothing else in your place is touched.

---

# 中文版（繁體中文）

你只需要複製貼上**一個東西，一次**。安裝器會替你建立所有的資料夾、腳本、遠端物件、武器、競技場和 GUI 物件。你永遠不需要手動建立任何腳本。

---

## 步驟 1 - 開啟 Roblox Studio

1. 開啟 **Roblox Studio**。
2. 建立新地圖：**File -> New -> Baseplate**（或開啟任何空白地圖）。
3. 停留在一般的 **EDIT（編輯）** 檢視。先**不要**按 Play。

## 步驟 2 - 開啟指令列（Command Bar）

1. 在上方選單點擊 **View**。
2. 點擊 **Command Bar**。
3. Studio 底部會出現一個寬的文字輸入框。

## 步驟 3 - 貼上安裝器（整個安裝就這一步）

1. 開啟檔案 **`HackerFightInstaller.lua`**（就在這個專案資料夾裡）。
2. **全選**：在檔案內點一下，按 **Ctrl + A**，再按 **Ctrl + C**。
3. 在**指令列**裡點一下，然後按 **Ctrl + V**。
4. 按一次 **Enter**。
   * 如果 Enter 只是換行，就改點指令列右側的**執行 / Run 按鈕**。
   * 你也可以設定 Enter 直接執行指令：**File -> Studio Settings ->
     Studio -> Command Bar -> "Execute command with Return"**。

## 步驟 4 - 確認是否成功

查看 **Output（輸出）** 視窗（View -> Output）。你應該會看到：

```
[HackerFight Installer] SUCCESS - Hacker Fight Simulator v1.0.0 installed.
```

如果看到 `FAILED`，請複製紅色文字，並閱讀 [README.md](README.md) 的「疑難排解」部分。

## 步驟 5 - 開始遊玩

1. 按 **Play**（藍色三角形）。
2. 駭客視窗會自動開啟。
3. 操作方式：
   * **RightShift** - 顯示 / 隱藏駭客視窗
   * **W A S D** - 移動，**Space** - 跳躍
   * **滑鼠左鍵**或 **E** - 攻擊
   * 左側邊緣的 **H** 按鈕 - 關閉視窗後重新打開
   * 手機上：點 **HIT** 按鈕攻擊，點 **H** 打開選單
4. 試試各個分頁：Combat、Move、Teleport、Visuals、Defense、Misc、Config。每個開關、滑桿和按鈕都已經接上功能。

## 步驟 6 - 儲存

1. **File -> Save to File**（儲存一份本地 `.rbxl` 副本），或
2. **File -> Publish to Roblox** 把遊戲發布到線上（見下方）。

---

## 發布遊戲，讓其他人也能玩

1. **File -> Publish to Roblox**。
2. 輸入一個名稱（例如 `Hacker Fight Simulator`）和遊戲說明。
3. 首次選擇 **Create new experience**，或選取既有的體驗。
4. 點擊 **Publish**。
5. 開啟 <https://create.roblox.com/dashboard/creations>，選取你的體驗，
   點擊 **Play** / **Public** 讓它上線。

設定和航點（waypoint）是用 **DataStoreService** 儲存的。在已發布的遊戲中會
自動運作。在 Studio 內預設是關閉的 - 如果你想在發布前先測試儲存功能，請參閱
[README.md](README.md) 的「開啟設定儲存」。

---

## 重新開始（重裝）

再執行一次安裝器即可。它會乾淨地取代上一次的安裝，只移除它自己建立的物件：

* `ReplicatedStorage/HackerFight`
* `ServerScriptService/HackerFight`
* `StarterPlayer/StarterPlayerScripts/HackerFight`
* `StarterGui/HackerFightUI`
* `Workspace/HackerFightArena`
* `StarterPack/DataBlade`
* `Hackers` 與 `Daemons` 兩個團隊

你地圖中的其他東西完全不會被更動。
