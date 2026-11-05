# Smooth world motion

Stage79. Domain owner world012; extends036/037 without changing atlas artwork.

Render committed, weighted-time motion traces rather than running a second A*
between snapshots. One clock owns simulation and interpolation phase. Render
one tick behind committed simulation, with continuous linear time between exact
path points; never ease/restart at grid nodes. Render phase uses the preserved
fixed-tick accumulator, including residual frame time at1x/2x/4x and catch-up.
Speed changes preserve phase; pausing freezes the current pose and phase, and
resuming continues without a snap or a fresh full-tick wait. Opening a new scene
starts at committed positions. Encounter transitions may explicitly synchronize
to the committed contact before opening the modal.

The route overlay prepends the unplayed committed company trace, so its first
line also follows the actual safe bends. All four NPC banners use the same
sampling as the company. Draw their visible banners at subpixel positions, with
native transparent hit/focus targets, to avoid integer-pixel Control snapping.
No visual path recomputation/backtracking to a center.
Actual terrain changes still affect travel time; no interpolated segment may
cut through blocked cells or a diagonal corner.

Proof: slice038, deterministic frame-rate/tick-boundary regression tests and
native GPU per-frame sampling at720p/1080p, with samples/screenshots retained.
Physical feel approval remains for the user; a static screenshot cannot prove
smoothness.
