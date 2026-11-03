# A selected: research before refinement

Follow-up2026-11-02: user selected **Knight**, authorized installation and new
modelling proposals. The research-only status below is historical. See
[painted candidates](PAINTED_CANDIDATES.md) and presentation012 for the subsequent
implementation and limits; it does not authorize a full roster replacement.

User2026-11-02 selects A / Painterly veteran as direction, but requests a less
clay-like finish. They explicitly ask to review skills, tools/MCP and examples
FIRST. Status: A_SELECTED_REFINEMENT_PENDING / RESEARCH_ONLY. No new model changes,
skill installations, paid calls or desktop control in this research step.

## Assessment and recommended route

Our assessment from the saved A renders/source: hair and mantle forms are too
rounded/uniform, cloth folds lack tension/compression structure, and the largely
procedural material treatment needs designed colour/roughness/shadow hierarchy.
A already has126322 triangles; the next useful work is shape/surface design.

The game already displays directional2D sprites rendered from3D sources. A more
illustrated2.5D result can keep this runtime: improve one A source, paint/bake its
materials, render consistent views, then review at native100px/m. Entirely drawn
characters are an alternative, but their views, equipment and motion need artwork
and animation authoring. This is our project-specific tradeoff assessment.

## Art examples for the user's review

1. [Young Knight — Tomé Costa / María Perez Galan](https://tomecosta.artstation.com/projects/RKP6Qr):
   authors describe painted textures, shadows and highlights for an illustrated
   result based on Gouf Gouf's concept. Useful target for a3D-to-painted treatment.
2. [Knight — Tommy Gunardi Teguh](https://tommygt.artstation.com/projects/EEv98):
   author's process/GIF breakdowns,1024px diffuse-only texture without scene light.
   Concept credited to Kyoung Hwan Kim/Tahra on the page.
3. [Julien Kaspar workflow](https://julienkaspar.artstation.com/blog/X4ar/stylized-character-workflow-blender-2-8-tutorial):
   artist's free condensed walkthrough; older Blender UI, methods still a useful
   reference when checked against our current APIs.
4. [Battle Brothers art decisions](https://battlebrothersgame.com/dev-blog-5-concept-art-explaining-battle-brothers-character-art-style/):
   developer explanation of readable paint and equipment workload. Reference only;
   no decision to remove our legs or animation.
5. [Motion Twin FAQ](https://motiontwin.com/faq): developer confirms most Dead Cells
   art began in3D and was transformed into2D. Technique example, not our art target.

No third-party artwork/mesh was downloaded for reuse. These are references.

## New skill candidate

[Scenario Labs Blender Expert family](https://github.com/scenario-labs/skills/tree/main/skills/dcc/blender),
MIT, inspected revision `7f4b801c7248d51b093ec365aceb114bd06139e6`.
The family contains Python helpers, stage checks and tutorial/source notes.
Its README reports tests on Blender5.2.1; those claims were not independently
executed here. Our Blender is5.2.3. Shared `scenario-blender-expert` scripts are
a dependency; inspect/install the family coherently, not one orphan specialist.

| Specialist | Useful work |
| --- | --- |
| [sculpting](https://github.com/scenario-labs/skills/blob/main/skills/dcc/blender/scenario-blender-sculpting/SKILL.md) | Face/jaw planes, proportions, hair masses and multi-view critique; `bx_sculpt.py` |
| [texturing-shading](https://github.com/scenario-labs/skills/blob/main/skills/dcc/blender/scenario-blender-texturing-shading/SKILL.md) | Masked layers, skin/eyes, wear and material separation; `bx_materials.py` |
| [hair](https://github.com/scenario-labs/skills/blob/main/skills/dcc/blender/scenario-blender-hair/SKILL.md) | Guide direction, clumps, parting and cards/curves; retain only game-scale readable forms |
| [uv-baking](https://github.com/scenario-labs/skills/blob/main/skills/dcc/blender/scenario-blender-uv-baking/SKILL.md) | Portable texture/bake workflow |
| [grease-pencil](https://github.com/scenario-labs/skills/blob/main/skills/dcc/blender/scenario-blender-grease-pencil/SKILL.md) | Optional drawn shadows/lines or a layered2D experiment |

Read as research sources, not activated/installed. Upstream explicitly separates
headless concept work from finishing with real sculpt/paint brushes in a live
Blender GUI. Hair-curve strokes have additional API limits. A future pilot must
verify helpers/bridge compatibility before any polished-art capability claim.

## Tools and MCP

- [Ucupaint demos/docs](https://ucupumar.github.io/ucupaint-wiki/) and
  [releases](https://github.com/ucupumar/ucupaint/releases): layer/mask/bake painting
  addon, most direct texture-pass candidate. Base addon is available without the
  optional Plus purchase. Not installed.
- [Malt](https://github.com/bnpr/Malt): MIT NPR rendering framework. Optional
  illustration/shadow experiment; compatibility with our5.2.3 is untested.
- [Existing MCP for Blender](https://www.mcp-for-blender.com/docs/tools/overview):
  Python execution, scene inspection, visual review. Our background adapter differs
  from a live GUI brush workflow; assess that bridge later. A new connection alone
  does not supply better sculpting/material decisions.
- [Blender Lab MCP](https://projects.blender.org/lab/blender_mcp/wiki): experimental
  alternative researched, not installed/tested; no need to switch just to send bpy.
- [Spine examples](https://esotericsoftware.com/spine-examples) and
  [interactive demos](https://eu.esotericsoftware.com/spine-demos): drawn-layer
  animation alternative, including skins/mix-and-match. Multiple views still need
  artwork. [Saving/exporting requires a paid license](https://esotericsoftware.com/spine-purchase).
  No purchase, installation or Godot integration attempted.

Next: user reviews Young Knight and Knight and identifies the preferred surface
and shape treatment. Only then agree a small A refinement comparison. Keep the
restored27-family animation/world intact; A selection alone does not authorize
an automatic new rigging/integration/roster batch.
