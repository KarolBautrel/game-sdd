# Painted tactical environment candidate

Stage83; agent-selected under delegated polish, user review pending. Built-in
imagegen, not CLI. Reference: native Forest Ambush capture from stage82. The
reference supplies accepted character palette/scale/camera; its low-poly trees
are deliberately replaced with painted counterparts. Original files retained.

Technical frame: Godot4.7,2D orthographic oblique, logical tile140x104, actors
about170px. RGBA props, linear texture filtering, upper-left diffuse light,
muted olive/umber/slate, restrained texture.16individual props, no animations.
Generated4x4 sheet is source material; Aseprite performs deterministic crops,
padding and canvas/ground normalization using existing world_art size/pivots.
Original generation metadata is retained with the raw source when available.

Source: OpenAI built-in imagegen,2026-11-05; generated project artwork, no third
party stock or artist imitation. Distribution subject to project/OpenAI terms;
this record does not assert a public-domain or third-party stock license.

Prompt is stored in prompt.txt. Raw source: generated-source.png. Editable:
assets_src/aseprite/tactical_environment/painted_props.aseprite. Runtime exports:
assets/combat/environment/painted_v2/. The source sheet remains outside Godot
imports via .gdignore. Manifest records all runtime IDs/canvases/pivots/hashes.
