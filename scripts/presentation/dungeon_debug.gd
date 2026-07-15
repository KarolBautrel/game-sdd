extends Control

const DUNGEON_PATH := "res://resources/data/dungeons/dungeon_old_mine.json"
const ROOM_SIZE := Vector2(220, 104)
const GRAPH_ORIGIN := Vector2(210, 250)
const GRAPH_STEP := Vector2(300, 190)

var dungeon: Dictionary = {}
var room_nodes: Dictionary = {}
var selected_room_id := ""

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var detail_label: Label = %DetailLabel
@onready var graph_layer: Control = %GraphLayer


func _ready() -> void:
	dungeon = _load_json(DUNGEON_PATH)
	if dungeon.is_empty():
		title_label.text = "Dungeon data missing"
		status_label.text = "Could not load %s" % DUNGEON_PATH
		return
	selected_room_id = str(dungeon.get("start_room_id", ""))
	title_label.text = dungeon.get("display_name", "Dungeon")
	status_label.text = "Abstract dungeon route - data contract view"
	_build_graph()
	_update_detail()


func _draw() -> void:
	if dungeon.is_empty():
		return
	var rooms_by_id: Dictionary = _rooms_by_id()
	for corridor: Dictionary in dungeon.get("corridors", []):
		var from_room: Dictionary = rooms_by_id.get(corridor.get("from", ""), {})
		var to_room: Dictionary = rooms_by_id.get(corridor.get("to", ""), {})
		if from_room.is_empty() or to_room.is_empty():
			continue
		var from_pos: Vector2 = _room_screen_position(from_room) + ROOM_SIZE * 0.5
		var to_pos: Vector2 = _room_screen_position(to_room) + ROOM_SIZE * 0.5
		draw_line(from_pos, to_pos, Color(0.45, 0.42, 0.34), 10.0, true)
		draw_line(from_pos, to_pos, Color(0.12, 0.11, 0.1), 4.0, true)


func _build_graph() -> void:
	for child in graph_layer.get_children():
		child.queue_free()
	room_nodes.clear()
	for room: Dictionary in dungeon.get("rooms", []):
		var room_panel: PanelContainer = _create_room_panel(room)
		graph_layer.add_child(room_panel)
		room_nodes[room["id"]] = room_panel
	queue_redraw()


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
		selected_room_id = room_id
		_refresh_room_styles()
		_update_detail()
	)
	panel.add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel


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
	var lines: PackedStringArray = [
		"Room: %s" % room.get("display_name", selected_room_id),
		"Kind: %s" % room.get("kind", "missing"),
		"Content: %s" % _content_summary(room),
		"Connected: %s" % ", ".join(_connected_room_labels(selected_room_id)),
	]
	detail_label.text = "\n".join(lines)


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
	var is_selected: bool = room_id == selected_room_id
	var is_start: bool = room_id == str(dungeon.get("start_room_id", ""))
	var color := Color(0.15, 0.15, 0.16)
	if kind == "combat" or kind == "guarded_treasure":
		color = Color(0.24, 0.12, 0.12)
	elif kind == "treasure":
		color = Color(0.25, 0.2, 0.1)
	elif kind == "exit":
		color = Color(0.1, 0.2, 0.17)
	elif is_start:
		color = Color(0.14, 0.2, 0.18)
	if is_selected:
		color = color.lightened(0.18)
	style.bg_color = color
	style.border_color = Color(0.75, 0.64, 0.42) if is_selected or is_start else Color(0.33, 0.31, 0.27)
	style.set_border_width_all(4 if is_selected else 2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


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
