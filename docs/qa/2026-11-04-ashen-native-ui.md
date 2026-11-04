# Ashen exploration UI production and native review

Latest user follow-up: the current dungeon appearance is approved for this stage.
They request game publication and return to the earlier queue at equipment.
Visual approval is no longer pending; detailed physical full-flow play remains
unreported. The earlier delivery status below is retained as historical evidence.

Stage75, owner presentation034/slice034. Status: IMPLEMENTED / AUTOMATED_PASS /
AWAITING_USER_VISUAL_AND_PHYSICAL_REVIEW. The user approved the four concepts,
authorized separate skill publication and continuation of native production.

## Result and boundaries

DungeonDebug now uses the new Ashen expedition composition. Shared painted
header/company strip, iron/paper inspector, native EB Garamond text, actual
portrait identities/current-max red HP, independent location art/name slips,
current pin, selected wax ring/seal, lock state and model-derived routes/costs.
Packing scrolls while its real Start action stays pinned and visible. The event
scrim/dialog covers every later-added decoration; title/copy clear the iron caps.
Ordinary world UI, actors, resolver and saves are preserved.

There are 59 runtime PNG components: seven room vignettes per theme plus shared
widgets, clean substrates, seals, example portrait settings and resource icons.
70 admitted editable Aseprite sources/11 admitted raw plates are bundled in the
workshop; an early opaque-matte plate and rejected attempts remain archived.
Exact imagegen prompts, originals and exports are under
`assets_src/ashen_ui/2026-11-04/`, `assets_src/aseprite/dungeon_ui/ashen/` and
`assets/ui/dungeon/ashen/`. Exporter: `tools/aseprite/ashen_components.lua`.
Fonts/official source URLs/hashes/notices are saved; EB Garamond is the selected
production face, not a claim that a generated mockup identified an exact font.

All four themes render in the actual native UI. Normal gameplay still uses the
accepted authored/generated Old Mine content. Blackbarrow/Ravenkeep/Crowswood
captures are presentation fixtures using legal mine mechanics and renamed labels;
they do not create new campaign adventures. The existing nine-template pool,
seed behavior and saved runs remain intact. The 15-layout library remains
preparation data awaiting a domain adapter/promotion, not an active runtime pool.

## Verification

- `ashen_exploration_tests.gd`: 378 checks / 0 failures, including true alpha for
  all 28 location illustrations, hollow ring interiors, all four themes, state
  preservation, cost preview, viewport bounds, visible Start and modal layering.
- `dungeon_visual_cohesion_tests.gd`: 692 / 0, truthful routes avoiding unrelated
  plates and fitted whole portraits/HP at 720p/1080p/1440p/4K.
- Route-preview 31 / 0; expedition art direction 99 / 0; party layout and dungeon
  HUD checks PASS. The old child-index room-name assumption was replaced by the
  named RoomName contract; a cast failure had otherwise left its test hanging.
- Session, dungeon-state, entry selection, beta loop and generation-quality
  checks PASS. Quality sweep covers 300 deterministic seeds/all nine templates.
- Repository validator and diff checks PASS. No combat rules changed.

Native GPU evidence uses the existing isolated minimized/no-focus renderer,
actual Controls and engine-local pointer events, no player save or desktop input:

| Run under artifacts/qa-runs/ | Sizes | Checks | Clicks | Captures | Result |
| --- | --- | --- | --- | --- | --- |
| ashen-native-final | 720p,1080p,1440p | 258 | 45 | 42 | PASS,0 errors/warnings |
| ashen-native-delivery | 720p,1080p | 173 | 30 | 28 | PASS,0 errors/warnings |
| ashen-native-modal | 720p,1080p | 61 | 18 | 12 | PASS,0 errors/warnings |

The delivery passes packing/start, free destination preview, confirmed travel,
room event, lamp oil, corridor hazard, loot and generated-map preview/scroll.
Agent inspected actual native family captures, 720p packing, event, selection,
health and generated layout. Geometry PASS alone missed glyphs under fixed iron
caps and decoration stacking over a modal; both were fixed and visually retested.
Actual desktop gameplay/user acceptance is NOT_RUN. Native visual comparison is
reviewable, not automatically labelled pixel-identical to the concept.

Commands from the repository:

```powershell
& "C:/Users/karol/Desktop/Gierka/installers/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://scripts/presentation/ashen_exploration_tests.gd
.venv/Scripts/python.exe tools/qa/render_campaign.py --run-id YOUR_NEW_ID --suite play --views dungeonpolish,ashenfamily --sizes 1280x720,1920x1080 --exercise --timeout 180
.venv/Scripts/python.exe tools/validators/validate_all.py
```

## Portable publication

Private workshop: https://github.com/KarolBautrel/dark-fantasy-ui-workshop.
Current main/tag v0.2.0: `0f98595a437e406eed6086b7fa496a23c0441ee7`.
English package includes actual production art/sources/fonts/prompts, rejected
history, native pilot evidence and a parameterized Aseprite exporter. Its generic
Godot skin helper has no game authority; a full portable HUD/resolver is not shipped.

Release: https://github.com/KarolBautrel/dark-fantasy-ui-workshop/releases/tag/v0.2.0.
ZIP SHA256 `ab564f915e93a74b4e846dce6ec4482c97576e8e3694e55eff089d1ecd0074c5`
matches GitHub's uploaded asset digest (139,329,150 bytes). Remote main/tag and
approved author identity were verified. A clean remote checkout passes all six
portable tests; all four Windows/Linux Python3.10/3.12 CI jobs PASS:
https://github.com/KarolBautrel/dark-fantasy-ui-workshop/actions/runs/41867076331.

A separate new project outside the game checkout reproduced all 59 runtime PNGs
byte-for-byte through Aseprite. Evidence: `artifacts/ui-workshop-review/production-roundtrip.json`.
Official skill validation and 3,600-configuration checks PASS. Installed skill is
updated to v0.2.0 after verifying the old installation was unchanged; v0.1.0 is
preserved at `~/.codex/skill-backups/dark-fantasy-game-ui-v0.1.0-20261104/`.
Only the workshop repo was published. Game changes remain local on master.

## Player review and next work

Open the real game on the configured larger left display:

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
& .\tools\qa\start_game.ps1 -Scene dungeon
```

Default content is randomized. Choose **Use Old Mine** during packing for the
seven-location comparison. Check full HP, labels/paths, destination preview and
cost, one room event, and whether packing controls/Start remain usable. Static
native gallery: `docs/design/exploration-native/2026-11-04/index.html`.

Review1/L67-01 stays open for this actual build; reviews2..6 remain pending.
Next implementation: adapt/promote the 15 authored layouts into legal versioned
domain content with independent length/difficulty and preserve legacy saves/seeds.
Additional playable environment adventures need their own domain content proof.
