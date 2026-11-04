# Approved world atlas visual baseline

Status: USER_APPROVED_VISUAL_REFERENCE, 2026-11-04.
The user calls the current result beautiful and explicitly asks to preserve it.
Approval concerns the appearance. It does not approve a fixed four-province
campaign as the final game structure, or establish physical gameplay acceptance.

## Preserve

- Antique golden parchment with a continuous natural paper surface and narrow
  irregular worn edges; sepia engraved hatching and oblique miniature landmarks.
- Muted olive forests, blue-green rivers/sea, warm stone mountains and restrained
  dark-fantasy atmosphere. Terrain retains detail at native game scale.
- Existing leather/brass frame family, Cinzel headings, Source Sans3 body text,
  readable native labels, explicit company position and clear selected routes.
- The approved original Marches plate and the four generated world/province
  plates, their raw sources, prompts and editable Aseprite files.
- Real Godot screenshots at720p/1080p, including province browsing, planning,
  a road event, arrival and the exact-reserve return to Ravenford.

Keep labels, routes, ownership and gameplay state native and data-driven. Do not
bake these into a new generated illustration. A fixed painted plate is a visual
reference for future modular world rendering, not a final geography constraint.

## Reproduce or extend

Read presentation035, world009, the stage76 QA report and current handoff first.
Use `create-game-assets`, `game-ui-design` and `godot-gamedev` for their relevant
work; use built-in imagegen for new illustrated plates and Aseprite for editable
source/export. Match this baseline through reference images and native previews.
Keep the original current files when exploring a new direction.

Prompts/provenance: `assets_src/world_atlas/2026-11-04/`.
Editable plates: `assets_src/aseprite/world_atlas/`.
Export: `tools/aseprite/world_atlas.lua`, `from_editable=1` exports existing ASE
files; omitting that parameter deliberately recreates ASE files from raw PNGs.
Runtime art: `assets/ui/campaign/`; shared fonts: `assets/ui/fonts/`.
Gallery: `index.html` in this directory. Verification/native receipts are adjacent.

## Recovery

Preserved bundle:
`assets_src/ui_review_baselines/2026-11-04-world-atlas-approved/world-atlas-stage76.zip`.
Its adjacent manifest records exact file/ZIP hashes and the published base commit.
A second byte-identical ZIP is stored outside the game repository under the
workspace `backups/sdd-game/2026-11-04-world-atlas-approved/` directory.

The bundle contains the working-tree delta plus explicit accepted art/font
dependencies. Restore into a separate checkout of its recorded base, overlay the
payload, and verify the manifest. It is not a standalone exported game.

## Current follow-up

The user wants a mercenary tactical RPG in a large living world inspired by
Battle Brothers and Mount & Blade, with dungeon expeditions as the main activity.
They question a finite static destination atlas. See `LIVING_WORLD_PROPOSAL.md`;
the user authorized its first living-region pilot under world010/presentation036.
Seeded geography and broader campaign content remain later work. This original
visual baseline and its recovery archive stay unchanged.
