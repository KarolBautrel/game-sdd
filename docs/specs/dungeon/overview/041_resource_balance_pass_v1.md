# Resource Balance Pass V1

Status: implemented
Date: 2026-07-17

## Intent

Make the first dungeon loadout choices matter before wider town/world economy integration.

This pass keeps ownership narrow: dungeon still receives carried expedition supplies and spends them during a run. Buying, restocking, pricing, crafting, and durable inventory ownership remain future town/world responsibilities.

## Rules

- Authored Old Mine uses 7 packing points.
- Generated mine profiles use tighter capacity by length:
  - `short_mine`: 6 packing points;
  - `medium_mine`: 7 packing points;
  - `deep_mine`: 9 packing points.
- The default Old Mine loadout remains playable without camping:
  - 2 torch oil;
  - 1 pickaxe;
  - 1 bandage;
  - 1 trap tools;
  - 1 food;
  - 0 camping kit.
- Taking a camping kit should require dropping other supplies.
- Every visible carried resource must have at least one in-dungeon use:
  - torch oil restores light;
  - pickaxe clears rubble/cave-in style hazards;
  - bandage repairs one point of expedition HP loss;
  - trap tools disarm trap hazards;
  - camping kit enables camp recovery;
  - food is consumed when camping.
- Camping requires both `camping_kit` and `food`.
- Camping still reduces accumulated HP loss, clears active dungeon debuffs, consumes light, and is blocked by pending combat, corridor hazards, or room events.

## Non-Goals

- supply prices;
- persistent supply ownership;
- vendor inventory;
- crafting;
- final long-run balance.

## Proof

- Domain tests cover loadout capacity, bandage use, camp food consumption, and missing-food camp rejection.
- HUD tests cover bandage selection for HP-only recovery.
