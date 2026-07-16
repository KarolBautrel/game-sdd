extends Control

const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")

const DUNGEON_PATH := "res://resources/data/dungeons/dungeon_old_mine.json"
const ROOM_SIZE := Vector2(220, 104)
const GRAPH_ORIGIN := Vector2(210, 250)
const GRAPH_STEP := Vector2(300, 190)
const ENTER_COMBAT_LABEL := "Enter Combat"
const FINISH_EXPEDITION_LABEL := "Finish Expedition"

var dungeon: Dictionary = {}
var run_state: Dictionary = {}
var room_nodes: Dictionary = {}
var selected_room_id := ""
var last_feedback := ""

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var progress_label: Label = %ProgressLabel
@onready var panel_title: Label = %PanelTitle
@onready var detail_label: Label = %DetailLabel
@onready var graph_layer: Control = %GraphLayer
@onready var detail_panel: PanelContainer = $DetailPanel
@onready var detail_box: VBoxContainer = $DetailPanel/MarginContainer/VBoxContainer

var action_row: HBoxContainer
var start_combat_button: Button
var exit_row: VBoxContainer
var reward_button: Button
var finish_button: Button
var oil_button: Button
var reset_button: Button
var corridor_event_panel: PanelContainer
var corridor_event_title_label: Label
var corridor_event_type_label: Label
var corridor_event_message_label: Label
var corridor_event_supply_label: Label
var corridor_event_result_label: Label
var corridor_event_choice_row: HBoxContainer
var corridor_hazard_choice_buttons: Array[Button] = []


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not run_state.get("pending_corridor_hazard", {}).is_empty():
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var slot := _number_key_slot(key_event)
	if slot <= 0:
		return
	var exits := _connected_room_options(selected_room_id)
	if slot > exits.size():
		return
	get_viewport().set_input_as_handled()
	_try_enter_room(str(exits[slot - 1].get("id", "")))


func _ready() -> void:
	dungeon = _load_json(DUNGEON_PATH)
	if dungeon.is_empty():
		title_label.text = "Dungeon data missing"
		status_label.text = "Could not load %s" % DUNGEON_PATH
		return
	if _run_session().has_dungeon_run():
		run_state = _run_session().dungeon_state.duplicate(true)
		if _run_session().last_feedback != "":
			last_feedback = _run_session().last_feedback
	else:
		run_state = DungeonStateModel.initial_state(dungeon)
		_run_session().set_dungeon_run(dungeon, run_state)
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	title_label.text = dungeon.get("display_name", "Dungeon")
	_apply_hud_visual_style()
	_create_action_buttons()
	_create_corridor_event_panel()
	_build_graph()
	_update_detail()


func _draw() -> void:
	pass


func _build_graph() -> void:
	for child in graph_layer.get_children():
		child.queue_free()
	room_nodes.clear()
	_build_corridors()
	for room: Dictionary in dungeon.get("rooms", []):
		var room_panel: PanelContainer = _create_room_panel(room)
		graph_layer.add_child(room_panel)
		room_nodes[room["id"]] = room_panel


func _build_corridors() -> void:
	var rooms_by_id: Dictionary = _rooms_by_id()
	for corridor: Dictionary in dungeon.get("corridors", []):
		var from_room: Dictionary = rooms_by_id.get(corridor.get("from", ""), {})
		var to_room: Dictionary = rooms_by_id.get(corridor.get("to", ""), {})
		if from_room.is_empty() or to_room.is_empty():
			continue
		var from_pos: Vector2 = _room_screen_position(from_room) + ROOM_SIZE * 0.5
		var to_pos: Vector2 = _room_screen_position(to_room) + ROOM_SIZE * 0.5
		graph_layer.add_child(_create_corridor_line(from_pos, to_pos, Color(0.12, 0.11, 0.1), 14.0))
		graph_layer.add_child(_create_corridor_line(from_pos, to_pos, Color(0.45, 0.42, 0.34), 8.0))


func _create_corridor_line(from_pos: Vector2, to_pos: Vector2, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	return line


func _create_room_panel(room: Dictionary) -> PanelContainer:
	var room_id: String = str(room["id"])
	var panel := PanelContainer.new()
	panel.position = _room_screen_position(room)
	panel.custom_minimum_size = ROOM_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", _room_style(room_id, str(room.get("kind", ""))))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	var name_label := Label.new()
	name_label.text = _room_map_label(room)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	box.add_child(name_label)

	var content_label := Label.new()
	content_label.text = _content_summary(room)
	content_label.add_theme_font_size_override("font_size", 15)
	content_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.76))
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(content_label)

	var button := Button.new()
	button.text = ""
	button.flat = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void:
		_try_enter_room(room_id)
	)
	panel.add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel


func _create_action_buttons() -> void:
	action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.add_child(action_row)

	start_combat_button = Button.new()
	start_combat_button.text = ENTER_COMBAT_LABEL
	start_combat_button.custom_minimum_size = Vector2(0, 58)
	start_combat_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_combat_button.add_theme_font_size_override("font_size", 22)
	start_combat_button.add_theme_stylebox_override("normal", _button_style(Color(0.58, 0.18, 0.12), Color(0.95, 0.62, 0.36)))
	start_combat_button.add_theme_stylebox_override("hover", _button_style(Color(0.7, 0.22, 0.14), Color(1.0, 0.76, 0.44)))
	start_combat_button.add_theme_stylebox_override("pressed", _button_style(Color(0.42, 0.12, 0.1), Color(0.86, 0.44, 0.28)))
	start_combat_button.pressed.connect(func() -> void:
		_start_pending_combat()
	)
	action_row.add_child(start_combat_button)

	reward_button = Button.new()
	reward_button.text = "Claim Reward"
	reward_button.custom_minimum_size = Vector2(0, 48)
	reward_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_button.add_theme_font_size_override("font_size", 18)
	reward_button.add_theme_stylebox_override("normal", _button_style(Color(0.22, 0.25, 0.10), Color(0.88, 0.72, 0.30)))
	reward_button.add_theme_stylebox_override("hover", _button_style(Color(0.30, 0.32, 0.12), Color(1.0, 0.84, 0.38)))
	reward_button.add_theme_stylebox_override("pressed", _button_style(Color(0.16, 0.18, 0.08), Color(0.74, 0.54, 0.20)))
	reward_button.pressed.connect(func() -> void:
		_claim_current_reward()
	)
	action_row.add_child(reward_button)

	finish_button = Button.new()
	finish_button.text = FINISH_EXPEDITION_LABEL
	finish_button.custom_minimum_size = Vector2(0, 48)
	finish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_button.add_theme_font_size_override("font_size", 18)
	finish_button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.25, 0.20), Color(0.54, 0.86, 0.62)))
	finish_button.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.34, 0.26), Color(0.68, 1.0, 0.78)))
	finish_button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.18, 0.15), Color(0.42, 0.70, 0.52)))
	finish_button.pressed.connect(func() -> void:
		_finish_expedition()
	)
	action_row.add_child(finish_button)

	oil_button = Button.new()
	oil_button.text = "Use Oil"
	oil_button.custom_minimum_size = Vector2(0, 48)
	oil_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	oil_button.add_theme_font_size_override("font_size", 18)
	oil_button.add_theme_stylebox_override("normal", _button_style(Color(0.18, 0.18, 0.08), Color(0.86, 0.68, 0.24)))
	oil_button.add_theme_stylebox_override("hover", _button_style(Color(0.26, 0.24, 0.10), Color(1.0, 0.82, 0.34)))
	oil_button.add_theme_stylebox_override("pressed", _button_style(Color(0.12, 0.12, 0.06), Color(0.70, 0.52, 0.18)))
	oil_button.pressed.connect(func() -> void:
		_use_lamp_oil()
	)
	action_row.add_child(oil_button)

	reset_button = Button.new()
	reset_button.text = "Reset Run"
	reset_button.custom_minimum_size = Vector2(0, 48)
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.add_theme_font_size_override("font_size", 18)
	reset_button.add_theme_stylebox_override("normal", _button_style(Color(0.16, 0.12, 0.12), Color(0.62, 0.34, 0.28)))
	reset_button.add_theme_stylebox_override("hover", _button_style(Color(0.24, 0.16, 0.14), Color(0.82, 0.46, 0.34)))
	reset_button.add_theme_stylebox_override("pressed", _button_style(Color(0.10, 0.08, 0.08), Color(0.48, 0.26, 0.22)))
	reset_button.pressed.connect(func() -> void:
		_reset_expedition()
	)
	action_row.add_child(reset_button)

	exit_row = VBoxContainer.new()
	exit_row.add_theme_constant_override("separation", 8)
	exit_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.add_child(exit_row)


func _create_corridor_event_panel() -> void:
	corridor_event_panel = PanelContainer.new()
	corridor_event_panel.visible = false
	corridor_event_panel.custom_minimum_size = Vector2(620, 260)
	corridor_event_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	corridor_event_panel.set_anchors_preset(Control.PRESET_CENTER)
	corridor_event_panel.position = Vector2(650, 320)
	corridor_event_panel.add_theme_stylebox_override("panel", _button_style(Color(0.055, 0.06, 0.055), Color(0.82, 0.62, 0.28)))
	add_child(corridor_event_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	corridor_event_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	corridor_event_title_label = Label.new()
	corridor_event_title_label.text = "Corridor Event"
	corridor_event_title_label.add_theme_font_size_override("font_size", 26)
	corridor_event_title_label.add_theme_color_override("font_color", Color(0.96, 0.80, 0.42))
	box.add_child(corridor_event_title_label)

	corridor_event_type_label = Label.new()
	corridor_event_type_label.add_theme_font_size_override("font_size", 17)
	corridor_event_type_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.74))
	box.add_child(corridor_event_type_label)

	corridor_event_message_label = Label.new()
	corridor_event_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corridor_event_message_label.add_theme_font_size_override("font_size", 18)
	box.add_child(corridor_event_message_label)

	corridor_event_supply_label = Label.new()
	corridor_event_supply_label.add_theme_font_size_override("font_size", 16)
	corridor_event_supply_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.68))
	box.add_child(corridor_event_supply_label)

	corridor_event_result_label = Label.new()
	corridor_event_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corridor_event_result_label.add_theme_font_size_override("font_size", 16)
	corridor_event_result_label.add_theme_color_override("font_color", Color(0.94, 0.66, 0.48))
	box.add_child(corridor_event_result_label)

	corridor_event_choice_row = HBoxContainer.new()
	corridor_event_choice_row.add_theme_constant_override("separation", 10)
	box.add_child(corridor_event_choice_row)


func _try_enter_room(room_id: String) -> void:
	var result: Dictionary = DungeonStateModel.enter_room(dungeon, run_state, room_id)
	if result["status"] == "accepted":
		run_state = result["state"]
		_run_session().set_dungeon_run(dungeon, run_state)
		selected_room_id = str(run_state["current_room_id"])
		last_feedback = _movement_feedback(result, selected_room_id)
	elif result["status"] == "choice_required":
		run_state = result["state"]
		_run_session().set_dungeon_run(dungeon, run_state)
		last_feedback = "Corridor event between %s and %s." % [
			_room_display_name(str(result["event"].get("from_room_id", ""))),
			_room_display_name(str(result["event"].get("to_room_id", ""))),
		]
		_show_corridor_hazard_popup(result["event"])
	else:
		last_feedback = "Cannot enter %s: %s." % [_room_display_name(room_id), result["rejection"]]
	_refresh_room_styles()
	_update_detail()


func _start_pending_combat() -> void:
	if _run_session().start_combat(dungeon, run_state):
		get_tree().change_scene_to_file(_run_session().COMBAT_SCENE_PATH)
	else:
		last_feedback = _run_session().last_feedback
		_update_detail()


func _claim_current_reward() -> void:
	var result: Dictionary = DungeonStateModel.claim_current_reward(dungeon, run_state)
	if result["status"] == "accepted":
		run_state = result["state"]
		_run_session().set_dungeon_run(dungeon, run_state)
		last_feedback = "Claimed reward from %s." % _room_display_name(selected_room_id)
	else:
		last_feedback = "Cannot claim reward: %s." % result["rejection"]
	_refresh_room_styles()
	_update_detail()


func _use_lamp_oil() -> void:
	var result: Dictionary = DungeonStateModel.use_lamp_oil(run_state)
	if result["status"] == "accepted":
		run_state = result["state"]
		_run_session().set_dungeon_run(dungeon, run_state)
		last_feedback = str(result["event"].get("message", "Lamp oil used."))
	else:
		last_feedback = "Cannot use oil: %s." % result["rejection"]
	_refresh_room_styles()
	_update_detail()


func _reset_expedition() -> void:
	_run_session().clear()
	run_state = DungeonStateModel.initial_state(dungeon)
	_run_session().set_dungeon_run(dungeon, run_state)
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	last_feedback = "Expedition reset."
	if corridor_event_panel != null:
		corridor_event_panel.hide()
	_refresh_room_styles()
	_update_detail()


func _resolve_pending_corridor_hazard(choice_id: String) -> void:
	var result: Dictionary = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, run_state, choice_id)
	if result["status"] == "accepted":
		run_state = result["state"]
		_run_session().set_dungeon_run(dungeon, run_state)
		selected_room_id = str(run_state["current_room_id"])
		last_feedback = _movement_feedback(result, selected_room_id)
	else:
		last_feedback = "Cannot resolve corridor event: %s." % result["rejection"]
	if corridor_event_panel != null:
		corridor_event_panel.hide()
	_refresh_room_styles()
	_update_detail()


func _finish_expedition() -> void:
	var result: Dictionary = DungeonStateModel.complete_current_room(dungeon, run_state)
	if result["status"] == "accepted":
		run_state = result["state"]
		_run_session().set_dungeon_run(dungeon, run_state)
		last_feedback = "Expedition completed at %s." % _room_display_name(selected_room_id)
	else:
		last_feedback = "Cannot finish expedition: %s." % result["rejection"]
	_refresh_room_styles()
	_update_detail()


func _apply_debug_combat_result(result: String) -> void:
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	if pending.is_empty():
		last_feedback = "No pending combat."
		_update_detail()
		return
	var apply_result: Dictionary = DungeonStateModel.apply_combat_result(dungeon, run_state, _debug_combat_payload(result, pending))
	if apply_result["status"] == "accepted":
		run_state = apply_result["state"]
		_run_session().set_dungeon_run(dungeon, run_state)
		last_feedback = "Combat %s applied for %s." % [result, _room_display_name(str(pending.get("room_id", "")))]
	else:
		last_feedback = "Combat result rejected: %s." % apply_result["rejection"]
	_refresh_room_styles()
	_update_detail()


func _refresh_room_styles() -> void:
	for room: Dictionary in dungeon.get("rooms", []):
		var panel: PanelContainer = room_nodes.get(room["id"])
		if panel != null:
			panel.add_theme_stylebox_override("panel", _room_style(str(room["id"]), str(room.get("kind", ""))))


func _update_detail() -> void:
	var room: Dictionary = _rooms_by_id().get(selected_room_id, {})
	if room.is_empty():
		detail_label.text = "No room selected."
		return
	panel_title.text = _room_display_name(selected_room_id)
	detail_label.text = "\n".join(_detail_lines_for_room(room))
	status_label.text = _status_summary()
	progress_label.text = _progress_summary()
	_refresh_action_buttons()
	_refresh_exit_buttons()


func _detail_lines_for_room(room: Dictionary) -> PackedStringArray:
	if bool(run_state.get("completed", false)):
		return _post_run_summary_lines()
	var room_id := str(room.get("id", selected_room_id))
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var pending_hazard: Dictionary = run_state.get("pending_corridor_hazard", {})
	var lines: PackedStringArray = [
		"State: %s" % _room_state_summary(room_id),
		"Position: %s" % _room_position_summary(room),
		"Content: %s" % _content_summary(room),
		"Light: %s %s/%s | Oil: %s | Pickaxe: %s | Trap Tools: %s" % [
			str(run_state.get("light_state", "bright")),
			int(run_state.get("light_level", 0)),
			int(run_state.get("max_light_level", 0)),
			DungeonStateModel.supply_count(run_state, "lamp_oil"),
			DungeonStateModel.supply_count(run_state, "pickaxe"),
			DungeonStateModel.supply_count(run_state, "trap_tools"),
		],
		"Exits: %s" % _state_list_or_none(_connected_room_labels(room_id)),
	]
	var reward_line := _reward_summary(room)
	if reward_line != "":
		lines.append(reward_line)
	var debuff_line := _active_debuff_line()
	if debuff_line != "":
		lines.append(debuff_line)
	if not pending_hazard.is_empty():
		lines.append("Corridor event: %s" % str(pending_hazard.get("message", "")))
	if not pending.is_empty():
		lines.append("Threat: enemies are waiting here.")
	if last_feedback != "":
		lines.append(last_feedback)
	var hazard_line := _last_hazard_summary()
	if hazard_line != "":
		lines.append(hazard_line)
	if bool(run_state.get("completed", false)):
		lines.append("Expedition complete.")
	return lines


func _post_run_summary_lines() -> PackedStringArray:
	var totals := DungeonStateModel.reward_totals(run_state)
	var items: Array = totals.get("items", [])
	var item_text := "none" if items.is_empty() else ", ".join(items)
	return PackedStringArray([
		"Expedition complete.",
		"Completed at: %s" % _room_display_name(str(run_state.get("completed_at_room_id", ""))),
		"Rooms visited: %s/%s" % [run_state.get("visited_room_ids", []).size(), dungeon.get("rooms", []).size()],
		"Rooms secured: %s/%s" % [run_state.get("cleared_room_ids", []).size(), dungeon.get("rooms", []).size()],
		"Gold claimed: %s" % int(totals.get("gold", 0)),
		"XP claimed: %s" % int(totals.get("xp", 0)),
		"Items claimed: %s" % item_text,
	])


func _refresh_action_buttons() -> void:
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var pending_hazard: Dictionary = run_state.get("pending_corridor_hazard", {})
	var has_pending := not pending.is_empty()
	var has_reward := pending_hazard.is_empty() and _current_room_has_claimable_reward()
	var has_finish := pending_hazard.is_empty() and _current_room_can_finish_expedition()
	var has_oil := pending_hazard.is_empty() and _can_use_lamp_oil()
	action_row.visible = true
	start_combat_button.disabled = not has_pending
	start_combat_button.visible = has_pending
	reward_button.disabled = not has_reward
	reward_button.visible = has_reward
	finish_button.disabled = not has_finish
	finish_button.visible = has_finish
	oil_button.disabled = not has_oil
	oil_button.visible = has_oil
	reset_button.disabled = false
	reset_button.visible = true


func _refresh_exit_buttons() -> void:
	for child in exit_row.get_children():
		child.queue_free()
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var pending_hazard: Dictionary = run_state.get("pending_corridor_hazard", {})
	exit_row.visible = pending.is_empty() and pending_hazard.is_empty()
	if not pending.is_empty() or not pending_hazard.is_empty():
		return
	for option: Dictionary in _connected_room_options(selected_room_id):
		var button := Button.new()
		button.text = "%s. %s" % [option.get("slot", 0), option.get("label", "")]
		button.custom_minimum_size = Vector2(0, 42)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_stylebox_override("normal", _button_style(Color(0.095, 0.105, 0.09), Color(0.40, 0.36, 0.22)))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.13, 0.15, 0.11), Color(0.78, 0.62, 0.30)))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.07, 0.08, 0.06), Color(0.64, 0.48, 0.24)))
		var target_room_id := str(option.get("id", ""))
		button.pressed.connect(func() -> void:
			_try_enter_room(target_room_id)
		)
		exit_row.add_child(button)


func _connected_room_labels(room_id: String) -> Array[String]:
	var labels: Array[String] = []
	for option: Dictionary in _connected_room_options(room_id):
		labels.append(str(option.get("label", "")))
	return labels


func _connected_room_options(room_id: String) -> Array[Dictionary]:
	var rooms_by_id: Dictionary = _rooms_by_id()
	var options: Array[Dictionary] = []
	var slot := 1
	for corridor: Dictionary in dungeon.get("corridors", []):
		var other_id: String = ""
		if corridor.get("from", "") == room_id:
			other_id = str(corridor.get("to", ""))
		elif corridor.get("to", "") == room_id:
			other_id = str(corridor.get("from", ""))
		if other_id != "":
			var other_room: Dictionary = rooms_by_id.get(other_id, {})
			options.append({
				"slot": slot,
				"id": other_id,
				"label": _exit_label_for_room(other_room),
			})
			slot += 1
	return options


func _room_map_label(room: Dictionary) -> String:
	return "%s %s" % [_room_kind_marker(str(room.get("kind", ""))), str(room.get("display_name", room.get("id", "")))]


func _exit_label_for_room(room: Dictionary) -> String:
	if room.is_empty():
		return "missing"
	var label := str(room.get("display_name", room.get("id", "")))
	var hints: Array[String] = []
	if str(room.get("locked_by_item_id", "")) != "" and not _room_is_unlocked_or_keyed(room):
		hints.append("locked")
	var kind := str(room.get("kind", ""))
	if kind == "exit":
		hints.append("exit")
	elif kind == "treasure" and not DungeonStateModel.room_reward_is_claimed(run_state, str(room.get("id", ""))):
		hints.append("reward")
	elif kind == "guarded_treasure":
		hints.append("guarded")
	elif kind == "combat" and not DungeonStateModel.room_is_cleared(run_state, str(room.get("id", ""))):
		hints.append("danger")
	if hints.is_empty():
		return label
	return "%s (%s)" % [label, ", ".join(hints)]


func _movement_feedback(result: Dictionary, room_id: String) -> String:
	var messages: Array[String] = ["Entered %s." % _room_display_name(room_id)]
	for event: Dictionary in result.get("event", {}).get("traversal_events", []):
		var message := str(event.get("message", ""))
		if message != "":
			messages.append(message)
	return " ".join(messages)


func _show_corridor_hazard_popup(prompt: Dictionary) -> void:
	if corridor_event_panel == null:
		return
	for old_button: Button in corridor_hazard_choice_buttons:
		if is_instance_valid(old_button):
			old_button.queue_free()
	corridor_hazard_choice_buttons.clear()
	corridor_event_title_label.text = "Corridor Event"
	corridor_event_type_label.text = "%s between %s and %s" % [
		str(prompt.get("hazard_type", "hazard")).capitalize(),
		_room_display_name(str(prompt.get("from_room_id", ""))),
		_room_display_name(str(prompt.get("to_room_id", ""))),
	]
	corridor_event_message_label.text = str(prompt.get("message", ""))
	corridor_event_supply_label.text = "Required supply: %s (%s)" % [
		str(prompt.get("required_supply_id", "none")),
		"available" if bool(prompt.get("supply_available", false)) else "missing",
	]
	corridor_event_result_label.text = "Choose how the party handles this corridor hazard."
	for choice: Dictionary in prompt.get("choices", []):
		var action := str(choice.get("id", ""))
		var button := Button.new()
		button.text = str(choice.get("label", action))
		button.disabled = not bool(choice.get("available", false))
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.13, 0.10), Color(0.62, 0.48, 0.24)))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.18, 0.18, 0.12), Color(0.90, 0.68, 0.30)))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.09, 0.07), Color(0.72, 0.50, 0.20)))
		button.pressed.connect(func() -> void:
			_resolve_pending_corridor_hazard(action)
		)
		corridor_event_choice_row.add_child(button)
		corridor_hazard_choice_buttons.append(button)
	corridor_event_panel.show()


func _corridor_hazard_popup_text(prompt: Dictionary) -> String:
	var supply_line := "Required: %s (%s)" % [
		str(prompt.get("required_supply_id", "none")),
		"available" if bool(prompt.get("supply_available", false)) else "missing",
	]
	return "%s\n\n%s\n\nThis happens in the corridor before the party reaches %s." % [
		str(prompt.get("message", "")),
		supply_line,
		_room_display_name(str(prompt.get("to_room_id", ""))),
	]


func _last_hazard_summary() -> String:
	var log: Array = run_state.get("hazard_log", [])
	if log.is_empty():
		return ""
	var event: Dictionary = log[log.size() - 1]
	if str(event.get("type", "")) == "light_changed":
		return "Last corridor: light is now %s." % str(event.get("light_state", ""))
	if str(event.get("type", "")) == "corridor_hazard_resolved":
		var outcome := str(event.get("outcome_id", ""))
		var consequence_text := _consequence_summary(event.get("consequences", []))
		if consequence_text == "":
			return "Last hazard: %s." % outcome
		return "Last hazard: %s (%s)." % [outcome, consequence_text]
	return ""


func _consequence_summary(consequences: Array) -> String:
	var labels: Array[String] = []
	for consequence: Dictionary in consequences:
		match str(consequence.get("type", "")):
			"consume_supply":
				labels.append("used %s" % str(consequence.get("supply_id", "supply")))
			"hp_loss":
				labels.append("HP -%s" % int(consequence.get("amount", 0)))
			"apply_debuff":
				labels.append(str(consequence.get("debuff_id", "debuff")))
			"reduce_light":
				labels.append("light -%s" % int(consequence.get("amount", 0)))
	return ", ".join(labels)


func _active_debuff_line() -> String:
	var summary := DungeonStateModel.active_debuff_summary(run_state)
	if summary.is_empty():
		return ""
	return "Debuffs: %s" % ", ".join(summary)


func _room_is_unlocked_or_keyed(room: Dictionary) -> bool:
	var required_item_id := str(room.get("locked_by_item_id", ""))
	if required_item_id == "":
		return true
	if DungeonStateModel.room_is_unlocked(run_state, str(room.get("id", ""))):
		return true
	return DungeonStateModel.reward_totals(run_state).get("items", []).has(required_item_id)


func _room_position_summary(room: Dictionary) -> String:
	var position: Dictionary = room.get("position", {})
	return "x%s y%s" % [int(position.get("x", 0)), int(position.get("y", 0))]


func _room_kind_marker(kind: String) -> String:
	match kind:
		"entrance":
			return "[IN]"
		"treasure":
			return "[$]"
		"combat":
			return "[!]"
		"guarded_treasure":
			return "[G]"
		"exit":
			return "[OUT]"
		_:
			return "[ ]"


func _rooms_by_id() -> Dictionary:
	var indexed: Dictionary = {}
	for room: Dictionary in dungeon.get("rooms", []):
		indexed[room["id"]] = room
	return indexed


func _room_screen_position(room: Dictionary) -> Vector2:
	var position: Dictionary = room.get("position", {})
	return GRAPH_ORIGIN + Vector2(float(position.get("x", 0)), float(position.get("y", 0))) * GRAPH_STEP


func _content_summary(room: Dictionary) -> String:
	var labels: Array[String] = []
	for content: Dictionary in room.get("content", []):
		var content_type: String = str(content.get("type", "missing"))
		if content_type == "empty":
			labels.append("quiet passage")
		elif content_type == "guarded_treasure":
			labels.append("guarded treasure")
		elif content_type == "combat":
			labels.append("combat")
		elif content_type == "treasure":
			var rewards: Dictionary = content.get("rewards", {})
			labels.append("treasure %sg" % int(rewards.get("gold", 0)))
		else:
			labels.append(content_type)
	return ", ".join(labels)


func _room_state_summary(room_id: String) -> String:
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	if str(pending.get("room_id", "")) == room_id:
		return "danger"
	if DungeonStateModel.room_reward_is_claimed(run_state, room_id):
		return "reward claimed"
	if DungeonStateModel.room_reward_is_unlocked(run_state, room_id):
		return "reward unlocked"
	if DungeonStateModel.room_is_cleared(run_state, room_id):
		return "cleared"
	if DungeonStateModel.room_is_visited(run_state, room_id):
		return "visited"
	return "unexplored"


func _reward_summary(room: Dictionary) -> String:
	var room_id := str(room.get("id", ""))
	for content: Dictionary in room.get("content", []):
		if not content.has("rewards"):
			continue
		var rewards: Dictionary = content.get("rewards", {})
		var reward_text := "Reward: %sg" % int(rewards.get("gold", 0))
		var items: Array = rewards.get("items", [])
		if not items.is_empty():
			reward_text += ", %s" % ", ".join(items)
		if DungeonStateModel.room_reward_is_claimed(run_state, room_id):
			return "%s (claimed)" % reward_text
		if str(content.get("type", "")) == "guarded_treasure" and not DungeonStateModel.room_reward_is_unlocked(run_state, room_id):
			return "%s (guarded)" % reward_text
		return reward_text
	return ""


func _status_summary() -> String:
	var current_room_id := str(run_state.get("current_room_id", ""))
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var pending_hazard: Dictionary = run_state.get("pending_corridor_hazard", {})
	if not pending_hazard.is_empty():
		return "Resolve the corridor event before the party reaches %s." % _room_display_name(str(pending_hazard.get("to_room_id", "")))
	if not pending.is_empty():
		return "%s is not safe. Enter combat to push deeper." % _room_display_name(current_room_id)
	if bool(run_state.get("completed", false)):
		return "Expedition complete. Future world-map return flow can start here."
	var exits := _connected_room_labels(current_room_id)
	if DungeonStateModel.room_is_cleared(run_state, current_room_id):
		return "%s is secure. Choose an exit to continue." % _room_display_name(current_room_id)
	if exits.is_empty():
		return "%s has no visible exits." % _room_display_name(current_room_id)
	return "Choose a connected room to continue exploring."


func _progress_summary() -> String:
	var room_count: int = dungeon.get("rooms", []).size()
	var visited_count: int = run_state.get("visited_room_ids", []).size()
	var cleared_count: int = run_state.get("cleared_room_ids", []).size()
	var totals := DungeonStateModel.reward_totals(run_state)
	return "Rooms visited %s/%s | Secured %s/%s | Light %s/%s %s | Oil %s | Pickaxe %s | Trap Tools %s | Debuffs %s | Gold %s | Items %s | XP %s" % [
		visited_count,
		room_count,
		cleared_count,
		room_count,
		int(run_state.get("light_level", 0)),
		int(run_state.get("max_light_level", 0)),
		str(run_state.get("light_state", "")),
		DungeonStateModel.supply_count(run_state, "lamp_oil"),
		DungeonStateModel.supply_count(run_state, "pickaxe"),
		DungeonStateModel.supply_count(run_state, "trap_tools"),
		DungeonStateModel.active_debuff_summary(run_state).size(),
		int(totals.get("gold", 0)),
		totals.get("items", []).size(),
		int(totals.get("xp", 0)),
	]


func _current_room_has_claimable_reward() -> bool:
	var room: Dictionary = _rooms_by_id().get(selected_room_id, {})
	if room.is_empty():
		return false
	if DungeonStateModel.room_reward_is_claimed(run_state, selected_room_id):
		return false
	for content: Dictionary in room.get("content", []):
		var content_type := str(content.get("type", ""))
		if not content.has("rewards"):
			continue
		if content_type == "treasure":
			return true
		if content_type == "guarded_treasure" and DungeonStateModel.room_reward_is_unlocked(run_state, selected_room_id):
			return true
	return false


func _current_room_can_finish_expedition() -> bool:
	if bool(run_state.get("completed", false)):
		return false
	if not run_state.get("pending_combat_request", {}).is_empty():
		return false
	var room: Dictionary = _rooms_by_id().get(selected_room_id, {})
	return str(room.get("kind", "")) == "exit"


func _can_use_lamp_oil() -> bool:
	if bool(run_state.get("completed", false)):
		return false
	if DungeonStateModel.supply_count(run_state, "lamp_oil") <= 0:
		return false
	return int(run_state.get("light_level", 0)) < int(run_state.get("max_light_level", 0))


func _apply_hud_visual_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.075, 0.07, 0.96)
	panel_style.border_color = Color(0.55, 0.45, 0.24)
	panel_style.set_border_width_all(3)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	detail_panel.add_theme_stylebox_override("panel", panel_style)


func _button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _number_key_slot(event: InputEventKey) -> int:
	match event.keycode:
		KEY_1:
			return 1
		KEY_2:
			return 2
		KEY_3:
			return 3
		KEY_4:
			return 4
		KEY_5:
			return 5
		KEY_6:
			return 6
		KEY_7:
			return 7
		KEY_8:
			return 8
		KEY_9:
			return 9
		_:
			return 0


func _room_style(room_id: String, kind: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var is_current: bool = room_id == str(run_state.get("current_room_id", ""))
	var is_start: bool = room_id == str(dungeon.get("start_room_id", ""))
	var is_visited: bool = DungeonStateModel.room_is_visited(run_state, room_id)
	var is_cleared: bool = DungeonStateModel.room_is_cleared(run_state, room_id)
	var is_reward_unlocked: bool = DungeonStateModel.room_reward_is_unlocked(run_state, room_id)
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var is_pending_combat: bool = str(pending.get("room_id", "")) == room_id
	var color := Color(0.15, 0.15, 0.16)
	if kind == "combat" or kind == "guarded_treasure":
		color = Color(0.24, 0.12, 0.12)
	elif kind == "treasure":
		color = Color(0.25, 0.2, 0.1)
	elif kind == "exit":
		color = Color(0.1, 0.2, 0.17)
	elif is_start:
		color = Color(0.14, 0.2, 0.18)
	if is_cleared:
		color = Color(0.12, 0.23, 0.16)
	if is_reward_unlocked:
		color = Color(0.24, 0.22, 0.11)
	if is_pending_combat:
		color = Color(0.34, 0.09, 0.08)
	if is_current:
		color = color.lightened(0.18)
	style.bg_color = color
	if is_current:
		style.border_color = Color(0.88, 0.72, 0.36)
	elif is_pending_combat:
		style.border_color = Color(0.85, 0.28, 0.22)
	elif is_cleared:
		style.border_color = Color(0.38, 0.62, 0.4)
	elif is_visited or is_start:
		style.border_color = Color(0.56, 0.48, 0.32)
	else:
		style.border_color = Color(0.33, 0.31, 0.27)
	style.set_border_width_all(4 if is_current else 2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _state_list_or_none(items: Array) -> String:
	if items.is_empty():
		return "none"
	return ", ".join(items)


func _room_display_name(room_id: String) -> String:
	return _rooms_by_id().get(room_id, {}).get("display_name", room_id)


func _debug_combat_payload(result: String, pending: Dictionary) -> Dictionary:
	return {
		"result": result,
		"combat_id": "debug_dungeon_combat",
		"source_dungeon_id": str(pending.get("dungeon_id", "")),
		"source_room_id": str(pending.get("room_id", "")),
		"surviving_players": [],
		"defeated_player_ids": [],
		"defeated_enemy_ids": [],
		"remaining_enemies": [],
		"rewards": {"xp": 0, "gold": 0, "items": []},
	}


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open dungeon data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Dungeon data is not an object: %s" % path)
		return {}
	return parsed


func _run_session() -> Node:
	return get_node("/root/DungeonRunSession")
