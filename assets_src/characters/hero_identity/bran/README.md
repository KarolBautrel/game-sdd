# Bran: authored equipment identity pilot

Stage61 candidate. The user accepted the original six-role art and stage60 for
now; this newly composed Bran greatsword variant still awaits visual review.

- `comparison.png`: five directions, sword/shield above and greatsword below.
- `preview.html`: seven actions/eight facings per kit, native1x, enlargement,
  actual timing, ground travel, pause and frame buttons. Completely local.
- `head_landmarks.json`: recorded native head references/placements/occlusion.
- `greatsword/`: separate source frames/atlases; no edits to accepted originals.
- `source_proof.json`: every layered Aseprite source reopened and compared,
  actual durations, edit counts, head masks and reflected-view disclosure.
- `accepted_roster_hashes.json`: all2304 accepted runtime PNGs remain unchanged.

The body/rigid weapon poses come from the accepted knight, which already wears
the same blue/gold armour family. Visible front/profile faces use Bran's native
warrior head pixels; falling heads follow the body's roll with nearest-pixel
rotation limited to the head. Rear drawings keep the compatible brown hair.
There is no whole-body resampling, generative replacement, generic equipment rig
or conversion of cosmetic armour slots. Three facings are reflected, reversing
handedness/asymmetry just as in the accepted set.

Editable two-layer sources:
`assets_src/aseprite/characters/hero_identity/bran_greatsword/<view>/<clip>.aseprite`.
Rebuild with `.venv/Scripts/python.exe tools/qa/build_bran_identity.py`, then
`tools/qa/build_hero_equipment_preview.py` and `tools/assets/build_catalogue.py`.
The source build asserts unchanged accepted art and planted idle feet. Walks
retain125ms cels,1000ms cycles and160px stride. New art approval and ordinary
physical campaign victory/return are deliberately recorded separately.
