# Party advancement and training

Stage18,2026-11-01. Implemented/automated PASS; AWAITING_INTERACTIVE. User authorized further code,
automation and campaign interfaces. This increment owns progression before UI19.

Campaign v4 adds advancement map for the two roster combat ids, integer levels1..4.
XP remains lifetime earned XP; available XP = earned minus cumulative allocations
to both heroes. Training in Ravenford spends availability by increasing a selected
hero's level one step, never reducing earned XP. Costs for levels2/3/4 are10/20/35;
bonuses are cumulative: level1 none,2 strength+1,3 strength+1/defense+1,
4 strength+2/defense+1/accuracy+5. Reference JSON/schema owns these values.
No HP/max-HP change or healing, no learned skills/respec/recruitment in this slice.

Training requires loaded campaign, Ravenford, no active expedition/pending event,
known hero, below cap and enough unallocated XP. Atomic validate/write/publish;
failure preserves state/file. Levels must fit known ids, bounds and total earned
XP budget. Valid v1/v2/v3 migrate in memory to level1 preserving all prior data;
existing gear/world migrations remain unchanged, no rewrite on load. v4 does not
regrant sold starter gear or reset training. Save filename remains campaign_v1.json.

Expedition begin and road Fight freeze advancement_snapshot alongside gear.
Checkpoints preserve it; load validates equality to current levels. Training is
locked during either activity. Managed launch applies effective roster stats from
the snapshot after base party/equipment setup and before injury modifiers. HP,
resources, gear and combat rules remain unchanged. Sandbox/authoring ignores
campaign levels. Existing road HP validation remains valid (roster max HP fixed).

Training view displays earned/allocated/available XP, each hero's level/current
effective stats, next cumulative bonuses and cost, disabled reason/cap and explicit
Train button. Selection alone cannot train. UI sends hero id; Campaign calculates
costs. Headless controls, budget boundaries, migration/write failure/restart,
snapshot/managed combat and no-healing proofs: party_advancement_tests and
world slice007/combat slice103. Live L18-01/02 NOT_RUN.
