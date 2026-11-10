# Slice023: real orders on long routes

Owner [world022](../022_supply_pipeline.md).

1. A deficit faction has one signed food shipment, but a long weighted route
   consumes more food than it carries. Its next legal order can overlap that
   shipment. Goods and escrow move only after both ordinary signatures.
2. Lead-time target matches the saved rates/current troops and actual weighted
   civilian path, not map distance. Short routes need less cover than long ones;
   higher saved consumption and actual troops increase cover. Production surplus
   never generates negative need. Saved warehouse limit bounds the target.
3. Real reachable cargo and pending buy quantities prevent excess orders. Expired
   offers and blocked expected arrivals do not count as available supplies.
   Same seller/resource pending offers and the global two-offer limit suppress
   redundant proposals; coin planning cannot knowingly overspend pending offers.
4. Incoming consent responses share the observed remaining budget and expected
   arrivals. Lower current stock alone cannot authorize unlimited incoming food.
   Explicit stale/competing commands still pass the authoritative resource gate.
5. Old stored requests remain loadable with their existing hashes. No quote
   mutates stocks/ledger/geometry. Both classic/model capabilities inherit the
   same proposed order. Preserve old player saves and accepted artwork.
6. Run matching180day classic/authored-offline Large/Vast matrices and30day
   native regional job-refresh probes from identical openings before/after.
   Reconcile every accepted boundary, preserve all live gates, and report any
   worsened case instead of asserting universal balance.

Named proofs: `supply_pipeline_tests.gd`, existing planner/adapter/session/native
regressions, `strategy_comparison_run.gd`, `regional_supply_probe.gd`.
L97b-01 remains AWAITING_INTERACTIVE.
