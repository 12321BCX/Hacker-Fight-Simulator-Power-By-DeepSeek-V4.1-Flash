# Hacker Fight Simulator

A complete, server-authoritative Roblox fighting game with a neon hacker
interface, five game modes and 30+ working features. Everything is installed by
**one paste** into the Roblox Studio Command Bar.

* Beginner steps: **[START_HERE.md](START_HERE.md)**
* Installer: **[HackerFightInstaller.lua](HackerFightInstaller.lua)** (the only file you paste)
* Source for every script: `src/`

---

## 1. What the installer creates

```
ReplicatedStorage/
  HackerFight/
    Config            ModuleScript - balance, limits, settings schema, themes
    Util              ModuleScript - shared helpers
    Features          ModuleScript - tab + row definitions used to build the GUI
    Remotes           ModuleScript - remote lookup
    Net/
      Attack  Ability  Teleport  Settings  State  AbilityState
      Feedback  KillFeed  CombatFX                 (RemoteEvents)
      GetRoster  GetSettings  GetRound             (RemoteFunctions)

ServerScriptService/
  HackerFight/
    Main              Script - boots services, wires RemoteFunctions
    Services/
      DataService     settings + waypoints persistence (DataStore)
      RoundService    modes, rounds, teams, spawn protection, scoring, dummies
      TeleportService validated teleports, safe landing, escape points
      AbilityService  fly window, speed, jump, noclip, god/shield/heal/invis
      CombatService   attacks, damage, reach, cooldowns, kills

StarterPlayer/StarterPlayerScripts/
  HackerFight/
    Main              LocalScript
    Modules/
      UI              builds and controls the whole hacker window
      HUD             match banner, health, kill feed, cooldowns, crosshair
      Abilities       movement client half (fly, TP walk, jumps, dash)
      Combat          kill aura, auto attack, target lock, weapon input
      Visuals         player / box / name / distance / health / skeleton / tracer ESP
      Teleport        teleport requests, waypoints, history
      Settings        client copy of saved settings

StarterGui/HackerFightUI        ScreenGui (window shell; the client fills it in)
StarterPack/DataBlade           Tool (neon blade, left click / tap to attack)
Workspace/HackerFightArena      floor, grid, walls, 6 spawns, 4 arena spawns,
                                training dummy folder, pillars
Teams/Hackers, Teams/Daemons    Team Deathmatch teams
```

Re-running the installer replaces exactly these objects and nothing else.

---

## 2. Features

| Tab | Working features |
| --- | --- |
| **Player** | live roster with health / team / K/D, tap a player to select them as target |
| **Combat** | combat master switch, kill aura, auto attack, target lock (camera), reach 5-20, damage multiplier 1.0-1.5, live status |
| **Move** | fly + flight speed, walk speed 16-80, jump power 50-200, infinite jump, double jump, TP walk, noclip, dash |
| **Teleport** | teleport to player, teleport to spawn, 5 saved waypoints with delete, teleport history, safe teleport, cooldown readout |
| **Visuals** | player ESP, box ESP, name ESP, distance, health bar, skeleton, tracers, visibility check, team filter, 4 colour presets, crosshair, performance mode |
| **Defense** | god mode (5 s), shield (60 absorb), heal +35, invisibility (6 s), anti-knockback (6 s), emergency escape |
| **Misc** | UI sounds, kill feed, reset session stats, current match info |
| **Config** | GUI toggle keybind, 4 themes, UI scale 0.7-1.3, save settings, reset all settings, storage status |

Interface: draggable window, minimize / maximize / close, toggle key
(RightShift by default), per-tab scrolling, global search, animated toggles and
sliders, ON/OFF state on every switch, touch layout with an on-screen **HIT**
button, theme + scale applied live.

Game modes rotate automatically: Free-for-All -> Team Deathmatch -> Hacker
Battle Arena -> Ability-Only Combat -> Training Grounds. Each round has a
countdown, spawn protection, scoring to 25, respawns, a kill feed and
`leaderstats` (Kills / Deaths / Score).

---

## 3. Server authority (how the cheating surface is controlled)

The client only ever **asks**. Every sensitive action is re-checked on the
server:

| Action | Server checks |
| --- | --- |
| Attack | phase is Active, attacker alive, spawn protection, per-player 0.45 s cooldown, reach clamped to 5-20, target must be an alive enemy inside reach + latency tolerance, team check, god mode, shield absorption, damage = 12 x multiplier clamped to 1.0-1.5 (forced to 1.0 in Ability-Only) |
| Speed / jump | slider value clamped to the configured min/max, then applied to the Humanoid by the server |
| Noclip | server clears `CanCollide` on character parts for max 30 s, then restores the original values |
| Fly | server grants a 12 s window, monitors horizontal speed and revokes flight above 1.8x the cap; the client only applies the movement |
| God / shield / heal / invis / anti-knock / escape / dash | cooldowns, durations and amounts live in `Config.Abilities`; invisibility breaks on attack; shield absorbs before health |
| Teleport | 4 s cooldown, alive check, target alive, world bounds, max distance, optional floor raycast (safe landing) - the server performs the move |
| Settings | whitelisted keys only, type checks, numeric clamps, string choice checks, 5 waypoint limit, bounds check |
| Jump requests | per-second rate limit, feature must be enabled in the server's saved settings |

Remote traffic is throttled on the client too (sliders coalesce to one request
per 100 ms; settings saves are debounced), so gameplay requests stay small.

---

## 4. Testing checklist

Studio, one player:

1. Paste the installer in the Command Bar (edit mode) -> Output shows `SUCCESS`.
2. Press Play: the window opens, `RightShift` hides / shows it, the `H` button
   reopens it after closing.
3. Every tab opens; search filters rows and jumps to the tab with matches.
4. Move tab: walk speed, jump power, fly (Space / Ctrl for altitude), noclip
   through a wall, dash, TP walk while holding W.
5. Combat tab: enable kill aura near a dummy in Training, or attack another
   player in a two-player test. Cooldown chips light up on Defense casts.
6. Teleport tab: save a waypoint, teleport to spawn, select a player (needs two
   players), check the cooldown readout.
7. Visuals tab: toggle each ESP layer, switch team filter, cycle the 4 colour
   presets, turn on performance mode (skeleton / tracers hide).
8. Config tab: change theme and UI scale, click Save, leave and rejoin to see
   the values restored (requires API services - see below).
9. Defense tab: god mode blocks damage, shield absorbs, heal restores, escape
   moves you to the safest spawn.

Multiplayer (Test -> Clients and Servers -> 2 players):

10. TDM: teams are balanced, teammates cannot damage each other, team scores
    update in the HUD and leaderboard.
11. Spawn protection blocks attacks for 4 s after a respawn (ForceField shimmer).
12. Kill feed shows "killer >> victim"; deaths and kills increment.
13. Teleport to the other player works; safe teleport refuses unsafe spots.

Mobile (Test -> Device -> iPhone / iPad):

14. Window fits the screen, tabs scroll horizontally, sliders drag, toggles tap.
15. The **HIT** button attacks; the **H** button opens the UI.

Performance:

16. Low-end mode: turn on Performance Mode in Visuals; ESP updates at 5 Hz and
    skeleton / tracers are off.

---

## 5. Turn on saved settings in Studio

`DataStoreService` is blocked in Studio until you allow it:

1. **File -> Studio Settings -> Security**.
2. Enable **"Enable Studio Access to API Services"**.
3. Restart the Play session.

In a published experience saving works without this. Without it the game still
runs; settings simply stay in memory for the session and the Config tab shows
`Studio API OFF`.

---

## 6. Honest limitations

Roblox gives the owner of a character authority over that character's physics.
The design works with that instead of pretending otherwise:

* **Fly, air jumps and anti-knockback** are *granted* by the server (window,
  cooldown, rate limit, speed monitor) but applied on the client. Making them
  fully server-simulated would need a custom character controller and would feel
  laggy for everyone. Everything with a real gameplay consequence - damage,
  range, cooldowns, collisions, teleports, shields, healing - is server-side.
* **ESP is a local overlay.** It can only draw information the server already
  replicates (characters, health, teams). Invisible players carry a replicated
  `HackerInvisible` attribute and are skipped. The visibility check uses client
  raycasts, so it is a gameplay aid, not an anti-cheat.
* **Target lock** rotates the local camera toward a validated enemy. It cannot
  create hits by itself; every attack is resolved by the server.
* **Training dummies** are static models with a Humanoid (150 HP, respawn after
  2.5 s). They do not move or shoot back.
* **Ability-Only Combat** forces the damage multiplier to 1.0; all combat in the
  game is already ability-based, so there is no separate weapon damage table.
* **The GUI shell is created by the installer; the full window is assembled on
  the first join.** Roblox cannot create a finished, wired GUI tree at
  edit time from the Command Bar without also shipping the code that runs it, so
  the client builds the tabs, rows and handlers when a player joins. You never
  create anything by hand.
* **Studio version**: pasting multi-line code into the Command Bar needs a
  current Studio (the multi-line Command Bar finished rolling out in March 2026).
  On older versions the installer cannot run - update Studio.
* **Balance is a starting point**, not a ranked ruleset. Tune `Config` in
  `ReplicatedStorage/HackerFight` (no installer rerun needed).

---

## 7. Troubleshooting

| Symptom | Fix |
| --- | --- |
| `FAILED: ... Source ... permission` | You are not in the Command Bar, or you pressed Play first. Stop the game, stay in Edit mode, run it from View -> Command Bar. |
| Nothing appears when you press Play | Open Output (View -> Output) and read the first red line. Usually the installer was stopped halfway - run it again. |
| Combat does nothing | The round is in intermission (HUD banner says "NEXT ROUND IN ..."), or you have spawn protection, or the target is outside Reach. |
| Settings do not save in Studio | Enable Studio Access to API Services (section 5). |
| "Missing remote" warning in Output | The install is incomplete: run the installer again. |
| Window is off-screen | Re-run the installer, join again, or press the `H` button; the window is re-centered on spawn. |

---

## 8. Developer workflow

```
src/
  shared/   Config, Util, Features, Remotes
  server/   Main + five services
  client/   Main + seven modules
tools/
  build_installer.py   embeds src/ into HackerFightInstaller.lua
  verify.py            static checks (syntax, remotes, handlers, protocol)
  mock_roblox.lua      minimal Roblox API mock
  client_mock.lua      signals, services, task shims, module loader
  run_installer.lua    installs with the mock and verifies the created tree
  run_client_smoke.lua installs, boots the real client, clicks real GUI elements
  run_server_smoke.lua boots the real server, drives remotes, checks damage etc.
  run_all.sh           runs everything
```

Rebuild after editing `src/`:

```bash
bash tools/run_all.sh
```

That regenerates `HackerFightInstaller.lua` and runs:

* byte-for-byte round-trip of all 18 embedded scripts
* Lua syntax parse of every source and the installer
* installer dry-run against the mock: 109 structural assertions
* client smoke test: boots the real `Main` LocalScript, 29 assertions, clicks
  toggles, buttons, tabs and the search box, asserts the remotes receive the
  right calls
* server smoke test: boots the real `Main` Script, 15 assertions, deals damage,
  rejects out-of-range attacks, verifies god mode, spawn protection, speed
  clamp, teleport validation, waypoint storage and RemoteFunctions
* static checks: remotes used == remotes created, every interactive row has a
  handler, every settings row exists in the schema, every client action is
  handled by the server, no deprecated APIs, no placeholder text

Limits of that harness: it runs Lua, not Roblox's physics/renderer. Visual
polish, actual flight feel and mobile layout still need a Studio playtest - that
is what the checklist in section 4 is for.

---

## 9. Security notes

This project is a **self-contained game**, not an executor or an exploit for
other experiences. All of its power-ups are server-validated game mechanics that
every player has. Nothing here injects into other games, and the client never
sends damage, hit results or trusted positions.

---

# 中文版（繁體中文）

一個完整的、伺服器權威（server-authoritative）的 Roblox 對戰遊戲，配有霓虹
駭客風格介面、五種遊戲模式與 30+ 個實際可用的功能。全部只要在 Roblox Studio
指令列**貼上一次**就能安裝。

* 新手步驟：**[START_HERE.md](START_HERE.md)**
* 安裝器：**[HackerFightInstaller.lua](HackerFightInstaller.lua)**（你唯一需要貼上的檔案）
* 所有腳本的原始碼：`src/`

---

## 1. 安裝器建立了什麼

```
ReplicatedStorage/
  HackerFight/
    Config            ModuleScript - 平衡數值、限制、設定架構、主題
    Util              ModuleScript - 共用輔助函式
    Features          ModuleScript - 用來建立 GUI 的分頁 + 列定義
    Remotes           ModuleScript - 遠端物件查表
    Net/
      Attack  Ability  Teleport  Settings  State  AbilityState
      Feedback  KillFeed  CombatFX                 (RemoteEvents)
      GetRoster  GetSettings  GetRound             (RemoteFunctions)

ServerScriptService/
  HackerFight/
    Main              Script - 啟動各服務、串接 RemoteFunctions
    Services/
      DataService     設定 + 航點持久化（DataStore）
      RoundService    模式、回合、團隊、出生保護、計分、訓練木樁
      TeleportService 經驗證的傳送、安全落地、逃生點
      AbilityService  飛行視窗、速度、跳躍、無碰撞、神模式/護盾/治療/隱形
      CombatService   攻擊、傷害、距離、冷卻、擊殺

StarterPlayer/StarterPlayerScripts/
  HackerFight/
    Main              LocalScript
    Modules/
      UI              建立並控制整個駭客視窗
      HUD             對局橫幅、血量、擊殺訊息、冷卻、準星
      Abilities       移動的客戶端半部（飛行、瞬移行走、跳躍、衝刺）
      Combat          自動殺傷光環、自動攻擊、目標鎖定、武器輸入
      Visuals         玩家 / 方框 / 名字 / 距離 / 血條 / 骨架 / 曳光線 ESP
      Teleport        傳送請求、航點、歷史紀錄
      Settings        已儲存設定的客戶端副本

StarterGui/HackerFightUI        ScreenGui（視窗外殼；由客戶端填入內容）
StarterPack/DataBlade           Tool（霓虹刀刃，左鍵 / 點觸攻擊）
Workspace/HackerFightArena      地板、格線、牆壁、6 個出生點、4 個競技場出生點、
                                訓練木樁資料夾、支柱
Teams/Hackers, Teams/Daemons    團隊死鬥（TDM）的兩個團隊
```

再次執行安裝器，只會精準取代這些物件，其他一律不動。

---

## 2. 功能一覽

| 分頁 | 實際可用的功能 |
| --- | --- |
| **Player** | 即時名冊，顯示血量 / 團隊 / K/D，點一下玩家即可將其選為目標 |
| **Combat** | 戰鬥總開關、自動殺傷光環（kill aura）、自動攻擊、目標鎖定（鏡頭）、攻擊距離 5-20、傷害倍率 1.0-1.5、即時狀態顯示 |
| **Move** | 飛行 + 飛行速度、行走速度 16-80、跳躍力量 50-200、無限跳、二段跳、瞬移行走（TP walk）、無碰撞（noclip）、衝刺（dash） |
| **Teleport** | 傳送到玩家、傳送到出生點、5 個可儲存航點（含刪除）、傳送歷史、安全傳送、冷卻顯示 |
| **Visuals** | 玩家 ESP、方框 ESP、名字 ESP、距離、血條、骨架、曳光線、可見性檢查、團隊篩選、4 組配色預設、準星、效能模式 |
| **Defense** | 神模式（5 秒）、護盾（吸收 60）、治療 +35、隱形（6 秒）、反擊退（6 秒）、緊急逃脫 |
| **Misc** | UI 音效、擊殺訊息、重置本次對局統計、目前對局資訊 |
| **Config** | GUI 開關按鍵、4 種主題、UI 縮放 0.7-1.3、儲存設定、重設所有設定、儲存狀態 |

介面：可拖曳視窗、最小化 / 最大化 / 關閉、開關按鍵（預設 RightShift）、
各分頁可捲動、全域搜尋、動畫開關與滑桿、每個開關都有 ON/OFF 狀態、觸控佈局
並附畫面上的 **HIT** 按鈕、主題與縮放即時套用。

遊戲模式自動輪替：自由混戰 -> 團隊死鬥 -> 駭客競技場 -> 僅限能力對戰 -> 訓練場。
每個回合都有倒數、出生保護、先到 25 分、重生、擊殺訊息，以及 `leaderstats`
（Kills / Deaths / Score）。

---

## 3. 伺服器權威（如何控管作弊面）

客戶端永遠只是**提出請求**。每一個敏感動作都會在伺服器重新檢查：

| 動作 | 伺服器檢查 |
| --- | --- |
| 攻擊 | 回合階段為 Active、攻擊者存活、出生保護、每位玩家 0.45 秒冷卻、攻擊距離限制在 5-20、目標必須是存活的敵人且在距離 + 延遲容差內、團隊檢查、神模式、護盾吸收、傷害 = 12 x 倍率並限制在 1.0-1.5（僅限能力對戰強制為 1.0） |
| 速度 / 跳躍 | 滑桿數值限制在設定的最小 / 最大值內，再由伺服器套用到 Humanoid |
| 無碰撞 | 伺服器最多 30 秒將角色部件的 `CanCollide` 清除，之後還原原本的值 |
| 飛行 | 伺服器授予 12 秒的視窗、監測水平速度，超過上限 1.8 倍就收回飛行權限；客戶端只負責套用移動 |
| 神模式 / 護盾 / 治療 / 隱形 / 反擊退 / 逃脫 / 衝刺 | 冷卻、持續時間與數值都定義在 `Config.Abilities`；攻擊會打破隱形；護盾先於血量吸收 |
| 傳送 | 4 秒冷卻、存活檢查、目標存活、世界邊界、最大距離、可選地板射線檢測（安全落地）- 移動由伺服器執行 |
| 設定 | 僅限白名單索引、型別檢查、數值限制、字串選項檢查、5 個航點上限、邊界檢查 |
| 跳躍請求 | 每秒請求頻率限制，且該功能必須在伺服器已儲存的設定中啟用 |

遠端流量在客戶端也有限流（滑桿每 100 毫秒合併為一次請求；設定儲存採防抖），
因此遊玩時的請求量保持精簡。

---

## 4. 測試清單

Studio，單人：

1. 在指令列貼上安裝器（編輯模式）-> Output 顯示 `SUCCESS`。
2. 按 Play：視窗開啟，`RightShift` 隱藏 / 顯示它，關閉後可用 `H` 按鈕
   重新開啟。
3. 每個分頁都能開啟；搜尋會篩選列，並跳到有符合項目的分頁。
4. Move 分頁：行走速度、跳躍力量、飛行（Space / Ctrl 控制高度）、穿牆無碰撞、
   衝刺、按住 W 的同時瞬移行走。
5. Combat 分頁：在訓練模式靠近木樁啟用 kill aura，或在兩人測試中攻擊
   另一位玩家。施放 Defense 能力時冷卻標籤會亮起。
6. Teleport 分頁：儲存一個航點、傳送到出生點、選取玩家（需要兩名玩家）、
   檢查冷卻顯示。
7. Visuals 分頁：切換每一個 ESP 層、切換團隊篩選、輪替 4 組配色、
   開啟效能模式（骨架 / 曳光線會關閉）。
8. Config 分頁：更換主題與 UI 縮放，點擊儲存，離開再重進查看數值是否還原
   （需要 API 服務 - 見下一節）。
9. Defense 分頁：神模式阻擋傷害、護盾吸收、治療回血、逃脫把你送到
   最安全的出生點。

多人（Test -> Clients and Servers -> 2 players）：

10. TDM：團隊均分，隊友無法互相傷害，團隊分數在 HUD 與排行榜更新。
11. 重生後 4 秒內出生保護會阻擋攻擊（ForceField 微光）。
12. 擊殺訊息顯示「兇手 >> 受害者」；擊殺數與死亡數累加。
13. 傳送到另一名玩家成功；安全傳送會拒絕不安全的位置。

行動裝置（Test -> Device -> iPhone / iPad）：

14. 視窗符合螢幕、分頁可水平捲動、滑桿可拖曳、開關可點擊。
15. **HIT** 按鈕可以攻擊；**H** 按鈕開啟 UI。

效能：

16. 低階裝置模式：在 Visuals 開啟 Performance Mode；ESP 以 5 Hz 更新，
    骨架 / 曳光線關閉。

---

## 5. 在 Studio 中開啟設定儲存

`DataStoreService` 在 Studio 中預設被封鎖，直到你允許它：

1. **File -> Studio Settings -> Security**。
2. 啟用 **"Enable Studio Access to API Services"**。
3. 重新啟動 Play 會話。

在已發布的體驗中，不需要這個設定也能儲存。沒有它的話遊戲仍然會執行；
設定只會留在該次會話的記憶體中，且 Config 分頁會顯示 `Studio API OFF`。

---

## 6. 如實說明的限制

Roblox 把角色物理的控制權交給該角色的擁有者。本設計是配合這點，而不是假裝
它不存在：

* **飛行、空中跳躍與反擊退**由伺服器*授予*（時間視窗、冷卻、頻率限制、速度
  監測），但在客戶端套用。若要完全由伺服器模擬，需要自訂角色控制器，而且
  所有人都會感到延遲。所有會產生實際遊玩影響的項目 - 傷害、距離、冷卻、
  碰撞、傳送、護盾、治療 - 都在伺服器端。
* **ESP 是本地疊加層。** 它只能繪製伺服器本來就會複製的資訊（角色、血量、
  團隊）。隱形玩家帶有被複製的 `HackerInvisible` 屬性並會被略過。可見性檢查
  使用客戶端射線檢測，所以它是遊玩輔助，不是反作弊機制。
* **目標鎖定**會把本地鏡頭轉向已驗證的敵人。它本身無法產生命中；每一次攻擊
  都由伺服器判定。
* **訓練木樧**是帶 Humanoid 的靜態模型（150 HP，2.5 秒後重生）。它們不會
  移動，也不會還擊。
* **僅限能力對戰**會把傷率倍率強制為 1.0；遊戲中的所有戰鬥本來就是能力導向，
  因此沒有獨立的武器傷害表。
* **GUI 外殼由安裝器建立；完整視窗在首次加入時組裝。** Roblox 無法在編輯模式下，
  僅憑指令列就建立一個已完成且接好線的 GUI 樹，而不同時附上執行它的程式碼，
  因此客戶端會在玩家加入時建立分頁、列與處理程序。你永遠不需要手動建立任何
  東西。
* **Studio 版本**：把多行程式碼貼進指令列需要目前版本的 Studio（多行指令列已於
  2026 年 3 月完成佈署）。較舊版本無法執行安裝器 - 請更新 Studio。
* **平衡數值只是起點**，不是排位用的規則集。可調整 `ReplicatedStorage/HackerFight`
  中的 `Config`（不需要重跑安裝器）。

---

## 7. 疑難排解

| 症狀 | 解法 |
| --- | --- |
| `FAILED: ... Source ... permission` | 你不是在指令列執行，或你先按了 Play。停止遊戲，停留在編輯模式，從 View -> Command Bar 執行。 |
| 按 Play 後什麼都沒出現 | 開啟 Output（View -> Output），閱讀第一行紅字。通常是安裝器中途中斷 - 再執行一次。 |
| 戰鬥沒有作用 | 回合處於中場休息（HUD 橫幅顯示 "NEXT ROUND IN ..."），或你有出生保護，或目標在攻擊距離之外。 |
| 設定在 Studio 中無法儲存 | 啟用 Studio Access to API Services（第 5 節）。 |
| Output 出現「Missing remote」警告 | 安裝不完整：再執行一次安裝器。 |
| 視窗跑到畫面外 | 重新執行安裝器、再次加入，或按 `H` 按鈕；視窗會在重生時重新置中。 |

---

## 8. 開發者工作流程

```
src/
  shared/   Config, Util, Features, Remotes
  server/   Main + five services
  client/   Main + seven modules
tools/
  build_installer.py   embeds src/ into HackerFightInstaller.lua
  verify.py            static checks (syntax, remotes, handlers, protocol)
  mock_roblox.lua      minimal Roblox API mock
  client_mock.lua      signals, services, task shims, module loader
  run_installer.lua    installs with the mock and verifies the created tree
  run_client_smoke.lua installs, boots the real client, clicks real GUI elements
  run_server_smoke.lua boots the real server, drives remotes, checks damage etc.
  run_all.sh           runs everything
```

編輯 `src/` 之後重新建置：

```bash
bash tools/run_all.sh
```

這會重新產生 `HackerFightInstaller.lua`，並執行：

* 全部 18 個內嵌腳本的位元組對位元組往返比對
* 每個來源檔與安裝器的 Lua 語法解析
* 安裝器對 mock 的乾跑：109 個結構斷言
* 客戶端煙霧測試：啟動真正的 `Main` LocalScript，29 個斷言，點擊開關、
  按鈕、分頁與搜尋框，並斷言遠端收到正確的呼叫
* 伺服器煙霧測試：啟動真正的 `Main` Script，15 個斷言，造成傷害、
  拒絕超出距離的攻擊、驗證神模式、出生保護、速度限制、傳送驗證、
  航點儲存與 RemoteFunctions
* 靜態檢查：使用的遠端 == 建立的遠端、每個互動列都有處理程序、
  每個設定列都存在於架構中、每個客戶端動作都由伺服器處理、
  無棄用 API、無佔位文字

這套測試工具的限制：它跑的是 Lua，不是 Roblox 的物理與渲染器。視覺打磨、
實際的飛行手感與行動裝置佈局仍需在 Studio 實測 - 這正是第 4 節清單的用途。

---

## 9. 安全說明

本專案是一個**自給自足的遊戲**，不是執行器（executor），也不是針對其他體驗的
外掛。它的所有強化都是每位玩家都擁有的、經伺服器驗證的遊戲機制。這裡沒有任何
東西會注入其他遊戲，客戶端也從不傳送傷害、命中結果或受信任的位置。
