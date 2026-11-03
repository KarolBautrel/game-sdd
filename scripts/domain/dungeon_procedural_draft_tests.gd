extends SceneTree

const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")


func _init() -> void:
	var errors: Array[String] = []
	var easy: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": 102, "difficulty": 1})
	var easy_again: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": 102, "difficulty": 1})
	var easy_other_seed: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": 103, "difficulty": 1})
	var medium: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": 102, "difficulty": 2})
	var hard: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": 102, "difficulty": 3})
	var short_profile: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": 102, "profile_id": "short_mine"})
	var deep_profile: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": 102, "profile_id": "deep_mine"})
	var twin_seed_a: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": 101, "difficulty": 2})
	var twin_seed_b: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": 103, "difficulty": 2})

	_expect_equal(errors, "generated dungeon id", easy["id"], "generated_old_mine_draft")
	_expect_equal(errors, "generated start room", easy["start_room_id"], "generated_entrance")
	_expect_equal(errors, "same seed graph signature", _graph_signature(easy), _graph_signature(easy_again))
	_expect_equal(errors, "same seed combat encounter signature", _combat_encounter_signature(easy), _combat_encounter_signature(easy_again))
	_expect_not_equal(errors, "different seed graph signature", _graph_signature(easy), _graph_signature(easy_other_seed))
	_expect_not_equal(errors, "different seed hazard placement", _hazard_signature(twin_seed_a), _hazard_signature(twin_seed_b))
	_expect_true(errors, "hazard type can swap on same corridor", _has_hazard_type_swap_across_seeds(2))
	_expect_true(errors, "medium has at least easy rooms", medium["rooms"].size() >= easy["rooms"].size())
	_expect_true(errors, "hard has at least medium rooms", hard["rooms"].size() >= medium["rooms"].size())
	_expect_equal(errors, "short profile id", short_profile["generated_profile"]["id"], "short_mine")
	_expect_equal(errors, "deep profile id", deep_profile["generated_profile"]["id"], "deep_mine")
	_expect_equal(errors, "deep profile light budget", deep_profile["max_light_level"], 5)
	_expect_true(errors, "deep profile capacity larger than short", int(deep_profile["supply_loadout_capacity"]) > int(short_profile["supply_loadout_capacity"]))
	_expect_true(errors, "generated exposes template id", str(short_profile.get("template_id", "")) != "")
	_expect_true(errors, "generated exposes template display name", str(short_profile.get("template_display_name", "")) != "")
	_expect_true(errors, "generated exposes template pacing", not short_profile.get("template_pacing", {}).is_empty())
	_expect_true(errors, "short profile has template variety", _selected_template_count_for_profile("short_mine") >= 3)
	_expect_true(errors, "medium profile has template variety", _selected_template_count_for_profile("medium_mine") >= 3)
	_expect_true(errors, "deep profile has template variety", _selected_template_count_for_profile("deep_mine") >= 3)
	_expect_true(errors, "deep profile has three combat rooms", _combat_room_count(deep_profile) >= 3)
	_expect_true(errors, "deep profile has long route span", max(_room_position_span(deep_profile, "x"), _room_position_span(deep_profile, "y")) >= 6)
	_expect_true(errors, "generated has treasure", _has_room_kind(easy, "treasure"))
	_expect_true(errors, "generated has combat", _has_room_kind(easy, "combat"))
	_expect_true(errors, "generated has exit", _has_room_kind(easy, "exit"))
	_expect_true(errors, "generated has hazard pool refs", _has_any_hazard_pool_ref(easy))
	_expect_true(errors, "generated has room event pool refs", _has_any_room_event_pool_ref(easy))
	_expect_true(errors, "generated combat has selected encounter path", _all_combat_content_has_encounter_path(easy))
	_expect_true(errors, "generated combat has encounter selection metadata", _all_generated_combat_has_selection_metadata(easy))
	_expect_true(errors, "generated encounter pool can select three paths", _selected_encounter_path_count_for_profile("medium_mine") >= 3)
	_expect_true(errors, "deep multi-combat rooms use different encounter paths", _combat_room_paths_are_unique_until_pool_exhausted(deep_profile, 2))
	_expect_not_equal(errors, "different seed room event placement", _room_event_signature(twin_seed_a), _room_event_signature(twin_seed_b))
	_expect_true(errors, "generated has rubble pool", _hazard_signature(easy).contains("old_mine_rubble_pool"))
	_expect_true(errors, "generated has trap pool", _hazard_signature(easy).contains("old_mine_trap_pool"))

	if not errors.is_empty():
		for error: String in errors:
			push_error(error)
		quit(1)
		return
	var state := DungeonStateModel.initial_state(easy)
	_expect_equal(errors, "initial generated room", state["current_room_id"], "generated_entrance")
	var combat_room_id := _first_room_kind(easy, "combat")
	state = _enter_path_to_room(errors, easy, state, combat_room_id)
	_expect_equal(errors, "generated current combat room", state["current_room_id"], combat_room_id)
	_expect_equal(errors, "generated combat room", state["pending_combat_request"]["room_id"], combat_room_id)
	_expect_true(errors, "generated pending combat has selection metadata", not state["pending_combat_request"].get("combat_encounter_selection", {}).is_empty())

	if errors.is_empty():
		print("Dungeon procedural draft validation passed.")
	else:
		for error: String in errors:
			push_error(error)
		quit(1)
		return
	quit(0)


func _enter_path_to_room(errors: Array[String], dungeon: Dictionary, state: Dictionary, target_room_id: String) -> Dictionary:
	var path := _path_to_room(dungeon, str(state.get("current_room_id", "")), target_room_id)
	for next_id: String in path:
		var result: Dictionary = DungeonStateModel.enter_room(dungeon, state, next_id)
		if result["status"] == "choice_required":
			result = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, result["state"], "force_passage")
		if result["status"] != "accepted":
			errors.append("generated route traversal: expected accepted, got %s" % result["status"])
			return state
		state = result["state"]
		if not state.get("pending_room_event", {}).is_empty():
			state = DungeonStateModel.resolve_room_event_choice(dungeon, state, "ignore")["state"]
	return state


func _path_to_room(dungeon: Dictionary, start_room_id: String, target_room_id: String) -> Array[String]:
	var frontier: Array[Array] = [[start_room_id]]
	var visited := {}
	while not frontier.is_empty():
		var path: Array = frontier.pop_front()
		var current_id := str(path[path.size() - 1])
		if current_id == target_room_id:
			var result: Array[String] = []
			for index in range(1, path.size()):
				result.append(str(path[index]))
			return result
		if visited.has(current_id):
			continue
		visited[current_id] = true
		for neighbor_id: String in _neighbor_room_ids(dungeon, current_id):
			if visited.has(neighbor_id):
				continue
			var next_path := path.duplicate()
			next_path.append(neighbor_id)
			frontier.append(next_path)
	return []


func _neighbor_room_ids(dungeon: Dictionary, room_id: String) -> Array[String]:
	var neighbors: Array[String] = []
	for corridor: Dictionary in dungeon.get("corridors", []):
		if str(corridor.get("from", "")) == room_id:
			neighbors.append(str(corridor.get("to", "")))
		elif str(corridor.get("to", "")) == room_id:
			neighbors.append(str(corridor.get("from", "")))
	return neighbors


func _corridor_to_room(dungeon: Dictionary, room_id: String) -> Dictionary:
	for corridor: Dictionary in dungeon.get("corridors", []):
		if str(corridor.get("to", "")) == room_id:
			return corridor
	return {}


func _graph_signature(dungeon: Dictionary) -> String:
	var parts: Array[String] = []
	for room: Dictionary in dungeon.get("rooms", []):
		var position: Dictionary = room.get("position", {})
		parts.append("%s:%s:%s:%s" % [room.get("id", ""), room.get("kind", ""), position.get("x", 0), position.get("y", 0)])
	for corridor: Dictionary in dungeon.get("corridors", []):
		parts.append("%s:%s:%s:%s" % [corridor.get("id", ""), corridor.get("from", ""), corridor.get("to", ""), corridor.get("danger", 0.0)])
	return "|".join(parts)


func _hazard_signature(dungeon: Dictionary) -> String:
	var parts: Array[String] = []
	for corridor: Dictionary in dungeon.get("corridors", []):
		for hazard_pool_ref: Dictionary in corridor.get("hazard_pool_refs", []):
			parts.append("%s:%s" % [corridor.get("id", ""), hazard_pool_ref.get("pool_id", "")])
	return "|".join(parts)


func _room_event_signature(dungeon: Dictionary) -> String:
	var parts: Array[String] = []
	for room: Dictionary in dungeon.get("rooms", []):
		for content: Dictionary in room.get("content", []):
			if str(content.get("type", "")) == "room_event":
				parts.append("%s:%s:%s" % [room.get("id", ""), content.get("id", ""), content.get("room_event_pool_id", content.get("event_id", ""))])
	return "|".join(parts)


func _combat_encounter_signature(dungeon: Dictionary) -> String:
	var parts: Array[String] = []
	for room: Dictionary in dungeon.get("rooms", []):
		for content: Dictionary in room.get("content", []):
			if str(content.get("type", "")) in ["combat", "guarded_treasure"]:
				parts.append("%s:%s:%s" % [room.get("id", ""), content.get("combat_encounter_path", ""), content.get("combat_encounter_selection", {}).get("entry_id", "")])
	return "|".join(parts)


func _has_room_kind(dungeon: Dictionary, kind: String) -> bool:
	for room: Dictionary in dungeon.get("rooms", []):
		if str(room.get("kind", "")) == kind:
			return true
	return false


func _first_room_kind(dungeon: Dictionary, kind: String) -> String:
	for room: Dictionary in dungeon.get("rooms", []):
		if str(room.get("kind", "")) == kind:
			return str(room.get("id", ""))
	return ""


func _combat_room_count(dungeon: Dictionary) -> int:
	var count := 0
	for room: Dictionary in dungeon.get("rooms", []):
		if str(room.get("kind", "")) == "combat":
			count += 1
	return count


func _room_position_span(dungeon: Dictionary, axis: String) -> int:
	var first := true
	var minimum := 0
	var maximum := 0
	for room: Dictionary in dungeon.get("rooms", []):
		var position: Dictionary = room.get("position", {})
		var value := int(position.get(axis, 0))
		if first:
			minimum = value
			maximum = value
			first = false
		else:
			minimum = mini(minimum, value)
			maximum = maxi(maximum, value)
	return maximum - minimum


func _has_any_hazard_pool_ref(dungeon: Dictionary) -> bool:
	for corridor: Dictionary in dungeon.get("corridors", []):
		if not corridor.get("hazard_pool_refs", []).is_empty():
			return true
	return false


func _has_any_room_event_pool_ref(dungeon: Dictionary) -> bool:
	for room: Dictionary in dungeon.get("rooms", []):
		for content: Dictionary in room.get("content", []):
			if str(content.get("type", "")) == "room_event" and str(content.get("room_event_pool_id", "")) != "":
				return true
	return false


func _all_combat_content_has_encounter_path(dungeon: Dictionary) -> bool:
	for room: Dictionary in dungeon.get("rooms", []):
		for content: Dictionary in room.get("content", []):
			if str(content.get("type", "")) in ["combat", "guarded_treasure"] and str(content.get("combat_encounter_path", "")) == "":
				return false
	return true


func _all_generated_combat_has_selection_metadata(dungeon: Dictionary) -> bool:
	for room: Dictionary in dungeon.get("rooms", []):
		for content: Dictionary in room.get("content", []):
			if str(content.get("type", "")) in ["combat", "guarded_treasure"] and str(content.get("combat_encounter_pool_id", "")) != "":
				if content.get("combat_encounter_selection", {}).is_empty():
					return false
	return true


func _has_hazard_type_swap_across_seeds(difficulty: int) -> bool:
	var pools_by_layout_and_corridor := {}
	for seed in range(100, 140):
		var dungeon: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": seed, "difficulty": difficulty})
		var layout_id := _graph_signature(dungeon)
		if not pools_by_layout_and_corridor.has(layout_id):
			pools_by_layout_and_corridor[layout_id] = {}
		var pools_by_corridor: Dictionary = pools_by_layout_and_corridor[layout_id]
		for corridor: Dictionary in dungeon.get("corridors", []):
			for hazard_pool_ref: Dictionary in corridor.get("hazard_pool_refs", []):
				var corridor_id := str(corridor.get("id", ""))
				var pool_id := str(hazard_pool_ref.get("pool_id", ""))
				if not pools_by_corridor.has(corridor_id):
					pools_by_corridor[corridor_id] = []
				if not pools_by_corridor[corridor_id].has(pool_id):
					pools_by_corridor[corridor_id].append(pool_id)
				if pools_by_corridor[corridor_id].has("old_mine_rubble_pool") and pools_by_corridor[corridor_id].has("old_mine_trap_pool"):
					return true
	return false


func _selected_template_count_for_profile(profile_id: String) -> int:
	var selected := {}
	for seed in range(100, 160):
		var dungeon: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": seed, "profile_id": profile_id})
		var template_id := str(dungeon.get("template_id", ""))
		if template_id != "":
			selected[template_id] = true
	return selected.size()


func _selected_encounter_path_count_for_profile(profile_id: String) -> int:
	var selected := {}
	for seed in range(100, 180):
		var dungeon: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": seed, "profile_id": profile_id})
		for room: Dictionary in dungeon.get("rooms", []):
			for content: Dictionary in room.get("content", []):
				if str(content.get("type", "")) in ["combat", "guarded_treasure"]:
					var encounter_path := str(content.get("combat_encounter_path", ""))
					if encounter_path != "":
						selected[encounter_path] = true
	return selected.size()


func _combat_room_paths_are_unique_until_pool_exhausted(dungeon: Dictionary, unique_pool_path_count: int) -> bool:
	var paths: Array[String] = []
	for room: Dictionary in dungeon.get("rooms", []):
		for content: Dictionary in room.get("content", []):
			if str(content.get("type", "")) in ["combat", "guarded_treasure"]:
				var encounter_path := str(content.get("combat_encounter_path", ""))
				if encounter_path == "":
					return false
				if paths.has(encounter_path) and paths.size() < unique_pool_path_count:
					return false
				paths.append(encounter_path)
	return paths.size() <= 1 or paths.size() == _unique_string_count(paths)


func _unique_string_count(values: Array[String]) -> int:
	var seen := {}
	for value: String in values:
		seen[value] = true
	return seen.size()


func _expect_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		errors.append("%s: expected %s, got %s" % [label, expected, actual])


func _expect_not_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual == expected:
		errors.append("%s: expected different values, got %s" % [label, actual])


func _expect_true(errors: Array[String], label: String, value: bool) -> void:
	if not value:
		errors.append("%s: expected true" % label)
