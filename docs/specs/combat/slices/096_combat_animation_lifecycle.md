# Slice096: animation fallback lifecycle

Owner: ../presentation/074_combat_action_feedback.md
Date: 2026-11-01.

Stage7 real exported playtesting logged two `started with no Tweeners` errors
while Defend produced status feedback without an attack animation.

- Defend through the ordinary command path spends one AP and preserves its
  resolver status; input unlocks and no unused Tween remains scheduled.
- Attack feedback whose actor visual is absent applies the next state/log and
  unlocks input without scheduling an empty Tween.
- Movement with an empty path or missing actor visual has the same fallback.
- Real movement, attacks, death and return continue working in the fresh EXE.

Proof: `scripts/presentation/combat_animation_lifecycle_tests.gd`, combat domain
slices, full verifier, fresh release probe, actual DISPLAY1 playthrough and log
audit. See tooling004 and the stage7 report for final results.
