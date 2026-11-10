extends SceneTree
const C := preload("res://scripts/domain/classic_world.gd")
const S := C.S
const Company := preload("res://scripts/session/campaign_session.gd")
var checks := 0
var failures: Array[String]=[]

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)

func submit(s: Dictionary, actor: String, action: String, payload: Dictionary) -> Dictionary:
	var before := s.duplicate(true)
	var result := C.apply(s,C.command(s,actor,action,payload))
	check(result.ok,"accepted "+action+": "+result.reason)
	check(Company.same_data(s,before) and S.valid(result.state),"valid immutable result "+action)
	return result.state

func reject(s: Dictionary, actor: String, action: String, payload: Dictionary, reason: String) -> void:
	var before := s.duplicate(true)
	var result := C.apply(s,C.command(s,actor,action,payload))
	check(not result.ok and result.reason==reason,"rejected "+action+": "+result.reason+" expected "+reason)
	check(Company.same_data(s,before) and Company.same_data(result.state,before),"rejection preserves every fact")

func trade(s: Dictionary) -> Dictionary:
	return {"id":S.next_id(s,"trade"),"seller":"river_league","buyer":"iron_march","resource":"food","amount":5,"unit_price":1,"source":"town_ravenford","target":"black_keep"}

func _initialize() -> void:
	var s := C.initial(2088)
	check(not s.is_empty() and S.valid(s),"valid classic fixture with committed initial plans")
	if s.is_empty(): finish();return
	check(s.plans.size()==4 and s.core.factions.size()==4,"four real initial plans")
	var before := s.duplicate(true)
	var terms := trade(s)
	s=submit(s,"iron_march","propose_trade",terms)
	check(Company.same_data(s.core.factions,before.core.factions),"proposal does not transfer goods/money")
	reject(s,"iron_march","accept_trade",{"id":terms.id},"not_recipient")
	s=submit(s,"river_league","accept_trade",{"id":terms.id})
	check(s.trades[terms.id].cargo==5 and s.trades[terms.id].escrow==5 and s.trades[terms.id].signed_by==["iron_march","river_league"],"dispatch holds real cargo and bilateral escrow")
	check(s.core.factions.iron_march.stocks.food==before.core.factions.iron_march.stocks.food and S.reconciles(s),"no delivery teleport")
	reject(s,"river_league","accept_trade",{"id":terms.id},"trade_not_pending")
	s=submit(s,"world_clock","advance",{"ticks":23})
	check(s.trades[terms.id].status=="transit" and s.trades[terms.id].remaining==1,"weighted24tick edge travels for24ticks")
	s=submit(s,"world_clock","advance",{"ticks":1})
	check(s.trades[terms.id].status=="delivered" and s.trades[terms.id].cargo==0 and s.metrics.trade_delivered==1,"actual arrival settles once")
	check(s.core.factions.iron_march.stocks.food==before.core.factions.iron_march.stocks.food+5 and s.core.factions.river_league.stocks.coin==before.core.factions.river_league.stocks.coin+5,"exact cargo/payment at destination")
	var replay := C.command(s,"world_clock","advance",{"ticks":1});replay.sequence=1;replay.id="intent_00000001"
	check(not C.apply(s,replay).ok,"old outer command cannot replay")
	reject(s,"world_clock","advance",{"ticks":0},"invalid_clock")
	reject(s,"river_league","advance",{"ticks":1},"invalid_clock")
	war_and_batches()
	boundaries()
	diplomatic_guards()
	finish()

func war_and_batches() -> void:
	var s := C.initial(2089)
	reject(s,"iron_march","declare_war",{"target":"river_league","route":"pass_road"},"no_ready_border_force")
	s=submit(s,"iron_march","mobilize",{"party":"iron_patrol","route":"pass_road"})
	check(s.forces.iron_patrol.mode=="preparing" and s.forces.iron_patrol.at=="black_keep","mobilization takes actual time")
	s=submit(s,"world_clock","advance",{"ticks":24})
	check(s.metrics.wars>=1 and S.hostile(s,"iron_march","river_league"),"dispute/readiness produces actual war")
	var seq: int=s.sequence
	for day in range(9): s=submit(s,"world_clock","advance",{"ticks":96})
	check(s.metrics.peace>=1 and s.wars[C.W.pair_key("iron_march","river_league")].truce_until>s.core.tick,"exhaustion supports bilateral ceasefire")
	check(s.metrics.casualties>0 and s.core.factions.iron_march.manpower<60,"world clashes deduct real manpower")
	check(s.sequence==seq+9 and S.reconciles(s),"time receipts and full accounting reconcile")
	var long_tail := C.initial(2088)
	var first := C.command(long_tail,"world_clock","advance",{"ticks":1})
	var accepted_all := true
	for i in range(70):
		var result := C.apply(long_tail,C.command(long_tail,"world_clock","advance",{"ticks":1}))
		accepted_all=accepted_all and result.ok
		if not result.ok: break
		long_tail=result.state
	check(accepted_all and long_tail.receipts.size()==64 and long_tail.sequence==70,"outer receipt tail remains bounded after70successful requests")
	var duplicate := C.apply(long_tail,first)
	check(not duplicate.ok and duplicate.reason=="command_replayed" and Company.same_data(duplicate.state,long_tail),"pruned command stays spent by durable watermark")
	var a := C.initial(2088);var b := a.duplicate(true)
	a=submit(a,"world_clock","advance",{"ticks":192})
	for tick in range(8): b=submit(b,"world_clock","advance",{"ticks":24})
	# Outer request receipts differ; world decisions and all simulated facts do not.
	for field: String in ["sequence","receipts"]: a.erase(field);b.erase(field)
	check(Company.same_data(a,b),"tick batching preserves all simulated facts and decisions")

func boundaries() -> void:
	var s := C.initial(2088)
	var reserve := {"id":S.next_id(s,"hold"),"resource":"coin","amount":95,"purpose":"unavailable budget"}
	s=submit(s,"iron_march","reserve_budget",reserve)
	var terms := trade(s);terms.amount=6
	reject(s,"iron_march","propose_trade",terms,"trade_unfunded")
	s=submit(s,"iron_march","release_budget",{"id":reserve.id})
	terms=trade(s)
	s=submit(s,"iron_march","propose_trade",terms)
	# A second valid reservation may invalidate yesterday's offer; acceptance rechecks.
	s=submit(s,"iron_march","reserve_budget",{"id":S.next_id(s,"hold"),"resource":"coin","amount":100,"purpose":"other goal"})
	reject(s,"river_league","accept_trade",{"id":terms.id},"trade_unfunded")
	var snapshot: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/strategy_snapshots/classic_opening_2088.json"))
	check(S.valid(snapshot) and Company.same_data(snapshot,C.initial(2088)),"portable reference matches runtime initialization")
	for mutate: Callable in [
		func(v): v.version=true,
		func(v): v.sequence=-1,
		func(v): v.entity_seq=0,
		func(v): v.core.factions.river_league.stocks.coin+=1,
		func(v): v.rules.policies.river_league.home="missing",
		func(v): v.forces.league_patrol.edge_to="saltwatch";v.forces.league_patrol.remaining=0,
		func(v): v.relations.iron_march.erase("river_league"),
		func(v): v.plans.iron_march.review_tick+=1,
		func(v): v.events[0].sequence=true,
	]:
		var broken := s.duplicate(true)
		# Events are empty before the first clock advance; entity/receipt guards still apply.
		if broken.events.is_empty(): S.event(broken,"fixture","iron_march","river_league","test")
		mutate.call(broken)
		check(not S.valid(broken),"invalid saved classic state rejects without engine errors")
	# A live shipment may neither be archived nor conjured at its destination.
	s=C.initial(2088);terms=trade(s)
	s=submit(s,"iron_march","propose_trade",terms);s=submit(s,"river_league","accept_trade",{"id":terms.id})
	var forged := s.duplicate(true);forged.trades[terms.id].signed_by=["iron_march"]
	check(not S.valid(forged),"single-sided shipment cannot load")
	forged=s.duplicate(true);forged.trades[terms.id].cargo=0
	check(not S.valid(forged),"cargo/escrow and signed quantity must match")
	# Boundary fixture: war closes all civilian routes from the source, no army there.
	var key := C.W.pair_key("river_league","iron_march")
	s.core.diplomacy[key].stance="war";s.wars[key].started_tick=0;s.wars[key].aggressor="iron_march";s.wars[key].route="pass_road"
	check(S.valid(s),"valid independent blocked-shipment fixture")
	C._move(s,[terms.id])
	check(s.trades[terms.id].status=="waiting" and s.trades[terms.id].at=="town_ravenford" and s.trades[terms.id].cargo==5 and S.reconciles(s),"closed route keeps physical cargo and escrow in place")
	C._archive(s)
	check(s.trades.has(terms.id),"archival never drops a live shipment")
	# Direct restored-peace boundary fixture: resume and settle through ordinary movement.
	s.core.diplomacy[key].stance="peace";s.wars[key].started_tick=null;s.wars[key].aggressor="";s.wars[key].route=""
	for tick in range(24): s.core.tick+=1;C._move(s,[terms.id])
	check(s.trades[terms.id].status=="delivered" and S.reconciles(s),"peace resumes the same waiting shipment once")
	# Actual hostile force at arrival, with no fabricated daily loss roll.
	s=C.initial(2088);terms=trade(s)
	s=submit(s,"iron_march","propose_trade",terms);s=submit(s,"river_league","accept_trade",{"id":terms.id})
	s.core.diplomacy[key].stance="war";s.wars[key].started_tick=0;s.wars[key].aggressor="iron_march";s.wars[key].route="pass_road"
	s.trades[terms.id].edge_to="black_keep";s.trades[terms.id].remaining=1
	var refunded: int=s.core.factions.iron_march.stocks.coin
	# A real stronger, supplied escort stops this same attempted interception.
	var protected := s.duplicate(true)
	protected.core.parties.league_patrol.headcount=12
	protected.forces.league_patrol.at="black_keep";protected.core.parties.league_patrol.settlement_id="black_keep"
	check(S.valid(protected),"valid guard fixture commits existing manpower")
	C._move(protected,[terms.id])
	check(protected.trades[terms.id].status=="waiting" and protected.trades[terms.id].cargo==5 and protected.metrics.trade_lost==0 and S.reconciles(protected),"ready equal-strength guard prevents seizure; war still suspends trade")
	var unavailable := protected.duplicate(true);unavailable.forces.league_patrol.ready_tick=100
	C._move(unavailable,[terms.id])
	check(unavailable.trades[terms.id].status=="lost" and unavailable.metrics.trade_lost==1 and S.reconciles(unavailable),"waiting cargo loses protection when its guard is not ready")
	# The ordinary eight-person guard is too weak for the twelve-person patrol.
	s.forces.league_patrol.at="black_keep";s.core.parties.league_patrol.settlement_id="black_keep"
	C._move(s,[terms.id]);C._move(s,[terms.id])
	check(s.trades[terms.id].status=="lost" and s.ledger.lost.food==5 and s.core.factions.iron_march.stocks.coin==refunded+5 and s.metrics.trade_lost==1 and S.reconciles(s),"real intercept destroys cargo/refunds escrow exactly once")
	# One-settlement ally retreats from a crossing without freezing on the edge.
	s=C.initial(2088);key=C.W.pair_key("iron_march","thornwood_accord")
	s.core.diplomacy[key].stance="war";s.wars[key].started_tick=0;s.wars[key].aggressor="iron_march";s.wars[key].route="woodland_road"
	s.forces.iron_patrol.at="town_ravenford";s.core.parties.iron_patrol.settlement_id="town_ravenford"
	s.forces.iron_patrol.edge_to="thornhaven";s.forces.iron_patrol.remaining=8;s.forces.iron_patrol.mode="marching"
	s.forces.accord_patrol.edge_to="town_ravenford";s.forces.accord_patrol.remaining=8;s.forces.accord_patrol.mode="marching"
	check(S.valid(s),"valid opposite-edge armies fixture")
	C._battles(s)
	check(s.forces.accord_patrol.mode=="marching" and s.forces.accord_patrol.edge_to!="","one-town losing force keeps moving on its actual edge")
	C._move(s,[])
	check(s.forces.accord_patrol.remaining==7 and S.valid(s),"retreat cannot freeze or teleport an edge position")

func diplomatic_guards() -> void:
	var s := C.initial(2089)
	var pact_id := S.next_id(s,"pact")
	s=submit(s,"river_league","propose_pact",{"id":pact_id,"target":"iron_march","kind":"nonaggression","duration_ticks":1344,"valid_for_ticks":96})
	s=submit(s,"iron_march","accept_pact",{"id":pact_id})
	reject(s,"iron_march","declare_war",{"target":"river_league","route":"pass_road"},"protected_by_pact_or_truce")
	s=C.initial(2089);pact_id=S.next_id(s,"pact")
	s=submit(s,"river_league","propose_pact",{"id":pact_id,"target":"thornwood_accord","kind":"defensive_pact","duration_ticks":1344,"valid_for_ticks":96})
	s=submit(s,"thornwood_accord","accept_pact",{"id":pact_id})
	s=submit(s,"iron_march","mobilize",{"party":"iron_patrol","route":"pass_road"})
	s=submit(s,"world_clock","advance",{"ticks":24})
	check(s.aid.size()==1,"only the direct signed ally receives aid request")
	var request_id: String=S.sorted_ids(s.aid)[0]
	reject(s,"cinder_compact","respond_aid",{"id":request_id,"accept":true},"aid_not_owned")
	s=submit(s,"thornwood_accord","respond_aid",{"id":request_id,"accept":true})
	check(S.hostile(s,"thornwood_accord","iron_march") and s.aid[request_id].status=="accepted" and s.aid.size()==1,"lawful aid joins once without recursively summoning allies")
	reject(s,"thornwood_accord","respond_aid",{"id":request_id,"accept":true},"aid_not_owned")
	for day in range(9): s=submit(s,"world_clock","advance",{"ticks":96})
	var key := C.W.pair_key("river_league","iron_march")
	check(s.wars[key].truce_until>s.core.tick,"bilateral ceasefire remains an active fact")
	reject(s,"iron_march","declare_war",{"target":"river_league","route":"pass_road"},"protected_by_pact_or_truce")

func finish() -> void:
	for failure: String in failures: push_error(failure)
	print("classic_world_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
