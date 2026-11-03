# Dark fantasy campaign art direction

The user authorized implementation on2026-11-02 after the UI research, explicitly
choosing the dark fantasy inventory and parchment world-map references. This
supersedes the reuse-only art restriction in presentation003 and the abstract
chart treatment in005. Gameplay and campaign persistence remain owned by world
specs. The presentation does not introduce additional items, destinations or rules.

## Visual contract

- One coherent family: aged dark metal, charcoal leather, restrained brass edges,
  warm readable text, parchment information surfaces and matching illustrated
  item/landmark art. The existing heroes establish the pixel-art character.
- Compare three complete inventory proposals before committing the implementation.
  The user's two selected references anchor the choice; record the selected target
  and the reasons. Concept images are design references, never runtime screenshots.
- Ship project-local licensed fonts with Polish glyph coverage. Body text and
  important item labels remain legible at1920x1080; inspect rendered glyphs. Text,
  quantities, prices, selection, hover, disabled and focus remain native Controls.
- Every catalogue item has an authored icon mapping. Equipment, keys, tokens,
  trinkets and quest items must not collapse into the same bag/shield placeholder.
  Unknown legacy items have an explicit unknown-object fallback.
- Inventory has a visually prominent hero/loadout, compact item grid, and a
  selected-item inspector with a large icon, real description, comparison and
  existing actions. Retain hero/item/category/slot selection and all domain guards.
- The map is illustrated parchment. Its three real landmarks and current routes
  align with the art at all supported sizes. Labels, current-location indication,
  costs and destination gating remain native and truthful.
- The same frame/button/type/icon family extends to trade, training and town.
  Default, hover, pressed, selected, disabled and keyboard focus are distinct.
- Responsive layouts support1920x1080 and2560x1440, with a readable narrow fallback.
  No fixed-width overflow or clipping of essential controls. Native keyboard focus
  is visible and survives relevant updates.

## Assets and tooling

Use Aseprite as the editable/export pipeline for final pixel assets. Preserve
source, export recipes, provenance, original licenses and required attribution.
Keep full vendor packs outside runtime assets; export only selected components.
Generated concepts and illustrations are marked as such in the manifest. The
user's references guide composition; their screenshots are not shipped as art.

Install the requested game-ui-ux and godot-ui-control skills, add the selected free
UI/icon libraries and ThemeGen, and configure the researched local Godot MCP.
Cloud generators requiring a separate account/token are optional dependencies;
the available image-generation tool is the default production route for this batch.

## Verification and continuation

Proof owner: slices/006_dark_fantasy_art_direction.md. Run the existing campaign
and interface suites plus focused new asset/layout/native-render checks. Native
GPU captures are required for visual iteration; reconstructed GDI previews are
not acceptable evidence. Automated engine input may exercise an isolated fixture
only without acquiring desktop focus or changing the player's save.

The user's background-work/deferred-live-test policy continues for this batch.
Actual physical pointer/keyboard, larger left DISPLAY1 windowed play and release
acceptance remain in live-test-scenarios.md until desktop control is released.
Record automated native renders separately from actual visible gameplay.
