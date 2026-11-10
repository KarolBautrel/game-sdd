extends SceneTree
const Bench := preload("res://scripts/qa/strategy_comparison.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func _initialize() -> void:
	var world := Bench.C.initial(2087)
	var classic := Bench.initial(world,"classic");var recorded := Bench.initial(world,"recorded")
	check(classic.stats.initial_digest==recorded.stats.initial_digest,"both modes start from identical world bytes")
	check(Bench.initial(world,"live").is_empty(),"unconfigured live transport cannot be selected")
	var before := Bench.P.digest(recorded)
	var rejected := Bench.step(recorded,1)
	check(not rejected.ok and Bench.P.digest(recorded)==before and Bench.P.digest(rejected.state)==before,"rejected experiment step is immutable")
	var invalid := recorded.duplicate(true);invalid.adapter.rules.provider="unsupported"
	before=Bench.P.digest(invalid);rejected=Bench.step(invalid)
	check(not rejected.ok and Bench.P.digest(invalid)==before and Bench.P.digest(rejected.state)==before,"candidate validation failure rolls back time, adapter and diagnostic sampling together")
	var checkpoint := {};var continued := {}
	for boundary in range(120):
		for mode: String in ["classic","recorded"]:
			var current: Dictionary=classic if mode=="classic" else recorded
			var result := Bench.step(current)
			check(result.ok,"valid and conserved paired boundary%d %s" % [boundary,mode])
			if not result.ok: finish();return
			if mode=="classic": classic=result.state
			else: recorded=result.state
		if boundary==23: checkpoint=JSON.parse_string(Bench.P.encoded(recorded));continued=checkpoint.duplicate(true)
		elif boundary>23:
			var result := Bench.step(continued);check(result.ok,"copied checkpoint advances")
			if not result.ok: finish();return
			continued=result.state
	check(Bench.P.digest(recorded)==Bench.P.digest(continued),"JSON checkpoint plus same boundaries reproduces full experiment exactly")
	check(Bench.P.digest(world)==classic.stats.initial_digest,"opening world remains immutable")
	var a := Bench.report(classic);var b := Bench.report(recorded)
	check(a.steps==120 and b.days==30 and a.reconciled and b.reconciled,"report covers actual full interval/accounting")
	check(a.reply_source=="none" and b.reply_source=="authored_offline" and b.strategist.cost_micros==0,"no invented live-model or provider cost claim")
	check(a.strategist.totals.accepted==0 and b.strategist.totals.accepted>0,"actual recorded adapter is exercised")
	check(a.delivery_duration_ticks.count==a.metrics.trade_delivered and b.delivery_duration_ticks.count==b.metrics.trade_delivered,"every real delivery duration is counted exactly once")
	check(b.strategist.applied_actions+b.strategist.blocked_actions<=b.strategist.totals.accepted*3,"plan and action counters remain distinct")
	var sample: Dictionary=Bench.initial(world,"classic").stats
	Bench._sample(sample,{"core":{"tick":25},"event_seq":1,"events":[{"sequence":1,"kind":"trade_dispatched","target":"trade_test","tick":24}]})
	Bench._sample(sample,{"core":{"tick":49},"event_seq":2,"events":[{"sequence":2,"kind":"trade_delivered","target":"trade_test","tick":49}]})
	check(sample.delivery_ticks==[25] and sample.dispatch_ticks.is_empty(),"delivery measurement survives same-boundary archival of an old shipment")
	finish()
func finish() -> void:
	for failure: String in failures: push_error(failure)
	print("strategy_comparison_tests: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
