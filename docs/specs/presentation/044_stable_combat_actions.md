# Stable combat action slots

Stage85, 2026-11-05. Follow-up to the ordinary battle review in stages82..84.
The user authorizes work that does not require their own testing. Existing
combat/actions, equipment profiles and the resolver retain ownership of legality,
costs, cooldowns and results. This spec owns presentation and input only.

- For the current active unit, show its granted primary actions in the existing
  PRIMARY_ACTION_IDS order. AP/MP depletion and cooldowns disable a slot instead
  of removing it. A different unit/loadout may have a different set of actions;
  do not introduce unavailable equipment skills or universal empty placeholders.
- Names, costs and numeric slots remain fixed while that unit spends resources.
  Disabled actions use a muted icon/caption and an explicit AP, MP or remaining
  cooldown reason in their tooltip and hover context. A missing target/range/LOS
  is still a target preview/resolver concern, not a reason to hide a slot.
- Clicks and unmodified number keys1..9 use the same currently displayed primary
  slot. Disabled slots are inert and never activate a neighbouring action or a
  developer command. Ignore repeat/modified keys and suspend shortcuts while a
  gallery/modal suspends battle input. Preserve ordinary native focus navigation.
- When a selected action becomes unavailable, fall back to the first usable
  primary action in display order (normally Move, otherwise another action or
  End turn). Finished combat has no selectable primary actions. Animation locks
  remain authoritative for input and do not alter the displayed granted set.
- Keep the accepted painted chrome, responsive720p/1080p/1440p layout, character
  artwork/poses/timing and all combat-domain behavior unchanged.

Proof: slices/044_stable_combat_actions.md,
stable_combat_actions_tests.gd, combat_hud_layout_tests.gd, combat slices and a
minimized no-focus native action-tray review. Agent/native verification is
distinct from user visual/feel acceptance and physical desktop play.
