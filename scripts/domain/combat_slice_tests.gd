extends SceneTree

const CombatResolver := preload("res://scripts/domain/combat_resolver.gd")

const SLICES := [
	{
		"id": "slice_01_basic_attack",
		"encounter": "res://resources/data/combat_encounters/slice_01_basic_attack.json",
		"commands": "res://tests/data/combat_commands/slice_01_basic_attack_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "damage_applied"],
		"expected_result": "in_progress",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}},
			"unit_enemy_001": {"resources": {"hp": 4}},
		},
	},
	{
		"id": "slice_02_invalid_no_ap",
		"encounter": "res://resources/data/combat_encounters/slice_02_invalid_no_ap.json",
		"commands": "res://tests/data/combat_commands/slice_02_invalid_no_ap_commands.json",
		"expected_events": ["combat_started", "turn_started", "command_rejected"],
		"expected_result": "in_progress",
		"expected_rejection": "not_enough_ap",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0, "hp": 10}, "position": {"x": 1, "y": 1}},
			"unit_enemy_001": {"resources": {"hp": 6}, "position": {"x": 2, "y": 1}},
		},
	},
	{
		"id": "slice_03_move",
		"encounter": "res://resources/data/combat_encounters/slice_03_move.json",
		"commands": "res://tests/data/combat_commands/slice_03_move_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "unit_moved"],
		"expected_result": "in_progress",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}, "position": {"x": 2, "y": 1}},
			"unit_enemy_001": {"resources": {"hp": 6}},
		},
	},
	{
		"id": "slice_04_move_occupied",
		"encounter": "res://resources/data/combat_encounters/slice_04_move_occupied.json",
		"commands": "res://tests/data/combat_commands/slice_04_move_occupied_commands.json",
		"expected_events": ["combat_started", "turn_started", "command_rejected"],
		"expected_result": "in_progress",
		"expected_rejection": "destination_occupied",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 1}, "position": {"x": 1, "y": 1}},
			"unit_enemy_001": {"resources": {"hp": 6}, "position": {"x": 2, "y": 1}},
		},
	},
	{
		"id": "slice_05_move_blocked",
		"encounter": "res://resources/data/combat_encounters/slice_05_move_blocked.json",
		"commands": "res://tests/data/combat_commands/slice_05_move_blocked_commands.json",
		"expected_events": ["combat_started", "turn_started", "command_rejected"],
		"expected_result": "in_progress",
		"expected_rejection": "destination_not_walkable",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 1}, "position": {"x": 1, "y": 1}},
			"unit_enemy_001": {"resources": {"hp": 6}, "position": {"x": 4, "y": 1}},
		},
	},
	{
		"id": "slice_06_defend",
		"encounter": "res://resources/data/combat_encounters/slice_06_defend.json",
		"commands": "res://tests/data/combat_commands/slice_06_defend_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "status_applied"],
		"expected_result": "in_progress",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}, "statuses": ["defending"]},
		},
	},
	{
		"id": "slice_07_end_turn",
		"encounter": "res://resources/data/combat_encounters/slice_07_end_turn.json",
		"commands": "res://tests/data/combat_commands/slice_07_end_turn_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "turn_ended", "turn_started"],
		"expected_result": "in_progress",
		"expected_active_unit_id": "unit_enemy_001",
		"unit_expectations": {
			"unit_enemy_001": {"resources": {"ap": 1}},
		},
	},
	{
		"id": "slice_08_enemy_ai_adjacent_attack",
		"encounter": "res://resources/data/combat_encounters/slice_08_enemy_ai_adjacent_attack.json",
		"ai_command": true,
		"expected_command_action": "basic_attack",
		"expected_command_actor": "unit_enemy_001",
		"expected_command_target": "unit_player_001",
		"expected_events": ["combat_started", "turn_started", "action_performed", "damage_applied"],
		"expected_result": "in_progress",
		"unit_expectations": {
			"unit_player_001": {"resources": {"hp": 8}},
			"unit_enemy_001": {"resources": {"ap": 0}},
		},
	},
	{
		"id": "slice_09_enemy_ai_move_toward_player",
		"encounter": "res://resources/data/combat_encounters/slice_09_enemy_ai_move_toward_player.json",
		"ai_command": true,
		"expected_command_action": "move",
		"expected_command_actor": "unit_enemy_001",
		"expected_command_position": {"x": 3, "y": 1},
		"expected_events": ["combat_started", "turn_started", "action_performed", "unit_moved"],
		"expected_result": "in_progress",
		"unit_expectations": {
			"unit_enemy_001": {"resources": {"ap": 0}, "position": {"x": 3, "y": 1}},
		},
	},
	{
		"id": "slice_10_diagonal_move",
		"encounter": "res://resources/data/combat_encounters/slice_10_diagonal_move.json",
		"commands": "res://tests/data/combat_commands/slice_10_diagonal_move_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "unit_moved"],
		"expected_result": "in_progress",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}, "position": {"x": 2, "y": 2}},
		},
	},
	{
		"id": "slice_11_diagonal_attack",
		"encounter": "res://resources/data/combat_encounters/slice_11_diagonal_attack.json",
		"commands": "res://tests/data/combat_commands/slice_11_diagonal_attack_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "damage_applied"],
		"expected_result": "in_progress",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}},
			"unit_enemy_001": {"resources": {"hp": 4}},
		},
	},
	{
		"id": "slice_12_enemy_ai_no_ap_end_turn",
		"encounter": "res://resources/data/combat_encounters/slice_12_enemy_ai_no_ap_end_turn.json",
		"ai_command": true,
		"expected_command_action": "end_turn",
		"expected_command_actor": "unit_enemy_001",
		"expected_events": ["combat_started", "turn_started", "action_performed", "turn_ended", "turn_started"],
		"expected_result": "in_progress",
		"expected_active_unit_id": "unit_player_001",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 1}},
			"unit_enemy_001": {"resources": {"ap": 0}},
		},
	},
	{
		"id": "slice_13_round_cycle_player_enemy_player",
		"encounter": "res://resources/data/combat_encounters/slice_13_round_cycle_player_enemy_player.json",
		"commands": "res://tests/data/combat_commands/slice_13_round_cycle_player_enemy_player_commands.json",
		"expected_events": [
			"combat_started",
			"turn_started",
			"action_performed",
			"turn_ended",
			"turn_started",
			"action_performed",
			"unit_moved",
			"action_performed",
			"turn_ended",
			"turn_started",
		],
		"expected_result": "in_progress",
		"expected_active_unit_id": "unit_player_001",
		"expected_round": 2,
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 1}},
			"unit_enemy_001": {"resources": {"ap": 0}, "position": {"x": 2, "y": 1}},
		},
	},
	{
		"id": "slice_14_victory_last_enemy_defeated",
		"encounter": "res://resources/data/combat_encounters/slice_14_victory_last_enemy_defeated.json",
		"commands": "res://tests/data/combat_commands/slice_14_victory_last_enemy_defeated_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "damage_applied", "unit_defeated", "combat_ended"],
		"expected_result": "victory",
		"expected_combat_ended_result": "victory",
		"unit_expectations": {
			"unit_enemy_001": {"resources": {"hp": 0}},
		},
	},
	{
		"id": "slice_15_defeat_last_player_defeated",
		"encounter": "res://resources/data/combat_encounters/slice_15_defeat_last_player_defeated.json",
		"commands": "res://tests/data/combat_commands/slice_15_defeat_last_player_defeated_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "damage_applied", "unit_defeated", "combat_ended"],
		"expected_result": "defeat",
		"expected_combat_ended_result": "defeat",
		"unit_expectations": {
			"unit_player_001": {"resources": {"hp": 0}},
		},
	},
	{
		"id": "slice_16_command_after_combat_end_rejected",
		"encounter": "res://resources/data/combat_encounters/slice_16_command_after_combat_end_rejected.json",
		"commands": "res://tests/data/combat_commands/slice_16_command_after_combat_end_rejected_commands.json",
		"expected_events": ["combat_started", "turn_started", "command_rejected"],
		"expected_result": "victory",
		"expected_rejection": "combat_already_ended",
		"unit_expectations": {
			"unit_player_001": {"position": {"x": 1, "y": 1}},
		},
	},
	{
		"id": "slice_19_highground_walkable",
		"encounter": "res://resources/data/combat_encounters/slice_19_highground_walkable.json",
		"commands": "res://tests/data/combat_commands/slice_19_highground_walkable_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "unit_moved"],
		"expected_result": "in_progress",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}, "position": {"x": 2, "y": 1}},
		},
	},
	{
		"id": "slice_21_ranged_attack_in_range",
		"encounter": "res://resources/data/combat_encounters/slice_21_ranged_attack_in_range.json",
		"commands": "res://tests/data/combat_commands/slice_21_ranged_attack_in_range_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"],
		"expected_result": "in_progress",
		"expected_hit_roll": {"roll": 38, "hit_chance": 70, "outcome": "hit"},
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}},
			"unit_enemy_001": {"resources": {"hp": 4}},
		},
	},
	{
		"id": "slice_22_ranged_attack_out_of_range",
		"encounter": "res://resources/data/combat_encounters/slice_22_ranged_attack_out_of_range.json",
		"commands": "res://tests/data/combat_commands/slice_22_ranged_attack_out_of_range_commands.json",
		"expected_events": ["combat_started", "turn_started", "command_rejected"],
		"expected_result": "in_progress",
		"expected_rejection": "target_out_of_range",
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 1}},
			"unit_enemy_001": {"resources": {"hp": 6}},
		},
	},
	{
		"id": "slice_23_ranged_attack_hit_roll",
		"encounter": "res://resources/data/combat_encounters/slice_23_ranged_attack_hit_roll.json",
		"commands": "res://tests/data/combat_commands/slice_23_ranged_attack_hit_roll_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"],
		"expected_result": "in_progress",
		"expected_hit_roll": {"roll": 40, "hit_chance": 70, "outcome": "hit"},
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}},
			"unit_enemy_001": {"resources": {"hp": 4}},
		},
	},
	{
		"id": "slice_24_ranged_attack_miss",
		"encounter": "res://resources/data/combat_encounters/slice_24_ranged_attack_miss.json",
		"commands": "res://tests/data/combat_commands/slice_24_ranged_attack_miss_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "hit_roll_resolved"],
		"expected_result": "in_progress",
		"expected_hit_roll": {"roll": 72, "hit_chance": 70, "outcome": "miss"},
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}},
			"unit_enemy_001": {"resources": {"hp": 6}},
		},
	},
	{
		"id": "slice_25_accuracy_increases_hit_chance",
		"encounter": "res://resources/data/combat_encounters/slice_25_accuracy_increases_hit_chance.json",
		"commands": "res://tests/data/combat_commands/slice_25_accuracy_increases_hit_chance_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"],
		"expected_result": "in_progress",
		"expected_hit_roll": {
			"roll": 72,
			"base_hit_chance": 70,
			"accuracy_modifier": 10,
			"evasion_modifier": 0,
			"hit_chance": 80,
			"outcome": "hit",
		},
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}},
			"unit_enemy_001": {"resources": {"hp": 4}},
		},
	},
	{
		"id": "slice_26_evasion_decreases_hit_chance",
		"encounter": "res://resources/data/combat_encounters/slice_26_evasion_decreases_hit_chance.json",
		"commands": "res://tests/data/combat_commands/slice_26_evasion_decreases_hit_chance_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "hit_roll_resolved"],
		"expected_result": "in_progress",
		"expected_hit_roll": {
			"roll": 40,
			"base_hit_chance": 70,
			"accuracy_modifier": 0,
			"evasion_modifier": 40,
			"hit_chance": 30,
			"outcome": "miss",
		},
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}},
			"unit_enemy_001": {"resources": {"hp": 6}},
		},
	},
	{
		"id": "slice_27_highground_increases_ranged_hit_chance",
		"encounter": "res://resources/data/combat_encounters/slice_27_highground_increases_ranged_hit_chance.json",
		"commands": "res://tests/data/combat_commands/slice_27_highground_increases_ranged_hit_chance_commands.json",
		"expected_events": ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"],
		"expected_result": "in_progress",
		"expected_hit_roll": {
			"roll": 72,
			"base_hit_chance": 70,
			"accuracy_modifier": 0,
			"evasion_modifier": 0,
			"terrain_modifier": 10,
			"hit_chance": 80,
			"outcome": "hit",
		},
		"unit_expectations": {
			"unit_player_001": {"resources": {"ap": 0}},
			"unit_enemy_001": {"resources": {"hp": 4}},
		},
	},
]


func _init() -> void:
	var errors: Array[String] = []
	for spec: Dictionary in SLICES:
		errors.append_array(_validate_slice(spec))

	if errors.is_empty():
		print("Godot combat slice validation passed.")
		quit(0)
		return

	push_error("Godot combat slice validation failed.")
	for error: String in errors:
		push_error(error)
	quit(1)


func _validate_slice(spec: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var encounter: Dictionary = _load_json(spec["encounter"])
	var commands: Array = _commands_for_spec(spec, encounter)
	var result: Dictionary = CombatResolver.simulate(encounter, commands)
	var state: Dictionary = result["state"]

	if result["result"] != spec["expected_result"]:
		errors.append("%s: expected result %s, got %s" % [spec["id"], spec["expected_result"], result["result"]])

	var event_types: Array[String] = _event_types(state)
	if event_types != spec["expected_events"]:
		errors.append("%s: expected events %s, got %s" % [spec["id"], spec["expected_events"], event_types])

	if spec.has("expected_rejection"):
		var rejection: Dictionary = _first_event(state, "command_rejected")
		if rejection.is_empty():
			errors.append("%s: expected command_rejected event" % spec["id"])
		elif rejection.get("reason", "") != spec["expected_rejection"]:
			errors.append("%s: expected rejection %s, got %s" % [spec["id"], spec["expected_rejection"], rejection.get("reason", "")])

	if spec.has("expected_combat_ended_result"):
		var ended: Dictionary = _first_event(state, "combat_ended")
		if ended.is_empty():
			errors.append("%s: expected combat_ended event" % spec["id"])
		elif ended.get("result", "") != spec["expected_combat_ended_result"]:
			errors.append("%s: expected combat_ended result %s, got %s" % [spec["id"], spec["expected_combat_ended_result"], ended.get("result", "")])

	if spec.has("expected_hit_roll"):
		var hit_roll: Dictionary = _first_event(state, "hit_roll_resolved")
		var expected_hit_roll: Dictionary = spec["expected_hit_roll"]
		if hit_roll.is_empty():
			errors.append("%s: expected hit_roll_resolved event" % spec["id"])
		elif not _hit_roll_matches(hit_roll, expected_hit_roll):
			errors.append("%s: unexpected hit roll payload %s" % [spec["id"], hit_roll])

	if spec.has("expected_active_unit_id") and state["turn_state"]["active_unit_id"] != spec["expected_active_unit_id"]:
		errors.append("%s: expected active unit %s, got %s" % [spec["id"], spec["expected_active_unit_id"], state["turn_state"]["active_unit_id"]])

	if spec.has("expected_round") and int(state["turn_state"]["round"]) != int(spec["expected_round"]):
		errors.append("%s: expected round %s, got %s" % [spec["id"], spec["expected_round"], state["turn_state"]["round"]])

	for unit_id: String in spec["unit_expectations"]:
		var unit := _unit_by_id(state, unit_id)
		var expectation: Dictionary = spec["unit_expectations"][unit_id]
		errors.append_array(_validate_unit_expectation(spec["id"], unit, expectation))

	var replay: Dictionary = CombatResolver.simulate(encounter, commands)
	if replay["state"]["event_log"] != state["event_log"]:
		errors.append("%s: replay event log differs" % spec["id"])

	return errors


func _commands_for_spec(spec: Dictionary, encounter: Dictionary) -> Array:
	if spec.get("ai_command", false):
		var command: Dictionary = CombatResolver.choose_enemy_command(encounter)
		if command["action_id"] != spec["expected_command_action"]:
			push_error("%s: expected AI command %s, got %s" % [spec["id"], spec["expected_command_action"], command["action_id"]])
		if command["actor_id"] != spec["expected_command_actor"]:
			push_error("%s: expected AI actor %s, got %s" % [spec["id"], spec["expected_command_actor"], command["actor_id"]])
		if spec.has("expected_command_target") and command["target"].get("unit_id", "") != spec["expected_command_target"]:
			push_error("%s: expected AI target %s, got %s" % [spec["id"], spec["expected_command_target"], command["target"].get("unit_id", "")])
		if spec.has("expected_command_position") and not _positions_equal(command["target"].get("position", {}), spec["expected_command_position"]):
			push_error("%s: expected AI position %s, got %s" % [spec["id"], spec["expected_command_position"], command["target"].get("position", {})])
		return [command]

	return _load_json(spec["commands"])


func _validate_unit_expectation(slice_id: String, unit: Dictionary, expectation: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if expectation.has("resources"):
		for resource_name: String in expectation["resources"]:
			var expected: int = expectation["resources"][resource_name]
			var actual: int = unit["resources"][resource_name]
			if actual != expected:
				errors.append("%s: expected %s %s, got %s" % [slice_id, resource_name, expected, actual])

	if expectation.has("position") and not _positions_equal(unit["position"], expectation["position"]):
		errors.append("%s: expected position %s, got %s" % [slice_id, expectation["position"], unit["position"]])

	if expectation.has("statuses"):
		var status_ids: Array[String] = []
		for status: Dictionary in unit["statuses"]:
			status_ids.append(status["id"])
		if status_ids != expectation["statuses"]:
			errors.append("%s: expected statuses %s, got %s" % [slice_id, expectation["statuses"], status_ids])

	return errors


func _load_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open JSON file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("Cannot parse JSON file: %s" % path)
		return {}
	return parsed


func _event_types(state: Dictionary) -> Array[String]:
	var types: Array[String] = []
	for event: Dictionary in state["event_log"]:
		types.append(event["type"])
	return types


func _positions_equal(actual: Dictionary, expected: Dictionary) -> bool:
	return int(actual["x"]) == int(expected["x"]) and int(actual["y"]) == int(expected["y"])


func _first_event(state: Dictionary, event_type: String) -> Dictionary:
	for event: Dictionary in state["event_log"]:
		if event["type"] == event_type:
			return event
	return {}


func _hit_roll_matches(actual: Dictionary, expected: Dictionary) -> bool:
	for key: String in expected:
		if key == "outcome":
			if actual.get(key, "") != expected[key]:
				return false
		elif int(actual.get(key, 0)) != int(expected[key]):
			return false
	return true


func _unit_by_id(state: Dictionary, unit_id: String) -> Dictionary:
	for unit: Dictionary in state["units"]:
		if unit["id"] == unit_id:
			return unit
	return {}
