# Painted tactical arena pilots

Date:2026-11-04. Authorized stage70. Owners: tooling003 map authoring,
combat overview092 encounter authoring, grid024 terrain and presentation024/025
accepted painted actors. This adds two isolated review scenarios, not campaign
spawn-pool entries or new combat rules.

- Author finite14x11/76px maps in canonical Tiled TMX. Export schema-v2 JSON
  through the existing converter. Spawn metadata identifies each existing actor;
  the encounter builder copies the approved pilot profiles, stats and equipment.
- Forest Ambush: a broken central obstacle belt, northern route toward a ranged
  rise, southern wider flank and low brush cover. Mine Breach: sparse stone piers
  with a narrow upper passage and a two-cell lower passage, rubble/crate cover
  before the crossing and an eastern ranged rise. Initial allies have safe room
  to select/move; no immediate adjacent attack or unreachable unit starts.
- Use existing painted environment assets and actual semantic prop aliases.
  Dress blocked cells as large obstacles, cover as low props; leave movement
  lanes readable. Intermediate blocked cells block ranged line of sight under
  combat/grid022; low cover stays walkable and does not hard-block shots.
  Terrain retains normal MP,
  cover and highground effects; no new bonuses or invisible hazards.
- Forest identifiers take woodland floor precedence over generic ambush/road
  heuristics. Titles and distinct pilot unit names identify both new scenarios.
- At1280x720 the combat chrome uses a compact header, narrower inspector and
  shorter named action tray, with at least18px captions and reachable controls.
  The14x11 board must retain at least500x280px of visible floor; larger logical
  canvases retain24px action captions and the existing material hierarchy.
- All seven actors retain their accepted identities, stats, weapons, SE/SW views,
  planted idles and calm walk timing. Only map references, positions and seed
  differ from painted_enemy_pilot. Existing scenario defaults remain unchanged.
- Each map must be connected, with both authored crossing routes available.
  Normal resolver commands must reach victory with active allies and defeat with
  passive allies, bounded to800commands, with no rejected AI command. Render and
  move through ordinary combat controls at720p/1080p/1440p without mutating saves.

Proof: slices/030_painted_tactical_arenas.md; canonical drift/connectivity Python
tests, painted_arena_tests.gd, combat slices and native arena review. Physical
normal play remains separately recorded when desktop activation is available.

Full-regression maintenance: scenario discovery tests must validate the retained
baseline/default plus extensible canonical entries, not freeze the catalogue at
an old row count. Archive delivery checks keep all source hashes and recognize
registered enabled drawn/identity/tactical profiles for current references.
Legacy asset-path probes must distinguish archived exports from current painted
runtime selection. Refresh only stale environment metadata checksums after
verifying all FBX proofs and unchanged visual/source asset hashes; record drift.
