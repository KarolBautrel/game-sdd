extends RefCounted
## Version5 host; only this authority supplies extra sites/tick hooks to version3.
const L := preload("res://scripts/domain/world_life.gd")
const R := L.R

static func base(s: Dictionary) -> Dictionary:
	var value := s.duplicate(true);value.erase("life");value.version=3;return value

static func initial(seed_value: int=2087, preset: String="marches", geography_version: int=3) -> Dictionary:
	var s := R.initial(seed_value,preset,geography_version)
	if s.is_empty(): return {}
	s.version=5;s.life=L.initial(s)
	return s if valid(s) else {}

static func valid(s: Variant) -> bool:
	if not s is Dictionary or not R.W._count(s.get("version"),5,5) or not s.get("life") is Dictionary: return false
	var root: Array=R.ROOT.duplicate();root.append("life")
	if not R.W._shape(s,root): return false
	if not R.W._registry(s.life.get("sites"),1,16) or not s.life.get("politics") is Dictionary or not R.W._registry(s.life.politics.get("outposts"),3,3): return false
	for registry: Dictionary in [s.life.sites,s.life.politics.outposts]:
		for site: Variant in registry.values():
			if not site is Dictionary or not R.G.Gen._valid_point(site.get("position")): return false
	var regional := base(s)
	if not R.valid(regional,extras(s)) or not L.valid(regional,s.life): return false
	if not s.company.active_run.is_empty() and s.life.sites.has(s.run_context.site):
		var site: Dictionary=s.life.sites[s.run_context.site]
		if site.status!="occupied" or s.life.episodes[site.episode].contract.get("status")!="company" or not R.Legacy.same_data(s.company.active_run.data,dungeon(s,site.id)): return false
	return true

static func extras(s: Dictionary) -> Dictionary:
	var result: Dictionary=s.life.sites.duplicate();result.merge(s.life.politics.outposts);return result

static func current(s: Dictionary) -> String: return R.current(s,extras(s))

static func dungeon(s: Dictionary, id: String) -> Dictionary:
	if not s.life.sites.has(id): return {}
	var site: Dictionary=s.life.sites[id]
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/dungeons/"+("ruined_shrine" if site.family=="ruins" else "road_camp")+".json"))
	data.id=id+"_"+site.episode;data.display_name=site.name;data.hazard_seed=int(site.seed)
	return data

static func prepare_reason(s: Dictionary) -> String:
	var id := current(s)
	if not s.life.sites.has(id) or s.life.sites[id].status!="occupied": return "Travel to an occupied camp."
	var e: Dictionary=s.life.episodes[s.life.sites[id].episode]
	if e.contract.get("status")!="company": return "Accept this camp's commission at its issuer before packing."
	return "" if s.company.active_run.is_empty() else "Resume the saved expedition."

static func contract_reason(s: Dictionary, id: String, report: bool=false) -> String:
	if not s.life.episodes.has(id): return "Unknown situation."
	var c: Dictionary=s.life.episodes[id].contract
	if c.is_empty(): return "No funded commission yet."
	if not s.company.active_run.is_empty(): return "Resolve the expedition first."
	if current(s)!=c.town: return "Visit "+s.region.sites[c.town].name+" to accept or report."
	if report: return "" if c.status=="objective" else "Complete the claimed objective before reporting."
	return "" if c.status=="offered" else "This commission is already claimed or closed."

static func _contract(s: Dictionary, cmd: Dictionary) -> Dictionary:
	var fail := {"ok":false,"reason":"Invalid or replayed situation request.","state":s.duplicate(true),"motion":{}}
	if not R.W._shape(cmd,["id","sequence","action","payload"]) or not R.W._count(cmd.sequence,1) or cmd.sequence!=s.request_seq+1 or cmd.id!="region_%08d" % int(cmd.sequence) or not R.W._shape(cmd.payload,["id"]) or not cmd.payload.id is String: return fail
	var reason := contract_reason(s,cmd.payload.id,cmd.action=="report_life")
	if reason!="": fail.reason=reason;return fail
	var next := s.duplicate(true);var e: Dictionary=next.life.episodes[cmd.payload.id];var c: Dictionary=e.contract
	if cmd.action=="accept_life":
		c.status="company";c.claim="company";c.deadline=int(next.strategy_world.core.tick)+480
		L.event(next,next.life,e,"Company accepted %s: exclusive until tick%d.24g /8XP; completed work remains payable." % [next.life.sites[e.site].name,c.deadline])
	else:
		L.release(next,c)
		if not R.C._spend(next.strategy_world,c.issuer,{"coin":int(c.gold)}): fail.reason="Reserved payment unavailable.";return fail
		next.company.gold+=int(c.gold);next.company.xp+=int(c.xp);c.status="paid"
		L.event(next,next.life,e,"Company received the frozen24g /8XP reward. This commission is settled.")
	next.request_seq=int(cmd.sequence);next.request_receipts.append({"id":cmd.id,"sequence":int(cmd.sequence),"action":cmd.action,"tick":int(next.strategy_world.core.tick)})
	while next.request_receipts.size()>64: next.request_receipts.pop_front()
	if not valid(next): fail.reason="Invalid contract settlement.";return fail
	return {"ok":true,"reason":"","state":next,"motion":{}}

static func apply(s: Dictionary, cmd: Dictionary) -> Dictionary:
	if not valid(s): return {"ok":false,"reason":"Invalid autonomous campaign.","state":s.duplicate(true),"motion":{}}
	if cmd.get("action") in ["accept_life","report_life"]: return _contract(s,cmd)
	var target := current(s)
	if cmd.get("action")=="begin_run" and s.life.politics.outposts.has(target): return {"ok":false,"reason":"This is a defended political outpost, not an expedition entrance.","state":s.duplicate(true),"motion":{}}
	if cmd.get("action")=="begin_run" and s.life.sites.has(target):
		var reason := prepare_reason(s)
		if reason=="" and not R.Legacy.same_data(cmd.get("payload",{}).get("data",{}),dungeon(s,target)): reason="The site's owned layout is fixed for this occupation."
		if reason!="": return {"ok":false,"reason":reason,"state":s.duplicate(true),"motion":{}}
	var life: Dictionary=s.life.duplicate(true)
	var motion := {}
	var hook := func(regional: Dictionary) -> void:
		motion.clear();L.tick(regional,life,motion)
	var result := R.apply(base(s),cmd,Callable(),hook,extras({"life":life}))
	if not result.ok:
		result.state=s.duplicate(true);return result
	if result.ok:
		result.motion.life=motion
		result.state.version=5;result.state.life=life
		if cmd.action=="settle" and s.life.sites.has(s.run_context.get("site","")) and cmd.payload.payload.outcome=="completed":
			var e: Dictionary=life.episodes[s.life.sites[s.run_context.site].episode]
			e.contract.status="objective";L.resolve(result.state,life,e,"company")
		if not valid(result.state): return {"ok":false,"reason":"Invalid autonomous transaction.","state":s.duplicate(true),"motion":{}}
	return result
