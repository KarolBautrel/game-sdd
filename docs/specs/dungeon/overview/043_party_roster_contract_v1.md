# Party Roster Contract V1

## Goal

Replace hardcoded single-portrait dungeon presentation and ad hoc combat hero data with a small shared party roster.

## Behavior

- The beta party is defined in `scripts/domain/party_roster.gd`.
- Each hero has:
  - stable hero id;
  - combat unit id;
  - display name;
  - class name;
  - dungeon portrait path;
  - combat visual config;
  - starting stats and resources;
  - available actions;
  - starting loadout.
- Dungeon state uses the roster to create the default party formation when dungeon data does not override it.
- Authored dungeon data may still define a compatible `default_party_formation`.
- Dungeon HUD renders party slots from `run_state.party_formation`, resolving each slot through the roster.
- Dungeon combat launch creates or normalizes player units from the same roster.
- Combat text resolves player unit ids to hero names.

## Beta Party

- Bran, Warrior, `unit_player_001`, visual `heroes/warrior`.
- Torin, Archer, `unit_player_002`, visual `heroes/archer_1`.

## Boundaries

This is not a full roster-management system. Recruitment, replacement, leveling, equipment UI, injuries, and persistent character progression remain future world/town or character-system work.

## Proof

- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/session/dungeon_run_session_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
- `scripts/presentation/combat_mercenary_asset_pipeline_tests.gd`
- headless dungeon and combat scene loads
