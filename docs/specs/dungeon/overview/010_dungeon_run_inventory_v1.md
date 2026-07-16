# 010 Dungeon Run Inventory V1

Status: active
Date: 2026-07-16

## Intent

Aggregate claimed rewards into a simple dungeon-run inventory summary.

This is still a progression stub. It makes reward totals queryable without introducing full party inventory or save-game persistence.

## Rules

- Dungeon state tracks `reward_totals`.
- `reward_totals` contains:
  - `xp`;
  - `gold`;
  - `items`.
- Claiming a reward increments XP and gold totals.
- Claiming a reward appends reward items to the item list.
- The HUD progress line shows reward totals, not only claimed reward count.
- Post-run summary uses the same reward totals.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/011_dungeon_run_inventory_v1.md
scripts/domain/dungeon_state_model.gd
scripts/domain/dungeon_state_model_tests.gd
scripts/presentation/dungeon_debug.gd
scripts/presentation/dungeon_exploration_hud_tests.gd
```

## Non-Goals

- persistent inventory;
- stack counts;
- equipment;
- item database behavior.
