# Slice100: data-authored encounter

Owner: [overview092](../overview/092_combat_encounter_authoring_v1.md).

| ID | Acceptance | Proof |
| --- | --- | --- |
| S11-01 | Existing ten scenarios plus clearing_crossfire load from exported catalogue; returned entries isolated. | combat_encounter_authoring_tests |
| S11-02 | Bad catalogue, missing/escaping paths, duplicate/blocked/invalid starts, unknown archetype/item/weapon/turn/background rejected. | test_combat_authoring.py, validate_all |
| S11-03 | Actual controller loads new map/archetypes/loadout without a branch and executes a legal move. | combat_encounter_authoring_tests |
| S11-04 | Referenced map becomes independent inline draft; safe-copy save/reload preserves it. | same suite plus map_authoring/editor suites |
| S11-05 | New encounter fight and full editor/play/return visibly work. | live L11-01/02, NOT_RUN |
