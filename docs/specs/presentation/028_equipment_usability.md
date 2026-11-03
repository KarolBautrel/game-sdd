# Equipment availability, explicit conflicts and retained navigation

Date:2026-11-04. Authorized stage68 under milestone022. Extends presentation003;
world005/CampaignSession/Gear still own assignment, conflicts, ownership and saves.

- Inspecting an item shows owned, equipped and unassigned copy counts plus the
  named hero/slot assignments. Counts derive from owned inventory and normalized
  loadouts, not a separate UI inventory. An equipped copy remains owned.
- Equip rejection distinguishes all copies already assigned from a two-handed /
  off-hand conflict, a wrong slot, already equipped and campaign lock. Explain
  which slot must be explicitly unequipped; never auto-remove/transfer another
  hero's gear or grant an extra copy. The backend revalidates every transaction.
- Clicking an item or category keeps native keyboard focus on the rebuilt item /
  category control. Slot/hero inspection does not steal focus into the inventory.
- Inventory refresh retains its independent scroll position; a completed equip /
  unequip retains the selected item's position/focus when still visible. Hidden
  or removed targets fall back safely. These local UI changes never mutate saves,
  consume gear, heal heroes or change combat appearance/behavior.
- Preserve the approved campaign material/typographic family and responsive
  inspection/scroll accessibility. No new item, slot or equipment rule is added.

Proof: slices/028_equipment_usability.md, equipment_usability_tests and existing
visual inventory/campaign/equipment suites, native stash GPU/engine-local input.
