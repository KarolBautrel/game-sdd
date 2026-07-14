# 062 Enemy AI Move Then Attack

Status: implemented
Date: 2026-07-14

## Acceptance

- enemy AI with MP can choose a multi-tile `move` destination instead of only the first path step;
- enemy starts at `(1,1)` with `AP 1` and `MP 3`;
- player starts at `(4,1)`;
- first AI command chooses `move` to `(3,1)`;
- movement spends `2 MP` and `0 AP`;
- enemy remains active with `AP 1` and `MP 1`;
- second AI command chooses `basic_attack` against the adjacent player;
- attack spends `1 AP` and leaves `MP 1`;
- player HP changes from `10` to `8`;
- event log records `unit_moved` before `damage_applied`.
