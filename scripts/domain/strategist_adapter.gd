extends RefCounted
## Durable asynchronous lifecycle. Transport and clock are session responsibilities.
const P := preload("res://scripts/domain/strategist_protocol.gd")
const C := P.C
const W := P.W
const ROOT := ["schema","version","mode","generation","request_seq","pending","next_review","completed","emergency_day","last_material","journal","totals","budget","rules"]
const FAULTS := ["missing","timeout","interrupted","transport","malformed","budget","late","stale","committed_plan","context_mismatch","unknown_capability","invented_event"]

static func initial(world: Dictionary) -> Dictionary:
	var a := {"schema":"sdd.strategist-state","version":1,"mode":"classic","generation":0,"request_seq":0,"pending":{},"next_review":{},"completed":{},"emergency_day":{},"last_material":{},"journal":[],"totals":{"accepted":0,"fallback":0,"cancelled":0,"dispatched":0},"budget":{"day":0,"calls":0,"tokens":0,"cost_micros":0},"rules":JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/strategists/rules_v1.json"))}
	for id: String in C.S.sorted_ids(world.core.factions):
		a.next_review[id]=0;a.completed[id]=0;a.emergency_day[id]=-1;a.last_material[id]=0
	return a

static func rules_valid(r: Variant) -> bool:
	if not W._shape(r,["schema","version","provider","calls_per_minute","calls_per_day","tokens_per_day","response_tokens","timeout_ms","cost_micro_limit"]) or not r.schema is String or not r.provider is String or r.schema!="sdd.strategist-rules" or not W._count(r.version,1,1) or r.provider!="recorded_fixtures": return false
	return W._count(r.calls_per_minute,0,4) and W._count(r.calls_per_day,0,8) and W._count(r.tokens_per_day,0,65536) and W._count(r.response_tokens,1,512) and W._count(r.timeout_ms,1,10000) and W._count(r.cost_micro_limit,0,0)

static func valid(a: Variant, world: Dictionary) -> bool:
	if not W._shape(a,ROOT) or not a.schema is String or a.schema!="sdd.strategist-state" or not W._count(a.version,1,1) or a.mode not in ["classic","recorded"] or not W._count(a.generation) or not W._count(a.request_seq) or not rules_valid(a.rules): return false
	var ids: Array=C.S.sorted_ids(world.core.factions);var tick := int(world.core.tick)
	for field: String in ["next_review","completed","emergency_day","last_material"]:
		if not a[field] is Dictionary or C.S.sorted_ids(a[field])!=ids: return false
		for id: String in ids:
			if not W._count(a[field][id],-1 if field=="emergency_day" else 0): return false
			if field=="completed" and a[field][id]>a.request_seq: return false
	if not W._registry(a.pending,0,ids.size()) or (a.mode=="classic" and not a.pending.is_empty()): return false
	var pending_numbers := {}
	for id: String in a.pending:
		var pending: Variant=a.pending[id]
		if id not in ids or not W._shape(pending,["request","status","reply","fault"]) or not P.request_valid(pending.request) or not pending.reply is Dictionary or not pending.fault is String: return false
		var q: Dictionary=pending.request
		if q.faction_id!=id or q.generation!=a.generation or q.number<=a.completed[id] or q.number>a.request_seq or pending_numbers.has(q.number) or q.observation_tick>tick or q.apply_by_tick<=tick: return false
		pending_numbers[q.number]=true
		if pending.status not in ["ready","sent","replied","fault"]: return false
		if pending.status=="replied":
			if P.reply_reason(q,pending.reply)!="" or pending.fault!="": return false
		elif not pending.reply.is_empty(): return false
		if pending.status=="fault":
			if pending.fault not in FAULTS: return false
		elif pending.fault!="": return false
	if not W._shape(a.totals,["accepted","fallback","cancelled","dispatched"]) or not W._shape(a.budget,["day","calls","tokens","cost_micros"]): return false
	for n: Variant in a.totals.values():
		if not W._count(n): return false
	for n: Variant in a.budget.values():
		if not W._count(n): return false
	if a.totals.accepted+a.totals.fallback+a.totals.cancelled+a.pending.size()!=a.request_seq or a.totals.dispatched>a.request_seq: return false
	if a.budget.day>tick/96 or a.budget.calls>a.rules.calls_per_day or a.budget.tokens>a.rules.tokens_per_day or a.budget.cost_micros!=0: return false
	if not a.journal is Array or a.journal.size()>64: return false
	var seen := {}
	for record: Variant in a.journal:
		if not W._shape(record,["number","request_id","decision_id","faction_id","generation","tick","outcome","reason","observation_hash","reply","executions"]): return false
		if not W._count(record.number,1,int(a.request_seq)) or seen.has(record.number) or not W._id(record.request_id) or not W._id(record.decision_id) or record.request_id!="request_%08d" % int(record.number) or record.decision_id!="decision_%08d" % int(record.number) or record.faction_id not in ids or record.number>a.completed[record.faction_id] or not W._count(record.generation,1,int(a.generation)) or not W._count(record.tick,0,tick): return false
		if record.outcome not in ["accepted","fallback","cancelled"] or record.reason not in FAULTS+["accepted","mode_changed"] or not record.observation_hash is String or record.observation_hash.length()!=64 or not record.reply is Dictionary or not record.executions is Array or record.executions.size()>3: return false
		if (record.outcome=="accepted" and record.reason!="accepted") or (record.outcome=="cancelled" and record.reason!="mode_changed") or (record.outcome=="fallback" and record.reason not in FAULTS): return false
		if record.outcome=="accepted" and record.reply.is_empty(): return false
		for result: Variant in record.executions:
			if not W._shape(result,["actor","action","reason"]) or not W._id(result.actor) or result.actor!=record.faction_id or result.action not in P.ACTIONS or not result.reason is String or result.reason.length()>128: return false
		seen[record.number]=true
	return true

static func observations(world: Dictionary) -> Dictionary:
	var result := {}
	for id: String in C.S.sorted_ids(world.core.factions): result[id]=C.observe(world,id)
	return result

static func _finish(a: Dictionary, actor: String, tick: int, outcome: String, reason: String) -> Dictionary:
	var pending: Dictionary=a.pending[actor];var q: Dictionary=pending.request
	var record := {"number":int(q.number),"request_id":q.request_id,"decision_id":"decision_%08d" % int(q.number),"faction_id":actor,"generation":int(q.generation),"tick":tick,"outcome":outcome,"reason":reason,"observation_hash":q.observation_hash,"reply":pending.reply.duplicate(true),"executions":[]}
	a.completed[actor]=int(q.number);a.journal.append(record);a.totals[outcome]+=1;a.pending.erase(actor)
	while a.journal.size()>64: a.journal.pop_front()
	return record

static func set_mode(a: Dictionary, world: Dictionary, mode: String) -> String:
	if mode not in ["classic","recorded"]: return "Unsupported strategist mode."
	if mode==a.mode: return "This strategist mode is already selected."
	var tick := int(world.core.tick)
	for id: String in C.S.sorted_ids(a.pending): _finish(a,id,tick,"cancelled","mode_changed")
	a.generation+=1;a.mode=mode
	var offset := 0
	for id: String in C.S.sorted_ids(world.core.factions):
		a.next_review[id]=maxi(tick,int(world.plans[id].commit_until)-24)+offset;offset+=168
	return ""

static func _material(o: Dictionary) -> int:
	var latest := 0
	for report: Dictionary in o.reports:
		if report.kind in ["war_declared","ceasefire","convoy_lost"]: latest=maxi(latest,int(report.sequence))
	return latest

static func review(a: Dictionary, inputs: Dictionary) -> Dictionary:
	var result := {"plans":{},"intents":{},"numbers":{}}
	if a.mode!="recorded": return result
	for id: String in C.S.sorted_ids(inputs):
		var o: Dictionary=inputs[id];var tick := int(o.tick)
		if a.pending.has(id) and tick>=a.pending[id].request.apply_by_tick:
			var pending: Dictionary=a.pending[id];var q: Dictionary=pending.request
			var reason: String=pending.fault if pending.status=="fault" else ("missing" if pending.status!="replied" else "")
			var caps := P.capabilities(P.bounded(o))
			if reason=="" and (P.context(q.observation)!=P.context(o) or not caps.goals.has(pending.reply.goal_id)): reason="stale"
			var committed: bool=not o.previous.is_empty() and tick<o.previous.commit_until
			if committed: reason="committed_plan"
			if reason=="":
				var reply: Dictionary=pending.reply
				result.plans[id]=P.plan(q.capabilities.goals[reply.goal_id],tick,reply.reason_code,reply.supporting)
				var chosen: Array=reply.intent_ids.duplicate()
				for contingency: Dictionary in reply.contingencies:
					if chosen.size()<3 and P.predicate(o,contingency.predicate): chosen.append(contingency.intent_id)
				result.intents[id]=[]
				for candidate: String in chosen: result.intents[id].append(q.capabilities.intents[candidate].duplicate(true))
				result.numbers[id]=int(q.number);_finish(a,id,tick,"accepted","accepted")
			else:
				if not committed: result.plans[id]=C.Planner.choose(o)
				_finish(a,id,tick,"fallback",reason)
		if a.pending.has(id): continue
		var old: Dictionary=o.previous
		var invalidated: bool=not old.is_empty() and old.target!="" and o.relations.any(func(r): return r.target==old.target and ((old.goal=="claim" and r.stance=="war") or (old.goal in ["defend","peace"] and r.stance=="peace")))
		var emergency: bool=invalidated and tick>=old.commit_until and _material(o)>a.last_material[id] and a.emergency_day[id]!=tick/96
		if tick<a.next_review[id] and not emergency: continue
		if emergency: a.emergency_day[id]=tick/96;a.last_material[id]=_material(o)
		a.request_seq+=1
		var q := P.request_observation(o,int(a.request_seq),int(a.generation))
		a.next_review[id]=tick+672
		a.pending[id]={"request":q,"status":"ready","reply":{},"fault":""}
		if not P.request_valid(q): _finish(a,id,tick,"fallback","malformed")
	return result

static func pending_actor(a: Dictionary, request_id: String) -> String:
	for id: String in a.pending:
		if a.pending[id].request.request_id==request_id: return id
	return ""

static func dispatch(a: Dictionary, request_id: String, tick: int) -> String:
	var id := pending_actor(a,request_id)
	if id=="" or a.pending[id].status!="ready": return "Request is not ready."
	var pending: Dictionary=a.pending[id]
	if tick>=pending.request.apply_by_tick: return "Request deadline passed."
	if a.budget.day!=tick/96: a.budget={"day":tick/96,"calls":0,"tokens":0,"cost_micros":0}
	var estimate := ceili(P.encoded(pending.request).to_utf8_buffer().size()/4.0)+int(a.rules.response_tokens)
	if a.budget.calls>=a.rules.calls_per_day or a.budget.tokens+estimate>a.rules.tokens_per_day:
		pending.status="fault";pending.fault="budget";return ""
	a.budget.calls+=1;a.budget.tokens+=estimate;a.totals.dispatched+=1;pending.status="sent"
	return ""

static func receive(a: Dictionary, request_id: String, raw: String, tick: int) -> String:
	var id := pending_actor(a,request_id)
	if id=="" or a.pending[id].status!="sent": return "No dispatched request matches this reply."
	var pending: Dictionary=a.pending[id]
	if tick>=pending.request.apply_by_tick: return "Reply arrived after the fixed deadline."
	if raw.to_utf8_buffer().size()>16384: return "Reply exceeds16KiB."
	var json := JSON.new()
	if json.parse(raw)!=OK: return "malformed"
	var reason := P.reply_reason(pending.request,json.data)
	if reason!="": return reason
	pending.reply=json.data;pending.status="replied";return ""

static func fault(a: Dictionary, request_id: String, reason: String) -> String:
	var id := pending_actor(a,request_id)
	if id=="" or a.pending[id].status not in ["ready","sent"] or reason not in FAULTS: return "Invalid request fault."
	a.pending[id].status="fault";a.pending[id].fault=reason;return ""

static func hook(a: Dictionary) -> Callable:
	var queue := {"intents":{},"numbers":{}}
	return func(phase: String, payload: Dictionary) -> Dictionary:
		if phase=="review":
			var result := review(a,payload);queue.intents=result.intents;queue.numbers=result.numbers;return result.plans
		if phase=="intents": return queue.intents
		if phase=="outcomes":
			for outcome: Dictionary in payload.results:
				if not queue.numbers.has(outcome.actor): continue
				for record: Dictionary in a.journal:
					if record.number==queue.numbers[outcome.actor]: record.executions.append(outcome.duplicate(true));break
			queue.intents={};queue.numbers={}
		return {}
