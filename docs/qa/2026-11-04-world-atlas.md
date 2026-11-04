# World atlas / stage76

Status: IMPLEMENTED / AUTOMATED_PASS / USER_APPROVED_VISUAL_REFERENCE;
physical full-flow acceptance remains pending. The user calls the result
beautiful and explicitly requests preserving it before discussing a larger
living-world campaign. Fixed geography is not approved as the final structure.
See APPROVED_STYLE.md and LIVING_WORLD_PROPOSAL.md in the native gallery folder.
Final source
verification70/70 PASS, zero errors/warnings; checked fingerprint matches the
workspace at the stage76 checkpoint. Stage77 subsequently extends the source;
use the latest living-world QA for current verification. Native stage76
roundtrip362checks/58pointer clicks/20captures PASS.
User explicitly chooses original review point3 before equipment. Preserve the
visually accepted dungeon and accepted Marches world artwork. Changes are local
on master; no commit, push or ordinary physical play is claimed for this stage.

World009 and presentation035 own the change; world slice009/presentation slice035
are its acceptance scenarios. The world now has four provinces, twenty named
destinations and26bidirectional roads. World atlas -> province -> landmark ->
multi-leg plan is integrated into App. Actual travel still commits a single
adjacent leg, with exact costs, town-return reserve, deterministic road events
and atomic persistence. The saved region001 identifier and version4 are stable;
province is derived from location. The original mine/cart edges are unchanged.

Ravenford is the only serviced town and Old Mine the only managed expedition.
New keeps/abbeys/camps/ford/coast sites are travel/viewing locations, with truthful
descriptions; new interiors, shops, healing, quests and repeatable rewards are
not delivered. Geography is authored, not randomized on each visit. A selected
itinerary is temporary UI state; after scene/restart reselect its final target.

## Evidence

- `scripts/session/world_atlas_tests.gd`:170checks/0failures, connected town
  returns, deterministic plans, authoritative leg quotes, exact totals/reserves,
  no preview/cancel mutation, real cross-province save/reload, write rollback,
  event blocking, hierarchy and stale duplicate-confirmation rejection. Every
  shown return itinerary fits exactly its nearest-town reserve; Black Keep
  chooses the three-food/22-hour pass instead of the four-food/21-hour road.
- `campaign_interface_tests.gd`:2468/0; `dark_fantasy_ui_tests.gd`:218/0.
- Native `world-atlas-final`:318checks/40engine-local pointer clicks/16captures,
  keyboard Enter activation,1280x720 and1920x1080, zero errors/warnings. Province
  buttons, text bounds, non-overlapping markers, free browsing/cancel, six-leg
  Ravenford->Black Keep journey, actual road-event interruption and location
  service gates are exercised. Final-source repeat: `world-atlas-delivery`.
- Full source verification `world-atlas-complete`:70/70 PASS before the final
  provision-saving return refinement. Current final-source verification:
  `artifacts/qa-runs/world-atlas-reserve-final/report.json`:70/70 PASS,
  zero diagnostics, exact checked-source fingerprint match. Tracked compact
  receipt: `docs/design/world-atlas/2026-11-04/verification-receipt.json`.
  Final outbound/return fixture: `world-atlas-roundtrip` PASS,
  362checks/58pointer clicks/20captures, zero diagnostics, including a deliberate
  memory-only exact-reserve setup of3food before returning. Both resolutions
  reach Ravenford with0food and normal town services reopened.
  The first sweep `world-atlas-verified` found compact
  party-summary visibility and400px marker-overlap failures. Both were repaired
  and their focused suites repeated; preserve the failed evidence honestly.
- Aseprite:4/4 editable exports reproduce exact runtime PNG hashes. Twelve raw/
  editable/export files and the unchanged Marches reference hash are recorded in
  `assets_src/world_atlas/2026-11-04/manifest.json`. Prompts are adjacent.

Native fixtures use an isolated minimized/no-focus GPU host and memory-only
campaign; no OS input or player save. Headless fixtures use separate save paths.
The compact map retains visible party HP in the header and fits its illustration;
lower journey/service content remains scrollable. Very narrow marker layouts
rearrange labels with tethers. Existing frame/font family is retained.

Native screenshot gallery: [actual engine views](../design/world-atlas/2026-11-04/index.html).

## Accepted appearance preserved

User explicitly approves the appearance and asks to preserve it. Style card:
docs/design/world-atlas/2026-11-04/APPROVED_STYLE.md. Exact preservation bundle/
manifest: assets_src/ui_review_baselines/2026-11-04-world-atlas-approved/.
233payload files,104.7MiBZIP,233/233extracted file hashes PASS. A byte-identical
backup is outside the game repository under workspace backups/sdd-game/.
Runtime code/spec fingerprint remains identical to the70/70checked source.
These documentation/archive changes do not claim physical acceptance, implement
the living-world proposal or publish a new remote checkpoint.

## Player review

From `game_dir/sdd-game`:

```powershell
& .\tools\qa\start_game.ps1 -Scene app
```

1. Click **World atlas**, then each province; browsing must leave location/food/
   clock unchanged. **Find company** returns to the actual current province.
2. In **Iron Highlands**, click **Black Keep**. Inspect stops, whole-plan food
   and next-leg costs. Cancel once, then select again.
3. Buy sufficient provisions in Ravenford before leaving (the initial Black
   Keep plan needs7food including return reserve). Confirm successive named
   stops; resolve road events with normal choices. No distant teleport.
4. Select Ravenford to plan a return; verify exact cost, actual current marker,
   event suspension and normal town/Old Mine gates. Restart once at a remote
   destination to check saved position. The planned final target can be reselected.

Physical case L76-01: NOT_RUN / awaiting player feedback. Current global map is
a playable first atlas; future province interiors/content remain a separate task.
