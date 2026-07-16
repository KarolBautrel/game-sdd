# 019 Dungeon Party Targeting V1

Status: implemented
Date: 2026-07-16

## Intent

Replace temporary `party_member_0` dungeon hazard targets with stable party formation targets.

Dungeon hazards need to hurt or debuff a party member before combat starts. Those effects should not depend on "first unit in the combat JSON" as a hidden rule. Dungeon owns expedition consequences, but combat launch needs a clear mapping from a dungeon party slot to a combat unit id.

## Target Contract

Dungeon hazard consequences may target party slots:

- `party_slot_front`: the front expedition slot.

The dungeon run state stores `party_formation`, an ordered list of slot records:

```json
[
  {
    "slot_id": "front",
    "target_id": "party_slot_front",
    "combat_unit_id": "unit_player_001",
    "label": "Front"
  }
]
```

`target_effects` are keyed by `target_id`, not directly by combat unit id. This keeps exploration data stable while allowing combat launch to translate the target into an encounter unit.

## Combat Bridge

When combat launches:

1. Dungeon includes `party_formation` in `dungeon_modifiers`.
2. Session launch maps each `target_effects` key to a combat unit id through `party_formation`.
3. Supported effects mutate only the resolved combat unit:
   - `hp_loss` reduces starting HP, clamped to at least 1;
   - `limping` halves starting MP, clamped to at least 1;
   - `bleeding` applies the supported combat `bleeding` status.

`party_member_0` remains a backwards-compatible fallback for older debug metadata, but new dungeon data should use party slot targets.

## Implementation Notes

Implemented first-pass support in:

```text
resources/schemas/dungeon.schema.json
resources/data/dungeons/dungeon_old_mine.json
scripts/domain/dungeon_state_model.gd
scripts/session/dungeon_run_session.gd
```

`dungeon_old_mine` defines a default front slot mapped to `unit_player_001`. Rubble and trap hazard consequences now target `party_slot_front`.

## Future Work

- Replace default dungeon formation with the real party roster/loadout selected before entering the dungeon.
- Let hazards select targets by role, random living party member, or authored slot.
- Surface affected party member names in the dungeon HUD once party character data exists.

## Non-Goals

- full roster persistence;
- character sheet UI;
- multi-character expedition selection;
- final targeting balance.
