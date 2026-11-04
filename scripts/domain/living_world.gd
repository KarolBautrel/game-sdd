extends RefCounted
## Pure living-region rules. Call only on CampaignSession transaction candidates.
const PATH := "res://resources/data/world_simulations/living_marches_v1.json"
static var cached_definition: Dictionary = {}

static func definition() -> Dictionary:
	if cached_definition.is_empty(): cached_definition=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return cached_definition

static func point(value: Dictionary) -> Vector2:
	return Vector2(float(value.x),float(value.y))

static func packed(value: Vector2) -> Dictionary:
	return {"x":value.x,"y":value.y}

static func site(id: String) -> Dictionary:
	for entry: Dictionary in definition().sites:
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

static func passable(position: Vector2,data: Dictionary = {}) -> bool:
	if data.is_empty(): data=definition()
	if not position.is_finite() or not Geometry2D.is_point_in_polygon(position,_polygon(data.land)): return false
	for polygon: Array in data.blocked:
		if Geometry2D.is_point_in_polygon(position,_polygon(polygon)): return false
	return true

static func terrain_cost(position: Vector2,data: Dictionary) -> float:
	for road: Array in data.roads:
		for index in range(1,road.size()):
			if position.distance_to(Geometry2D.get_closest_point_to_segment(position,point(road[index-1]),point(road[index]))) < .026: return 1.0
	return 2.2 if position.x < .46 and position.y < .55 else 1.5

static func path_between(start: Vector2,destination: Vector2) -> Array[Dictionary]:
	var data := definition()
	var result: Array[Dictionary] = []
	if not passable(start,data) or not passable(destination,data): return result
	var dimensions := Vector2i(int(data.grid.width),int(data.grid.height))
	var nav := AStarGrid2D.new()
	nav.region=Rect2i(Vector2i.ZERO,dimensions)
	nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			var cell := Vector2i(x,y)
			var center := (Vector2(cell)+Vector2(.5,.5))/Vector2(dimensions)
			nav.set_point_solid(cell,not passable(center,data))
			nav.set_point_weight_scale(cell,terrain_cost(center,data))
	var from := Vector2i(start*Vector2(dimensions)).clamp(Vector2i.ZERO,dimensions-Vector2i.ONE)
	var to := Vector2i(destination*Vector2(dimensions)).clamp(Vector2i.ZERO,dimensions-Vector2i.ONE)
	if nav.is_point_solid(from) or nav.is_point_solid(to): return result
	var cells := nav.get_id_path(from,to)
	if cells.is_empty(): return result
	for index in range(1,cells.size()): result.append(packed((Vector2(cells[index])+Vector2(.5,.5))/Vector2(dimensions)))
	result.append(packed(destination))
	return result

static func _actor(id: String,kind: String,faction: String,route: Array,speed: float) -> Dictionary:
	return {"id":id,"kind":kind,"faction":faction,"position":route[0].duplicate(),"route":route.duplicate(true),"index":1,"direction":1,"speed":speed,"cargo":24 if kind=="caravan" else 0,"active":true}

static func initial(seed: int,elapsed_hours: int = 0) -> Dictionary:
	var data := definition()
	var result := {"version":1,"scenario":str(data.id),"seed":seed,"tick":elapsed_hours*4,
		"party":{"position":site("town_ravenford").position.duplicate(),"path":[],"goal":"","camping":false,"fatigue":0},
		"settlements":{"town_ravenford":{"supply":30,"security":45},"saltwatch":{"supply":28,"security":40},"black_keep":{"supply":65,"security":65}},
		"factions":{"river_league":{"relation":0,"strength":80},"iron_march":{"relation":0,"strength":80}},
		"mine":{"status":"occupied","threat":70},"politics":{"tension":55,"phase":"rivalry","skirmishes":0,"next_skirmish_tick":0},
		"contracts":{},"intelligence":false,"encounter_until":0,"next_raid_tick":0,"raids":0,"deliveries":0,"journal":[],
		"actors":[_actor("caravan","caravan","river_league",data.roads[0],.014),
			_actor("league_patrol","patrol","river_league",[data.sites[0].position,{"x":.35,"y":.65},{"x":.46,"y":.65}],.018),
			_actor("iron_patrol","patrol","iron_march",[{"x":.75,"y":.20},{"x":.74,"y":.43},{"x":.66,"y":.62}],.018),
			_actor("mine_raiders","raiders","bandits",[{"x":.4,"y":.78},{"x":.46,"y":.65},{"x":.55,"y":.62}],.022)]}
	_log(result,"Ore deliveries have stopped. Raiders occupy the Old Mine.")
	_offers(result)
	return result

static func _log(state: Dictionary,message: String) -> void:
	state.journal.append({"tick":int(state.tick),"text":message})
	while state.journal.size()>24: state.journal.pop_front()

static func at_site(state: Dictionary,id: String) -> bool:
	var entry := site(id)
	return not entry.is_empty() and state.party.path.is_empty() and point(state.party.position).distance_to(point(entry.position))<=.022

static func current_site(state: Dictionary) -> String:
	for entry: Dictionary in definition().sites:
		if at_site(state,entry.id): return str(entry.id)
	return ""

static func at_town(state: Dictionary) -> bool:
	return site(current_site(state)).get("kind","") == "town"

static func food_price(state: Dictionary) -> int:
	var town := current_site(state)
	return 2 if state.settlements.has(town) and int(state.settlements[town].supply)<40 else 1

static func course(profile: Dictionary,destination: Vector2,goal: String = "") -> bool:
	var state: Dictionary=profile.living_world
	if not goal.is_empty():
		if site(goal).is_empty(): return false
		destination=point(site(goal).position)
	var route:=path_between(point(state.party.position),destination)
	if route.is_empty(): return false
	state.party.path=route
	state.party.goal=goal
	state.party.camping=false
	return true

static func _walk(unit: Dictionary,path: Array,distance: float) -> bool:
	var position:=point(unit.position)
	while distance>0 and not path.is_empty():
		var target:=point(path[0])
		var length:=position.distance_to(target)
		if length<=distance:
			position=target
			distance-=length
			path.pop_front()
		else:
			position=position.move_toward(target,distance)
			distance=0
	unit.position=packed(position)
	return path.is_empty()

static func advance(profile: Dictionary,ticks: int,inside: bool = false) -> bool:
	var state: Dictionary=profile.living_world
	var data:=definition()
	for iteration in range(ticks):
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
				var speed:=.035/(terrain_cost(point(state.party.position),data)*(1.0+float(state.party.fatigue)/200.0))
				if int(profile.supplies.food)==0: speed*=.65
				if _walk(state.party,state.party.path,speed):
					var arrival:=str(state.party.goal)
					if arrival.is_empty(): arrival=current_site(state)
					if not arrival.is_empty():
						profile.world.location_id=arrival
						_log(state,"Arrived at "+str(site(arrival).name)+".")
						if arrival=="high_pass" and state.contracts.get("scout_pass",{}).get("stage","")=="accepted":
							state.contracts.scout_pass.stage="objective"
							state.intelligence=true
							_log(state,"High Pass surveyed. Report to Black Keep.")
					state.party.goal=""
				state.party.fatigue=mini(100,int(state.party.fatigue)+1)
		_actors(state)
		if int(state.tick)%96==0: _politics(state)
		_offers(state)
		if not inside and not state.party.path.is_empty() and int(state.tick)>=int(state.encounter_until):
			for actor: Dictionary in state.actors:
				if actor.kind=="raiders" and actor.active and point(actor.position).distance_to(point(state.party.position))<.035:
					state.encounter_until=int(state.tick)+32
					_log(state,"Mine raiders intercepted the company.")
					return true
	return false

static func _actors(state: Dictionary) -> void:
	var caravan: Dictionary=state.actors[0]
	var raiders: Dictionary=state.actors[3]
	raiders.active=state.mine.status=="occupied"
	for actor: Dictionary in state.actors:
		if not actor.active: continue
		var route: Array=[actor.route[int(actor.index)]]
		if _walk(actor,route,float(actor.speed)):
			var index:=int(actor.index)
			if index==0 or index==actor.route.size()-1:
				if actor.kind=="caravan":
					var town: String="town_ravenford" if index==0 else "saltwatch"
					if int(actor.cargo)>0:
						state.settlements[town].supply=mini(100,int(state.settlements[town].supply)+12)
						state.deliveries=int(state.deliveries)+1
						_log(state,"Caravan supplied "+str(site(town).name)+".")
					actor.cargo=24
				actor.direction=-int(actor.direction)
			actor.index=index+int(actor.direction)
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
	for entry: Dictionary in definition().contracts:
		if state.contracts.has(entry.id): continue
		var offer: bool=(entry.kind=="restoration" and state.mine.status=="occupied" and int(state.settlements.town_ravenford.supply)<60) or (entry.kind=="delivery" and int(state.settlements.saltwatch.supply)<40) or (entry.kind=="scout" and not state.intelligence)
		if offer:
			state.contracts[entry.id]={"stage":"offered"}
			_log(state,"Contract posted in %s: %s." % [site(entry.issuer).name,entry.name])

static func accept(profile: Dictionary,id: String) -> bool:
	var state: Dictionary=profile.living_world
	var entry:=contract(id)
	if entry.is_empty() or not at_site(state,entry.issuer) or state.contracts.get(id,{}).get("stage","")!="offered": return false
	state.contracts[id].stage="accepted"
	_log(state,"Accepted: "+str(entry.name)+".")
	return true

static func report(profile: Dictionary,id: String) -> bool:
	var state: Dictionary=profile.living_world
	var entry:=contract(id)
	if entry.is_empty() or not at_site(state,entry.issuer): return false
	var stage: String=str(state.contracts.get(id,{}).get("stage",""))
	if entry.kind=="delivery":
		if stage!="accepted" or int(profile.supplies.food)<3: return false
		profile.supplies.food=int(profile.supplies.food)-3
		state.settlements.saltwatch.supply=mini(100,int(state.settlements.saltwatch.supply)+24)
	elif stage!="objective": return false
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
	for key in ["seed","tick","encounter_until","next_raid_tick","raids","deliveries"]:
		if not _integer(value.get(key),1 if key=="seed" else 0): return false
	for key in ["party","settlements","factions","mine","politics","contracts"]:
		if not value.get(key) is Dictionary: return false
	var party: Dictionary=value.party
	if not valid_point(party.get("position")) or not party.get("path") is Array or party.path.size()>2000 or not party.get("camping") is bool or not _integer(party.get("fatigue"),0,100): return false
	if not passable(point(party.position)) or (party.camping and not party.path.is_empty()): return false
	if not party.get("goal") is String or (party.goal!="" and site(party.goal).is_empty()): return false
	for entry in party.path:
		if not valid_point(entry): return false
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
