# Classic four-faction simulation

Stage94. Owner: [world017](../017_classic_strategy.md). Implementation complete;
automated evidence and final-source status:
[stage94 QA](../../../qa/2026-11-09-classic-strategy.md).

- Tick batching, registry reorder, save/reload continuation and same seed retain
  identical facts/decisions. Load advances no time. Wrong versions/commands and
  unsupported provider modes reject atomically.
- Production and upkeep match declared boundaries. Stock/cargo/escrow accounting
  reconciles; no overdraw, duplicate purchase/delivery or magical manpower.
- Propose/accept trade has both signatures and real weighted travel. Transit /
  waiting/interception/reload each settle once; exhausted budgets and closed
  routes reject. Suspended cargo/escrow survives archival and restart.
- War requires motive/readiness/reachability and respects pacts/ceasefires.
  Mobilization and retreat take time; casualties affect actual troops/manpower.
  Peace and defensive aid require the named party's consent and lawful resources.
- Observations exclude opponents' private plans and hidden company data.
  Plans have recorded scores/commitments; real shortage/trade/deterrence/war /
  exhaustion can produce different decisions without a daily tension trigger.
- Run16seeds x180days and longer soaks, reconcile all ledgers and durable state,
  retain bounded histories and log diagnostics without a fun/balance claim.
- Dedicated v2 session uses unchanged atomic boundary. Forced write failure
  rolls back an entire multi-day advance; retry/reload equals uninterrupted run.
  Existing v1 strategy, legacy pilots/saves and art remain unchanged.

Proof: classic_world_tests.gd, faction_planner_tests.gd, classic_session_tests.gd,
Python configuration/schema validation and the full headless runner. Native map
integration and ordinary play remain stage95; current desktop controls withheld.

Focused domain161/session20checks and7newPython tests pass. The planner suite
includes1360checks,16x180day campaigns and two720day soaks; it is rerun on the
final source in the full runner. Diagnostics distinguish cooperative openings
from an unresolved ore dispute, recording actual trade, losses, casualties,
war/peace, bounded histories and resource/manpower reconciliation. No balancing /
enjoyment acceptance or player-visible political scene is inferred.
