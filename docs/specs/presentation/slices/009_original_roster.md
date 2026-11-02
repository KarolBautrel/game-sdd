# Original roster acceptance

Owner: [presentation009](../009_original_roster.md).

S31: Inventory every configured/data-driven character and aliases; retain old
references/hashes and inspect their design. Compare representative old/new
silhouette, face/equipment exposure and game-scale grounding using a controlled
camera study. Record a chosen common recipe; do not compare mismatched views as
exact overlays.

S32: Verify all human variants have original meshes, rigs, UV/textures, distinct
equipment/palettes, eight-view/five-action exports, matching portraits and FBX
roundtrip motion. Check melee/ranged attachments and legal resolver animations,
legacy IDs/saves, native portraits/board, reset and existing regressions.

S33: Verify anatomy-specific animals, arthropods, flying creatures, serpents and
undead; valid weights/clips, nonempty changing frames and no cut-off appendages.
Prove all27 families/data references resolve only to original assets, aliases
work, and normal game/export routes load them. Check final release/native GPU
gallery at1080p/1440p/4K and register remaining physical cases.

Every batch needs source/FBX/material/frame manifest evidence plus the project
validator/test runner. Physical cases cover normal-speed gait/grip/grounding,
crowded tactical readability and normal campaign victory/return/restart/log audit
after explicit control release.

Executable proof: `tools/blender/verify_roster.py` (actual FBX roundtrip/motion and
long-weapon clearance), `tools/aseprite/roster.lua` (every frame/bounds),
`roster_timing.lua` (saved clip reopen), `tools/qa/check_roster.py` and
`tests/test_original_roster.py` (complete hashed delivery). Godot
`original_roster_tests.gd` proves all families/aliases and passive gallery;
`-- --human-only` scopes stage32. `original_raider_tests.gd` exercises resolver
animation lifecycles; `combat_feedback_polish_tests.gd` checks every family's
top-left resource/target/silhouette placement. `verify_project.py` runs the full
project suite; `export_smoke.py` and `render_campaign.py` exercise the actual
packaged play/campaign views. Stage31..33 reports name final run IDs and outcomes.
