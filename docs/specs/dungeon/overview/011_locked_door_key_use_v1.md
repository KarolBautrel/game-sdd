# 011 Locked Door Key Use V1

Status: active
Date: 2026-07-16

## Intent

Add the first item-gated dungeon room.

This proves that claimed dungeon rewards can unlock later traversal without a full inventory system.

## Rules

- Dungeon room data may include `locked_by_item_id`.
- A locked room cannot be entered unless the run reward totals contain the required item id.
- Entering an unlockable locked room records the room id in `unlocked_room_ids`.
- Locked room rejection uses stable reason `locked_missing_key`.
- The HUD marks locked exits before they are opened.
- The first reference locked room is unlocked by `rusty_key`.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/013_locked_door_key_use_v1.md
resources/schemas/dungeon.schema.json
resources/data/dungeons/dungeon_old_mine.json
scripts/domain/dungeon_state_model.gd
scripts/domain/dungeon_state_model_tests.gd
scripts/presentation/dungeon_debug.gd
scripts/presentation/dungeon_exploration_hud_tests.gd
```

## Non-Goals

- consumable keys;
- lockpicking;
- locked corridor art;
- multi-key conditions.
