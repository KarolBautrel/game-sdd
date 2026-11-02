# Character art production tooling

Owner: tooling. Requested 2026-11-02, before the deferred physical acceptance
session. This increment prepares visual production; it does not replace actors,
change combat rules, or accept stages that still require ordinary gameplay.

## Production direction

The current renderer consumes eight directional character sheets with pose,
walk, combat, hit and death actions. Prefer original models/rigs in Blender,
rendered to that existing contract, with editable pixel-art cleanup/export in
Aseprite. Keep the approved dark-fantasy UI and oblique tactical camera as visual
references. A full 3D runtime migration is outside this task.

Preserve original .blend files, FBX plus textures for character delivery, animation
sources, licences, direction order, pivots, frame counts and generation provenance.
AI output is a draft until inspected for anatomy, silhouette, materials, skinning
and temporal consistency. A single enemy pilot must prove the pipeline before
replacing the roster. Non-humanoid creatures need an appropriate custom rig;
humanoid retargeting is not evidence that a monster works.

## Local dependencies

Install useful free tools in a versioned user-local location, outside runtime
assets. Record source versions and hashes. Do not overwrite user settings, other
Blender sessions or existing Codex integrations. Prefer a portable stable/LTS
Blender, existing Aseprite and Godot, a reviewed Blender MCP and a focused Godot
animation skill. External generators are optional; installing their connector
does not authorize paid generation or imply a usable account/API key.

Download only explicitly free animation library variants and retain the licence.
Do not describe a paid Source edition or all advertised clips as installed when
only a free subset was obtained. Do not add unrelated premade character packs.

## Verification and handoff

Use background processes without desktop focus/input. Prove Blender starts,
basic scene save/render/FBX export/re-import, available rigging functionality,
and MCP initialize/tool discovery plus actual local execution where supported.
Use an isolated diagnostic object, not a new production character. Verify any
downloaded animation library by importing it and inspecting its actions/rig.
Keep setup metadata and repeatable commands in the repository; raw binaries and
diagnostic renders belong in ignored artifacts or the user-local tools folder.

Research notes must distinguish installed-and-tested, available-but-unconnected,
and rejected/deferred options. Update CONTINUE_HERE and the live-test registry
without marking any of the 46 pending gameplay cases passed.

Acceptance scenarios: [slice005](slices/005_character_art_pipeline.md).
