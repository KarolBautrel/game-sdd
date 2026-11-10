extends RefCounted
## Whole company/terrain/classic-world candidate; no file or scene authority here.
const C := preload("res://scripts/domain/classic_world.gd")
const G := preload("res://scripts/domain/strategic_geography.gd")
const Legacy := preload("res://scripts/session/campaign_session.gd")
const W := C.W
const ROOT := ["schema","version","company","strategy_world","current_settlement_id","region","region_rules","travel","jobs","job_seq","request_seq","request_receipts","cooldowns","scouting","mine","run_context","notes"]
const KINDS := ["delivery","recon","restoration"]
const PUBLIC_EVENTS := ["trade_dispatched","trade_delivered","convoy_lost","mobilization","war_declared","border_clash","ceasefire","accept_pact"]

static func initial(seed_value: int=2087, preset: String="marches", geography_version: int=2) -> Dictionary:
	var world := C.initial(seed_value)
	if world.is_empty(): return {}
	var geography := G.build(world.core,preset,geography_version)
	if geography.is_empty(): return {}
	G.bind(world.core,geography)
	var company := Legacy.initial_profile()
	company.gold=80;company.supplies.food=16;company.world.seed=seed_value
	company.equipment=Legacy.Gear.normalized(company.equipment)
	var rules: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/strategy_regions/rules_v1.json"))
	var s := {"schema":"sdd.strategy-campaign","version":3,"company":company,"strategy_world":world,"current_settlement_id":"town_ravenford","region":geography,"region_rules":rules,"travel":{"position":geography.sites.town_ravenford.position.duplicate(),"path":[],"goal":"","camping":false,"fatigue":0},"jobs":{},"job_seq":0,"request_seq":0,"request_receipts":[],"cooldowns":{},"scouting":{},"mine":{"status":"occupied","ore_rate":int(world.rules.policies.river_league.production.ore)},"run_context":{},"notes":[]}
	world.rules.policies.river_league.production.ore=0
	_note(s,"mine_occupied","dungeon_old_mine","Ore production has stopped at the occupied Old Mine.")
	_refresh_jobs(s)
	return s if valid(s) else {}

static func current(s: Dictionary) -> String:
	if not s.travel.path.is_empty(): return ""
	for id: String in s.region.sites:
		if G.point(s.travel.position).distance_to(G.point(s.region.sites[id].position))<=.012/G.travel_scale(s.region): return id
	return ""

static func at_town(s: Dictionary) -> bool:
	return s.region.sites.get(current(s),{}).get("kind")=="town" and s.company.active_run.is_empty()

static func site_owner(s: Dictionary, id: String) -> String:
	if id=="dungeon_old_mine" and s.mine.status=="restored": return "river_league"
	return s.region.sites.get(id,{}).get("owner","neutral")

static func _note(s: Dictionary, kind: String, target: String, text: String) -> void:
	s.notes.append({"tick":int(s.strategy_world.core.tick),"kind":kind,"target":target,"text":text})
	while s.notes.size()>48: s.notes.pop_front()

static func rules_valid(r: Variant) -> bool:
	if not W._shape(r,["schema","version","food_ratio","offer_ticks","cooldown_ticks","delivery","recon","restoration"]) or r.schema!="sdd.region-rules" or not W._count(r.version,1,1): return false
	if not W._count(r.food_ratio,1,20) or not W._count(r.offer_ticks,96,672) or not W._count(r.cooldown_ticks,96,2880): return false
	for kind: String in KINDS:
		if not W._shape(r[kind],["gold","xp","party_food","world_food"] if kind=="delivery" else ["gold","xp"]): return false
		for n: Variant in r[kind].values():
			if not W._count(n,1,100): return false
	return r.delivery.world_food==r.delivery.party_food*r.food_ratio

static func valid(s: Variant) -> bool:
	if not W._shape(s,ROOT) or s.schema!="sdd.strategy-campaign" or not W._count(s.version,3,3) or not C.S.valid(s.strategy_world) or not rules_valid(s.region_rules): return false
	var core: Dictionary=s.strategy_world.core
	if not G.binding_valid(core,s.region) or not s.company is Dictionary or not W._count(s.company.get("version"),4,4) or s.company.has("living_world") or not Legacy._valid_profile(s.company): return false
	if not s.company.world.pending_event.is_empty() or s.company.world.seed!=core.seed or s.company.world.elapsed_hours!=int(core.tick)/4: return false
	if not W._shape(s.travel,["position","path","goal","camping","fatigue"]) or not G.Gen._valid_point(s.travel.position) or not s.travel.path is Array or s.travel.path.size()>2000 or not s.travel.goal is String or (s.travel.goal!="" and not s.region.sites.has(s.travel.goal)) or not s.travel.camping is bool or not W._count(s.travel.fatigue,0,100): return false
	var nav := G.Gen.navigation(s.region.base)
	if not nav.passable(G.point(s.travel.position)): return false
	for p: Variant in s.travel.path:
		if not G.Gen._valid_point(p): return false
	if not is_finite(nav.route_cost(G.point(s.travel.position),s.travel.path)): return false
	if s.current_settlement_id!=current(s): return false
	for field: String in ["job_seq","request_seq"]:
		if not W._count(s[field]): return false
	if not W._registry(s.jobs,0,128) or not W._registry(s.cooldowns,0,128) or not W._registry(s.scouting,0,32) or not s.notes is Array or s.notes.size()>48: return false
	for tick: Variant in s.cooldowns.values():
		if not W._count(tick): return false
	for id: String in s.scouting:
		if not core.factions.has(id) or not W._registry(s.scouting[id],0,32): return false
		for target: String in s.scouting[id]:
			if not s.region.sites.has(target) or not W._count(s.scouting[id][target]) or s.scouting[id][target]>core.tick: return false
	if not W._shape(s.mine,["status","ore_rate"]) or s.mine.status not in ["occupied","restored"] or not W._count(s.mine.ore_rate,0,1000): return false
	if s.strategy_world.rules.policies.river_league.production.ore!=(s.mine.ore_rate if s.mine.status=="restored" else 0): return false
	if not s.run_context is Dictionary: return false
	if s.company.active_run.is_empty():
		if not s.run_context.is_empty(): return false
	else:
		if not W._shape(s.run_context,["id","site","rooms","camps"]) or s.run_context.id!=s.company.active_run.id or s.run_context.site!="dungeon_old_mine" or s.mine.status!="occupied" or current(s)!="dungeon_old_mine": return false
		for key: String in ["rooms","camps"]:
			if not W._count(s.run_context[key]): return false
		var run: Dictionary=s.company.active_run.state
		if not run.get("visited_room_ids") is Array or not run.get("camp_log") is Array or s.run_context.rooms!=run.visited_room_ids.size() or s.run_context.camps!=run.camp_log.size(): return false
	for id: String in s.jobs:
		var j: Variant=s.jobs[id]
		if not W._shape(j,["id","number","kind","issuer","issuer_town","target","cause","hold","gold","xp","party_food","world_food","created_tick","expires_tick","accepted_tick","status"]): return false
		if not W._count(j.number,1) or j.number>s.job_seq or id!="job_%08d" % int(j.number) or j.id!=id or j.kind not in KINDS or not core.factions.has(j.issuer) or not core.settlements.has(j.issuer_town) or core.settlements[j.issuer_town].owner_id!=j.issuer or not s.region.sites.has(j.target): return false
		if j.status not in ["offered","accepted","objective","paid","closed"] or not W._count(j.gold,1,100) or not W._count(j.xp,1,100) or not W._count(j.party_food,0,100) or not W._count(j.world_food,0,100): return false
		if not W._count(j.created_tick) or j.created_tick>core.tick or j.expires_tick!=j.created_tick+s.region_rules.offer_ticks or not W._id(j.hold) or not W._shape(j.cause,["id","kind","tick","context"]) or not W._id(j.cause.id) or not W._text(j.cause.kind) or not W._count(j.cause.tick) or j.cause.tick>j.created_tick or not W._text(j.cause.context): return false
		if j.status in ["accepted","objective","paid"]:
			if not W._count(j.accepted_tick) or j.accepted_tick<j.created_tick or j.accepted_tick>=j.expires_tick or j.accepted_tick>core.tick: return false
		elif j.accepted_tick!=null: return false
		if j.kind=="delivery" and (j.party_food<1 or j.world_food!=j.party_food*s.region_rules.food_ratio): return false
		if j.kind!="delivery" and (j.party_food!=0 or j.world_food!=0): return false
		if j.kind=="restoration" and (j.target!="dungeon_old_mine" or j.issuer!="river_league" or j.cause.kind!="site_occupied" or (j.status in ["objective","paid"] and s.mine.status!="restored")): return false
		if j.kind=="recon" and j.status in ["objective","paid"] and s.scouting.get(j.issuer,{}).get(j.target,-1)<=j.accepted_tick: return false
		var hold: Dictionary=core.reservations.get(j.hold,{})
		if j.status in ["offered","accepted","objective"]:
			if hold.is_empty() or hold.status!="reserved" or hold.faction_id!=j.issuer or hold.resource!="coin" or hold.amount!=j.gold or hold.purpose!=j.id: return false
		elif not hold.is_empty() and hold.status!="released": return false
	for note: Variant in s.notes:
		if not W._shape(note,["tick","kind","target","text"]) or not W._count(note.tick) or note.tick>core.tick or not W._text(note.kind) or not W._text(note.target) or not note.text is String or note.text.length()>256: return false
	if not s.request_receipts is Array or s.request_receipts.size()!=mini(int(s.request_seq),64): return false
	var expected: int=int(s.request_seq)-s.request_receipts.size()+1
	for receipt: Variant in s.request_receipts:
		if not W._shape(receipt,["id","sequence","action","tick"]) or not W._count(receipt.sequence,1) or receipt.sequence!=expected or receipt.id!="region_%08d" % expected or not W._text(receipt.action) or not W._count(receipt.tick) or receipt.tick>core.tick: return false
		expected+=1
	return true

static func command(s: Dictionary, action: String, payload: Dictionary) -> Dictionary:
	var n := int(s.request_seq)+1
	return {"id":"region_%08d" % n,"sequence":n,"action":action,"payload":payload.duplicate(true)}

static func apply(s: Dictionary, cmd: Dictionary, planner_hook: Callable=Callable()) -> Dictionary:
	if not valid(s): return {"ok":false,"reason":"Invalid regional campaign.","state":s.duplicate(true),"motion":{}}
	if not W._shape(cmd,["id","sequence","action","payload"]) or not W._count(cmd.sequence,1) or cmd.sequence!=s.request_seq+1 or cmd.id!="region_%08d" % int(cmd.sequence) or not cmd.action is String or not cmd.payload is Dictionary: return {"ok":false,"reason":"Invalid or replayed regional request.","state":s.duplicate(true),"motion":{}}
	var next := s.duplicate(true);var motion := {}
	var reason := _execute(next,cmd.action,cmd.payload,motion,planner_hook)
	if reason=="":
		next.request_seq=int(cmd.sequence);next.request_receipts.append({"id":cmd.id,"sequence":int(cmd.sequence),"action":cmd.action,"tick":int(next.strategy_world.core.tick)})
		while next.request_receipts.size()>64: next.request_receipts.pop_front()
		next.current_settlement_id=current(next)
		next.company.world.location_id="dungeon_old_mine" if current(next)=="dungeon_old_mine" else "town_ravenford"
		if not valid(next): reason="Invalid regional transaction."
	return {"ok":reason=="","reason":reason,"state":next if reason=="" else s.duplicate(true),"motion":motion if reason=="" else {}}

static func _advance(s: Dictionary, ticks: int, inside: bool, motion: Dictionary, planner_hook: Callable=Callable()) -> String:
	var hook := func(world: Dictionary) -> void:
		s.strategy_world=world
		var tick := int(world.core.tick)
		s.company.world.elapsed_hours=tick/4
		if tick%96==0: s.company.gold=maxi(0,int(s.company.gold)-3)
		if not inside:
			if tick%32==0 and s.company.supplies.food>0: s.company.supplies.food-=1
			if s.travel.camping: s.travel.fatigue=maxi(0,int(s.travel.fatigue)-4)
			elif not s.travel.path.is_empty():
				var speed := .0225/(1.0+float(s.travel.fatigue)/200.0)/G.travel_scale(s.region)
				if s.company.supplies.food==0: speed*=.65
				var detail := {}
				var arrived: bool=G.Gen.navigation(s.region.base).walk(s.travel,s.travel.path,speed,detail)
				motion.clear();motion.merge({"budget":speed,"samples":detail.samples,"tick":tick})
				s.travel.fatigue=mini(100,int(s.travel.fatigue)+1)
				if arrived:
					var id: String=s.travel.goal if s.travel.goal!="" else current(s)
					s.travel.goal=""
					if id!="": _arrive(s,id)
		_refresh_jobs(s)
	var result := C.apply(s.strategy_world,C.command(s.strategy_world,"world_clock","advance",{"ticks":ticks}),hook,planner_hook)
	if not result.ok: return "World advance rejected: "+str(result.reason)
	s.strategy_world=result.state
	return ""

static func _execute(s: Dictionary, action: String, p: Dictionary, motion: Dictionary, planner_hook: Callable=Callable()) -> String:
	if action in ["begin_run","checkpoint","settle"]: return _expedition(s,action,p,motion,planner_hook)
	if not s.company.active_run.is_empty(): return "Resolve or resume the active expedition."
	if action=="advance":
		if not W._shape(p,["ticks"]) or not W._count(p.ticks,1,192): return "Advance requires1..192ticks."
		return _advance(s,int(p.ticks),false,motion,planner_hook)
	if action=="course":
		if not W._shape(p,["position","site"]) or not p.site is String or (p.site!="" and not s.region.sites.has(p.site)) or not G.Gen._valid_point(p.position): return "Unknown destination."
		var destination: Dictionary=p.position if p.site=="" else s.region.sites[p.site].position
		var nav := G.Gen.navigation(s.region.base)
		if not nav.passable(G.point(destination)): return "Water and high peaks are blocked; use a crossing or pass."
		var path: Array=nav.route(G.point(s.travel.position),G.point(destination))
		if path.is_empty(): return "No terrain-safe route to the destination."
		s.travel.path=path;s.travel.goal=p.site;s.travel.camping=false
		return ""
	if action=="camp":
		if not W._shape(p,["enabled"]) or not p.enabled is bool: return "Invalid camp order."
		s.travel.path=[];s.travel.goal="";s.travel.camping=p.enabled;return ""
	if action in ["accept_job","report_job"]:
		if not W._shape(p,["id"]) or not W._id(p.id): return "Unknown job."
		return _job_action(s,action,p.id)
	return _service(s,action,p)

static func _post_job(s: Dictionary, kind: String, issuer: String, target: String, cause: Dictionary) -> void:
	var world: Dictionary=s.strategy_world
	var terms: Dictionary=s.region_rules[kind]
	if W.available(world.core,issuer,"coin")<int(terms.gold)+5: return
	for j: Dictionary in s.jobs.values():
		if j.cause.id==cause.id or (j.issuer==issuer and j.kind==kind and j.status in ["offered","accepted","objective"]): return
	if s.cooldowns.get(issuer+"_"+kind,0)>world.core.tick or s.jobs.size()>=128: return
	var number := int(s.job_seq)+1;var id := "job_%08d" % number
	var hold := C.S.next_id(world,"hold")
	if C._operate(world,issuer,"reserve_budget",{"id":hold,"resource":"coin","amount":int(terms.gold),"purpose":id})!="": return
	s.job_seq=number
	s.jobs[id]={"id":id,"number":number,"kind":kind,"issuer":issuer,"issuer_town":world.rules.policies[issuer].home,"target":target,"cause":cause.duplicate(true),"hold":hold,"gold":int(terms.gold),"xp":int(terms.xp),"party_food":int(terms.get("party_food",0)),"world_food":int(terms.get("world_food",0)),"created_tick":int(world.core.tick),"expires_tick":int(world.core.tick)+int(s.region_rules.offer_ticks),"accepted_tick":null,"status":"offered"}
	_note(s,"job_posted",id,"New work: "+kind+" / "+world.core.factions[issuer].name+".")

static func _release(s: Dictionary, j: Dictionary) -> void:
	C._operate(s.strategy_world,j.issuer,"release_budget",{"id":j.hold})

static func _refresh_jobs(s: Dictionary) -> void:
	var world: Dictionary=s.strategy_world;var tick := int(world.core.tick)
	for id: String in C.S.sorted_ids(s.jobs):
		var j: Dictionary=s.jobs[id]
		if j.status=="offered":
			var resolved: bool=(j.kind=="restoration" and s.mine.status=="restored") or (j.kind=="delivery" and world.core.factions[j.issuer].stocks.food>=world.rules.policies[j.issuer].targets.food*.75)
			if tick>=j.expires_tick or resolved:
				_release(s,j);j.status="closed";_note(s,"job_closed",id,"Unaccepted offer closed; issuer funds released.")
		elif j.status in ["paid","closed"] and tick-int(j.created_tick)>1344: s.jobs.erase(id)
	var week := tick/672
	for issuer: String in C.S.sorted_ids(world.core.factions):
		var policy: Dictionary=world.rules.policies[issuer]
		if world.core.factions[issuer].stocks.food<policy.targets.food*.5:
			_post_job(s,"delivery",issuer,policy.home,{"id":"need_"+(issuer+str(week)).sha256_text().substr(0,24),"kind":"food_deficit","tick":tick,"context":"Published food reserve is below half its target."})
		var report_target := "high_pass";var cause: Dictionary={}
		for e: Dictionary in world.events:
			if e.kind=="convoy_lost" and tick-int(e.tick)<672:
				var t: Dictionary=world.trades.get(e.target,{})
				if not t.is_empty() and issuer in [t.seller,t.buyer]: report_target=t.at;cause={"id":e.id,"kind":"convoy_lost","tick":int(e.tick),"context":"A confirmed convoy loss needs fresh reconnaissance."}
			elif e.kind=="war_declared" and issuer in [e.actor,e.target] and tick-int(e.tick)<672:
				cause={"id":e.id,"kind":"war_declared","tick":int(e.tick),"context":"A public declaration has made border reports obsolete."}
		var last: int=int(s.scouting.get(issuer,{}).get(report_target,-672))
		if tick-last>=672 and (not cause.is_empty() or issuer=="iron_march"):
			if cause.is_empty(): cause={"id":"intel_"+(issuer+str(week)).sha256_text().substr(0,24),"kind":"missing_report","tick":tick,"context":"No recent verified report from the High Pass."}
			_post_job(s,"recon",issuer,report_target,cause)
	if s.mine.status=="occupied": _post_job(s,"restoration","river_league","dungeon_old_mine",{"id":"occupied_old_mine","kind":"site_occupied","tick":0,"context":"The Old Mine is occupied; ore production is suspended."})

static func job_reason(s: Dictionary, id: String, report: bool=false) -> String:
	if not s.jobs.has(id): return "Unknown or archived contract."
	if not s.company.active_run.is_empty(): return "Resolve the active expedition first."
	var j: Dictionary=s.jobs[id]
	if j.status in ["paid","closed"]: return "This contract is paid or closed."
	if current(s)!=j.issuer_town: return "Stop at "+s.region.sites[j.issuer_town].name+" to accept or report."
	if not report:
		if j.status!="offered": return "This contract was already accepted."
		if s.strategy_world.core.tick>=j.expires_tick: return "This offer expired."
	else:
		if j.status not in ["accepted","objective"]: return "Accept the contract first."
		if j.kind=="delivery" and s.company.supplies.food<j.party_food: return "Carry %d owned food (%d/%d)." % [j.party_food,s.company.supplies.food,j.party_food]
		if j.kind!="delivery" and j.status!="objective": return "Complete the accepted objective and return to the issuer."
	return ""

static func _job_action(s: Dictionary, action: String, id: String) -> String:
	var reason := job_reason(s,id,action=="report_job")
	if reason!="": return reason
	var j: Dictionary=s.jobs[id]
	if action=="accept_job":
		j.status="accepted";j.accepted_tick=int(s.strategy_world.core.tick)
		_note(s,"job_accepted",id,"Accepted "+j.kind+" contract; reward terms are frozen.")
		return ""
	_release(s,j)
	var world: Dictionary=s.strategy_world
	world.core.factions[j.issuer].stocks.coin-=int(j.gold);world.ledger.consumed.coin+=int(j.gold)
	s.company.gold+=int(j.gold);s.company.xp+=int(j.xp)
	if j.kind=="delivery":
		s.company.supplies.food-=int(j.party_food)
		world.core.factions[j.issuer].stocks.food+=int(j.world_food);world.ledger.produced.food+=int(j.world_food)
	world.core.company_reputation[j.issuer]=mini(100,int(world.core.company_reputation[j.issuer])+5)
	j.status="paid";s.cooldowns[j.issuer+"_"+j.kind]=int(world.core.tick)+int(s.region_rules.cooldown_ticks)
	C.S.event(world,"company_contract",j.issuer,j.id,"reserved_reward_paid","coin",int(j.gold))
	_note(s,"job_paid",id,"Contract reported: +%dg / +%dXP." % [j.gold,j.xp])
	return ""

static func _arrive(s: Dictionary, target: String) -> void:
	_note(s,"arrival",target,"Arrived at "+s.region.sites[target].name+".")
	for j: Dictionary in s.jobs.values():
		if j.kind=="recon" and j.status=="accepted" and j.target==target and s.strategy_world.core.tick>j.accepted_tick:
			j.status="objective"
			if not s.scouting.has(j.issuer): s.scouting[j.issuer]={}
			s.scouting[j.issuer][target]=int(s.strategy_world.core.tick)
			_note(s,"recon_ready",j.id,"Verified report ready; return to "+s.region.sites[j.issuer_town].name+".")

static func _service(s: Dictionary, action: String, p: Dictionary) -> String:
	if action=="buy_supply":
		if not W._shape(p,["id"]) or not p.id is String: return "Unknown supply."
		var quote := supply_quote(s,p.id)
		if quote.reason!="": return quote.reason
		var faction: String=s.region.sites[current(s)].owner
		var world: Dictionary=s.strategy_world
		var price: int=int(quote.price)
		s.company.gold-=price;s.company.supplies[p.id]+=1
		world.core.factions[faction].stocks.coin+=price;world.ledger.produced.coin+=price
		if p.id=="food": world.core.factions[faction].stocks.food-=int(s.region_rules.food_ratio);world.ledger.consumed.food+=int(s.region_rules.food_ratio)
		_note(s,"purchase",current(s),"Bought "+str(Legacy.SUPPLY_NAMES[p.id])+" for %dg." % price)
		return ""
	if action not in ["recover","equip","purchase_item","sell_item","train"]: return "Unsupported regional action."
	if action!="equip" and not at_town(s): return "Stop at a town for this service."
	var calculator := Legacy.new();calculator.loaded=true;calculator.memory_only=true;calculator.state=s.company.duplicate(true)
	calculator.state.world.location_id="town_ravenford"
	var accepted := false
	match action:
		"recover":
			if p.is_empty(): accepted=calculator.recover()
		"equip":
			if W._shape(p,["hero","slot","item"]) and p.hero is String and p.slot is String and (p.item==null or p.item is String): accepted=calculator.equip(p.hero,p.slot,p.item)
		"purchase_item","sell_item":
			if W._shape(p,["id"]) and p.id is String: accepted=calculator.call(action,p.id)
		"train":
			if W._shape(p,["hero"]) and p.hero is String: accepted=calculator.train(p.hero)
	var reason: String=calculator.last_feedback
	if accepted:
		var delta := int(s.company.gold)-int(calculator.state.gold)
		if delta!=0:
			var faction: String=s.region.sites[current(s)].owner
			if delta<0 and W.available(s.strategy_world.core,faction,"coin")< -delta: accepted=false;reason="The town cannot fund this sale."
			else:
				s.strategy_world.core.factions[faction].stocks.coin+=delta
				if delta>0: s.strategy_world.ledger.produced.coin+=delta
				else: s.strategy_world.ledger.consumed.coin-=delta
		if accepted:
			s.company=calculator.state.duplicate(true)
			if action=="recover": s.travel.fatigue=0
			_note(s,"service",current(s) if current(s)!="" else "company",reason)
	calculator.free()
	return "" if accepted else (reason if reason!="" else "Invalid service request.")

static func supply_quote(s: Dictionary, id: String) -> Dictionary:
	var result := {"price":int(Legacy.PRICES.get(id,0)),"reason":""}
	if not Legacy.PRICES.has(id): result.reason="Unknown supply.";return result
	if not at_town(s): result.reason="Buy supplies at a stopped town.";return result
	var faction: String=s.region.sites[current(s)].owner
	if id=="food":
		result.price=2 if s.strategy_world.core.factions[faction].stocks.food<s.strategy_world.rules.policies[faction].targets.food else 1
		if W.available(s.strategy_world.core,faction,"food")<s.region_rules.food_ratio: result.reason="This town has no food to spare."
	if result.reason=="" and s.company.gold<result.price: result.reason="Not enough company gold."
	return result

static func _expedition(s: Dictionary, action: String, p: Dictionary, motion: Dictionary, planner_hook: Callable=Callable()) -> String:
	if action=="begin_run" and (current(s)!="dungeon_old_mine" or s.mine.status!="occupied" or not s.company.active_run.is_empty()): return "Travel to the occupied Old Mine before packing."
	if action=="begin_run":
		if not W._shape(p,["data","state"]) or not p.data is Dictionary or not p.state is Dictionary or not p.data.get("rooms") is Array or p.data.rooms.is_empty() or not p.data.get("generated_profile",{}) is Dictionary or (p.data.get("id")!="dungeon_old_mine" and p.data.get("generated_profile",{}).get("theme")!="mine"): return "Unsupported expedition site or layout."
	elif action=="checkpoint":
		if not W._shape(p,["data","state","seed"]) or not p.data is Dictionary or not p.state is Dictionary or not W._count(p.seed): return "Invalid checkpoint."
	elif not W._shape(p,["payload"]) or not p.payload is Dictionary: return "Invalid return payload."
	if action!="begin_run" and s.company.active_run.is_empty(): return "No active managed expedition."
	if action=="checkpoint" and (not Legacy.same_data(p.data,s.company.active_run.data) or not p.state.get("visited_room_ids") is Array or not p.state.get("camp_log") is Array): return "Checkpoint layout/context differs from the active expedition."
	var calculator := Legacy.new();calculator.loaded=true;calculator.memory_only=true;calculator.state=s.company.duplicate(true)
	calculator.state.world.location_id="dungeon_old_mine"
	var accepted := false
	if action=="begin_run": accepted=calculator.begin_run(p.data,p.state)
	elif action=="checkpoint": accepted=calculator.checkpoint(p.data,p.state,int(p.seed))
	else: accepted=calculator.settle(p.payload)
	var reason: String=calculator.last_feedback
	if not accepted: calculator.free();return reason
	if action=="begin_run":
		s.company=calculator.state.duplicate(true)
		s.run_context={"id":s.company.active_run.id,"site":"dungeon_old_mine","rooms":s.company.active_run.state.get("visited_room_ids",[]).size(),"camps":s.company.active_run.state.get("camp_log",[]).size()}
	elif action=="checkpoint":
		var rooms: int=p.state.get("visited_room_ids",[]).size();var camps: int=p.state.get("camp_log",[]).size()
		var ticks := maxi(0,rooms-int(s.run_context.rooms))+16*maxi(0,camps-int(s.run_context.camps))
		if ticks>192: calculator.free();return "Invalid checkpoint time increment."
		s.company=calculator.state.duplicate(true)
		if ticks>0:
			var error := _advance(s,ticks,true,motion,planner_hook)
			if error!="": calculator.free();return error
		s.run_context.rooms=maxi(rooms,int(s.run_context.rooms));s.run_context.camps=maxi(camps,int(s.run_context.camps))
	else:
		s.company=calculator.state.duplicate(true);s.run_context={}
		if p.payload.outcome=="completed":
			s.mine.status="restored";s.strategy_world.rules.policies.river_league.production.ore=int(s.mine.ore_rate)
			for j: Dictionary in s.jobs.values():
				if j.kind=="restoration" and j.status=="accepted": j.status="objective"
			_note(s,"mine_restored","dungeon_old_mine","The restored mine resumes ore production. Report accepted work to Ravenford.")
		else: _note(s,"expedition_return","dungeon_old_mine","Expedition "+str(p.payload.outcome)+"; the mine remains occupied.")
	calculator.free()
	_refresh_jobs(s)
	return ""

static func public_faction(s: Dictionary, faction: String) -> Dictionary:
	if not s.strategy_world.core.factions.has(faction): return {}
	var core: Dictionary=s.strategy_world.core
	var result := {"name":core.factions[faction].name,"reputation":int(core.company_reputation[faction]),"towns":[],"diplomacy":[],"troops":0}
	for id: String in core.settlements:
		if core.settlements[id].owner_id==faction: result.towns.append(core.settlements[id].name)
	for party: Dictionary in core.parties.values():
		if party.faction_id==faction: result.troops+=int(party.headcount)
	for key: String in core.diplomacy:
		var pair: Dictionary=core.diplomacy[key]
		if faction not in [pair.a,pair.b]: continue
		var other: String=pair.b if pair.a==faction else pair.a
		var pacts: Array=[]
		for pact: Dictionary in pair.treaties:
			if pact.end_tick>core.tick: pacts.append(pact.kind.replace("_"," "))
		result.diplomacy.append({"name":core.factions[other].name,"stance":pair.stance,"pacts":pacts,"truce_ticks":maxi(0,int(s.strategy_world.wars[key].truce_until)-int(core.tick))})
	return result

static func chronicle(s: Dictionary) -> Array:
	var rows: Array=[]
	for e: Dictionary in s.strategy_world.events:
		if e.kind not in PUBLIC_EVENTS: continue
		var actor: String=s.strategy_world.core.factions.get(e.actor,{}).get("name",e.actor)
		var target: String=s.strategy_world.core.factions.get(e.target,{}).get("name","")
		var descriptions := {"trade_dispatched":"sent a convoy","trade_delivered":"completed a delivery","convoy_lost":"intercepted a convoy","mobilization":"is mustering troops","war_declared":"declared war","border_clash":"fought a border clash","ceasefire":"signed a ceasefire","accept_pact":"signed an agreement"}
		var text: String=actor+" "+descriptions[e.kind]
		if target!="": text+=" / "+target
		elif s.strategy_world.trades.has(e.target):
			var trade: Dictionary=s.strategy_world.trades[e.target]
			var where: String=trade.source if e.kind=="trade_dispatched" else (trade.target if e.kind=="trade_delivered" else trade.at)
			text+=" near "+s.region.sites[where].name
		rows.append({"tick":int(e.tick),"text":text+".","cause":e.id})
	for note: Dictionary in s.notes: rows.append({"tick":int(note.tick),"text":note.text,"cause":note.kind})
	rows.sort_custom(func(a,b): return a.tick>b.tick)
	return rows.slice(0,48)
