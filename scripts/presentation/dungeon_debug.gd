extends Control

const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")

const DUNGEON_PATH := "res://resources/data/dungeons/dungeon_old_mine.json"
const ROOM_SIZE := Vector2(220, 104)
const GRAPH_ORIGIN := Vector2(210, 250)
const GRAPH_STEP := Vector2(300, 190)

var dungeon: Dictionary = {}
var run_state: Dictionary = {}
var room_nodes: Dictionary = {}
var selected_room_id := ""
var last_feedback := ""

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var detail_label: Label = %DetailLabel
@onready var graph_layer: Control = %GraphLayer
@onready var detail_box: VBoxContainer = $DetailPanel/MarginContainer/VBoxContainer

var action_row: HBoxContainer
var start_combat_button: Button
var victory_button: Button
var defeat_button: Button


func _ready() -> void:
	dungeon = _load_json(DUNGEON_PATH)
	if dungeon.is_empty():
		title_label.text = "Dungeon data missing"
		status_label.text = "Could not load %s" % DUNGEON_PATH
		return
	if DungeonRunSession.has_dungeon_run():
		run_state = DungeonRunSession.dungeon_state.duplicate(true)
		if DungeonRunSession.last_feedback != "":
			last_feedback = DungeonRunSession.last_feedback
	else:
		run_state = DungeonStateModel.initial_state(dungeon)
		DungeonRunSession.set_dungeon_run(dungeon, run_state)
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	title_label.text = dungeon.get("display_name", "Dungeon")
	status_label.text = "Dungeon state debug - click connected rooms to move"
	_create_action_buttons()
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
	name_label.text = str(room.get("display_name", room_id))
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
	detail_box.add_child(action_row)

	start_combat_button = Button.new()
	start_combat_button.text = "Start Combat"
	start_combat_button.pressed.connect(func() -> void:
		_start_pending_combat()
	)
	action_row.add_child(start_combat_button)

	victory_button = Button.new()
	victory_button.text = "Resolve Victory"
	victory_button.pressed.connect(func() -> void:
		_apply_debug_combat_result("victory")
	)
	action_row.add_child(victory_button)

	defeat_button = Button.new()
	defeat_button.text = "Resolve Defeat"
	defeat_button.pressed.connect(func() -> void:
		_apply_debug_combat_result("defeat")
	)
	action_row.add_child(defeat_button)


func _try_enter_room(room_id: String) -> void:
	var result: Dictionary = DungeonStateModel.enter_room(dungeon, run_state, room_id)
	if result["status"] == "accepted":
		run_state = result["state"]
		DungeonRunSession.set_dungeon_run(dungeon, run_state)
		selected_room_id = str(run_state["current_room_id"])
		last_feedback = "Entered %s." % _room_display_name(selected_room_id)
	else:
		last_feedback = "Cannot enter %s: %s." % [_room_display_name(room_id), result["rejection"]]
	_refresh_room_styles()
	_update_detail()


func _start_pending_combat() -> void:
	if DungeonRunSession.start_combat(dungeon, run_state):
		get_tree().change_scene_to_file(DungeonRunSession.COMBAT_SCENE_PATH)
	else:
		last_feedback = DungeonRunSession.last_feedback
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
		DungeonRunSession.set_dungeon_run(dungeon, run_state)
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
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var lines: PackedStringArray = [
		"Current: %s" % _room_display_name(str(run_state.get("current_room_id", ""))),
		"Room: %s" % room.get("display_name", selected_room_id),
		"Kind: %s" % room.get("kind", "missing"),
		"Content: %s" % _content_summary(room),
		"Connected: %s" % ", ".join(_connected_room_labels(selected_room_id)),
		"Visited: %s" % ", ".join(run_state.get("visited_room_ids", [])),
		"Cleared: %s" % ", ".join(run_state.get("cleared_room_ids", [])),
		"Rewards unlocked: %s" % _state_list_or_none(run_state.get("unlocked_reward_room_ids", [])),
	]
	if not pending.is_empty():
		lines.append("Pending combat: %s" % pending.get("combat_encounter_path", ""))
	if last_feedback != "":
		lines.append("Last: %s" % last_feedback)
	detail_label.text = "\n".join(lines)
	_refresh_action_buttons()


func _refresh_action_buttons() -> void:
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var has_pending := not pending.is_empty()
	action_row.visible = has_pending
	start_combat_button.disabled = not has_pending
	victory_button.disabled = not has_pending
	defeat_button.disabled = not has_pending


func _connected_room_labels(room_id: String) -> Array[String]:
	var rooms_by_id: Dictionary = _rooms_by_id()
	var labels: Array[String] = []
	for corridor: Dictionary in dungeon.get("corridors", []):
		var other_id: String = ""
		if corridor.get("from", "") == room_id:
			other_id = str(corridor.get("to", ""))
		elif corridor.get("to", "") == room_id:
			other_id = str(corridor.get("from", ""))
		if other_id != "":
			labels.append(rooms_by_id.get(other_id, {}).get("display_name", other_id))
	return labels


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
		if content_type == "guarded_treasure":
			labels.append("guarded treasure")
		elif content_type == "combat":
			labels.append("combat")
		elif content_type == "treasure":
			var rewards: Dictionary = content.get("rewards", {})
			labels.append("treasure %sg" % int(rewards.get("gold", 0)))
		else:
			labels.append(content_type)
	return ", ".join(labels)


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
