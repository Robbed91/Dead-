# Dead Shift

**Survive. Build. Defend.**

Dead Shift is a Godot 4 mobile Android prototype for a 2D zombie survival colony-builder set in a British industrial estate. This first playable version focuses on the colony loop: manage survivors and resources, scavenge, improve buildings, resolve night attacks, save, and continue.

## Current Playable Loop

- Start a new game from `MainMenu.tscn`.
- Review resources, colony status, buildings, survivors, and event log.
- Assign survivor tasks.
- Assign survivors to claimed buildings.
- Assign building uses such as Workshop, Watch Post, Medical Bay, Storage, Sleeping Quarters, Quarantine, and Food Prep.
- Scout, clear, claim, repair, or fortify buildings.
- Pick a survivor and scavenge locations for food, water, medicine, fuel, tools, materials, and ammo.
- Potentially find recruitable survivors and invite, reject, or quarantine them.
- Daily survivor jobs and building uses apply small resource, security, morale, infection, and horde-threat effects.
- Prepare defences and resolve the night attack.
- Consume food and water, update morale and threat, auto-save, and advance the day.
- Continue from `user://dead_shift_save.json`.

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

The project is configured for a portrait mobile viewport of `390 x 844` with canvas item stretching.

## Android Portrait Orientation

Portrait is already set in `project.godot`:

```ini
[display]
window/handheld/orientation=1
```

In the editor this is visible under:

**Project > Project Settings > Display > Window > Handheld > Orientation**

Set it to **Portrait** if you change it later.

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

The save file uses Godot's user path:

```text
user://dead_shift_save.json
```

On desktop test runs, the exact folder is platform-specific and can be inspected in Godot with `ProjectSettings.globalize_path("user://")`.

## Known Limitations

- UI art is placeholder only.
- Combat is formula-based, not animated.
- Scavenging has survivor selection, but no multi-person expedition planning yet.
- Building assignment and building-use bonuses are intentionally simple.
- Crafting is a small prototype tab, not a full production chain.
- No pathfinding, base map, character movement, or final audio.
- Android export still requires local Godot export templates, SDK, JDK, and signing configuration.

## Suggested Next Phase

- Add a simple industrial estate map view with tappable building lots.
- Add survivor selection for scavenging and building assignment.
- Expand building uses into functional bonuses.
- Add more event variety: alarms, trader visits, sickness, disputes, weather, and horde warnings.
- Add survivor job effects so cooks, medics, guards, and builders influence daily outcomes.
- Add lightweight placeholder animations, sound toggles, and improved mobile theme polish.
- Add automated save/load validation tests using Godot's headless runner.
