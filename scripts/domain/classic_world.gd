extends RefCounted
## One authoritative classic executor. No scene, network or wall-clock dependency.
const W := preload("res://scripts/domain/world_strategy.gd")
const S := preload("res://scripts/domain/classic_world_state.gd")
const Planner := preload("res://scripts/domain/faction_planner.gd")
const ACTIONS := ["advance","propose_trade","accept_trade","reject_trade","mobilize","declare_war","propose_peace","accept_peace","reject_peace","respond_aid","propose_pact","accept_pact","reject_pact","withdraw_pact","reserve_budget","release_budget","protect_route"]

static func initial(seed_value: int = 2087) -> Dictionary:
	var s := S.initial(seed_value)
	if s.is_empty(): return {}
	_review(s)
	return s if S.valid(s) else {}

static func command(s: Dictionary, actor: String, action: String, payload: Dictionary) -> Dictionary:
	var seq := int(s.sequence)+1
	return {"schema":"sdd.classic-command","version":1,"id":"intent_%08d" % seq,"sequence":seq,"actor_id":actor,"action":action,"payload":payload.duplicate(true)}

static func apply(s: Dictionary, cmd: Dictionary, tick_hook: Callable=Callable(), planner_hook: Callable=Callable()) -> Dictionary:
	if not S.valid(s): return _no(s,"invalid_state")
	if not W._shape(cmd,["schema","version","id","sequence","actor_id","action","payload"]) or cmd.schema!="sdd.classic-command" or not W._count(cmd.version,1,1) or not W._count(cmd.sequence,1) or not cmd.payload is Dictionary: return _no(s,"invalid_command")
	if cmd.sequence<=s.sequence: return _no(s,"command_replayed")
	if cmd.sequence!=s.sequence+1 or cmd.id!="intent_%08d" % int(cmd.sequence): return _no(s,"sequence_mismatch")
	if cmd.action not in ACTIONS: return _no(s,"unsupported_action")
	var next := s.duplicate(true)
	var reason := ""
	if cmd.action=="advance":
		if cmd.actor_id!="world_clock" or not W._shape(cmd.payload,["ticks"]) or not W._count(cmd.payload.ticks,1,672): return _no(s,"invalid_clock")
		_advance(next,int(cmd.payload.ticks),tick_hook,planner_hook)
	else:
		if not W._id(cmd.actor_id) or not s.core.factions.has(cmd.actor_id): return _no(s,"unknown_actor")
		reason=_operate(next,cmd.actor_id,cmd.action,cmd.payload)
	if reason!="": return _no(s,reason)
	next.sequence=int(cmd.sequence)
	next.receipts.append({"id":cmd.id,"sequence":int(cmd.sequence),"actor_id":cmd.actor_id,"action":cmd.action,"tick":int(next.core.tick)})
	while next.receipts.size()>64: next.receipts.pop_front()
	_archive(next)
	if not S.valid(next): return _no(s,"invalid_transition")
	return {"ok":true,"reason":"","state":next}

static func _no(s: Dictionary, reason: String) -> Dictionary:
	return {"ok":false,"reason":reason,"state":s.duplicate(true)}

static func _spend(s: Dictionary, actor: String, costs: Dictionary) -> bool:
	for resource: String in W.STOCKS:
		if W.available(s.core,actor,resource)<costs.get(resource,0): return false
	for resource: String in W.STOCKS:
		var amount: int=int(costs.get(resource,0))
		s.core.factions[actor].stocks[resource]-=amount;s.ledger.consumed[resource]+=amount
	return true

static func _relation(s: Dictionary, actor: String, other: String, trust: int, grievance: int = 0) -> void:
	var r: Dictionary=s.relations[actor][other]
	r.trust=clampi(int(r.trust)+trust,-100,100);r.grievance=clampi(int(r.grievance)+grievance,0,100)

static func _operate(s: Dictionary, actor: String, action: String, p: Dictionary) -> String:
	if action in ["propose_trade","accept_trade","reject_trade"]: return _trade(s,actor,action,p)
	if action in ["mobilize","protect_route"]: return _mobilize(s,actor,action,p)
	if action in ["declare_war","propose_peace","accept_peace","reject_peace","respond_aid"]: return _diplomacy(s,actor,action,p)
	if action in W.ACTIONS:
		if action in ["propose_pact","reserve_budget"]:
			var prefix := "pact" if action=="propose_pact" else "hold"
			if p.get("id")!=S.next_id(s,prefix): return "entity_sequence_mismatch"
		var result := W.apply(s.core,W.command(s.core,actor,action,p))
		if not result.ok: return str(result.reason)
		s.core=result.state
		if action in ["propose_pact","reserve_budget"]: s.entity_seq=int(s.entity_seq)+1
		S.event(s,action,actor,str(p.id),"bilateral_terms" if action.contains("pact") else "budget_hold")
		return ""
	return "unsupported_action"

static func _trade(s: Dictionary, actor: String, action: String, p: Dictionary) -> String:
	if action=="propose_trade":
		if not W._shape(p,["id","seller","buyer","resource","amount","unit_price","source","target"]) or p.id!=S.next_id(s,"trade") or not S.parties_valid(s,p.seller,p.buyer) or actor not in [p.seller,p.buyer] or p.resource not in ["food","ore","timber"] or not W._count(p.amount,1,12) or not W._count(p.unit_price,1,100): return "invalid_trade_terms"
		if not W._id(p.source) or not W._id(p.target) or not s.core.settlements.has(p.source) or not s.core.settlements.has(p.target) or s.core.settlements[p.source].owner_id!=p.seller or s.core.settlements[p.target].owner_id!=p.buyer: return "invalid_trade_towns"
		if S.hostile(s,p.seller,p.buyer) or S.path(s,p.source,p.target,[p.seller,p.buyer]).is_empty(): return "trade_route_closed"
		var pending := 0
		for t: Dictionary in s.trades.values():
			if t.status=="proposed" and t.proposer==actor:
				pending+=1
				if t.seller==p.seller and t.buyer==p.buyer and t.resource==p.resource: return "trade_pending"
		if pending>=2: return "offer_capacity"
		if W.available(s.core,p.seller,p.resource)<p.amount or W.available(s.core,p.buyer,"coin")<p.amount*p.unit_price: return "trade_unfunded"
		var t := p.duplicate(true)
		t.merge({"proposer":actor,"signed_by":[actor],"status":"proposed","created_tick":int(s.core.tick),"expires_tick":int(s.core.tick)+96,"accepted_tick":null,"cargo":0,"escrow":0,"at":p.source,"edge_to":"","remaining":0,"objective":p.target})
		s.trades[p.id]=t;s.entity_seq=int(s.entity_seq)+1
		S.event(s,"trade_offer",actor,p.id,"supply_negotiation",p.resource,int(p.amount))
		return ""
	if not W._shape(p,["id"]) or not W._id(p.id) or not s.trades.has(p.id): return "unknown_trade"
	var t: Dictionary=s.trades[p.id]
	if t.status!="proposed" or s.core.tick>=t.expires_tick: return "trade_not_pending"
	if actor==t.proposer or actor not in [t.seller,t.buyer]: return "not_recipient"
	if action=="reject_trade": t.status="rejected";return ""
	if S.hostile(s,t.seller,t.buyer) or S.path(s,t.source,t.target,[t.seller,t.buyer]).is_empty(): return "trade_route_closed"
	var active := 0
	for other: Dictionary in s.trades.values():
		if other.status in ["transit","waiting"]: active+=1
	if active>=32: return "shipment_capacity"
	if W.available(s.core,t.seller,t.resource)<t.amount or W.available(s.core,t.buyer,"coin")<t.amount*t.unit_price: return "trade_unfunded"
	s.core.factions[t.seller].stocks[t.resource]-=int(t.amount)
	s.core.factions[t.buyer].stocks.coin-=int(t.amount)*int(t.unit_price)
	t.cargo=int(t.amount);t.escrow=int(t.amount)*int(t.unit_price);t.status="transit";t.accepted_tick=int(s.core.tick)
	t.signed_by=[t.seller,t.buyer];t.signed_by.sort();s.metrics.trade_started+=1
	S.event(s,"trade_dispatched",actor,t.id,"cargo_and_escrow_committed",t.resource,int(t.amount))
	return ""

static func _move(s: Dictionary, active: Array) -> void:
	for id: String in S.sorted_ids(s.forces):
		var f: Dictionary=s.forces[id]
		if f.mode=="preparing" and s.core.tick>=f.ready_tick: f.mode="marching"
		if f.mode!="marching": continue
		if _step(s,f,[]):
			f.mode="holding" if f.mission in ["border","attack","escort"] else "idle"
			s.core.parties[id].settlement_id=f.at
		s.core.parties[id].settlement_id=f.at
	for id: String in active:
		var t: Dictionary=s.trades[id]
		if t.status not in ["transit","waiting"]: continue
		if t.edge_to=="" and _intercepted(s,t): continue
		var old_at: String=t.at
		var arrived := _step(s,t,[t.seller,t.buyer])
		if old_at!=t.at and _intercepted(s,t): continue
		if arrived:
			if S.hostile(s,t.seller,t.buyer): t.status="waiting";continue
			s.core.factions[t.buyer].stocks[t.resource]+=int(t.cargo)
			s.core.factions[t.seller].stocks.coin+=int(t.escrow)
			s.metrics.trade_delivered+=1;s.metrics.trade_volume+=int(t.cargo)
			for a: String in [t.seller,t.buyer]:
				var b: String=t.buyer if a==t.seller else t.seller
				_relation(s,a,b,2);s.relations[a][b].deliveries+=1
			S.event(s,"trade_delivered",t.seller,t.id,"actual_arrival",t.resource,int(t.cargo))
			t.cargo=0;t.escrow=0;t.status="delivered"
		else: t.status="waiting" if t.edge_to=="" else "transit"

static func _step(s: Dictionary, moving: Dictionary, civilians: Array) -> bool:
	if moving.edge_to=="":
		if moving.at==moving.objective: return true
		var route := S.path(s,moving.at,moving.objective,civilians)
		if route.size()<2: return false
		moving.edge_to=route[1];moving.remaining=S.edge_ticks(s,moving.at,moving.edge_to)
	moving.remaining=int(moving.remaining)-1
	if moving.remaining==0: moving.at=moving.edge_to;moving.edge_to=""
	return moving.at==moving.objective and moving.edge_to==""

static func _intercepted(s: Dictionary, t: Dictionary) -> bool:
	var threats: Array=[]
	var threat_count := 0
	for id: String in S.sorted_ids(s.forces):
		var f: Dictionary=s.forces[id];var army: Dictionary=s.core.parties[id]
		if f.at!=t.at or f.edge_to!="" or s.core.tick<f.ready_tick or army.headcount<6 or W.available(s.core,army.faction_id,"food")<2: continue
		if army.faction_id==t.seller: continue # Originator does not intercept its own shipment.
		if not S.hostile(s,army.faction_id,t.seller) and not S.hostile(s,army.faction_id,t.buyer): continue
		threats.append(id);threat_count+=int(army.headcount)
	if threats.is_empty(): return false
	var guards := 0
	for id: String in S.sorted_ids(s.forces):
		var f: Dictionary=s.forces[id];var army: Dictionary=s.core.parties[id]
		if id in threats or army.faction_id not in [t.seller,t.buyer] or f.at!=t.at or f.edge_to!="" or f.ready_tick>s.core.tick or W.available(s.core,army.faction_id,"food")<2: continue
		if threats.any(func(enemy): return S.hostile(s,army.faction_id,s.core.parties[enemy].faction_id)): guards+=int(army.headcount)
	if guards>=threat_count: return false
	for id: String in threats:
		var army: Dictionary=s.core.parties[id]
		s.ledger.lost[t.resource]+=int(t.cargo);s.core.factions[t.buyer].stocks.coin+=int(t.escrow)
		if t.seller!=army.faction_id: _relation(s,t.seller,army.faction_id,-10,15)
		else: _relation(s,t.buyer,army.faction_id,-10,15)
		S.event(s,"convoy_lost",army.faction_id,t.id,"hostile_force_at_arrival",t.resource,int(t.cargo))
		t.cargo=0;t.escrow=0;t.remaining=0;t.edge_to="";t.status="lost";s.metrics.trade_lost+=1
		return true
	return false

static func _economy(s: Dictionary) -> void:
	for id: String in S.sorted_ids(s.core.factions):
		var p: Dictionary=s.rules.policies[id];var store: Dictionary=s.core.factions[id].stocks
		var troops := 0
		for party: Dictionary in s.core.parties.values():
			if party.faction_id==id: troops+=int(party.headcount)
		for resource: String in W.STOCKS:
			var produced := maxi(0,mini(int(p.production[resource]),int(s.rules.warehouse_cap)-int(store[resource])))
			store[resource]+=produced;s.ledger.produced[resource]+=produced
			var need := int(p.consumption[resource])
			if resource in ["coin","food"]: need+=ceili(troops/8.0)
			var paid := mini(need,W.available(s.core,id,resource))
			store[resource]-=paid;s.ledger.consumed[resource]+=paid;s.shortfalls[id][resource]=need-paid
	for key: String in S.sorted_ids(s.wars):
		var war: Dictionary=s.wars[key]
		for id: String in war.exhaustion:
			war.exhaustion[id]=clampi(int(war.exhaustion[id])+(2+int(s.shortfalls[id].food) if s.core.diplomacy[key].stance=="war" else -2),0,100)

static func _mobilize(s: Dictionary, actor: String, action: String, p: Dictionary) -> String:
	if not W._shape(p,["party","route"]) or not W._id(p.party) or not W._id(p.route) or not s.core.parties.has(p.party) or not s.core.routes.has(p.route): return "invalid_mobilization"
	var army: Dictionary=s.core.parties[p.party];var f: Dictionary=s.forces[p.party];var edge: Dictionary=s.core.routes[p.route]
	if army.faction_id!=actor or f.mode in ["preparing","marching"] or s.core.tick<f.ready_tick: return "force_not_ready"
	var staging: String=edge.a if s.core.settlements[edge.a].owner_id==actor else edge.b
	if action=="mobilize" and s.core.settlements[staging].owner_id!=actor: return "not_a_border"
	if action=="protect_route" and S.hostile(s,actor,s.core.settlements[staging].owner_id): return "hostile_escort_route"
	var opposite: String=edge.b if staging==edge.a else edge.a
	var attacking := action=="mobilize" and S.hostile(s,actor,s.core.settlements[opposite].owner_id)
	if attacking: staging=opposite
	if S.path(s,f.at,staging).is_empty(): return "unreachable_border"
	if f.mode=="holding" and f.objective==staging and f.mission in ["border","escort","attack"]: return "mobilization_exists"
	var committed := 0
	for other: Dictionary in s.core.parties.values():
		if other.faction_id==actor: committed+=int(other.headcount)
	var recruits := maxi(0,mini(12-int(army.headcount),int(s.core.factions[actor].manpower)-committed))
	if army.headcount+recruits<6: return "insufficient_manpower"
	var cost: Dictionary=s.rules.mobilize_cost.duplicate(true)
	cost.coin+=recruits*2;cost.food+=recruits;cost.ore+=ceili(recruits/2.0)
	if not _spend(s,actor,cost): return "mobilization_unfunded"
	army.headcount+=recruits
	f.mode="preparing";f.ready_tick=int(s.core.tick)+int(s.rules.train_ticks);f.objective=staging;f.mission="escort" if action=="protect_route" else ("attack" if attacking else "border")
	S.event(s,"mobilization",actor,p.party,"prepared_force_on_real_route","coin",int(cost.coin))
	return ""

static func _pact_blocks(s: Dictionary, a: String, b: String) -> bool:
	var pair: Dictionary=s.core.diplomacy[W.pair_key(a,b)]
	return W._active_kind(s.core,pair,"nonaggression") or W._active_kind(s.core,pair,"defensive_pact") or s.wars[W.pair_key(a,b)].truce_until>s.core.tick

static func _war(s: Dictionary, actor: String, target: String, route_id: String, aid: bool = false) -> String:
	if not S.parties_valid(s,actor,target) or not s.core.routes.has(route_id): return "invalid_war_target"
	var key := W.pair_key(actor,target)
	if S.hostile(s,actor,target): return "already_at_war"
	if _pact_blocks(s,actor,target): return "protected_by_pact_or_truce"
	var route: Dictionary=s.core.routes[route_id]
	var owners: Array=[s.core.settlements[route.a].owner_id,s.core.settlements[route.b].owner_id]
	if not aid and (actor not in owners or target not in owners or (s.rules.policies[actor].claim_route!=route_id and s.relations[actor][target].grievance<25)): return "no_reachable_motive"
	var objective: String=route.a if s.core.settlements[route.a].owner_id==target else route.b
	var staging: String=route.b if objective==route.a else route.a
	var selected := ""
	for id: String in S.sorted_ids(s.forces):
		var f: Dictionary=s.forces[id];var party: Dictionary=s.core.parties[id]
		if party.faction_id==actor and party.headcount>=6 and f.edge_to=="" and s.core.tick>=f.ready_tick and f.mode!="preparing" and (aid or (f.at==staging and f.mode=="holding" and f.mission=="border")) and not S.path(s,f.at,objective).is_empty(): selected=id;break
	if selected=="": return "no_ready_border_force"
	if not _spend(s,actor,{"coin":5,"food":4}): return "war_unfunded"
	s.core.diplomacy[key].stance="war"
	# Expired offers are not promises; live negotiations close explicitly on war.
	for offer: Dictionary in s.core.pact_offers.values():
		if offer.status=="pending" and W.pair_key(offer.proposer,offer.recipient)==key: offer.status="withdrawn"
	var war: Dictionary=s.wars[key]
	war.started_tick=int(s.core.tick);war.aggressor=actor;war.route=route_id
	_relation(s,target,actor,-40,30);s.metrics.wars+=1
	s.forces[selected].mode="marching";s.forces[selected].mission="attack";s.forces[selected].objective=objective
	S.event(s,"war_declared",actor,target,"defensive_aid" if aid else "contested_corridor")
	if not aid:
		for ally: String in S.sorted_ids(s.core.factions):
			if ally in [actor,target]: continue
			if W._active_kind(s.core,s.core.diplomacy[W.pair_key(ally,target)],"defensive_pact"):
				var id := S.next_id(s,"aid");s.entity_seq=int(s.entity_seq)+1
				s.aid[id]={"id":id,"ally":ally,"protected":target,"aggressor":actor,"war_pair":key,"war_tick":int(s.core.tick),"status":"pending"}
	return ""

static func _diplomacy(s: Dictionary, actor: String, action: String, p: Dictionary) -> String:
	if action=="declare_war":
		if not W._shape(p,["target","route"]) or not W._id(p.target) or not W._id(p.route): return "invalid_war_target"
		return _war(s,actor,p.target,p.route)
	if action=="respond_aid":
		if not W._shape(p,["id","accept"]) or not W._id(p.id) or not p.accept is bool or not s.aid.has(p.id): return "unknown_aid"
		var a: Dictionary=s.aid[p.id]
		if a.ally!=actor or a.status!="pending": return "aid_not_owned"
		if not S.hostile(s,a.protected,a.aggressor) or s.wars[a.war_pair].started_tick!=a.war_tick: return "aid_war_closed"
		if p.accept:
			if not S.hostile(s,actor,a.aggressor):
				var reason := _war(s,actor,a.aggressor,s.wars[a.war_pair].route,true)
				if reason!="": return reason
			a.status="accepted"
		else: a.status="declined";_relation(s,a.protected,actor,-8,8)
		S.event(s,"aid_response",actor,a.protected,"honored" if p.accept else "unavailable")
		return ""
	if action=="propose_peace":
		if not W._shape(p,["id","target"]) or p.id!=S.next_id(s,"peace") or not S.parties_valid(s,actor,p.target) or not S.hostile(s,actor,p.target): return "invalid_peace_offer"
		var war: Dictionary=s.wars[W.pair_key(actor,p.target)]
		if s.core.tick-war.started_tick<672 and war.exhaustion[actor]<24 and s.shortfalls[actor].food==0: return "no_peace_pressure"
		for offer: Dictionary in s.peace_offers.values():
			if offer.status=="pending" and W.pair_key(offer.proposer,offer.recipient)==W.pair_key(actor,p.target): return "peace_pending"
		s.peace_offers[p.id]={"id":p.id,"proposer":actor,"recipient":p.target,"signed_by":[actor],"status":"pending","created_tick":int(s.core.tick),"expires_tick":int(s.core.tick)+96,"accepted_tick":null}
		s.entity_seq=int(s.entity_seq)+1
		S.event(s,"peace_offer",actor,p.target,"war_costs")
		return ""
	if not W._shape(p,["id"]) or not W._id(p.id) or not s.peace_offers.has(p.id): return "unknown_peace_offer"
	var offer: Dictionary=s.peace_offers[p.id]
	if offer.status!="pending" or s.core.tick>=offer.expires_tick: return "peace_not_pending"
	if offer.recipient!=actor: return "not_recipient"
	if action=="reject_peace": offer.status="rejected";return ""
	if not S.hostile(s,offer.proposer,actor): return "war_already_closed"
	var key := W.pair_key(offer.proposer,actor)
	offer.status="accepted";offer.signed_by=[offer.proposer,actor];offer.signed_by.sort();offer.accepted_tick=int(s.core.tick)
	s.core.diplomacy[key].stance="peace"
	s.wars[key].started_tick=null;s.wars[key].aggressor="";s.wars[key].route="";s.wars[key].truce_until=int(s.core.tick)+int(s.rules.ceasefire_ticks);s.wars[key].peace_id=offer.id
	for id: String in S.sorted_ids(s.forces):
		var party: Dictionary=s.core.parties[id]
		if party.faction_id in offer.signed_by:
			var f: Dictionary=s.forces[id]
			f.objective=s.rules.policies[party.faction_id].home;f.mode="marching";f.mission="return"
	for a: Dictionary in s.aid.values():
		if a.war_pair==key and a.status=="pending": a.status="closed"
	s.metrics.peace+=1;S.event(s,"ceasefire",actor,offer.proposer,"bilateral_fourteen_days")
	return ""

static func _battles(s: Dictionary) -> void:
	var ids := S.sorted_ids(s.forces)
	for i in range(ids.size()):
		for j in range(i+1,ids.size()):
			var a: Dictionary=s.core.parties[ids[i]];var b: Dictionary=s.core.parties[ids[j]]
			var fa: Dictionary=s.forces[ids[i]];var fb: Dictionary=s.forces[ids[j]]
			var same_node: bool=fa.at==fb.at and fa.edge_to=="" and fb.edge_to==""
			var crossing: bool=fa.edge_to==fb.at and fb.edge_to==fa.at and fa.edge_to!="" and fa.remaining+fb.remaining<=S.edge_ticks(s,fa.at,fa.edge_to)
			if not S.hostile(s,a.faction_id,b.faction_id) or not (same_node or crossing) or a.headcount<1 or b.headcount<1 or s.core.tick<fa.ready_tick or s.core.tick<fb.ready_tick: continue
			var strength_a := int(a.headcount)*(100 if W.available(s.core,a.faction_id,"food")>=2 else 60)
			var strength_b := int(b.headcount)*(100 if W.available(s.core,b.faction_id,"food")>=2 else 60)
			if same_node and s.core.settlements[fa.at].owner_id==a.faction_id: strength_a=strength_a*120/100
			if same_node and s.core.settlements[fb.at].owner_id==b.faction_id: strength_b=strength_b*120/100
			strength_a+=S.roll(int(s.core.seed),int(s.core.tick),ids[i]+ids[j],101)
			var losses_a := mini(int(a.headcount),maxi(1,ceili(strength_b/(250.0 if strength_a>=strength_b else 120.0))))
			var losses_b := mini(int(b.headcount),maxi(1,ceili(strength_a/(120.0 if strength_a>=strength_b else 250.0))))
			for loss: Array in [[ids[i],losses_a],[ids[j],losses_b]]:
				var army: Dictionary=s.core.parties[loss[0]]
				army.headcount-=int(loss[1]);s.core.factions[army.faction_id].manpower-=int(loss[1]);s.metrics.casualties+=int(loss[1])
				var exhaustion: Dictionary=s.wars[W.pair_key(a.faction_id,b.faction_id)].exhaustion
				exhaustion[army.faction_id]=mini(100,int(exhaustion[army.faction_id])+int(loss[1])*2)
			var loser_id: String=ids[j] if strength_a>=strength_b else ids[i]
			var loser: Dictionary=s.forces[loser_id];var faction: String=s.core.parties[loser_id].faction_id
			loser.ready_tick=int(s.core.tick)+96;loser.mission="return";loser.objective=s.rules.policies[faction].home
			for town: String in S.sorted_ids(s.core.settlements):
				if town!=loser.at and s.core.settlements[town].owner_id==faction: loser.objective=town;break
			loser.mode="idle" if loser.objective==loser.at and loser.edge_to=="" else "marching"
			s.metrics.battles+=1;S.event(s,"border_clash",a.faction_id,b.faction_id,"supplied_seeded_resolution","",losses_a+losses_b)

static func _advance(s: Dictionary, ticks: int, tick_hook: Callable=Callable(), planner_hook: Callable=Callable()) -> void:
	var active: Array=S.sorted_ids(s.trades).filter(func(id): return s.trades[id].status in ["transit","waiting"])
	for step in range(ticks):
		s.core.tick=int(s.core.tick)+1
		_move(s,active)
		_battles(s)
		if int(s.core.tick)%96==0: _economy(s)
		if int(s.core.tick)%24==0:
			_review(s,planner_hook);_execute_plans(s,planner_hook);_archive(s)
			active=S.sorted_ids(s.trades).filter(func(id): return s.trades[id].status in ["transit","waiting"])
		if tick_hook.is_valid(): tick_hook.call(s)

static func _review(s: Dictionary, planner_hook: Callable=Callable()) -> void:
	var proposals := {}
	var overrides := {}
	if planner_hook.is_valid():
		var observations := {}
		for id: String in S.sorted_ids(s.core.factions): observations[id]=observe(s,id)
		overrides=planner_hook.call("review",observations)
	for id: String in S.sorted_ids(s.core.factions):
		var old: Dictionary=s.plans.get(id,{})
		if overrides.has(id) and S.plan_valid(s,overrides[id]) and (old.is_empty() or s.core.tick>=old.commit_until):
			proposals[id]=overrides[id];continue
		if not old.is_empty() and s.core.tick<old.review_tick:
			var invalidated: bool=old.target!="" and ((old.goal=="claim" and S.hostile(s,id,old.target)) or (old.goal in ["defend","peace"] and not S.hostile(s,id,old.target)))
			if s.core.tick<old.commit_until or not invalidated: continue
		proposals[id]=Planner.choose(observe(s,id))
	for id: String in S.sorted_ids(proposals):
		var old: Dictionary=s.plans.get(id,{})
		var plan: Dictionary=proposals[id]
		s.plans[id]=plan;s.decisions[id].append(plan.duplicate(true));s.metrics.reviews+=1
		if old.is_empty() or old.goal!=plan.goal or old.target!=plan.target or old.resource!=plan.resource: s.metrics.plan_changes+=1
		while s.decisions[id].size()>16: s.decisions[id].pop_front()

static func _execute_plans(s: Dictionary, planner_hook: Callable=Callable()) -> void:
	var ids := S.sorted_ids(s.core.factions)
	var proposals := {}
	for id: String in ids: proposals[id]=Planner.intents(observe(s,id),s.plans[id])
	if planner_hook.is_valid():
		var overrides: Dictionary=planner_hook.call("intents",{})
		for id: String in overrides:
			if proposals.has(id): proposals[id]=overrides[id]
	var outcomes: Array=[]
	var offset := S.roll(int(s.core.seed),int(s.core.tick),"resolution_order",ids.size())
	for i in range(ids.size()):
		var id: String=ids[(i+offset)%ids.size()]
		for intent: Dictionary in proposals[id]:
			var payload: Dictionary=intent.payload.duplicate(true)
			if intent.action in ["propose_trade","propose_peace","propose_pact"]:
				payload.id=S.next_id(s,{"propose_trade":"trade","propose_peace":"peace","propose_pact":"pact"}[intent.action])
			var reason := _operate(s,id,intent.action,payload)
			if reason!="": s.metrics.rejected_intents+=1
			if planner_hook.is_valid(): outcomes.append({"actor":id,"action":intent.action,"reason":reason})
	if planner_hook.is_valid(): planner_hook.call("outcomes",{"tick":int(s.core.tick),"results":outcomes})

static func _archive(s: Dictionary) -> void:
	for t: Dictionary in s.trades.values():
		if t.status=="proposed" and s.core.tick>=t.expires_tick: t.status="expired"
	for p: Dictionary in s.peace_offers.values():
		if p.status=="pending" and s.core.tick>=p.expires_tick: p.status="expired"
	for field: String in ["trades","peace_offers","aid"]:
		for id: String in S.sorted_ids(s[field]):
			var record: Dictionary=s[field][id]
			if field=="trades" and record.status in ["proposed","transit","waiting"]: continue
			if field=="peace_offers" and (record.status=="pending" or s.wars.values().any(func(w): return w.peace_id==id)): continue
			if field=="aid" and record.status=="pending": continue
			var created: int=int(record.get("created_tick",record.get("war_tick",0)))
			if s.core.tick-created>1344: s[field].erase(id)
	var retained := {}
	for receipt: Dictionary in s.core.receipts: retained[receipt.target_id]=true
	for id: String in S.sorted_ids(s.core.pact_offers):
		var p: Dictionary=s.core.pact_offers[id]
		if retained.has(id) or (p.status=="pending" and p.expires_tick>s.core.tick): continue
		if p.status=="accepted" and p.accepted_tick+p.duration_ticks>s.core.tick: continue
		if p.status=="accepted":
			var treaties: Array=s.core.diplomacy[W.pair_key(p.proposer,p.recipient)].treaties
			for i in range(treaties.size()-1,-1,-1):
				if treaties[i].id==id: treaties.remove_at(i)
		s.core.pact_offers.erase(id)
	for id: String in S.sorted_ids(s.core.reservations):
		if s.core.reservations[id].status=="released" and not retained.has(id): s.core.reservations.erase(id)

static func observe(s: Dictionary, actor: String) -> Dictionary:
	if not s.core.factions.has(actor): return {}
	var own: Dictionary=s.core.factions[actor].duplicate(true)
	own["available"]=S.stocks()
	for resource: String in W.STOCKS: own.available[resource]=W.available(s.core,actor,resource)
	own["policy"]=s.rules.policies[actor].duplicate(true);own["shortfalls"]=s.shortfalls[actor].duplicate(true);own["prices"]=s.rules.prices.duplicate(true)
	var result := {"tick":int(s.core.tick),"seed":int(s.core.seed),"actor":actor,"own":own,"previous":s.plans.get(actor,{}).duplicate(true),"forces":[],"relations":[],"markets":[],"incoming_trades":[],"incoming_pacts":[],"incoming_peace":[],"aid":[],"pending_trades":[],"claim":{},"live_trade_resources":[],"own_trade_route":""}
	var total_strength := {}
	for id: String in s.core.factions: total_strength[id]=0
	for id: String in S.sorted_ids(s.core.parties):
		var p: Dictionary=s.core.parties[id];total_strength[p.faction_id]+=int(p.headcount)
		if p.faction_id==actor:
			var f: Dictionary=s.forces[id].duplicate(true);f["id"]=id;f["headcount"]=int(p.headcount);result.forces.append(f)
	for other: String in S.sorted_ids(s.core.factions):
		if other==actor: continue
		var key := W.pair_key(actor,other);var pair: Dictionary=s.core.diplomacy[key];var war: Dictionary=s.wars[key]
		var r: Dictionary=s.relations[actor][other].duplicate(true)
		r.merge({"target":other,"stance":pair.stance,"truce_until":int(war.truce_until),"exhaustion":int(war.exhaustion[actor]),"war_age":0 if war.started_tick==null else int(s.core.tick)-int(war.started_tick),"route":war.route,"strength":total_strength[other],"pacts":[]})
		for treaty: Dictionary in pair.treaties:
			if treaty.end_tick>s.core.tick: r.pacts.append(treaty.kind)
		result.relations.append(r)
		if pair.stance=="war": continue
		for resource: String in ["food","ore","timber"]:
			var offered := mini(12,maxi(0,W.available(s.core,other,resource)-int(s.rules.policies[other].targets[resource])/2))
			if offered==0: continue
			var source: String=s.rules.policies[other].home
			if S.path(s,source,own.policy.home,[actor,other]).is_empty(): continue
			result.markets.append({"seller":other,"source":source,"resource":resource,"amount":offered,"unit_price":int(s.rules.prices[resource])})
	var claim_route: String=own.policy.claim_route
	if claim_route!="":
		var edge: Dictionary=s.core.routes[claim_route]
		var staging: String=edge.a if s.core.settlements[edge.a].owner_id==actor else edge.b
		var objective: String=edge.b if staging==edge.a else edge.a
		var target: String=s.core.settlements[objective].owner_id
		if target!=actor and s.core.settlements[staging].owner_id==actor:
			result.claim={"route":claim_route,"target":target,"staging":staging,"objective":objective}
	for id: String in S.sorted_ids(s.trades):
		var t: Dictionary=s.trades[id]
		if actor not in [t.seller,t.buyer]: continue
		if t.status=="proposed":
			if t.proposer==actor: result.pending_trades.append(t.duplicate(true))
			else: result.incoming_trades.append(t.duplicate(true))
		if t.status in ["transit","waiting"]:
			if t.buyer==actor: result.live_trade_resources.append(t.resource)
			if result.own_trade_route=="":
				for route_id: String in S.sorted_ids(s.core.routes):
					var e: Dictionary=s.core.routes[route_id]
					if t.at in [e.a,e.b]: result.own_trade_route=route_id;break
	for id: String in S.sorted_ids(s.core.pact_offers):
		var p: Dictionary=s.core.pact_offers[id]
		if p.status=="pending" and p.recipient==actor and p.expires_tick>s.core.tick: result.incoming_pacts.append(p.duplicate(true))
	for id: String in S.sorted_ids(s.peace_offers):
		var p: Dictionary=s.peace_offers[id]
		if p.status=="pending" and p.recipient==actor and p.expires_tick>s.core.tick: result.incoming_peace.append(p.duplicate(true))
	for id: String in S.sorted_ids(s.aid):
		var a: Dictionary=s.aid[id]
		if a.status=="pending" and a.ally==actor: result.aid.append(a.duplicate(true))
	result["reports"]=[]
	for e: Dictionary in s.events:
		var own_trade: bool=s.trades.has(e.target) and actor in [s.trades[e.target].seller,s.trades[e.target].buyer]
		if e.actor!=actor and e.target!=actor and not own_trade and e.kind not in ["war_declared","ceasefire","mobilization","border_clash","accept_pact"]: continue
		var report := e.duplicate(true);report["age_ticks"]=int(s.core.tick)-int(e.tick);report["confidence"]=100
		result.reports.append(report)
		while result.reports.size()>16: result.reports.pop_front()
	return result
