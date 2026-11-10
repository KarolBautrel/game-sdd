extends SceneTree
const C := preload("res://scripts/domain/classic_world.gd")
const P := preload("res://scripts/domain/strategist_protocol.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func stock(s: Dictionary, actor: String, resource: String, amount: int) -> void:
	# Isolated opening fixture, preserving authoritative accounting.
	s.ledger.opening[resource]+=amount-int(s.core.factions[actor].stocks[resource])
	s.core.factions[actor].stocks[resource]=amount
func commerce(s: Dictionary) -> Dictionary:
	var o := C.observe(s,"cinder_compact")
	o.own_trade_route="market_road";o.live_trade_resources=["food","ore","timber"]
	return o
func has_action(intents: Array, action: String) -> bool:
	return intents.any(func(i): return i.action==action)
func _initialize() -> void:
	var s := C.initial(2088);var actor := "cinder_compact";var party := "compact_watch"
	stock(s,actor,"coin",30);stock(s,actor,"food",9);stock(s,actor,"ore",5)
	var before := P.digest(s);var quote := C.mobilization_quote(s,actor,party)
	check(quote.recruits==6 and P.encoded(quote.cost)==P.encoded({"coin":20,"food":10,"ore":5,"timber":0}),"full base plus actual recruit cost")
	check(quote.staffed and not quote.funded and P.digest(s)==before,"food deficit blocks quote without spending")
	var observation := commerce(s)
	check(not has_action(C.Planner.intents(observation,{"goal":"commerce"}),"protect_route"),"30coins do not imply food/ore-funded escort")
	check(not P.capabilities(observation).intents.values().any(func(i): return i.action=="protect_route"),"new model capabilities inherit the same funding gate")
	observation.forces[0].erase("mobilization")
	check(not has_action(C.Planner.intents(observation,{"goal":"commerce"}),"protect_route"),"old quote-free observations do not gain preparation capabilities")
	for resource: String in C.W.STOCKS: stock(s,actor,resource,int(quote.cost[resource]))
	check(C.S.valid(s),"exact-cost isolated opening remains legal and conserved")
	check(has_action(C.Planner.intents(commerce(s),{"goal":"commerce"}),"protect_route"),"exact full quote qualifies even below obsolete30coin threshold")
	before=P.digest(s)
	var applied := C.apply(s,C.command(s,actor,"protect_route",{"party":party,"route":"market_road"}))
	check(applied.ok and P.digest(s)==before,"ordinary operator accepts affordable escort immutably")
	if applied.ok:
		check(applied.state.core.parties[party].headcount==12 and applied.state.forces[party].mode=="preparing","only actual recruits join, preparation still takes time")
		for resource: String in C.W.STOCKS:
			check(applied.state.core.factions[actor].stocks[resource]==0 and applied.state.ledger.consumed[resource]-s.ledger.consumed[resource]==quote.cost[resource],"operator spends exactly quoted "+resource)
		check(C.S.reconciles(applied.state),"preparation accounting remains exact")
	var held := C.apply(s,C.command(s,actor,"reserve_budget",{"id":C.S.next_id(s,"hold"),"resource":"food","amount":1,"purpose":"Existing obligation"}))
	check(held.ok,"reserve one actual food unit after quoting")
	if held.ok:
		before=P.digest(held.state)
		var denied := C.apply(held.state,C.command(held.state,actor,"protect_route",{"party":party,"route":"market_road"}))
		check(not denied.ok and denied.reason=="mobilization_unfunded" and P.digest(denied.state)==before,"intervening reservation rejects stale affordable proposal atomically")
		check(not C.mobilization_quote(held.state,actor,party).funded,"fresh quote respects foundation reservations")
	s.rules.mobilize_cost={"coin":17,"food":9,"ore":7,"timber":2}
	quote=C.mobilization_quote(s,actor,party)
	check(quote.cost=={"coin":29,"food":15,"ore":10,"timber":2},"saved configured base price drives the shared quote")
	for resource: String in C.W.STOCKS: stock(s,actor,resource,int(quote.cost[resource]))
	check(C.apply(s,C.command(s,actor,"protect_route",{"party":party,"route":"market_road"})).ok,"operator shares changed saved price")
	var claim := C.initial(2089)
	stock(claim,"iron_march","ore",0)
	var o := C.observe(claim,"iron_march")
	var intents := C.Planner.intents(o,claim.plans.iron_march)
	check(not has_action(intents,"mobilize") and has_action(intents,"propose_trade"),"unfunded claim continues ordinary procurement instead of repeated mobilization")
	claim.forces.iron_patrol.mode="holding";claim.forces.iron_patrol.mission="border"
	o=C.observe(claim,"iron_march");intents=C.Planner.intents(o,claim.plans.iron_march)
	check(not o.forces[0].mobilization.funded and has_action(intents,"declare_war"),"prepared border force does not need a second preparation price")
	check(C.apply(claim,C.command(claim,"iron_march","declare_war",{"target":"river_league","route":"pass_road"})).ok,"declaration retains its own actual legal/resource gate")
	var path := "res://resources/data/strategist_requests/cinder_2087.json"
	var bytes := FileAccess.get_file_as_string(path);var legacy: Dictionary=JSON.parse_string(bytes)
	check(P.request_valid(legacy) and not legacy.observation.forces[0].has("mobilization"),"old persisted request/hash remains structurally valid")
	check(FileAccess.get_file_as_string(path)==bytes,"loading legacy request never rewrites its bytes")
	var understaffed := s.duplicate(true)
	understaffed.core.factions[actor].manpower=3;understaffed.core.parties[party].headcount=3
	check(not C.mobilization_quote(understaffed,actor,party).staffed,"free manpower cannot invent minimum six troops")
	check(C.mobilization_quote(s,"iron_march",party).is_empty(),"foreign party has no own preparation quote")
	for failure: String in failures: push_error(failure)
	print("faction_readiness_tests: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
