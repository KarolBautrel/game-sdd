# Trading and training presentation polish

Stage21,2026-11-02; implemented/automated PASS, AWAITING_INTERACTIVE. Extends presentation003,
world006/007 without changing pricing, training or save rules.

Trading uses visual Buy/Sell grids with selected-item inspectors, prices and
free/owned/assigned counts. Selection persists across transactions; unavailable
selection falls back to first available item. Empty/insufficient/locked states
remain readable. Protected items are excluded by trusted sale quotes. Explicit
Buy/Sell commits exactly one copy through CampaignSession; no selection mutation.

Training uses compact portrait cards, current stats, clear next-stat deltas, XP
availability bar, authored tier/cost progression and one explicit Advance action.
Meaningful descriptions move into tooltips; cost and disabled reason remain on
screen. Existing action ids and public train_buttons map remain testable.

Use common warm skin, ornament hero/service panels, selected/focus states and
short hover/selection feedback (<=0.15s). Tweens belong to nodes and must stop
cleanly when views refresh/free. No action may wait for presentation to commit.
Proof slice004, service_interface_tests, existing town/training suites/export.
Actual visual/keyboard/ordinary use L21-01/02 NOT_RUN.
