# Matched strategic diagnostics

Stage97a. Compare classic planning with authored offline examples on identical
terrain-bound starting worlds before choosing a paid/live model. Gameplay rules
remain in world017/019/020/021; proof is world slice022.

`scripts/qa/strategy_comparison.gd` runs the actual classic executor and optional
strategist hook in24tick transactions. Each pair starts from the same copied
world, actual terrain-derived route weights, occupied mine and opening company-job
reservations from a fresh regional campaign. It then isolates faction simulation:
no company travel, job completion or dungeon automation is represented. Identify
this limitation in the report. Do not mutate saved campaigns or generate markers.

Service authored replies between boundaries through adapter dispatch/receive;
never bypass commitment, deadlines, capabilities, daily budgets or operator gates.
This is a deterministic domain experiment, not a wall-time transport/rate-limit
benchmark. Classic and recorded use the same boundary size. Check world validity,
resource reconciliation and adapter validity throughout. Failed transitions do
not publish candidate world/adapter/diagnostic state.

Use seeds2087/2088/2089 (all three opening premises), Large2 and Vast3,180days
per mode by default. Record source revision separately from results and label the
recorded source `authored_offline`, not live AI. Include starting-state digest,
geography checksum, actual route times, end-state digest, production/consumption/
loss ledger, trade/war/peace/churn/rejected-action counters, daily food shortfall
faction-days, real delivered shipment duration, unresolved cargo/escrow and actual
accepted-plan execution/fallback counts. Rejections are measurements, not a rule
to force success. Counts of accepted plans never imply applied world actions.

`scripts/qa/strategy_comparison_run.gd` accepts optional `--days N` (1..720)
and `--label ID` (safe lowercase letters/digits/hyphens). It writes only a new
`artifacts/qa-runs/strategy-comparison-ID/` directory; reject an existing directory.
Store JSON and a concise Markdown table. Network/HTTP/session/desktop transports
are never instantiated. Test copied-checkpoint continuation and deterministic
repeatability; retain pre-change and post-change reports when tuning readiness.

The result supports further tuning and a future matched real-model experiment.
No finite matrix proves fun, full balance or physical acceptance. Preserve every
open live case and the unresolved live provider/model/budget decision.

Stage97b supplements the frozen-job faction experiment with
`scripts/qa/regional_supply_probe.gd -- --label ID`: six native classic regions
(seeds2087/2088/2089, Large/Vast),30days in192tick commands. Actual regional job
refresh/expiry and company upkeep run; the company remains idle at its starting
town, with no restoration, purchases or contract completion. Host-only review
observations measure daily shortages without overriding plans. Reconcile and
validate every candidate. Store only a new owned
`artifacts/qa-runs/regional-supply-ID/` output. No player profile or transport.
