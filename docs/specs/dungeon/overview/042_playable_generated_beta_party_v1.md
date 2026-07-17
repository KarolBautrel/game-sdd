# Playable Generated Beta Party V1

## Goal

Make the first playable dungeon beta pass start from generated dungeon content by default and test combat with two heroes from this point forward.

## Behavior

- `DungeonEntrySelection.default_payload()` returns a generated medium-mine payload.
- `DungeonDebug.tscn` opens on the generated dungeon source unless a saved session is resumed.
- Authored Old Mine remains available through the debug source toggle.
- Dungeon state defaults to a two-slot party formation:
  - `party_slot_front` -> `unit_player_001` / Warrior;
  - `party_slot_back` -> `unit_player_002` / Archer.
- Combat launch metadata keeps resolving dungeon target effects through `party_formation`.
- Dungeon combat launches ensure the beta party is present in the encounter before enemy randomization.
- The Archer receives a bow loadout and ranged/aimed-shot item profile during dungeon combat launch.
- Enemy randomization continues to replace only enemy units; both player units are preserved.

## Boundaries

This pass does not author final tactical combat maps. Generated dungeon rooms may select existing validated combat encounter files until bespoke maps are designed.

This pass does not add durable roster, recruitment, or town inventory ownership. The two-hero setup is a beta testing contract for dungeon and combat flow.

## Proof

- `python tools/validators/validate_all.py`
- `scripts/domain/dungeon_entry_selection_tests.gd`
- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/session/dungeon_run_session_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
