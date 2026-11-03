# Stage62: two tactical facings

Authorized: user requests SE/SW only in tactical combat, preserving other art.
Owner: presentation024 / slice024.
Status: IMPLEMENTED / AUTOMATED_PASS / AWAITING_USER_VISUAL_REVIEW.

Battle sprites now select SE/SW at CombatUnitArt.unit_direction; battle preload
uses those two directions. Raw sheet lookup, galleries and geographic events
retain all eight views. No raster or Aseprite edits. Accepted2304 PNG hashes and
all seven painted families' eight-view availability verified unchanged.

Proof: tactical_facing_tests.gd4751checks/0, actual HUD startup, northward movement
with per-step callbacks, above-left/right bow attacks through normal resolver
victory, hit/death/final corpse. Geographic visual-state tests PASS. Full drawn/
battle/original/lifecycle/equipment/combat/feedback and identity/campaign/trade
regressions plus validate_all PASS via run_hero_equipment_checks.py.

Next: L62-01 user plays ordinary battle using
`tools/qa/start_game.ps1 -Scene combat -CombatScenario drawn_roster_skirmish`.
Source/gallery preview may still show all eight authored views; this is deliberate
archive access. No city movement, new art, next roster batch, commit or push implied.
