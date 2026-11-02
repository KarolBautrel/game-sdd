# Persistent campaign equipment

Status: implemented, automated PASS; AWAITING_INTERACTIVE. Stage16,2026-11-01.
Combat rules remain equipment053 (actions/loadout/two-handed) and058 (armor).

Campaign profile v3 adds equipment keyed by the two PartyRoster combat ids, each
with exactly main_hand/off_hand/armor slots (item id or null). Inventory still
contains all owned items, including equipped copies. Equipped counts cannot
exceed owned quantities. Only catalogue Equipment with a combat_profile for the
matching slot may be assigned. Two-handed main hand plus off hand is rejected;
the user explicitly unequips the conflicting item first. No class restrictions,
durability, shop/trade or stat progression. Empty weapon grants no weapon actions.

Stage17/world006 adds explicit town buy/sell services around this ownership
contract. Buying never equips; selling can remove only unassigned copies.
Stage18/world007 migrates to v4 with frozen advancement alongside this equipment
snapshot. Gear ownership/slots and fixed max-HP injury rules remain unchanged.
Stage20/presentation003 replaces form dropdowns with portrait/slot/item-tile
selection and retained local inspection state; persistence rules below stay owned
here. No hidden legacy form controls are part of current UI.

New game owns/equips hero_sword on Bran and hero_bow on Torin. Their action
profiles preserve the current managed dungeon baseline: sword from the authored
dungeon encounter, bow from DungeonRunSession's managed-party profile. Road fights
now use those same persistent weapons instead of encounter-local variants. Loading valid v1/v2 migrates in memory,
preserves all progress/loot/receipts/injuries/world and adds only missing starter
copies for those default assignments. v1 gets default world as before. Existing
active expedition/pending fight gets the same default equipment snapshot. Loading
does not rewrite the old file; next successful transaction writes v3 atomically.
Invalid v3 ownership/loadouts/snapshots block load and preserve the file. Never
regrant items to a v3 save. Existing user://campaign_v1.json filename is retained.

Equip/unequip is an atomic CampaignSession transaction, requires loaded profile,
no active expedition and no pending event, and never changes items, HP or effects.
Failed save publishes no mutation. Expedition begin freezes equipment_snapshot;
road Fight freezes the same before launch. Checkpoints retain it; loading validates
it against ownership and current equipment (mutations are blocked until return).

Managed/road launch injects those catalogue combat profiles, sets each hero's
loadout and resets available_actions to roster base actions, preventing stale
template weapon grants after unequip. Identity/base stats/max HP stay unchanged;
weapon metadata selects matching existing warrior/archer visual. Injury modifiers
apply afterwards. Sandbox/authoring retains its own encounter loadouts.

Available upgrades: cart salvage yields shield (Shield Wall) and patched leather
(armor reduction1); road victory yields salvaged blade (+1 to sword attack damage
bonuses). Existing combat resolver owns costs, damage, cooldowns and reduction.
Starter bow is two-handed. Metadata/schema must validate combat profiles using
the existing encounter item-profile definition and valid action ids.

Stash shows per-hero loadout and separate Hero/Slot/Item selections, Equip and
Unequip buttons. Selection alone has no save effect. It displays owned/assigned
quantities and profile benefit text; locked equipment stays viewable with reason.
Inventory list/filter remains passive; App handles Campaign mutations/feedback.

Proof: world slice005, combat slice102, campaign_equipment_tests, schema/semantic
validation and full regression/export. Actual equip/transfer/expedition/road return
and restart remain L16-01/02 NOT_RUN in docs/qa/live-test-scenarios.md.
