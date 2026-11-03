# Combat feedback polish v2

Status: implemented; automated PASS; actual play deferred by user.
Date:2026-11-01. Stage10 / queue17. Owners068/074/087 remain applicable.

## Rules

Feedback remains derived from resolver events, profiles and committed result.
Do not change damage, random rolls, action legality, animation durations or the
existing debug preview information policy as part of this presentation pass.

- Hovering an action shows its profile AP cost, or destination-dependent MP cost
  for movement. Current AP/MP use the same temporary display overrides as bars.
  End turn is0AP. Debug controls describe stepping/reloading rather than a fake
  combat cost. Hover cannot overwrite committed terminal-result feedback or
  an in-progress animation's action banner.
- Rejected commands include the human-readable resolver reason in both detail
  and recent feed. They do not create damage floating text or spend resources.
- Unit target preview has three readable lines for chance/outcome, damage and
  cost. Its text stays inside frame padding and does not overlap the resource
  readout. At the top board edge, clamp the resource readout into the board and
  place preview below its actual final rectangle; status row follows resources.
- After the final animated state is committed, the action context clearly says
  Victory or Defeat and explains the normal return/reset path. Preserve recent
  action history and the existing return button. Do not show victory merely
  because a predicted event is being animated before committed state changes.
  In authoring draft play, direct the player to F6/workbench instead of promising
  that the sandbox scenario picker replaces the retained draft. Dungeon return
  copy must cover both victory and defeat without promising continued exploration.
- Global status, mini-bar values and overhead readouts use the same displayed
  resources during action/impact/step animation. Floating damage/miss/status
  retain the shared helper's distinct colors, cleanup and nonblocking input.

## Proof

Slice099; `combat_feedback_polish_tests.gd` exercises actual scene hover cost,
temporary display values, rejected command reason/resource preservation, result
rendering and top-edge resource/target geometry. Existing targeting, floating
text, animation lifecycle and domain/beta suites remain gates. Live L10-01/02
cover visible hit/miss/status, input unlock, normal victory/defeat and return.
The terminal test awaits actual animated commit with a bounded6second deadline,
so the selected painted bow/death timings are not mistaken for a stuck turn by
a fixed short sleep. This changes verification only, not gameplay durations.
