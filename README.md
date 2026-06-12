# Dead Shift

**Survive. Build. Defend.**

Dead Shift is a Godot 4 mobile Android prototype for a 2D zombie survival colony-builder set in a British industrial estate. The current build is a landscape command-dashboard version: manage the estate from a single base screen, watch survivor tokens move between jobs, scavenge, improve buildings, handle random colony events, resolve night attacks, save, and continue.

## Current Playable Loop

- Start a new game from `MainMenu.tscn`.
- Review resources, colony status, night threat, buildings, survivors, objectives, alerts, and event log.
- Assign survivor tasks and watch survivor tokens move around the estate while job progress fills.
- Survivor health, infection risk, and status progress over time. Injured or infected survivors need rest, medicine, medical workers, or quarantine support.
- Assign survivors to claimed buildings.
- Assign building uses such as Workshop, Watch Post, Medical Bay, Storage, Sleeping Quarters, Quarantine, and Food Prep.
- Scout, clear, claim, repair, or fortify buildings.
- Install persistent building upgrades: Barricade Kit, Floodlights, Rain Catchers, Workshop Bench, and Spike Traps.
- Upgrades affect night defence, daily water/material production, horde pressure, security, and building condition.
- Pick a survivor and scavenge locations for food, water, medicine, fuel, tools, materials, and ammo.
- Scavenging now runs as a timed survivor job before loot and danger resolve.
- Scavenging locations deplete as they are looted, can become temporarily too hot to enter, and recover slightly over time.
- Potentially find recruitable survivors and invite, reject, or quarantine them.
- Daily survivor jobs and building uses apply small resource, security, morale, infection, and horde-threat effects.
- Random end-of-day events can add storage finds, generator problems, ration disputes, rain collection, horde movement, or clinic treatment.
- Prepare defences and resolve the night attack.
- Choose defence tactics before nightfall: Patch Barricades, Ammo Traps, or Quiet Watch.
- End Day shows a compact night report covering combat, survivor jobs, building bonuses, events, scavenging recovery, rations, and auto-save.
- Consume food and water, update morale and threat, auto-save, and advance the day.
- Continue from `user://dead_shift_save.json`.
- Main menu shows the local save summary and disables Continue when no save exists.
- Settings are stored separately in `user://dead_shift_settings.json`.

## Project Structure

```text
res://
  scenes/
    MainMenu.tscn
    Game.tscn
    screens/
      BuildingsScreen.tscn
      SurvivorsScreen.tscn
      ScavengeScreen.tscn
      NightDefenseScreen.tscn
      SettingsScreen.tscn
  scripts/
    GameManager.gd
    ResourceManager.gd
    SurvivorManager.gd
    BuildingManager.gd
    ScavengeManager.gd
    NightDefenseManager.gd
    SaveManager.gd
    ActivityManager.gd
    UIManager.gd
    MainMenu.gd
    SettingsScreen.gd
  data/
    starting_survivors.gd
    starting_buildings.gd
    scavenging_locations.gd
  assets/
    icons/
    placeholders/
    ui/
  export/
```

## Open In Godot 4

1. Install Godot 4.x.
2. Open Godot Project Manager.
3. Select **Import**.
4. Choose this folder and open `project.godot`.
5. Run the project. The main scene is `res://scenes/MainMenu.tscn`.

## Run In The Editor

1. Press **F5** or click **Run Project**.
2. Choose **New Game**.
3. Use the bottom navigation tabs to manage the colony.
4. Use **Resolve Night / End Day** from Colony or Defence to advance the loop.

The project is configured for a landscape mobile viewport of `1280 x 720` with canvas item stretching. On phones, rotate the device to landscape after installing the APK.

## Smoke Test

A headless smoke test checks the core loop managers without manual clicking:

```bash
Godot_v4.6.3-stable_win64.exe --headless --path . -s tests/SmokeTest.gd
```

It starts a new game, claims a building, installs an upgrade, starts and completes a scavenge job, checks location depletion/recovery, checks survivor condition progression, prepares a named defence tactic, previews night defence, saves, checks save summaries/settings persistence, reloads, and ends the day. The test backs up and restores any existing `user://dead_shift_save.json` and `user://dead_shift_settings.json`.

## Android Landscape Orientation

Landscape is already set in `project.godot`:

```ini
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/handheld/orientation=0
```

In the editor this is visible under:

**Project > Project Settings > Display > Window > Handheld > Orientation**

Set it to **Landscape** if you change it later.

## Install Android Export Templates

1. Open Godot.
2. Go to **Editor > Manage Export Templates**.
3. Download and install the matching templates for your Godot 4.x version.

## Configure Android SDK And JDK

1. Install Android Studio or the Android command line tools.
2. Install:
   - Android SDK Platform
   - Android SDK Build Tools
   - Android SDK Platform Tools
   - Android Emulator if needed
3. Install a compatible JDK. Godot 4 commonly works with JDK 17.
4. In Godot, open **Editor > Editor Settings > Export > Android**.
5. Set the Android SDK path.
6. Set the JDK path.
7. Let Godot create or configure the debug keystore if prompted.

## Export A Debug APK

### From GitHub Actions

1. Open the GitHub repo on desktop or mobile.
2. Go to **Actions**.
3. Select **Build Android Debug APK**.
4. Tap **Run workflow**.
5. Open the completed run.
6. Download the `dead-shift-debug-apk` artifact.
7. Extract the downloaded ZIP to get `dead-shift-debug.apk`.

Android will warn that the APK is from outside the Play Store. That is expected for local debug testing.

### From Godot Locally

1. Open **Project > Export**.
2. Select the included **Android Debug** preset.
3. Confirm the package name is suitable for local testing: `com.prototype.deadshift`.
4. Click **Export Project**.
5. Export to:

```text
export/dead-shift-debug.apk
```

The preset is set up for debug APK export using `arm64-v8a`. Once Android export is fully configured in Godot, you can also add a release preset for AAB export for Google Play.

## Install APK On Android Phone

With USB debugging enabled and `adb` available:

```bash
adb install -r export/dead-shift-debug.apk
```

You can also copy the APK to the phone and open it there if the device allows local APK installs.

## Reset Save Data

In game:

1. Open **Settings** from the main menu.
2. Press **Reset Save**.
3. Confirm the reset prompt.

The save file uses Godot's user path:

```text
user://dead_shift_save.json
user://dead_shift_settings.json
```

On desktop test runs, the exact folder is platform-specific and can be inspected in Godot with `ProjectSettings.globalize_path("user://")`.

## Known Limitations

- Art is prototype-ready rather than commercial final: generated stage backdrops plus procedural in-game buildings, facades, survivor sprites, role marks, location cards, lights, horde markers, and UI icons.
- Combat is formula-based with night-attack visual feedback, not direct tactical combat.
- Scavenging has timed solo and party expeditions with party-size selection, shared return timing, location depletion, cooldown, injury/infection risk, loot, and survivor encounters.
- Building assignment and building-use bonuses are intentionally simple.
- Crafting is a facility-gated recipe system for ammo, medicine, water, fuel, tools, and upgrades; it is not yet a deep factory/production-chain simulation.
- Facility upgrades are functional, but upgrade visuals are still represented by building stats and icons rather than bespoke construction art.
- Survivor movement is animated token movement around colony buildings rather than full tactical pathfinding.
- No final audio or music yet.
- Android export still requires local Godot export templates, SDK, JDK, and signing configuration.

## Suggested Next Phase

- Replace procedural building facades with hand-authored or generated production art per lot.
- Add larger survivor sprites and bespoke portrait art for named story survivors.
- Add expedition loadouts, vehicle use, and specialist scouting modifiers.
- Expand crafting into weapon tiers, barricade kits, traps, and queued workshop production.
- Add more event variety: alarms, trader visits, sickness, disputes, weather, horde warnings, and survivor relationship moments.
- Add sound effects, menu music, night ambience, and Android vibration feedback.
- Add automated save/load validation tests using Godot's headless runner.
