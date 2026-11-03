# Equipment usability acceptance

Owner: presentation028; stage68. Status: IMPLEMENTED / AUTOMATED_PASS /
AWAITING_INTERACTIVE. Native GPU review is recorded separately from OS input.

1. Inspect the sole owned bow currently on Torin as Bran. Show owned1/equipped1 /
   available0 and Torin's named slot; no transfer occurs and Equip explains why.
2. Inspect a two-handed greatsword with a shield worn, and a shield with a bow
   worn. Explain the exact conflicting slot; do not auto-unequip or consume gear.
3. Inspect two copies of armor with one assigned: available1. Normal equip on the
   other hero remains legal; counts refresh without adding/removing inventory.
4. Select/filter with real buttons: new focus remains on the corresponding native
   control. Scroll a long inventory, refresh and equip/unequip; the position and
   selected tile remain reachable without jumping to the start.
5. Re-run inventory/campaign/gear and native stash captures; preserve the real
   player's save. OS-window acceptance remains separate if activation still fails.
