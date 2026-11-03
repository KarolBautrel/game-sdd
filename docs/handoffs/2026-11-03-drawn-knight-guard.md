# Resume: two-handed guard, then the ordered motion pilot

Work in `game_dir/sdd-game` on `2d-art-research`. Preserve all uncommitted020 and
021 work. No current commit/push or historical Git repair request exists.

Latest user feedback2026-11-03: BOTH static020 finishes fit the game's desired
art direction. They request the combat pose with a sword in BOTH gloved hands,
instead of the previous rest sword-down stance. The assistant proposed static
guard A/B -> short3/4 readiness/walk/cut -> normal-speed native review -> remaining
directions/actions and one-knight integration. User: "Dobra to po kolei kazdy
etap lecimy". This authorizes that order; visual checkpoints remain meaningful.

Read presentation021 / slice021 / milestone016 and stage48. First checkpoint is
delivered and shown as static boards, new pose feedback pending:

- `assets_src/characters/drawn_knight_guard/2026-11-03/comparison.png`
- `assets_src/characters/drawn_knight_guard/2026-11-03/closeup.png`
- `assets_src/characters/drawn_knight_guard/2026-11-03/board_scale.png`
- `assets_src/characters/drawn_knight_guard/2026-11-03/layer_review.png`

Both styles retain the accepted knight/outfit. New grip has the right glove near
the crossguard and left toward pommel, raised straight blade, modest staggered
stance and soft aligned knees. A uses47-color pixel palette/binary alpha; B
painted brushwork/edge alpha. Canvas280x280, foot anchor140,229; bodies66x169(A),
64x166(B). Body scale is uniform and excludes raised sword height.

Source generation: built-in imagegen edits, raw outputs/prompts retained. Aseprite
does ALL raster editing. A targeted generator repair did not fully align the
blade; repeatable Aseprite masks/basis transform put it on the actual handle
axis. Three editable layers: body / rigid sword / foreground gloves. Fill only
the hidden grip section. Other occluded surfaces/poses still need drawing.
All editable masters/native sources and review boards are under
`assets_src/aseprite/characters/drawn_knight_guard/2026-11-03/`.

Builder: `python tools/qa/build_drawn_knight_guard.py`, PASS27 file identities,
native source roundtrip, removable sword, correct sole anchor/margins/palette,
and20 previous020 PNG/source hashes preserved. Validator PASS. Final boards
visually inspected after blade-junction/ground-anchor fixes. Stage48 has limits.

Next work: use the user's guard feedback, fix the pose if needed, then start the
authorized short3/4 readiness/walk/single-cut motion proof. B was the assistant's
recommended working finish, not an exclusive user rejection of A. A remains an
accepted visual option; don't force an artificial reapproval of the entire art
direction. Don't substitute rigid puppet/wrist rotation for a whole-body cut or
declare motion accepted from file metrics. Continuous1x review precedes expanding
the pilot into all directions/actions and the runtime character.

The rejected3D motion archive remains preserved.61 game cases still NOT_RUN.
Desktop control remains unreleased; no mouse/keyboard or visible game/app launch.
Current static work changed no runtime resources/assets/scripts or saves.
External sprite services remain researched/unconnected; no paid provider or
tool installation was used. Previous research/Git details are in the older
2026-11-03 drawn2D research handoff; its production pause is superseded by the
user's current ordered pilot instruction, not by permission to rewrite history.
