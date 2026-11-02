# Ravenford equipment and loot trade

Status: implemented, automated PASS; AWAITING_INTERACTIVE. Stage17,2026-11-01.
User requested continuation after stage16; retain background-only testing policy.
Stage21/presentation004 supersedes the compact selectors with visual Buy/Sell
grids and inspectors. All pricing/ownership/transaction rules below stay unchanged.

Trading Post is a Ravenford town service. CampaignSession alone commits purchases
and sales through the existing validate/temp/rename/publish transaction. Require
loaded campaign, at_town and no active expedition. Pending events block town
services through at_town. Rejected/failed writes preserve all profile data and
existing save bytes. Inventory remains the v3 string array; no save migration or
vendor state is added. Changes do not affect HP/effects/supplies/XP/equipment.

Schema-validated town_trade/ravenford.json owns town_id and equipment offers.
Stable item ids reference ItemCatalog Equipment. Offer ids are unique; buy_price
is an integer1..1e9 strictly greater than the catalogue appraised value. Stock is
unlimited and UI states this explicitly. Initial buy prices: sword10g,bow10g,
salvaged blade16g,shield12g,patched leather14g. Buying adds exactly one owned copy,
deducts its trusted offer price, never auto-equips, and rejects insufficient gold
or unlisted ids. The API accepts item id only, never caller-supplied prices/rewards.

Selling removes exactly one unassigned copy and credits its catalogue value.
Only known Valuable or Equipment with positive value can be sold. Quest, Legacy,
zero-value, missing or fully assigned items reject. Free copies = owned count
minus assignments across both heroes/all slots. Selling a spare of an equipped
item is allowed, preserving every assignment. Gear.valid still gates the commit.
No supply sales, bulk sales, repairs, crafting, haggling or buyback history here.
Buying then selling cannot generate gold; every successful click trades one copy.

Town exposes Trading Post and Back. Passive TradingView receives copied owned
items/equipment/gold/availability and emits buy/sell requests. Compact selectors
show names, exact prices, owned/free/assigned counts and item descriptions.
Selection alone does not mutate state. Buttons reflect funds/availability; model
still validates every request. Refresh after trade retains selected ids, shows
updated totals and feedback. Back restores town service controls. Existing stash
can equip purchased gear; quest/legacy entries remain visible there and are never
implicitly discarded. UI uses existing fonts/colors/panel conventions.

Proof: world slice006, town_trade_tests.gd, Python source/schema/negative tests,
full verifier and exported Trading Post UI probe. Actual buy/sell/equip/restart
and rejection/readability cases L17-01/02 stay NOT_RUN in live-test-scenarios.md.
