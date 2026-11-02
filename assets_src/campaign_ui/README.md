# Campaign art sources

Concept A from inventory-concepts.png is the selected target. Generated source
briefs and generation IDs: prompts.md. Rebuild final pixels with
tools/assets/build_campaign_ui.ps1, then build_catalogue.py and
build_campaign_manifest.py. Manifest hashes original PNGs, editable Aseprite
files and final exports. Full third-party packs and original notices are under
assets_src/vendor; tools/assets/ui_dependencies.json pins downloads.

Final assets: charcoal leather and brass panel frames, parchment,128x64 button,
1280x720 map,768x432 town vignette, sixteen96x96 RGBA item icons, ten32px remixed
glyphs, Kenney divider and slot. Frames use36px corner margins; the small button
uses16px. Runtime texture filtering and native Controls handle scaling without
baking text or values into art. Map landmark anchors live in region_map.gd.

Runtime/legal notices: resources/licenses/campaign-ui.txt. Cinzel headlines and
static Source Sans3 Semibold body have Polish glyph coverage; the static body
font replaced a variable-font rendering issue found in actual GPU captures.

Stage27 extends the same family with eight160x120 dungeon room vignettes from
rooms-source.png (four columns/two rows). The original generated sheet and exact
brief are retained; dark vignette backdrops are intentionally inside room cards.
Source/editable/export manifest now91 files. No unverified alpha-cutout claim.
