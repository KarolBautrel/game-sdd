# Realistic character surfaces: diagnosis and production route

Research date:2026-11-02. Owner [presentation014](../../specs/presentation/014_realistic_character_pipeline.md),
[slice014](../../specs/presentation/slices/014_realistic_character_pipeline.md),
[milestone009](../../specs/presentation/milestones/009_realistic_character_pipeline.md).

The user reports blurred, stretched and apparently overlaid faces after stage40.
Smoothing the existing geometry did not fix the underlying surface method. The
next task is a coherent head/skin pilot, not another whole-roster smoothing pass.
Keep the selected Knight-inspired painted costume direction; realism need not
mean cinematic pore detail or a change of engine/game perspective.

## What the actual files establish

Read-only Blender5.2.3 probe:
`tools/blender/diagnose_face_sources.py`. Saved output:
[face-source diagnosis](evidence/2026-11-02-face-source-diagnosis.json).
The source SHA256 is included; no .blend was saved. The same hash was retained
across both successful diagnostic runs.

| Observation | Evidence | Consequence |
| --- | --- | --- |
| Front face samples a small portion of a whole-body reference | Actual warden .blend:1536x1024 `projection-padded.png`; approximate central front-facing face region spans58.3x85.2 source pixels | A2048px output atlas cannot recover absent face detail. This is an approximate ROI, not the resolution of every anatomical feature. |
| Three view projections blend according to surface normals | `build_painted_candidates.py:projection_material`; actual `Reference_front`, `Reference_back`, `Reference_side` UV nodes | Blending front/profile features that have not been registered to the same anatomy plausibly produces doubled or stretched features. This causal explanation is an inference from the construction and visible symptoms, not a numerical landmark-registration result. |
| Eyes and hair reuse the projected Head material | Actual head/neck, both anatomical eyeballs and swept hair object share the material | Eyes can receive face paint rather than independent iris/sclera alignment; hair inherits the same projection limitations. |
| Face paint already carries designed light | Head shader above1.60m mixes0.88 emission with0.12 diffuse | Useful for a fixed painted concept, but not a complete realistic skin/eye response under changed lighting. |
| Final atlas is a bake of the same projection | Existing factory unwrap/bake/export path; stage39/40 evidence | Baking, subdivision and sharper output filtering do not repair inaccurate source registration. |

Reopened and visually inspected stage40 `details.png`: the before/after bust
retains blurred facial features and a painted hair cap; softer geometry has not
resolved these defects. Prior source/export/UV tests remain technical PASS.
They must not be presented as approval of realistic facial quality. This probe
does not isolate every artifact in every model or establish the runtime zoom limit.

## Practical character bases

### MPFB / MakeHuman: recommended free technical pilot

[Official Blender extension](https://extensions.blender.org/add-ons/mpfb/):
MPFB2.0.18, released2026-10-10, advertises Blender4.2LTS+ support. It supplies a
parametric human workflow rather than independent AI-view projections. Our
Blender5.2.3 compatibility is **not locally tested**.

[Getting started](https://static.makehumancommunity.org/mpfb/docs/getting_started.html)
requires the system asset pack for skins, eyes and related assets; the addon alone
is not the complete character library. Standalone MakeHuman is not required.
[Official asset packs](https://static.makehumancommunity.org/assets/assetpacks/index.html)
list CC0 system assets, Skins02 natural male skins, Skins01 natural female skins
and System eye materials01. Other packs have different licenses; inspect each.
[Core license](https://github.com/makehumancommunity/mpfb2/blob/master/LICENSE.md)
separates GPL addon code from CC0 core graphical assets.

[Material documentation](https://static.makehumancommunity.org/mpfb/docs/materials.html)
distinguishes export-oriented texture materials from heavier layered skin setups;
do not assume every layered setup is suitable for animation/export.
[Face UV focus](https://static.makehumancommunity.org/mpfb/docs/assets/makeup.html)
shows a deliberate face-focused UV layout. This illustrates head texel budgeting,
not an automatic guarantee of realism. [Official scripting samples](https://github.com/makehumancommunity/mpfb2/blob/master/script_samples/index.md)
offer an automation starting point, not a tested local integration.

Service caveat: [the2026-10-21 notice](https://static.makehumancommunity.org/news/2026-10-21-community-site-shut-down.html)
says the legacy forum/asset repository is offline; use the maintained static pack
index and GitHub, not old forum links. A free base still needs art direction and
material review. No cinematic-quality claim is made.

### Human Generator: paid Blender-native alternative

[Human Generator](https://humgen3d.com/) provides human presets, skin, hair and rigs.
[Skin guide](https://help.humgen3d.com/Guide/Skin) documents4K and optional8K assets.
The [Python API](https://humgen3d.com/docs/api) is relevant to repeatable authoring.
The new [Process export system](https://humgen3d.com/docs/process), including
documented engine recipes, is **early access**, not locally verified stable export.
No addon installation or Blender5.2.3 compatibility test occurred here.

[Asset license](https://humgen3d.com/docs/faq/human-generator-asset-license) and
[license FAQ](https://humgen3d.com/docs/faq/license-faq) distinguish GPL code from
paid graphical assets and restrict extractable source redistribution, including
modified assets. Commercial-game use and sharing .blend/FBX/textures in a repository
are separate considerations. Check the selected license and repository workflow
before adopting it. No purchase or trial activation this turn.

### Character Creator5: paid complete character-authoring application

[Official production workflow](https://www.reallusion.com/character-creator/production.html)
and [FBX export manual](https://manual.reallusion.com/Character-Creator-5/Content/ENU/5.0/17-Export/Export-FBX.htm)
describe an external character pipeline. [Headshot3](https://www.reallusion.com/character-creator/headshot/)
is its current photo-based head option. Useful if we choose a broader paid
ecosystem, but more setup than a Blender-native pilot. Neither the application,
its Blender integration, exports nor the selected asset-license terms were tested
locally. No Godot-to-Unreal migration is required for offline sprite production.

## Concrete visual references and specialist materials

- [CG Cookie HUMAN, Kent Trammell](https://www.cgcookie.com/courses/human-realistic-portrait-creation-with-blender):
  a clear reference for head construction, deformation topology, painted skin,
  separate eyes, hair and portrait lighting. Public curriculum inspected; the
  paid course was not purchased/watched. Older Blender UI/API examples need
  adaptation. Use the visible portraits as a facial-quality benchmark rather
  than matching their extreme closeup detail everywhere in our game.
- [3DScanStore free base heads](https://www.3dscanstore.com/blog/Tutorials/Free-Base-Mesh):
  the official indexed description advertises heads sharing topology/UV compatibility
  with its scan texture products. Useful example of matched geometry and textures.
  Full page access returned403; no download occurred. Free geometry does not imply
  that all associated scan textures are free or source-redistributable.
- [KeenTools FaceBuilder](https://keentools.io/products/facebuilder-for-blender):
  an alternative for reconstructing a head from consistent photographs and fitting
  projections to that geometry. It cannot be assumed to reconcile contradictory
  AI views automatically. Paid core; no trial/install/test occurred.
- [Poly Haven textures](https://polyhaven.com/textures) and [license](https://polyhaven.com/license):
  CC0 texture assets can support cloth, leather and metal look development.
  They do not provide a replacement human face. Site artwork and branding are
  distinct from the licensed asset library. No downloads this turn.

The installed Scenario Blender Expert/UV/texturing/rendering skills remain useful
instructions and tools. An MCP bridge executes work; it does not supply coherent
anatomy or fix bad source UV registration by itself. No additional skill pack or
MCP installation is identified as the missing prerequisite.

## Ordered pilot and reusable acceptance gate

1. Start with one representative male head/upper body using MPFB core + Skins02
   + System eye materials01 as the free feasibility test. Record versions, source
   licenses and actual import compatibility. If its quality is insufficient,
   compare a licensed HumGen/CC5 source before investing in the cast.
2. Retain matching source UVs. Use real skin source detail and an explicit head
   texel budget; evaluate2K/4K head maps from genuine detail, not enlarged58x85
   pixels. Give eyes/iris and hair their own correctly aligned materials. Treat
   albedo, roughness and normal data according to their roles.
3. Inspect an unlit/albedo pass, neutral light and changed light, with front,
   profile and three-quarter closeups. Reject duplicate pupils/lips/brows,
   projected hair on skin, stretched seams and waxy skin. A UV-checker pass must
   expose stretching before detailed painting. Save exact model/map identities.
4. Render matched views against the retained warden, plus our native100px/m
   tactical framing and the intended zoom. Closeup quality and tactical
   readability are separate gates. Native camera/zoom behavior still needs an
   actual Godot test later; an offline ground composite is not gameplay evidence.
5. Only after the facial method works, fit the selected Knight-inspired clothing
   and armor. Preserve a reusable head/material/light/render template. Verify
   actual export/reimport and then a second distinct face before a cast rollout.
6. Rigging, grip, idle/walk/attack deformations and sprite integration are later
   work. A static realistic head does not prove motion quality. Existing61
   physical game scenarios remain NOT_RUN and must still be tested with control.

This turn delivers read-only diagnosis, research and workflow notes. No new model,
runtime replacement, paid generation, installation, visible app launch or desktop
input. Stage39/40 sources, production roster and prior dirty work are retained.

## Verification

Blender background `diagnose_face_sources.py`: PASS after deriving dimensions
from the actual image connected to the front UV node; report includes source hash.
`tools/validators/validate_all.py` and `git diff --check`: PASS for this
documentation increment. Both retained source deliveries were checked against
their manifests (202 file hashes); research/handoff local links resolve.
These checks do not establish future pilot art quality.
