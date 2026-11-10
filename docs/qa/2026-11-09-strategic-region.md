# Native strategic-region campaign, stage95

2026-11-09. Opt-in campaignv3 implemented; AWAITING_INTERACTIVE.
Owner [world018](../specs/world/018_strategic_region.md),
[slice019](../specs/world/slices/019_strategic_region.md),
[presentation045](../specs/presentation/045_strategic_region.md),
[handoff](../handoffs/2026-11-09-strategic-region.md).

No desktop takeover, OS input, activation, GPU/visible launch, provider call,
commit or push. All runtime proofs use headless Godot, memory-only profiles or
fresh owned QA files. Old player saves/art/atlas/mask are preservation targets.

## Focused proof

- Domain221checks: nine seed/preset bindings, actual terrain-safe route samples
  forward/reverse, cached-versus-full cost integration, seven-decimal exact JSON
  roundtrip, inner/outer checksums, physical weight and stopped-location gates.
- Session380checks: actual terrain journeys, delivery/recon/report with owned
  stock and reserved budgets, wrong issuer/stock/objective/duplicate rejection,
  provisions exchange, unaccepted expiry, normal retreat, full-day write failure
  rollback, deterministic retry and exact disk reload.
- Managed expedition127checks: real DungeonDebug packing, authored mine choices,
  pending-combat save/reload, real CombatDebug/resolver31ordinary commands,
  victory payload,7g/12XP loot, exit, forced completion-write failure/retry and
  strategic return. Genuine completion restores ore, actual issuer report adds
  reserved28g/12XP once, next daily production changes by the restored5ore.
  This headless path does not prove physical play or animation quality.
- Native interface81checks at1280x720/1920x1080/2560x1440: actual controls,
  layout bounds, nine sites/five tabs, privacy, stable job rows, real callbacks,
  provisions and travel, clock pause, camera isolation and actor controls.
- Six Python tests cover schemas/references, required cause/budget fields,
  version/binding/clock gates, conversion/mine consistency and replay receipts.

Two implementation defects found and fixed before final verification: terrain
costs needed seven-decimal quantization for exact JSON persistence; a cached
outer checksum must not hide a corrupted inner base checksum. Regression cases
now reject both. Headless completion-write failure also exercises retry through
the normal return callback without publishing a partial world.

Physical route-position lookup originally walked/copied the entire path. A
bounded immutable prefix-cost cache now binary-searches the segment and uses
the same terrain integrator within it. Focused1000query measurements improved
from about1.17s to15–18ms, with full-integration parity. This is a local query
benchmark, not a rendered frame-rate or gameplay acceptance claim.

## Final-source verification

```powershell
.\.venv\Scripts\python.exe tools/qa/verify_project.py --run-id strategic-region-20261109-final2 --timeout 180
```

The first full run `strategic-region-20261109-final` had101PASS/1FAIL: the existing
negative foundation test found that new v3 dispatch compared a boolean version
with an integer before type validation. All gameplay/UI suites passed, but the
script diagnostic correctly failed the entire run. Dispatch now uses the shared
numeric-count guard; nested company versions use it too, with an extra regression.
The final2 run repeats all checks on this corrected source. The first run is
diagnostic evidence, not acceptance.

The executed full result, source integrity and preservation receipts follow
below. Portable evidence lives in
`docs/design/living-world/2026-11-09/region/`; complete local logs remain under
the named artifact run. Earlier stage94 results do not count as proof of95.

## Deferred review and next work

L95-01/02 stay AWAITING_INTERACTIVE: readable native map/factions/jobs/company,
camera/continuous motion, normal managed victory, return/report and restart.
All earlier open L91/L77/user appearance and movement cases remain open. The
new pilot is explicit, not a default replacement of accepted travel/combat.

Next96 is recorded model proposals/strict adapter/replay/classic fallback;
provider and cost budget remain unselected. No paid/network inference this stage.

## Final executed result

- `strategic-region-20261109-final2`:102/102PASS,0errors/0warnings. Includes97Python
  tests, Godot import,88Godot suites and10scene boots. Physical review NOT_RUN.
- Final focused suites: domain221, session380, expedition127, interface81 and
  shared foundation-session94checks, all PASS without script diagnostics.
- Domain samples cover nine seed/preset geographies and reverse/cost-based path
  integration. Final1000query diagnostic:15.205ms on this machine.
- Managed trace:31ordinary commands, normal victory, pending-combat reload,
  loot, failed-completion-save retry, restored production, actual return/report
  and exact disk reload. No Debug Win or visible animation proof.
- Exact final source match:
  `c9419c3f2fe045586a4f0f4b2c92804cd9a2d5e34ced113e039a9d69a9a4b737`.
- Eight preexisting saves, accepted terrain mask and atlas:10/10hashes unchanged
  after all tests exited. Local changes are uncommitted; no push performed.
- Local Markdown audit:262targets across12navigation/owner/proof documents exist;
  `git diff --check` exits0. Git reports only existing CRLF normalization notices.
- Stage remains AWAITING_INTERACTIVE: L95-01/02 and all prior open cases remain.

[Full receipt](../design/living-world/2026-11-09/region/verification.json),
[source integrity](../design/living-world/2026-11-09/region/integrity.json),
[preservation](../design/living-world/2026-11-09/region/preservation.json),
[domain output](../design/living-world/2026-11-09/region/strategic_region_tests.stdout.txt),
[session output](../design/living-world/2026-11-09/region/regional_session_tests.stdout.txt),
[managed output](../design/living-world/2026-11-09/region/regional_expedition_tests.stdout.txt),
[interface output](../design/living-world/2026-11-09/region/strategic_interface_tests.stdout.txt),
[ordinary command trace](../design/living-world/2026-11-09/region/ordinary-commands.json).
The same directory retains first-run failure evidence, corrected shared-session
output, selected classic/legacy regression streams and final classic diagnostics.
