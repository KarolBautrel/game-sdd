# Character/enemy/animation tooling setup

Status: tooling preparation PASS; production character pilot NOT_STARTED.
Owner: tooling005/slice005. User explicitly reprioritized visual tools before
physical acceptance. No runtime actor/UI/domain changes or new game export.

Research, sources, paths, costs, limitations and next steps are in
[the production guide](../design/character-art/TOOLING.md). Dependency identities
are in tools/assets/character_dependencies.json. The previous uncommitted preview
launcher fix and documentation were preserved; no commit/push was requested.

## Acceptance evidence

| Slice case | Result |
| --- | --- |
| Existing renderer/tools inspected | PASS: current CombatUnitArt maps directional pose/walk/combat/hit/death sheets; retain runtime2D/2.5D |
| Free tools/skills pinned and installed | PASS: Blender5.2.3 official SHA verified, MCP2.2.6 source pinned, Retarget5.2.0 ZIP hash recorded, two focused skills installed |
| Rig/render/FBX roundtrip | PASS: Rigify generated222 bones; isolated skinned diagnostic cube rendered and saved; FBX re-import contains1 mesh/1 rig/1 action |
| MCP actual execution | PASS: initialize/9 tools, edit+assert+save+scene query on owned background Blender; clean shutdown; no GUI/input |
| Motion libraries | PASS: both free Standard ZIPs/licences downloaded; each in-place GLB imported43 actions and65 bones; no paid Pro/Source editions |
| Optional generators | PASS as connector checks only: Meshy MCP0.6.7 initialize/28 tools, CLI0.7.3 version; account not connected; PixelLab/Tripo researched; zero paid/API generation calls |
| Handoff/regression | PASS: repository validators; full workflow and deferred physical gap recorded |

Raw proof: artifacts/character-art-setup/smoke/blender-smoke.json plus native PNG,
.blend and FBX; blender-mcp.json/meshy-mcp.json and logs; background session logs in
artifacts/blender-mcp/. Native PNG inspected: transparent, lit diagnostic cube.
This is a toolchain proof, not a production character approval or actual gameplay.

Defects fixed during verification: Retarget must be enabled through Blender's
addon API so its preferences entry exists; render/export output paths must be
absolute; current-action FBX export must disable NLA-only mode to retain motion.
Affected tests were rerun successfully. Upstream's ordinary server requires GUI;
the pinned addon is unchanged and a documented main-thread queue adapter supports
our background usage. Viewport tools still require GUI and remain unsupported here.

Commands: tools/blender/toolchain_smoke.py through Blender --background (full
command in the guide), `.venv/Scripts/python.exe tools/qa/probe_character_mcp.py`,
`.venv/Scripts/python.exe tools/validators/validate_all.py`. All passed. A future
original model still needs anatomy/weights/retarget/render/runtime review.

All46 gameplay scenarios remain NOT_RUN, AWAITING_INTERACTIVE. No focus/mouse/
keyboard release, visible app launch or player save access occurred.
