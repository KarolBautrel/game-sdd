# Original characters and animation: production tools

Follow-up2026-11-02: installed/tested Scenario Blender Expert family15 skills and
Ucupaint3.0.0 in the owned profile for the user-selected Knight painted direction.
See [painted candidates](PAINTED_CANDIDATES.md) and
`tools/assets/painted_character_dependencies.json`. These sources are static
proposals, with no rigged-production or GUI brush-stroke claim.

Verified 2026-11-02. Owner: tooling005 / slice005. The user moved visual tooling
ahead of the physical gameplay session. Setup is complete. The subsequent
[stage30 raider pilot](RAIDER.md) is now implemented, with physical acceptance
pending. The original setup report below is a tooling baseline, not its art approval.

## Chosen route

Concept/reference -> original Blender model -> rig/weights -> authored or
retargeted animation -> orthographic eight-direction render -> Aseprite source
and sheet export -> existing CombatUnitArt mapping -> actual native game review.

The game already renders eight-direction sheets. Original 3D source models make
consistent views and equipment changes possible while retaining that renderer.
This is our production recommendation, not a claim that a finished enemy already
exists. Image generation is available for concepts; Blender can also build assets
without a paid geometry generator. Review silhouettes from the actual tactical
camera before spending time on detail.

## Installed on this workstation

Root: `C:/Users/karol/.codex/tools/character-art/` (outside the Godot runtime).
Pinned sources, SHA-256 values, npm integrity and skill commits:
[`tools/assets/character_dependencies.json`](../../../tools/assets/character_dependencies.json).

| Tool | Verified state | Purpose |
| --- | --- | --- |
| Blender5.2.3 LTS portable | Official ZIP hash matched; background render/save/export/import PASS | Original meshes, materials, rigging, animation, directional renders |
| Rigify, bundled with Blender | Generated222-bone humanoid rig in the smoke | Authoring control rigs; a production rig still needs fitted anatomy/weights |
| Retarget5.2.0 | Release ZIP hash recorded; addon registration PASS | Transfer/edit animation between compatible humanoid rigs; real character retarget quality remains untested |
| MCP for Blender2.2.6 | Pinned upstream commit; initialize,9 tools, actual edit/save/query PASS | Agent-driven bpy operations |
| Quaternius UAL1 + UAL2 Standard | Both downloaded, CC0 licences retained; each imports43 actions on a65-bone rig | Motion sources for our characters; not replacement character art |
| Meshy MCP0.6.7 | Installed; initialize and28-tool discovery PASS, zero API calls | Optional AI geometry, textures, remesh, humanoid rig and animation |
| Meshy CLI0.7.3 | Local installation; version PASS | Official Meshy skill runner, account not connected |
| New skills | godot-animation; meshy-3d-generation installed | Runtime motion and official generator workflow |
| Existing skills/tools | blender-game-assets, create-game-assets, game-development-rendering, Godot skills/MCP, Aseprite1.3.17.2 | Production/review/export and existing UI pipeline |

UAL1 Standard includes locomotion, idle, hit/death and other actions. UAL2 Standard
adds actions including sword movement, zombie movement, interactions and others.
The exact names/frame ranges are in the smoke JSON.43 actions per file includes
the reference A_TPose, and is not a promise of86 distinct motion clips. Root-motion
and in-place variants are downloaded; only the in-place GLBs were import-tested.
The advertised120+/130+ full libraries include paid editions that we did not buy.

New skills are discoverable from the next agent turn. `blender-art` was added to
the user's Codex MCP configuration; a fresh/reconnected Codex session loads its
tools. Existing node_repl, rea and godot-ui definitions were preserved. Shell
commands below work immediately without a new session.

## Background MCP and its limits

Configured command: repository `.venv/Scripts/python.exe` running
`tools/blender/mcp_stdio.py`. It starts an owned factory-startup Blender, binds a
fresh loopback-only port, then starts the pinned upstream stdio server. Blender
stops when that MCP session ends; logs and session metadata are under
`artifacts/blender-mcp/`. No GUI, desktop activation or OS input is needed.

Upstream's addon refuses its normal start() in background mode: timers do not
run inside a blocking Python job. Our small adapter explicitly drains the same
upstream command queue on Blender's main thread. This has been tested end to end;
it does not patch the downloaded addon. Rigify/Retarget are enabled in this owned
scene, with a separate config/scripts profile under `character-art/profile/`.

Use execute_blender_code, data queries and bpy render-to-file in this mode. The
upstream `look`/viewport screenshot and UI pickers need interactive Blender and
are not verified/supported by this background adapter. Inspect rendered PNGs
with view_image instead. Do not attach to or discard a user's open .blend.
The Blender Lab bridge mentioned in the existing blender-game-assets skill uses
a different socket protocol; it is not this upstream MCP and was not registered.

Telemetry is disabled in both child processes. Generator/library integrations
inside the Blender addon start disabled. No account secrets are in this repo.
Meshy discovery was deliberately run with MESHY_API_KEY removed from its process
environment; no generation, upload, credit spend or device login occurred.

## Repeat the checks

From the active repository, without opening any window:

```powershell
$env:BLENDER_USER_CONFIG = "$env:USERPROFILE/.codex/tools/character-art/profile/config"
$env:BLENDER_USER_SCRIPTS = "$env:USERPROFILE/.codex/tools/character-art/profile/scripts"
& "$env:USERPROFILE/.codex/tools/character-art/blender-5.2.3-windows-x64/blender.exe" --background --factory-startup --python-exit-code 1 --python tools/blender/toolchain_smoke.py -- --tool-root "$env:USERPROFILE/.codex/tools/character-art" --out artifacts/character-art-setup/smoke
.venv/Scripts/python.exe tools/qa/probe_character_mcp.py
.venv/Scripts/python.exe tools/validators/validate_all.py
```

Proof: `artifacts/character-art-setup/smoke/blender-smoke.json`, diagnostic.blend,
diagnostic.fbx and diagnostic.png; `blender-mcp.json`, `meshy-mcp.json` and logs.
The visible diagnostic is only a skinned animated cube, not a character concept.
FBX roundtrip preserved one mesh, one armature and one action. For current-action
export use both bake_anim_use_all_actions=False and bake_anim_use_nla_strips=False;
leaving NLA-only export enabled with no strips produced an FBX without animation.

For a new workstation, restore the versions/archives from the dependency manifest,
verify their hashes and preserve the archive licences. Clone MCP at the pinned
commit, make its own .venv, install tools/assets/blender_mcp_requirements.txt there,
then pip install --no-deps the cloned MCP source. Install the two exact npm package
versions into the manifest's separate user-local folders. Extract Retarget to
retarget-5.2.0/retarget and copy it to profile/scripts/addons/retarget; the current
workstation already has these. Re-run the smoke before registering the command.
Use the skill-installer helper with the manifest's repo/path/ref; do not overwrite
existing skill folders. Standard animation ZIPs are the free files linked on the
author's itch.io pages below, not the paid Pro/Source versions.

## Optional cloud tools and researched alternatives

| Candidate | Fit and limitation | Decision |
| --- | --- | --- |
| [PixelLab MCP](https://www.pixellab.ai/mcp) / [tool reference](https://api.pixellab.ai/mcp/docs) | Direct4/8-direction pixel characters, animation and reference style controls; cloud generation and account token required | Best direct-sprite alternative. Remote service, no local binary to download; not authenticated/configured |
| [Meshy official MCP/skill](https://docs.meshy.ai/en/api/ai) | Text/image/multi-view to3D, remesh, texture, motion; use own concept as reference | Local connectors ready, account/budget absent; no paid job started |
| [Tripo official MCP](https://github.com/Tripo-Developer/tripo-mcp) / [rigging docs](https://www.tripo3d.ai/product-doc/module-post-processing/rigging-animation) | Alternative3D provider; Studio documents several creature skeleton types | Keep as an alternative, not a second mandatory subscription. Studio claims do not prove that every rig is exposed by this MCP |
| [Mixamo](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) | Free with Adobe ID; commercial game use permitted; autorig/library for biped humanoids | Optional manual account step, no login or assets downloaded |
| [Poly Haven](https://polyhaven.com/license) | CC0 textures/HDRIs useful for material/lighting references | Source on demand after choosing a model/material brief; no unrelated model collection downloaded |
| [Cascadeur](https://cascadeur.com/plans) | Animation/physics assistance; current free tier only .casc export and non-commercial use | Not needed for the free production baseline; no installation |

[Meshy API pricing](https://docs.meshy.ai/en/api/pricing) is prepaid: current docs
list30 credits for a textured2K image-to3D job,5 for rigging and3 per preset
animation action. Extra remesh/texturing/motion requests cost separately. These
are example credit costs, not a project budget or authorization. Check live
account quotes before any paid submission. [Rigging API](https://docs.meshy.ai/en/api/rigging)
supports clearly structured humanoids, not arbitrary monsters. PixelLab's exact
subscription price is dynamically loaded; it was not reliably verified, so no
monthly price is asserted here. Its MCP docs quote operation-specific generation
costs and its [FAQ](https://www.pixellab.ai/docs/faq) describes trial limits.

The connected plugin directory search did not return Blender, Meshy or PixelLab;
it returned unrelated general video tools and Figma. Direct MCP/CLI setup is used
instead. A video-generation plugin does not supply a usable character rig.

Official download/licence sources:
[Blender releases](https://www.blender.org/releases/),
[Blender ZIP/checksums](https://download.blender.org/release/Blender5.2/),
[Rigify manual](https://docs.blender.org/manual/en/5.2/addons/rigify/index.html),
[Retarget release](https://github.com/KBSBAUDRICE/Retarget/releases/tag/v5.2.0),
[UAL1 Standard](https://quaternius.itch.io/universal-animation-library),
[UAL2 Standard](https://quaternius.itch.io/universal-animation-library-2).

## Production checklist, before replacing the roster

Update2026-11-02: the user has now approved the original-model direction and
authorized the complete27-family replacement. Presentation009 and ROSTER.md own
stages31..33; the pilot-only statements below describe the earlier stage30 gate.
Physical acceptance remains deferred; the live registry now contains55 cases.

The first raider now implements this checklist; see RAIDER.md and stage30 proof.
Its user visual/physical approval remains pending. Reuse the checklist for later
assets only within a new authorized content increment.

1. Measure current actor footprint, frame/pivot contract and oblique angle; save
   a brief and reference board against the approved UI/world. Pick one original
   raider as a pilot. Choose silhouette/materials before producing a family.
2. Create its original mesh, UV/materials and fitted rig. Save one .blend per
   model and deliver FBX plus textures. If a paid generator is chosen later,
   establish account/credit budget first and retain prompt/task provenance.
3. Prove idle/walk/attack/hit/death in all8 directions; inspect feet, weapon grip,
   shoulders, silhouettes, loop boundaries and consistent ground pivots. Retarget
   is installed, but transferring motion to this new body is still production work.
4. Render a consistent camera/light setup. Pixel-art cleanup/export goes through
   Aseprite, assets_src/aseprite and tools/aseprite; do not resize arbitrary AI
   frames and call them a verified animation. Preserve action/frame metadata.
5. Implement an opt-in native preview/integration with a presentation owner/slice,
   exercise the real game camera and actions, inspect GPU captures at target
   resolutions. Only then extend the art family to heroes, monsters, props,
   terrain and effects. Toolchain PASS alone does not establish visual quality.
6. Keep all46 existing physical acceptance cases pending. New content integration
   needs its own cases; actual play occurs after explicit desktop release.
