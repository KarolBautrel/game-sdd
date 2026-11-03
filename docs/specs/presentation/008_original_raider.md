# Original ash-road raider pilot

Authorized2026-11-02: add an original animated enemy before the deferred physical
play session. Owner: presentation; tooling005 defines the available production tools.

## Art and delivery

One original hooded humanoid raider with weathered leather brigandine, short cowl,
asymmetric steel shoulder, burgundy sash, gloves/boots and a right-hand cleaver.
Use the generated four-view reference under assets_src/characters/ash_raider.
It is an agent-selected target, not user approval of a finished model. Keep
rough dark-fantasy materials and readable volumes at the existing tactical zoom.

Author the mesh and UVs in Blender; preserve the .blend, FBX, textures and builder.
CC0 Quaternius supplies the compatible skeleton/motion, never the visible mannequin.
Retain licence/provenance and prove the exported model by re-import. New paid
generation/account connection is outside this increment.

Render distinct south, south_west, west, north_west, north, north_east, east and
south_east views. Actions: pose4, walk8, combat8, hit4, death8. Pose/walk loop;
combat/hit return to pose; final death frame is held. Use one camera/light recipe
and a fixed ground pivot across frames, without mirroring asymmetric equipment.
Normalize alpha/palette and export editable action/direction sources in Aseprite.
Keep final PNGs runtime-only and model sources outside Godot runtime imports.

The shared canvas is448x352 with ground pivot(224,266), rendered at native pixel
scale. The TextureRect may extend beyond the legacy384x240 unit container while
its pivot remains at the same board anchor. This preserves fall/weapon margins.
Only this actor uses idle0.2s, walk0.065s, combat0.07s, hit0.06s and death0.08s
per frame; all attack frames fit the existing0.56s visual action window. A timer
advances passive idle without overwriting active action clips or changing state.

## Integration

Extend processed character configuration with opt-in eight-direction naming,
fixed-canvas scale/pivot and final-death hold. Existing legacy characters keep
their left/right paths and scaling. Presentation follows resolver events and
does not decide hits, damage, AI, movement legality or settlement.

Add a selectable Ash-road raiders encounter using existing raider melee/ranged
rules and loadouts. Show the original raider in that encounter and the roadside
ambush. Do not replace the rest of the roster or change existing balance/saves.
Use Ash-road Raider as its readable identity and Ash-road Raiders as the new
scenario title. Other characters retain their current labels.

## Acceptance

Verify frame inventory, alpha/clipping, directional distinction, stable ground
pivot, nonempty changing animation frames, all visible vertices weighted, UVs,
triangle budget and a mesh/rig/motion FBX roundtrip. Inspect model front/side/back,
attack/hit/death and actual native GPU board captures. Run targeted presentation,
combat and repository regression checks; export a review build and record hashes.
Continuous normal-speed animation review and physical ordinary gameplay remain
explicit gaps until observed; sampled PNGs cannot establish smoothness or feel.

Proof: [slice008](slices/008_original_raider.md); stage30 remains
AWAITING_INTERACTIVE until its named physical cases pass.
