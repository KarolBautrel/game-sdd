extends RefCounted
## Explicit v4 composition; v3 remains authoritative for company/terrain/expeditions.
const R := preload("res://scripts/domain/strategic_region.gd")
const A := preload("res://scripts/domain/strategist_adapter.gd")
const W := R.W
const ACTIONS := ["model_mode","model_dispatch","model_reply","model_fault"]

static func regional(s: Dictionary) -> Dictionary:
	var result := s.duplicate(true);result.erase("strategist");result.version=3;return result
static func initial(seed_value: int=2087, preset: String="marches", geography_version: int=2) -> Dictionary:
	var result := R.initial(seed_value,preset,geography_version)
	if result.is_empty(): return {}
	result.version=4;result.strategist=A.initial(result.strategy_world)
	return result if valid(result) else {}
static func valid(s: Variant) -> bool:
	return W._shape(s,R.ROOT+["strategist"]) and s.schema is String and s.schema=="sdd.strategy-campaign" and W._count(s.version,4,4) and R.valid(regional(s)) and A.valid(s.strategist,s.strategy_world)
static func command(s: Dictionary, action: String, payload: Dictionary={}) -> Dictionary: return R.command(s,action,payload)
static func apply(s: Dictionary, cmd: Dictionary) -> Dictionary:
	if not valid(s): return {"ok":false,"reason":"Invalid strategist campaign.","state":s.duplicate(true),"motion":{}}
	if not W._shape(cmd,["id","sequence","action","payload"]) or not cmd.id is String or not W._count(cmd.sequence,1) or cmd.sequence!=s.request_seq+1 or cmd.id!="region_%08d" % int(cmd.sequence) or not cmd.action is String or not cmd.payload is Dictionary: return {"ok":false,"reason":"Invalid or replayed strategist command.","state":s.duplicate(true),"motion":{}}
	var next := s.duplicate(true);var reason := "";var motion := {}
	if cmd.action in ACTIONS:
		if not next.company.active_run.is_empty(): reason="Resolve the active expedition first."
		else: reason=_execute(next,cmd.action,cmd.payload)
		if reason=="":
			next.request_seq=int(cmd.sequence);next.request_receipts.append({"id":cmd.id,"sequence":int(cmd.sequence),"action":cmd.action,"tick":int(next.strategy_world.core.tick)})
			while next.request_receipts.size()>64: next.request_receipts.pop_front()
	else:
		var hook := A.hook(next.strategist) if next.strategist.mode=="recorded" else Callable()
		var result := R.apply(regional(next),cmd,hook)
		if not result.ok: reason=result.reason
		else:
			var adapter: Dictionary=next.strategist;next=result.state;next.version=4;next.strategist=adapter;motion=result.motion
	if reason=="" and not valid(next): reason="Invalid strategist transition."
	return {"ok":reason=="","reason":reason,"state":next if reason=="" else s.duplicate(true),"motion":motion if reason=="" else {}}
static func _execute(s: Dictionary, action: String, p: Dictionary) -> String:
	var a: Dictionary=s.strategist;var tick := int(s.strategy_world.core.tick)
	if action=="model_mode":
		if not W._shape(p,["mode"]) or not p.mode is String: return "Invalid strategist mode."
		return A.set_mode(a,s.strategy_world,p.mode)
	if action=="model_dispatch":
		if not W._shape(p,["request_id"]) or not W._id(p.request_id): return "Invalid dispatch."
		return A.dispatch(a,p.request_id,tick)
	if action=="model_reply":
		if not W._shape(p,["request_id","raw"]) or not W._id(p.request_id) or not p.raw is String: return "Invalid reply."
		return A.receive(a,p.request_id,p.raw,tick)
	if not W._shape(p,["request_id","reason"]) or not W._id(p.request_id) or not p.reason is String: return "Invalid request fault."
	return A.fault(a,p.request_id,p.reason)
static func replay(checkpoint: Dictionary, commands: Array) -> Dictionary:
	if not valid(checkpoint) or commands.size()>2048: return {"ok":false,"reason":"Invalid checkpoint/tail.","state":checkpoint.duplicate(true),"processed":0}
	var state := checkpoint.duplicate(true);var processed := 0
	for cmd: Variant in commands:
		if not cmd is Dictionary: return {"ok":false,"reason":"Invalid replay command.","state":checkpoint.duplicate(true),"processed":processed}
		var result := apply(state,cmd)
		if not result.ok: return {"ok":false,"reason":result.reason,"state":checkpoint.duplicate(true),"processed":processed}
		state=result.state;processed+=1
	return {"ok":true,"reason":"","state":state,"processed":processed}
