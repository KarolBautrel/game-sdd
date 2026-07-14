# 061 AP MP Turn Economy

Status: implemented
Date: 2026-07-14

## Acceptance

- AP and MP are separate resources;
- `move` spends MP and does not spend AP when `resources.mp` exists;
- `basic_attack` spends AP and does not spend MP;
- player starts at `(1,1)` with `AP 1` and `MP 3`;
- enemy starts at `(4,1)`;
- player moves to `(3,1)` in one command;
- player AP remains `1`;
- player MP changes from `3` to `1`;
- player performs `basic_attack` in the same turn;
- player AP changes from `1` to `0`;
- player MP remains `1`;
- enemy HP changes from `6` to `3`;
- the active unit remains the player because no end-turn command was issued.
