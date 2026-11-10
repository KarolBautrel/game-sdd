# Classic strategy stage94

2026-11-09. Isolated backend implemented; final-source97/97automated PASS,
zero errors/warnings. Owner [world017](../specs/world/017_classic_strategy.md),
[slice018](../specs/world/slices/018_classic_strategy.md),
[handoff](../handoffs/2026-11-09-classic-strategy.md).

No desktop controls, visible window, model/provider call, commit or push. All
runtime tests use headless Godot and fresh QA-only files. No old player save,
accepted atlas/terrain or character art is used as a mutation fixture.

## Meaningful proofs

- Conserved source/production/upkeep/loss accounting includes cargo and escrow;
  mobilization uses existing manpower, casualties reconcile against opening total.
- Bilateral funded trade takes real weighted travel time; no purchase teleport,
  double delivery or budget reuse. Waiting shipments survive blocked routes and
  archival, resume after peace, and lose cargo only to a real hostile force at
  arrival with one escrow refund.
- War requires motive, public mobilization/readiness/routes/resources; pacts and
  ceasefires block it. Ordinary border clashes and opposite-edge collisions cause
  actual casualties. A defeated one-town force keeps moving on its real edge.
  Aid has one direct request/response, no transitive cascade. Peace needs consent
  and creates a14day truce while armies physically return.
- Same seed, registry reordering, tick batching and JSON/disk continuation yield
  identical simulated facts/decisions. Observations exclude other private plans /
  policies and company inventory. Reports have IDs/age/confidence; plans have
  recorded utility components, commitments/reviews/horizons.
- Sixteen180day and two720day runs reconcile every accepted boundary and retain
  bounded histories. Diagnostics record real trade/losses, wars/peace, casualties,
  rejected revalidations and plan churn. They do not prove balance or enjoyment.
- Dedicated v2 persistence uses the same atomic boundary as v1; a forced failed
  week preserves file and memory, then retries once. Cross-format commands reject.
  Legacy/v1 loaders retain their prior behavior and no implicit conversion occurs.
- Schema/reference/negative Python tests include a shared-validator regression:
  Godot serializes some integral sequence numbers as floats; typed schema accepts
  these and the validator now normalizes that count before enumerating receipts.

Focused domain161/session20checks and7newPython tests pass; foundation Python
regression adds one. Full runner reruns final planner/18campaign matrix and all
existing suites. Per-suite180second allowance covers the finite long matrix.

```powershell
.\.venv\Scripts\python.exe tools/qa/verify_project.py --run-id classic-strategy-20261109-final2 --timeout 180
```

## Boundary and next stage

Current game continues to use its approved living pilot. This new simulation
has no native scene, terrain adapter, company political contract integration,
player tactical joining or model connection. Those remain95/96. Earlier live
L91/L77 and user appearance/motion acceptance are still open. No ordinary
visible victory or player-facing strategic acceptance is claimed.

Portable final evidence is retained under
`docs/design/living-world/2026-11-09/classic/`. The same directory retains the
long-run diagnostic data; full logs also remain in the named local artifact run.

Initial full attempt `classic-strategy-20261109-final` was intentionally stopped
after its long-run suite passed, to add effective physical escort protection and
a waiting-cargo regression. It is incomplete, not final-source acceptance. The
new `final2` run repeats the whole suite on the corrected source.

## Final executed result

- `classic-strategy-20261109-final2`:97/97PASS,0errors/0warnings. Includes91Python
  tests, Godot import, every script suite and nine scene boots.
- New suites: classic domain161checks, planner1360checks /18campaigns, session20
  checks, all PASS. The finite planner matrix took84.094seconds on this machine.
-16x180days plus2x720days =4320strategic days across separate campaigns. Totals:
  28,893deliveries,421real interceptions,71war declarations and70ceasefires.
  One campaign can end during an ongoing war; these are diagnostic sums, not a
  target ratio or a claim that every war must end by the test deadline.
- Every accepted batch reconciles holdings/cargo/escrow, production/upkeep/losses
  and total manpower/casualties. Cooperative openings can stay peaceful. The
  unresolved ore claim can recur after truces; attrition can exhaust available
  forces. Further balance/player causality is still required.
- Final escort regressions: equal supplied ready protection prevents seizure;
  weak or unready protection leaves actual waiting cargo exposed. Originators
  do not intercept their own shipments. No duplicate cargo loss/refund.
- Exact source match:
  `1d5b94e37dd22c9f38f07970a16ff38262a51b176b5bc0abe082559e936c5696`.
- Eight preexisting saves, terrain mask and atlas:10/10hashes unchanged after
  all tests exit. Local Markdown targets and `git diff --check` pass.
- Generic runner status remains AWAITING_INTERACTIVE; no earlier physical gap
  closes and this backend adds no new player scene.

[Full receipt](../design/living-world/2026-11-09/classic/verification.json),
[source integrity](../design/living-world/2026-11-09/classic/integrity.json),
[preservation](../design/living-world/2026-11-09/classic/preservation.json),
[campaign table](../design/living-world/2026-11-09/classic/CAMPAIGN_DIAGNOSTICS.md),
[domain output](../design/living-world/2026-11-09/classic/classic_world_tests.stdout.txt),
[planner output](../design/living-world/2026-11-09/classic/faction_planner_tests.stdout.txt),
[session output](../design/living-world/2026-11-09/classic/classic_session_tests.stdout.txt).
Selected trackable `.txt` stdout/stderr streams and raw diagnostic JSON are beside
the report. The complete local artifact logs remain under the named run.
