# Visual inventory and hero loadout

Stage20,2026-11-02; implemented/automated PASS, AWAITING_INTERACTIVE. User authorized the
complete UI polish plan after stage19. Extends presentation002 and world004/005;
CampaignSession/Gear continue owning all inventory/equipment rules and writes.

Replace the inventory text list with responsive icon tiles. Show known/legacy
items, exact stack quantities, assignment markers, tooltips and explicit selected
state. Named category tabs filter without campaign mutations. Clicking a tile
selects it and opens the hero inspector; it never equips automatically. The grid
scrolls independently. Responsive columns must fit1280..2560 logical widths.

Hero picker uses portrait buttons; current hero/HP/level/effective stats and three
named equipment slots stay visible. Clicking a filled slot inspects that item;
clicking an empty slot highlights compatible items. Selecting equipment derives
its slot from trusted metadata. No Hero/Slot/Item form dropdowns. Equip/Unequip
send id/slot to CampaignSession. Show explicit lock/ownership/two-handed reasons
and reject unavailable combinations before sending; backend still validates.
Selection persists across equip/unequip, filtering and refresh while it exists.
An unavailable old selection falls back safely; no hidden compatibility controls.

Inspector shows item icon/name/category/description/quantity/value, currently
equipped item and comparison of authored profile fields (basic attack bonus,
range, armor reduction; action grants). It must not forecast actual hit/damage or
decide combat outcomes. Label increases/decreases with text and color. Quest/
legacy items stay inspectable and cannot be equipped. Changing view never heals,
consumes an item or updates a save. Two independent view instances do not share
selection. Preserve keyboard focus and readable disabled states.

Use compact resource chips, heading typography and warm charcoal/brass palette.
Use existing imported ornament frame/portraits/icons, no raster art creation.
Keep party rail only for region; other tabs use their own hero/service content.
Test real icon/filter/hero/slot/Equip interactions, retention, guards, comparison
metadata and geometry. Owner slice003; visual_inventory_tests and existing suites.
Actual native art/pointer/keyboard/resize still L20-01/02 NOT_RUN.
