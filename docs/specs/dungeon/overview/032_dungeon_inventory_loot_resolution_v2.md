# Dungeon Inventory And Loot Resolution V2

Status: implemented
Owner: dungeon overview

## Purpose

Separate temporary dungeon-run loot from future durable player inventory. Reward claiming still happens inside the dungeon run, but end-of-run payloads now explicitly say which claimed rewards are kept, which are lost, and what inventory delta a future inventory service should apply.

## Rules

- Dungeon state owns a `run_inventory` bucket for loot claimed during the current run.
- `run_inventory` contains:
  - `xp`;
  - `gold`;
  - `items`;
  - `reward_records`.
- Claiming a reward appends a reward record to `run_inventory.reward_records`.
- Claiming a reward increments `run_inventory.xp`, `run_inventory.gold`, and `run_inventory.items`.
- Existing `reward_totals` remains a compatibility summary of the same claimed run inventory.
- Dungeon run result payloads include:
  - `claimed_run_inventory`;
  - `kept_rewards`;
  - `lost_rewards`;
  - `inventory_delta`.
- `completed` keeps all claimed run loot.
- `retreated` keeps all claimed run loot in this first beta rule.
- `failed` loses claimed run loot, keeps no inventory delta, and still reports persistent effects.
- `inventory_delta` is data-shaped only. It prepares for a real inventory service but does not mutate durable player inventory yet.

## Current Scope

This version does not add item stack definitions, equipment behavior, inventory UI, secured-loot checkpoints, retreat penalties, or save-game persistence.

## Proof

- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/session/dungeon_run_session_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
