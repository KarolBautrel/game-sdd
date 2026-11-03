# Character art research and static style studies

Researched2026-11-02. Owner: presentation011. These studies are isolated from the
restored stage33 roster. The user will choose a style before any new integration.

## What helps this project

The previous primitive-built characters lacked anatomical facial forms and
continuous tailored surfaces. Another MCP connection alone cannot fix that.
Use a proper anatomical scaffold, design a strong costume silhouette, separate
large material/value shapes, then inspect the actual100px/m tactical render.
These are our production conclusions, not an upstream quality guarantee.

| Primary source | Findings and actual use |
| --- | --- |
| [Blender Studio Human Base Meshes](https://www.blender.org/download/demo-files/) | Official v1.4.1 CC0 bundle, realistic/stylized male bodies and eyes used as anatomy/topology scaffolds. Face/neck retained; authored costume, hair, beard, armour, shield and sword added separately. This is **not** a claim that the underlying anatomy was authored from scratch. |
| [Character artist skill](https://github.com/arjun988/blender-skills/blob/main/.claude/skills/character-artist/SKILL.md) | MIT workflow reference: establish proportions first, maintain facial/joint topology and separate clothing/gear. Read and applied as guidance, not blindly executed. |
| [Stylized style skill](https://github.com/arjun988/blender-skills/blob/main/.claude/skills/stylized-style/SKILL.md) | Read limited-palette, shape-language and native-size silhouette guidance. Used a common blue/steel/leather identity, changing anatomy/costume construction and graphic treatment. |
| [Comic book style](https://github.com/arjun988/blender-skills/blob/main/.claude/skills/comic-book-style/SKILL.md) and [NPR shader notes](https://github.com/arjun988/blender-skills/blob/main/.claude/skills/stylized-style/references/npr-shaders.md) | Read contour/tonal grouping approaches. B uses stepped object-space colour and a render-only backface contour hull. Its FBX has baked colour; the hull is deliberately excluded. |
| [Hand-painted style](https://github.com/arjun988/blender-skills/blob/main/.claude/skills/hand-painted-style/SKILL.md) | Soft bevels and restrained material variation inform the miniature study. Current surfaces are procedural/baked, **not** hand-painted production textures. A dedicated painted-texture pass remains future work. |
| [Valve Character Art Guide](https://help.steampowered.com/en/faqs/view/0688-7692-4D5A-1935) | Upper-body value hierarchy and silhouette readability are useful for a tactical camera. Research reference only; no Valve meshes/textures copied. |
| [Blender Studio Stylized Character Workflow](https://studio.blender.org/training/stylized-character-workflow/) | Reference for blockout/sculpt/retopology progression. Listing/free lesson material was available; paid training was not purchased or claimed completed. |
| [MPFB](https://extensions.blender.org/add-ons/mpfb/) / [official license](https://www.makehumancommunity.org/about/license.html) | Useful future anatomy variation tool: core assets CC0; addon code GPL. Not installed or used by these studies. Third-party clothing may have other licenses. |
| [Malt](https://github.com/bnpr/Malt) | Optional NPR rendering framework. Researched, not installed; compatibility with our Blender5.2.3 has not been tested. Current studies use built-in Cycles and do not require it. |

Skill pack upstream revision inspected:
`arjun988/blender-skills@8f778d2405a214b508d4c7d80742be8e43acdd52`.
The pack's skill prose is advice, not a library of finished character models or
an automatic quality guarantee. Existing local `create-game-assets`,
`blender-game-assets` and `game-development-rendering` remain the working skills.
No global skill/MCP configuration was overwritten and no paid generators called.

## Reproducible scaffold

Official archive:
https://download.blender.org/demo/asset-bundles/human-base-meshes/human-base-meshes-bundle-v1.4.1.zip

Download/extract outside the game to:
`%USERPROFILE%/.codex/tools/character-art/base-meshes/unpacked/`.
The exact archive and library SHA-256 are recorded in `provenance.json` beside
the studies. The used anatomical geometry is saved inside each committed .blend
and FBX, so viewing the deliverables does not require the downloaded archive.
Rebuilding from script requires that pinned archive. CC0 declaration is on the
official demo-file listing. [CC0 legal code](https://creativecommons.org/publicdomain/zero/1.0/legalcode.en).

## Three studies of the same mercenary

- **A / Painterly veteran:** anatomical adult head, asymmetric shoulder protection,
  layered leather brigandine, muted wool/leather/steel. A starting point for a
  grounded dark-fantasy painted texture pass.
- **B / Ink warden:** narrower body, broader angular face, peaked steel cuirass,
  tapered cloak, stepped dark values and contours. Most graphic interpretation.
- **C / Heroic miniature:** stylized anatomy and larger facial features, wider
  shoulders, broader armour/shield/weapon, brighter blue/brass material blocks.

All use the same neutral exposure, three studio lights,18-degree elevation,
orthographic three-quarter yaw330 and100px/m tactical sample. Close renders are
larger for inspection. Lighting, camera and authored procedural graphs live in
each .blend. Portable FBX uses2048px baked colour plus roughness/metal values;
procedural bump/ink contours and B's graphic emission shader are authoring-render
features, not portable shaders. B also has restrained procedural hatching.
No AI-painted render is presented as a real model. The displayed images are
actual Blender renders of the delivered meshes.

Rebuild: `blender --background --factory-startup --python-exit-code 1 --python
tools/blender/build_style_studies.py -- --style a` (repeat b,c).
Raster comparison: `tools/aseprite/style_studies.lua`, via Aseprite batch/hidden.
Verification: `tools/blender/verify_style_studies.py` and repository validators.

## Scope limits and next decision

These are static design prototypes, not rigged/animated/game-ready replacements.
No complete retopology/LOD/weight or locomotion acceptance is claimed. After the
user selects A/B/C (or a specific combination), author one rigged pilot, verify
grip/gait/8 views in motion, then request a separate roster rollout. Existing
physical61-case gameplay backlog stays pending until desktop control is released.
