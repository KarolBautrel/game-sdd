# Dungeon UI art research and isolated proposal

Status: PROPOSAL_READY / DESIGN_ONLY / AWAITING_USER_REVIEW. User rejects the flat72b material correction
and explicitly keeps textured72 as the temporary current version. Preserve
both before researching skills, packs and MCP. Do not replace the game with a
new proposal until its appearance is chosen. Reviews2..6remain pending.

Applied methods: installed game-ui-design (MIT, game decisions/states/navigation)
and frontend-design (Apache-2.0, deliberate materials/type/hierarchy). Read each
full entry and the game-UI review checklist. Existing game-ui-ux, Godot controls,
imagegen and Aseprite remain the native production tools. No framework/engine
migration. No purchased pack, new MCP connection or user visual approval claimed.

## Visual plan before producing a proposal

Working concept: **The Expedition Ledger**. A hand-painted mine chart mounted in
a worn expedition folio, matching the approved world map. The map is the main
object. A narrow destination leaf explains one selected passage; the company
and supplies read as parts of the same folio, rather than equal-weight boxes.

Palette: soot leather#181714, iron#353936, aged brass#9c7a43, parchment#bd9b66,
ivory#e6d8b9, blood red#993c32. No emissive trim. Cinzel headings and Source Sans
3body text remain production type. Artwork is painted and detailed at actual
screen size. Body texture is quiet but present; metal edge shadows show depth.

Composition at16:9: map~70%, destination leaf~26%, modest title/supply band,
compact company strip with two existing portraits and full red HP. Thin authored
map paths and small location labels keep the cave illustration visible. Avoid
repeated square leather, identical huge resource boxes, nested gold frames,
flat black wire boxes and extravagant skull decoration.

Primary action: inspect a real adjacent destination, read actual light cost,
confirm travel. Only show selected-room detail. Keep the existing authored
seven-room/six-corridor graph, two heroes, resources and domain behavior. No
new stress, quests, timers or rewards. The proposed composition is artwork only;
runtime legality/focus/packing remain owned by the existing Godot implementation.

Self-review before building: generic thin gold rectangles on black would repeat
the rejected72b direction. Use authored material depth and one coherent folio
composition instead. A full web-dashboard card grid would also repeat the
previous failure. Keep the actual world reference visible during art generation.

Output: an isolated raster concept for visual review, clearly labelled as a
concept rather than implemented game UI. Baseline72 remains the launch default.
