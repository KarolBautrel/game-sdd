# Stage66: dungeon UI corrected to the world-travel family

The user reports that the first flat design does not resemble the approved
world panel and reiterates DARK FANTASY. Same game-ui-ux/godot-ui-control skills
were used, but the first prototype omitted the established material/illustration
production workflow. The revision uses actual campaign frame_dark/frame_paper /
frame_metal/button/leather/divider exports and packaged fonts/portraits/icons.
Flat olive/chart treatment is superseded and archived, not accepted.

Built-in image_gen edited the approved marches_map.png as an underground mine
parchment. Exact prompt/default generated path and source/export hashes are in
docs/design/dungeon-ui/art/{GENERATION.md,manifest.json}. The original was copied
to assets_src/dungeon_ui_design/2026-11-04; Aseprite exported the1280x570 chart and
320x240 cave-in image and saved both editable files under assets_src/aseprite.
No runtime/accepted art was overwritten. Generation is a design candidate.

Browser matrix: node tools/qa/render_dungeon_ui_design.cjs, final report copied
beside prototype.html.39checks/17screenshots PASS, including resource/fonts,
five resolution bounds, forced-choice input/focus, packing/reward semantics and
actual campaign frame/button + mine illustration usage. Visually inspected the
1080p exploration and cave-in composition. Replaced stretched leather centers
with repeat-tiled existing leather after visual review; preserved native frames.
Five review screenshots retained; more sizes are ignored QA artifacts.

The later user instruction authorizes roughly two hours of staged game work,
desktop input and publication after each verified episode. Stage66 is design
work, so browser composition evidence is the appropriate gate; native game /
ordinary expedition tests belong to67. Existing game files and player saves are
unchanged. validate_all and whitespace check run before publication.

Next: inspect the real dungeon, implement a bounded native interaction/UI pass,
test and operate its actual controls on DISPLAY1, then publish that episode.
