# Agent Working Rules

This project is built with Spec Driven Development.

## Session Start And Continuation

Read `docs/CONTINUE_HERE.md` before choosing the next implementation task. It
links accepted stage reports and the active ordered milestone. Read the owning
specs and inspect current Git changes; preserve existing uncommitted work.

For a generic resume such as "Wracamy do tego na czym skonczylismy ostatnio",
read the latest dated handoff linked at the top of CONTINUE_HERE before choosing
work. Follow its accepted/rejected status and outstanding scope decisions; do
not restart a superseded historical queue or infer unresolved approvals.

The default stage loop is: owning spec and acceptance scenarios -> implementation
-> automated acceptance -> actual visible gameplay -> persisted report -> next
stage. Fix failures and repeat affected checks before closing a stage. Headless
checks and Debug Win do not replace normal hands-on victory.

Current explicit user override (extended2026-11-02 to expedition/battle stages27..29
and the original-enemy pilot stage30, extended to full-roster stages31..33 and equipment/world refinement stages34..36): implement the authorized stages in order with
automated checks while the user uses the computer, then perform the accumulated
actual play scenarios together when the user releases desktop controls. Stages8..12
also awaits that session. Record every deferred scenario and its result in
`docs/qa/live-test-scenarios.md`; report stages as AWAITING_INTERACTIVE, not
accepted. Automated PASS permits the next background implementation stage in
this batch; automated failure does not. Full acceptance still needs actual play.

Interactive tests must use a window on the larger left Windows DISPLAY1 on this
workstation. Use `tools/qa/start_game.ps1` and the placement/verification contract
in `docs/specs/tooling/001_stage_verification.md`. Check current monitor mapping;
do not silently launch on the other monitor or overwrite a player's save for QA.

## Default Workflow

1. Read `docs/specs/` before changing gameplay or presentation behavior.
2. Identify the domain spec that owns the rule. If no owner exists, create one in the correct domain folder before implementation.
3. Add or update the relevant domain spec before implementation.
4. Add or update schemas and reference data when behavior depends on data.
5. Add or update executable slices for acceptance scenarios.
6. Add or update the test/validator coverage that proves the slice. If no automated test harness exists yet, record the manual verification gap in the slice and milestone, then add the smallest practical automated coverage when possible.
7. Keep slices as proofs/tests only. Do not define durable gameplay, data, AI, UI, or presentation rules only inside `slices/`.
8. Keep milestones as progress summaries and navigation aids only. Do not use milestones as the only source for implemented rules.
9. Run validation before finishing:

```powershell
python tools\validators\validate_all.py
```

10. Run Godot combat slice tests when combat changes:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/combat_slice_tests.gd
```

11. Always give the user the command for launching the interactive debug scene after combat work:

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game"
```

## Milestone Updates

After every meaningful gameplay/spec change, update the relevant milestone document in `docs/specs/*/milestones/`.

The update should include:

- what changed;
- which specs or slices were affected;
- which commands passed;
- what the next recommended step is.

Do not leave milestone notes only in chat. Persist them in the repository.

When a milestone contains an ordered implementation queue:

- Work on the first unfinished item unless the user explicitly reprioritizes.
- For the current authorized batch, an implemented/automated-PASS item awaiting
  live tests permits work on the next queued item; preserve its acceptance gap.
- Do not skip ahead to a more complex feature while a prerequisite item is unfinished.
- Mark an item done only after the owning spec, slice, implementation, and named validation/test proof are complete.
- If an item exposes missing prerequisite work, add that prerequisite to the queue instead of burying it in chat.

## Spec Ownership Rules

- Every behavior change must follow this chain: owning domain/presentation spec -> chronological slice acceptance scenario -> automated test/validator or explicitly documented manual verification gap.
- Domain folders own rules: `overview/`, `grid/`, `turns/`, `actions/`, `attacks/`, `hit_resolution/`, `equipment/`, `weapons/`, `ai/`, `presentation/`, and future domain folders.
- `slices/` contains chronological executable acceptance scenarios proving that domain rules work.
- `milestones/` contains implementation summaries, validation notes, and next-step guidance.
- When adding a slice for a new mechanic, link the slice back to the owning domain spec.
- When adding a presentation/UI behavior, still add a presentation spec and a slice. If the proof is a helper/unit test instead of a domain combat slice, name that test/validator in the slice.
- When adding a new domain spec, update the relevant `README.md` or structure file that indexes that domain.
- If implementation reveals a rule not covered by a domain spec, update the spec in the same change before finishing.

## Git And Push Policy

Do not commit or push automatically after every change.

- Commit only when the user asks for a commit or when explicitly instructed as part of the current task.
- Push only when the user explicitly says to push, wypchnij, or otherwise asks to send changes to the remote repository.
- It is acceptable to leave validated local changes uncommitted when the user wants to test first.
- Before any requested commit or push, run the relevant validation commands and report the result.
- Before committing, inspect the effective author identity. Never use an invented
  placeholder such as `karol@example.local`. Use the user's approved identity;
  verify GitHub account linkage when attribution is part of the task. Changing
  local config does not rewrite existing commits or grant permission to rewrite
  remote default-branch history. Preserve old refs for any approved author repair.

## Combat Rules

Combat domain rules live in:

```text
scripts/domain/combat_resolver.gd
tools/combat/simulate_combat.py
```

Presentation code must not decide combat legality or outcomes. It sends commands to the resolver and displays events.

## Art Creation Rules

For original characters/enemies/models/animation, first read
`docs/design/character-art/TOOLING.md` and tooling005/slice005. The user prioritized
this visual preparation before physical tests on2026-11-02. Background Blender
MCP is available; viewport/UI tools still need a later interactive session.

Read `agents/README.md` before creating or editing pixel art.

- Pixel-art work must use Aseprite as the source/editor pipeline.
- Terrain art must follow the current tactical 2.5D/oblique direction, not flat top-down debug tiles.
- Keep exported assets repeatable: store Aseprite sources under `assets_src/aseprite/` and generation/export scripts under `tools/aseprite/` when practical.
