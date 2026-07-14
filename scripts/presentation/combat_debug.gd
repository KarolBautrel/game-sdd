extends Control

const CombatResolver := preload("res://scripts/domain/combat_resolver.gd")

const ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_03_move.json"
const TILE_SIZE := 56
const TILE_GAP := 4
const ACTION_IDS := ["move", "basic_attack", "ranged_attack", "defend", "end_turn", "enemy_ai", "enemy_turn", "reset"]
const ACTION_LABELS := {
	"move": "Move",
	"basic_attack": "Melee attack",
	"ranged_attack": "Ranged attack",
	"defend": "Defend",
	"end_turn": "End turn",
	"enemy_ai": "Enemy AI once",
	"enemy_turn": "Enemy turn helper",
	"reset": "Reset encounter",
}

@onready var grid_container: GridContainer = %GridContainer
@onready var status_label: Label = %StatusLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var legend_label: Label = %LegendLabel
@onready var unit_list_label: Label = %UnitListLabel
@onready var event_log_label: Label = %EventLogLabel
@onready var command_buttons: VBoxContainer = %CommandButtons

var state: Dictionary = {}
var command_index := 1
var selected_action := "move"
var last_feedback := "Select an action."


func _ready() -> void:
	_reset_debug_encounter()


func _reset_debug_encounter() -> void:
	state = _load_json(ENCOUNTER_PATH)
	state["event_log"] = []
	command_index = 1
	selected_action = "move"
	last_feedback = "Encounter reset."
	var result := CombatResolver.simulate(state, [])
	state = result["state"]
	_render()


func _render() -> void:
	_clear_grid()
	grid_container.columns = int(state["grid"]["width"])

	for y in range(int(state["grid"]["height"])):
		for x in range(int(state["grid"]["width"])):
			grid_container.add_child(_build_tile({"x": x, "y": y}))

	_render_status()
	_render_feedback()
	_render_legend()
	_render_unit_list()
	_render_event_log()
	_render_command_buttons()


func _build_tile(position: Dictionary) -> Button:
	var tile := Button.new()
	tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.text = _tile_text(position)
	tile.tooltip_text = "x:%s y:%s" % [position["x"], position["y"]]
	tile.pressed.connect(func() -> void:
		_on_tile_pressed(position)
	)

	var unit := _living_unit_at(position)
	if not unit.is_empty():
		if unit["team"] == "player":
			tile.modulate = Color(0.55, 0.8, 1.0)
		else:
			tile.modulate = Color(1.0, 0.48, 0.42)
	elif _tile_type(position) == "blocked":
		tile.modulate = Color(0.32, 0.32, 0.34)
	elif _tile_type(position) == "highground":
		tile.modulate = Color(0.84, 0.72, 0.42)
	else:
		tile.modulate = Color(0.64, 0.66, 0.58)

	if _is_active_unit_at(position):
		tile.modulate = Color(1.0, 0.92, 0.35)
	elif _is_legal_target_for_selected_action(position):
		tile.modulate = Color(0.55, 1.0, 0.55)

	return tile


func _tile_text(position: Dictionary) -> String:
	var unit := _living_unit_at(position)
	if unit.is_empty():
		match _tile_type(position):
			"blocked":
				return "BLOCK"
			"highground":
				return "HIGH"
			_:
				return ""

	var hp: int = unit["resources"]["hp"]
	var ap: int = unit["resources"]["ap"]
	if unit["team"] == "player":
		return "P\nHP %s\nAP %s" % [hp, ap]
	return "E\nHP %s\nAP %s" % [hp, ap]


func _render_status() -> void:
	var active := _unit_by_id(state["turn_state"]["active_unit_id"])
	status_label.text = "Round %s | Result: %s\nActive: %s (%s) | HP %s | AP %s | Selected: %s" % [
		state["turn_state"]["round"],
		_combat_result(),
		active.get("id", "missing"),
		active.get("team", "missing"),
		active.get("resources", {}).get("hp", "?"),
		active.get("resources", {}).get("ap", "?"),
		ACTION_LABELS.get(selected_action, selected_action),
	]


func _render_feedback() -> void:
	feedback_label.text = last_feedback


func _render_legend() -> void:
	legend_label.text = "Blue: player | Red: enemy | Yellow: active | Green: legal target | Gold: highground | Dark: blocked"


func _render_unit_list() -> void:
	var lines: Array[String] = []
	for unit: Dictionary in state["units"]:
		var marker := "*" if unit["id"] == state["turn_state"]["active_unit_id"] else " "
		lines.append("%s %s [%s] HP %s/%s AP %s/%s ACC %s EVA %s pos (%s,%s)" % [
			marker,
			unit["id"],
			unit["team"],
			unit["resources"]["hp"],
			unit["stats"]["max_hp"],
			unit["resources"]["ap"],
			unit["stats"]["max_ap"],
			unit["stats"].get("accuracy", 0),
			unit["stats"].get("evasion", 0),
			unit["position"]["x"],
			unit["position"]["y"],
		])
	unit_list_label.text = "\n".join(lines)


func _render_event_log() -> void:
	var lines: Array[String] = []
	for event: Dictionary in state["event_log"]:
		lines.append("%s. %s %s" % [
			event["sequence"],
			event["type"],
			_event_summary(event),
		])
	event_log_label.text = "\n".join(lines)


func _render_command_buttons() -> void:
	for child in command_buttons.get_children():
		child.queue_free()

	for action_id in ACTION_IDS:
		var button := Button.new()
		button.text = ACTION_LABELS.get(action_id, action_id)
		button.toggle_mode = true
		button.button_pressed = selected_action == action_id
		button.disabled = _combat_result() != "in_progress" and action_id != "reset"
		button.pressed.connect(func() -> void:
			selected_action = action_id
			if action_id == "reset":
				_reset_debug_encounter()
			elif action_id == "enemy_turn":
				_run_enemy_turn_helper()
			elif action_id == "enemy_ai":
				_run_command(CombatResolver.choose_enemy_command(state, "cmd_%03d" % command_index))
			elif action_id in ["defend", "end_turn"]:
				_run_command(_build_command(action_id, {}))
			else:
				last_feedback = "Select a highlighted target for %s." % ACTION_LABELS.get(action_id, action_id)
				_render()
		)
		command_buttons.add_child(button)


func _on_tile_pressed(position: Dictionary) -> void:
	if selected_action == "move":
		_run_command(_build_command("move", {
			"type": "tile",
			"position": position,
		}))
	elif selected_action == "basic_attack":
		var unit := _living_unit_at(position)
		_run_command(_build_command("basic_attack", {
			"type": "unit",
			"unit_id": unit.get("id", ""),
		}))
	elif selected_action == "ranged_attack":
		var unit := _living_unit_at(position)
		_run_command(_build_command("ranged_attack", {
			"type": "unit",
			"unit_id": unit.get("id", ""),
		}))


func _build_command(action_id: String, target: Dictionary) -> Dictionary:
	var active_unit_id: String = state["turn_state"]["active_unit_id"]
	return {
		"id": "cmd_%03d" % command_index,
		"type": "perform_action",
		"actor_id": active_unit_id,
		"action_id": action_id,
		"target": target if not target.is_empty() else {"type": "none"},
	}


func _run_command(command: Dictionary) -> void:
	if _combat_result() != "in_progress":
		last_feedback = "Combat already ended."
		_render()
		return

	var previous_log: Array = state["event_log"].duplicate(true)
	var result := CombatResolver.simulate(_state_without_log(), [command])
	state = result["state"]
	var new_events: Array = _events_after_startup(result["state"]["event_log"])
	state["event_log"] = previous_log + new_events
	last_feedback = _feedback_from_events(new_events)
	command_index += 1
	_render()


func _run_enemy_turn_helper() -> void:
	if _combat_result() != "in_progress":
		last_feedback = "Combat already ended."
		_render()
		return

	var safety_limit := 4
	while safety_limit > 0 and _combat_result() == "in_progress":
		var active := _unit_by_id(state["turn_state"]["active_unit_id"])
		if active.is_empty():
			last_feedback = "No active unit."
			break

		if active["team"] == "player":
			_run_command_without_render(_build_command("end_turn", {}))
		elif active["team"] == "enemy":
			_run_command_without_render(CombatResolver.choose_enemy_command(state, "cmd_%03d" % command_index))
		else:
			last_feedback = "Unknown active team."
			break

		var next_active := _unit_by_id(state["turn_state"]["active_unit_id"])
		if next_active.is_empty() or next_active["team"] == "player":
			break

		safety_limit -= 1

	last_feedback = "Enemy turn helper complete."
	_render()


func _run_command_without_render(command: Dictionary) -> void:
	if _combat_result() != "in_progress":
		return

	var previous_log: Array = state["event_log"].duplicate(true)
	var result := CombatResolver.simulate(_state_without_log(), [command])
	state = result["state"]
	var new_events: Array = _events_after_startup(result["state"]["event_log"])
	state["event_log"] = previous_log + new_events
	command_index += 1


func _state_without_log() -> Dictionary:
	var clean_state := state.duplicate(true)
	clean_state["event_log"] = []
	return clean_state


func _events_after_startup(events: Array) -> Array:
	var filtered: Array = []
	for event: Dictionary in events:
		if event["type"] in ["combat_started", "turn_started"] and event["sequence"] <= 2:
			continue
		var next_event := event.duplicate(true)
		next_event["sequence"] = state["event_log"].size() + filtered.size() + 1
		filtered.append(next_event)
	return filtered


func _event_summary(event: Dictionary) -> String:
	if event["type"] == "command_rejected":
		return "(%s)" % event.get("reason", "")
	if event["type"] == "damage_applied":
		return "(%s damage to %s)" % [event.get("damage", "?"), event.get("target_unit_id", "?")]
	if event["type"] == "hit_roll_resolved":
		return "(%s: roll %s vs %s%%, base %s + acc %s - eva %s)" % [
			event.get("outcome", "?"),
			event.get("roll", "?"),
			event.get("hit_chance", "?"),
			event.get("base_hit_chance", "?"),
			event.get("accuracy_modifier", "?"),
			event.get("evasion_modifier", "?"),
		]
	if event["type"] == "unit_moved":
		return "(%s -> %s)" % [event.get("from", {}), event.get("to", {})]
	if event.has("action_id"):
		return "(%s)" % event["action_id"]
	return ""


func _feedback_from_events(events: Array) -> String:
	for event: Dictionary in events:
		if event["type"] == "command_rejected":
			return "Rejected: %s" % event.get("reason", "unknown")
	for event: Dictionary in events:
		if event["type"] == "combat_ended":
			return "Combat ended: %s" % event.get("result", "unknown")
	for event: Dictionary in events:
		if event["type"] == "hit_roll_resolved" and event.get("outcome", "") == "miss":
			return "Miss: roll %s vs %s%%" % [event.get("roll", "?"), event.get("hit_chance", "?")]
	for event: Dictionary in events:
		if event["type"] == "damage_applied":
			return "Damage: %s to %s" % [event.get("damage", "?"), event.get("target_unit_id", "?")]
	for event: Dictionary in events:
		if event["type"] == "unit_moved":
			return "Moved to %s" % event.get("to", {})
	for event: Dictionary in events:
		if event["type"] == "status_applied":
			return "Status applied: %s" % event.get("status", {}).get("id", "unknown")
	return "Command accepted."


func _clear_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()


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


func _unit_by_id(unit_id: String) -> Dictionary:
	for unit: Dictionary in state["units"]:
		if unit["id"] == unit_id:
			return unit
	return {}


func _living_unit_at(position: Dictionary) -> Dictionary:
	for unit: Dictionary in state["units"]:
		if unit["resources"]["hp"] > 0 and _positions_equal(unit["position"], position):
			return unit
	return {}


func _tile_type(position: Dictionary) -> String:
	for tile: Dictionary in state["grid"]["tiles"]:
		if int(tile["x"]) == int(position["x"]) and int(tile["y"]) == int(position["y"]):
			return tile["type"]
	return ""


func _is_active_unit_at(position: Dictionary) -> bool:
	var active := _unit_by_id(state["turn_state"]["active_unit_id"])
	return not active.is_empty() and active["resources"]["hp"] > 0 and _positions_equal(active["position"], position)


func _is_legal_target_for_selected_action(position: Dictionary) -> bool:
	if _combat_result() != "in_progress":
		return false
	if selected_action == "move":
		return _command_would_be_accepted(_build_command("move", {
			"type": "tile",
			"position": position,
		}))
	if selected_action == "basic_attack":
		var unit := _living_unit_at(position)
		if unit.is_empty():
			return false
		return _command_would_be_accepted(_build_command("basic_attack", {
			"type": "unit",
			"unit_id": unit["id"],
		}))
	if selected_action == "ranged_attack":
		var unit := _living_unit_at(position)
		if unit.is_empty():
			return false
		return _command_would_be_accepted(_build_command("ranged_attack", {
			"type": "unit",
			"unit_id": unit["id"],
		}))
	return false


func _command_would_be_accepted(command: Dictionary) -> bool:
	var result: Dictionary = CombatResolver.simulate(_state_without_log(), [command])
	for event: Dictionary in _events_after_startup(result["state"]["event_log"]):
		if event["type"] == "command_rejected":
			return false
	return true


func _positions_equal(first: Dictionary, second: Dictionary) -> bool:
	return int(first["x"]) == int(second["x"]) and int(first["y"]) == int(second["y"])


func _combat_result() -> String:
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
