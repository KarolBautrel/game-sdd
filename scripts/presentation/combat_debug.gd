extends Control

const CombatResolver := preload("res://scripts/domain/combat_resolver.gd")

const ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_03_move.json"
const TILE_SIZE := 56
const TILE_GAP := 4

@onready var grid_container: GridContainer = %GridContainer
@onready var status_label: Label = %StatusLabel
@onready var event_log_label: Label = %EventLogLabel
@onready var command_buttons: VBoxContainer = %CommandButtons

var state: Dictionary = {}
var command_index := 1
var selected_action := "move"


func _ready() -> void:
	state = _load_json(ENCOUNTER_PATH)
	state["event_log"] = []
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
	else:
		tile.modulate = Color(0.64, 0.66, 0.58)

	return tile


func _tile_text(position: Dictionary) -> String:
	var unit := _living_unit_at(position)
	if unit.is_empty():
		return ""

	var hp: int = unit["resources"]["hp"]
	var ap: int = unit["resources"]["ap"]
	if unit["team"] == "player":
		return "P\nHP %s\nAP %s" % [hp, ap]
	return "E\nHP %s\nAP %s" % [hp, ap]


func _render_status() -> void:
	var active := _unit_by_id(state["turn_state"]["active_unit_id"])
	status_label.text = "Active: %s | Team: %s | HP: %s | AP: %s | Action: %s" % [
		active.get("id", "missing"),
		active.get("team", "missing"),
		active.get("resources", {}).get("hp", "?"),
		active.get("resources", {}).get("ap", "?"),
		selected_action,
	]


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

	for action_id in ["move", "basic_attack", "defend", "end_turn", "enemy_ai"]:
		var button := Button.new()
		button.text = action_id
		button.toggle_mode = true
		button.button_pressed = selected_action == action_id
		button.pressed.connect(func() -> void:
			selected_action = action_id
			if action_id == "enemy_ai":
				_run_command(CombatResolver.choose_enemy_command(state, "cmd_%03d" % command_index))
			elif action_id in ["defend", "end_turn"]:
				_run_command(_build_command(action_id, {}))
			else:
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
	var previous_log: Array = state["event_log"].duplicate(true)
	var result := CombatResolver.simulate(_state_without_log(), [command])
	state = result["state"]
	state["event_log"] = previous_log + _events_after_startup(result["state"]["event_log"])
	command_index += 1
	_render()


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
	if event["type"] == "unit_moved":
		return "(%s -> %s)" % [event.get("from", {}), event.get("to", {})]
	if event.has("action_id"):
		return "(%s)" % event["action_id"]
	return ""


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


func _positions_equal(first: Dictionary, second: Dictionary) -> bool:
	return int(first["x"]) == int(second["x"]) and int(first["y"]) == int(second["y"])
