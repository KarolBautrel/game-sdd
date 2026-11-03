# Stage verification reports

Continuation status and the next unfinished task: [CONTINUE_HERE.md](../CONTINUE_HERE.md).
Accumulated actual-play acceptance: [live-test-scenarios.md](live-test-scenarios.md).

Research baseline: the user rejected the earlier UI appearance. See
[UI research and proposed design sequence](2026-11-02-ui-design-research.md).
The subsequent authorized response is presentation006, stages23..26: selected
concept A, new coherent assets, dark inventory and parchment map. It does not mark
any live test PASS; user visual approval remains pending.
The user subsequently approved the campaign appearance and requested the same
family for dungeon and battle. Stages27..29 implement that extension; physical
acceptance remains separate in the46-case live registry.

The accepted implementation plan is executed in stage order. Each stage needs
written acceptance tests, automated evidence and actual gameplay on Windows
DISPLAY1. The user's override, extended2026-11-02, permits stages9..29 implementation after
automated PASS while accumulating actual tests for one later session. Stages8..29
remain unaccepted until the live registry passes; stages0..7 retain their evidence.

| Stage | Report | State |
| --- | --- | --- |
| 0: environment and baseline | [2026-11-01-stage-0.md](stages/2026-11-01-stage-0.md) | PASS: 23/23 checks, real expedition complete, repaired HUD retested |
| 1: Dungeon Beta QA | [2026-11-01-stage-1.md](stages/2026-11-01-stage-1.md) | PASS: 26/26 checks and actual expedition, injury return/recovery verified |
| 2: exportable assets | [2026-11-01-stage-2.md](stages/2026-11-01-stage-2.md) | PASS: 27/27 checks, clean export and source/EXE gameplay |
| 3: presentation extraction | [2026-11-01-stage-3.md](stages/2026-11-01-stage-3.md) | PASS: 28/28 checks, actual injury/recovery and combat meters |
| 4: map pipeline | [2026-11-01-stage-4.md](stages/2026-11-01-stage-4.md) | PASS: 29/29, actual edit/save/reload/play/return |
| 5: generation quality | [2026-11-01-stage-5.md](stages/2026-11-01-stage-5.md) | PASS: 30/30, 300 seeds, actual profiles/reroll/exploration |
| 6: world/town | [2026-11-01-stage-6.md](stages/2026-11-01-stage-6.md) | PASS: 33/33, actual purchase/save/restart/retreat/recovery |
| 7: final acceptance | [2026-11-01-stage-7.md](stages/2026-11-01-stage-7.md) | PASS: 34/34, corrected export, ordinary victory, full expedition/settlement, clean log and restart |
| 8: combat frame/panels | [2026-11-01-stage-8.md](stages/2026-11-01-stage-8.md) | AWAITING_INTERACTIVE:35/35, scene checker and export/probe PASS; actual play waits for desktop availability |
| 9: units/resources | [2026-11-01-stage-9.md](stages/2026-11-01-stage-9.md) | AWAITING_INTERACTIVE:36/36 PASS; live L9-01/02 deferred by user |
| 10: combat feedback | [2026-11-01-stage-10.md](stages/2026-11-01-stage-10.md) | AWAITING_INTERACTIVE:37/37 PASS; live L10-01/02 deferred by user |
| 11: encounter authoring | [2026-11-01-stage-11.md](stages/2026-11-01-stage-11.md) | AWAITING_INTERACTIVE:38/38 PASS; live L11-01/02 deferred by user |
| 12: batch readiness/export | [2026-11-01-stage-12.md](stages/2026-11-01-stage-12.md) | AWAITING_INTERACTIVE:38/38, strict checker and extended EXE probe PASS; all11 live cases NOT_RUN |
| 13: world travel | [2026-11-01-stage-13.md](stages/2026-11-01-stage-13.md) | AWAITING_INTERACTIVE:39/39 PASS; L13-01/02 deferred |
| 14: road events/ambush | [2026-11-01-stage-14.md](stages/2026-11-01-stage-14.md) | AWAITING_INTERACTIVE:40/40 PASS; L14-01/02 deferred |
| 15: readable stash | [2026-11-01-stage-15.md](stages/2026-11-01-stage-15.md) | AWAITING_INTERACTIVE:41/41 PASS; L15-01 deferred |
| 16: persistent equipment / batch build | [2026-11-01-stage-16.md](stages/2026-11-01-stage-16.md) | AWAITING_INTERACTIVE:42/42,1997-file checker and extended EXE probe PASS; all18 live cases NOT_RUN |
| 17: Ravenford trade | [2026-11-01-stage-17.md](stages/2026-11-01-stage-17.md) | AWAITING_INTERACTIVE:43/43,2003-file checker and extended EXE trade probe PASS; all20 live cases NOT_RUN |
| 18: party advancement | [2026-11-01-stage-18.md](stages/2026-11-01-stage-18.md) | AWAITING_INTERACTIVE:44/44 PASS; L18-01/02 deferred |
| 19: campaign interface design | [2026-11-01-stage-19.md](stages/2026-11-01-stage-19.md) | AWAITING_INTERACTIVE:45/45,1219 UI checks,2022-file checker and final extended EXE probe PASS;24 live cases NOT_RUN |
| 20: visual inventory / hero editor | [2026-11-02-stage-20.md](stages/2026-11-02-stage-20.md) | AWAITING_INTERACTIVE:46/46 PASS; L20-01/02 deferred |
| 21: visual trading / training | [2026-11-02-stage-21.md](stages/2026-11-02-stage-21.md) | AWAITING_INTERACTIVE:47/47 PASS; L21-01/02 deferred |
| 22: town / region / final UI build | [2026-11-02-stage-22.md](stages/2026-11-02-stage-22.md) | AWAITING_INTERACTIVE:48/48,2223 UI assertions,2032-file checker and corrected EXE probe PASS;30 live cases NOT_RUN |
| 23: skills / libraries / Godot MCP | [2026-11-02-stage-23.md](stages/2026-11-02-stage-23.md) | Automated PASS: installed,75-tool protocol,48 checks and native no-focus pilot |
| 24: art family / inventory | [2026-11-02-stage-24.md](stages/2026-11-02-stage-24.md) | AWAITING_INTERACTIVE:49/49 and42-click three-size native GPU exercise PASS |
| 25: parchment map / campaign family | [2026-11-02-stage-25.md](stages/2026-11-02-stage-25.md) | AWAITING_INTERACTIVE:49/49,2316 layout checks,72 native clicks PASS |
| 26: final release and handoff | [2026-11-02-stage-26.md](stages/2026-11-02-stage-26.md) | AWAITING_INTERACTIVE:49/49, strict2076, final EXE four-size96-click native PASS;38 physical cases NOT_RUN |
| 27: dungeon art/layout | [2026-11-02-stage-27.md](stages/2026-11-02-stage-27.md) | AWAITING_INTERACTIVE:50/50,99 layout checks,21 native clicks PASS |
| 28: battle art/layout | [2026-11-02-stage-28.md](stages/2026-11-02-stage-28.md) | AWAITING_INTERACTIVE:51/51,150 layout/reload checks,39 native clicks PASS |
| 29: integrated release/handoff | [2026-11-02-stage-29.md](stages/2026-11-02-stage-29.md) | AWAITING_INTERACTIVE:51/51, strict2094, final EXE104 clicks/51 captures PASS;46 physical cases NOT_RUN |

Raw runs are saved in ignored `artifacts/qa-runs/`. The stage contract is
`docs/specs/tooling/001_stage_verification.md` and stage-0 acceptance is
`docs/specs/tooling/slices/001_environment_baseline.md`.
