# Recovery And Camping V1

Status: active
Date: 2026-07-17

## Intent

Add a first explicit in-dungeon recovery action that is stronger than instant remedy use and creates a meaningful reason to carry a camping kit.

## Rules

- Camping is an expedition action, not a town rest action.
- Camping requires a carried `camping_kit`.
- Camping is blocked while combat, corridor hazards, or room events are pending.
- Camping consumes one camping kit.
- Camping can reduce accumulated dungeon HP loss and clear active dungeon debuffs.
- Camping costs time/light by reducing expedition light.
- Camping writes a structured event to run logs.

## Non-Goals

- full hunger system;
- full ambush encounter generation;
- detailed per-character healing;
- permanent injury treatment;
- town inn/rest flow.

## Proof

- domain tests for camping rejection, supply consumption, HP loss reduction, debuff clearing, and light cost;
- HUD tests for camp action visibility.
