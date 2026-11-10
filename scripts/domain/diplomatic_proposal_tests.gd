extends SceneTree
const C := preload("res://scripts/domain/classic_world.gd")
const P := preload("res://scripts/domain/strategist_protocol.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func submit(s: Dictionary, actor: String, action: String, payload: Dictionary) -> Dictionary:
	var before := P.digest(s);var result := C.apply(s,C.command(s,actor,action,payload))
	check(result.ok and C.S.valid(result.state) and P.digest(s)==before,"ordinary immutable "+action+" / "+result.reason)
	return result.state
func reject(s: Dictionary, actor: String, action: String, payload: Dictionary, reason: String) -> void:
	var before := P.digest(s);var result := C.apply(s,C.command(s,actor,action,payload))
	check(not result.ok and result.reason==reason and P.digest(result.state)==before and P.digest(s)==before,"authoritative rejection "+reason)
func isolated(o: Dictionary) -> Dictionary:
	o.markets=[];o.forces=[];return o
func relation(o: Dictionary, target: String) -> Dictionary:
	for r: Dictionary in o.relations:
		if r.target==target: return r
	return {}
func proposes(o: Dictionary, action: String, kind: String="") -> bool:
	return C.Planner.intents(o,{"goal":"hold"}).any(func(i): return i.action==action and (kind=="" or i.payload.get("kind")==kind))
func pact(s: Dictionary, target: String, kind: String) -> Dictionary:
	return {"id":C.S.next_id(s,"pact"),"target":target,"kind":kind,"duration_ticks":1344,"valid_for_ticks":96}
func age_without_planner_actions(s: Dictionary, ticks: int) -> Dictionary:
	var hook := func(phase: String,_payload: Dictionary) -> Dictionary:
		return {"river_league":[],"iron_march":[],"cinder_compact":[],"thornwood_accord":[]} if phase=="intents" else {}
	var result := C.apply(s,C.command(s,"world_clock","advance",{"ticks":ticks}),Callable(),hook)
	check(result.ok and C.S.reconciles(result.state),"actual clock/movement/upkeep age offers without a scripted AI reply")
	return result.state
func _initialize() -> void:
	pacts();peace();expired_trade();privacy()
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/strategist_requests/cinder_2087.json"))
	check(P.request_valid(old),"old negotiation-free request shape/hash remains valid")
	for failure: String in failures: push_error(failure)
	print("diplomatic_proposal_tests: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func pacts() -> void:
	var s := C.initial(2088)
	for pair: Array in [["cinder_compact","river_league"],["river_league","cinder_compact"]]:
		s.relations[pair[0]][pair[1]].trust=40;s.relations[pair[0]][pair[1]].deliveries=8
	var o := isolated(C.observe(s,"cinder_compact"))
	check(proposes(o,"propose_pact","nonaggression"),"commercial history makes an otherwise legal pact candidate")
	var payload := pact(s,"river_league","nonaggression");var id: String=payload.id
	s=submit(s,"cinder_compact","propose_pact",payload)
	var before := P.digest(s);o=isolated(C.observe(s,"cinder_compact"))
	check("nonaggression" in relation(o,"river_league").pending_pacts and not proposes(o,"propose_pact","nonaggression"),"outgoing live offer suppresses same-kind proposal")
	check(not P.capabilities(o).intents.values().any(func(i): return i.action=="propose_pact" and i.payload.kind=="nonaggression"),"new model catalogue shares pending-offer filter")
	check(P.digest(s)==before,"reading negotiations does not sign, archive or rewrite state")
	o=isolated(C.observe(s,"river_league"))
	var replies := C.Planner.intents(o,{"goal":"hold"})
	check(replies.any(func(i): return i.action=="accept_pact" and i.payload.id==id) and not proposes(o,"propose_pact","nonaggression"),"incoming reply retains original terms without also proposing their duplicate")
	reject(s,"thornwood_accord","accept_pact",{"id":id},"not_recipient")
	s=submit(s,"river_league","accept_pact",{"id":id})
	check(C.W._active_kind(s.core,s.core.diplomacy[C.W.pair_key("cinder_compact","river_league")],"nonaggression") and s.core.pact_offers[id].signed_by.size()==2,"two real signatures create the actual active agreement")
	reject(s,"cinder_compact","propose_pact",pact(s,"river_league","nonaggression"),"pact_exists")
	payload=pact(s,"river_league","defensive_pact");id=payload.id
	s=submit(s,"cinder_compact","propose_pact",payload)
	o=isolated(C.observe(s,"river_league"))
	check(not proposes(o,"propose_pact","defensive_pact") and proposes(o,"accept_pact"),"pending defensive agreement suppresses a duplicate while permitting its reply")
	s=age_without_planner_actions(s,96)
	o=isolated(C.observe(s,"river_league"))
	check(o.incoming_pacts.is_empty() and not ("defensive_pact" in relation(o,"cinder_compact").pending_pacts),"expired agreement is no longer an offered reply or live negotiation")
	check(proposes(o,"propose_pact","defensive_pact"),"fresh eligible proposal is available after the previous offer expires")
	reject(s,"river_league","accept_pact",{"id":id},"offer_expired")
func peace() -> void:
	var s := C.initial(2089)
	s=submit(s,"iron_march","mobilize",{"party":"iron_patrol","route":"pass_road"})
	s=submit(s,"world_clock","advance",{"ticks":24})
	var pair := C.W.pair_key("iron_march","river_league")
	check(C.S.hostile(s,"iron_march","river_league"),"peace test starts from an actual ordinary declared war")
	s.wars[pair].exhaustion.iron_march=24;s.wars[pair].exhaustion.river_league=24
	var payload := {"id":C.S.next_id(s,"peace"),"target":"river_league"};var id: String=payload.id
	s=submit(s,"iron_march","propose_peace",payload)
	var o := isolated(C.observe(s,"iron_march"))
	check(relation(o,"river_league").peace_pending and not proposes(o,"propose_peace"),"own unexpired ceasefire offer prevents another identical negotiation")
	o=isolated(C.observe(s,"river_league"))
	check(proposes(o,"accept_peace") and not proposes(o,"propose_peace"),"incoming peace is answered without a redundant reciprocal offer")
	var waiting := s.duplicate(true)
	s=submit(s,"river_league","accept_peace",{"id":id})
	check(not C.S.hostile(s,"iron_march","river_league") and s.peace_offers[id].signed_by.size()==2 and s.wars[pair].peace_id==id,"only bilateral acceptance creates real peace and retains its receipt")
	waiting=age_without_planner_actions(waiting,96)
	o=isolated(C.observe(waiting,"iron_march"))
	check(not relation(o,"river_league").peace_pending and proposes(o,"propose_peace"),"overdue ceasefire cannot block a fresh pressured proposal")
	check(waiting.peace_offers[id].status=="expired","ordinary archival marks the overdue record expired without a second signature")
	waiting.peace_offers[id].status="pending" # Older clients could retain overdue pending records.
	check(C.S.valid(waiting),"historical overdue-pending save is structurally supported")
	var before := P.digest(waiting)
	check(not relation(C.observe(waiting,"iron_march"),"river_league").peace_pending and P.digest(waiting)==before,"old overdue record is filtered without a load-time mutation")
	reject(waiting,"river_league","accept_peace",{"id":id},"peace_not_pending")
	payload={"id":C.S.next_id(waiting,"peace"),"target":"river_league"}
	waiting=submit(waiting,"iron_march","propose_peace",payload)
	reject(waiting,"iron_march","propose_peace",{"id":C.S.next_id(waiting,"peace"),"target":"river_league"},"peace_pending")
func expired_trade() -> void:
	var s := C.initial(2088)
	var payload := {"id":C.S.next_id(s,"trade"),"seller":"river_league","buyer":"cinder_compact","resource":"food","amount":1,"unit_price":1,"source":"town_ravenford","target":"ashmere"}
	s=submit(s,"river_league","propose_trade",payload)
	s=age_without_planner_actions(s,96)
	var o := C.observe(s,"cinder_compact")
	check(o.incoming_trades.is_empty() and s.trades[payload.id].status=="expired","expired trade produces no fresh classic/model response")
	reject(s,"cinder_compact","accept_trade",{"id":payload.id},"trade_not_pending")
func privacy() -> void:
	var s := C.initial(2088);var before := P.digest(C.observe(s,"cinder_compact"))
	s=submit(s,"iron_march","propose_pact",pact(s,"thornwood_accord","nonaggression"))
	check(P.digest(C.observe(s,"cinder_compact"))==before,"third-party private negotiations are absent from this faction's observation")
	for kind: String in ["nonaggression","defensive_pact"]: s=submit(s,"cinder_compact","propose_pact",pact(s,"river_league",kind))
	var reordered := s.duplicate(true);reordered.core.pact_offers={}
	var ids := C.S.sorted_ids(s.core.pact_offers);ids.reverse()
	for id: String in ids: reordered.core.pact_offers[id]=s.core.pact_offers[id].duplicate(true)
	check(P.digest(C.observe(s,"cinder_compact"))==P.digest(C.observe(reordered,"cinder_compact")),"negotiation observations are independent of offer dictionary insertion order")
