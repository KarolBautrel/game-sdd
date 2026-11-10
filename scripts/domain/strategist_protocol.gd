extends RefCounted
## Untrusted proposals select finite observed capabilities, never executable text.
const C := preload("res://scripts/domain/classic_world.gd")
const W := C.W
const POLICY := 1
const REASONS := ["reserve_deficit","profitable_exports","actual_war","war_costs","contested_supply_claim","rebuild_reserves","honour_agreement","protect_trade"]
const PREDICATES := ["food_below_target","at_war","trade_offer_waiting"]
const ACTIONS := ["propose_trade","accept_trade","reject_trade","mobilize","protect_route","declare_war","propose_peace","accept_peace","reject_peace","respond_aid","propose_pact","accept_pact","reject_pact"]
const OBS_KEYS := ["tick","seed","actor","own","previous","forces","relations","markets","incoming_trades","incoming_pacts","incoming_peace","aid","pending_trades","claim","live_trade_resources","own_trade_route","reports"]
const REQUEST_KEYS := ["schema","version","policy_version","request_id","number","faction_id","generation","observation_tick","apply_by_tick","requested_review_tick","horizon_tick","observation_hash","observation","capabilities"]
const REPLY_KEYS := ["schema","version","policy_version","request_id","decision_id","faction_id","generation","observation_tick","apply_by_tick","requested_review_tick","horizon_tick","observation_hash","goal_id","intent_ids","supporting","contingencies","reason_code","cited_events","public_summary"]

static func normalized(v: Variant) -> Variant:
	if v is Dictionary:
		var result := {}
		for k: Variant in v: result[k]=normalized(v[k])
		return result
	if v is Array:
		var result: Array=[]
		for item: Variant in v: result.append(normalized(item))
		return result
	if v is float and is_finite(v) and v==floor(v): return int(v)
	return v
static func encoded(v: Variant) -> String: return JSON.stringify(normalized(v),"",true,true)
static func digest(v: Variant) -> String: return encoded(v).sha256_text()

static func observation(world: Dictionary, actor: String) -> Dictionary:
	return bounded(C.observe(world,actor))
static func bounded(value: Dictionary) -> Dictionary:
	var o := value.duplicate(true)
	for field: String in ["forces","relations","markets","incoming_trades","incoming_pacts","incoming_peace","aid","pending_trades","reports"]:
		var cap := 16 if field in ["relations","reports"] else (12 if field=="markets" else 8)
		o[field]=o[field].slice(0,cap)
	return o

static func plan(goal: Dictionary, tick: int, reason: String="rebuild_reserves", supporting: Array=[]) -> Dictionary:
	return {"goal":goal.goal,"target":goal.target,"resource":goal.resource,"reason":reason,"scores":{"economic":0,"security":0,"claim":0,"readiness":0,"cost":0,"switching":0},"selected_tick":tick,"commit_until":tick+288,"review_tick":tick+672,"horizon_tick":tick+1344,"supporting":supporting.duplicate()}

static func capabilities(o: Dictionary) -> Dictionary:
	var goals: Array=[{"goal":"hold","target":"","resource":""},{"goal":"commerce","target":"","resource":""}]
	for resource: String in ["food","ore","timber"]:
		if o.own.available[resource]<o.own.policy.targets[resource]: goals.append({"goal":"supplies","target":"","resource":resource})
	for r: Dictionary in o.relations:
		if r.stance=="war":
			for goal: String in ["defend","peace"]: goals.append({"goal":goal,"target":r.target,"resource":""})
		elif not o.claim.is_empty() and r.target==o.claim.target and r.truce_until<=o.tick and r.pacts.is_empty(): goals.append({"goal":"claim","target":r.target,"resource":"ore"})
	var result := {"goals":{},"intents":{},"predicates":PREDICATES.duplicate(),"reason_codes":REASONS.duplicate()}
	for goal: Dictionary in goals:
		result.goals["goal_"+digest(goal).substr(0,20)]=goal
		for intent: Dictionary in C.Planner.intents(o,plan(goal,int(o.tick))):
			result.intents["candidate_"+digest(intent).substr(0,20)]=intent
	return result

static func request(world: Dictionary, actor: String, number: int, generation: int) -> Dictionary:
	return request_observation(C.observe(world,actor),number,generation)
static func request_observation(value: Dictionary, number: int, generation: int) -> Dictionary:
	var o := bounded(value);var caps := capabilities(o);var tick := int(o.tick);var actor: String=o.actor
	var boundary := ceili((tick+24)/24.0)*24
	return {"schema":"sdd.strategist-request","version":1,"policy_version":POLICY,"request_id":"request_%08d" % number,"number":number,"faction_id":actor,"generation":generation,"observation_tick":tick,"apply_by_tick":boundary,"requested_review_tick":boundary+672,"horizon_tick":boundary+1344,"observation_hash":digest({"observation":o,"capabilities":caps}),"observation":o,"capabilities":caps}

static func goal_valid(g: Variant) -> bool:
	return W._shape(g,["goal","target","resource"]) and g.goal in ["hold","commerce","supplies","claim","defend","peace"] and g.target is String and (g.target=="" or W._id(g.target)) and g.resource in ["","food","ore","timber"]

static func intent_valid(i: Variant) -> bool:
	if not W._shape(i,["action","payload"]) or i.action not in ACTIONS or not i.payload is Dictionary: return false
	var p: Dictionary=i.payload
	match i.action:
		"propose_trade": return W._shape(p,["id","seller","buyer","resource","amount","unit_price","source","target"]) and W._id(p.id) and p.id=="pending" and W._id(p.seller) and W._id(p.buyer) and p.seller!=p.buyer and p.resource in ["food","ore","timber"] and W._count(p.amount,1,12) and W._count(p.unit_price,1,100) and W._id(p.source) and W._id(p.target)
		"mobilize","protect_route": return W._shape(p,["party","route"]) and W._id(p.party) and W._id(p.route)
		"declare_war": return W._shape(p,["target","route"]) and W._id(p.target) and W._id(p.route)
		"propose_peace": return W._shape(p,["id","target"]) and W._id(p.id) and p.id=="pending" and W._id(p.target)
		"propose_pact": return W._shape(p,["id","target","kind","duration_ticks","valid_for_ticks"]) and W._id(p.id) and p.id=="pending" and W._id(p.target) and p.kind in W.KINDS and W._count(p.duration_ticks,96,2880) and W._count(p.valid_for_ticks,1,672)
		"respond_aid": return W._shape(p,["id","accept"]) and W._id(p.id) and p.accept is bool
	return W._shape(p,["id"]) and W._id(p.id)

static func observation_valid(o: Variant) -> bool:
	if not W._shape(o,OBS_KEYS) or not W._id(o.actor) or not W._count(o.tick) or not W._count(o.seed,1) or not W._shape(o.own,["name","stocks","manpower","available","policy","shortfalls","prices"]): return false
	if not W._text(o.own.name) or not W._count(o.own.manpower) or not W._shape(o.own.policy,["home","claim_route","production","consumption","targets","personality"]): return false
	var policy: Dictionary=o.own.policy
	if not W._id(policy.home) or not policy.claim_route is String or (policy.claim_route!="" and not W._id(policy.claim_route)) or not W._shape(policy.personality,["trade","security","aggression"]): return false
	for field: String in ["stocks","available","shortfalls"]:
		if not C.S.counts(o.own[field]): return false
	for field: String in ["production","consumption","targets"]:
		if not C.S.counts(policy[field],1000): return false
	for value: Variant in policy.personality.values():
		if not W._count(value,0,100): return false
	if not W._shape(o.own.prices,["food","ore","timber"]): return false
	for value: Variant in o.own.prices.values():
		if not W._count(value,1,100): return false
	if not o.previous is Dictionary or not o.claim is Dictionary or not o.own_trade_route is String or not o.live_trade_resources is Array or o.live_trade_resources.size()>32: return false
	for resource: Variant in o.live_trade_resources:
		if resource not in ["food","ore","timber"]: return false
	for field: String in ["forces","relations","markets","incoming_trades","incoming_pacts","incoming_peace","aid","pending_trades","reports"]:
		var cap := 16 if field in ["relations","reports"] else (12 if field=="markets" else 8)
		if not o[field] is Array or o[field].size()>cap or not o[field].all(func(x): return x is Dictionary): return false
	var known := {o.actor:{}}
	for r: Dictionary in o.relations:
		if not W._id(r.get("target")) or r.get("stance") not in ["peace","war"] or not r.get("pacts") is Array or not W._count(r.get("truce_until")): return false
		known[r.target]={}
	if not o.previous.is_empty() and not C.S.plan_valid({"core":{"tick":o.tick,"factions":known}},o.previous): return false
	for report: Dictionary in o.reports:
		if not W._shape(report,["id","sequence","tick","kind","actor","target","reason","resource","amount","age_ticks","confidence"]) or not W._id(report.id) or not W._count(report.sequence,1) or not W._count(report.tick,0,int(o.tick)) or not W._count(report.age_ticks) or not W._count(report.confidence,0,100): return false
	return true

static func request_valid(q: Variant) -> bool:
	if not W._shape(q,REQUEST_KEYS) or not q.schema is String or q.schema!="sdd.strategist-request" or not q.request_id is String or not q.observation_hash is String or not W._count(q.version,1,1) or not W._count(q.policy_version,POLICY,POLICY): return false
	if not W._count(q.number,1) or q.request_id!="request_%08d" % int(q.number) or not W._id(q.faction_id) or not W._count(q.generation,1) or not W._count(q.observation_tick) or not W._count(q.apply_by_tick) or not W._count(q.requested_review_tick) or not W._count(q.horizon_tick) or q.apply_by_tick!=ceili((q.observation_tick+24)/24.0)*24 or q.requested_review_tick!=q.apply_by_tick+672 or q.horizon_tick!=q.apply_by_tick+1344: return false
	var o: Variant=q.observation;var caps: Variant=q.capabilities
	if not observation_valid(o) or o.actor!=q.faction_id or o.tick!=q.observation_tick: return false
	if not W._shape(caps,["goals","intents","predicates","reason_codes"]) or not W._registry(caps.goals,1,40) or not W._registry(caps.intents,0,80) or not caps.predicates is Array or not caps.reason_codes is Array or caps.predicates!=PREDICATES or caps.reason_codes!=REASONS: return false
	for id: String in caps.goals:
		if not goal_valid(caps.goals[id]) or id!="goal_"+digest(caps.goals[id]).substr(0,20): return false
	for id: String in caps.intents:
		if not intent_valid(caps.intents[id]) or id!="candidate_"+digest(caps.intents[id]).substr(0,20): return false
	return encoded(q).to_utf8_buffer().size()<=32768 and q.observation_hash==digest({"observation":o,"capabilities":caps})

static func distinct(v: Variant, cap: int) -> bool:
	if not v is Array or v.size()>cap: return false
	var seen := {}
	for x: Variant in v:
		if not x is String or seen.has(x): return false
		seen[x]=true
	return true

static func reply_reason(q: Dictionary, p: Variant) -> String:
	if not W._shape(p,REPLY_KEYS) or not p.schema is String or p.schema!="sdd.strategist-reply" or not p.decision_id is String or not W._count(p.version,1,1): return "malformed"
	for field: String in ["policy_version","request_id","faction_id","generation","observation_tick","apply_by_tick","requested_review_tick","horizon_tick","observation_hash"]:
		if encoded(p[field])!=encoded(q[field]): return "context_mismatch"
	if p.decision_id!="decision_%08d" % int(q.number) or not p.goal_id is String or not q.capabilities.goals.has(p.goal_id) or p.reason_code not in REASONS: return "unknown_capability"
	if not distinct(p.intent_ids,3) or not distinct(p.supporting,2) or not distinct(p.cited_events,4) or not p.contingencies is Array or p.contingencies.size()>2: return "malformed"
	for id: String in p.intent_ids:
		if not q.capabilities.intents.has(id): return "unknown_capability"
	for support: String in p.supporting:
		if support not in ["trade","guard","rebuild"]: return "unknown_capability"
	var events := {}
	for e: Dictionary in q.observation.reports: events[e.id]=true
	for id: String in p.cited_events:
		if not events.has(id): return "invented_event"
	var contingencies := {}
	for c: Variant in p.contingencies:
		if not W._shape(c,["predicate","intent_id"]) or c.predicate not in PREDICATES or not c.intent_id is String or not q.capabilities.intents.has(c.intent_id) or c.intent_id in p.intent_ids or contingencies.has(c.intent_id): return "unknown_capability"
		contingencies[c.intent_id]=true
	if not p.public_summary is String or p.public_summary.length()>180 or encoded(p).to_utf8_buffer().size()>16384: return "malformed"
	return ""

static func context(o: Dictionary) -> String:
	var facts: Array=[]
	for r: Dictionary in o.relations: facts.append({"target":r.target,"stance":r.stance,"pacts":r.pacts,"truce_until":r.truce_until})
	return digest({"relations":facts,"claim":o.claim})

static func predicate(o: Dictionary, name: String) -> bool:
	if name=="food_below_target": return o.own.available.food<o.own.policy.targets.food
	if name=="at_war": return o.relations.any(func(r): return r.stance=="war")
	return not o.incoming_trades.is_empty() if name=="trade_offer_waiting" else false
