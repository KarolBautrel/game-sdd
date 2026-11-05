# Live combat tile tooltips

Stage84,2026-11-05. During ordinary Forest Ambush, a stationary pointer retained
the target's old HP even after a resolved attack/death. Godot4.7's default popup
copies tooltip text when it opens; changing Control.tooltip_text alone does not
refresh the existing Label (engine source scene/gui/control.cpp and viewport.cpp).

Tile tooltips must show the same presentation snapshot as actor badges: position,
terrain, HP/AP/MP, status and action legality. A tooltip that is already open must
refresh at the same render boundary as its tile, including a corpse or empty tile.
Retain the native themed tooltip panel/font, wrapping, hover delay and placement.
Use a tile-owned custom Label with a weak reference; no global tooltip polling,
synthetic input, combat outcome changes or access to engine-private methods.
Freed/closed popups must not retain nodes or produce invalid-instance errors.

Proof: slices/043_live_combat_tooltips.md and live_combat_tooltip_tests.gd; native
popup snapshot and subsequent ordinary physical skirmish review. Technical PASS
and agent observation remain separate from user acceptance.
