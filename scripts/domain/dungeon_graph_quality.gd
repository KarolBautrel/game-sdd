extends RefCounted


static func errors(graph: Dictionary, deep: bool = false) -> Array[String]:
	var failures: Array[String] = []
	var rooms: Dictionary = {}
	var positions: Dictionary = {}
	var entrance := ""
	var exits := 0
	var combats := 0
	var treasures := 0
	for room: Dictionary in graph.get("rooms", []):
		var id := str(room.get("id", ""))
		if id == "" or rooms.has(id): failures.append("Duplicate/missing room id: %s" % id)
		rooms[id] = []
		var point: Dictionary = room.get("position", {})
		var position := "%s,%s" % [point.get("x", "?"), point.get("y", "?")]
		if positions.has(position): failures.append("Overlapping room position: %s" % position)
		positions[position] = true
		if room.get("kind") == "entrance":
			if entrance != "": failures.append("Multiple entrances")
			entrance = id
		if room.get("kind") == "exit": exits += 1
		for content: Dictionary in room.get("content", []):
			if content.get("type") in ["combat", "guarded_treasure"]: combats += 1
			if content.get("type") in ["treasure", "guarded_treasure"]: treasures += 1
	if entrance == "" or exits == 0: failures.append("Entrance and exit required")
	if combats < (3 if deep else 1) or treasures < 1: failures.append("Missing required combat/treasure pacing")
	var edges: Dictionary = {}
	var edge_ids: Dictionary = {}
	for corridor: Dictionary in graph.get("corridors", []):
		var from := str(corridor.get("from", ""))
		var to := str(corridor.get("to", ""))
		var id := str(corridor.get("id", ""))
		var pair := [from, to]
		pair.sort()
		var edge := "|".join(pair)
		if from == to or not rooms.has(from) or not rooms.has(to) or edges.has(edge) or edge_ids.has(id):
			failures.append("Invalid/duplicate corridor: %s" % id)
			continue
		edges[edge] = true
		edge_ids[id] = true
		rooms[from].append(to)
		rooms[to].append(from)
	var visited: Dictionary = {}
	var queue: Array = [entrance] if entrance != "" else []
	while not queue.is_empty():
		var id := str(queue.pop_front())
		if visited.has(id): continue
		visited[id] = true
		queue.append_array(rooms.get(id, []))
	if visited.size() != rooms.size(): failures.append("Disconnected rooms")
	return failures
