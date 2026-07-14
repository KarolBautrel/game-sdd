extends Control

const CombatResolver := preload("res://scripts/domain/combat_resolver.gd")

const DEFAULT_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_03_move.json"
const LOS_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_28_ranged_attack_blocked_by_line_of_sight.json"
const COVER_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_29_cover_reduces_ranged_hit_chance.json"
const RANGED_AI_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_30_enemy_ai_ranged_attack.json"
const PATHFINDING_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_31_enemy_ai_pathfinds_around_blocked_tile.json"
const LOW_CHANCE_AI_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_34_enemy_ai_approaches_low_chance_ranged_target.json"
const MULTI_ENEMY_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_40_multi_enemy_pathing_and_targeting.json"
const BOTTLENECK_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_41_multi_enemy_bottleneck_spacing.json"
const MIXED_ROLES_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_42_mixed_melee_ranged_enemy_roles.json"
const TARGET_SELECTION_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_43_target_selection_multiple_players.json"
const INTERCEPT_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_44_ranged_intercept_by_unit.json"
const WEAPON_MELEE_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_45_weapon_profile_melee_damage.json"
const WEAPON_RANGED_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_46_weapon_profile_ranged_range_hit.json"
const WEAPON_AP_COST_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_47_weapon_profile_ap_cost.json"
const POWER_STRIKE_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_48_power_strike_skill.json"
const WEAPON_AP_COST_SUCCESS_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_49_weapon_profile_ap_cost_success.json"
const ENEMY_POWER_STRIKE_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_50_enemy_ai_power_strike.json"
const ENEMY_POWER_STRIKE_COOLDOWN_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_51_enemy_ai_power_strike_cooldown_blocks_repeat.json"
const SKILL_COOLDOWN_EXPIRES_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_52_skill_cooldown_expires_on_own_turn.json"
const WEAPON_LOADOUT_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_53_weapon_loadout_v1.json"
const BOW_REQUIRED_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_54_bow_required_for_ranged_attack.json"
const SHIELD_REQUIRED_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_55_shield_required_for_shield_wall.json"
const TWO_HANDED_BLOCKS_SHIELD_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_56_two_handed_blocks_shield.json"
const WEAPON_GRANTS_POWER_STRIKE_TEST_ENCOUNTER_PATH := "res://resources/data/combat_encounters/slice_57_weapon_grants_power_strike.json"
const PLAYER_WARRIOR_SHEET_PATH := "res://assets/combat/units/player_warrior_sheet.png"
const ENEMY_RAIDER_SHEET_PATH := "res://assets/combat/units/enemy_raider_sheet.png"
const TILE_SIZE := 64
const TILE_GAP := 4
const UNIT_FRAME_SIZE := Vector2i(32, 32)
const UNIT_POSE_FRAMES := {
	"idle": 0,
	"move": 1,
	"attack": 2,
}
const COMMAND_ACTION_IDS := ["move", "basic_attack", "ranged_attack", "aimed_shot", "power_strike", "shield_wall", "defend", "end_turn", "enemy_ai", "enemy_turn"]
const ACTION_LABELS := {
	"move": "Move",
	"basic_attack": "Melee attack",
	"ranged_attack": "Ranged attack",
	"aimed_shot": "Aimed shot",
	"power_strike": "Power strike",
	"shield_wall": "Shield wall",
	"defend": "Defend",
	"end_turn": "End turn",
	"enemy_ai": "Enemy AI once",
	"enemy_turn": "Enemy turn helper",
	"reset": "Reset encounter",
	"load_los_test": "Load LoS test",
	"load_cover_test": "Load Cover test",
	"load_ranged_ai_test": "Load Ranged AI test",
	"load_pathfinding_test": "Load Pathfinding test",
	"load_low_chance_ai_test": "Load Low Chance AI test",
	"load_multi_enemy_test": "Load Multi Enemy test",
	"load_bottleneck_test": "Load Bottleneck test",
	"load_mixed_roles_test": "Load Mixed Roles test",
	"load_target_selection_test": "Load Target Selection test",
	"load_intercept_test": "Load Intercept test",
	"load_weapon_melee_test": "Load Weapon Melee test",
	"load_weapon_ranged_test": "Load Weapon Ranged test",
	"load_weapon_ap_cost_test": "Load Weapon AP Cost blocked test",
	"load_power_strike_test": "Load Power Strike test",
	"load_weapon_ap_cost_success_test": "Load Weapon AP Cost success test",
	"load_enemy_power_strike_test": "Load Enemy Power Strike test",
	"load_enemy_power_strike_cooldown_test": "Load Enemy Power Strike cooldown test",
	"load_skill_cooldown_expires_test": "Load Skill Cooldown expires test",
}

@onready var grid_container: GridContainer = %GridContainer
@onready var status_label: Label = %StatusLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var legend_label: Label = %LegendLabel
@onready var unit_list_label: Label = %UnitListLabel
@onready var inspect_label: Label = %InspectLabel
@onready var event_log_label: Label = %EventLogLabel
@onready var command_buttons: VBoxContainer = %CommandButtons

var state: Dictionary = {}
var command_index := 1
var selected_action := "move"
var last_feedback := "Select an action."
var current_encounter_path := DEFAULT_ENCOUNTER_PATH
var selected_scenario_id := "reset"
var selected_position: Dictionary = {}
var unit_visual_pose: Dictionary = {}
var unit_texture_cache: Dictionary = {}
var unit_sheet_cache: Dictionary = {}
var visual_generation := 0


func _ready() -> void:
	_reset_debug_encounter()


func _reset_debug_encounter() -> void:
	state = _load_json(current_encounter_path)
	state["event_log"] = []
	command_index = 1
	selected_action = "move"
	unit_visual_pose.clear()
	last_feedback = "Encounter reset."
	var result := CombatResolver.simulate(state, [])
	state = result["state"]
	selected_position = _unit_by_id(state["turn_state"]["active_unit_id"]).get("position", {})
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
	_render_inspect()
	_render_event_log()
	_render_command_buttons()


func _build_tile(position: Dictionary) -> Button:
	var tile := Button.new()
	tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.text = _tile_text(position)
	tile.tooltip_text = _tile_tooltip(position)
	tile.pressed.connect(func() -> void:
		_on_tile_pressed(position)
	)

	var unit := _living_unit_at(position)
	if not unit.is_empty():
		tile.icon = _unit_icon(unit)
		tile.expand_icon = false
		tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		tile.add_theme_font_size_override("font_size", 10)
		if unit["team"] == "player":
			tile.modulate = Color(0.55, 0.8, 1.0)
		else:
			tile.modulate = Color(1.0, 0.48, 0.42)
	elif _tile_type(position) == "blocked":
		tile.modulate = Color(0.32, 0.32, 0.34)
	elif _tile_type(position) == "highground":
		tile.modulate = Color(0.84, 0.72, 0.42)
	elif _tile_type(position) == "cover_low":
		tile.modulate = Color(0.46, 0.62, 0.42)
	else:
		tile.modulate = Color(0.64, 0.66, 0.58)

	if _is_active_unit_at(position):
		tile.modulate = Color(1.0, 0.92, 0.35)
	elif _is_legal_target_for_selected_action(position):
		tile.modulate = Color(0.55, 1.0, 0.55)
	elif _positions_equal(selected_position, position):
		tile.modulate = Color(0.78, 0.78, 1.0)

	return tile


func _tile_text(position: Dictionary) -> String:
	var unit := _living_unit_at(position)
	if unit.is_empty():
		match _tile_type(position):
			"blocked":
				return "BLOCK"
			"highground":
				return "HIGH"
			"cover_low":
				return "COVER"
			_:
				return ""

	var hp: int = unit["resources"]["hp"]
	var ap: int = unit["resources"]["ap"]
	var tile_marker := _occupied_tile_marker(position)
	if unit["team"] == "player":
		return "%s\nHP %s AP %s" % [tile_marker, hp, ap]
	return "%s\nHP %s AP %s" % [tile_marker, hp, ap]


func _occupied_tile_marker(position: Dictionary) -> String:
	match _tile_type(position):
		"highground":
			return "\nHIGH"
		"cover_low":
			return "\nCOVER"
		_:
			return ""


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
	legend_label.text = "Blue player | Red enemy | Yellow active | Green legal | Lavender inspected | Gold highground | Olive cover | Dark blocked"


func _render_unit_list() -> void:
	var lines: Array[String] = []
	for unit: Dictionary in state["units"]:
		var marker := "*" if unit["id"] == state["turn_state"]["active_unit_id"] else " "
		lines.append("%s %s [%s] HP %s/%s AP %s/%s ACC %s EVA %s WPN %s pos (%s,%s)\n  Cooldowns: %s | Statuses: %s" % [
			marker,
			unit["id"],
			unit["team"],
			unit["resources"]["hp"],
			unit["stats"]["max_hp"],
			unit["resources"]["ap"],
			unit["stats"]["max_ap"],
			unit["stats"].get("accuracy", 0),
			unit["stats"].get("evasion", 0),
			unit.get("equipped_weapon_id", "none"),
			unit["position"]["x"],
			unit["position"]["y"],
			_cooldown_summary(unit),
			_status_summary(unit),
		])
	unit_list_label.text = "\n".join(lines)


func _status_summary(unit: Dictionary) -> String:
	var status_labels: Array[String] = []
	for status: Dictionary in unit["statuses"]:
		if status.get("id", "") != "skill_cooldown":
			if status.has("damage_reduction"):
				status_labels.append("%s %s DR" % [status.get("id", "unknown"), status.get("damage_reduction", "?")])
			else:
				status_labels.append(status.get("id", "unknown"))
	return ",".join(status_labels) if not status_labels.is_empty() else "none"


func _cooldown_summary(unit: Dictionary) -> String:
	var cooldown_labels: Array[String] = []
	for status: Dictionary in unit["statuses"]:
		if status.get("id", "") == "skill_cooldown":
			cooldown_labels.append("%s %s" % [ACTION_LABELS.get(status.get("action_id", "skill"), status.get("action_id", "skill")), status.get("remaining_turns", "?")])
	return ", ".join(cooldown_labels) if not cooldown_labels.is_empty() else "none"


func _render_inspect() -> void:
	if selected_position.is_empty():
		inspect_label.text = "No tile selected."
		return

	var unit := _living_unit_at(selected_position)
	var lines: Array[String] = [
		"Tile: (%s,%s)" % [selected_position["x"], selected_position["y"]],
		"Terrain: %s" % _tile_type(selected_position),
	]
	if unit.is_empty():
		lines.append("Unit: none")
	else:
		lines.append("Unit: %s [%s]" % [unit["id"], unit["team"]])
		lines.append("HP/AP: %s/%s" % [unit["resources"]["hp"], unit["resources"]["ap"]])

	var command := _preview_command_for_position(selected_position)
	if command.is_empty():
		lines.append("Selected action: %s" % ACTION_LABELS.get(selected_action, selected_action))
	else:
		var rejection := _command_rejection_reason(command)
		if rejection == "":
			lines.append("Selected action: legal")
		else:
			lines.append("Selected action: rejected")
			lines.append("Reason: %s" % rejection)

	inspect_label.text = "\n".join(lines)


func _render_event_log() -> void:
	var lines: Array[String] = []
	var events: Array = state["event_log"].duplicate(true)
	events.reverse()
	for event: Dictionary in events:
		lines.append("%s %s. %s %s" % [
			_event_marker(event),
			event["sequence"],
			event["type"],
			_event_summary(event),
		])
	event_log_label.text = "\n".join(lines)


func _render_command_buttons() -> void:
	for child in command_buttons.get_children():
		child.queue_free()

	_add_button_section("Commands")
	for action_id in COMMAND_ACTION_IDS:
		_add_action_button(action_id)

	_add_button_section("Load Test")
	_add_scenario_picker()


func _add_button_section(title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 14)
	command_buttons.add_child(label)


func _add_action_button(action_id: String) -> void:
	var button := Button.new()
	button.text = ACTION_LABELS.get(action_id, action_id)
	button.toggle_mode = true
	button.button_pressed = selected_action == action_id
	button.disabled = _combat_result() != "in_progress"
	button.pressed.connect(func() -> void:
		selected_action = action_id
		if action_id == "enemy_turn":
			_run_enemy_turn_helper()
		elif action_id == "enemy_ai":
			_run_command(CombatResolver.choose_enemy_command(state, "cmd_%03d" % command_index))
		elif action_id in ["shield_wall", "defend", "end_turn"]:
			_run_command(_build_command(action_id, {}))
		else:
			last_feedback = "Select a highlighted target for %s." % ACTION_LABELS.get(action_id, action_id)
			_render()
	)
	command_buttons.add_child(button)


func _add_scenario_picker() -> void:
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var selected_index := 0
	var options := _scenario_options()
	for index in range(options.size()):
		var option: Dictionary = options[index]
		picker.add_item(option["label"])
		picker.set_item_metadata(index, option["id"])
		if option["id"] == selected_scenario_id:
			selected_index = index

	picker.select(selected_index)
	picker.item_selected.connect(func(index: int) -> void:
		selected_scenario_id = str(picker.get_item_metadata(index))
	)
	command_buttons.add_child(picker)

	var load_button := Button.new()
	load_button.text = "Load selected test"
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.pressed.connect(func() -> void:
		_load_selected_scenario()
	)
	command_buttons.add_child(load_button)


func _load_selected_scenario() -> void:
	for option: Dictionary in _scenario_options():
		if option["id"] == selected_scenario_id:
			current_encounter_path = option["path"]
			_reset_debug_encounter()
			return

	last_feedback = "Unknown test selection: %s" % selected_scenario_id
	_render()


func _scenario_options() -> Array[Dictionary]:
	return [
		{"id": "reset", "label": "Default move", "path": DEFAULT_ENCOUNTER_PATH},
		{"id": "load_los_test", "label": "LoS blocked shot", "path": LOS_TEST_ENCOUNTER_PATH},
		{"id": "load_cover_test", "label": "Cover", "path": COVER_TEST_ENCOUNTER_PATH},
		{"id": "load_ranged_ai_test", "label": "Ranged enemy AI", "path": RANGED_AI_TEST_ENCOUNTER_PATH},
		{"id": "load_pathfinding_test", "label": "Pathfinding obstacle", "path": PATHFINDING_TEST_ENCOUNTER_PATH},
		{"id": "load_low_chance_ai_test", "label": "Low chance AI approach", "path": LOW_CHANCE_AI_TEST_ENCOUNTER_PATH},
		{"id": "load_multi_enemy_test", "label": "Multi enemy", "path": MULTI_ENEMY_TEST_ENCOUNTER_PATH},
		{"id": "load_bottleneck_test", "label": "Bottleneck spacing", "path": BOTTLENECK_TEST_ENCOUNTER_PATH},
		{"id": "load_mixed_roles_test", "label": "Mixed melee/ranged roles", "path": MIXED_ROLES_TEST_ENCOUNTER_PATH},
		{"id": "load_target_selection_test", "label": "Target selection", "path": TARGET_SELECTION_TEST_ENCOUNTER_PATH},
		{"id": "load_intercept_test", "label": "Ranged intercept", "path": INTERCEPT_TEST_ENCOUNTER_PATH},
		{"id": "load_weapon_melee_test", "label": "Weapon melee damage", "path": WEAPON_MELEE_TEST_ENCOUNTER_PATH},
		{"id": "load_weapon_ranged_test", "label": "Weapon ranged range/hit", "path": WEAPON_RANGED_TEST_ENCOUNTER_PATH},
		{"id": "load_weapon_ap_cost_test", "label": "Weapon AP cost blocked", "path": WEAPON_AP_COST_TEST_ENCOUNTER_PATH},
		{"id": "load_power_strike_test", "label": "Power strike", "path": POWER_STRIKE_TEST_ENCOUNTER_PATH},
		{"id": "load_weapon_ap_cost_success_test", "label": "Weapon AP cost success", "path": WEAPON_AP_COST_SUCCESS_TEST_ENCOUNTER_PATH},
		{"id": "load_enemy_power_strike_test", "label": "Enemy power strike", "path": ENEMY_POWER_STRIKE_TEST_ENCOUNTER_PATH},
		{"id": "load_enemy_power_strike_cooldown_test", "label": "Enemy power strike cooldown", "path": ENEMY_POWER_STRIKE_COOLDOWN_TEST_ENCOUNTER_PATH},
		{"id": "load_skill_cooldown_expires_test", "label": "Skill cooldown expires", "path": SKILL_COOLDOWN_EXPIRES_TEST_ENCOUNTER_PATH},
		{"id": "load_weapon_loadout_test", "label": "Loadout weapon grants melee", "path": WEAPON_LOADOUT_TEST_ENCOUNTER_PATH},
		{"id": "load_bow_required_test", "label": "Bow required for ranged", "path": BOW_REQUIRED_TEST_ENCOUNTER_PATH},
		{"id": "load_shield_required_test", "label": "Shield required for shield wall", "path": SHIELD_REQUIRED_TEST_ENCOUNTER_PATH},
		{"id": "load_two_handed_blocks_shield_test", "label": "Two-handed blocks shield", "path": TWO_HANDED_BLOCKS_SHIELD_TEST_ENCOUNTER_PATH},
		{"id": "load_weapon_grants_power_strike_test", "label": "Weapon grants power strike", "path": WEAPON_GRANTS_POWER_STRIKE_TEST_ENCOUNTER_PATH},
	]


func _on_tile_pressed(position: Dictionary) -> void:
	selected_position = position.duplicate(true)
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
	elif selected_action == "aimed_shot":
		var unit := _living_unit_at(position)
		_run_command(_build_command("aimed_shot", {
			"type": "unit",
			"unit_id": unit.get("id", ""),
		}))
	elif selected_action == "power_strike":
		var unit := _living_unit_at(position)
		_run_command(_build_command("power_strike", {
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
	_capture_unit_visuals(new_events)
	_render()
	_schedule_visual_reset()


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
	_capture_unit_visuals(new_events)


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
		return "(%s damage to %s, reduction %s)" % [event.get("damage", "?"), event.get("target_unit_id", "?"), event.get("damage_reduction", 0)]
	if event["type"] == "status_applied":
		var status: Dictionary = event.get("status", {})
		return "(%s on %s, turns %s)" % [status.get("id", "?"), event.get("target_unit_id", "?"), status.get("remaining_turns", "?")]
	if event["type"] == "status_expired":
		var expired_status: Dictionary = event.get("status", {})
		return "(%s on %s)" % [expired_status.get("id", "?"), event.get("target_unit_id", "?")]
	if event["type"] == "hit_roll_resolved":
		return "(%s: roll %s vs %s%%, base %s + acc %s - eva %s + terrain %s + cover %s)" % [
			event.get("outcome", "?"),
			event.get("roll", "?"),
			event.get("hit_chance", "?"),
			event.get("base_hit_chance", "?"),
			event.get("accuracy_modifier", "?"),
			event.get("evasion_modifier", "?"),
			event.get("terrain_modifier", "?"),
			event.get("cover_modifier", "?"),
		]
	if event["type"] == "shot_intercept_resolved":
		return "(%s: %s -> %s via %s, roll %s vs %s%%)" % [
			event.get("outcome", "?"),
			event.get("original_target_unit_id", "?"),
			event.get("final_target_unit_id", "?"),
			event.get("blocker_unit_id", "?"),
			event.get("roll", "?"),
			event.get("intercept_chance", "?"),
		]
	if event["type"] == "unit_moved":
		return "(%s -> %s)" % [event.get("from", {}), event.get("to", {})]
	if event.has("action_id"):
		return "(%s)" % event["action_id"]
	return ""


func _event_marker(event: Dictionary) -> String:
	match event["type"]:
		"command_rejected":
			return "!"
		"damage_applied", "unit_defeated", "combat_ended":
			return "*"
		"status_applied", "status_expired":
			return "#"
		"hit_roll_resolved":
			return "%"
		"shot_intercept_resolved":
			return "~"
		"unit_moved":
			return ">"
		"turn_started", "turn_ended":
			return "-"
		_:
			return "."


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


func _capture_unit_visuals(events: Array) -> void:
	for event: Dictionary in events:
		if event["type"] == "unit_moved":
			unit_visual_pose[event.get("actor_id", "")] = "move"
		elif event["type"] == "damage_applied":
			unit_visual_pose[event.get("actor_id", "")] = "attack"


func _schedule_visual_reset() -> void:
	if unit_visual_pose.is_empty():
		return
	visual_generation += 1
	var current_generation := visual_generation
	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		if current_generation != visual_generation:
			return
		unit_visual_pose.clear()
		_render()
	)


func _clear_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()


func _unit_icon(unit: Dictionary) -> Texture2D:
	var pose := str(unit_visual_pose.get(unit["id"], "idle"))
	var team := str(unit.get("team", "enemy"))
	var cache_key := "%s:%s" % [team, pose]
	if unit_texture_cache.has(cache_key):
		return unit_texture_cache[cache_key]

	var sheet_path := PLAYER_WARRIOR_SHEET_PATH if team == "player" else ENEMY_RAIDER_SHEET_PATH
	var sheet := _unit_sheet(sheet_path)
	if sheet == null:
		return null

	var frame: int = UNIT_POSE_FRAMES.get(pose, 0)
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = Rect2(frame * UNIT_FRAME_SIZE.x, 0, UNIT_FRAME_SIZE.x, UNIT_FRAME_SIZE.y)
	unit_texture_cache[cache_key] = texture
	return texture


func _unit_sheet(sheet_path: String) -> Texture2D:
	if unit_sheet_cache.has(sheet_path):
		return unit_sheet_cache[sheet_path]

	var image := Image.new()
	var error := image.load(sheet_path)
	if error != OK:
		push_error("Cannot load unit sprite sheet: %s" % sheet_path)
		return null

	var texture := ImageTexture.create_from_image(image)
	unit_sheet_cache[sheet_path] = texture
	return texture


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


func _tile_tooltip(position: Dictionary) -> String:
	var lines: Array[String] = [
		"x:%s y:%s" % [position["x"], position["y"]],
		"terrain: %s" % _tile_type(position),
	]
	var command := _preview_command_for_position(position)
	if not command.is_empty():
		var rejection := _command_rejection_reason(command)
		lines.append("selected action: legal" if rejection == "" else "rejected: %s" % rejection)
	return "\n".join(lines)


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
	if selected_action == "aimed_shot":
		var unit := _living_unit_at(position)
		if unit.is_empty():
			return false
		return _command_would_be_accepted(_build_command("aimed_shot", {
			"type": "unit",
			"unit_id": unit["id"],
		}))
	if selected_action == "power_strike":
		var unit := _living_unit_at(position)
		if unit.is_empty():
			return false
		return _command_would_be_accepted(_build_command("power_strike", {
			"type": "unit",
			"unit_id": unit["id"],
		}))
	return false


func _command_would_be_accepted(command: Dictionary) -> bool:
	return _command_rejection_reason(command) == ""


func _command_rejection_reason(command: Dictionary) -> String:
	var result: Dictionary = CombatResolver.simulate(_state_without_log(), [command])
	for event: Dictionary in _events_after_startup(result["state"]["event_log"]):
		if event["type"] == "command_rejected":
			return event.get("reason", "unknown")
	return ""


func _preview_command_for_position(position: Dictionary) -> Dictionary:
	if selected_action == "move":
		return _build_command("move", {
			"type": "tile",
			"position": position,
		})
	if selected_action == "basic_attack":
		var melee_unit := _living_unit_at(position)
		if melee_unit.is_empty():
			return {}
		return _build_command("basic_attack", {
			"type": "unit",
			"unit_id": melee_unit["id"],
		})
	if selected_action == "ranged_attack":
		var ranged_unit := _living_unit_at(position)
		if ranged_unit.is_empty():
			return {}
		return _build_command("ranged_attack", {
			"type": "unit",
			"unit_id": ranged_unit["id"],
		})
	if selected_action == "aimed_shot":
		var aimed_unit := _living_unit_at(position)
		if aimed_unit.is_empty():
			return {}
		return _build_command("aimed_shot", {
			"type": "unit",
			"unit_id": aimed_unit["id"],
		})
	if selected_action == "power_strike":
		var power_unit := _living_unit_at(position)
		if power_unit.is_empty():
			return {}
		return _build_command("power_strike", {
			"type": "unit",
			"unit_id": power_unit["id"],
		})
	return {}


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
