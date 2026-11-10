# Lead-time-aware faction procurement

Stage97b,2026-11-10. Extends world017/019/020/021 without changing the saved
production, consumption, prices, trade size12, consent or32shipment capacity.
Proof: [slice023](slices/023_supply_pipeline.md).

## Orders cover the journey as well as current reserves

New public market quotes and own incoming offers carry an own-buyer `supply`
snapshot: weighted civilian route ticks, current net daily consumption, desired
stock position and actually reachable signed inbound cargo for that resource.
Net daily consumption is saved consumption plus ceil(own troops/8) for food,
minus saved production, floored at zero. Desired stock position is the saved
policy target plus ceil(net daily consumption * (route ticks +24)/96), bounded
by the saved warehouse limit. The24ticks allow one ordinary negotiation boundary.
No quoted stock or future production is added to canonical inventory.

For procurement, inventory position counts available unreserved stock, actual
reachable signed cargo and unexpired own buy offers. Pending offers are soft
ordering commitments only: they cannot fund an army, feed upkeep or authorize
another faction's signature. Their estimated coin commitments reduce the next
proposal budget. Quotes include public free shipment slots; fresh classic
responses share them and wait when none are free. New models may select either
individually affordable response as an alternative, while the executor still
prevents combined overspending/capacity overflow. Seller responses also share
their observed remaining stock instead of selling the same cargo twice.
Exclude cargo whose remaining civilian route is closed or whose
seller/buyer are at war from expected arrivals; retain the actual cargo/escrow
obligation unchanged. There is no replacement refund or teleportation.

A resource already in transit can receive another order while its inventory
position is below the lead-time target. Avoid a duplicate pending buy proposal
to the same seller/resource and obey the existing two-offer proposer limit.
Prefer the shortest lawful quoted lead time; seeded ties remain deterministic.
Select the resource with the greatest remaining procurement deficit. Incoming
buy offers use this same desired stock position and a shared remaining coin /
planned-arrival budget, so several responses cannot knowingly spend the same
observed funds. The executor rechecks actual cargo, coin, routes and capacity.

Quotes reveal only own commitments and already quoted public routes/terms.
They live inside existing generic market/offer observations; no campaign or
request schema migration. Stored requests/hashes/capabilities remain unchanged.
Old quote-free observations retain their conservative single-shipment behavior.
Both classic and newly generated model capabilities use the same planner.

Recorded checkpoint/command replay is deterministic within its simulation-code
revision. A planner change can change other factions' subsequent ordinary
commands, even with unchanged old reply bytes. Retain the previous replay manifest
with its Git revision and update only the current fixture's expected result;
never rewrite player checkpoints, stored requests or the recorded command stream.

## Measured scope and gates

Retain the identical-start12case180day faction-only matrix before/after. Also
run a30day six-case native regional probe with actual company upkeep and job
refresh/expiry, rather than treating frozen opening job holds as full gameplay.
The native probe remains classic and in memory, with no company actions or
restoration; recorded-adapter comparison remains in the matched matrix.
Record shortages, deliveries, rejections and conserved stocks/cargo/manpower.
Do not require every faction/seed to avoid shortage: the occupied mine still
removes real production. No paid/live provider or promotion of the campaign.

Physical readability/travel/consequences remain AWAITING_INTERACTIVE.
