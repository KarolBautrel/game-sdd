# Slice098: unit and resource readability

Owner: [presentation090](../presentation/090_combat_unit_resource_assets_v1.md).

| ID | Acceptance | Proof |
| --- | --- | --- |
| S9-01 | Active identity and numeric mini-bar values match current unit, including zero and changed active unit. | combat_unit_readability_tests |
| S9-02 | Presentation overrides update bars/numbers/overhead without mutating resolver state. | same suite; existing animation lifecycle tests |
| S9-03 | Hover/active/wounded/team styles differ and clear correctly; death hides live UI. | same suite; existing visual state tests |
| S9-04 | Invalid visual returns existing emergency sprite without changing source unit; repeated lookup deterministic. | same suite; mercenary pipeline tests |
| S9-05 | Actual unit identity/state/resource timing is readable while playing. | live L9-01/02, NOT_RUN |

Automated PASS permits the next background stage under the explicit batch
override. Final acceptance still requires the recorded live scenarios.
