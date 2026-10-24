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
