# 008 Dungeon Reward Claim V1

Status: active
Date: 2026-07-16

## Intent

Add the first deterministic dungeon reward claim state.

This is a dungeon-run stub, not a full inventory/progression system. Claimed rewards are recorded in dungeon state so later inventory work can consume the same reward-shaped payloads.

## Rules

- Dungeon state tracks `claimed_reward_room_ids`.
- Dungeon state tracks `claimed_rewards` as a list of reward records.
- A room reward may be claimed once.
- Plain `treasure` content may be claimed after entering the room.
- `guarded_treasure` content may be claimed only after its room reward is unlocked by combat victory.
- Claiming a reward marks that room cleared.
- Claiming a reward returns an event containing room id and reward payload.
- Claiming without claimable reward is rejected with a stable reason.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/008_dungeon_reward_claim_v1.md
scripts/domain/dungeon_state_model.gd
scripts/domain/dungeon_state_model_tests.gd
scripts/presentation/dungeon_debug.gd
scripts/presentation/dungeon_exploration_hud_tests.gd
```

## Non-Goals

- inventory UI;
- item database validation;
- XP or gold application outside dungeon state;
- reward choice screens.
