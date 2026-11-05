# Slice043: stationary-pointer combat tooltip refresh

Owner: ../043_live_combat_tooltips.md.

1. Open an actual tile custom tooltip, then submit a normal legal attack through
   CombatDebug. Its existing Label must match the rendered tile after commitment.
2. Repeat for a lethal attack: no living HP remains in the existing popup.
3. Closing/freeing the popup, rerendering and opening another is safe. Its font,
   theme variation and mouse filtering preserve the standard tooltip contract.
4. Capture the actual native tooltip; review ordinary desktop play afterward.

Automated proof: scripts/presentation/live_combat_tooltip_tests.gd. Native GUI
popup evidence and physical gameplay receipts are persisted in stage84 QA.
