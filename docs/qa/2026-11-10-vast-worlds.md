# Vast world maps, follow-up96c

[Owner world020](../specs/world/020_vast_regions.md),
[slice021](../specs/world/slices/021_vast_regions.md),
[presentation048](../specs/presentation/048_vast_worlds.md),
[handoff](../handoffs/2026-11-10-vast-worlds.md).

User leaves existing save/retest alone and requests larger maps. Actual new
Vast generatorv3 /768x432 /4xLarge area, shared physical scale4, local framing and
separate size slots are implemented. No player migration/reset, extra fictional
site content, paid provider, OS input, desktop activation, visible/GPU launch,
commit or push. All tests use headless processes/memory/fresh owned QA files.

## Focused proof

- Domain72checks: three actual Vast seed/preset strategic bindings, all nine
  sites/seven safe paths, climate/crossings, exact snapshot roundtrip, reverse
  path interpolation, physical caravan/company scale and camera area. Six old
  v1/v2 snapshot checksums remain identical. Data are genuinely768x432, not zoom.
- Session38checks: unchanged old slot names and independent size/format paths,
  real Vast travel, failed-write whole-state rollback/retry/exact reload, legacy
  living-mode compatibility and30days of longer-route conserved world simulation.
  This proves validity/accounting, not economic balance or enjoyment.
- Native84checks across720/1080/1440p and both formats: local5.2/max9, quarter-area
  local chart versus Large, minimap/overview/Company, style reference width6688,
  readable controls, size selection without mutation and correct opening/return.
- Managed127checks/31ordinary battle commands: real wider-map journeys, owned
  packing, pending combat reload, normal victory/loot/exit, failed-save retry,
  restored ore, issuer payment, exact reload and correct Vast return. No Debug Win
  or physical animation proof. V3native81/model78/foundry81regressions also PASS.
- Six Python cases cover new schema/data, size/diagnostic rejection, scaled route
  weights and old snapshot/schema compatibility. All110Python tests PASS before
  the final complete run. Rebuild scripts keep embedded/standalone schemas exact.
- Supplementary Foundry11/11native headless checks PASS: actual Vast choice,
  generation/camera/summary, read-only route preview and both legacy/strategic
  opening paths. The retained script/JSON are separate from the full suite count.

Focused failures corrected before final verification: negative generator input
tests now reject unsupportedv4 becausev3is supported; a new biome binding test
needed the core rather than its classic wrapper; schema copies needed the same
standalone living-state contract and omitted inline `$schema` metadata. Assertions
were retained and reruns pass. Terrain writer restrictions were not relaxed.

## Final-source verification

```powershell
.\.venv\Scripts\python.exe tools/qa/verify_project.py --run-id vast-worlds-20261110-final --timeout 180
```

Executed results/integrity/preservation follow below. Portable evidence:
`docs/design/living-world/2026-11-10/vast/`; complete local logs remain under the
named artifact run. Earlier107/107 and targeted96b receipts are historical.
L96c-01 and earlier visual/input/strategy cases remain AWAITING_INTERACTIVE.

## Final executed result

- `vast-worlds-20261110-final`:113/113PASS,0errors/0warnings, including110Python
  tests, import,96Godot suites and13scene boots. Physical review NOT_RUN.
- New suites: Vast domain72/session38/native84/managed127checks PASS. The wider
  mine trace contains31ordinary commands, real loot/return/report and exact reload.
  All old suites pass, including v1/v2 checksum and native travel regressions.
- Supplementary native Foundry11/11checks PASS. Generation/binding timings for
  the three wider biome cases are retained as CPU diagnostics, not FPS claims.
- Exact final source match:
  `d95384ec3ed753bf6390f295d7069cb22294175306e21ec23a532b0f457a42bf`.
- Eight baseline saves, authored mask and approved atlas:10/10hashes unchanged.
  The player's existing Large v4 file remains generator2/tick410. Its hash differs
  from the older96b receipt at343; its last write was22:38:33UTC, before this final
  run began23:04:27UTC. This is recorded separately, not falsely counted as an
  unchanged old receipt. No reset/migration or test writer targeted that slot.
- No new commit/push or visible launch. L96c-01 and prior open cases remain.

[Full receipt](../design/living-world/2026-11-10/vast/verification.json),
[integrity](../design/living-world/2026-11-10/vast/integrity.json),
[preservation](../design/living-world/2026-11-10/vast/preservation.json),
[generation diagnostics](../design/living-world/2026-11-10/vast/generation.json),
[domain output](../design/living-world/2026-11-10/vast/vast_region_tests.stdout.txt),
[session output](../design/living-world/2026-11-10/vast/vast_session_tests.stdout.txt),
[native output](../design/living-world/2026-11-10/vast/vast_interface_tests.stdout.txt),
[managed output](../design/living-world/2026-11-10/vast/vast_expedition_tests.stdout.txt),
[ordinary commands](../design/living-world/2026-11-10/vast/ordinary-commands.json),
[Foundry receipt](../design/living-world/2026-11-10/vast/foundry.json).
