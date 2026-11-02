# Campaign interface visual target

The user selected dark fantasy inventory and parchment-map references on2026-11-02.
The generated inventory-concepts.png compares three complete compositions.

Selected: A, upper-left. It matches the requested dark inventory, our existing
mercenary portrait and the parchment information/map treatment. B is too stone
heavy; C makes the entire inventory compete with the future parchment map.

Preserve A's hierarchy: portrait/loadout, compact inventory, light selected-item
inspector. Actual game data has three equipment slots and no drop command; the
concept's extra Compare/Drop buttons are illustration artifacts and are not
implemented. No fictional capacity or loot is introduced by the artwork.

Materials: charcoal leather, aged brass, iron, warm ivory parchment. Headlines:
Cinzel; body and values: Source Sans3. Text, quantities, costs, locks and actions
remain native UI. Body minimum24 logical units, nominal18px at1080p under the
current2560x1440 reference; inspect actual glyphs and increase where needed.

The map uses authored anchors on a calm illustrated parchment background. Only
Ravenford, Broken Cart and Old Mine are interactive. Generated lettering and
controls are never used as runtime data.

Concepts/materials/map/items were generated with the built-in image tool from
explicit material/composition prompts and then prepared through Aseprite. Source
images and complete prompt log live in assets_src/campaign_ui; editable exports
in assets_src/aseprite/campaign_ui and tools/aseprite/campaign_ui_assets.lua.
Owning behavior spec: docs/specs/presentation/006_dark_fantasy_art_direction.md.

Implemented output: [inventory](implemented-inventory.png) and
[parchment map](implemented-map.png), actual GPU captures from the final EXE
at1920x1080 with an isolated in-memory fixture. These are implementation evidence,
not user approval or physical gameplay. The concept sheet remains separate.
Repeatable setup/export/test commands: [TOOLING.md](TOOLING.md).
