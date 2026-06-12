# Dead Shift V1 Completion Plan

This is the practical definition of a complete testable V1, separate from a commercial release.

## Must Be Complete For V1

- Start with Billy only in the workshop.
- Grow through Hideout, Camp, Community, Settlement, District, and City.
- Unlock buildings through population growth and survivor skills.
- Let the player scout, clear, claim, repair, fortify, assign use, and assign survivors only when the building state allows it.
- Provide two recruitment routes: scavenging and radio contact.
- Make NPC survivors choose useful work automatically, while Crew survivors remain directly controllable.
- Resolve each day with jobs, building bonuses, random colony events, rations, infection progression, night defence, auto-save, and a report.
- End in defeat if survivors die, morale collapses, or all controlled buildings are lost.
- End in victory when the colony becomes a City, controls the whole estate, and survives to Day 30.
- Keep Android landscape UI usable with fixed in-game menus and no native popups that resize the screen.
- Save/load the full campaign state.

## Implemented In Current V1 Pass

- Building unlock rules now use population and survivor skills.
- Scavenging has early, mid, and late-game locations with facility requirements.
- Radio contact can find recruitable survivors.
- Scavenging supports solo and party expeditions with shared timed jobs and party-size selection.
- Campaign victory exists: reach City, control all estate buildings, and survive to Day 30.
- End-of-day events include trader, alarm, repair, sickness, radio, kitchen, weather, and resource moments.
- Larger colonies now consume more support resources and suffer overcrowding if beds are short.
- Crafting uses facility-gated recipes for ammo, medicine, water, fuel, tools, and upgrades; radio, assignment, and building-management controls are disabled or hidden when unavailable.
- First-run tutorial overlay explains the core loop and can be reopened from the in-game menu.
- Settings/reset/credits and game prompts use in-game modals instead of native popups.
- Main menu, settings, and game dashboard apply safe-area margins so Android cutouts/navigation areas have less chance of covering controls.
- Scavenge cards, survivor portraits, building markers, role marks, resource chips, horde tokens, and location icons use a consistent procedural art style.
- Save/load and APK export pass automated local checks.

## Still Requires Physical QA

- Install and play the APK on the Samsung S24 Ultra.
- Confirm no Android system navigation or camera cutout hides bottom controls on the Samsung S24 Ultra.
- Confirm long sessions feel balanced from Day 1 to Day 30.
- Confirm generated background art looks acceptable on the phone screen.
- Confirm audio behavior once sound effects/music are added.
- Add a release keystore path for Play Store AAB builds. The current setup is debug APK focused.

## Not In V1

- Pathfinding-based character control.
- Multiplayer.
- Cloud saves.
- Final commercial artwork.
- Complex real-time combat.
