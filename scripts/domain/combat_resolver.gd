extends RefCounted
class_name CombatResolver

const RANGED_ATTACK_HIT_CHANCE := 70
const MIN_HIT_CHANCE := 10
const MAX_HIT_CHANCE := 95
const HIGHGROUND_RANGED_HIT_MODIFIER := 10
const COVER_LOW_RANGED_HIT_MODIFIER := -20
const HIGHGROUND_RANGED_RANGE_BONUS := 1
const AI_RANGED_MIN_HIT_CHANCE := 60
const MIN_INTERCEPT_CHANCE := 20
const MAX_INTERCEPT_CHANCE := 80
const AI_POWER_STRIKE_CHANCE := 35
const POWER_STRIKE_COOLDOWN_TURNS := 2
const DEFAULT_AIMED_SHOT_COOLDOWN_TURNS := 2
const DEFAULT_SHIELD_WALL_COOLDOWN_TURNS := 2


static func simulate(encounter: Dictionary, commands: Array) -> Dictionary:
	var state: Dictionary = encounter.duplicate(true)
	_apply_map_reference(state)
	_apply_enemy_archetypes(state)
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
		"result_payload": _combat_result_payload(state),
	}


static func choose_enemy_command(state: Dictionary, command_id: String = "cmd_ai_001") -> Dictionary:
	state = _state_with_archetypes(state)
	var actor := _unit_by_id(state, state["turn_state"]["active_unit_id"])
	if actor.is_empty() or actor["team"] != "enemy":
		return _end_turn_command(state["turn_state"]["active_unit_id"], command_id)

	var adjacent_player := _adjacent_living_enemy(state, actor, "player")
	if not adjacent_player.is_empty() and _enemy_should_use_power_strike(state, actor, adjacent_player):
		return {
			"id": command_id,
			"type": "perform_action",
			"actor_id": actor["id"],
			"action_id": "power_strike",
			"target": {
				"type": "unit",
				"unit_id": adjacent_player["id"],
			},
		}

	if not adjacent_player.is_empty() and actor["resources"]["ap"] >= 1 and _action_available(state, actor, "basic_attack"):
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

	var ranged_player := _ranged_living_enemy(state, actor, "player")
	if not ranged_player.is_empty():
		return {
			"id": command_id,
			"type": "perform_action",
			"actor_id": actor["id"],
			"action_id": "ranged_attack",
			"target": {
				"type": "unit",
				"unit_id": ranged_player["id"],
			},
		}

	var nearest_player := _nearest_living_enemy(state, actor, "player")
	var move_target := _best_move_toward(state, actor, nearest_player) if not nearest_player.is_empty() else {}
	if not move_target.is_empty() and _can_pay_move(actor) and _action_available(state, actor, "move"):
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
	if _combat_result(state) != "in_progress":
		return _reject(state, sequence, command, "combat_already_ended")

	if command["type"] != "perform_action":
		return _reject(state, sequence, command, "unsupported_command_type")

	match command["action_id"]:
		"basic_attack":
			return _resolve_attack(state, command, sequence, "basic_attack", 1, false)
		"ranged_attack":
			return _resolve_attack(state, command, sequence, "ranged_attack", 3, true)
		"aimed_shot":
			return _resolve_attack(state, command, sequence, "aimed_shot", 4, true, 1, 2)
		"power_strike":
			return _resolve_attack(state, command, sequence, "power_strike", 1, false, 2, 2)
		"deep_cut":
			return _resolve_attack(state, command, sequence, "deep_cut", 1, false, 0, 1)
		"guard_break":
			return _resolve_attack(state, command, sequence, "guard_break", 1, false, 0, 1)
		"shield_wall":
			return _resolve_self_status_action(state, command, sequence, "shield_wall", 1)
		"move":
			return _resolve_move(state, command, sequence)
		"defend":
			return _resolve_defend(state, command, sequence)
		"end_turn":
			return _resolve_end_turn(state, command, sequence)
		_:
			return _reject(state, sequence, command, "unsupported_action")


static func _resolve_attack(state: Dictionary, command: Dictionary, sequence: int, action_id: String, max_range: int, uses_hit_chance: bool, damage_bonus: int = 0, ap_cost: int = 1) -> int:
	var actor := _unit_by_id(state, command["actor_id"])
	var target := _unit_by_id(state, command["target"].get("unit_id", ""))
	var weapon_profile_variant: Variant = _profile_for_action(state, actor, action_id)

	var rejection := _attack_rejection(state, actor, target, action_id, max_range, ap_cost)
	if rejection != "":
		return _reject(state, sequence, command, rejection)

	var weapon_profile: Dictionary = weapon_profile_variant
	var attack_range := _effective_attack_range(state, actor, action_id, _attack_range(weapon_profile, max_range))
	var attack_ap_cost := _attack_ap_cost(weapon_profile, ap_cost)
	var attack_damage_bonus := _attack_damage_bonus(weapon_profile, damage_bonus)

	rejection = _range_rejection(state, actor, target, action_id, attack_range)
	if rejection != "":
		return _reject(state, sequence, command, rejection)

	actor["resources"]["ap"] -= attack_ap_cost

	sequence = _emit(state, sequence, "action_performed", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"action_id": command["action_id"],
		"target_unit_id": target["id"],
		"ap_spent": attack_ap_cost,
		"profile_id": weapon_profile.get("id", ""),
		"weapon_id": weapon_profile.get("id", ""),
	})
	var cooldown_turns := _cooldown_turns(weapon_profile, _default_cooldown_turns(action_id))
	if cooldown_turns > 0:
		var cooldown_status := _skill_cooldown_status(actor["id"], action_id, cooldown_turns)
		actor["statuses"].append(cooldown_status)
		sequence = _emit(state, sequence, "status_applied", {
			"command_id": command["id"],
			"actor_id": actor["id"],
			"target_unit_id": actor["id"],
			"status": cooldown_status,
		})

	var original_target := target
	if uses_hit_chance:
		var intercept := _ranged_intercept_candidate(state, actor, target)
		if not intercept.is_empty():
			var intercept_roll := _deterministic_intercept_roll(state, command)
			var blocker: Dictionary = intercept["unit"]
			var intercept_outcome := "intercepted" if intercept_roll <= int(intercept["chance"]) else "clear"
			sequence = _emit(state, sequence, "shot_intercept_resolved", {
				"command_id": command["id"],
				"actor_id": actor["id"],
				"original_target_unit_id": original_target["id"],
				"blocker_unit_id": blocker["id"],
				"final_target_unit_id": blocker["id"] if intercept_outcome == "intercepted" else original_target["id"],
				"blocker_progress": intercept["progress"],
				"intercept_chance": intercept["chance"],
				"roll": intercept_roll,
				"outcome": intercept_outcome,
			})
			if intercept_outcome == "intercepted":
				target = blocker

	if uses_hit_chance:
		var roll := _deterministic_roll(state, command)
		var base_hit_chance := _base_hit_chance(weapon_profile)
		var accuracy_modifier := _stat(actor, "accuracy")
		var evasion_modifier := _stat(target, "evasion")
		var terrain_modifier := _terrain_hit_modifier(state, actor, action_id)
		var cover_modifier := _cover_hit_modifier(state, target, action_id)
		var hit_chance := clampi(base_hit_chance + accuracy_modifier - evasion_modifier + terrain_modifier + cover_modifier, MIN_HIT_CHANCE, MAX_HIT_CHANCE)
		var outcome := "hit" if roll <= hit_chance else "miss"
		sequence = _emit(state, sequence, "hit_roll_resolved", {
			"command_id": command["id"],
			"actor_id": actor["id"],
			"target_unit_id": target["id"],
			"roll": roll,
			"base_hit_chance": base_hit_chance,
			"accuracy_modifier": accuracy_modifier,
			"evasion_modifier": evasion_modifier,
			"terrain_modifier": terrain_modifier,
			"cover_modifier": cover_modifier,
			"hit_chance": hit_chance,
			"outcome": outcome,
		})
		if outcome == "miss":
			return sequence

	var raw_damage: int = max(1, actor["stats"]["strength"] + attack_damage_bonus - _effective_defense(target))
	var reduction := _damage_reduction(state, target)
	var armor_id := _armor_id(target)
	var damage: int = max(1, raw_damage - reduction)
	var old_hp: int = target["resources"]["hp"]
	target["resources"]["hp"] = max(0, old_hp - damage)

	sequence = _emit(state, sequence, "damage_applied", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"target_unit_id": target["id"],
		"damage": damage,
		"raw_damage": raw_damage,
		"damage_reduction": reduction,
		"damage_bonus": attack_damage_bonus,
		"armor_id": armor_id,
		"profile_id": weapon_profile.get("id", ""),
		"weapon_id": weapon_profile.get("id", ""),
		"hp_before": old_hp,
		"hp_after": target["resources"]["hp"],
	})

	if target["resources"]["hp"] > 0 and _profile_applies_status(weapon_profile):
		var status := _profile_status(actor["id"], weapon_profile, str(weapon_profile.get("status_id", action_id)))
		target["statuses"].append(status)
		sequence = _emit(state, sequence, "status_applied", {
			"command_id": command["id"],
			"actor_id": actor["id"],
			"target_unit_id": target["id"],
			"status": status,
		})

	if target["resources"]["hp"] == 0:
		sequence = _emit(state, sequence, "unit_defeated", {
			"command_id": command["id"],
			"actor_id": actor["id"],
			"target_unit_id": target["id"],
		})

	if _combat_result(state) != "in_progress":
		var result_payload := _combat_result_payload(state)
		sequence = _emit(state, sequence, "combat_ended", {
			"command_id": command["id"],
			"actor_id": actor["id"],
			"result": result_payload["result"],
			"result_payload": result_payload,
		})

	return sequence


static func _resolve_self_status_action(state: Dictionary, command: Dictionary, sequence: int, action_id: String, ap_cost: int) -> int:
	var actor := _unit_by_id(state, command["actor_id"])
	var action_profile: Dictionary = _profile_for_action(state, actor, action_id)
	var required_ap := _attack_ap_cost(action_profile, ap_cost)
	var rejection := _self_action_rejection(state, actor, action_id, required_ap)
	if rejection != "":
		return _reject(state, sequence, command, rejection)

	actor["resources"]["ap"] -= required_ap
	sequence = _emit(state, sequence, "action_performed", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"action_id": action_id,
		"ap_spent": required_ap,
		"profile_id": action_profile.get("id", ""),
	})

	var status := _profile_status(actor["id"], action_profile, action_id)
	actor["statuses"].append(status)
	sequence = _emit(state, sequence, "status_applied", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"target_unit_id": actor["id"],
		"status": status,
	})

	var cooldown_turns := _cooldown_turns(action_profile, _default_cooldown_turns(action_id))
	if cooldown_turns > 0:
		var cooldown_status := _skill_cooldown_status(actor["id"], action_id, cooldown_turns)
		actor["statuses"].append(cooldown_status)
		sequence = _emit(state, sequence, "status_applied", {
			"command_id": command["id"],
			"actor_id": actor["id"],
			"target_unit_id": actor["id"],
			"status": cooldown_status,
		})

	return sequence


static func _resolve_move(state: Dictionary, command: Dictionary, sequence: int) -> int:
	var actor := _unit_by_id(state, command["actor_id"])
	var destination: Dictionary = command["target"].get("position", {})

	var rejection := _move_rejection(state, actor, destination)
	if rejection != "":
		return _reject(state, sequence, command, rejection)

	var old_position: Dictionary = actor["position"].duplicate(true)
	var movement_path := _movement_path(state, actor, destination)
	var movement_cost := _movement_path_cost(state, movement_path)
	var ap_spent := 0 if _movement_uses_mp(actor) else 1
	var mp_spent := movement_cost if _movement_uses_mp(actor) else 0
	actor["resources"]["ap"] -= ap_spent
	if _movement_uses_mp(actor):
		actor["resources"]["mp"] -= mp_spent
	actor["position"] = destination.duplicate(true)

	sequence = _emit(state, sequence, "action_performed", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"action_id": command["action_id"],
		"ap_spent": ap_spent,
		"mp_spent": mp_spent,
	})
	return _emit(state, sequence, "unit_moved", {
		"command_id": command["id"],
		"actor_id": actor["id"],
		"from": old_position,
		"to": destination.duplicate(true),
		"path": movement_path,
		"mp_spent": mp_spent,
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
	return _start_next_living_turn(state, command, sequence, previous_unit_id)


static func _start_next_living_turn(state: Dictionary, command: Dictionary, sequence: int, previous_unit_id: String) -> int:
	var cursor_unit_id := previous_unit_id
	while true:
		var next_unit_id := _next_living_unit_id(state, cursor_unit_id)
		if next_unit_id == "":
			return _reject(state, sequence, command, "no_next_living_unit")

		if _turn_order_wraps(state, cursor_unit_id, next_unit_id):
			state["turn_state"]["round"] += 1

		state["turn_state"]["active_unit_id"] = next_unit_id
		var next_unit := _unit_by_id(state, next_unit_id)
		next_unit["resources"]["ap"] = next_unit["stats"]["max_ap"]
		if next_unit["resources"].has("mp"):
			next_unit["resources"]["mp"] = next_unit["stats"]["move_points"]
		var turn_start_status_result := _tick_turn_start_statuses(next_unit)
		var status_damage_events: Array = turn_start_status_result["damage_events"]
		var expired_statuses: Array = turn_start_status_result["expired_statuses"]

		sequence = _emit(state, sequence, "turn_started", {
			"command_id": command["id"],
			"actor_id": next_unit_id,
			"round": state["turn_state"]["round"],
		})
		for damage_event: Dictionary in status_damage_events:
			damage_event["command_id"] = command["id"]
			damage_event["actor_id"] = next_unit_id
			damage_event["target_unit_id"] = next_unit_id
			sequence = _emit(state, sequence, "damage_applied", damage_event)
			if int(damage_event.get("hp_after", 1)) == 0:
				sequence = _emit(state, sequence, "unit_defeated", {
					"command_id": command["id"],
					"actor_id": next_unit_id,
					"target_unit_id": next_unit_id,
				})
				if _combat_result(state) != "in_progress":
					var result_payload := _combat_result_payload(state)
					sequence = _emit(state, sequence, "combat_ended", {
						"command_id": command["id"],
						"actor_id": next_unit_id,
						"result": result_payload["result"],
						"result_payload": result_payload,
					})
		for status: Dictionary in expired_statuses:
			sequence = _emit(state, sequence, "status_expired", {
				"command_id": command["id"],
				"actor_id": next_unit_id,
				"target_unit_id": next_unit_id,
				"status": status,
			})

		if _combat_result(state) != "in_progress" or next_unit["resources"]["hp"] > 0:
			return sequence

		sequence = _emit(state, sequence, "turn_ended", {
			"command_id": command["id"],
			"actor_id": next_unit_id,
			"reason": "actor_defeated_at_turn_start",
		})
		cursor_unit_id = next_unit_id
	return sequence


static func _attack_rejection(state: Dictionary, actor: Dictionary, target: Dictionary, action_id: String, max_range: int, required_ap: int = 1) -> String:
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
	var loadout_rejection := _loadout_rejection(state, actor)
	if loadout_rejection != "":
		return loadout_rejection
	if not _action_available(state, actor, action_id):
		return "action_not_available"
	var weapon_profile_variant: Variant = _weapon_profile_for_action(state, actor, action_id)
	if weapon_profile_variant == null:
		return "missing_weapon_profile"
	var weapon_profile: Dictionary = weapon_profile_variant
	if actor["resources"]["ap"] < _attack_ap_cost(weapon_profile, required_ap):
		return "not_enough_ap"
	if _skill_on_cooldown(actor, action_id):
		return "skill_on_cooldown"
	var range_rejection := _range_rejection(state, actor, target, action_id, _effective_attack_range(state, actor, action_id, _attack_range(weapon_profile, max_range)))
	if range_rejection != "":
		return range_rejection
	return ""


static func _self_action_rejection(state: Dictionary, actor: Dictionary, action_id: String, required_ap: int) -> String:
	if actor.is_empty():
		return "missing_actor"
	if state["turn_state"]["active_unit_id"] != actor["id"]:
		return "actor_is_not_active_unit"
	if actor["resources"]["hp"] <= 0:
		return "actor_defeated"
	if actor["resources"]["ap"] < required_ap:
		return "not_enough_ap"
	var loadout_rejection := _loadout_rejection(state, actor)
	if loadout_rejection != "":
		return loadout_rejection
	if _skill_on_cooldown(actor, action_id):
		return "skill_on_cooldown"
	if not _action_available(state, actor, action_id):
		return "action_not_available"
	return ""


static func _range_rejection(state: Dictionary, actor: Dictionary, target: Dictionary, action_id: String, max_range: int) -> String:
	if _chebyshev(actor["position"], target["position"]) > max_range:
		return "target_out_of_range"
	if action_id == "ranged_attack" and not _has_line_of_sight(state, actor["position"], target["position"]):
		return "target_not_visible"
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
	if not _action_available(state, actor, action_id):
		return "action_not_available"
	return ""


static func _move_rejection(state: Dictionary, actor: Dictionary, destination: Dictionary) -> String:
	if actor.is_empty():
		return "missing_actor"
	if state["turn_state"]["active_unit_id"] != actor["id"]:
		return "actor_is_not_active_unit"
	if actor["resources"]["hp"] <= 0:
		return "actor_defeated"
	if _movement_uses_mp(actor):
		if actor["resources"]["mp"] < 1:
			return "not_enough_mp"
	elif actor["resources"]["ap"] < 1:
		return "not_enough_ap"
	if not _action_available(state, actor, "move"):
		return "action_not_available"
	if not destination.has("x") or not destination.has("y"):
		return "missing_destination"
	if not _inside_grid(state, destination):
		return "destination_out_of_bounds"
	if not _is_walkable_tile(state, destination):
		return "destination_not_walkable"
	if not _living_unit_at(state, destination).is_empty():
		return "destination_occupied"
	if not _movement_uses_mp(actor) and _chebyshev(actor["position"], destination) != 1:
		return "destination_not_adjacent"
	var movement_path := _movement_path(state, actor, destination)
	if movement_path.is_empty():
		return "destination_unreachable"
	if _movement_uses_mp(actor):
		if _movement_path_cost(state, movement_path) > actor["resources"]["mp"]:
			return "not_enough_mp"
	elif _is_diagonal_step(actor["position"], destination) and not _diagonal_step_allowed(state, actor["position"], destination):
		return "diagonal_corner_blocked"
	return ""


static func _movement_uses_mp(actor: Dictionary) -> bool:
	return actor.get("resources", {}).has("mp")


static func _can_pay_move(actor: Dictionary) -> bool:
	if _movement_uses_mp(actor):
		return actor["resources"]["mp"] >= 1
	return actor["resources"]["ap"] >= 1


static func _movement_path_cost(state: Dictionary, path: Array) -> int:
	var cost := 0
	for position: Dictionary in path:
		cost += _terrain_movement_cost(state, position)
	return cost


static func _movement_path(state: Dictionary, actor: Dictionary, destination: Dictionary) -> Array:
	if not destination.has("x") or not destination.has("y"):
		return []
	var start: Dictionary = actor["position"]
	if _positions_equal(start, destination):
		return []

	var queue: Array[Dictionary] = [{"position": start, "path": [], "cost": 0}]
	var best_cost := {_position_key(start): 0}

	while not queue.is_empty():
		queue.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
			if int(first["cost"]) != int(second["cost"]):
				return int(first["cost"]) < int(second["cost"])
			if first["path"].size() != second["path"].size():
				return first["path"].size() < second["path"].size()
			var first_position: Dictionary = first["position"]
			var second_position: Dictionary = second["position"]
			var first_distance := _manhattan(first_position, destination)
			var second_distance := _manhattan(second_position, destination)
			if first_distance != second_distance:
				return first_distance < second_distance
			if int(first_position["y"]) != int(second_position["y"]):
				return int(first_position["y"]) < int(second_position["y"])
			return int(first_position["x"]) < int(second_position["x"])
		)
		var item: Dictionary = queue.pop_front()
		var current: Dictionary = item["position"]
		var path: Array = item["path"]
		var cost := int(item["cost"])
		if _positions_equal(current, destination) and not path.is_empty():
			return path
		for neighbor: Dictionary in _movement_neighbors(state, actor, current):
			var key := _position_key(neighbor)
			var next_cost := cost + _terrain_movement_cost(state, neighbor)
			if best_cost.has(key) and int(best_cost[key]) <= next_cost:
				continue
			var next_path := path.duplicate(true)
			next_path.append(neighbor)
			best_cost[key] = next_cost
			queue.append({"position": neighbor, "path": next_path, "cost": next_cost})

	return []


static func _movement_neighbors(state: Dictionary, actor: Dictionary, position: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = [
		{"x": position["x"] - 1, "y": position["y"]},
		{"x": position["x"] + 1, "y": position["y"]},
		{"x": position["x"], "y": position["y"] - 1},
		{"x": position["x"], "y": position["y"] + 1},
		{"x": position["x"] - 1, "y": position["y"] - 1},
		{"x": position["x"] - 1, "y": position["y"] + 1},
		{"x": position["x"] + 1, "y": position["y"] - 1},
		{"x": position["x"] + 1, "y": position["y"] + 1},
	]
	var legal_candidates: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		if _path_position_is_legal(state, actor, position, candidate):
			legal_candidates.append(candidate)
	return legal_candidates


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


static func _deterministic_roll(state: Dictionary, command: Dictionary) -> int:
	var command_hash := 0
	for index in range(command["id"].length()):
		command_hash += command["id"].unicode_at(index)
	var total := int(state["seed"]) + command_hash * 17
	return total % 100 + 1


static func _deterministic_intercept_roll(state: Dictionary, command: Dictionary) -> int:
	var roll_id := "%s_intercept" % command["id"]
	var command_hash := 0
	for index in range(roll_id.length()):
		command_hash += roll_id.unicode_at(index)
	var total := int(state["seed"]) + command_hash * 17
	return total % 100 + 1


static func _deterministic_ai_decision_roll(state: Dictionary, actor: Dictionary, action_id: String) -> int:
	var roll_id := "%s_%s_%s" % [actor["id"], action_id, state["turn_state"]["round"]]
	var command_hash := 0
	for index in range(roll_id.length()):
		command_hash += roll_id.unicode_at(index)
	var total := int(state["seed"]) + command_hash * 13
	return total % 100 + 1


static func _stat(unit: Dictionary, stat_name: String) -> int:
	return int(unit["stats"].get(stat_name, 0))


static func _profile_for_action(state: Dictionary, actor: Dictionary, action_id: String) -> Variant:
	if actor.is_empty():
		return {}
	var profile: Dictionary = {}
	if actor.has("equipped_weapon_id"):
		var weapon_id: String = actor["equipped_weapon_id"]
		var profiles: Dictionary = state.get("weapon_profiles", {})
		if not profiles.has(weapon_id):
			return null
		var found_profile: Dictionary = profiles[weapon_id]
		if found_profile.get("action_id", "") == action_id:
			profile = found_profile
	if not profile.is_empty():
		return profile
	var item_profile_variant: Variant = _item_action_profile_for_action(state, actor, action_id)
	if item_profile_variant != null:
		return item_profile_variant
	var action_profiles: Dictionary = state.get("action_profiles", {})
	if action_profiles.has(action_id):
		return action_profiles[action_id]
	return {}


static func _weapon_profile_for_action(state: Dictionary, actor: Dictionary, action_id: String) -> Variant:
	return _profile_for_action(state, actor, action_id)


static func _enemy_should_use_power_strike(state: Dictionary, actor: Dictionary, target: Dictionary) -> bool:
	if not _action_available(state, actor, "power_strike"):
		return false
	var profile: Dictionary = _profile_for_action(state, actor, "power_strike")
	if _attack_rejection(state, actor, target, "power_strike", 1, _attack_ap_cost(profile, 2)) != "":
		return false
	return _deterministic_ai_decision_roll(state, actor, "power_strike") <= AI_POWER_STRIKE_CHANCE


static func _skill_on_cooldown(actor: Dictionary, action_id: String) -> bool:
	for status: Dictionary in actor["statuses"]:
		if status.get("id", "") == "skill_cooldown" and status.get("action_id", "") == action_id and int(status.get("remaining_turns", 0)) > 0:
			return true
	return false


static func _skill_cooldown_status(source_unit_id: String, action_id: String, remaining_turns: int) -> Dictionary:
	return {
		"id": "skill_cooldown",
		"action_id": action_id,
		"remaining_turns": remaining_turns,
		"duration_rule": "own_turn_starts",
		"source_unit_id": source_unit_id,
	}


static func _tick_turn_start_statuses(unit: Dictionary) -> Dictionary:
	var kept_statuses: Array[Dictionary] = []
	var expired_statuses: Array[Dictionary] = []
	var damage_events: Array[Dictionary] = []
	for status: Dictionary in unit["statuses"]:
		var next_status: Dictionary = status.duplicate(true)
		var tick_damage := int(next_status.get("tick_damage", 0))
		if tick_damage > 0 and unit["resources"]["hp"] > 0:
			var old_hp := int(unit["resources"]["hp"])
			var damage := mini(tick_damage, old_hp)
			unit["resources"]["hp"] = max(0, old_hp - damage)
			damage_events.append({
				"damage": damage,
				"raw_damage": tick_damage,
				"damage_reduction": 0,
				"damage_bonus": 0,
				"armor_id": "",
				"profile_id": "",
				"weapon_id": "",
				"hp_before": old_hp,
				"hp_after": unit["resources"]["hp"],
				"source_status_id": next_status.get("id", ""),
			})
		if next_status.get("id", "") == "skill_cooldown":
			next_status["remaining_turns"] = max(0, int(next_status.get("remaining_turns", 0)) - 1)
			if int(next_status["remaining_turns"]) == 0:
				expired_statuses.append(next_status)
				continue
		elif next_status.get("duration_rule", "") == "own_turn_starts":
			next_status["remaining_turns"] = max(0, int(next_status.get("remaining_turns", 0)) - 1)
			if int(next_status["remaining_turns"]) == 0:
				expired_statuses.append(next_status)
				continue
		kept_statuses.append(next_status)
	unit["statuses"] = kept_statuses
	return {
		"damage_events": damage_events,
		"expired_statuses": expired_statuses,
	}


static func _attack_range(weapon_profile: Dictionary, fallback: int) -> int:
	return int(weapon_profile.get("range", fallback))


static func _effective_attack_range(state: Dictionary, actor: Dictionary, action_id: String, base_range: int) -> int:
	if action_id == "ranged_attack" and _tile_type(state, actor["position"]) == "highground":
		return base_range + HIGHGROUND_RANGED_RANGE_BONUS
	return base_range


static func _action_available(state: Dictionary, actor: Dictionary, action_id: String) -> bool:
	if actor.get("available_actions", []).has(action_id):
		return true
	if actor.get("learned_actions", []).has(action_id):
		return true
	for item: Dictionary in _loadout_items(state, actor):
		if item.get("grants_actions", []).has(action_id):
			return true
	return false


static func _item_action_profile_for_action(state: Dictionary, actor: Dictionary, action_id: String) -> Variant:
	if actor.is_empty():
		return null
	for item: Dictionary in _loadout_items(state, actor):
		if not item.get("grants_actions", []).has(action_id):
			continue
		var action_profiles: Dictionary = item.get("action_profiles", {})
		if action_profiles.has(action_id):
			return action_profiles[action_id]
	return null


static func _state_with_archetypes(state: Dictionary) -> Dictionary:
	var prepared := state.duplicate(true)
	_apply_map_reference(prepared)
	_apply_enemy_archetypes(prepared)
	return prepared


static func _apply_map_reference(state: Dictionary) -> void:
	var map_path := str(state.get("map_path", ""))
	if map_path == "":
		return
	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		push_error("Could not load combat map: %s" % map_path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Combat map is not a JSON object: %s" % map_path)
		return
	var map_data: Dictionary = parsed
	for key: String in ["background_path", "terrain_theme", "terrain_decorations"]:
		if not state.has(key) and map_data.has(key):
			state[key] = map_data[key].duplicate(true) if map_data[key] is Array else map_data[key]
	state["grid"] = {
		"width": map_data["width"],
		"height": map_data["height"],
		"tiles": map_data["tiles"].duplicate(true),
	}


static func _apply_enemy_archetypes(state: Dictionary) -> void:
	var archetypes: Dictionary = state.get("enemy_archetypes", {})
	if archetypes.is_empty():
		return
	for unit: Dictionary in state["units"]:
		var archetype_id := str(unit.get("archetype_id", ""))
		if unit.get("team", "") != "enemy" or archetype_id == "":
			continue
		if not archetypes.has(archetype_id):
			continue
		var archetype: Dictionary = archetypes[archetype_id]
		var merged_actions: Array = unit.get("available_actions", []).duplicate(true)
		for action_id: String in archetype.get("available_actions", []):
			if not merged_actions.has(action_id):
				merged_actions.append(action_id)
		unit["available_actions"] = merged_actions
		var merged_learned_actions: Array = unit.get("learned_actions", []).duplicate(true)
		for action_id: String in archetype.get("learned_actions", []):
			if not merged_learned_actions.has(action_id):
				merged_learned_actions.append(action_id)
		unit["learned_actions"] = merged_learned_actions
		if archetype.has("loadout"):
			var loadout: Dictionary = archetype["loadout"].duplicate(true)
			for slot: String in unit.get("loadout", {}):
				loadout[slot] = unit["loadout"][slot]
			unit["loadout"] = loadout
		if not unit.has("visual") and archetype.has("visual_pool"):
			var visual := _archetype_visual_from_pool(archetype, unit)
			if not visual.is_empty():
				unit["visual"] = visual


static func _archetype_visual_from_pool(archetype: Dictionary, unit: Dictionary) -> Dictionary:
	var visual_pool: Array = archetype.get("visual_pool", [])
	if visual_pool.is_empty():
		return {}
	var stable_key := "%s:%s" % [unit.get("id", ""), unit.get("archetype_id", "")]
	var index := _stable_visual_pool_index(stable_key, visual_pool.size())
	var visual: Variant = visual_pool[index]
	if typeof(visual) != TYPE_DICTIONARY:
		return {}
	return (visual as Dictionary).duplicate(true)


static func _stable_visual_pool_index(stable_key: String, pool_size: int) -> int:
	if pool_size <= 0:
		return 0
	var total := 0
	for index in range(stable_key.length()):
		total += stable_key.unicode_at(index)
	return total % pool_size


static func _loadout_items(state: Dictionary, actor: Dictionary) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var item_profiles: Dictionary = state.get("item_profiles", {})
	for item_id: Variant in actor.get("loadout", {}).values():
		if item_id == null:
			continue
		if item_profiles.has(item_id):
			items.append(item_profiles[item_id])
	return items


static func _loadout_rejection(state: Dictionary, actor: Dictionary) -> String:
	var loadout: Dictionary = actor.get("loadout", {})
	if loadout.is_empty():
		return ""
	var item_profiles: Dictionary = state.get("item_profiles", {})
	for slot: String in loadout:
		var item_id: Variant = loadout[slot]
		if item_id == null:
			continue
		if not item_profiles.has(item_id):
			return "missing_item_profile"
		var item: Dictionary = item_profiles[item_id]
		if item.get("slot", "") != slot:
			return "item_slot_mismatch"
	var main_item_id: Variant = loadout.get("main_hand", null)
	var off_item_id: Variant = loadout.get("off_hand", null)
	var main_item: Dictionary = item_profiles.get(main_item_id, {}) if main_item_id != null else {}
	if not main_item.is_empty() and main_item.get("two_handed", false) and off_item_id != null:
		return "invalid_loadout_two_handed_with_off_hand"
	return ""


static func _attack_ap_cost(weapon_profile: Dictionary, fallback: int) -> int:
	return int(weapon_profile.get("ap_cost", fallback))


static func _attack_damage_bonus(weapon_profile: Dictionary, fallback: int) -> int:
	return int(weapon_profile.get("damage_bonus", fallback))


static func _base_hit_chance(weapon_profile: Dictionary) -> int:
	return int(weapon_profile.get("base_hit_chance", RANGED_ATTACK_HIT_CHANCE))


static func _cooldown_turns(action_profile: Dictionary, fallback: int) -> int:
	return int(action_profile.get("cooldown_turns", fallback))


static func _default_cooldown_turns(action_id: String) -> int:
	if action_id == "power_strike":
		return POWER_STRIKE_COOLDOWN_TURNS
	if action_id == "aimed_shot":
		return DEFAULT_AIMED_SHOT_COOLDOWN_TURNS
	if action_id == "shield_wall":
		return DEFAULT_SHIELD_WALL_COOLDOWN_TURNS
	return 0


static func _profile_status(source_unit_id: String, action_profile: Dictionary, fallback_status_id: String) -> Dictionary:
	var status := {
		"id": action_profile.get("status_id", fallback_status_id),
		"remaining_turns": int(action_profile.get("status_remaining_turns", 1)),
		"duration_rule": "own_turn_starts",
		"source_unit_id": source_unit_id,
	}
	if action_profile.has("damage_reduction"):
		status["damage_reduction"] = int(action_profile["damage_reduction"])
	if action_profile.has("status_tick_damage"):
		status["tick_damage"] = int(action_profile["status_tick_damage"])
	if action_profile.has("status_defense_modifier"):
		status["defense_modifier"] = int(action_profile["status_defense_modifier"])
	return status


static func _profile_applies_status(action_profile: Dictionary) -> bool:
	return action_profile.has("status_id") or action_profile.has("status_tick_damage") or action_profile.has("status_defense_modifier")


static func _effective_defense(target: Dictionary) -> int:
	var defense := int(target["stats"].get("defense", 0))
	for status: Dictionary in target.get("statuses", []):
		defense += int(status.get("defense_modifier", 0))
	return max(0, defense)


static func _damage_reduction(state: Dictionary, target: Dictionary) -> int:
	var reduction := 0
	for status: Dictionary in target["statuses"]:
		reduction += int(status.get("damage_reduction", 0))
	var armor := _armor_item(state, target)
	if not armor.is_empty():
		reduction += int(armor.get("armor_reduction", 0))
	return reduction


static func _armor_item(state: Dictionary, target: Dictionary) -> Dictionary:
	var armor_id := _armor_id(target)
	if armor_id == "":
		return {}
	var armor: Dictionary = state.get("item_profiles", {}).get(armor_id, {})
	if armor.is_empty() or armor.get("slot", "") != "armor":
		return {}
	return armor


static func _armor_id(target: Dictionary) -> String:
	var armor_id: Variant = target.get("loadout", {}).get("armor", null)
	if armor_id == null:
		return ""
	return str(armor_id)


static func _terrain_hit_modifier(state: Dictionary, actor: Dictionary, action_id: String) -> int:
	if action_id == "ranged_attack" and _tile_type(state, actor["position"]) == "highground":
		return HIGHGROUND_RANGED_HIT_MODIFIER
	return 0


static func _cover_hit_modifier(state: Dictionary, target: Dictionary, action_id: String) -> int:
	if action_id == "ranged_attack" and _tile_type(state, target["position"]) == "cover_low":
		return COVER_LOW_RANGED_HIT_MODIFIER
	return 0


static func _has_line_of_sight(state: Dictionary, origin: Dictionary, target: Dictionary) -> bool:
	for position: Dictionary in _line_between(origin, target):
		if _tile_type(state, position) == "blocked":
			return false
	return true


static func _ranged_intercept_candidate(state: Dictionary, actor: Dictionary, target: Dictionary) -> Dictionary:
	var total_distance := _chebyshev(actor["position"], target["position"])
	if total_distance <= 1:
		return {}

	var candidates: Array[Dictionary] = []
	for position: Dictionary in _line_between(actor["position"], target["position"]):
		var unit := _living_unit_at(state, position)
		if unit.is_empty() or unit["id"] == actor["id"] or unit["id"] == target["id"]:
			continue
		var distance_from_actor := _chebyshev(actor["position"], unit["position"])
		var progress := clampi(roundi(float(distance_from_actor) * 100.0 / float(total_distance)), 1, 99)
		var chance := clampi(MIN_INTERCEPT_CHANCE + roundi(60.0 * float(progress) / 100.0), MIN_INTERCEPT_CHANCE, MAX_INTERCEPT_CHANCE)
		candidates.append({"unit": unit, "progress": progress, "chance": chance})

	candidates.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		if int(first["progress"]) != int(second["progress"]):
			return int(first["progress"]) > int(second["progress"])
		return first["unit"]["id"] < second["unit"]["id"]
	)
	return candidates[0] if not candidates.is_empty() else {}


static func _line_between(origin: Dictionary, target: Dictionary) -> Array[Dictionary]:
	var distance := _chebyshev(origin, target)
	if distance <= 1:
		return []

	var positions: Array[Dictionary] = []

	for step in range(1, distance):
		positions.append({
			"x": roundi(float(origin["x"]) + float(target["x"] - origin["x"]) * float(step) / float(distance)),
			"y": roundi(float(origin["y"]) + float(target["y"] - origin["y"]) * float(step) / float(distance)),
		})

	return positions


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


static func _is_walkable_tile(state: Dictionary, position: Dictionary) -> bool:
	return _tile_type(state, position) in ["floor", "highground", "cover_low"]


static func _terrain_movement_cost(state: Dictionary, position: Dictionary) -> int:
	match _tile_type(state, position):
		"highground":
			return 2
		"floor", "cover_low":
			return 1
		_:
			return 999999


static func _living_unit_at(state: Dictionary, position: Dictionary) -> Dictionary:
	for unit: Dictionary in state["units"]:
		if unit["resources"]["hp"] > 0 and int(unit["position"]["x"]) == int(position["x"]) and int(unit["position"]["y"]) == int(position["y"]):
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


static func _turn_order_wraps(state: Dictionary, current_unit_id: String, next_unit_id: String) -> bool:
	var turn_order: Array = state["turn_state"]["turn_order"]
	return turn_order.find(next_unit_id) <= turn_order.find(current_unit_id)


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


static func _ranged_living_enemy(state: Dictionary, actor: Dictionary, target_team: String) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for unit: Dictionary in state["units"]:
		if unit["team"] == target_team and unit["resources"]["hp"] > 0 and _attack_rejection(state, actor, unit, "ranged_attack", 3) == "" and _ranged_hit_chance(state, actor, unit, "ranged_attack") >= AI_RANGED_MIN_HIT_CHANCE:
			candidates.append(unit)

	candidates.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_distance: int = _chebyshev(actor["position"], first["position"])
		var second_distance: int = _chebyshev(actor["position"], second["position"])
		if first_distance == second_distance:
			return first["id"] < second["id"]
		return first_distance < second_distance
	)
	return candidates[0] if not candidates.is_empty() else {}


static func _best_move_toward(state: Dictionary, actor: Dictionary, target: Dictionary) -> Dictionary:
	if _movement_uses_mp(actor):
		var multi_tile_target := _best_mp_move_toward(state, actor, target)
		if not multi_tile_target.is_empty():
			return multi_tile_target

	var path_step := _first_path_step_toward(state, actor, target)
	if not path_step.is_empty():
		return path_step

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


static func _best_mp_move_toward(state: Dictionary, actor: Dictionary, target: Dictionary) -> Dictionary:
	var max_cost := int(actor["resources"].get("mp", 0))
	if max_cost <= 0:
		return {}

	var start: Dictionary = actor["position"]
	var queue: Array[Dictionary] = [{"position": start, "path": [], "cost": 0}]
	var best_cost := {_position_key(start): 0}
	var candidates: Array[Dictionary] = []

	while not queue.is_empty():
		queue.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
			if int(first["cost"]) != int(second["cost"]):
				return int(first["cost"]) < int(second["cost"])
			if first["path"].size() != second["path"].size():
				return first["path"].size() < second["path"].size()
			var first_position: Dictionary = first["position"]
			var second_position: Dictionary = second["position"]
			if int(first_position["y"]) != int(second_position["y"]):
				return int(first_position["y"]) < int(second_position["y"])
			return int(first_position["x"]) < int(second_position["x"])
		)
		var item: Dictionary = queue.pop_front()
		var current: Dictionary = item["position"]
		var path: Array = item["path"]
		var cost := int(item["cost"])
		if not path.is_empty():
			candidates.append({"position": current, "path": path, "cost": cost})
		if cost >= max_cost:
			continue

		for neighbor: Dictionary in _path_neighbors(state, actor, current):
			var next_cost := cost + _terrain_movement_cost(state, neighbor)
			if next_cost > max_cost:
				continue
			var key := _position_key(neighbor)
			if best_cost.has(key) and int(best_cost[key]) <= next_cost:
				continue
			best_cost[key] = next_cost
			var next_path := path.duplicate(true)
			next_path.append(neighbor)
			queue.append({"position": neighbor, "path": next_path, "cost": next_cost})

	var current_distance := _chebyshev(start, target["position"])
	var legal_candidates: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		var position: Dictionary = candidate["position"]
		if _move_rejection(state, actor, position) != "":
			continue
		if _chebyshev(position, target["position"]) >= current_distance:
			continue
		legal_candidates.append(candidate)

	legal_candidates.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_position: Dictionary = first["position"]
		var second_position: Dictionary = second["position"]
		var first_adjacent := 0 if _chebyshev(first_position, target["position"]) == 1 else 1
		var second_adjacent := 0 if _chebyshev(second_position, target["position"]) == 1 else 1
		if first_adjacent != second_adjacent:
			return first_adjacent < second_adjacent
		var first_chebyshev := _chebyshev(first_position, target["position"])
		var second_chebyshev := _chebyshev(second_position, target["position"])
		if first_chebyshev != second_chebyshev:
			return first_chebyshev < second_chebyshev
		var first_manhattan := _manhattan(first_position, target["position"])
		var second_manhattan := _manhattan(second_position, target["position"])
		if first_manhattan != second_manhattan:
			return first_manhattan < second_manhattan
		if int(first["cost"]) != int(second["cost"]):
			return int(first["cost"]) < int(second["cost"])
		if first["path"].size() != second["path"].size():
			return first["path"].size() < second["path"].size()
		if int(first_position["y"]) != int(second_position["y"]):
			return int(first_position["y"]) < int(second_position["y"])
		return int(first_position["x"]) < int(second_position["x"])
	)
	return legal_candidates[0]["position"] if not legal_candidates.is_empty() else {}


static func _first_path_step_toward(state: Dictionary, actor: Dictionary, target: Dictionary) -> Dictionary:
	var start: Dictionary = actor["position"]
	var queue: Array[Dictionary] = [{"position": start, "path": []}]
	var visited := {_position_key(start): true}

	while not queue.is_empty():
		var item: Dictionary = queue.pop_front()
		var current: Dictionary = item["position"]
		var path: Array = item["path"]
		if not path.is_empty() and _chebyshev(current, target["position"]) == 1:
			return path[0]

		for neighbor: Dictionary in _path_neighbors(state, actor, current):
			var key := _position_key(neighbor)
			if visited.has(key):
				continue
			visited[key] = true
			var next_path := path.duplicate(true)
			next_path.append(neighbor)
			queue.append({"position": neighbor, "path": next_path})

	return {}


static func _path_neighbors(state: Dictionary, actor: Dictionary, position: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = [
		{"x": position["x"] - 1, "y": position["y"]},
		{"x": position["x"] + 1, "y": position["y"]},
		{"x": position["x"], "y": position["y"] - 1},
		{"x": position["x"], "y": position["y"] + 1},
		{"x": position["x"] - 1, "y": position["y"] - 1},
		{"x": position["x"] - 1, "y": position["y"] + 1},
		{"x": position["x"] + 1, "y": position["y"] - 1},
		{"x": position["x"] + 1, "y": position["y"] + 1},
	]
	var legal_candidates: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		if _path_position_is_legal(state, actor, position, candidate):
			legal_candidates.append(candidate)

	legal_candidates.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		if int(first["y"]) != int(second["y"]):
			return int(first["y"]) < int(second["y"])
		return int(first["x"]) < int(second["x"])
	)
	return legal_candidates


static func _path_position_is_legal(state: Dictionary, actor: Dictionary, origin: Dictionary, position: Dictionary) -> bool:
	if not _inside_grid(state, position):
		return false
	if not _is_walkable_tile(state, position):
		return false
	if _is_diagonal_step(origin, position) and not _diagonal_step_allowed(state, origin, position):
		return false
	var unit := _living_unit_at(state, position)
	return unit.is_empty() or unit["id"] == actor["id"]


static func _ranged_hit_chance(state: Dictionary, actor: Dictionary, target: Dictionary, action_id: String) -> int:
	var weapon_profile: Dictionary = _profile_for_action(state, actor, action_id)
	return clampi(
		_base_hit_chance(weapon_profile)
		+ _stat(actor, "accuracy")
		- _stat(target, "evasion")
		+ _terrain_hit_modifier(state, actor, action_id)
		+ _cover_hit_modifier(state, target, action_id),
		MIN_HIT_CHANCE,
		MAX_HIT_CHANCE
	)


static func _is_diagonal_step(origin: Dictionary, destination: Dictionary) -> bool:
	return abs(origin["x"] - destination["x"]) == 1 and abs(origin["y"] - destination["y"]) == 1


static func _diagonal_step_allowed(state: Dictionary, origin: Dictionary, destination: Dictionary) -> bool:
	var side_a := {"x": destination["x"], "y": origin["y"]}
	var side_b := {"x": origin["x"], "y": destination["y"]}
	return _is_walkable_tile(state, side_a) and _is_walkable_tile(state, side_b)


static func _position_key(position: Dictionary) -> String:
	return "%s,%s" % [position["x"], position["y"]]


static func _positions_equal(first: Dictionary, second: Dictionary) -> bool:
	return int(first["x"]) == int(second["x"]) and int(first["y"]) == int(second["y"])


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


static func _combat_result_payload(state: Dictionary) -> Dictionary:
	var result := _combat_result(state)
	var payload := {
		"result": result,
		"combat_id": state["id"],
		"source_dungeon_id": state.get("source_dungeon_id", ""),
		"source_room_id": state.get("source_room_id", ""),
		"surviving_players": [],
		"defeated_player_ids": [],
		"defeated_enemy_ids": [],
		"remaining_enemies": [],
		"rewards": _reward_result_summary(state.get("rewards", {})),
	}
	if result == "in_progress":
		return payload

	for unit: Dictionary in state["units"]:
		if unit["team"] == "player":
			if int(unit["resources"]["hp"]) > 0:
				payload["surviving_players"].append(_unit_result_summary(unit))
			else:
				payload["defeated_player_ids"].append(unit["id"])
		elif unit["team"] == "enemy":
			if int(unit["resources"]["hp"]) > 0:
				payload["remaining_enemies"].append(_unit_result_summary(unit))
			else:
				payload["defeated_enemy_ids"].append(unit["id"])
	return payload


static func _reward_result_summary(rewards: Dictionary) -> Dictionary:
	return {
		"xp": int(rewards.get("xp", 0)),
		"gold": int(rewards.get("gold", 0)),
		"items": rewards.get("items", []).duplicate(true),
	}


static func _unit_result_summary(unit: Dictionary) -> Dictionary:
	var summary := {
		"id": unit["id"],
		"team": unit["team"],
		"hp": int(unit["resources"].get("hp", 0)),
		"max_hp": int(unit["stats"].get("max_hp", 0)),
		"statuses": unit.get("statuses", []).duplicate(true),
		"position": unit.get("position", {}).duplicate(true),
	}
	if unit.get("resources", {}).has("ap"):
		summary["ap"] = int(unit["resources"].get("ap", 0))
	if unit.get("resources", {}).has("mp"):
		summary["mp"] = int(unit["resources"].get("mp", 0))
	return summary
