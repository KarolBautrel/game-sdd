extends RefCounted
## Saved classic extension; core remains the single stock/party/diplomacy owner.
const W := preload("res://scripts/domain/world_strategy.gd")
const RULES := "res://resources/data/strategy_simulations/classic_rules_v1.json"
const ROOT := ["schema","version","core","rules","premise","initial_manpower","sequence","entity_seq","event_seq","receipts","relations","wars","forces","trades","peace_offers","aid","plans","decisions","shortfalls","ledger","events","metrics"]
const METRICS := ["trade_started","trade_delivered","trade_lost","trade_volume","wars","peace","battles","casualties","reviews","plan_changes","rejected_intents"]
const SHIPMENT_LIMIT := 32

static func sorted_ids(registry: Dictionary) -> Array:
	var ids := registry.keys(); ids.sort(); return ids

static func roll(seed_value: int, tick: int, key: String, bound: int) -> int:
	var h := seed_value % 2147483647
	for byte in (key+":"+str(tick)).to_utf8_buffer(): h=(h*48271+byte)%2147483647
	return h % bound

static func stocks(amount: int = 0) -> Dictionary:
	return {"coin":amount,"food":amount,"ore":amount,"timber":amount}

static func counts(value: Variant, high: int = 1000000000) -> bool:
	if not W._shape(value,W.STOCKS): return false
	for n: Variant in value.values():
		if not W._count(n,0,high): return false
	return true

static func rules_valid(r: Variant, core: Dictionary) -> bool:
	if not W._shape(r,["schema","version","warehouse_cap","prices","train_ticks","ceasefire_ticks","mobilize_cost","policies","premises"]): return false
	if r.schema != "sdd.classic-rules" or not W._count(r.version,1,1) or not W._count(r.warehouse_cap,100,100000) or not W._count(r.train_ticks,1,96) or not W._count(r.ceasefire_ticks,96,2880): return false
	if not W._shape(r.prices,["food","ore","timber"]) or not counts(r.mobilize_cost,1000) or not r.policies is Dictionary or r.policies.size()!=core.factions.size(): return false
	for price: Variant in r.prices.values():
		if not W._count(price,1,100): return false
	for id: String in core.factions:
		var p: Variant=r.policies.get(id)
		if not W._shape(p,["home","claim_route","production","consumption","targets","personality"]): return false
		if not W._id(p.home) or not core.settlements.has(p.home) or core.settlements[p.home].owner_id!=id or not p.claim_route is String: return false
		if p.claim_route!="" and not core.routes.has(p.claim_route): return false
		for field: String in ["production","consumption","targets"]:
			if not counts(p[field],1000): return false
		if not W._shape(p.personality,["trade","security","aggression"]): return false
		for n: Variant in p.personality.values():
			if not W._count(n,0,100): return false
	if not r.premises is Array or r.premises.is_empty() or r.premises.size()>16: return false
	var seen := {}
	for p: Variant in r.premises:
		if not W._shape(p,["id","stocks","dispute"]) or not W._id(p.id) or seen.has(p.id) or not p.dispute is bool or not p.stocks is Dictionary: return false
		seen[p.id]=true
		for id: Variant in p.stocks:
			if not core.factions.has(id) or not p.stocks[id] is Dictionary: return false
			for resource: Variant in p.stocks[id]:
				if resource not in W.STOCKS or not W._count(p.stocks[id][resource],0,1000): return false
	return true

static func initial(seed_value: int) -> Dictionary:
	var core := W.initial(seed_value)
	if core.is_empty(): return {}
	var rules: Variant=JSON.parse_string(FileAccess.get_file_as_string(RULES))
	if not rules_valid(rules,core): return {}
	var premise: Dictionary=rules.premises[seed_value % rules.premises.size()]
	for id: String in premise.stocks:
		for resource: String in premise.stocks[id]: core.factions[id].stocks[resource]=int(premise.stocks[id][resource])
	var s := {"schema":"sdd.classic-world","version":1,"core":core,"rules":rules,"premise":premise.id,"sequence":0,"entity_seq":0,"event_seq":0,"receipts":[],"relations":{},"wars":{},"forces":{},"trades":{},"peace_offers":{},"aid":{},"plans":{},"decisions":{},"shortfalls":{},"ledger":{"opening":stocks(),"produced":stocks(),"consumed":stocks(),"lost":stocks()},"events":[],"metrics":{}}
	for key: String in METRICS: s.metrics[key]=0
	s["initial_manpower"]=0
	for id: String in core.factions:
		s.initial_manpower+=int(core.factions[id].manpower)
		s.relations[id]={};s.decisions[id]=[];s.shortfalls[id]=stocks()
		for other: String in core.factions:
			if other!=id: s.relations[id][other]={"trust":10,"grievance":0,"deliveries":0}
		for resource: String in W.STOCKS: s.ledger.opening[resource]+=int(core.factions[id].stocks[resource])
	if premise.dispute:
		s.relations.iron_march.river_league.trust=-45;s.relations.river_league.iron_march.trust=-45
		s.relations.iron_march.river_league.grievance=35
	for key: String in core.diplomacy:
		var pair: Dictionary=core.diplomacy[key]
		s.wars[key]={"started_tick":null,"aggressor":"","route":"","exhaustion":{pair.a:0,pair.b:0},"truce_until":0,"peace_id":""}
	for id: String in core.parties:
		var party: Dictionary=core.parties[id]
		s.forces[id]={"at":party.settlement_id,"edge_to":"","remaining":0,"objective":party.settlement_id,"mode":"idle","mission":"guard","ready_tick":0}
	return s

static func next_id(s: Dictionary, prefix: String) -> String:
	return "%s_%08d" % [prefix,int(s.entity_seq)+1]

static func event(s: Dictionary, kind: String, actor: String, target: String, reason: String, resource: String = "", amount: int = 0) -> void:
	s.event_seq=int(s.event_seq)+1
	s.events.append({"id":"event_%010d" % int(s.event_seq),"sequence":int(s.event_seq),"tick":int(s.core.tick),"kind":kind,"actor":actor,"target":target,"reason":reason,"resource":resource,"amount":amount})
	while s.events.size()>128: s.events.pop_front()

static func totals(s: Dictionary) -> Dictionary:
	var total := stocks()
	for faction: Dictionary in s.core.factions.values():
		for resource: String in W.STOCKS: total[resource]+=int(faction.stocks[resource])
	for trade: Dictionary in s.trades.values():
		total[trade.resource]+=int(trade.cargo);total.coin+=int(trade.escrow)
	return total

static func reconciles(s: Dictionary) -> bool:
	var total := totals(s)
	for resource: String in W.STOCKS:
		if total[resource]!=s.ledger.opening[resource]+s.ledger.produced[resource]-s.ledger.consumed[resource]-s.ledger.lost[resource]: return false
	return true

static func edge_ticks(s: Dictionary, a: String, b: String) -> int:
	for edge: Dictionary in s.core.routes.values():
		if (edge.a==a and edge.b==b) or (edge.a==b and edge.b==a): return int(edge.travel_ticks)
	return 0

static func hostile(s: Dictionary, a: String, b: String) -> bool:
	return a!=b and s.core.diplomacy[W.pair_key(a,b)].stance=="war"

static func path(s: Dictionary, start: String, goal: String, civilians: Array = []) -> Array:
	if not s.core.settlements.has(start) or not s.core.settlements.has(goal): return []
	var distance := {start:0};var parent := {};var open: Array=[start]
	while not open.is_empty():
		open.sort_custom(func(a,b): return distance[a]<distance[b] if distance[a]!=distance[b] else a<b)
		var at: String=open.pop_front()
		if at==goal:
			var result: Array=[goal]
			while at!=start: at=parent[at];result.push_front(at)
			return result
		for id: String in sorted_ids(s.core.routes):
			var edge: Dictionary=s.core.routes[id]
			var other: String=edge.b if edge.a==at else (edge.a if edge.b==at else "")
			if other=="": continue
			var blocked := false
			for faction: String in civilians:
				if hostile(s,faction,s.core.settlements[other].owner_id): blocked=true
			if blocked: continue
			var cost: int=int(distance[at])+int(edge.travel_ticks)
			if not distance.has(other) or cost<distance[other]:
				distance[other]=cost;parent[other]=at
				if other not in open: open.append(other)
	return []

static func valid(s: Variant) -> bool:
	if not W._shape(s,ROOT) or s.schema!="sdd.classic-world" or not W._count(s.version,1,1) or not W.valid(s.core) or not rules_valid(s.rules,s.core): return false
	for n: String in ["sequence","entity_seq","event_seq"]:
		if not W._count(s[n]): return false
	var premise_found := false
	for premise: Dictionary in s.rules.premises:
		if premise.id==s.premise: premise_found=true
	if not premise_found: return false
	for field: String in ["relations","shortfalls","decisions"]:
		if not s[field] is Dictionary or sorted_ids(s[field])!=sorted_ids(s.core.factions): return false
	if not s.wars is Dictionary or sorted_ids(s.wars)!=sorted_ids(s.core.diplomacy): return false
	if not s.forces is Dictionary or sorted_ids(s.forces)!=sorted_ids(s.core.parties): return false
	for field: String in ["trades","peace_offers","aid","plans"]:
		if not W._registry(s[field],0,512): return false
	var entity_numbers := {}
	for entry: Array in [[s.trades,"trade"],[s.peace_offers,"peace"],[s.aid,"aid"],[s.core.pact_offers,"pact"],[s.core.reservations,"hold"]]:
		for id: String in entry[0]:
			var parts := id.split("_")
			if parts.size()!=2 or parts[0]!=entry[1] or not parts[1].is_valid_int(): return false
			var n := int(parts[1])
			if n<1 or n>s.entity_seq or id!="%s_%08d" % [entry[1],n] or entity_numbers.has(n): return false
			entity_numbers[n]=true
	for id: String in s.core.factions:
		if not counts(s.shortfalls[id]) or not s.decisions[id] is Array or s.decisions[id].size()>16 or not s.relations[id] is Dictionary or s.relations[id].size()!=s.core.factions.size()-1: return false
		for other: String in s.core.factions:
			if other==id: continue
			var relation: Variant=s.relations[id].get(other)
			if not W._shape(relation,["trust","grievance","deliveries"]) or not W._count(relation.trust,-100,100) or not W._count(relation.grievance,0,100) or not W._count(relation.deliveries): return false
	for id: String in s.forces:
		var f: Variant=s.forces[id]
		if not W._shape(f,["at","edge_to","remaining","objective","mode","mission","ready_tick"]) or not journey_valid(s,f) or not W._count(f.ready_tick): return false
		if f.mode not in ["idle","preparing","marching","holding"] or f.mission not in ["guard","border","attack","return","escort"] or s.core.parties[id].settlement_id!=f.at: return false
	for key: String in s.wars:
		var war: Variant=s.wars[key];var pair: Dictionary=s.core.diplomacy[key]
		if not W._shape(war,["started_tick","aggressor","route","exhaustion","truce_until","peace_id"]) or not W._count(war.truce_until) or not W._shape(war.exhaustion,[pair.a,pair.b]): return false
		for n: Variant in war.exhaustion.values():
			if not W._count(n,0,100): return false
		if pair.stance=="war":
			if not W._count(war.started_tick) or war.started_tick>s.core.tick or war.aggressor not in [pair.a,pair.b] or not s.core.routes.has(war.route) or war.truce_until>s.core.tick: return false
		elif war.started_tick!=null or war.aggressor!="" or war.route!="": return false
		if not war.peace_id is String: return false
		if war.peace_id!="":
			var p: Variant=s.peace_offers.get(war.peace_id)
			if not p is Dictionary or p.get("status")!="accepted" or not W._id(p.get("proposer")) or not W._id(p.get("recipient")) or not W._count(p.get("accepted_tick")) or W.pair_key(p.proposer,p.recipient)!=key or p.accepted_tick+s.rules.ceasefire_ticks!=war.truce_until: return false
	var active := 0
	for id: String in s.trades:
		var t: Variant=s.trades[id]
		if not W._shape(t,["id","seller","buyer","resource","amount","unit_price","source","target","proposer","signed_by","status","created_tick","expires_tick","accepted_tick","cargo","escrow","at","edge_to","remaining","objective"]): return false
		if t.id!=id or not parties_valid(s,t.seller,t.buyer) or t.proposer not in [t.seller,t.buyer] or t.resource not in ["food","ore","timber"]: return false
		if not W._count(t.amount,1,12) or not W._count(t.unit_price,1,100) or not window_valid(s,t) or not journey_valid(s,t): return false
		if not s.core.settlements.has(t.source) or not s.core.settlements.has(t.target) or s.core.settlements[t.source].owner_id!=t.seller or s.core.settlements[t.target].owner_id!=t.buyer or t.objective!=t.target: return false
		if t.status not in ["proposed","transit","waiting","delivered","lost","rejected","expired"] or not W._count(t.cargo) or not W._count(t.escrow): return false
		if t.status in ["transit","waiting","delivered","lost"]:
			var signers: Array=[t.seller,t.buyer];signers.sort()
			if t.signed_by!=signers or not W._count(t.accepted_tick) or t.accepted_tick<t.created_tick or t.accepted_tick>=t.expires_tick or t.accepted_tick>s.core.tick: return false
		else:
			if t.signed_by!=[t.proposer] or t.accepted_tick!=null: return false
		if t.status in ["transit","waiting"]:
			active+=1
			if t.cargo!=t.amount or t.escrow!=t.amount*t.unit_price: return false
		elif t.cargo!=0 or t.escrow!=0 or t.remaining!=0 or t.edge_to!="": return false
	if active>SHIPMENT_LIMIT: return false
	for id: String in s.peace_offers:
		var p: Variant=s.peace_offers[id]
		if not W._shape(p,["id","proposer","recipient","signed_by","status","created_tick","expires_tick","accepted_tick"]) or p.id!=id or not parties_valid(s,p.proposer,p.recipient) or not window_valid(s,p): return false
		if p.status not in ["pending","accepted","rejected","expired"]: return false
		var endpoints: Array=[p.proposer,p.recipient];endpoints.sort()
		if p.status=="accepted":
			if p.signed_by!=endpoints or not W._count(p.accepted_tick) or p.accepted_tick<p.created_tick or p.accepted_tick>=p.expires_tick or p.accepted_tick>s.core.tick: return false
		elif p.signed_by!=[p.proposer] or p.accepted_tick!=null: return false
	for id: String in s.aid:
		var a: Variant=s.aid[id]
		if not W._shape(a,["id","ally","protected","aggressor","war_pair","war_tick","status"]) or a.id!=id or not parties_valid(s,a.protected,a.aggressor) or not W._id(a.ally) or not s.core.factions.has(a.ally) or a.ally in [a.protected,a.aggressor] or not W._count(a.war_tick) or a.war_tick>s.core.tick or a.war_pair!=W.pair_key(a.protected,a.aggressor) or a.status not in ["pending","accepted","declined","closed"]: return false
	for id: String in s.plans:
		if not s.core.factions.has(id) or not plan_valid(s,s.plans[id]): return false
	for decisions: Array in s.decisions.values():
		for plan: Variant in decisions:
			if not plan_valid(s,plan): return false
	if not W._shape(s.ledger,["opening","produced","consumed","lost"]) or not W._shape(s.metrics,METRICS): return false
	for values: Variant in s.ledger.values():
		if not counts(values,1000000000000): return false
	for n: Variant in s.metrics.values():
		if not W._count(n): return false
	var remaining_manpower := 0
	for f: Dictionary in s.core.factions.values(): remaining_manpower+=int(f.manpower)
	if not W._count(s.initial_manpower,0,1000000000000) or remaining_manpower+s.metrics.casualties!=s.initial_manpower: return false
	if not s.events is Array or s.events.size()!=mini(int(s.event_seq),128) or not s.receipts is Array or s.receipts.size()!=mini(int(s.sequence),64): return false
	var expected: int=int(s.event_seq)-s.events.size()+1
	for e: Variant in s.events:
		if not W._shape(e,["id","sequence","tick","kind","actor","target","reason","resource","amount"]) or not W._count(e.sequence,1) or e.sequence!=expected or e.id!="event_%010d" % expected or not W._count(e.tick) or e.tick>s.core.tick or not W._text(e.kind) or not W._text(e.actor) or not W._text(e.target) or not W._text(e.reason) or e.resource not in ["","coin","food","ore","timber"] or not W._count(e.amount): return false
		expected+=1
	expected=int(s.sequence)-s.receipts.size()+1
	for r: Variant in s.receipts:
		if not W._shape(r,["id","sequence","actor_id","action","tick"]) or not W._count(r.sequence,1) or r.sequence!=expected or r.id!="intent_%08d" % expected or not W._count(r.tick) or r.tick>s.core.tick or not W._text(r.action) or (r.actor_id!="world_clock" and not s.core.factions.has(r.actor_id)): return false
		expected+=1
	return reconciles(s)

static func parties_valid(s: Dictionary, a: Variant, b: Variant) -> bool:
	return W._id(a) and W._id(b) and a!=b and s.core.factions.has(a) and s.core.factions.has(b)

static func window_valid(s: Dictionary, p: Dictionary) -> bool:
	return W._count(p.created_tick) and p.created_tick<=s.core.tick and W._count(p.expires_tick) and p.expires_tick==p.created_tick+96

static func journey_valid(s: Dictionary, f: Dictionary) -> bool:
	if not W._id(f.at) or not W._id(f.objective) or not s.core.settlements.has(f.at) or not s.core.settlements.has(f.objective) or not f.edge_to is String or not W._count(f.remaining,0,1000000): return false
	if f.edge_to=="": return f.remaining==0
	return W._id(f.edge_to) and s.core.settlements.has(f.edge_to) and f.remaining>0 and f.remaining<=edge_ticks(s,f.at,f.edge_to)

static func plan_valid(s: Dictionary, p: Variant) -> bool:
	if not W._shape(p,["goal","target","resource","reason","scores","selected_tick","commit_until","review_tick","horizon_tick","supporting"]): return false
	if p.goal not in ["supplies","commerce","claim","defend","peace","hold"] or not p.target is String or (p.target!="" and not s.core.factions.has(p.target)) or p.resource not in ["","food","ore","timber"] or not W._text(p.reason): return false
	if not W._shape(p.scores,["economic","security","claim","readiness","cost","switching"]) or not W._count(p.selected_tick) or p.selected_tick>s.core.tick or p.commit_until!=p.selected_tick+288 or p.review_tick!=p.selected_tick+672 or p.horizon_tick!=p.selected_tick+1344: return false
	for n: Variant in p.scores.values():
		if not W._count(n,-1000,1000): return false
	return p.supporting is Array and p.supporting.size()<=2 and p.supporting.all(func(x): return x in ["trade","guard","rebuild"])
