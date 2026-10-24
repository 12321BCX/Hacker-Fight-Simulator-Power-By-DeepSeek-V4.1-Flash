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
