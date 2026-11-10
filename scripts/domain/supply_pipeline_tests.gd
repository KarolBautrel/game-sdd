extends SceneTree
const C := preload("res://scripts/domain/classic_world.gd")
const Q := C.Supply
const P := preload("res://scripts/domain/strategist_protocol.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func stock(s: Dictionary, actor: String, resource: String, amount: int) -> void:
	s.ledger.opening[resource]+=amount-int(s.core.factions[actor].stocks[resource]);s.core.factions[actor].stocks[resource]=amount
func submit(s: Dictionary, actor: String, action: String, payload: Dictionary) -> Dictionary:
	var before := P.digest(s);var result := C.apply(s,C.command(s,actor,action,payload))
	check(result.ok and C.S.reconciles(result.state) and P.digest(s)==before,"ordinary immutable/conserved "+action+" / "+result.reason)
	return result.state
func setup() -> Dictionary:
	var s := C.initial(2088)
	for edge: Dictionary in s.core.routes.values(): edge.travel_ticks=192
	for resource: String in ["ore","timber"]: s.rules.policies.cinder_compact.targets[resource]=0
	for actor: String in ["iron_march","thornwood_accord"]: s.relations.cinder_compact[actor].trust=-100
	stock(s,"cinder_compact","food",10)
	return s
func food(o: Dictionary) -> Dictionary:
	for market: Dictionary in o.markets:
		if market.resource=="food" and market.seller=="river_league": return market
	return {}
func buy_payload(s: Dictionary, seller: String, resource: String, amount: int) -> Dictionary:
	return {"id":C.S.next_id(s,"trade"),"seller":seller,"buyer":"cinder_compact","resource":resource,"amount":amount,"unit_price":1,"source":s.rules.policies[seller].home,"target":"ashmere"}
func _initialize() -> void:
	var s := setup();var before := P.digest(s)
	var o := C.observe(s,"cinder_compact");var market := food(o);var quote: Dictionary=market.supply
	check(quote.lead_ticks==384 and quote.net_daily_need==2 and quote.reorder_target==51,"weighted two-edge journey and saved troop upkeep determine exact coverage")
	check(P.digest(s)==before,"observation quote has no stock/ledger side effect")
	var changed := s.duplicate(true);changed.rules.policies.cinder_compact.production.food=0
	check(food(C.observe(changed,"cinder_compact")).supply.net_daily_need==4,"saved production rate drives demand")
	changed.core.parties.compact_watch.headcount=12
	check(food(C.observe(changed,"cinder_compact")).supply.net_daily_need==5,"actual additional troops drive real food upkeep")
	changed.rules.warehouse_cap=100;changed.rules.policies.cinder_compact.consumption.food=1000
	check(food(C.observe(changed,"cinder_compact")).supply.reorder_target==100,"saved warehouse bound limits target")
	changed=s.duplicate(true);changed.rules.policies.cinder_compact.production.food=1000
	check(food(C.observe(changed,"cinder_compact")).supply.reorder_target==42,"production surplus cannot create negative procurement")
	changed=s.duplicate(true)
	for edge: Dictionary in changed.core.routes.values(): edge.travel_ticks=12
	check(food(C.observe(changed,"cinder_compact")).supply.reorder_target<quote.reorder_target,"shorter actual route needs less cover")
	changed=s.duplicate(true);changed.rules.policies.river_league.production.food=0
	check(P.encoded(food(C.observe(changed,"cinder_compact")).supply)==P.encoded(quote),"quote excludes opponent private production policy")
	s=submit(s,"river_league","propose_trade",buy_payload(s,"river_league","food",12))
	var id: String=C.S.sorted_ids(s.trades)[0]
	s=submit(s,"cinder_compact","accept_trade",{"id":id})
	o=C.observe(s,"cinder_compact");market=food(o)
	check(market.supply.inbound==12 and s.core.factions.cinder_compact.stocks.food==10,"signed cargo is future inventory position, not current provisions")
	var intents := C.Planner.intents(o,{"goal":"commerce"})
	check(intents.any(func(i): return i.action=="propose_trade" and i.payload.resource=="food"),"long journey permits overlap with existing signed food shipment")
	check(P.capabilities(o).intents.values().any(func(i): return i.action=="propose_trade" and i.payload.resource=="food"),"bounded model capabilities share overlapping supply orders")
	var legacy := o.duplicate(true)
	for entry: Dictionary in legacy.markets: entry.erase("supply")
	check(not C.Planner.intents(legacy,{"goal":"commerce"}).any(func(i): return i.action=="propose_trade" and i.payload.resource=="food"),"quote-free observation retains conservative single-shipment behavior")
	var covered := o.duplicate(true);food(covered).supply.inbound=100
	check(Q.need(covered,food(covered))==0,"real incoming inventory prevents excess ordering")
	s=submit(s,"cinder_compact","propose_trade",buy_payload(s,"river_league","food",12))
	o=C.observe(s,"cinder_compact")
	check(Q.pending(o,"food")==12 and Q.coins(o)==int(o.own.available.coin)-12,"pending quantity and coin are counted once as soft commitments")
	check(not C.Planner.intents(o,{"goal":"commerce"}).any(func(i): return i.action=="propose_trade" and i.payload.seller=="river_league" and i.payload.resource=="food"),"same supplier/resource pending offer suppresses duplicate")
	check(s.core.factions.cinder_compact.stocks.food==10 and Q.inbound(s,"cinder_compact").food==12,"unsigned offer neither adds cargo nor feeds upkeep")
	var expired := o.duplicate(true);expired.tick=97
	check(Q.pending(expired,"food")==0 and Q.offers(expired)==0,"expired own orders stop reserving the planning budget")
	var denied := s.duplicate(true)
	denied.core.diplomacy[C.W.pair_key("river_league","cinder_compact")].stance="war"
	check(Q.inbound(denied,"cinder_compact").food==0 and denied.trades[id].cargo==12,"hostile shipment stays real but cannot promise an arrival")
	denied=s.duplicate(true)
	denied.core.diplomacy[C.W.pair_key("river_league","iron_march")].stance="war"
	denied.core.diplomacy[C.W.pair_key("river_league","thornwood_accord")].stance="war"
	denied.core.settlements.saltwatch.owner_id="iron_march"
	check(Q.inbound(denied,"cinder_compact").food==0 and denied.trades[id].escrow==12,"closed remaining corridor excludes expected supply without refund/deletion")
	consent_budgets()
	capacity()
	for failure: String in failures: push_error(failure)
	print("supply_pipeline_tests: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func consent_budgets() -> void:
	var s := setup();stock(s,"cinder_compact","coin",20)
	# Two individually affordable incoming offers share the same actual20coins.
	s=submit(s,"river_league","propose_trade",buy_payload(s,"river_league","food",12))
	s=submit(s,"thornwood_accord","propose_trade",buy_payload(s,"thornwood_accord","timber",12))
	s.relations.cinder_compact.thornwood_accord.trust=10;s.rules.policies.cinder_compact.targets.timber=30
	stock(s,"cinder_compact","timber",0)
	var o := C.observe(s,"cinder_compact");var intents := C.Planner.intents(o,{"goal":"hold"})
	check(intents.filter(func(i): return i.action=="accept_trade").size()==1,"classic responses cannot knowingly spend shared20coins twice")
	var caps := P.capabilities(o)
	check(caps.intents.values().filter(func(i): return i.action=="accept_trade").size()==2,"model may choose either independently affordable alternative; executor retains shared budget authority")
	var before := P.digest(s)
	check(P.request_valid(P.request(s,"cinder_compact",1,1)) and P.digest(s)==before,"new bounded request remains within size/privacy contract without mutation")
func capacity() -> void:
	var s := setup()
	for i in range(C.S.SHIPMENT_LIMIT):
		var payload := buy_payload(s,"river_league","food",1);var id: String=payload.id
		s=submit(s,"river_league","propose_trade",payload)
		s=submit(s,"cinder_compact","accept_trade",{"id":id})
	var o := C.observe(s,"cinder_compact")
	check(Q.free_slots(s)==0 and Q.slots(o)==0 and C.S.valid(s),"32 actual signed shipments fill the existing finite capacity")
	check(not C.Planner.intents(o,{"goal":"commerce"}).any(func(i): return i.action in ["propose_trade","accept_trade"]),"fresh classic planning waits for real free capacity")
	var payload := buy_payload(s,"river_league","food",1)
	s=submit(s,"river_league","propose_trade",payload)
	o=C.observe(s,"cinder_compact")
	check(not P.capabilities(o).intents.values().any(func(i): return i.action=="accept_trade"),"new model catalogue omits a presently impossible signature")
	var before := P.digest(s)
	var result := C.apply(s,C.command(s,"cinder_compact","accept_trade",{"id":payload.id}))
	check(not result.ok and result.reason=="shipment_capacity" and P.digest(result.state)==before,"explicit/stale consent cannot bypass capacity or destroy cargo")
