# Original tactical character roster

Authorized2026-11-02: user approves the original-model direction and requests
replacement of every existing character, using the old designs as references.
This supersedes stage30's one-pilot scope and prior instruction to test physically
before extending the roster. Desktop control remains unreleased.

## Visual contract

Replace all27 existing configured character families, including the pilot,
heroes/NPC/bandit variants and creatures in debug encounters. Preserve visual
identities: blue warrior/shield, blue hooded archer, red/brown bandits, distinctive
weapons, heavy armour, undead anatomy and species silhouettes. Legacy IDs and
saved visual metadata resolve to original art through explicit aliases. No
changes to combat rules, loadouts, rewards, map legality or saves.

The canonical roster manifest records a retained legacy reference, design brief,
kind, equipment and palette for each model. Hidden surfaces absent from old
sprites are inferred consistently; old sprites are not measured orthographic
plans. Preserve the old source assets for comparison, but stop routing runtime
characters to them after replacement. Do not hide missing original artwork with
a silent legacy fallback.

Use common tactical exposure: upright readable poses, faces and equipment visible
at ordinary board zoom, restrained perspective-free volume. Calibrate a lower
camera elevation against legacy appearance before batch production. Keep one
camera/light/scale/pivot recipe across the roster, with documented species size
differences. Eight real views, not mirrored asymmetric equipment. Grounding and
weapon/fall margins remain stable across every action.

Original authored geometry, fitted bones/weights and material response are saved
as .blend + FBX + baked texture files. Humanoids may reuse CC0 skeleton/motion;
archery/crossbow actions and creature rigs/motion must fit their anatomy. A bow
must read as a bow, a spear as a spear, and an animal must not use humanoid limbs.
Preserve five actions (pose, walk, combat, hit, death), complete frame timing and
final corpse hold. Aseprite owns final pixel normalization/editable exports.
Hero portraits use the matching new model rather than the old illustration.
Canonical frame_seconds also drives editable Aseprite durations and gallery
playback; reopening saved clips must preserve the same timing as runtime.
Long shafts need fitted walk/hit/death wrist tracks rather than generic sword
orientation. Reimported FBX must keep the spear/hand geometry above the ground
within2.5cm sampling tolerance across all five clips. Persist the complete
27-model FBX proof with hashes beside the sources; partial proofs do not replace it.

North diagonals also bias toward a visible face: north_east300degrees and
north_west60degrees. North remains an actual rear view. This corrects the default
spawn's excessive back exposure found during native stage32 review. Resource
panels sit above each family's measured idle silhouette, with targeting feedback
above the resource panel and sufficient board headroom. They must not cover the
actor's face. The gallery is a full-screen modal above battle overlays; its
controls must leave both actor rows visible at the standard logical resolution.

## Ordered background stages

31. Reference inventory and camera/material/pose calibration on representative
    hero, ranged hero and raider. Compare old/new at board scale and inspect
    front/side/rear. Save the target recipe before batch rendering.
32. Complete all humanoid variants and weapon kit, integrate their original art
    and matching hero portraits; validate native/gameplay regressions.
33. Complete all remaining creature variants, anatomy-specific rigs and actions;
    finish routing/aliases, coverage, gallery, native review and final release.

Each stage needs automated PASS and persisted evidence before the next. Physical
acceptance remains AWAITING_INTERACTIVE; add per-stage scenarios to the live
registry. Do not claim continuous-motion approval from stills or fixtures.

Optional environmental prop work follows complete character coverage and must
not alter collision/layout incidentally. Character weapon/shield meshes are part
of this scope and may also be exported as reusable props.

Acceptance: [slice009](slices/009_original_roster.md).
