# 060 Movement Points Multi Tile

Status: implemented
Date: 2026-07-14

## Acceptance

- unit resources may include `mp` next to `ap`;
- a unit with `mp` uses MP for `move` instead of AP;
- a move target may be more than one tile away when a legal path exists;
- movement cost is the number of path steps;
- player starts at `(1,1)` with `AP 1` and `MP 3`;
- player moves to `(3,1)` in one command;
- player ends at `(3,1)`;
- player AP remains `1`;
- player MP changes from `3` to `1`;
- `action_performed` records `ap_spent: 0` and `mp_spent: 2`;
- `unit_moved` records the path `[(2,1), (3,1)]` so presentation can animate each step.
