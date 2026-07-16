extends Control

const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")

const DUNGEON_PATH := "res://resources/data/dungeons/dungeon_old_mine.json"
const DUNGEON_SOURCE_AUTHORED := "authored"
const DUNGEON_SOURCE_GENERATED := "generated"
const DEFAULT_GENERATED_DUNGEON_DIFFICULTY := 2
const ROOM_SIZE := Vector2(196, 96)
const ENTER_COMBAT_LABEL := "Enter Combat"
const FINISH_EXPEDITION_LABEL := "Finish Expedition"
const FALLBACK_VIEWPORT_SIZE := Vector2(2048, 1152)

var dungeon: Dictionary = {}
var dungeon_source := DUNGEON_SOURCE_AUTHORED
var generated_dungeon_seed := 0
var generated_dungeon_difficulty := DEFAULT_GENERATED_DUNGEON_DIFFICULTY
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
var recovery_button: Button
var reset_button: Button
var corridor_event_panel: PanelContainer
var corridor_event_title_label: Label
var corridor_event_type_label: Label
var corridor_event_message_label: Label
var corridor_event_supply_label: Label
var corridor_event_result_label: Label
var corridor_event_choice_row: HBoxContainer
var corridor_hazard_choice_buttons: Array[Button] = []
var map_frame_panel: PanelContainer
var map_title_label: Label
var route_state_label: Label
var resource_tray_panel: PanelContainer
var resource_tile_labels: Dictionary = {}
var map_legend_panel: PanelContainer
var loadout_panel: PanelContainer
var loadout_summary_label: Label
var generator_summary_label: Label
var source_toggle_button: Button
var generated_reroll_button: Button
var generated_difficulty_buttons: Array[Button] = []
var loadout_rows: Dictionary = {}
var selected_supply_loadout: Dictionary = {}
var expedition_started := false
var map_area := Rect2(24, 178, 1320, 920)
var resource_tray_area := Rect2(24, 104, 1320, 58)
var legend_area := Rect2(48, 1022, 600, 54)
var detail_area := Rect2(1584, 150, 440, 966)
var loadout_area := Rect2(1608, 368, 392, 520)
var graph_origin := Vector2(140, 360)
var graph_step := Vector2(258, 168)
var room_node_size := ROOM_SIZE
var graph_node_scale := 1.0


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not run_state.get("pending_corridor_hazard", {}).is_empty() or not run_state.get("pending_room_event", {}).is_empty():
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
	if _run_session().has_dungeon_run():
		dungeon = _run_session().dungeon_data.duplicate(true)
		dungeon_source = _source_for_dungeon(dungeon)
		generated_dungeon_seed = int(dungeon.get("hazard_seed", 0)) if dungeon_source == DUNGEON_SOURCE_GENERATED else 0
		run_state = _run_session().dungeon_state.duplicate(true)
		selected_supply_loadout = run_state.get("selected_supply_loadout", DungeonStateModel.default_supply_loadout(dungeon)).duplicate(true)
		expedition_started = true
		if _run_session().last_feedback != "":
			last_feedback = _run_session().last_feedback
	else:
		dungeon = _dungeon_data_for_source(dungeon_source)
		if dungeon.is_empty():
			title_label.text = "Dungeon data missing"
			status_label.text = "Could not load %s" % DUNGEON_PATH
			return
		selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
		run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
		expedition_started = false
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	title_label.text = dungeon.get("display_name", "Dungeon")
	_apply_responsive_layout()
	_apply_hud_visual_style()
	_create_map_chrome()
	_create_resource_tray()
	_create_map_legend()
	_create_loadout_panel()
	_create_action_buttons()
	_create_corridor_event_panel()
	_apply_positioned_chrome()
	_build_graph()
	_update_detail()
	_refresh_loadout_panel()


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	if dungeon.is_empty() or detail_panel == null:
		return
	_apply_responsive_layout()
	_apply_positioned_chrome()
	_build_graph()
	_refresh_loadout_panel()


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


func _apply_responsive_layout() -> void:
	var viewport_size := FALLBACK_VIEWPORT_SIZE
	if is_inside_tree():
		viewport_size = get_viewport_rect().size
	var margin: float = 24.0
	var detail_width: float = clampf(viewport_size.x * 0.23, 420.0, 520.0)
	var detail_x: float = viewport_size.x - detail_width - margin
	var detail_top: float = 148.0
	detail_area = Rect2(detail_x, detail_top, detail_width, max(520.0, viewport_size.y - detail_top - 36.0))
	resource_tray_area = Rect2(margin, 102.0, detail_x - margin * 2.0, 58.0)
	map_area = Rect2(margin, 178.0, detail_x - margin * 2.0, max(560.0, viewport_size.y - 210.0))
	legend_area = Rect2(map_area.position + Vector2(18, map_area.size.y - 70), Vector2(min(620.0, map_area.size.x - 36.0), 54))
	loadout_area = Rect2(detail_area.position + Vector2(22, 226), Vector2(detail_area.size.x - 44, 520))
	_apply_detail_panel_layout()
	_recalculate_graph_transform()


func _apply_detail_panel_layout() -> void:
	if detail_panel == null:
		return
	detail_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	detail_panel.position = detail_area.position
	detail_panel.size = detail_area.size
	detail_panel.custom_minimum_size = detail_area.size


func _apply_positioned_chrome() -> void:
	if map_frame_panel != null:
		map_frame_panel.position = map_area.position
		map_frame_panel.custom_minimum_size = map_area.size
		map_frame_panel.size = map_area.size
	if resource_tray_panel != null:
		resource_tray_panel.position = resource_tray_area.position
		resource_tray_panel.custom_minimum_size = resource_tray_area.size
		resource_tray_panel.size = resource_tray_area.size
	if map_legend_panel != null:
		map_legend_panel.position = legend_area.position
		map_legend_panel.custom_minimum_size = legend_area.size
		map_legend_panel.size = legend_area.size
	if loadout_panel != null:
		loadout_panel.position = loadout_area.position
		loadout_panel.custom_minimum_size = loadout_area.size
		loadout_panel.size = loadout_area.size


func _recalculate_graph_transform() -> void:
	var bounds := _authored_room_bounds()
	var graph_rect := Rect2(map_area.position + Vector2(80, 126), map_area.size - Vector2(160, 250))
	var range_x = max(1.0, float(bounds["max_x"] - bounds["min_x"]))
	var range_y = max(1.0, float(bounds["max_y"] - bounds["min_y"]))
	var columns: float = range_x + 1.0
	var rows: float = range_y + 1.0
	var available_cell := Vector2(graph_rect.size.x / columns, graph_rect.size.y / rows)
	var fit_scale: float = min(1.0, min(available_cell.x / ROOM_SIZE.x, available_cell.y / ROOM_SIZE.y) * 0.82)
	graph_node_scale = clampf(fit_scale, 0.64, 1.0)
	room_node_size = Vector2(
		floor(ROOM_SIZE.x * graph_node_scale),
		floor(ROOM_SIZE.y * graph_node_scale)
	)
	graph_rect.size.x = max(room_node_size.x + 16, graph_rect.size.x)
	graph_rect.size.y = max(room_node_size.y + 16, graph_rect.size.y)
	graph_step = Vector2(
		(graph_rect.size.x - room_node_size.x) / range_x,
		(graph_rect.size.y - room_node_size.y) / range_y
	)
	graph_origin = graph_rect.position - Vector2(float(bounds["min_x"]), float(bounds["min_y"])) * graph_step


func _authored_room_bounds() -> Dictionary:
	var min_x := 0
	var min_y := 0
	var max_x := 0
	var max_y := 0
	var first := true
	for room: Dictionary in dungeon.get("rooms", []):
		var position: Dictionary = room.get("position", {})
		var x := int(position.get("x", 0))
		var y := int(position.get("y", 0))
		if first:
			min_x = x
			max_x = x
			min_y = y
			max_y = y
			first = false
		else:
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)
	return {"min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y}


func _build_corridors() -> void:
	var rooms_by_id: Dictionary = _rooms_by_id()
	for corridor: Dictionary in dungeon.get("corridors", []):
		var from_room: Dictionary = rooms_by_id.get(corridor.get("from", ""), {})
		var to_room: Dictionary = rooms_by_id.get(corridor.get("to", ""), {})
		if from_room.is_empty() or to_room.is_empty():
			continue
		var from_pos: Vector2 = _room_screen_position(from_room) + room_node_size * 0.5
		var to_pos: Vector2 = _room_screen_position(to_room) + room_node_size * 0.5
		graph_layer.add_child(_create_corridor_line(from_pos, to_pos, Color(0.08, 0.075, 0.065), 16.0 * graph_node_scale))
		graph_layer.add_child(_create_corridor_line(from_pos, to_pos, _corridor_color(corridor), 8.0 * graph_node_scale))
		var marker := _corridor_marker_label(corridor)
		if marker != "":
			graph_layer.add_child(_create_corridor_marker(marker, from_pos.lerp(to_pos, 0.5)))


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


func _create_corridor_marker(text: String, center: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	var marker_size := Vector2(92, 32) * graph_node_scale
	panel.position = center - marker_size * 0.5
	panel.custom_minimum_size = marker_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _fantasy_panel_style(Color(0.09, 0.065, 0.038), Color(0.72, 0.46, 0.18), 1, 5))

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", max(10, int(13.0 * graph_node_scale)))
	label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.44))
	panel.add_child(label)
	return panel


func _create_room_panel(room: Dictionary) -> PanelContainer:
	var room_id: String = str(room["id"])
	var panel := PanelContainer.new()
	panel.position = _room_screen_position(room)
	panel.custom_minimum_size = room_node_size
	panel.size = room_node_size
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", _room_style(room_id, str(room.get("kind", ""))))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", max(8, int(12.0 * graph_node_scale)))
	margin.add_theme_constant_override("margin_top", max(7, int(10.0 * graph_node_scale)))
	margin.add_theme_constant_override("margin_right", max(8, int(12.0 * graph_node_scale)))
	margin.add_theme_constant_override("margin_bottom", max(7, int(10.0 * graph_node_scale)))
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	var name_label := Label.new()
	name_label.text = _room_map_label(room)
	name_label.add_theme_font_size_override("font_size", max(13, int(18.0 * graph_node_scale)))
	name_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_label)

	var content_label := Label.new()
	content_label.text = _content_summary(room)
	content_label.add_theme_font_size_override("font_size", max(10, int(13.0 * graph_node_scale)))
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

	recovery_button = Button.new()
	recovery_button.text = "Use Remedy"
	recovery_button.custom_minimum_size = Vector2(0, 48)
	recovery_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recovery_button.add_theme_font_size_override("font_size", 18)
	recovery_button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.20, 0.20), Color(0.46, 0.76, 0.70)))
	recovery_button.add_theme_stylebox_override("hover", _button_style(Color(0.16, 0.28, 0.28), Color(0.62, 0.96, 0.86)))
	recovery_button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.14, 0.14), Color(0.36, 0.62, 0.58)))
	recovery_button.pressed.connect(func() -> void:
		_use_recovery_supply()
	)
	action_row.add_child(recovery_button)

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


func _create_map_chrome() -> void:
	map_frame_panel = PanelContainer.new()
	map_frame_panel.position = map_area.position
	map_frame_panel.custom_minimum_size = map_area.size
	map_frame_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_frame_panel.add_theme_stylebox_override("panel", _map_frame_style())
	add_child(map_frame_panel)
	move_child(map_frame_panel, graph_layer.get_index())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	map_frame_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	map_title_label = Label.new()
	map_title_label.text = "Old Mine Route Map"
	map_title_label.add_theme_font_size_override("font_size", 25)
	map_title_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.46))
	box.add_child(map_title_label)

	route_state_label = Label.new()
	route_state_label.add_theme_font_size_override("font_size", 16)
	route_state_label.add_theme_color_override("font_color", Color(0.68, 0.74, 0.68))
	box.add_child(route_state_label)


func _create_resource_tray() -> void:
	resource_tray_panel = PanelContainer.new()
	resource_tray_panel.position = resource_tray_area.position
	resource_tray_panel.custom_minimum_size = resource_tray_area.size
	resource_tray_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resource_tray_panel.add_theme_stylebox_override("panel", _fantasy_panel_style(Color(0.045, 0.038, 0.032, 0.98), Color(0.48, 0.34, 0.16), 2, 6))
	add_child(resource_tray_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	resource_tray_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	resource_tile_labels.clear()
	for tile_id: String in ["light", "oil", "pickaxe", "trap_tools", "remedy_kit", "effects"]:
		var label := _create_resource_tile_label()
		resource_tile_labels[tile_id] = label
		row.add_child(label)


func _create_resource_tile_label() -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(196, 38)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.62))
	label.add_theme_stylebox_override("normal", _fantasy_panel_style(Color(0.075, 0.067, 0.052), Color(0.42, 0.30, 0.14), 1, 4))
	return label


func _create_map_legend() -> void:
	map_legend_panel = PanelContainer.new()
	map_legend_panel.position = legend_area.position
	map_legend_panel.custom_minimum_size = legend_area.size
	map_legend_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_legend_panel.add_theme_stylebox_override("panel", _fantasy_panel_style(Color(0.045, 0.040, 0.032, 0.96), Color(0.42, 0.31, 0.16), 1, 5))
	add_child(map_legend_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	map_legend_panel.add_child(margin)

	var label := Label.new()
	label.text = " | ".join(_map_legend_lines())
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.76, 0.74, 0.62))
	margin.add_child(label)


func _create_loadout_panel() -> void:
	loadout_panel = PanelContainer.new()
	loadout_panel.custom_minimum_size = loadout_area.size
	loadout_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	loadout_panel.position = loadout_area.position
	loadout_panel.add_theme_stylebox_override("panel", _button_style(Color(0.055, 0.06, 0.055), Color(0.68, 0.54, 0.26)))
	add_child(loadout_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	loadout_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Prepare Expedition"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.94, 0.80, 0.46))
	box.add_child(title)

	loadout_summary_label = Label.new()
	loadout_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loadout_summary_label.add_theme_font_size_override("font_size", 17)
	loadout_summary_label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.64))
	box.add_child(loadout_summary_label)

	generator_summary_label = Label.new()
	generator_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	generator_summary_label.add_theme_font_size_override("font_size", 15)
	generator_summary_label.add_theme_color_override("font_color", Color(0.68, 0.74, 0.66))
	box.add_child(generator_summary_label)

	var difficulty_row := HBoxContainer.new()
	difficulty_row.add_theme_constant_override("separation", 8)
	box.add_child(difficulty_row)

	var difficulty_label := Label.new()
	difficulty_label.text = "Difficulty"
	difficulty_label.custom_minimum_size = Vector2(118, 0)
	difficulty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_font_size_override("font_size", 16)
	difficulty_label.add_theme_color_override("font_color", Color(0.84, 0.82, 0.70))
	difficulty_row.add_child(difficulty_label)

	generated_difficulty_buttons.clear()
	for difficulty in [1, 2, 3]:
		var selected_difficulty := int(difficulty)
		var difficulty_button := Button.new()
		difficulty_button.text = "D%s" % selected_difficulty
		difficulty_button.custom_minimum_size = Vector2(0, 34)
		difficulty_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		difficulty_button.add_theme_font_size_override("font_size", 15)
		difficulty_button.pressed.connect(func() -> void:
			_set_generated_difficulty(selected_difficulty)
		)
		difficulty_row.add_child(difficulty_button)
		generated_difficulty_buttons.append(difficulty_button)

	loadout_rows.clear()
	for supply_id: String in _loadout_supply_ids():
		box.add_child(_create_loadout_row(supply_id))

	var start_button := Button.new()
	start_button.text = "Start Expedition"
	start_button.custom_minimum_size = Vector2(0, 50)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.add_theme_font_size_override("font_size", 19)
	start_button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.24, 0.16), Color(0.56, 0.86, 0.48)))
	start_button.add_theme_stylebox_override("hover", _button_style(Color(0.16, 0.34, 0.20), Color(0.70, 1.0, 0.56)))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.16, 0.11), Color(0.44, 0.66, 0.36)))
	start_button.pressed.connect(func() -> void:
		_start_expedition_with_loadout()
	)
	box.add_child(start_button)

	source_toggle_button = Button.new()
	source_toggle_button.custom_minimum_size = Vector2(0, 40)
	source_toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	source_toggle_button.add_theme_font_size_override("font_size", 16)
	source_toggle_button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.11, 0.12), Color(0.46, 0.40, 0.28)))
	source_toggle_button.add_theme_stylebox_override("hover", _button_style(Color(0.14, 0.15, 0.16), Color(0.76, 0.62, 0.32)))
	source_toggle_button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.08, 0.09), Color(0.54, 0.44, 0.24)))
	source_toggle_button.pressed.connect(func() -> void:
		_toggle_dungeon_source()
	)
	box.add_child(source_toggle_button)

	generated_reroll_button = Button.new()
	generated_reroll_button.text = "Reroll Generated"
	generated_reroll_button.custom_minimum_size = Vector2(0, 40)
	generated_reroll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	generated_reroll_button.add_theme_font_size_override("font_size", 16)
	generated_reroll_button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.10, 0.13), Color(0.50, 0.38, 0.58)))
	generated_reroll_button.add_theme_stylebox_override("hover", _button_style(Color(0.16, 0.13, 0.18), Color(0.74, 0.54, 0.86)))
	generated_reroll_button.add_theme_stylebox_override("pressed", _button_style(Color(0.09, 0.08, 0.10), Color(0.44, 0.30, 0.58)))
	generated_reroll_button.pressed.connect(func() -> void:
		_reroll_generated_dungeon()
	)
	box.add_child(generated_reroll_button)


func _create_loadout_row(supply_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = _supply_display_name(supply_id)
	label.custom_minimum_size = Vector2(170, 0)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.84, 0.82, 0.70))
	row.add_child(label)

	var minus_button := Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(44, 38)
	minus_button.add_theme_font_size_override("font_size", 20)
	minus_button.pressed.connect(func() -> void:
		_adjust_loadout_supply(supply_id, -1)
	)
	row.add_child(minus_button)

	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(54, 0)
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.52))
	row.add_child(value_label)

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(44, 38)
	plus_button.add_theme_font_size_override("font_size", 20)
	plus_button.pressed.connect(func() -> void:
		_adjust_loadout_supply(supply_id, 1)
	)
	row.add_child(plus_button)

	loadout_rows[supply_id] = {
		"value_label": value_label,
		"minus_button": minus_button,
		"plus_button": plus_button,
	}
	return row


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
	if _loadout_pending():
		last_feedback = "Start the expedition before entering rooms."
		_update_detail()
		return
	var result: Dictionary = DungeonStateModel.enter_room(dungeon, run_state, room_id)
	if result["status"] == "accepted":
		run_state = result["state"]
		_run_session().set_dungeon_run(dungeon, run_state)
		selected_room_id = str(run_state["current_room_id"])
		last_feedback = _movement_feedback(result, selected_room_id)
		var pending_room_event: Dictionary = run_state.get("pending_room_event", {})
		if not pending_room_event.is_empty():
			_show_room_event_popup(pending_room_event)
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


func _use_recovery_supply() -> void:
	var result: Dictionary = DungeonStateModel.use_recovery_supply(run_state, "remedy_kit")
	if result["status"] == "accepted":
		run_state = result["state"]
		if is_inside_tree():
			_run_session().set_dungeon_run(dungeon, run_state)
		last_feedback = str(result["event"].get("message", "Recovery used."))
	else:
		last_feedback = "Cannot use remedy: %s." % result["rejection"]
	_refresh_room_styles()
	_update_detail()


func _reset_expedition() -> void:
	_run_session().clear()
	selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
	expedition_started = false
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	last_feedback = "Expedition reset. Prepare a new loadout."
	if corridor_event_panel != null:
		corridor_event_panel.hide()
	_refresh_room_styles()
	_update_detail()
	_refresh_loadout_panel()


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


func _resolve_pending_room_event(choice_id: String) -> void:
	var result: Dictionary = DungeonStateModel.resolve_room_event_choice(dungeon, run_state, choice_id)
	if result["status"] == "accepted":
		run_state = result["state"]
		if is_inside_tree():
			_run_session().set_dungeon_run(dungeon, run_state)
		last_feedback = "Room event resolved: %s." % str(result["event"].get("outcome_id", "resolved"))
	else:
		last_feedback = "Cannot resolve room event: %s." % result["rejection"]
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
	if detail_label == null or panel_title == null or status_label == null or progress_label == null:
		return
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
	_refresh_loadout_panel()
	_refresh_presentation_chrome()


func _detail_lines_for_room(room: Dictionary) -> PackedStringArray:
	if _loadout_pending():
		return PackedStringArray([
			"Prepare supplies before entering the dungeon.",
			"Loadout: %s" % _loadout_summary_text(selected_supply_loadout),
			"Light starts at %s/%s." % [int(run_state.get("light_level", 0)), int(run_state.get("max_light_level", 0))],
		])
	if bool(run_state.get("completed", false)):
		return _post_run_summary_lines()
	var room_id := str(room.get("id", selected_room_id))
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var pending_hazard: Dictionary = run_state.get("pending_corridor_hazard", {})
	var pending_room_event: Dictionary = run_state.get("pending_room_event", {})
	var lines: PackedStringArray = [
		"State: %s" % _room_state_summary(room_id),
		"Position: %s" % _room_position_summary(room),
		"Content: %s" % _content_summary(room),
		"Light: %s %s/%s | Oil: %s | Pickaxe: %s | Trap Tools: %s | Remedy: %s" % [
			str(run_state.get("light_state", "bright")),
			int(run_state.get("light_level", 0)),
			int(run_state.get("max_light_level", 0)),
			DungeonStateModel.supply_count(run_state, "lamp_oil"),
			DungeonStateModel.supply_count(run_state, "pickaxe"),
			DungeonStateModel.supply_count(run_state, "trap_tools"),
			DungeonStateModel.supply_count(run_state, "remedy_kit"),
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
	if not pending_room_event.is_empty():
		lines.append("Room event: %s" % str(pending_room_event.get("message", "")))
	if not pending.is_empty():
		lines.append("Threat: enemies are waiting here.")
	if last_feedback != "":
		lines.append(last_feedback)
	var hazard_line := _last_hazard_summary()
	if hazard_line != "":
		lines.append(hazard_line)
	var room_event_line := _last_room_event_summary()
	if room_event_line != "":
		lines.append(room_event_line)
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
	if _loadout_pending():
		action_row.visible = false
		return
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var pending_hazard: Dictionary = run_state.get("pending_corridor_hazard", {})
	var pending_room_event: Dictionary = run_state.get("pending_room_event", {})
	var has_pending := not pending.is_empty()
	var blocked_by_event := not pending_hazard.is_empty() or not pending_room_event.is_empty()
	var has_reward := not blocked_by_event and _current_room_has_claimable_reward()
	var has_finish := not blocked_by_event and _current_room_can_finish_expedition()
	var has_oil := not blocked_by_event and _can_use_lamp_oil()
	var has_recovery := not blocked_by_event and _can_use_recovery_supply()
	action_row.visible = true
	start_combat_button.disabled = not has_pending
	start_combat_button.visible = has_pending
	reward_button.disabled = not has_reward
	reward_button.visible = has_reward
	finish_button.disabled = not has_finish
	finish_button.visible = has_finish
	oil_button.disabled = not has_oil
	oil_button.visible = has_oil
	recovery_button.disabled = not has_recovery
	recovery_button.visible = has_recovery
	reset_button.disabled = false
	reset_button.visible = true


func _refresh_exit_buttons() -> void:
	for child in exit_row.get_children():
		child.queue_free()
	if _loadout_pending():
		exit_row.visible = false
		return
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var pending_hazard: Dictionary = run_state.get("pending_corridor_hazard", {})
	var pending_room_event: Dictionary = run_state.get("pending_room_event", {})
	exit_row.visible = pending.is_empty() and pending_hazard.is_empty() and pending_room_event.is_empty()
	if not pending.is_empty() or not pending_hazard.is_empty() or not pending_room_event.is_empty():
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


func _show_room_event_popup(prompt: Dictionary) -> void:
	if corridor_event_panel == null:
		return
	for old_button: Button in corridor_hazard_choice_buttons:
		if is_instance_valid(old_button):
			old_button.queue_free()
	corridor_hazard_choice_buttons.clear()
	corridor_event_title_label.text = "Room Event"
	corridor_event_type_label.text = "%s in %s" % [
		str(prompt.get("event_type", "event")).capitalize(),
		_room_display_name(str(prompt.get("room_id", ""))),
	]
	corridor_event_message_label.text = str(prompt.get("message", ""))
	corridor_event_supply_label.text = "Room discovery"
	corridor_event_result_label.text = "Choose how the party handles this room event."
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
			_resolve_pending_room_event(action)
		)
		corridor_event_choice_row.add_child(button)
		corridor_hazard_choice_buttons.append(button)
	corridor_event_panel.show()


func _room_event_popup_text(prompt: Dictionary) -> String:
	return "%s\n\nThis happens inside %s." % [
		str(prompt.get("message", "")),
		_room_display_name(str(prompt.get("room_id", ""))),
	]


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


func _last_room_event_summary() -> String:
	var log: Array = run_state.get("room_event_log", [])
	if log.is_empty():
		return ""
	var event: Dictionary = log[log.size() - 1]
	var outcome := str(event.get("outcome_id", ""))
	var consequence_text := _consequence_summary(event.get("consequences", []))
	if consequence_text == "":
		return "Last room event: %s." % outcome
	return "Last room event: %s (%s)." % [outcome, consequence_text]


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
			"restore_light":
				labels.append("light +%s" % int(consequence.get("amount", 0)))
			"reward":
				var rewards: Dictionary = consequence.get("rewards", {})
				labels.append("+%sg" % int(rewards.get("gold", 0)))
	return ", ".join(labels)


func _active_debuff_line() -> String:
	var summary := DungeonStateModel.active_debuff_summary(run_state)
	if summary.is_empty():
		return ""
	return "Debuffs: %s" % ", ".join(summary)


func _active_debuff_summary_text() -> String:
	var summary := DungeonStateModel.active_debuff_summary(run_state)
	if summary.is_empty():
		return "none"
	return ", ".join(summary)


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


func _corridor_marker_label(corridor: Dictionary) -> String:
	var hazards: Array = DungeonStateModel._corridor_hazards(corridor)
	if hazards.is_empty():
		return ""
	var labels: Array[String] = []
	for hazard: Dictionary in hazards:
		var hazard_type := str(hazard.get("type", "hazard"))
		labels.append(hazard_type.capitalize())
	return ", ".join(labels)


func _corridor_color(corridor: Dictionary) -> Color:
	var danger := float(corridor.get("danger", 0.0))
	if danger >= 0.2:
		return Color(0.62, 0.28, 0.18)
	if danger >= 0.1:
		return Color(0.58, 0.48, 0.24)
	return Color(0.34, 0.43, 0.32)


func _map_legend_lines() -> Array[String]:
	return [
		"[IN] entrance",
		"[!] combat",
		"[$] treasure",
		"[G] guarded",
		"[OUT] exit",
		"red path danger",
	]


func _rooms_by_id() -> Dictionary:
	var indexed: Dictionary = {}
	for room: Dictionary in dungeon.get("rooms", []):
		indexed[room["id"]] = room
	return indexed


func _room_screen_position(room: Dictionary) -> Vector2:
	var position: Dictionary = room.get("position", {})
	return graph_origin + Vector2(float(position.get("x", 0)), float(position.get("y", 0))) * graph_step


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
		elif content_type == "room_event":
			labels.append("room event")
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


func _start_expedition_with_loadout() -> void:
	selected_supply_loadout = DungeonStateModel.clamp_supply_loadout(dungeon, selected_supply_loadout)
	run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
	if is_inside_tree():
		_run_session().set_dungeon_run(dungeon, run_state)
	expedition_started = true
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	last_feedback = "Expedition started with %s." % _loadout_summary_text(selected_supply_loadout)
	if loadout_panel != null:
		loadout_panel.hide()
	if detail_label != null:
		_refresh_room_styles()
		_update_detail()


func _adjust_loadout_supply(supply_id: String, delta: int) -> void:
	if selected_supply_loadout.is_empty():
		selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	var next_loadout := selected_supply_loadout.duplicate(true)
	next_loadout[supply_id] = int(next_loadout.get(supply_id, 0)) + delta
	selected_supply_loadout = DungeonStateModel.clamp_supply_loadout(dungeon, next_loadout)
	run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	if detail_label != null:
		_refresh_room_styles()
		_update_detail()


func _refresh_loadout_panel() -> void:
	if loadout_panel == null:
		return
	loadout_panel.visible = _loadout_pending()
	if selected_supply_loadout.is_empty():
		selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	if loadout_summary_label != null:
		loadout_summary_label.text = "Source: %s\nSelected: %s" % [_source_display_name(dungeon_source), _loadout_summary_text(selected_supply_loadout)]
	if generator_summary_label != null:
		generator_summary_label.text = _generator_summary_text()
	if source_toggle_button != null:
		source_toggle_button.text = "Use %s" % _source_display_name(_other_dungeon_source())
		source_toggle_button.visible = _loadout_pending()
	if generated_reroll_button != null:
		generated_reroll_button.visible = _loadout_pending() and dungeon_source == DUNGEON_SOURCE_GENERATED
		generated_reroll_button.text = "Reroll Generated"
	_refresh_generator_difficulty_buttons()
	var options: Dictionary = dungeon.get("supply_loadout_options", {})
	for supply_id: String in loadout_rows.keys():
		var row: Dictionary = loadout_rows.get(supply_id, {})
		var value := int(selected_supply_loadout.get(supply_id, 0))
		var value_label: Label = row.get("value_label", null)
		if value_label != null:
			value_label.text = str(value)
		var option: Dictionary = options.get(supply_id, {"min": 0, "max": value})
		var minus_button: Button = row.get("minus_button", null)
		if minus_button != null:
			minus_button.disabled = value <= int(option.get("min", 0))
		var plus_button: Button = row.get("plus_button", null)
		if plus_button != null:
			plus_button.disabled = value >= int(option.get("max", value))


func _loadout_pending() -> bool:
	return not expedition_started


func _toggle_dungeon_source() -> void:
	_set_dungeon_source(_other_dungeon_source())


func _set_dungeon_source(next_source: String) -> void:
	if not _loadout_pending():
		return
	dungeon_source = next_source
	generated_dungeon_seed = _new_generated_seed() if dungeon_source == DUNGEON_SOURCE_GENERATED else 0
	dungeon = _dungeon_data_for_source(dungeon_source)
	_recalculate_graph_transform()
	selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	last_feedback = "Dungeon source changed to %s. Prepare a new loadout." % _source_display_name(dungeon_source)
	if is_inside_tree():
		_run_session().clear()
	if title_label != null:
		title_label.text = dungeon.get("display_name", "Dungeon")
	if corridor_event_panel != null:
		corridor_event_panel.hide()
	if graph_layer != null:
		_build_graph()
	_refresh_room_styles()
	_update_detail()
	_refresh_loadout_panel()


func _reroll_generated_dungeon() -> void:
	if not _loadout_pending():
		return
	dungeon_source = DUNGEON_SOURCE_GENERATED
	var previous_seed := generated_dungeon_seed
	generated_dungeon_seed = (previous_seed % 999999) + 1 if previous_seed > 0 else _new_generated_seed()
	dungeon = _dungeon_data_for_source(dungeon_source)
	_recalculate_graph_transform()
	selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	last_feedback = "Generated draft rerolled with D%s seed %s." % [generated_dungeon_difficulty, generated_dungeon_seed]
	if is_inside_tree():
		_run_session().clear()
	if title_label != null:
		title_label.text = dungeon.get("display_name", "Dungeon")
	if corridor_event_panel != null:
		corridor_event_panel.hide()
	if graph_layer != null:
		_build_graph()
	_refresh_room_styles()
	_update_detail()
	_refresh_loadout_panel()


func _set_generated_difficulty(difficulty: int) -> void:
	if not _loadout_pending():
		return
	generated_dungeon_difficulty = clampi(difficulty, 1, 3)
	if dungeon_source != DUNGEON_SOURCE_GENERATED:
		_refresh_loadout_panel()
		return
	if generated_dungeon_seed == 0:
		generated_dungeon_seed = _new_generated_seed()
	dungeon = _dungeon_data_for_source(dungeon_source)
	_recalculate_graph_transform()
	selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	last_feedback = "Generated difficulty set to D%s." % generated_dungeon_difficulty
	if is_inside_tree():
		_run_session().clear()
	if title_label != null:
		title_label.text = dungeon.get("display_name", "Dungeon")
	if corridor_event_panel != null:
		corridor_event_panel.hide()
	if graph_layer != null:
		_build_graph()
	_refresh_room_styles()
	_update_detail()
	_refresh_loadout_panel()


func _dungeon_data_for_source(source: String) -> Dictionary:
	if source == DUNGEON_SOURCE_GENERATED:
		if generated_dungeon_seed == 0:
			generated_dungeon_seed = _new_generated_seed()
		return DungeonStateModel.procedural_dungeon_draft({
			"seed": generated_dungeon_seed,
			"difficulty": generated_dungeon_difficulty,
		})
	return _load_json(DUNGEON_PATH)


func _source_for_dungeon(next_dungeon: Dictionary) -> String:
	var dungeon_id := str(next_dungeon.get("id", ""))
	if dungeon_id.begins_with("generated_"):
		return DUNGEON_SOURCE_GENERATED
	return DUNGEON_SOURCE_AUTHORED


func _other_dungeon_source() -> String:
	return DUNGEON_SOURCE_AUTHORED if dungeon_source == DUNGEON_SOURCE_GENERATED else DUNGEON_SOURCE_GENERATED


func _source_display_name(source: String) -> String:
	if source == DUNGEON_SOURCE_GENERATED:
		if generated_dungeon_seed > 0:
			return "Generated D%s S%s" % [generated_dungeon_difficulty, generated_dungeon_seed]
		return "Generated Draft"
	return "Old Mine"


func _refresh_generator_difficulty_buttons() -> void:
	for index in range(generated_difficulty_buttons.size()):
		var button: Button = generated_difficulty_buttons[index]
		var difficulty := index + 1
		button.disabled = not _loadout_pending()
		if difficulty == generated_dungeon_difficulty:
			button.add_theme_stylebox_override("normal", _button_style(Color(0.20, 0.16, 0.08), Color(0.88, 0.70, 0.30)))
			button.add_theme_stylebox_override("hover", _button_style(Color(0.26, 0.20, 0.10), Color(1.0, 0.84, 0.40)))
		else:
			button.add_theme_stylebox_override("normal", _button_style(Color(0.09, 0.09, 0.08), Color(0.38, 0.32, 0.20)))
			button.add_theme_stylebox_override("hover", _button_style(Color(0.13, 0.13, 0.11), Color(0.62, 0.50, 0.26)))


func _generator_summary_text() -> String:
	var room_count: int = dungeon.get("rooms", []).size()
	var corridor_count: int = dungeon.get("corridors", []).size()
	var hazard_count := _generated_hazard_count(dungeon)
	if dungeon_source == DUNGEON_SOURCE_GENERATED:
		return "Generated: D%s | Seed %s | Rooms %s | Corridors %s | Hazards %s" % [
			generated_dungeon_difficulty,
			generated_dungeon_seed,
			room_count,
			corridor_count,
			hazard_count,
		]
	return "Authored: Rooms %s | Corridors %s | Hazards %s" % [room_count, corridor_count, hazard_count]


func _generated_hazard_count(next_dungeon: Dictionary) -> int:
	var count := 0
	for corridor: Dictionary in next_dungeon.get("corridors", []):
		count += corridor.get("hazards", []).size()
		count += corridor.get("hazard_refs", []).size()
		count += corridor.get("hazard_pool_refs", []).size()
	return count


func _new_generated_seed() -> int:
	return int(Time.get_ticks_usec() % 999999) + 1


func _loadout_supply_ids() -> Array[String]:
	var ids: Array[String] = []
	var options: Dictionary = dungeon.get("supply_loadout_options", {})
	if options.is_empty():
		for supply_id: String in DungeonStateModel.default_supply_loadout(dungeon).keys():
			ids.append(supply_id)
	else:
		for supply_id: String in options.keys():
			ids.append(supply_id)
	ids.sort()
	return ids


func _loadout_summary_text(loadout: Dictionary) -> String:
	var labels: Array[String] = []
	for supply_id: String in _loadout_supply_ids():
		labels.append("%s %s" % [_supply_display_name(supply_id), int(loadout.get(supply_id, 0))])
	return ", ".join(labels)


func _supply_display_name(supply_id: String) -> String:
	match supply_id:
		"lamp_oil":
			return "Oil"
		"pickaxe":
			return "Pickaxe"
		"trap_tools":
			return "Trap Tools"
		"remedy_kit":
			return "Remedy"
		_:
			return supply_id.capitalize()


func _status_summary() -> String:
	if _loadout_pending():
		return "Prepare expedition supplies before entering %s." % str(dungeon.get("display_name", "Dungeon"))
	var current_room_id := str(run_state.get("current_room_id", ""))
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	var pending_hazard: Dictionary = run_state.get("pending_corridor_hazard", {})
	var pending_room_event: Dictionary = run_state.get("pending_room_event", {})
	if not pending_hazard.is_empty():
		return "Resolve the corridor event before the party reaches %s." % _room_display_name(str(pending_hazard.get("to_room_id", "")))
	if not pending_room_event.is_empty():
		return "Resolve the room event in %s." % _room_display_name(str(pending_room_event.get("room_id", "")))
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


func _refresh_presentation_chrome() -> void:
	if route_state_label != null:
		route_state_label.text = _route_state_text()
	if resource_tile_labels.is_empty():
		return
	var tile_texts := _resource_tile_texts()
	for tile_id: String in tile_texts.keys():
		var label: Label = resource_tile_labels.get(tile_id, null)
		if label != null:
			label.text = str(tile_texts.get(tile_id, ""))


func _resource_tile_texts() -> Dictionary:
	var loadout := selected_supply_loadout
	var state_supplies: Dictionary = run_state.get("supplies", {})
	var oil := int(loadout.get("lamp_oil", state_supplies.get("lamp_oil", 0))) if _loadout_pending() else DungeonStateModel.supply_count(run_state, "lamp_oil")
	var pickaxe := int(loadout.get("pickaxe", state_supplies.get("pickaxe", 0))) if _loadout_pending() else DungeonStateModel.supply_count(run_state, "pickaxe")
	var trap_tools := int(loadout.get("trap_tools", state_supplies.get("trap_tools", 0))) if _loadout_pending() else DungeonStateModel.supply_count(run_state, "trap_tools")
	var remedy_kit := int(loadout.get("remedy_kit", state_supplies.get("remedy_kit", 0))) if _loadout_pending() else DungeonStateModel.supply_count(run_state, "remedy_kit")
	return {
		"light": "Light %s/%s %s" % [
			int(run_state.get("light_level", 0)),
			int(run_state.get("max_light_level", 0)),
			str(run_state.get("light_state", "")),
		],
		"oil": "Oil %s" % oil,
		"pickaxe": "Pickaxe %s" % pickaxe,
		"trap_tools": "Trap Tools %s" % trap_tools,
		"remedy_kit": "Remedy %s" % remedy_kit,
		"effects": "Effects %s" % _active_debuff_summary_text(),
	}


func _route_state_text() -> String:
	if _loadout_pending():
		return "Preparation: choose supplies before the party enters the mine."
	var pending_hazard: Dictionary = run_state.get("pending_corridor_hazard", {})
	if not pending_hazard.is_empty():
		return "Corridor event: %s -> %s" % [
			_room_display_name(str(pending_hazard.get("from_room_id", ""))),
			_room_display_name(str(pending_hazard.get("to_room_id", ""))),
		]
	var pending_room_event: Dictionary = run_state.get("pending_room_event", {})
	if not pending_room_event.is_empty():
		return "Room event: %s" % _room_display_name(str(pending_room_event.get("room_id", "")))
	var pending: Dictionary = run_state.get("pending_combat_request", {})
	if not pending.is_empty():
		return "Combat ready: %s" % _room_display_name(str(pending.get("room_id", "")))
	return "Exploring from: %s" % _room_display_name(str(run_state.get("current_room_id", "")))


func _map_frame_style() -> StyleBoxFlat:
	var style := _fantasy_panel_style(Color(0.035, 0.033, 0.028, 0.94), Color(0.42, 0.32, 0.16), 2, 6)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 3)
	return style


func _progress_summary() -> String:
	var room_count: int = dungeon.get("rooms", []).size()
	var visited_count: int = run_state.get("visited_room_ids", []).size()
	var cleared_count: int = run_state.get("cleared_room_ids", []).size()
	var totals := DungeonStateModel.reward_totals(run_state)
	return "Rooms visited %s/%s | Secured %s/%s | Light %s/%s %s | Oil %s | Pickaxe %s | Trap Tools %s | Effects %s | Gold %s | Items %s | XP %s" % [
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
		_active_debuff_summary_text(),
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


func _can_use_recovery_supply() -> bool:
	if bool(run_state.get("completed", false)):
		return false
	if DungeonStateModel.supply_count(run_state, "remedy_kit") <= 0:
		return false
	return not DungeonStateModel.active_debuff_summary(run_state).is_empty()


func _apply_hud_visual_style() -> void:
	var panel_style := _fantasy_panel_style(Color(0.045, 0.040, 0.035, 0.98), Color(0.62, 0.44, 0.20), 2, 6)
	panel_style.shadow_color = Color(0, 0, 0, 0.50)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0, 4)
	detail_panel.add_theme_stylebox_override("panel", panel_style)


func _button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	return _fantasy_panel_style(bg_color, border_color, 2, 6)


func _fantasy_panel_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
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
	var border := Color(0.34, 0.29, 0.18)
	var width := 2
	if is_current:
		border = Color(0.92, 0.68, 0.30)
		width = 3
	elif is_pending_combat:
		border = Color(0.78, 0.26, 0.18)
	elif is_cleared:
		border = Color(0.34, 0.52, 0.32)
	elif is_visited or is_start:
		border = Color(0.52, 0.40, 0.22)
	var style := _fantasy_panel_style(color, border, width, 5)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
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
