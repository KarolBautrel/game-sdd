# Supply and diplomatic follow-ups,97b/c

User: execute the next steps. Implemented after the published97a baseline,
master654aaa22. Current follow-ups remain local/uncommitted; no new publication
request or desktop control inferred. Owning rules:
[world022](../specs/world/022_supply_pipeline.md),
[world023](../specs/world/023_diplomatic_proposals.md),
[slice024](../specs/world/slices/024_diplomatic_proposals.md).

## Completed behavior

Supply97b uses actual lead time, saved net demand/troops, signed reachable cargo,
soft pending quantities/coin and free slots. Orders can overlap on long routes.
Consent responses share current observed funds, stock and slots; individually
affordable model alternatives still face the actual executor when combined.
Existing order size12, shipment limit32, production, prices and consent persist.

Diplomacy97c exposes only own-pair live negotiations. Fresh planners avoid
proposing an already active/pending pact or duplicate ceasefire, including the
same boundary that answers an incoming offer. Expired incoming trade/pact/peace
records are filtered, and overdue peace offers become expired in ordinary archive
processing. Historical overdue-pending saves remain valid and can propose a new
lawful ceasefire. Reading/loading never rewrites them. Explicit duplicates, stale
responses and simultaneous decisions retain their ordinary legal rejections.

The UI tests now compare visible counts against actual committed operator
outcomes, rather than assuming a particular first-plan result after every tuning
change. Separate genuine historical blocked and explicit zero-action fixtures
retain both behaviors at720/1080/1440p. No presentation behavior or art changed.

## Focused automated evidence

- Diplomatic42checks PASS: actual bilateral signatures, wrong actor/duplicate /
  late rejection, old overdue-pending state, order-independent observations and
  third-party negotiation privacy.
- Supply96/readiness26/classic161/adapter184/native90/comparison348PASS.
- Regional221/session380/model-session67 and regional/model/Vast managed
  127/131/127PASS during97b, including31ordinary resolver battle commands each.
- Validation and111Python cases PASS after97b and97c. Full shared-source run below.
- Matched12faction-only180day worlds and six actual native30day regions at each
  stage: identical opening digests/geography; every transition reconciles.

Portable evidence:
[97b supply](../design/living-world/2026-11-10/supply-pipeline/README.md),
[97c diplomacy](../design/living-world/2026-11-10/diplomatic-proposals/README.md).
Factions-only matrices retain fixed opening job holds. Native probes additionally
run actual job expiry/reposting and idle-company upkeep, with occupied mines and
no player actions. Neither represents an ordinary physical playthrough.

## Measured outcomes

Across97a->97b, classic food-shortfall faction-days581->4, recorded654->2;
native55->4. Through97c they stay4/2/4. This counts faction-days, not elapsed days.
Production, starting resources and geography are unchanged. The occupied mine's
ore shortage remains real; the planner cannot manufacture missing materials.

Across97b->97c, classic rejected intents1731->934; recorded2053->1185. Classic
active-pact retries392->0 and obsolete-trade responses235->0. Native52->0 and
35->0 respectively. Recorded delayed/conflicting proposals still fail legitimately.
Native convoy-capacity contention95->104 is retained, with no invented free slots.
Deliveries vary: classic6238->6191, recorded6125->6165, native937->930. Do not
report diplomacy as an across-the-board delivery improvement or full balance.

## Final common-source verification

```powershell
.\.venv\Scripts\python.exe tools/qa/verify_project.py --run-id supply-diplomacy-20261110-final --timeout 420
```

Final117/117PASS,0errors/0warnings:111Python cases,100Godot suites,13scene boots.
Tested/final source SHA256 matches:
`2aeb2613a3b259cd2a9c2354df2c87a7f0a5c813f51ad77573c7bc5cc693e96a`.
Portable [verification](../design/living-world/2026-11-10/diplomatic-proposals/verification.json),
[integrity](../design/living-world/2026-11-10/diplomatic-proposals/integrity.json) and
[preservation](../design/living-world/2026-11-10/diplomatic-proposals/preservation.json)
retain the final proof. All11tracked persistent save/terrain/art hashes are
unchanged. Git diff/whitespace checks pass. The per-check420second allowance
does not alter world time or mask failures; the18campaign planner suite actually
took98.5seconds. No full-run failure on this final source. Focused development
findings below are retained, not described as accepted intermediate source.

Initial development findings: the first pipeline ignored known transport slots
and saturated capacity, now covered by a32real-shipment gate test. The preparation
fixture needed to isolate eligible military preparation from newly legitimate
procurement. The first-plan assertion needed actual-outcome counts, while
historical blocked/zero-action cases remain explicit. Planner-code changes also
change deterministic future actions: retain old replay/source and update only
the current expected digest, not checkpoint/commands/old request or reply bytes.

Physical L97b-01/L97c-01 and all prior gates remain AWAITING_INTERACTIVE.
No OS input, activation, visible/GPU launch, external-model call or player-save
reset. Current11persistent save/terrain/art files are tracked separately from
fresh test-owned region_mine fixtures that tests create and remove.

## Next

Review actual company travel/traffic/jobs when the user releases controls. Before
live asynchronous model integration and genuine classic/model comparison, choose
provider/local hosting, model and request/cost budget. The authored offline
examples cannot establish real-model quality. Preserve all pending live gates;
do not restart old city/art/tactical rewrite queues or promote this experiment
as the main campaign automatically.
