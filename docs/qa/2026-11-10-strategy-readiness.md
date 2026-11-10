# Faction readiness and matched logistics,97a

User requested publication of all existing work and the next stage. Existing
85..96c published to origin/master4223f8d7 after verifying the GitHub-linked
author, remote head and unchanged113/113tested source. No force push or history
rewrite. This follow-up implements the larger-world logistics/readiness
prerequisite; it does not close live inference or physical acceptance.

Owners: [world021](../specs/world/021_strategy_readiness.md),
[slice022](../specs/world/slices/022_strategy_readiness.md),
[tooling006](../specs/tooling/006_strategy_comparison.md).
Portable evidence: [comparison directory](../design/living-world/2026-11-10/strategy-comparison/README.md).

## Implemented behavior

Own-force preparation quotes share the operator's saved base costs, actual free
recruits and available unreserved resources. Classic and newly generated bounded
capabilities omit already-unfunded preparation intents. A constrained claim or
defence can still arrange ordinary supplies. Prepared border forces need not
pay preparation again merely to propose a lawful declaration. Execution still
rechecks stock, readiness, routes, consent and actual war costs.

Quotes grant no reservation or promise. An intervening obligation can invalidate
them. Existing request bytes/capabilities/hashes, company saves, terrain and art
are not migrated or reset. No extra troops, provisions or success are fabricated.
Accepted plans may have zero executable actions; the existing outcome strip
continues to distinguish that from an actual change in the world.

## Focused proof and matrix

- `faction_readiness_tests.gd`:26checks PASS; exact/configured prices, staffing,
  existing reservations, unchanged old request bytes and ordinary operator gates.
- `strategy_comparison_tests.gd`:348checks PASS; paired boundaries, immutable
  failures including candidate-validation failure, exact JSON checkpoint
  continuation, archival-safe shipment timing and honest offline provenance.
- Existing classic161 / strategist adapter184checks PASS.
- Native strategist84checks PASS at720/1080/1440p: a fresh zero-action plan and
  its immediate retained display, plus the actual historical blocked request.
- Pre/post12cases each: three opening seeds x Large/Vast x classic/authored
  recorded,180days per case; every boundary validated/reconciled. Initial digests
  match across modes/revisions. The final post-change rerun checks repeatability.
- Three CLI negative cases PASS: reused output, unsafe label and excessive day
  count reject; the existing result bytes remain unchanged.

The matrix isolates factions after regional initialization. Opening issuer holds
remain fixed; company movement and regional job refresh/expiry/completion do not
run. It is a controlled common-executor diagnostic, not a full native campaign
soak or a measurement of player progression. Preserve this scope when using the
numbers for future provision tuning.

Across six worlds per mode, classic unfunded preparations1713->0, deliveries
1579->1671; recorded unfunded preparations1307->8, deliveries1597->1642. All
rejections remain measured, including lawful failures of delayed proposals.
Daily food-shortfall faction-days620->581classic,660->654recorded. This aggregate
hides regressions: recorded Large2089 worsens132->148. No claim of a generally
balanced campaign, real-model superiority or visible gameplay acceptance.

Observed development failures were corrected before the final run: the initial
quote test compared JSON float/int dictionary representations directly; the old
adapter assertion required an effect from the newly valid zero-action first
plan; a new test variable needed an explicit Dictionary type. The operator
outcome/concurrent-spending and historical reply/replay coverage remain intact.
The first full run was114/115: only the old native assertion that the first
review must block an unfunded escort failed. Native coverage now tests both the
new zero-action result and the unchanged historical blocked request. The second
run was interrupted after Python's Windows timeout test left a redirector child
holding a temporary log. PID-tree-only timeout cleanup now stops descendants;
all111Python cases and the dedicated five runner contracts pass. Both timeout
cases also passed20repetitions each (40checks) under the ongoing verifier load.
Failed and
interrupted receipts/logs are retained, rather than represented as a final PASS.

## Final-source verification

Command:

```powershell
.\.venv\Scripts\python.exe tools/qa/verify_project.py --run-id strategy-readiness-20261110-final3 --timeout 180
```

Final115/115PASS,0errors/0warnings:111Python cases,98Godot suites,13scene boots.
The completed full-source fingerprint matches the final tree:
`e26c8757b2d217c8b50d5318956c23879ca35f141dbaee660ce1d8af9e767968`.
Portable [verification](../design/living-world/2026-11-10/strategy-comparison/verification.json),
[integrity](../design/living-world/2026-11-10/strategy-comparison/integrity.json) and
[preservation](../design/living-world/2026-11-10/strategy-comparison/preservation.json)
retain the final result. All11pre-verification save/terrain/art hashes are
unchanged, including the player's deferred Largev4 file. No reset or migration.
Git diff/whitespace checks pass. The existing approved author maps to GitHub
account93617105/KarolBautrel; no placeholder identity or history rewrite.
Source and portable evidence are included in the requested master publication.

Physical status remains AWAITING_INTERACTIVE (L97a-01 and all earlier gaps).
No OS input, window activation, visible/GPU launch, network provider call or
player-save write was performed.

## Next work

Review food provision throughput/targets against actual longer route times;
retain conservative prices and real cargo/escrow. Diagnose repeated diplomatic
proposals before retuning them. Provider/local hosting, model and request/cost
budget remain unselected. Configure a live asynchronous transport only after
that choice; then perform the genuine matched classic/model comparison.
