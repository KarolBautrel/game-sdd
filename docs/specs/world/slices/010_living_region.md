# Slice010: living-region campaign loop

Owner: world010; presentation036/slice036.

- Legacy v4 profile loads unchanged. Pilot initialization is isolated, resumable
  and atomic. Invalid optional state/save failures preserve profile/file bytes.
- Continuous course uses passable land/road costs. Pause does not advance; equal
  tick commands reproduce positions, upkeep, caravan raids and faction state.
- Caravan deliveries/raids affect actual supply; food quotes/transactions agree.
- Mine threat causes an offer. Accept at Ravenford, complete a real managed mine
  with cleared combat, settle once, then report: mine/raid/supply/relations/reward
  change persistently. Retreat/empty cleared list/duplicate receipt do not grant it.
- Reconnaissance and delivery use actual visited site/owned stock, issuer report
  and one-time payment. Active event/run gates service, course and clock.
- Dungeon room/camp time is charged once across checkpoints/reload. Existing
  ambush and dungeon return scenes resume the living company, not a reset world.

Proof: living-world domain/session tests and existing campaign/dungeon suites;
native movement/pause/speed/contracts/provision input and visible world activity.
Physical full expedition to ordinary victory and return: AWAITING_INTERACTIVE.
