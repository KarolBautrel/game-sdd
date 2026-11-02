# Equipment, portrait and world art refinement

## Current override: character rollback2026-11-02

The user rejected the stage34..36 character/grip/pose changes after visual review.
Restore exactly the stage33 original roster sprites/animation rendering, before
the weapon/helmet refinements, in native battle and gallery. Do not return to the
older vendor characters. Disable modular GLB atlas integration and the live3D
inventory actor preview. Restore prior weapon-driven hero visual selection.
Keep the new terrain/props/contact shadows, independent illustrated portraits,
item/icon assets, five-slot save compatibility and the unrelated input-race fix.
Preserve source experiments without wiring them into playable scenes. They are
rejected historical experiments, not accepted runtime art. Visible modular armour/
boots/helmet is deferred; do not claim it works on the restored sprite roster.
Validate unchanged stage33 file hashes and observe multiple walk-frame textures
during actual resolver-driven movement in the native fixture. Update handoff and
release identity; previous stage36 EXE is superseded for character presentation.

The remainder records the superseded implementation brief and retained world art.

User feedback2026-11-02: preserve the approved original-model direction while
improving weapon contact/angles, bow visibility, full heavy helmets and dynamic
spearman poses. Replace rendered-model portraits with separate illustrated pixel
portraits. Actual equipped armour, boots, helmet, weapon and shield must appear
on the hero. Rework the entire visible environment/floor family coherently;
hand-painted2D environment art is explicitly allowed by the user.

The tactical grid, resolver, ranges and outcomes remain2D and authoritative.
Use original rigged actors rendered to transparent SubViewport textures inside
the existing2D board; this is a2.5D character presentation, not a3D world migration.
This avoids exponential sprite combinations and supports interchangeable gear.
Headless tests retain the established sprite fallback; native GPU tests must
prove the actual modular renderer. Persist that distinction in every report.

A single shared atlas viewport per host renders actors at100pixels/metre with
18-degree orthographic exposure and the accepted eight front-biased facings.
Rigged mesh components have explicit body/armour/boots/headwear/main/off-hand
channels. Empty slots remove gear, identity/clothes remain, and weapon swaps do
not replace the hero identity. A genuine wrapped palm/hilt socket, diagonal blade
and broadly visible tilted bow replace axial wrist attachments. Spear guard is
near the hip with bent elbows, anticipation/thrust/recovery and weight shift.
Heavy brute helmet encloses crown, cheeks, jaw and rear with a visible visor.
Encounter-local legacy items without campaign appearance metadata retain the
model's default main weapon, or a bow inferred from trusted ranged action grants;
they must not select a nonexistent `weapon_default` component. Empty slots remain
visibly empty. This compatibility path does not alter item profiles or mechanics.

Campaign gear adds helmet/boots slots without invalidating old three-slot saves
or pending expedition snapshots. Existing combat bonuses remain unchanged;
new cosmetic pieces grant no hidden combat effects. Ownership/two-hand rules
and checkpoint transfer apply to every slot. Inventory preview shows the actual
actor alongside the independent illustrated portrait.

Environment routing replaces every displayed legacy floor/decor family with
coherent original painted earth/stone and rendered low-poly props. Preserve tile
legality, cover/elevation/collision, map IDs and authored placements. Palette,
lighting, material grain, silhouettes and detail density follow the actors/UI.
All final raster normalization/source work goes through Aseprite. No paid asset
service/account is authorized; existing Blender/imagegen tooling is sufficient.
Logical blocked/low-cover tiles lacking an explicit prop receive a presentation
terrain silhouette (boulder/wall or log/crate) so legality is visually readable.
This does not add serialized decorations, move authored props, fill empty floor
tiles or change collision. Raised front faces remain30px, matching actor offsets.

Ordered background stages34..36 (user's unreleased-desktop workflow continues):
34. Grip/pose/full-helmet prototypes and all actors; illustrated hero portraits;
    validate modular native atlas before extending equipment.
35. Five-slot ownership/save compatibility, visible equipment variants and live
    equipment preview; validate real transfers and native equip/unequip.
36. Coherent floors/walls/nature/dungeon props and final combined regression/
    export/native review. Physical gameplay/visual approval stays deferred.

Each stage needs saved source/manifest, automated/native proof and a report
before the next. Tests include rendered silhouettes/contacts, body identity,
all equipment slots, backwards compatibility, alias coverage, empty/two-hand
states, first/last frames, all facings, physical ground clearance, and unchanged
map legality. Extend the live registry for normal-speed movement/gear/environment
readability after desktop release.
