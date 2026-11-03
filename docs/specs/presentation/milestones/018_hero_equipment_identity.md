# Stage61: Bran equipment/identity pilot

Authorized: point1, one hero with sword/shield and greatsword;2026-11-03.
Owner: presentation023 / slice023, world005, combat053.
Status: IMPLEMENTED / AUTOMATED_PASS / AWAITING_INTERACTIVE.
Accepted stage60 remains unchanged. New Bran variant awaits user art review.

Separate identity/kit mapping,352-frame/56-layered-source Bran greatsword variant,
normal merchant/equipment integration and isolated resumable campaign review are
implemented. All2304 accepted PNGs are unchanged; idle planting,125ms walks and
160px stride retained. Source reopen/pixel comparison PASS for all56 sources.

Commands: `tools/qa/build_bran_identity.py`, `build_hero_equipment_preview.py`,
`run_hero_equipment_checks.py` with repo Python. Identity1046/0; normal merchant
and UI transactions, durable ownership/conflicts, frozen road/run restart and
return PASS. Legal AI road victories33commands (shield) /30(greatsword), both
settled. Existing native7386/0, battle313/0, original15679/0, equipment31/0,
feedback179/0, lifecycle/combat plus campaign50/0/trade48/0/validator PASS.
DISPLAY1 ConfigureOnly receipt and headless ordinary App startup PASS.

Next: user reviews both kits with `start_hero_equipment_preview.ps1`, then plays
the separate campaign via `start_hero_equipment_pilot.ps1` (L61-01/02). Preserve
that resumable QA save and the real player save. No next roster batch, commit or
push implied. See docs/qa/2026-11-03-hero-equipment-identity.md and new handoff.
