extends RefCounted
class_name CombatResolver


static func simulate(encounter: Dictionary, commands: Array) -> Dictionary:
	var state: Dictionary = encounter.duplicate(true)
	state["event_log"] = []
	var sequence := 1

	sequence = _emit(state, sequence, "combat_started", {})
	sequence = _emit(state, sequence, "turn_started", {
		"actor_id": state["turn_state"]["active_unit_id"],
		"round": state["turn_state"]["round"],
	})

	for command: Dictionary in commands:
		sequence = _resolve_command(state, command, sequence)

	return {
		"state": state,
		"result": _combat_result(state),
	}


static func choose_enemy_command(state: Dictionary, command_id: String = "cmd_ai_001") -> Dictionary:
	var actor := _unit_by_id(state, state["turn_state"]["active_unit_id"])
	if actor.is_empty() or actor["team"] != "enemy":
		return _end_turn_command(state["turn_state"]["active_unit_id"], command_id)

	var adjacent_player := _adjacent_living_enemy(state, actor, "player")
	if not adjacent_player.is_empty() and actor["resources"]["ap"] >= 1 and actor["available_actions"].has("basic_attack"):
		return {
			"id": command_id,
			"type": "perform_action",
			"actor_id": actor["id"],
			"action_id": "basic_attack",
			"target": {
				"type": "unit",
				"unit_id": adjacent_player["id"],
			},
		}

	var nearest_player := _nearest_living_enemy(state, actor, "player")
	var move_target := _best_step_toward(state, actor, nearest_player) if not nearest_player.is_empty() else {}
	if not move_target.is_empty() and actor["resources"]["ap"] >= 1 and actor["available_actions"].has("move"):
		return {
			"id": command_id,
			"type": "perform_action",
			"actor_id": actor["id"],
			"action_id": "move",
			"target": {
				"type": "tile",
				"position": move_target,
			},
		}

	return _end_turn_command(actor["id"], command_id)


static func _resolve_command(state: Dictionary, command: Dictionary, sequence: int) -> int:
	if command["type"] != "perform_action":
		return _reject(state, sequence, command, "unsupported_command_type")

	match command["action_id"]:
		"basic_attack":
			return _resolve_basic_attack(state, command, sequence)
		"move":
			return _resolve_move(state, command, sequence)
		"defend":
			return _resolve_defend(state, command, sequence)
		"end_turn":
			return _resolve_end_turn(state, command, sequence)
		_:
			return _reject(state, sequence, command, "unsupported_action")


static func _resolve_basic_attack(state: Dictionary, command: Dictionary, sequence: int) -> int:
	var actor := _unit_by_id(state, command["actor_id"])
	var target := _unit_by_id(state, command["target"].get("unit_id", ""))

	var rejection := _basic_attack_rejection(state, actor, target)
	if rejection != "":
		return _reject(state, sequence, command, rejection)

	actor["resources"]["ap"] -= 1
	var damage: int = max(1, actor["stats"]["strength"] - target["stats"]["defense"])
	var old_hp: int = target["resources"]["hp"]
	target["resources"]["hp"] = max(0, old_hp - damage)

	sequence = _emit(state, sequence, "action_performed", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"action_id": command["action_id"],
		"target_unit_id": target["id"],
		"ap_spent": 1,
	})
	sequence = _emit(state, sequence, "damage_applied", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"target_unit_id": target["id"],
		"damage": damage,
		"hp_before": old_hp,
		"hp_after": target["resources"]["hp"],
	})

	if target["resources"]["hp"] == 0:
		sequence = _emit(state, sequence, "unit_defeated", {
			"command_id": command["id"],
			"actor_id": actor["id"],
			"target_unit_id": target["id"],
		})

	if _combat_result(state) != "in_progress":
		sequence = _emit(state, sequence, "combat_ended", {
			"command_id": command["id"],
			"actor_id": actor["id"],
			"result": _combat_result(state),
		})

	return sequence


static func _resolve_move(state: Dictionary, command: Dictionary, sequence: int) -> int:
	var actor := _unit_by_id(state, command["actor_id"])
	var destination: Dictionary = command["target"].get("position", {})

	var rejection := _move_rejection(state, actor, destination)
	if rejection != "":
		return _reject(state, sequence, command, rejection)

	var old_position: Dictionary = actor["position"].duplicate(true)
	actor["resources"]["ap"] -= 1
	actor["position"] = destination.duplicate(true)

	sequence = _emit(state, sequence, "action_performed", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"action_id": command["action_id"],
		"ap_spent": 1,
	})
	return _emit(state, sequence, "unit_moved", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"from": old_position,
		"to": destination.duplicate(true),
	})


static func _resolve_defend(state: Dictionary, command: Dictionary, sequence: int) -> int:
	var actor := _unit_by_id(state, command["actor_id"])
	var rejection := _action_rejection(state, actor, "defend", 1)
	if rejection != "":
		return _reject(state, sequence, command, rejection)

	actor["resources"]["ap"] -= 1
	var status := {
		"id": "defending",
		"duration_rule": "until_next_turn_start",
		"source_unit_id": actor["id"],
	}
	actor["statuses"].append(status)

	sequence = _emit(state, sequence, "action_performed", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"action_id": command["action_id"],
		"ap_spent": 1,
	})
	return _emit(state, sequence, "status_applied", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"target_unit_id": actor["id"],
		"status": status,
	})


static func _resolve_end_turn(state: Dictionary, command: Dictionary, sequence: int) -> int:
	var actor := _unit_by_id(state, command["actor_id"])
	var rejection := _action_rejection(state, actor, "end_turn", 0)
	if rejection != "":
		return _reject(state, sequence, command, rejection)

	var previous_unit_id: String = actor["id"]
	var next_unit_id := _next_living_unit_id(state, previous_unit_id)
	if next_unit_id == "":
		return _reject(state, sequence, command, "no_next_living_unit")

	state["turn_state"]["active_unit_id"] = next_unit_id
	var next_unit := _unit_by_id(state, next_unit_id)
	next_unit["resources"]["ap"] = next_unit["stats"]["max_ap"]

	sequence = _emit(state, sequence, "action_performed", {
		"command_id": command["id"],
		"actor_id": previous_unit_id,
		"action_id": command["action_id"],
		"ap_spent": 0,
	})
	sequence = _emit(state, sequence, "turn_ended", {
		"command_id": command["id"],
		"actor_id": previous_unit_id,
	})
	return _emit(state, sequence, "turn_started", {
		"command_id": command["id"],
		"actor_id": next_unit_id,
		"round": state["turn_state"]["round"],
	})


static func _basic_attack_rejection(state: Dictionary, actor: Dictionary, target: Dictionary) -> String:
	if actor.is_empty():
		return "missing_actor"
	if target.is_empty():
		return "missing_target"
	if state["turn_state"]["active_unit_id"] != actor["id"]:
		return "actor_is_not_active_unit"
	if actor["resources"]["hp"] <= 0:
		return "actor_defeated"
	if target["resources"]["hp"] <= 0:
		return "target_defeated"
	if actor["team"] == target["team"]:
		return "target_is_not_enemy"
	if actor["resources"]["ap"] < 1:
		return "not_enough_ap"
	if _chebyshev(actor["position"], target["position"]) > 1:
		return "target_out_of_range"
	if not actor["available_actions"].has("basic_attack"):
		return "action_not_available"
	return ""


static func _action_rejection(state: Dictionary, actor: Dictionary, action_id: String, required_ap: int) -> String:
	if actor.is_empty():
		return "missing_actor"
	if state["turn_state"]["active_unit_id"] != actor["id"]:
		return "actor_is_not_active_unit"
	if actor["resources"]["hp"] <= 0:
		return "actor_defeated"
	if actor["resources"]["ap"] < required_ap:
		return "not_enough_ap"
	if not actor["available_actions"].has(action_id):
		return "action_not_available"
	return ""


static func _move_rejection(state: Dictionary, actor: Dictionary, destination: Dictionary) -> String:
	if actor.is_empty():
		return "missing_actor"
	if state["turn_state"]["active_unit_id"] != actor["id"]:
		return "actor_is_not_active_unit"
	if actor["resources"]["hp"] <= 0:
		return "actor_defeated"
	if actor["resources"]["ap"] < 1:
		return "not_enough_ap"
	if not actor["available_actions"].has("move"):
		return "action_not_available"
	if not destination.has("x") or not destination.has("y"):
		return "missing_destination"
	if not _inside_grid(state, destination):
		return "destination_out_of_bounds"
	if _tile_type(state, destination) != "floor":
		return "destination_not_walkable"
	if not _living_unit_at(state, destination).is_empty():
		return "destination_occupied"
	if _chebyshev(actor["position"], destination) != 1:
		return "destination_not_adjacent"
	return ""


static func _reject(state: Dictionary, sequence: int, command: Dictionary, reason: String) -> int:
	return _emit(state, sequence, "command_rejected", {
		"command_id": command.get("id", "missing"),
		"actor_id": command.get("actor_id", "missing"),
		"reason": reason,
	})


static func _emit(state: Dictionary, sequence: int, event_type: String, payload: Dictionary) -> int:
	var event := {
		"type": event_type,
		"sequence": sequence,
		"combat_id": state["id"],
	}
	for key: String in payload:
		event[key] = payload[key]
	state["event_log"].append(event)
	return sequence + 1


static func _unit_by_id(state: Dictionary, unit_id: String) -> Dictionary:
	for unit: Dictionary in state["units"]:
		if unit["id"] == unit_id:
			return unit
	return {}


static func _manhattan(first: Dictionary, second: Dictionary) -> int:
	return abs(first["x"] - second["x"]) + abs(first["y"] - second["y"])


static func _chebyshev(first: Dictionary, second: Dictionary) -> int:
	return max(abs(first["x"] - second["x"]), abs(first["y"] - second["y"]))


static func _inside_grid(state: Dictionary, position: Dictionary) -> bool:
	return 0 <= position["x"] and position["x"] < state["grid"]["width"] and 0 <= position["y"] and position["y"] < state["grid"]["height"]


static func _tile_type(state: Dictionary, position: Dictionary) -> String:
	for tile: Dictionary in state["grid"]["tiles"]:
		if tile["x"] == position["x"] and tile["y"] == position["y"]:
			return tile["type"]
	return ""


static func _living_unit_at(state: Dictionary, position: Dictionary) -> Dictionary:
	for unit: Dictionary in state["units"]:
		if unit["resources"]["hp"] > 0 and unit["position"] == position:
			return unit
	return {}


static func _next_living_unit_id(state: Dictionary, current_unit_id: String) -> String:
	var turn_order: Array = state["turn_state"]["turn_order"]
	var current_index := turn_order.find(current_unit_id)
	for offset in range(1, turn_order.size() + 1):
		var candidate_id: String = turn_order[(current_index + offset) % turn_order.size()]
		var candidate := _unit_by_id(state, candidate_id)
		if not candidate.is_empty() and candidate["resources"]["hp"] > 0:
			return candidate_id
	return ""


static func _adjacent_living_enemy(state: Dictionary, actor: Dictionary, target_team: String) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for unit: Dictionary in state["units"]:
		if unit["team"] == target_team and unit["resources"]["hp"] > 0 and _chebyshev(actor["position"], unit["position"]) == 1:
			candidates.append(unit)

	candidates.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return first["id"] < second["id"]
	)
	return candidates[0] if not candidates.is_empty() else {}


static func _nearest_living_enemy(state: Dictionary, actor: Dictionary, target_team: String) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for unit: Dictionary in state["units"]:
		if unit["team"] == target_team and unit["resources"]["hp"] > 0:
			candidates.append(unit)

	candidates.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_distance: int = _manhattan(actor["position"], first["position"])
		var second_distance: int = _manhattan(actor["position"], second["position"])
		if first_distance == second_distance:
			return first["id"] < second["id"]
		return first_distance < second_distance
	)
	return candidates[0] if not candidates.is_empty() else {}


static func _best_step_toward(state: Dictionary, actor: Dictionary, target: Dictionary) -> Dictionary:
	var current_distance: int = _manhattan(actor["position"], target["position"])
	var candidates: Array[Dictionary] = [
		{"x": actor["position"]["x"] - 1, "y": actor["position"]["y"]},
		{"x": actor["position"]["x"] + 1, "y": actor["position"]["y"]},
		{"x": actor["position"]["x"], "y": actor["position"]["y"] - 1},
		{"x": actor["position"]["x"], "y": actor["position"]["y"] + 1},
		{"x": actor["position"]["x"] - 1, "y": actor["position"]["y"] - 1},
		{"x": actor["position"]["x"] - 1, "y": actor["position"]["y"] + 1},
		{"x": actor["position"]["x"] + 1, "y": actor["position"]["y"] - 1},
		{"x": actor["position"]["x"] + 1, "y": actor["position"]["y"] + 1},
	]
	var legal_candidates: Array[Dictionary] = []
	for position: Dictionary in candidates:
		if _move_rejection(state, actor, position) == "" and _manhattan(position, target["position"]) < current_distance:
			legal_candidates.append(position)

	legal_candidates.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_distance: int = _manhattan(first, target["position"])
		var second_distance: int = _manhattan(second, target["position"])
		if first_distance != second_distance:
			return first_distance < second_distance
		if int(first["y"]) != int(second["y"]):
			return int(first["y"]) < int(second["y"])
		return int(first["x"]) < int(second["x"])
	)
	return legal_candidates[0] if not legal_candidates.is_empty() else {}


static func _end_turn_command(actor_id: String, command_id: String) -> Dictionary:
	return {
		"id": command_id,
		"type": "perform_action",
		"actor_id": actor_id,
		"action_id": "end_turn",
		"target": {"type": "none"},
	}


static func _combat_result(state: Dictionary) -> String:
	var player_alive := false
	var enemy_alive := false

	for unit: Dictionary in state["units"]:
		if unit["team"] == "player" and unit["resources"]["hp"] > 0:
			player_alive = true
		if unit["team"] == "enemy" and unit["resources"]["hp"] > 0:
			enemy_alive = true

	if player_alive and enemy_alive:
		return "in_progress"
	if player_alive:
		return "victory"
	return "defeat"
