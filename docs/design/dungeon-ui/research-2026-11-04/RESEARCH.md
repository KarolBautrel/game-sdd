# Fantasy game UI tools and asset research

Latest user steering: base the next sample especially on the free Bloodlines
pack, without1:1copying. Latest proposal is `ashen-cartographer-concept.png`;
BRIEF-v2 and GENERATION-v2 record game-ui-design decisions and references.
The earlier Moon Tribe recommendation below is research history, not a choice
to purchase/use that pack. Public Bloodlines preview sheets have now been inspected.

Checked2026-11-04. Primary author/publisher pages were read; public pack preview
images were inspected where stated. The generated proposal uses our existing
approved references, not extracted or copied paid-pack components.

## Installed skills and applied workflow

| Skill | Source / terms | Contribution and action |
| --- | --- | --- |
| game-ui-design | [AgentSkills](https://github.com/jeremylongworth-source/AgentSkills/tree/main/skills/game-ui-design), MIT | Installed with the system skill-installer. Read its full entry and game-ui-checklist. Use game decisions, complete states, meaningful hierarchy and native-scale review. |
| frontend-design | [Anthropic](https://github.com/anthropics/skills/tree/main/skills/frontend-design), Apache-2.0 in included LICENSE.txt | Installed with skill-installer. Read the full entry. Applied the plan/critique method in BRIEF.md before generation; game materials/type and real content take precedence over web defaults. |
| game-ui-frontend | [OpenAI game-studio](https://github.com/openai/plugins/tree/main/plugins/game-studio/skills/game-ui-frontend) | Read as a research reference. Browser-oriented, with shared references outside its skill folder; not separately installed or treated as a native Godot theme package. |
| design-ui-ux-game | [fcsouza](https://github.com/fcsouza/agent-skills/tree/main/plugins/game-dev/design/ui-ux-game) | Read and compared. Generic/mobile/minimalist guidance overlaps the installed game skills; not selected as the art-style authority. |

Already available: game-ui-ux, godot-ui-control, create-game-assets, imagegen and
Aseprite. New skill entries become available automatically on subsequent turns;
their installed instruction files were read directly for the current work.

Installation receipts: `C:/Users/karol/.codex/skills/`.

- game-ui-design entry SHA256:
  `3291770337d611d6fc6425e1d273c4dffdc6d5a8634eac8a2c23459f356c303a`.
  Upstream HEAD at installation review:
  `45f314d2a3d3201dd5a0304a3a4f3a5f23a905a2`.
- frontend-design entry SHA256:
  `b8009ae690dfa69edc7f08bb8715f32db8817112cfa4388741dbaf876c237df8`.
  Upstream HEAD at installation review:
  `ca45fc496a3436251f191354091d557da31c15b5`.

## Asset packs

| Pack / publisher | Verified facts | Fit assessment |
| --- | --- | --- |
| [Fantasy RPG UI Pack — Moon Tribe](https://moon-tribe.itch.io/fantasy-rpg-ui-pack) | Paid; PNG/PSD, publisher specifies4K, panel bases/decorations/icons/bars. Publisher permits commercial adaptation under its custom README terms; no standalone resale. Inspected two public previews. | Strongest production-art candidate for depth, coherent crafted frames and editable material layers. Warm treatment would need adaptation to our world. No purchase/download of the paid files. |
| [Bloodlines Dark UI — xGaida/Shieldomirs](https://xgaida.itch.io/bloodlines-ui) | Free personal/commercial use; separate Textures.zip as well as a Unity package. Publisher requires no asset repackaging/resale; full terms are in its LICENSE.txt. | Useful free Gothic alternative. Texture files can be evaluated for Godot independently of Unity prefabs. Not yet imported; exact bundled terms must be read before integration. |
| [Emberhold Free](https://victorgabrielf.itch.io/emberhold-free-dark-fantasy-ui-kit-with-matching-sounds) | Free commercial use with no asset-pack resale; UI components, SVG/PNG icons, matching audio, documented nine-slice insets. Inspected its public preview. | Technically useful, especially states/audio; its cleaner flatter look is less suitable as the main visual target after the user's rejection. |
| [Dark Fantasy Elements — ZSS Game Lab](https://zss-game-lab.itch.io/grimdark-arpg-ui-elements-pack) | Paid PNG/PSD pack with stated commercial use; publisher discloses AI-assisted graphics. | Additional component candidate, not selected ahead of the coherent Moon Tribe direction. No purchase/import. |
| [Dark Fantasy4K — Vill8tion](https://vill8tion.itch.io/dark-fantasy-rpg-ui-kit-high-resolution-4k) | Publisher describes AI workflow, black-background PNG extraction and a4K product; its profile states upscaling. | A4K label alone does not establish native source detail. Not the first candidate for fixing the current texture/scaling defect. |

No account checkout, donation, paid acquisition, pack rehosting or external
message occurred. The current concept contains no third-party pack graphics.

## MCP and connected design tools

The plugin catalogue was searched for Godot/Figma/game-UI capabilities. Figma
is already installed and available: suitable for editable layout/components and
review. Generic app prototyping plugins found in the catalogue were not added.
No dedicated Godot result appeared in that catalogue query.

Separately checked [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp)
(MIT): editor launch, project run and debug-output automation. It is an editor
integration candidate, not a fantasy artwork library. No new MCP was installed
or configured. Existing Godot source editing/native GPU review already supports
the present prototype stage; Figma remains available if an editable board is
chosen next.

## Concrete trial and limitations

BRIEF.md records the design plan and critique. Used built-in imagegen with the
approved world-travel screenshot and textured72dungeon screenshot as references.
Output: `expedition-ledger-concept.png`, a16:9raster art-direction study.

Reviewed: seven named locations, six visible path relationships, compact supply
rail, two portraits and complete red HP, larger chart, destination leaf and one
main action. Material character and scene hierarchy replace the rejected flat
wire-frame treatment. The bright selected path should be toned down during
implementation. Typography and controls must become native nodes; concept text
is baked into the image. Generated portraits are placeholders for the unchanged
approved production portraits. No runtime, input, responsive layout or save
acceptance is implied by this picture.

Temporary runtime remains textured72. Restoration proof: native1080p route PNG
matches its preserved stage72reference byte for byte, SHA256
`1287baf92675bc741c3af0dc91ac878ab3df3fb4deb26c79373de82a4eeb6a09`.
692cohesion checks and validator PASS; native restoration fixture9engine actions,
6captures,0errors/0warnings PASS. Physical acceptance remains separate.

Next: user compares this separate art direction with the temporary current
screen. Only after the look is chosen, prepare full-size source materials and
native Control layouts/states through Aseprite/Godot, then repeat native review.
No later checklist item or publication queue advances automatically.
