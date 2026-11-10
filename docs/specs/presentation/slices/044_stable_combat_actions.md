# Stable action tray acceptance

Owner: ../044_stable_combat_actions.md. Stage85.

1. Load normal sword/shield, greatsword, bow and dagger actors. Snapshot granted
   action order/slot numbers and button positions. Spend AP/MP and start a real
   skill cooldown; retain slots, disable only unavailable actions, show the
   correct reason and preserve costs. Equipment-derived grants remain intact.
2. Click/use a number key for an exhausted/cooling action: no command, resource
   change, selection change or alternate action. Enabled numeric keys select or
   execute exactly their displayed primary action. Developer buttons never gain
   primary numeric shortcuts. Ignore held-key repeats and modified shortcuts.
3. Exhaust the selected action: fall back to a usable action. Spend all AP/MP:
   End turn remains at its original slot and can advance normally. Next unit
   refreshes its own grants/resources. Busy animation and embedded gallery input
   suspension block both click and keyboard paths.
4. Run the real native tray at1280x720,1920x1080 and2560x1440. Disabled captions,
   hover reasons and enabled focus remain inside the HUD. Use ordinary engine
   pointer/key input; do not edit combat outcomes or player saves.

Proofs: scripts/presentation/stable_combat_actions_tests.gd,
scripts/presentation/combat_hud_layout_tests.gd,
scripts/domain/combat_slice_tests.gd and scripts/qa/play_render_review.gd
--review-views=stableactions. Record receipts in the stage85 QA report.
