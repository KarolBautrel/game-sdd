# Autonomous world design,98

User explicitly prioritizes whole-world autonomous life and permits simpler
economics. Work: product plan, proposed world024/slice025, world index, priority
notes in the earlier plan/spec, milestone and continuation/handoff. No runtime,
data, schema, map, art, save, provider or desktop changes.

Owners:
[world024](../specs/world/024_autonomous_world_life.md),
[slice025](../specs/world/slices/025_autonomous_world_life.md),
[product plan](../design/living-world/2026-11-10/AUTONOMOUS_WORLD_PLAN.md).

Design covers autonomous actors/goals, four broad strategic assessments,
persistent episode progression/resolution/aftermath, bounded conflict/control,
NPC rivals, accepted company terms, persistent sites, game time, distant regions,
knowledge and visible consequences. Stages99..103 complete local classic world
life before optional104live-model integration. The next vertical slice is a
threatened road with a real camp encounter and actual NPC intervention.

Validation command:

```powershell
.\.venv\Scripts\python.exe tools/validators/validate_all.py
```

Data validation PASS;219local document links checked,0missing; whitespace PASS.
All637runtime/data/tool/test files match their pre-design bytes. Baseline captured
before edits matched the previous117/117source exactly. Runtime fingerprint
excludes documentation and covers the same non-document files as the verifier.
Receipt: [design verification](../design/living-world/2026-11-10/autonomous-world-design/verification.json).
Runtime SHA256 before/after:
`78d76a761661b9c8ea75c2a92e1737401c17a4a9b455bb401c00dbb4962e5a0f`.

The previous117/117 receipt remains historical for97b/c. Documentation is part
of its full source fingerprint, so that exact aggregate changes in98even though
runtime bytes do not. No new full gameplay suite is needed or claimed for a
documentation-only product plan. Slice025's W98scenarios are future acceptance,
not implemented/passed gameplay. All actual-play gates remain open.

No commit/push. Existing97b/c implementation remains local on master654aaa22 and
must not be overwritten. Provider/model/budget still unchosen, deferred behind
local world behaviour. No clock/economy rewrite or player-save reset performed.
