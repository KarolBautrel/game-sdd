# Slice001: reusable HUD

Owner: `../001_reusable_hud_components.md`.

| ID | Scenario | Expected |
| --- | --- | --- |
| U3-01 | Configure two party card instances, injure/recover one | Correct names, portraits, HP and bars; other instance unchanged |
| U3-02 | Zero HP and repeated set_hp | Zero displayed; no model mutation or additional child nodes |
| U3-03 | Configure two combat meters, set zero/full/overflow | Existing visual clamp behavior; independent values |
| U3-04 | Build skins at different sizes/margins | Cache does not alias distinct variants or screens |
| U3-05 | Existing domain/session/HUD suites | Same outcomes and readable bounded UI |
| U3-06 | Real preparation/event/combat interaction | Cards, resource bars and normal move/attack feedback remain visible |

Proof: `scripts/presentation/hud_component_tests.gd`, existing suites and stage3 report.
