# Slice 051 - Party Roster Contract V1

## Objective

Make Warrior and Archer real shared party members for dungeon presentation and dungeon-launched combat.

## Implementation

- Add a shared party roster domain helper.
- Move Warrior and Archer names, classes, visuals, portraits, stats, resources, and loadouts into the roster.
- Use roster formation as the default dungeon party.
- Render dungeon HUD party cards from formation/roster data instead of one hardcoded mercenary portrait.
- Use roster combat units during dungeon combat launch.
- Resolve player names in combat text from the roster.
- Add tests for two dungeon UI party members, portrait paths, combat visual ids, and Archer/Warrior asset resolution.

## Acceptance

- Dungeon HUD shows both Bran and Torin with separate portraits and role/stat summaries.
- Dungeon-launched combat includes visible Warrior and Archer units.
- Warrior resolves to processed `warrior` combat sprites.
- Archer resolves to processed `archer_1` combat sprites.
- Existing dungeon/combat validation remains green.
