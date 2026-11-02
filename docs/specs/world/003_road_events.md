# Road events and tactical ambush

Status: implemented; automated PASS; actual play deferred. Stage14,2026-11-01.

Each committed journey may create one pending event in the same transaction.
Arrival at unresolved Broken Cart creates its authored choice event; otherwise
roll authored road danger using RandomNumberGenerator seeded by
1+posmod(world.seed+journey_count*104729,999999999). Persist seed, journey id,
destination, kind and choice/combat phase. Restart never rerolls/recharges travel.
Pending event blocks travel/new expeditions/services until resolved.

Broken Cart offers data-defined help or salvage with explicit gold/time/reward
changes. Resolve once and record its node; future visits do not regenerate loot.
Ambush offers a5g toll or normal tactical combat. Fight first commits combat
phase, then launches authored roadside_ambush with saved seed, roster/injuries.
Road combat does not pack or refund expedition supplies.

Reuse DungeonRunSession's combat boundary with explicit road mode and region
return scene. Keep authored enemies. The return control says Return to Region.
App resumes saved combat at encounter entry/seed; mid-turn saves unsupported.

Settlement validates result/context/combat id, complete/nonduplicated hero/enemy
summaries, bounded finite HP and outcome consistency. Apply absolute HP through
shared party-injury helper. Fallen heroes recover to1HP for campaign, retaining
other injuries/debuffs. Victory grants only authored event rewards; defeat none.
Do not add losses twice. Clear pending/effects/rewards/outcome in one atomic
transaction. Failed writes retain the retryable battle. Duplicate returns reject.

Source definitions, encounter and schema validate before use. UI only sends
choices and shows saved state. Proof world slice003, road_event_tests.gd, domain/
HP/session regression and full verifier. Live L14-01/02 remain NOT_RUN.
