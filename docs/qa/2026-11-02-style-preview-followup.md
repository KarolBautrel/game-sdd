# Local A/B/C preview follow-up

Owner presentation011 / slice011 / milestone006. Added local opt-in
`scenes/combat/CharacterStylePreview.tscn`, synchronized direction/scale/ground/
face controls, battle Tools -> Style A/B/C and launcher `-Scene styles`.
Aseprite exports12 native100px/m body views and3 face derivatives. Production
roster routing and source models remain untouched. Texture catalogue rebuilt.

PASS:42 headless preview assertions (actual textures, synchronized controls,
modal close/input restore and unchanged combat state), combat slice tests and
project validator. Logs: `artifacts/style-preview-tests.log`,
`artifacts/style-preview-combat.log`, `artifacts/style-preview-import.log`.

Visible launch: `artifacts/qa-runs/launch-20261102T1841530722985Z/launch.json`,
PID28196,1920x1080 logical/windowed, DISPLAY1 physical3840x2160 left of DISPLAY2.
Computer-use screenshot showed all three bodies on earth at200%.
Observed screenshot outer bounds: origin(-3361,-506),2882x1668 pixels, inside
the larger left display. Engine position alone was DPI-virtualized and was not
used as physical placement proof.

A physical click did not establish face-mode activation under150% desktop scaling.
Before the corrected input could execute, the user pressed physical Escape and
the computer-use tool stopped. No later UI input was sent. Do not claim full
physical control acceptance. Existing61 normal-gameplay cases remain NOT_RUN.

These local preview changes are uncommitted. Subsequent user choice is A, with
clay-like finish rejected as final; next authorized scope is research first.
