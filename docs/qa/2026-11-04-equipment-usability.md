# Stage68: equipment availability and navigation

Owner: presentation028/slice028; world005 unchanged. Status: IMPLEMENTED /
AUTOMATED_PASS / AGENT_GPU_VISUAL_REVIEW / AWAITING_INTERACTIVE.

The item inspector now names equipped heroes/slots and shows unassigned versus
equipped counts. Ownership exhaustion and each two-hand/off-hand conflict have
specific instructions. No automatic transfer, unequip, item grant or save rule.
Item/category rebuilds preserve keyboard focus, refreshes preserve independent
inventory scroll, and normal equip/unequip keeps the selected tile reachable.
Hidden targets fall back to the visible category. Existing campaign materials,
five slots, character identity/animation and owned quantities are unchanged.

Focused equipment_usability_tests19/0: real native selection, filter and equip /
unequip signals on an in-memory campaign, named Torin/Bran assignments, explicit
shield/greatsword conflicts, two-copy armor ownership, real scroll and focus /
hidden-target fallback. Existing visual_inventory13/0, campaign_interface2430/0,
campaign_equipment50/0 and hero_equipment_identity1259/0 PASS. No player save used.

Native source review: render_campaign.py --run-id equipment-68-v1 --views stash
--sizes1920x1080,1280x720,2560x1440 --exercise: PASS,112checks/60engine pointer
events/9captures,0errors/warnings. Inspected the1080p final stash/inspector; all
availability, comparisons and actions remain readable in the approved skin.
Final focused/validator checks are repeated after the hidden-focus fallback.

OS activation remains blocked as documented in stage67; no actual desktop
equip/transfer/restart play is claimed. L68-01 stays open. This independent stage
continues the explicitly authorized unattended polish, with that gate visible.
Next: world destination preview with truthful arrival/cost/danger/reserve before
committing a journey, while preserving the approved world-map appearance.
