# Slice101: readiness review and batch export

Owner: [overview093](../overview/093_combat_readiness_for_dungeon.md), tooling004.

| ID | Acceptance | Proof |
| --- | --- | --- |
| S12-01 | Map all combat readiness criteria to owner/slice/current checks and actual-play gaps. | stage12 review matrix |
| S12-02 | Full final source verifier and strict scene checker pass with recorded diagnostics. | source JSON/logs and scene-check JSON |
| S12-03 | Fresh exported EXE loads five scenes and data-authored scenario, shows resource UI and executes normal confirmed movement from build directory. | extended export_probe; export_smoke and negative parser tests |
| S12-04 | Final build has recorded hashes/engine/fingerprint and preserved player-save/local-profile boundary. | export report and stage12 report |
| S12-05 | Accumulated windowed DISPLAY1 scenarios, normal expedition/return, restart and clean log pass. | live L8..L12; NOT_RUN |
