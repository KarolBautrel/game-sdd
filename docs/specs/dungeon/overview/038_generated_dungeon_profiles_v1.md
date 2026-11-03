# Generated Dungeon Profiles V1

Status: active
Date: 2026-07-17

## Intent

Move generated dungeon entry away from anonymous difficulty-only generation and toward named dungeon profiles that can later be selected by world-map nodes.

## Rules

- Generated entry payloads may carry `generated_profile`.
- The first profile set is `short_mine`, `medium_mine`, and `deep_mine`.
- Profiles currently map to existing finite Old Mine template difficulty bands.
- Profiles may define display name, difficulty, theme, length, light budget, and loadout capacity.
- Existing debug difficulty buttons act as profile shortcuts until a fuller entry UI exists.

## Non-Goals

- crypt/ruins content implementation;
- new art assets;
- free-form procedural generation;
- production world-map selection UI.

## Proof

- entry payload tests for profile preservation;
- procedural draft tests for profile metadata and profile-driven dungeon differences;
- schema validation for generated profile shape when present.
