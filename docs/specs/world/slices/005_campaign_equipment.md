# World slice005: persistent equipment

Owner: ../005_campaign_equipment.md; combat equipment053/058.

| ID | Acceptance | Proof |
| --- | --- | --- |
| W16-01 | v1/v2 migration preserves progress, grants only missing starters, no rewrite; invalid v3 rejected | campaign_equipment_tests |
| W16-02 | correct slot/ownership/counts, transfer/unequip, two-handed conflicts, atomic failure, no healing | same suite |
| W16-03 | begin/fight snapshots survive restart; gear locked; managed actions/damage/armor/visuals; sandbox isolation | same suite and combat slice102 |
| W16-04 | actual stash controls save equipment, selection alone has no effect | same suite |
| W16-05 | real UI, ordinary equipped battle/return/restart | live L16-01/02 NOT_RUN |
