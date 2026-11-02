extends RefCounted
## Pure route quotes and validation; CampaignSession owns commits.

const REGION_PATH := "res://resources/data/world_regions/region_001.json"
const EVENTS_PATH := "res://resources/data/world_events/catalogue.json"
const NAMES := {"town_ravenford":"Ravenford", "dungeon_old_mine":"Old Mine", "event_broken_cart":"Broken Cart"}


static func region() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGION_PATH))
	return data if data is Dictionary else {}


static func node_name(id: String) -> String:
	return NAMES.get(id, id.replace("_", " ").capitalize())


static func node(data: Dictionary, id: String) -> Dictionary:
	for entry: Dictionary in data.get("nodes", []):
		if str(entry.get("id", "")) == id:
			return entry
	return {}


static func routes(data: Dictionary, from: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for edge: Dictionary in data.get("edges", []):
		var to := ""
		if edge.get("from") == from:
			to = str(edge.to)
		elif edge.get("to") == from:
			to = str(edge.from)
		if not to.is_empty():
			result.append({"from":from,"to":to,"time_hours":int(edge.travel_cost.time_hours),"food":int(edge.travel_cost.food),"danger":float(edge.danger)})
	return result


static func return_food(data: Dictionary, from: String) -> int:
	var best := {from:0}
	var pending: Array[String] = [from]
	while not pending.is_empty():
		pending.sort_custom(func(a: String, b: String) -> bool: return int(best[a]) < int(best[b]))
		var current: String = pending.pop_front()
		if node(data, current).get("type", "") == "town":
			return int(best[current])
		for route: Dictionary in routes(data, current):
			var cost := int(best[current]) + int(route.food)
			if not best.has(route.to) or cost < int(best[route.to]):
				best[route.to] = cost
				pending.append(route.to)
	return 1000000000


static func quote(world: Dictionary, destination: String) -> Dictionary:
	var data := region()
	for route: Dictionary in routes(data, str(world.get("location_id", ""))):
		if route.to == destination:
			route.return_food = return_food(data, destination)
			return route
	return {}


static func clock_text(world: Dictionary) -> String:
	var hours := int(world.get("elapsed_hours", 0)) + 8
	return "Day %s  %02d:00" % [1 + hours / 24, hours % 24]


static func valid(world: Variant) -> bool:
	if not world is Dictionary:
		return false
	var data := region()
	if world.get("region_id") != data.get("id") or node(data, str(world.get("location_id", ""))).is_empty():
		return false
	for key in ["elapsed_hours", "journey_count", "seed"]:
		var value: Variant = world.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > 1000000000 or float(value) != floor(float(value)):
			return false
	if not world.get("pending_event") is Dictionary or not world.get("resolved_nodes") is Array or not valid_pending(world) or not world.get("last_journey") is Dictionary:
		return false
	var seen: Dictionary = {}
	for id in world.resolved_nodes:
		if not id is String or seen.has(id) or node(data, id).is_empty():
			return false
		seen[id] = true
	return true


static func event_definitions() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	return data if data is Dictionary else {}


static func pending_for(world: Dictionary, route: Dictionary) -> Dictionary:
	var seed := 1 + posmod(int(world.seed) + int(world.journey_count) * 104729, 999999999)
	var kind := ""
	if route.to == "event_broken_cart" and not world.resolved_nodes.has(route.to):
		kind = "cart"
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		if rng.randf() < float(route.danger):
			kind = "ambush"
	if kind.is_empty():
		return {}
	return {"id":"road_%s" % int(world.journey_count),"kind":kind,"phase":"choice","seed":seed,"node_id":route.to,"journey_id":int(world.journey_count)}


static func valid_pending(world: Dictionary) -> bool:
	var pending: Dictionary = world.pending_event
	if pending.is_empty():
		return true
	if int(world.journey_count) < 1:
		return false
	if pending.get("kind") not in ["cart", "ambush"] or pending.get("phase") not in ["choice", "combat"] or pending.get("node_id") != world.location_id or pending.get("journey_id") != world.journey_count or pending.get("id") != "road_%s" % int(world.journey_count):
		return false
	var seed: Variant = pending.get("seed")
	if not (seed is int or seed is float) or not is_finite(float(seed)) or seed < 1 or seed > 1000000000 or float(seed) != floor(float(seed)):
		return false
	if int(seed) != 1 + posmod(int(world.seed) + int(world.journey_count) * 104729, 999999999):
		return false
	return pending.kind != "cart" or (pending.node_id == "event_broken_cart" and pending.phase == "choice" and not world.get("resolved_nodes", []).has(pending.node_id))
