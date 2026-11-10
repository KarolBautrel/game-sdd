extends RefCounted
## Pure living-region rules. Call only on CampaignSession transaction candidates.
const PATH := "res://resources/data/world_simulations/living_marches_v1.json"
const Terrain := preload("res://scripts/domain/terrain_navigation.gd")
const Generator := preload("res://scripts/domain/region_generator.gd")
static var cached_definition: Dictionary = {}
static var generated_definitions: Dictionary={}

static func definition(state: Dictionary={}) -> Dictionary:
	if cached_definition.is_empty(): cached_definition=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if state.has("geography"):
		var geo: Dictionary=state.geography
		if not generated_definitions.has(geo.checksum):
			if generated_definitions.size()>=24: generated_definitions.erase(generated_definitions.keys()[0])
			var data:=cached_definition.duplicate(false)
			data.sites=geo.sites;data.roads=geo.roads;data.geography=geo
			generated_definitions[geo.checksum]=data
		return generated_definitions[geo.checksum]
	return cached_definition

static func navigation(state: Dictionary={}) -> RefCounted:
	return Generator.navigation(state.geography) if state.has("geography") else Terrain.current()

static func point(value: Dictionary) -> Vector2:
	return Vector2(float(value.x),float(value.y))

static func packed(value: Vector2) -> Dictionary:
	return Terrain.packed(value)

static func site(id: String,state: Dictionary={}) -> Dictionary:
	for entry: Dictionary in definition(state).sites:
		if entry.id == id: return entry
	return {}

static func contract(id: String) -> Dictionary:
	for entry: Dictionary in definition().contracts:
		if entry.id == id: return entry
	return {}

static func _polygon(values: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for value: Dictionary in values: result.append(point(value))
	return result

static func passable(position: Vector2,state: Dictionary = {}) -> bool:
	return navigation(state).passable(position)

static func legacy_land(position: Vector2,data: Dictionary = {}) -> bool:
	if data.is_empty(): data=definition()
	if not position.is_finite() or not Geometry2D.is_point_in_polygon(position,_polygon(data.land)): return false
	for polygon: Array in data.blocked:
		if Geometry2D.is_point_in_polygon(position,_polygon(polygon)): return false
	return true

static func terrain_cost(position: Vector2,state: Dictionary) -> float:
	return navigation(state).cost_at(position)

static func path_between(start: Vector2,destination: Vector2,state: Dictionary={}) -> Array[Dictionary]:
	return navigation(state).route(start,destination)

static func navigation_anchors(state: Dictionary={}) -> Array:
	var result: Array=definition(state).sites.duplicate(true)
	for index in range(definition(state).roads.size()):
		for cursor in range(definition(state).roads[index].size()):
			var name: String=["Trade road","Mine track","Abbey road","Highland road","Keep road"][index]
			result.append({"id":"%s / waypoint %d" % [name,cursor+1],"position":definition(state).roads[index][cursor]})
	return result

static func prepare_navigation(state: Dictionary) -> void:
	var nav: RefCounted=navigation(state)
	if state.get("terrain_signature","")==nav.signature: return
	var destination: Dictionary=state.party.path.back().duplicate() if not state.party.path.is_empty() else {}
	var recovered:=false
	var mainland:=point(site("town_ravenford",state).position)
	for unit: Dictionary in [state.party]+state.actors:
		var old:=point(unit.position)
		var safe: Vector2=nav.nearest(old,mainland)
		if not safe.is_equal_approx(old): unit.position=packed(safe);recovered=true
	for actor: Dictionary in state.actors:
		for index in range(actor.route.size()): actor.route[index]=packed(nav.nearest(point(actor.route[index]),mainland))
		actor.path=[]
	state.party.path=path_between(point(state.party.position),point(destination),state) if not destination.is_empty() else []
	if state.party.path.is_empty(): state.party.goal=""
	state.terrain_signature=nav.signature
	_log(state,"Terrain updated: routes recalculated."+(" A blocked saved position was moved to the nearest accessible ground." if recovered else ""))

static func _actor(id: String,kind: String,faction: String,route: Array,speed: float) -> Dictionary:
	return {"id":id,"kind":kind,"faction":faction,"position":route[0].duplicate(),"route":route.duplicate(true),"path":[],"index":1,"direction":1,"speed":speed,"cargo":24 if kind=="caravan" else 0,"active":true}

static func initial(seed: int,elapsed_hours: int = 0,geography: Dictionary={}) -> Dictionary:
	var context: Dictionary={"geography":geography} if not geography.is_empty() else {}
	var data := definition(context)
	var result := {"version":1,"scenario":str(data.id),"seed":seed,"tick":elapsed_hours*4,
		"party":{"position":site("town_ravenford",context).position.duplicate(),"path":[],"goal":"","camping":false,"fatigue":0},
		"settlements":{"town_ravenford":{"supply":30,"security":45},"saltwatch":{"supply":28,"security":40},"black_keep":{"supply":65,"security":65}},
		"factions":{"river_league":{"relation":0,"strength":80},"iron_march":{"relation":0,"strength":80}},
		"mine":{"status":"occupied","threat":70},"politics":{"tension":55,"phase":"rivalry","skirmishes":0,"next_skirmish_tick":0},
		"contracts":{},"intelligence":false,"encounter_until":0,"next_raid_tick":0,"raids":0,"deliveries":0,"journal":[],
		"terrain_signature":str(navigation(context).signature),
		"actors":[_actor("caravan","caravan","river_league",data.roads[0],.014),
			_actor("league_patrol","patrol","river_league",data.roads[0].slice(0,4),.018),
			_actor("iron_patrol","patrol","iron_march",data.roads[4],.018),
			_actor("mine_raiders","raiders","bandits",[data.sites[3].position,data.roads[0][3],data.roads[0][4]],.022)]}
	if not geography.is_empty(): result.geography=geography.duplicate(true)
	_log(result,"Ore deliveries have stopped. Raiders occupy the Old Mine.")
	_offers(result)
	return result

static func _log(state: Dictionary,message: String) -> void:
	state.journal.append({"tick":int(state.tick),"text":message})
	while state.journal.size()>24: state.journal.pop_front()

static func at_site(state: Dictionary,id: String) -> bool:
	var entry := site(id,state)
	return not entry.is_empty() and state.party.path.is_empty() and point(state.party.position).distance_to(point(entry.position))<=.022

static func current_site(state: Dictionary) -> String:
	for entry: Dictionary in definition(state).sites:
		if at_site(state,entry.id): return str(entry.id)
	return ""

static func at_town(state: Dictionary) -> bool:
	return site(current_site(state),state).get("kind","") == "town"

static func food_price(state: Dictionary) -> int:
	var town := current_site(state)
	return 2 if state.settlements.has(town) and int(state.settlements[town].supply)<40 else 1

static func course(profile: Dictionary,destination: Vector2,goal: String = "") -> bool:
	var state: Dictionary=profile.living_world
	if not goal.is_empty():
		if site(goal,state).is_empty(): return false
		destination=point(site(goal,state).position)
	# Reject bad targets before migration can mutate the candidate.
	if not passable(destination,state): return false
	prepare_navigation(state)
	var route:=path_between(point(state.party.position),destination,state)
	if route.is_empty(): return false
	state.party.path=route
	state.party.goal=goal
	state.party.camping=false
	return true

static func travel_scale(state: Dictionary) -> float:
	return float(Generator.world_scale(int(state.get("geography",{}).get("version",1))))
static func _walk(unit: Dictionary,path: Array,distance: float,motion: Variant=null,state: Dictionary={}) -> bool:
	var scale:=travel_scale(state)
	var arrived: bool=navigation(state).walk(unit,path,distance/scale,motion)
	if motion!=null and scale!=1:
		motion.remaining=float(motion.remaining)*scale
		for sample: Dictionary in motion.samples: sample.cost=float(sample.cost)*scale
	return arrived

static func _trace(units: Variant,id: String,detail: Dictionary,offset: float,total: float) -> void:
	if units==null: return
	if not units.has(id): units[id]=[]
	for sample: Dictionary in detail.samples:
		var value: Dictionary={"time":clampf((offset+float(sample.cost))/total,0,1),"position":sample.position}
		if not units[id].is_empty() and is_equal_approx(float(units[id].back().time),float(value.time)): continue
		units[id].append(value)

static func advance(profile: Dictionary,ticks: int,inside: bool = false,motion: Variant=null) -> bool:
	var state: Dictionary=profile.living_world
	prepare_navigation(state)
	for iteration in range(ticks):
		var units: Dictionary={}
		state.tick=int(state.tick)+1
		profile.world.elapsed_hours=int(state.tick)/4
		if int(state.tick)%96==0:
			profile.gold=maxi(0,int(profile.gold)-3)
			_log(state,"Daily company wages: 3 gold.")
		if not inside:
			if int(state.tick)%32==0:
				if int(profile.supplies.food)>0: profile.supplies.food=int(profile.supplies.food)-1
				else: _log(state,"Food is exhausted. The company travels more slowly until resupplied.")
			if state.party.camping: state.party.fatigue=maxi(0,int(state.party.fatigue)-4)
			elif not state.party.path.is_empty():
				var speed:=.045/(1.0+float(state.party.fatigue)/200.0)
				if int(profile.supplies.food)==0: speed*=.65
				var detail: Dictionary={}
				var arrived:=_walk(state.party,state.party.path,speed,detail if motion!=null else null,state)
				if motion!=null: _trace(units,"company",detail,0,speed)
				if arrived:
					var arrival:=str(state.party.goal)
					if arrival.is_empty(): arrival=current_site(state)
					if not arrival.is_empty():
						profile.world.location_id=arrival
						_log(state,"Arrived at "+str(site(arrival,state).name)+".")
						if arrival=="high_pass" and state.contracts.get("scout_pass",{}).get("stage","")=="accepted":
							state.contracts.scout_pass.stage="objective"
							state.intelligence=true
							_log(state,"High Pass surveyed. Report to Black Keep.")
					state.party.goal=""
				state.party.fatigue=mini(100,int(state.party.fatigue)+1)
		_actors(state,units if motion!=null else null)
		if motion!=null:
			for samples: Array in units.values():
				if not samples.is_empty() and float(samples.back().time)<1:
					var held: Dictionary=samples.back().duplicate(true);held.time=1.0;samples.append(held)
			motion.clear()
			motion.merge({"from_tick":int(state.tick)-1,"tick":int(state.tick),"units":units})
		if int(state.tick)%96==0: _politics(state)
		_offers(state)
		if not inside and not state.party.path.is_empty() and int(state.tick)>=int(state.encounter_until):
			for actor: Dictionary in state.actors:
				if actor.kind=="raiders" and actor.active and point(actor.position).distance_to(point(state.party.position))<.035:
					state.encounter_until=int(state.tick)+32
					_log(state,"Mine raiders intercepted the company.")
					return true
	return false

static func _actors(state: Dictionary,motion: Variant=null) -> void:
	var caravan: Dictionary=state.actors[0]
	var raiders: Dictionary=state.actors[3]
	raiders.active=state.mine.status=="occupied"
	for actor: Dictionary in state.actors:
		if not actor.active: continue
		if int(state.tick)<int(actor.get("wait_until",0)): continue
		var total: float=float(actor.speed)*1.3
		var budget:=total
		var legs:=0
		while budget>.00000001 and legs<64:
			legs+=1
			if not actor.has("path"): actor.path=[]
			if actor.path.is_empty(): actor.path=path_between(point(actor.position),point(actor.route[int(actor.index)]),state)
			if actor.path.is_empty(): break
			var detail: Dictionary={}
			var arrived:=_walk(actor,actor.path,budget,detail,state)
			_trace(motion,str(actor.id),detail,total-budget,total)
			budget=float(detail.remaining)
			if not arrived: break
			var index:=int(actor.index)
			if index==0 or index==actor.route.size()-1:
				# Patrols guard the end of their circuit for two campaign hours.
				# Contact remains spatial; weighted routes must not phase-lock rivals.
				if actor.kind=="patrol": actor.wait_until=int(state.tick)+8
				if actor.kind=="caravan":
					var town: String="town_ravenford" if index==0 else "saltwatch"
					if int(actor.cargo)>0:
						state.settlements[town].supply=mini(100,int(state.settlements[town].supply)+12)
						state.deliveries=int(state.deliveries)+1
						_log(state,"Caravan supplied "+str(site(town,state).name)+".")
					actor.cargo=24
				actor.direction=-int(actor.direction)
			actor.index=index+int(actor.direction)
			if int(actor.get("wait_until",0))>int(state.tick): break
	var protected := false
	for actor: Dictionary in state.actors:
		if actor.kind=="patrol" and actor.faction==caravan.faction and point(actor.position).distance_to(point(caravan.position))<.09: protected=true
	if raiders.active and not protected and int(state.tick)>=int(state.next_raid_tick) and int(caravan.cargo)>0 and point(raiders.position).distance_to(point(caravan.position))<.065:
		caravan.cargo=0
		state.raids=int(state.raids)+1
		state.next_raid_tick=int(state.tick)+24
		for town: String in ["town_ravenford","saltwatch"]:
			state.settlements[town].supply=maxi(0,int(state.settlements[town].supply)-12)
			state.settlements[town].security=maxi(0,int(state.settlements[town].security)-4)
		_log(state,"Mine raiders looted the caravan. River settlements lost supplies.")
	if raiders.active and int(state.tick)%12==0:
		for actor: Dictionary in state.actors:
			if actor.kind=="patrol" and point(actor.position).distance_to(point(raiders.position))<.08:
				state.mine.threat=maxi(20,int(state.mine.threat)-4)
				_log(state,"A patrol drove raiders away from the road. Their mine base remains.")
	if state.politics.phase=="border_war" and int(state.tick)>=int(state.politics.next_skirmish_tick) and point(state.actors[1].position).distance_to(point(state.actors[2].position))<.065:
		state.politics.next_skirmish_tick=int(state.tick)+24
		state.politics.skirmishes=int(state.politics.skirmishes)+1
		for faction: Dictionary in state.factions.values(): faction.strength=maxi(10,int(faction.strength)-2)
		state.settlements.black_keep.security=maxi(20,int(state.settlements.black_keep.security)-2)
		_log(state,"Border patrols clashed. Both factions lost strength.")

static func _politics(state: Dictionary) -> void:
	var politics: Dictionary=state.politics
	politics.tension=mini(100,int(politics.tension)+3)
	if politics.phase=="rivalry" and int(politics.tension)>=65:
		politics.phase="border_war"
		state.actors[2].route.append(state.actors[1].route.back().duplicate())
		_log(state,"River League and Iron March entered a border conflict.")

static func _offers(state: Dictionary) -> void:
	for entry: Dictionary in definition(state).contracts:
		if state.contracts.has(entry.id): continue
		var offer: bool=(entry.kind=="restoration" and state.mine.status=="occupied" and int(state.settlements.town_ravenford.supply)<60) or (entry.kind=="delivery" and int(state.settlements.saltwatch.supply)<40) or (entry.kind=="scout" and not state.intelligence)
		if offer:
			state.contracts[entry.id]={"stage":"offered"}
			_log(state,"Contract posted in %s: %s." % [site(entry.issuer,state).name,entry.name])

static func contract_availability(profile: Dictionary,id: String) -> Dictionary:
	var result := {"accept_reason":"Living-world campaign is unavailable.","report_reason":"Living-world campaign is unavailable.","progress":""}
	if not profile.has("living_world"): return result
	var entry := contract(id)
	if entry.is_empty():
		result.accept_reason="Unknown contract."
		result.report_reason="Unknown contract."
		return result
	var state: Dictionary=profile.living_world
	var stage: String=str(state.contracts.get(id,{}).get("stage","unavailable"))
	var issuer: String=str(site(entry.issuer,state).name)
	var blocked := ""
	if not profile.get("active_run",{}).is_empty() or not profile.get("world",{}).get("pending_event",{}).is_empty():
		blocked="Resolve the expedition or road encounter first."
	elif not at_site(state,entry.issuer):
		blocked="Stop at %s to accept or report this contract." % issuer
	result.accept_reason=blocked if stage=="offered" else "This contract is already accepted."
	result.report_reason=blocked
	if stage in ["completed","expired","unavailable"]:
		var reason: String={"completed":"Contract already paid.","expired":"This contract is closed.","unavailable":"This contract is not available."}[stage]
		result.accept_reason=reason
		result.report_reason=reason
		result.progress="Payment collected." if stage=="completed" else reason
	elif stage=="offered":
		result.report_reason="Accept this contract first."
		result.progress="Accept at %s." % issuer
	elif entry.kind=="delivery":
		var food: int=int(profile.supplies.food)
		result.progress="Food carried: %d/3. Deliver at %s." % [food,issuer]
		if stage!="accepted": result.report_reason="This delivery is not ready to report."
		elif blocked.is_empty() and food<3: result.report_reason="Need 3 food; carrying %d." % food
	elif stage=="objective":
		result.progress="Objective complete. Report to %s." % issuer
	else:
		result.progress="Visit %s, then report to %s." % [site(entry.target,state).name,issuer] if entry.kind=="scout" else "Clear the defended mine expedition, then report to %s." % issuer
		if blocked.is_empty(): result.report_reason="Visit %s after accepting the contract." % site(entry.target,state).name if entry.kind=="scout" else "Complete the defended mine expedition first."
	return result

static func accept(profile: Dictionary,id: String) -> bool:
	var state: Dictionary=profile.living_world
	var entry:=contract(id)
	if not str(contract_availability(profile,id).accept_reason).is_empty(): return false
	state.contracts[id].stage="accepted"
	_log(state,"Accepted: "+str(entry.name)+".")
	return true

static func report(profile: Dictionary,id: String) -> bool:
	var state: Dictionary=profile.living_world
	var entry:=contract(id)
	if not str(contract_availability(profile,id).report_reason).is_empty(): return false
	if entry.kind=="delivery":
		profile.supplies.food=int(profile.supplies.food)-3
		state.settlements.saltwatch.supply=mini(100,int(state.settlements.saltwatch.supply)+24)
	state.contracts[id].stage="completed"
	profile.gold=int(profile.gold)+int(entry.gold)
	profile.xp=int(profile.xp)+int(entry.xp)
	state.factions[entry.faction].relation=mini(100,int(state.factions[entry.faction].relation)+int(entry.relation))
	if entry.faction=="iron_march":
		state.factions.river_league.relation=maxi(-100,int(state.factions.river_league.relation)-2)
		state.politics.tension=mini(100,int(state.politics.tension)+8)
	_log(state,"Contract paid: %s (+%dg, +%d XP)." % [entry.name,int(entry.gold),int(entry.xp)])
	return true

static func expedition_result(profile: Dictionary,active: Dictionary,outcome: String) -> bool:
	if active.get("living_site","")!="dungeon_old_mine" or outcome!="completed": return false
	var combat_cleared := false
	for room: Dictionary in active.data.get("rooms",[]):
		if not active.state.get("cleared_room_ids",[]).has(room.id): continue
		for content: Dictionary in room.get("content",[]):
			if content.get("type","") in ["combat","guarded_treasure"]: combat_cleared=true
	if not combat_cleared or profile.living_world.mine.status!="occupied": return false
	var state: Dictionary=profile.living_world
	state.mine={"status":"cleared","threat":0}
	state.actors[3].active=false
	for town: String in ["town_ravenford","saltwatch"]:
		state.settlements[town].supply=mini(100,int(state.settlements[town].supply)+40)
		state.settlements[town].security=mini(100,int(state.settlements[town].security)+25)
	if state.contracts.get("restore_mine",{}).get("stage","")=="accepted": state.contracts.restore_mine.stage="objective"
	elif state.contracts.has("restore_mine"): state.contracts.restore_mine.stage="expired"
	_log(state,"Old Mine restored. Raider departures stopped; river supplies and security improved.")
	return true

static func valid_point(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["x","y"]:
		var number: Variant=value.get(key)
		if not (number is int or number is float) or not is_finite(float(number)) or number<0 or number>1: return false
	return true

static func _integer(value: Variant,minimum: int = 0,maximum: int = 1000000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=minimum and value<=maximum

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("version")!=1 or value.get("scenario")!="living_marches_v1": return false
	if value.has("geography") and (not Generator.errors(value.geography).is_empty() or not value.has("terrain_signature")): return false
	for key in ["seed","tick","encounter_until","next_raid_tick","raids","deliveries"]:
		if not _integer(value.get(key),1 if key=="seed" else 0): return false
	for key in ["party","settlements","factions","mine","politics","contracts"]:
		if not value.get(key) is Dictionary: return false
	var party: Dictionary=value.party
	if not valid_point(party.get("position")) or not party.get("path") is Array or party.path.size()>2000 or not party.get("camping") is bool or not _integer(party.get("fatigue"),0,100): return false
	var current_terrain: bool=value.get("terrain_signature","")==navigation(value).signature
	if value.has("terrain_signature") and (not value.terrain_signature is String or value.terrain_signature.length()!=64): return false
	if value.has("terrain_signature"):
		for character in value.terrain_signature:
			if not "0123456789abcdef".contains(character): return false
	if current_terrain and not passable(point(party.position),value): return false
	if not value.has("terrain_signature") and not legacy_land(point(party.position)): return false
	if party.camping and not party.path.is_empty(): return false
	if not party.get("goal") is String or (party.goal!="" and site(party.goal,value).is_empty()): return false
	for entry in party.path:
		if not valid_point(entry): return false
		if current_terrain and not passable(point(entry),value): return false
	if value.settlements.keys().size()!=3 or value.factions.keys().size()!=2: return false
	for id: String in ["town_ravenford","saltwatch","black_keep"]:
		if not value.settlements.get(id) is Dictionary: return false
		for key in ["supply","security"]:
			if not _integer(value.settlements[id].get(key),0,100): return false
	for id: String in ["river_league","iron_march"]:
		if not value.factions.get(id) is Dictionary or not _integer(value.factions[id].get("relation"),-100,100) or not _integer(value.factions[id].get("strength"),0,100): return false
	if value.mine.get("status") not in ["occupied","cleared"] or not _integer(value.mine.get("threat"),0,100): return false
	if value.mine.status=="cleared" and value.mine.threat!=0: return false
	if value.politics.get("phase") not in ["rivalry","border_war"] or not _integer(value.politics.get("tension"),0,100) or not _integer(value.politics.get("skirmishes")): return false
	if not _integer(value.politics.get("next_skirmish_tick")): return false
	if not value.get("intelligence") is bool or not value.get("actors") is Array or value.actors.size()!=4 or not value.get("journal") is Array or value.journal.size()>24: return false
	var ids: Array[String]=[]
	for actor in value.actors:
		if not actor is Dictionary or actor.get("id") not in ["caravan","league_patrol","iron_patrol","mine_raiders"] or ids.has(str(actor.id)): return false
		ids.append(str(actor.id))
		if not valid_point(actor.get("position")) or not actor.get("route") is Array or actor.route.size()<2 or actor.route.size()>32: return false
		for position in actor.route:
			if not valid_point(position): return false
		if current_terrain and not passable(point(actor.position),value): return false
		if actor.has("path"):
			if not actor.path is Array or actor.path.size()>2000: return false
			for position in actor.path:
				if not valid_point(position) or (current_terrain and not passable(point(position),value)): return false
		if actor.has("wait_until") and not _integer(actor.wait_until): return false
		if not _integer(actor.get("index"),0,actor.route.size()-1) or not _integer(actor.get("direction"),-1,1) or int(actor.direction)==0 or not actor.get("active") is bool or not _integer(actor.get("cargo"),0,24): return false
		var speed: Variant=actor.get("speed")
		if not (speed is int or speed is float) or not is_finite(float(speed)) or speed<=0 or speed>.05: return false
		if actor.get("kind") not in ["caravan","patrol","raiders"] or actor.get("faction") not in ["river_league","iron_march","bandits"]: return false
	if ids != ["caravan","league_patrol","iron_patrol","mine_raiders"]: return false
	for id in value.contracts:
		if not id is String or contract(id).is_empty() or not value.contracts[id] is Dictionary or value.contracts[id].get("stage") not in ["offered","accepted","objective","completed","expired"]: return false
	for entry in value.journal:
		if not entry is Dictionary or not _integer(entry.get("tick"),0,int(value.tick)) or not entry.get("text") is String or entry.text.length()>500: return false
	return true
