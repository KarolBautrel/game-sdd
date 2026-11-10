extends Control
signal scene_requested(path: String)

const AssetCatalog := preload("res://scripts/presentation/shared/asset_catalog.gd")
const PixelSkin := preload("res://scripts/presentation/shared/pixel_skin.gd")
const PartyCardScene := preload("res://scenes/ui/PartyCard.tscn")
var pixel_skin := PixelSkin.new()
var party_cards: Dictionary = {}

const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")
const DungeonEntrySelection := preload("res://scripts/domain/dungeon_entry_selection.gd")
const PartyRoster := preload("res://scripts/domain/party_roster.gd")

const DUNGEON_PATH := DungeonEntrySelection.DUNGEON_PATH
const DUNGEON_SOURCE_AUTHORED := DungeonEntrySelection.SOURCE_AUTHORED
const DUNGEON_SOURCE_GENERATED := DungeonEntrySelection.SOURCE_GENERATED
const DEFAULT_GENERATED_DUNGEON_DIFFICULTY := DungeonEntrySelection.DEFAULT_GENERATED_DUNGEON_DIFFICULTY
const ROOM_SIZE := Vector2(256, 232)
const ExpeditionChrome := preload("res://scripts/presentation/dungeon/ashen_expedition.gd")
var expedition_chrome: RefCounted
const ENTER_COMBAT_LABEL := "Enter Combat"
const FINISH_EXPEDITION_LABEL := "Finish Expedition"
const FALLBACK_VIEWPORT_SIZE := Vector2(2048, 1152)
const DUNGEON_UI_MAP_FRAME_PATH := "res://assets/ui/dungeon/processed/dungeon_ui/dungeon_ui_08.png"
const DUNGEON_UI_DETAIL_PANEL_PATH := "res://assets/ui/dungeon/processed/dungeon_ui/dungeon_ui_07.png"
const DUNGEON_UI_MODAL_PATH := "res://assets/ui/dungeon/processed/dungeon_ui/dungeon_ui_10.png"
const DUNGEON_UI_PARTY_PANEL_PATH := "res://assets/ui/dungeon/processed/dungeon_ui/dungeon_ui_10.png"
const DUNGEON_UI_PORTRAIT_FRAME_PATH := "res://assets/ui/dungeon/processed/dungeon_ui/dungeon_ui_20.png"
const DUNGEON_UI_CORRIDOR_PATH := "res://assets/ui/dungeon/processed/dungeon_icons/dungeon_icons_56.png"
const DUNGEON_UI_CORRIDOR_DIAMOND_PATH := "res://assets/ui/dungeon/processed/dungoen_ramki/dungoen_ramki_18.png"
const DUNGEON_UI_TILE_PREFIX := "res://assets/ui/dungeon/processed/dungeon_ui/dungeon_ui_"
const DUNGEON_ICON_PREFIX := "res://assets/ui/dungeon/processed/dungeon_icons/dungeon_icons_"
const DUNGEON_DEDICATED_ICON_DIR := "res://assets/ui/dungeon/processed/icons/"
const DUNGEON_ROOM_FRAME_PREFIX := "res://assets/ui/dungeon/processed/dungoen_ramki/dungoen_ramki_"
const DUNGEON_LAYOUT_OVERRIDE_PATH := "res://resources/debug/dungeon_debug_layout_overrides.json"
const LAYOUT_EDIT_HANDLE_SIZE := 24.0
const EVENT_POPUP_DEFAULT_SIZE := Vector2(700, 353)
const EVENT_POPUP_MIN_SIZE := Vector2(560, 280)
const EVENT_POPUP_MAX_SIZE := Vector2(760, 420)

var dungeon: Dictionary = {}
var entry_payload: Dictionary = DungeonEntrySelection.default_payload()
var dungeon_source := DUNGEON_SOURCE_GENERATED
var generated_dungeon_seed := int(entry_payload.get("generated_seed", 0))
var generated_dungeon_difficulty := DEFAULT_GENERATED_DUNGEON_DIFFICULTY
var generated_profile_id := DungeonEntrySelection.DEFAULT_GENERATED_PROFILE_ID
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

var action_row: GridContainer
var start_combat_button: Button
var exit_row: VBoxContainer
var reward_button: Button
var finish_button: Button
var oil_button: Button
var recovery_button: Button
var camp_button: Button
var reset_button: Button
var retreat_button: Button
var world_button: Button
var corridor_event_panel: Control
var corridor_event_title_label: Label
var corridor_event_type_label: Label
var corridor_event_message_label: Label
var corridor_event_supply_label: Label
var corridor_event_result_label: Label
var corridor_event_choice_row: HBoxContainer
var corridor_hazard_choice_buttons: Array[Button] = []
var map_frame_panel: PanelContainer
var map_scroll_container: ScrollContainer
var map_title_label: Label
var route_state_label: Label
var resource_tray_panel: PanelContainer
var resource_tiles: Dictionary = {}
var resource_tile_labels: Dictionary = {}
var loadout_panel: PanelContainer
var party_panel: PanelContainer
var party_hp_labels: Dictionary = {}
var party_hp_bars: Dictionary = {}
var party_log_label: Label
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
var party_area := Rect2(24, 988, 920, 140)
var detail_area := Rect2(1584, 150, 440, 966)
var loadout_area := Rect2(1608, 368, 392, 520)
var graph_origin := Vector2(140, 360)
var graph_step := Vector2(258, 168)
var room_node_size := ROOM_SIZE
var graph_node_scale := 1.0
var graph_content_size := Vector2(1320, 920)
var graph_axis_swap := false
var dungeon_ui_texture_cache: Dictionary = {}
var layout_overrides: Dictionary = {}
var layout_edit_enabled := false
var layout_edit_target_id := ""
var layout_edit_operation := ""
var layout_edit_drag_offset := Vector2.ZERO
var layout_edit_start_mouse := Vector2.ZERO
var layout_edit_start_rect := Rect2()
var layout_edit_preview_popup := false
var qa_input_trace_enabled := OS.get_cmdline_user_args().has("--qa-input-trace")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		if _expedition_decision_pending():
			get_viewport().set_input_as_handled()
			return
		_open_world()
		return
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		if _run_session().managed_run or _run_session().town_preparation:
			return
		_run_session().set_dungeon_run(dungeon, run_state)
		get_tree().change_scene_to_file("res://scenes/combat/CombatMapEditor.tscn")
		return
	if qa_input_trace_enabled and (event is InputEventMouseButton or event is InputEventKey):
		print("QA_INPUT ", JSON.stringify({"event": event.as_text(), "pressed": event.is_pressed(), "viewport_mouse": str(get_viewport().get_mouse_position())}))
	if _handle_layout_edit_input(event):
		return


func _expedition_decision_pending() -> bool:
	return not run_state.get("pending_corridor_hazard", {}).is_empty() or not run_state.get("pending_room_event", {}).is_empty()


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
	var target := str(exits[slot - 1].get("id", ""))
	if expedition_chrome != null:
		expedition_chrome.preview_room(self, target)
	else:
		_try_enter_room(target)


func _ready() -> void:
	if qa_input_trace_enabled:
		var qa_screen := DisplayServer.window_get_current_screen()
		print("QA_WINDOW ", JSON.stringify({"mode": DisplayServer.window_get_mode(), "window_position": str(DisplayServer.window_get_position()), "window_size": str(DisplayServer.window_get_size()), "screen": qa_screen, "screen_position": str(DisplayServer.screen_get_position(qa_screen)), "screen_size": str(DisplayServer.screen_get_size(qa_screen))}))
	if _run_session().has_dungeon_run():
		dungeon = _run_session().dungeon_data.duplicate(true)
		entry_payload = DungeonEntrySelection.payload_for_dungeon(dungeon)
		_apply_entry_payload_fields()
		run_state = _run_session().dungeon_state.duplicate(true)
		selected_supply_loadout = run_state.get("selected_supply_loadout", DungeonStateModel.default_supply_loadout(dungeon)).duplicate(true)
		expedition_started = true
		if _run_session().last_feedback != "":
			last_feedback = _run_session().last_feedback
	else:
		entry_payload = DungeonEntrySelection.default_payload()
		_apply_entry_payload_fields()
		dungeon = _dungeon_data_for_entry_payload()
		if dungeon.is_empty():
			title_label.text = "Dungeon data missing"
			status_label.text = "Could not load %s" % DUNGEON_PATH
			return
		selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
		run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
		expedition_started = false
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	title_label.text = dungeon.get("display_name", "Dungeon")
	_load_layout_overrides()
	_apply_responsive_layout()
	_apply_hud_visual_style()
	_create_map_chrome()
	_create_resource_tray()
	_create_party_status_panel()
	_create_loadout_panel()
	world_button = Button.new()
	world_button.text = "World / Ravenford [F7]"
	world_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	world_button.offset_left = -360
	world_button.offset_right = -40
	world_button.offset_top = 38
	world_button.offset_bottom = 88
	world_button.add_theme_font_size_override("font_size", 20)
	world_button.pressed.connect(_open_world)
	add_child(world_button)
	_create_action_buttons()
	_create_corridor_event_panel()
	_apply_positioned_chrome()
	_build_graph()
	_update_detail()
	_refresh_loadout_panel()
	expedition_chrome = ExpeditionChrome.new()
	expedition_chrome.setup(self)
	_build_graph()
	_refresh_presentation_chrome()


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
		graph_layer.remove_child(child)
		child.queue_free()
	room_nodes.clear()
	if expedition_chrome != null:
		expedition_chrome.build_backdrop(self)
	_build_corridors()
	for room: Dictionary in dungeon.get("rooms", []):
		var room_panel: PanelContainer = _create_room_panel(room)
		graph_layer.add_child(room_panel)
		room_nodes[room["id"]] = room_panel


func _apply_responsive_layout() -> void:
	if expedition_chrome!=null and not layout_edit_enabled:
		expedition_chrome.layout(self)
		return
	var viewport_size := FALLBACK_VIEWPORT_SIZE
	if is_inside_tree():
		viewport_size = get_viewport_rect().size
	if not layout_edit_enabled:
		_load_layout_overrides()
	var margin: float = 24.0
	var detail_width: float = clampf(viewport_size.x * 0.23, 420.0, 520.0)
	var detail_x: float = viewport_size.x - detail_width - margin
	var detail_top: float = 102.0
	detail_area = Rect2(detail_x, detail_top, detail_width, max(520.0, viewport_size.y - detail_top - 24.0))
	resource_tray_area = Rect2(margin, 102.0, detail_x - margin * 2.0, 58.0)
	var party_height := clampf(viewport_size.y * 0.16, 164.0, 190.0)
	var party_width: float = minf(620.0, detail_x - margin * 2.0)
	party_area = Rect2(margin, viewport_size.y - party_height - 24.0, party_width, party_height)
	map_area = Rect2(margin, 158.0, detail_x - margin * 2.0, max(520.0, party_area.position.y - 158.0))
	loadout_area = Rect2(detail_area.position + Vector2(22, 226), Vector2(detail_area.size.x - 44, 520))
	_apply_layout_overrides()
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
	if expedition_chrome!=null:
		expedition_chrome.layout(self)
		return
	if map_frame_panel != null:
		map_frame_panel.position = map_area.position
		map_frame_panel.custom_minimum_size = map_area.size
		map_frame_panel.size = map_area.size
	if map_scroll_container != null:
		var scroll_rect := _map_scroll_rect()
		map_scroll_container.position = scroll_rect.position
		map_scroll_container.custom_minimum_size = scroll_rect.size
		map_scroll_container.size = scroll_rect.size
		map_scroll_container.clip_contents = true
	if graph_layer != null:
		graph_layer.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		graph_layer.position = Vector2.ZERO
		graph_layer.custom_minimum_size = graph_content_size
		graph_layer.size = graph_content_size
	if resource_tray_panel != null:
		resource_tray_panel.position = resource_tray_area.position
		resource_tray_panel.custom_minimum_size = resource_tray_area.size
		resource_tray_panel.size = resource_tray_area.size
	if party_panel != null:
		party_panel.position = party_area.position
		party_panel.custom_minimum_size = party_area.size
		party_panel.size = party_area.size
	if loadout_panel != null:
		loadout_panel.position = loadout_area.position
		loadout_panel.custom_minimum_size = loadout_area.size
		loadout_panel.size = loadout_area.size
	if corridor_event_panel != null:
		_center_corridor_event_panel()


func _apply_layout_overrides() -> void:
	map_area = _rect_from_dict(layout_overrides.get("map", {}), map_area)
	resource_tray_area = _rect_from_dict(layout_overrides.get("resources", {}), resource_tray_area)
	party_area = _rect_from_dict(layout_overrides.get("party", {}), party_area)
	detail_area = _rect_from_dict(layout_overrides.get("detail", {}), detail_area)
	loadout_area = _rect_from_dict(layout_overrides.get("loadout", {}), loadout_area)


func _recalculate_graph_transform() -> void:
	if expedition_chrome != null and expedition_chrome.has_method("layout_graph"):
		expedition_chrome.layout_graph(self)
		return
	if expedition_chrome != null and expedition_chrome.use_mine_chart(self):
		graph_axis_swap = false
		graph_node_scale = 1.0
		room_node_size = Vector2(224,136)
		graph_content_size = Vector2(1720,766)
		return
	graph_axis_swap = _should_swap_graph_axes()
	var bounds := _authored_room_bounds()
	var graph_rect := Rect2(Vector2(32, 28), _map_scroll_rect().size - Vector2(64, 56))
	var range_x = max(1.0, float(bounds["max_x"] - bounds["min_x"]))
	var range_y = max(1.0, float(bounds["max_y"] - bounds["min_y"]))
	var minimum_step := Vector2(312, 272)
	if _generated_dungeon_scroll_tier() >= 2:
		minimum_step.x = 520.0
	graph_node_scale = 1.0
	room_node_size = ROOM_SIZE
	var required_graph_size := Vector2(
		room_node_size.x + range_x * minimum_step.x,
		room_node_size.y + range_y * minimum_step.y
	)
	graph_rect.size.x = max(graph_rect.size.x, required_graph_size.x)
	graph_rect.size.y = max(graph_rect.size.y, required_graph_size.y)
	graph_content_size = graph_rect.size + Vector2(64, 56)
	graph_step = Vector2(
		(graph_rect.size.x - room_node_size.x) / range_x,
		(graph_rect.size.y - room_node_size.y) / range_y
	)
	graph_origin = graph_rect.position - Vector2(float(bounds["min_x"]), float(bounds["min_y"])) * graph_step


func _map_scroll_rect() -> Rect2:
	if expedition_chrome!=null: return expedition_chrome.map_scroll_rect(self)
	var inset := Vector2(30, 42)
	var size := map_area.size - Vector2(inset.x * 2.0, inset.y + 24.0)
	return Rect2(map_area.position + inset, Vector2(maxf(120.0, size.x), maxf(120.0, size.y)))


func _authored_room_bounds() -> Dictionary:
	var min_x := 0
	var min_y := 0
	var max_x := 0
	var max_y := 0
	var first := true
	for room: Dictionary in dungeon.get("rooms", []):
		var map_position := _room_map_position(room)
		var x := int(map_position.x)
		var y := int(map_position.y)
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


func _should_swap_graph_axes() -> bool:
	if _generated_dungeon_scroll_tier() < 2:
		return false
	var raw_bounds := _raw_room_bounds()
	var span_x := int(raw_bounds["max_x"] - raw_bounds["min_x"])
	var span_y := int(raw_bounds["max_y"] - raw_bounds["min_y"])
	return span_y > span_x


func _raw_room_bounds() -> Dictionary:
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


func _generated_dungeon_scroll_tier() -> int:
	if not dungeon.has("generated_profile"):
		return 0
	var profile: Dictionary = dungeon.get("generated_profile", {})
	return clampi(int(profile.get("difficulty", dungeon.get("recommended_party_level", 1))), 1, 3)


func _build_corridors() -> void:
	# Native chart ink is derived from actual corridors, below the room plates.
	if expedition_chrome != null:
		expedition_chrome.build_passages(self)
		return
	var rooms_by_id: Dictionary = _rooms_by_id()
	for corridor: Dictionary in dungeon.get("corridors", []):
		var from_room: Dictionary = rooms_by_id.get(corridor.get("from", ""), {})
		var to_room: Dictionary = rooms_by_id.get(corridor.get("to", ""), {})
		if from_room.is_empty() or to_room.is_empty():
			continue
		var from_pos: Vector2 = _room_screen_position(from_room) + room_node_size * 0.5
		var to_pos: Vector2 = _room_screen_position(to_room) + room_node_size * 0.5
		graph_layer.add_child(_create_corridor_ornament_line(from_pos, to_pos, Color(0.12, 0.08, 0.035, 0.82), 12.0 * graph_node_scale))
		graph_layer.add_child(_create_corridor_ornament_line(from_pos, to_pos, _corridor_color(corridor), 5.0 * graph_node_scale))
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


func _create_corridor_ornament_line(from_pos: Vector2, to_pos: Vector2, color: Color, width: float) -> Node2D:
	var delta := to_pos - from_pos
	var group := Node2D.new()
	var normal := delta.normalized()
	var diamond_radius := 22.0 * graph_node_scale
	var center := from_pos.lerp(to_pos, 0.5)
	var first_end := center - normal * diamond_radius
	var second_start := center + normal * diamond_radius
	group.add_child(_create_corridor_line(from_pos, first_end, color, width))
	group.add_child(_create_corridor_line(second_start, to_pos, color, width))
	if width <= 6.0 * graph_node_scale:
		var diamond_texture := _dungeon_ui_texture(DUNGEON_UI_CORRIDOR_DIAMOND_PATH)
		if diamond_texture != null:
			var diamond := Sprite2D.new()
			diamond.texture = diamond_texture
			var diamond_size := Vector2(34, 34) * graph_node_scale
			diamond.position = center
			diamond.scale = Vector2(
				diamond_size.x / float(diamond_texture.get_width()),
				diamond_size.y / float(diamond_texture.get_height())
			)
			diamond.modulate = Color(0.96, 0.84, 0.42)
			group.add_child(diamond)
	return group


func _create_corridor_marker(text: String, center: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	var marker_size := Vector2(140, 52) * graph_node_scale
	panel.position = center - marker_size * 0.5
	panel.custom_minimum_size = marker_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _fantasy_panel_style(Color(0.09, 0.065, 0.038), Color(0.72, 0.46, 0.18), 1, 5))

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", max(24, int(24.0 * graph_node_scale)))
	label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.44))
	panel.add_child(label)
	return panel


func _create_room_panel(room: Dictionary) -> PanelContainer:
	if expedition_chrome!=null: return expedition_chrome.room_panel(self,room)
	var room_id: String = str(room["id"])
	var panel := PanelContainer.new()
	panel.position = _room_screen_position(room)
	panel.custom_minimum_size = room_node_size
	panel.size = room_node_size
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", _room_style(room_id, str(room.get("kind", ""))))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", max(13, int(20.0 * graph_node_scale)))
	margin.add_theme_constant_override("margin_top", max(34, int(44.0 * graph_node_scale)))
	margin.add_theme_constant_override("margin_right", max(13, int(20.0 * graph_node_scale)))
	margin.add_theme_constant_override("margin_bottom", max(10, int(14.0 * graph_node_scale)))
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", max(5, int(8.0 * graph_node_scale)))
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var icon := TextureRect.new()
	icon.texture = _dungeon_ui_texture(_room_icon_path(room))
	icon.custom_minimum_size = Vector2(66, 66) * graph_node_scale
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)

	var name_label := Label.new()
	name_label.text = _short_room_map_label(room)
	name_label.add_theme_font_size_override("font_size", max(13, int(17.0 * graph_node_scale)))
	name_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)

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
	action_row = GridContainer.new()
	action_row.columns = 2
	action_row.add_theme_constant_override("h_separation", 8)
	action_row.add_theme_constant_override("v_separation", 8)
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.add_child(action_row)

	start_combat_button = Button.new()
	start_combat_button.text = ENTER_COMBAT_LABEL
	start_combat_button.custom_minimum_size = Vector2(0, 44)
	start_combat_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_combat_button.add_theme_font_size_override("font_size", 15)
	start_combat_button.add_theme_stylebox_override("normal", _button_style(Color(0.58, 0.18, 0.12), Color(0.95, 0.62, 0.36)))
	start_combat_button.add_theme_stylebox_override("hover", _button_style(Color(0.7, 0.22, 0.14), Color(1.0, 0.76, 0.44)))
	start_combat_button.add_theme_stylebox_override("pressed", _button_style(Color(0.42, 0.12, 0.1), Color(0.86, 0.44, 0.28)))
	start_combat_button.pressed.connect(func() -> void:
		_start_pending_combat()
	)
	action_row.add_child(start_combat_button)

	reward_button = Button.new()
	reward_button.text = "Claim Reward"
	reward_button.custom_minimum_size = Vector2(0, 42)
	reward_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_button.add_theme_font_size_override("font_size", 14)
	reward_button.add_theme_stylebox_override("normal", _button_style(Color(0.22, 0.25, 0.10), Color(0.88, 0.72, 0.30)))
	reward_button.add_theme_stylebox_override("hover", _button_style(Color(0.30, 0.32, 0.12), Color(1.0, 0.84, 0.38)))
	reward_button.add_theme_stylebox_override("pressed", _button_style(Color(0.16, 0.18, 0.08), Color(0.74, 0.54, 0.20)))
	reward_button.pressed.connect(func() -> void:
		_claim_current_reward()
	)
	action_row.add_child(reward_button)

	finish_button = Button.new()
	finish_button.text = FINISH_EXPEDITION_LABEL
	finish_button.custom_minimum_size = Vector2(0, 42)
	finish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_button.add_theme_font_size_override("font_size", 14)
	finish_button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.25, 0.20), Color(0.54, 0.86, 0.62)))
	finish_button.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.34, 0.26), Color(0.68, 1.0, 0.78)))
	finish_button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.18, 0.15), Color(0.42, 0.70, 0.52)))
	finish_button.pressed.connect(func() -> void:
		_finish_expedition()
	)
	action_row.add_child(finish_button)

	oil_button = Button.new()
	oil_button.text = "Use Oil"
	oil_button.custom_minimum_size = Vector2(0, 42)
	oil_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	oil_button.add_theme_font_size_override("font_size", 14)
	oil_button.add_theme_stylebox_override("normal", _button_style(Color(0.18, 0.18, 0.08), Color(0.86, 0.68, 0.24)))
	oil_button.add_theme_stylebox_override("hover", _button_style(Color(0.26, 0.24, 0.10), Color(1.0, 0.82, 0.34)))
	oil_button.add_theme_stylebox_override("pressed", _button_style(Color(0.12, 0.12, 0.06), Color(0.70, 0.52, 0.18)))
	oil_button.pressed.connect(func() -> void:
		_use_lamp_oil()
	)
	action_row.add_child(oil_button)

	recovery_button = Button.new()
	recovery_button.text = "Use Recovery"
	recovery_button.custom_minimum_size = Vector2(0, 42)
	recovery_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recovery_button.add_theme_font_size_override("font_size", 14)
	recovery_button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.20, 0.20), Color(0.46, 0.76, 0.70)))
	recovery_button.add_theme_stylebox_override("hover", _button_style(Color(0.16, 0.28, 0.28), Color(0.62, 0.96, 0.86)))
	recovery_button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.14, 0.14), Color(0.36, 0.62, 0.58)))
	recovery_button.pressed.connect(func() -> void:
		_use_recovery_supply()
	)
	action_row.add_child(recovery_button)

	camp_button = Button.new()
	camp_button.text = "Camp"
	camp_button.custom_minimum_size = Vector2(0, 42)
	camp_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	camp_button.add_theme_font_size_override("font_size", 14)
	camp_button.add_theme_stylebox_override("normal", _button_style(Color(0.16, 0.14, 0.10), Color(0.70, 0.54, 0.30)))
	camp_button.add_theme_stylebox_override("hover", _button_style(Color(0.24, 0.20, 0.13), Color(0.94, 0.72, 0.40)))
	camp_button.add_theme_stylebox_override("pressed", _button_style(Color(0.11, 0.10, 0.08), Color(0.56, 0.42, 0.24)))
	camp_button.pressed.connect(func() -> void:
		_use_camp()
	)
	action_row.add_child(camp_button)

	reset_button = Button.new()
	reset_button.text = "Reset Run"
	reset_button.custom_minimum_size = Vector2(0, 42)
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.add_theme_font_size_override("font_size", 14)
	reset_button.add_theme_stylebox_override("normal", _button_style(Color(0.16, 0.12, 0.12), Color(0.62, 0.34, 0.28)))
	reset_button.add_theme_stylebox_override("hover", _button_style(Color(0.24, 0.16, 0.14), Color(0.82, 0.46, 0.34)))
	reset_button.add_theme_stylebox_override("pressed", _button_style(Color(0.10, 0.08, 0.08), Color(0.48, 0.26, 0.22)))
	reset_button.pressed.connect(func() -> void:
		_reset_expedition()
	)
	action_row.add_child(reset_button)
	retreat_button = Button.new()
	retreat_button.text = "Retreat to Ravenford"
	retreat_button.custom_minimum_size = Vector2(0, 42)
	retreat_button.add_theme_font_size_override("font_size", 14)
	retreat_button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.16, 0.16), Color(0.50, 0.65, 0.60)))
	retreat_button.add_theme_stylebox_override("hover", _button_style(Color(0.16, 0.24, 0.22), Color(0.78, 0.86, 0.60)))
	retreat_button.pressed.connect(_retreat_to_world)
	action_row.add_child(retreat_button)

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

	_create_map_scroll_container()
	map_title_label = null
	route_state_label = null


func _create_map_scroll_container() -> void:
	map_scroll_container = ScrollContainer.new()
	map_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	map_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	map_scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	map_scroll_container.clip_contents = true
	map_scroll_container.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	map_scroll_container.gui_input.connect(_handle_map_scroll_input)
	add_child(map_scroll_container)
	move_child(map_scroll_container, map_frame_panel.get_index() + 1)

	var previous_parent := graph_layer.get_parent()
	if previous_parent != null:
		previous_parent.remove_child(graph_layer)
	map_scroll_container.add_child(graph_layer)
	graph_layer.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	graph_layer.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	graph_layer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	graph_layer.mouse_filter = Control.MOUSE_FILTER_PASS


func _handle_map_scroll_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN or mouse_event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
		_scroll_map_horizontal(180)
		get_viewport().set_input_as_handled()
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
		_scroll_map_horizontal(-180)
		get_viewport().set_input_as_handled()


func _scroll_map_horizontal(delta: int) -> void:
	if map_scroll_container == null:
		return
	var max_scroll := maxi(0, int(graph_content_size.x - map_scroll_container.size.x))
	map_scroll_container.scroll_horizontal = clampi(map_scroll_container.scroll_horizontal + delta, 0, max_scroll)


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

	resource_tiles.clear()
	resource_tile_labels.clear()
	for tile_id: String in _resource_tile_ids():
		var tile := _create_resource_tile(tile_id)
		var label: Label = tile.get_meta("value_label") as Label
		resource_tiles[tile_id] = tile
		resource_tile_labels[tile_id] = label
		row.add_child(tile)


func _create_resource_tile_label() -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(34, 38)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.62))
	return label


func _create_resource_tile(tile_id: String) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(92, 46)
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.tooltip_text = _resource_tooltip_text(tile_id)
	tile.add_theme_stylebox_override("panel", _dungeon_ui_stylebox(
		_resource_tile_frame_path(tile_id),
		Vector4(34, 18, 34, 18),
		Vector4(16, 7, 16, 7),
		_fantasy_panel_style(Color(0.075, 0.067, 0.052), Color(0.42, 0.30, 0.14), 1, 4)
	))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 5)
	tile.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	margin.add_child(row)

	var icon := TextureRect.new()
	icon.texture = _dungeon_ui_texture(_resource_icon_path(tile_id))
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var label := _create_resource_tile_label()
	row.add_child(label)
	tile.set_meta("value_label", label)
	return tile

func _create_party_status_panel() -> void:
	party_panel = PanelContainer.new()
	party_panel.position = party_area.position
	party_panel.custom_minimum_size = party_area.size
	party_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	party_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(party_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	party_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var party_members := _party_members_for_ui()
	for index in range(party_members.size()):
		row.add_child(_create_party_portrait_slot(party_members[index], index))

	party_log_label = Label.new()
	party_log_label.custom_minimum_size = Vector2(300, 0)
	party_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	party_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	party_log_label.add_theme_font_size_override("font_size", 16)
	party_log_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.64))
	row.add_child(party_log_label)


func _create_party_portrait_slot(hero: Dictionary, slot_index: int) -> PanelContainer:
	var slot := PartyCardScene.instantiate()
	var frame := _dungeon_ui_stylebox(
		DUNGEON_UI_PORTRAIT_FRAME_PATH,
		Vector4(38, 34, 38, 34),
		Vector4(16, 14, 16, 14),
		_fantasy_panel_style(Color(0.060, 0.052, 0.045), Color(0.46, 0.34, 0.18), 1, 4)
	)
	var unit_id := str(hero.get("combat_unit_id", ""))
	slot.configure(hero, DungeonStateModel.party_member_hp(run_state, unit_id), _party_slot_bar_color(slot_index), frame)
	party_cards[unit_id] = slot
	party_hp_labels[unit_id] = slot.hp_label
	party_hp_bars[unit_id] = slot.hp_bar
	return slot


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
	corridor_event_panel = Control.new()
	corridor_event_panel.visible = false
	corridor_event_panel.custom_minimum_size = EVENT_POPUP_MIN_SIZE
	corridor_event_panel.clip_contents = true
	corridor_event_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	corridor_event_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(corridor_event_panel)
	_center_corridor_event_panel()

	var background := NinePatchRect.new()
	background.texture = _dungeon_ui_texture(DUNGEON_UI_MODAL_PATH)
	background.patch_margin_left = 54
	background.patch_margin_top = 42
	background.patch_margin_right = 54
	background.patch_margin_bottom = 42
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	corridor_event_panel.add_child(background)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 46
	margin.offset_top = 38
	margin.offset_right = -46
	margin.offset_bottom = -34
	corridor_event_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	corridor_event_title_label = Label.new()
	corridor_event_title_label.text = "Corridor Event"
	corridor_event_title_label.add_theme_font_size_override("font_size", 22)
	corridor_event_title_label.add_theme_color_override("font_color", Color(0.96, 0.80, 0.42))
	box.add_child(corridor_event_title_label)

	corridor_event_type_label = Label.new()
	corridor_event_type_label.add_theme_font_size_override("font_size", 15)
	corridor_event_type_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.74))
	box.add_child(corridor_event_type_label)

	corridor_event_message_label = Label.new()
	corridor_event_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corridor_event_message_label.add_theme_font_size_override("font_size", 15)
	box.add_child(corridor_event_message_label)

	corridor_event_supply_label = Label.new()
	corridor_event_supply_label.add_theme_font_size_override("font_size", 14)
	corridor_event_supply_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.68))
	box.add_child(corridor_event_supply_label)

	corridor_event_result_label = Label.new()
	corridor_event_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corridor_event_result_label.add_theme_font_size_override("font_size", 14)
	corridor_event_result_label.add_theme_color_override("font_color", Color(0.94, 0.66, 0.48))
	box.add_child(corridor_event_result_label)

	corridor_event_choice_row = HBoxContainer.new()
	corridor_event_choice_row.add_theme_constant_override("separation", 10)
	box.add_child(corridor_event_choice_row)


func _center_corridor_event_panel() -> void:
	if expedition_chrome!=null:
		expedition_chrome.center_event(self)
		return
	if corridor_event_panel == null:
		return
	var panel_rect := _default_event_popup_rect()
	if layout_overrides.has("event_popup"):
		panel_rect = _clamp_event_popup_rect(_rect_from_dict(layout_overrides["event_popup"], panel_rect))
	_apply_event_popup_rect(panel_rect)


func _show_event_popup_panel() -> void:
	if corridor_event_panel == null:
		return
	_center_corridor_event_panel()
	corridor_event_panel.show()
	call_deferred("_force_event_popup_rect")


func _force_event_popup_rect() -> void:
	if corridor_event_panel == null or not corridor_event_panel.visible:
		return
	_center_corridor_event_panel()


func _default_event_popup_rect() -> Rect2:
	var viewport_size := FALLBACK_VIEWPORT_SIZE
	if is_inside_tree():
		viewport_size = get_viewport_rect().size
	return Rect2((viewport_size - EVENT_POPUP_DEFAULT_SIZE) * 0.5, EVENT_POPUP_DEFAULT_SIZE)


func _handle_layout_edit_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return false
		if key_event.keycode == KEY_F9:
			_set_layout_edit_enabled(not layout_edit_enabled)
			get_viewport().set_input_as_handled()
			return true
		if layout_edit_enabled and key_event.keycode == KEY_S and key_event.ctrl_pressed:
			_save_layout_overrides()
			get_viewport().set_input_as_handled()
			return true
	if not layout_edit_enabled:
		return false
	if event is InputEventMouseButton:
		return _handle_layout_edit_mouse_button(event as InputEventMouseButton)
	if event is InputEventMouseMotion:
		return _handle_layout_edit_mouse_motion(event as InputEventMouseMotion)
	return false


func _handle_layout_edit_mouse_button(event: InputEventMouseButton) -> bool:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return false
	if not event.pressed:
		layout_edit_target_id = ""
		layout_edit_operation = ""
		get_viewport().set_input_as_handled()
		return true
	var target := _layout_edit_target_at(event.position)
	if target.is_empty():
		return false
	layout_edit_target_id = str(target.get("id", ""))
	layout_edit_start_rect = target.get("rect", Rect2())
	layout_edit_start_mouse = event.position
	layout_edit_drag_offset = event.position - layout_edit_start_rect.position
	layout_edit_operation = "resize" if _layout_resize_handle_rect(layout_edit_start_rect).has_point(event.position) else "move"
	get_viewport().set_input_as_handled()
	return true


func _handle_layout_edit_mouse_motion(event: InputEventMouseMotion) -> bool:
	if layout_edit_target_id == "":
		return false
	var next_rect := layout_edit_start_rect
	if layout_edit_operation == "resize":
		var delta := event.position - layout_edit_start_mouse
		next_rect.size = Vector2(
			maxf(120.0, layout_edit_start_rect.size.x + delta.x),
			maxf(80.0, layout_edit_start_rect.size.y + delta.y)
		)
	else:
		next_rect.position = event.position - layout_edit_drag_offset
	if layout_edit_target_id == "event_popup":
		next_rect = _clamp_event_popup_rect(next_rect)
	_set_layout_rect(layout_edit_target_id, next_rect)
	get_viewport().set_input_as_handled()
	return true


func _set_layout_edit_enabled(enabled: bool) -> void:
	layout_edit_enabled = enabled
	layout_edit_target_id = ""
	layout_edit_operation = ""
	if enabled:
		last_feedback = "Layout edit enabled. Drag panels, resize from bottom-right, Ctrl+S saves."
		if corridor_event_panel != null and not corridor_event_panel.visible:
			layout_edit_preview_popup = true
			corridor_event_title_label.text = "Layout Preview"
			corridor_event_type_label.text = "F9 toggles edit mode"
			corridor_event_message_label.text = "Drag this popup or resize it from the bottom-right corner."
			corridor_event_supply_label.text = "Ctrl+S saves to %s" % DUNGEON_LAYOUT_OVERRIDE_PATH
			corridor_event_result_label.text = ""
			_show_event_popup_panel()
	else:
		last_feedback = "Layout edit disabled."
		if layout_edit_preview_popup and corridor_event_panel != null:
			corridor_event_panel.hide()
		layout_edit_preview_popup = false
	_update_detail()


func _layout_edit_target_at(point: Vector2) -> Dictionary:
	for item: Dictionary in _layout_edit_items():
		var rect: Rect2 = item.get("rect", Rect2())
		if rect.has_point(point):
			return item
	return {}


func _layout_edit_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if corridor_event_panel != null and corridor_event_panel.visible:
		items.append({"id": "event_popup", "rect": Rect2(corridor_event_panel.position, corridor_event_panel.size)})
	items.append({"id": "detail", "rect": detail_area})
	if expedition_chrome==null: items.append({"id": "loadout", "rect": loadout_area})
	items.append({"id": "party", "rect": party_area})
	items.append({"id": "resources", "rect": resource_tray_area})
	items.append({"id": "map", "rect": map_area})
	return items


func _layout_resize_handle_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position + rect.size - Vector2(LAYOUT_EDIT_HANDLE_SIZE, LAYOUT_EDIT_HANDLE_SIZE), Vector2(LAYOUT_EDIT_HANDLE_SIZE, LAYOUT_EDIT_HANDLE_SIZE))


func _set_layout_rect(id: String, rect: Rect2) -> void:
	if id == "event_popup":
		rect = _clamp_event_popup_rect(rect)
	layout_overrides[id] = _rect_to_dict(rect)
	match id:
		"map":
			map_area = rect
			_recalculate_graph_transform()
			_apply_positioned_chrome()
			_build_graph()
		"resources":
			resource_tray_area = rect
			_apply_positioned_chrome()
		"party":
			party_area = rect
			_apply_positioned_chrome()
		"detail":
			detail_area = rect
			_apply_detail_panel_layout()
		"loadout":
			loadout_area = rect
			_apply_positioned_chrome()
		"event_popup":
			if corridor_event_panel != null:
				_apply_event_popup_rect(rect)


func _apply_control_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
	control.custom_minimum_size = rect.size


func _apply_event_popup_rect(rect: Rect2) -> void:
	if corridor_event_panel == null:
		return
	rect = _clamp_event_popup_rect(rect)
	corridor_event_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	corridor_event_panel.custom_minimum_size = EVENT_POPUP_MIN_SIZE
	corridor_event_panel.position = rect.position
	corridor_event_panel.size = rect.size


func _clamp_event_popup_rect(rect: Rect2) -> Rect2:
	var viewport_size := FALLBACK_VIEWPORT_SIZE
	if is_inside_tree():
		viewport_size = get_viewport_rect().size
	var max_size := Vector2(
		minf(EVENT_POPUP_MAX_SIZE.x, maxf(EVENT_POPUP_MIN_SIZE.x, viewport_size.x - 64.0)),
		minf(EVENT_POPUP_MAX_SIZE.y, maxf(EVENT_POPUP_MIN_SIZE.y, viewport_size.y - 64.0))
	)
	var clamped_size := Vector2(
		clampf(rect.size.x, EVENT_POPUP_MIN_SIZE.x, max_size.x),
		clampf(rect.size.y, EVENT_POPUP_MIN_SIZE.y, max_size.y)
	)
	var max_position := Vector2(
		maxf(24.0, viewport_size.x - clamped_size.x - 24.0),
		maxf(24.0, viewport_size.y - clamped_size.y - 24.0)
	)
	var clamped_position := Vector2(
		clampf(rect.position.x, 24.0, max_position.x),
		clampf(rect.position.y, 24.0, max_position.y)
	)
	return Rect2(clamped_position, clamped_size)


func _load_layout_overrides() -> void:
	if not is_inside_tree():
		layout_overrides = {}
		return
	if not FileAccess.file_exists(DUNGEON_LAYOUT_OVERRIDE_PATH):
		layout_overrides = {}
		return
	var file := FileAccess.open(DUNGEON_LAYOUT_OVERRIDE_PATH, FileAccess.READ)
	if file == null:
		layout_overrides = {}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	layout_overrides = parsed if parsed is Dictionary else {}


func _save_layout_overrides() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DUNGEON_LAYOUT_OVERRIDE_PATH.get_base_dir()))
	layout_overrides["map"] = _rect_to_dict(map_area)
	layout_overrides["resources"] = _rect_to_dict(resource_tray_area)
	layout_overrides["party"] = _rect_to_dict(party_area)
	layout_overrides["detail"] = _rect_to_dict(detail_area)
	layout_overrides["loadout"] = _rect_to_dict(loadout_area)
	if corridor_event_panel != null:
		layout_overrides["event_popup"] = _rect_to_dict(_clamp_event_popup_rect(Rect2(corridor_event_panel.position, corridor_event_panel.size)))
	var file := FileAccess.open(DUNGEON_LAYOUT_OVERRIDE_PATH, FileAccess.WRITE)
	if file == null:
		last_feedback = "Could not save layout overrides."
		_update_detail()
		return
	file.store_string(JSON.stringify(layout_overrides, "\t"))
	last_feedback = "Layout saved to %s." % DUNGEON_LAYOUT_OVERRIDE_PATH
	_update_detail()


func _rect_to_dict(rect: Rect2) -> Dictionary:
	return {
		"x": snappedf(rect.position.x, 0.1),
		"y": snappedf(rect.position.y, 0.1),
		"w": snappedf(rect.size.x, 0.1),
		"h": snappedf(rect.size.y, 0.1),
	}


func _rect_from_dict(value: Variant, fallback: Rect2) -> Rect2:
	if not value is Dictionary:
		return fallback
	var data := value as Dictionary
	return Rect2(
		Vector2(float(data.get("x", fallback.position.x)), float(data.get("y", fallback.position.y))),
		Vector2(float(data.get("w", fallback.size.x)), float(data.get("h", fallback.size.y)))
	)


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
	elif result["status"] == "choice_required":
		run_state = result["state"]
		_run_session().set_dungeon_run(dungeon, run_state)
		last_feedback = "Corridor event between %s and %s." % [
			_room_display_name(str(result["event"].get("from_room_id", ""))),
			_room_display_name(str(result["event"].get("to_room_id", ""))),
		]
	else:
		last_feedback = "Cannot enter %s: %s." % [_room_display_name(room_id), result["rejection"]]
	_refresh_pending_event_popup()
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
	var supply_id := _preferred_recovery_supply_id()
	var result: Dictionary = DungeonStateModel.use_bandage(run_state, supply_id) if supply_id == "bandage" else DungeonStateModel.use_recovery_supply(run_state, supply_id)
	if result["status"] == "accepted":
		run_state = result["state"]
		if is_inside_tree():
			_run_session().set_dungeon_run(dungeon, run_state)
		last_feedback = str(result["event"].get("message", "Recovery used."))
	else:
		last_feedback = "Cannot use %s: %s." % [_supply_display_name(supply_id), result["rejection"]]
	_refresh_room_styles()
	_update_detail()


func _use_camp() -> void:
	var result: Dictionary = DungeonStateModel.use_camp(run_state, "camping_kit")
	if result["status"] == "accepted":
		run_state = result["state"]
		if is_inside_tree():
			_run_session().set_dungeon_run(dungeon, run_state)
		last_feedback = str(result["event"].get("message", "Camp used."))
	else:
		last_feedback = "Cannot camp: %s." % result["rejection"]
	_refresh_room_styles()
	_update_detail()


func _reset_expedition() -> void:
	if _run_session().managed_run:
		return
	_run_session().clear()
	dungeon = _dungeon_data_for_entry_payload()
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
		if is_inside_tree():
			_run_session().set_dungeon_run(dungeon, run_state)
		selected_room_id = str(run_state["current_room_id"])
		last_feedback = _movement_feedback(result, selected_room_id)
	elif result["rejection"] == "hazard_blocked":
		run_state = result["state"]
		if is_inside_tree():
			_run_session().set_dungeon_run(dungeon, run_state)
		selected_room_id = str(run_state["current_room_id"])
		last_feedback = str(result.get("event", {}).get("message", "The passage remains blocked."))
	else:
		last_feedback = "Cannot resolve corridor event: %s." % result["rejection"]
	_refresh_pending_event_popup()
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
	_refresh_pending_event_popup()
	_refresh_room_styles()
	_update_detail()


func _finish_expedition() -> void:
	if _run_session().finish_run(dungeon, run_state, "completed"):
		run_state = _run_session().dungeon_state.duplicate(true)
		last_feedback = _run_session().last_feedback
	else:
		last_feedback = _run_session().last_feedback
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


func _retreat_to_world() -> void:
	if not _run_session().managed_run:
		return
	if _run_session().finish_run(dungeon, run_state, "retreated"):
		run_state = _run_session().dungeon_state.duplicate(true)
		_open_world()
	else:
		last_feedback = _run_session().last_feedback
		_update_detail()


func _open_world() -> void:
	if _expedition_decision_pending():
		return
	var session := _run_session()
	var return_path := "res://scenes/app/App.tscn"
	var owner: Node = session.campaign_owner()
	if owner.has_method("world_return_scene"): return_path=owner.world_return_scene()
	if session.managed_run:
		if bool(run_state.get("completed", false)):
			var campaign: Node = _run_session().campaign_owner()
			if campaign.has_method("regional_active") and not session.checkpoint_campaign():
				last_feedback=session.last_feedback;_update_detail();return
			if not campaign.settle(session.pending_world_return_payload):
				last_feedback = campaign.last_feedback
				_update_detail()
				return
			session.clear()
		else:
			if not session.checkpoint_campaign():
				last_feedback = session.last_feedback
				_update_detail()
				return
	elif expedition_started and not bool(run_state.get("completed", false)):
		last_feedback = "Finish or reset this sandbox before opening the campaign."
		_update_detail()
		return
	else:
		session.clear()
	if scene_requested.has_connections(): scene_requested.emit(return_path)
	else: get_tree().change_scene_to_file(return_path)


func _refresh_room_styles() -> void:
	for room: Dictionary in dungeon.get("rooms", []):
		var panel: PanelContainer = room_nodes.get(room["id"])
		if panel != null:
			panel.add_theme_stylebox_override("panel", _room_style(str(room["id"]), str(room.get("kind", ""))))


func _update_detail() -> void:
	if is_inside_tree() and not expedition_started and _run_session().town_preparation:
		var campaign: Node = _run_session().campaign_owner()
		for key in ["party_effects", "target_effects", "active_debuffs"]:
			run_state[key] = campaign.state.effects.get(key, {}).duplicate(true)
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
		"Light: %s %s/%s | Torch: %s | Pickaxe: %s | Trap Tools: %s | Bandage: %s" % [
			str(run_state.get("light_state", "bright")),
			int(run_state.get("light_level", 0)),
			int(run_state.get("max_light_level", 0)),
			DungeonStateModel.supply_count(run_state, "lamp_oil"),
			DungeonStateModel.supply_count(run_state, "pickaxe"),
			DungeonStateModel.supply_count(run_state, "trap_tools"),
			DungeonStateModel.supply_count(run_state, "bandage"),
		],
		"Camping Kit: %s | Food: %s | %s" % [
			DungeonStateModel.supply_count(run_state, "camping_kit"),
			DungeonStateModel.supply_count(run_state, "food"),
			_loadout_packing_text(run_state.get("selected_supply_loadout", {})),
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
	var payload: Dictionary = run_state.get("run_result_payload", DungeonStateModel.run_result_payload(dungeon, run_state))
	var totals: Dictionary = payload.get("reward_totals", DungeonStateModel.reward_totals(run_state))
	var items: Array = totals.get("items", [])
	var item_text := "none" if items.is_empty() else ", ".join(items)
	return PackedStringArray([
		"Expedition result: %s." % str(payload.get("outcome", "completed")),
		"Completed at: %s" % _room_display_name(str(run_state.get("completed_at_room_id", ""))),
		"Rooms visited: %s/%s" % [run_state.get("visited_room_ids", []).size(), dungeon.get("rooms", []).size()],
		"Rooms secured: %s/%s" % [run_state.get("cleared_room_ids", []).size(), dungeon.get("rooms", []).size()],
		"Gold claimed: %s" % int(totals.get("gold", 0)),
		"XP claimed: %s" % int(totals.get("xp", 0)),
		"Items claimed: %s" % item_text,
		"Return hook: %s" % str(payload.get("next_scene_path", DungeonStateModel.DEFAULT_RETURN_SCENE_PATH)),
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
	var has_camp := not blocked_by_event and _can_use_camp()
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
	recovery_button.text = "Use %s" % _supply_display_name(_preferred_recovery_supply_id()) if has_recovery else "Use Recovery"
	camp_button.disabled = not has_camp
	camp_button.visible = has_camp
	reset_button.disabled = false
	reset_button.visible = true
	if is_inside_tree() and _run_session().managed_run:
		reset_button.visible = false
	if retreat_button != null:
		retreat_button.visible = is_inside_tree() and _run_session().managed_run and not bool(run_state.get("completed", false)) and bool(dungeon.get("exit_rules", {}).get("allow_retreat", false)) and not has_pending and not blocked_by_event


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
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_stylebox_override("normal", _button_style(Color(0.095, 0.105, 0.09), Color(0.40, 0.36, 0.22)))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.13, 0.15, 0.11), Color(0.78, 0.62, 0.30)))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.07, 0.08, 0.06), Color(0.64, 0.48, 0.24)))
		var target_room_id := str(option.get("id", ""))
		if expedition_chrome != null:
			var passage: Dictionary = expedition_chrome._corridor(self,target_room_id)
			button.text = "%s. Inspect %s\nLight -%s" % [option.get("slot",0),option.get("label",""),int(passage.get("light_decay",0))]
			button.tooltip_text = "Preview this passage before confirming travel."
		button.pressed.connect(func() -> void:
			if expedition_chrome != null:
				expedition_chrome.preview_room(self, target_room_id)
			else:
				_try_enter_room(target_room_id)
		)
		exit_row.add_child(button)
		if expedition_chrome!=null:
			expedition_chrome.style_button(button)
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.custom_minimum_size.y = 92


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


func _short_room_map_label(room: Dictionary) -> String:
	var room_id := str(room.get("id", ""))
	if room_id == str(run_state.get("current_room_id", "")):
		return "HERE"
	if DungeonStateModel.room_is_cleared(run_state, room_id):
		return "SECURE"
	if DungeonStateModel.room_is_visited(run_state, room_id):
		return "VISITED"
	var label := str(room.get("display_name", room.get("id", ""))).to_upper()
	if label.length() > 18:
		return "%s..." % label.substr(0, 15)
	return label


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
		button.pressed.connect(_resolve_pending_corridor_hazard.bind(action))
		corridor_event_choice_row.add_child(button)
		corridor_hazard_choice_buttons.append(button)
	_show_event_popup_panel()


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
	corridor_event_supply_label.text = _room_event_supply_summary(prompt)
	corridor_event_result_label.text = "Choose how the party handles this room event."
	for choice: Dictionary in prompt.get("choices", []):
		var action := str(choice.get("id", ""))
		var button := Button.new()
		button.text = str(choice.get("label", action))
		button.disabled = not bool(choice.get("available", false))
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.13, 0.10), Color(0.62, 0.48, 0.24)))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.18, 0.18, 0.12), Color(0.90, 0.68, 0.30)))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.09, 0.07), Color(0.72, 0.50, 0.20)))
		button.pressed.connect(_resolve_pending_room_event.bind(action))
		corridor_event_choice_row.add_child(button)
		corridor_hazard_choice_buttons.append(button)
	_show_event_popup_panel()


func _refresh_pending_event_popup() -> void:
	if corridor_event_panel == null:
		return
	var pending_hazard: Dictionary = run_state.get("pending_corridor_hazard", {})
	if not pending_hazard.is_empty():
		_show_corridor_hazard_popup(pending_hazard)
		return
	var pending_room_event: Dictionary = run_state.get("pending_room_event", {})
	if not pending_room_event.is_empty():
		_show_room_event_popup(pending_room_event)
		return
	corridor_event_panel.hide()


func _room_event_popup_text(prompt: Dictionary) -> String:
	return "%s\n\nThis happens inside %s." % [
		str(prompt.get("message", "")),
		_room_display_name(str(prompt.get("room_id", ""))),
	]


func _room_event_supply_summary(prompt: Dictionary) -> String:
	var requirements: Array[String] = []
	for choice: Dictionary in prompt.get("choices", []):
		var supply_id := str(choice.get("requires_supply", ""))
		if supply_id == "":
			continue
		var state_text := "available" if bool(choice.get("available", false)) else "missing"
		requirements.append("%s %s" % [_supply_display_name(supply_id), state_text])
	if requirements.is_empty():
		return "Room discovery"
	return "Requires: %s" % ", ".join(requirements)


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
	var history := DungeonStateModel.room_event_history(run_state)
	var resolved_count := int(history.get("resolved_count", log.size()))
	var consequence_text := _consequence_summary(event.get("consequences", []))
	if consequence_text == "":
		return "Last room event: %s. Events resolved: %s." % [outcome, resolved_count]
	return "Last room event: %s (%s). Events resolved: %s." % [outcome, consequence_text, resolved_count]


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


func _rooms_by_id() -> Dictionary:
	var indexed: Dictionary = {}
	for room: Dictionary in dungeon.get("rooms", []):
		indexed[room["id"]] = room
	return indexed


func _room_screen_position(room: Dictionary) -> Vector2:
	if expedition_chrome != null and expedition_chrome.use_mine_chart(self):
		return expedition_chrome.chart_room_position(self,str(room.get("id","")))
	return graph_origin + _room_map_position(room) * graph_step


func _room_map_position(room: Dictionary) -> Vector2:
	var position: Dictionary = room.get("position", {})
	var raw_position := Vector2(float(position.get("x", 0)), float(position.get("y", 0)))
	if graph_axis_swap:
		return Vector2(raw_position.y, raw_position.x)
	return raw_position


func _display_room_position_span(axis: String) -> float:
	var first := true
	var minimum := 0.0
	var maximum := 0.0
	for room: Dictionary in dungeon.get("rooms", []):
		var map_position := _room_map_position(room)
		var value := map_position.x if axis == "x" else map_position.y
		if first:
			minimum = value
			maximum = value
			first = false
		else:
			minimum = minf(minimum, value)
			maximum = maxf(maximum, value)
	return maximum - minimum


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


func _map_legend_lines() -> PackedStringArray:
	return PackedStringArray([
		"[*] entrance",
		"[ ] empty",
		"[$] treasure",
		"[!] combat",
		"[>] exit",
	])


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
	if dungeon.get("rooms", []).is_empty():
		last_feedback = "Cannot start: no accepted dungeon layout is available."
		if status_label != null:
			status_label.text = last_feedback
		return
	selected_supply_loadout = DungeonStateModel.clamp_supply_loadout(dungeon, selected_supply_loadout)
	run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
	if is_inside_tree() and _run_session().town_preparation:
		var campaign: Node = _run_session().campaign_owner()
		if not campaign.begin_run(dungeon, run_state):
			last_feedback = campaign.last_feedback
			status_label.text = last_feedback
			return
		run_state = campaign.state.active_run.state.duplicate(true)
		_run_session().managed_run = true
		_run_session().town_preparation = false
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
	selected_supply_loadout = DungeonStateModel.clamp_supply_loadout(dungeon, next_loadout, supply_id)
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
		loadout_summary_label.text = "Source: %s\nSelected: %s\n%s" % [
			_source_display_name(dungeon_source),
			_loadout_summary_text(selected_supply_loadout),
			_loadout_packing_text(selected_supply_loadout),
		]
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
			if is_inside_tree() and _run_session().town_preparation:
				value_label.tooltip_text = ("Owned by the company: %s" if _run_session().campaign_owner().has_method("regional_active") else "Owned in Ravenford: %s") % _run_session().campaign_owner().state.supplies.get(supply_id, 0)
		var option: Dictionary = options.get(supply_id, {"min": 0, "max": value})
		var minus_button: Button = row.get("minus_button", null)
		if minus_button != null:
			minus_button.disabled = value <= int(option.get("min", 0))
		var plus_button: Button = row.get("plus_button", null)
		if plus_button != null:
			var packing_summary := DungeonStateModel.loadout_packing_summary(dungeon, selected_supply_loadout)
			var capacity := int(packing_summary.get("capacity", 0))
			var remaining := int(packing_summary.get("remaining", 0))
			var cost := DungeonStateModel.supply_packing_cost(dungeon, supply_id)
			plus_button.disabled = value >= int(option.get("max", value)) or (capacity > 0 and remaining < cost)
	if expedition_chrome!=null: expedition_chrome.refresh(self)


func _loadout_pending() -> bool:
	return not expedition_started


func _toggle_dungeon_source() -> void:
	_set_dungeon_source(_other_dungeon_source())


func _clear_preparation_preview() -> void:
	if not is_inside_tree():
		return
	var session := _run_session()
	var from_campaign: bool = session.town_preparation
	session.clear()
	session.town_preparation = from_campaign


func _set_dungeon_source(next_source: String) -> void:
	if not _loadout_pending():
		return
	if next_source == DUNGEON_SOURCE_GENERATED:
		entry_payload = DungeonEntrySelection.generated_payload(_new_generated_seed(), generated_dungeon_difficulty, generated_profile_id)
	else:
		entry_payload = DungeonEntrySelection.authored_payload()
	_apply_entry_payload_fields()
	dungeon = _dungeon_data_for_entry_payload()
	_recalculate_graph_transform()
	selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	last_feedback = "Dungeon source changed to %s. Prepare a new loadout." % _source_display_name(dungeon_source)
	_clear_preparation_preview()
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
	var previous_seed := generated_dungeon_seed
	entry_payload = DungeonEntrySelection.generated_payload(
		(previous_seed % 999999) + 1 if previous_seed > 0 else _new_generated_seed(),
		generated_dungeon_difficulty,
		generated_profile_id
	)
	_apply_entry_payload_fields()
	dungeon = _dungeon_data_for_entry_payload()
	_recalculate_graph_transform()
	selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	last_feedback = "Generated draft rerolled with D%s seed %s." % [generated_dungeon_difficulty, generated_dungeon_seed]
	_clear_preparation_preview()
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
	generated_profile_id = str(DungeonStateModel.generated_dungeon_profile("", generated_dungeon_difficulty).get("id", generated_profile_id))
	if dungeon_source != DUNGEON_SOURCE_GENERATED:
		entry_payload = DungeonEntrySelection.normalize_payload({
			"source": dungeon_source,
			"generated_difficulty": generated_dungeon_difficulty,
		})
		_refresh_loadout_panel()
		return
	if generated_dungeon_seed == 0:
		generated_dungeon_seed = _new_generated_seed()
	entry_payload = DungeonEntrySelection.generated_payload(generated_dungeon_seed, generated_dungeon_difficulty, generated_profile_id)
	_apply_entry_payload_fields()
	dungeon = _dungeon_data_for_entry_payload()
	_recalculate_graph_transform()
	selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	run_state = DungeonStateModel.initial_state(dungeon, selected_supply_loadout)
	selected_room_id = str(run_state.get("current_room_id", dungeon.get("start_room_id", "")))
	last_feedback = "Generated difficulty set to D%s." % generated_dungeon_difficulty
	_clear_preparation_preview()
	if title_label != null:
		title_label.text = dungeon.get("display_name", "Dungeon")
	if corridor_event_panel != null:
		corridor_event_panel.hide()
	if graph_layer != null:
		_build_graph()
	_refresh_room_styles()
	_update_detail()
	_refresh_loadout_panel()


func _dungeon_data_for_entry_payload() -> Dictionary:
	entry_payload = DungeonEntrySelection.normalize_payload(entry_payload)
	return DungeonEntrySelection.dungeon_for_payload(entry_payload)


func _dungeon_data_for_source(source: String) -> Dictionary:
	if source == DUNGEON_SOURCE_GENERATED:
		if generated_dungeon_seed == 0:
			generated_dungeon_seed = _new_generated_seed()
		entry_payload = DungeonEntrySelection.generated_payload(generated_dungeon_seed, generated_dungeon_difficulty, generated_profile_id)
	else:
		entry_payload = DungeonEntrySelection.authored_payload()
	_apply_entry_payload_fields()
	return _dungeon_data_for_entry_payload()


func _apply_entry_payload_fields() -> void:
	entry_payload = DungeonEntrySelection.normalize_payload(entry_payload)
	dungeon_source = str(entry_payload.get("source", DUNGEON_SOURCE_AUTHORED))
	generated_dungeon_seed = int(entry_payload.get("generated_seed", 0))
	generated_dungeon_difficulty = int(entry_payload.get("generated_difficulty", DEFAULT_GENERATED_DUNGEON_DIFFICULTY))
	generated_profile_id = str(entry_payload.get("generated_profile", DungeonEntrySelection.DEFAULT_GENERATED_PROFILE_ID))


func _source_for_dungeon(next_dungeon: Dictionary) -> String:
	return DungeonEntrySelection.source_for_dungeon(next_dungeon)


func _other_dungeon_source() -> String:
	return DUNGEON_SOURCE_AUTHORED if dungeon_source == DUNGEON_SOURCE_GENERATED else DUNGEON_SOURCE_GENERATED


func _source_display_name(source: String) -> String:
	if source == DUNGEON_SOURCE_GENERATED:
		return DungeonEntrySelection.display_name(DungeonEntrySelection.generated_payload(maxi(1, generated_dungeon_seed), generated_dungeon_difficulty, generated_profile_id)) if generated_dungeon_seed > 0 else "Generated Draft"
	return DungeonEntrySelection.display_name(DungeonEntrySelection.authored_payload())


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
		var profile: Dictionary = dungeon.get("generated_profile", {})
		return "Generated: %s | D%s | Seed %s | Rooms %s | Corridors %s | Hazards %s" % [
			str(profile.get("display_name", "Profile")),
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


func _loadout_packing_text(loadout: Dictionary) -> String:
	var summary := DungeonStateModel.loadout_packing_summary(dungeon, loadout)
	if int(summary.get("capacity", 0)) <= 0:
		return "Packing: unlimited"
	return "Packing: %s/%s points, %s left" % [
		int(summary.get("used", 0)),
		int(summary.get("capacity", 0)),
		int(summary.get("remaining", 0)),
	]


func _supply_display_name(supply_id: String) -> String:
	var option: Dictionary = dungeon.get("supply_loadout_options", {}).get(supply_id, {})
	if str(option.get("label", "")) != "":
		return str(option.get("label", ""))
	match supply_id:
		"lamp_oil":
			return "Torch"
		"pickaxe":
			return "Pickaxe"
		"bandage":
			return "Bandage"
		"trap_tools":
			return "Trap Tools"
		"camping_kit":
			return "Camping Kit"
		"food":
			return "Food"
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
		var payload: Dictionary = run_state.get("run_result_payload", {})
		return "Expedition %s. Return payload is ready for %s." % [
			str(payload.get("outcome", "completed")),
			str(payload.get("next_scene_path", DungeonStateModel.DEFAULT_RETURN_SCENE_PATH)),
		]
	var exits := _connected_room_labels(current_room_id)
	if DungeonStateModel.room_is_cleared(run_state, current_room_id):
		return "%s is secure. Choose an exit to continue." % _room_display_name(current_room_id)
	if exits.is_empty():
		return "%s has no visible exits." % _room_display_name(current_room_id)
	return "Choose a connected room to continue exploring."


func _refresh_presentation_chrome() -> void:
	if expedition_chrome!=null: expedition_chrome.refresh(self)
	if route_state_label != null:
		route_state_label.text = _route_state_text()
	if party_log_label != null:
		party_log_label.text = _party_log_text()
		if expedition_chrome != null and expedition_chrome.has_method("company_feedback"):
			party_log_label.text = expedition_chrome.company_feedback(party_log_label.text)
	for hero: Dictionary in _party_members_for_ui():
		var unit_id := str(hero.get("combat_unit_id", ""))
		if party_hp_labels.has(unit_id):
			party_cards[unit_id].set_hp(DungeonStateModel.party_member_hp(run_state, unit_id))
	if resource_tile_labels.is_empty():
		return
	var tile_texts := _resource_tile_texts()
	for tile_id: String in tile_texts.keys():
		var label: Label = resource_tile_labels.get(tile_id, null)
		if label != null:
			label.text = str(tile_texts.get(tile_id, ""))
		var tile: Control = resource_tiles.get(tile_id, null)
		if tile != null:
			tile.tooltip_text = _resource_tooltip_text(tile_id)


func _resource_tile_texts() -> Dictionary:
	return {
		"torch": str(_resource_tile_count("torch")),
		"pickaxe": str(_resource_tile_count("pickaxe")),
		"bandage": str(_resource_tile_count("bandage")),
		"trap_tools": str(_resource_tile_count("trap_tools")),
		"camping_kit": str(_resource_tile_count("camping_kit")),
		"food": str(_resource_tile_count("food")),
	}


func _resource_tile_ids() -> Array[String]:
	return ["torch", "pickaxe", "trap_tools", "bandage", "camping_kit", "food"]


func _resource_tile_count(tile_id: String) -> int:
	var supply_id := _resource_tile_supply_id(tile_id)
	if supply_id == "":
		return int(run_state.get("light_level", 0))
	var loadout := selected_supply_loadout
	var state_supplies: Dictionary = run_state.get("supplies", {})
	return int(loadout.get(supply_id, state_supplies.get(supply_id, 0))) if _loadout_pending() else DungeonStateModel.supply_count(run_state, supply_id)


func _resource_tile_supply_id(tile_id: String) -> String:
	match tile_id:
		"torch":
			return "lamp_oil"
		"pickaxe":
			return "pickaxe"
		"bandage":
			return "bandage"
		"trap_tools":
			return "trap_tools"
		"camping_kit":
			return "camping_kit"
		"food":
			return "food"
		_:
			return ""


func _resource_tooltip_text(tile_id: String) -> String:
	var count := _resource_tile_count(tile_id)
	match tile_id:
		"torch":
			return "Torch oil: %s carried. Light: %s/%s %s." % [
				count,
				int(run_state.get("light_level", 0)),
				int(run_state.get("max_light_level", 0)),
				str(run_state.get("light_state", "")),
			]
		"pickaxe":
			return "Pickaxe: %s carried. Clears rubble and cave-ins." % count
		"bandage":
			return "Bandages: %s carried. Patches one injury." % count
		"trap_tools":
			return "Trap tools: %s carried. Disarms corridor traps." % count
		"camping_kit":
			return "Camping kit: %s carried. Enables camp recovery with food." % count
		"food":
			return "Food: %s carried. Spent when the party camps." % count
		_:
			return ""


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


func _map_frame_style() -> StyleBox:
	var fallback := _fantasy_panel_style(Color(0.035, 0.033, 0.028, 0.94), Color(0.42, 0.32, 0.16), 2, 6)
	fallback.shadow_color = Color(0, 0, 0, 0.42)
	fallback.shadow_size = 10
	fallback.shadow_offset = Vector2(0, 3)
	return _dungeon_ui_stylebox(DUNGEON_UI_MAP_FRAME_PATH, Vector4(72, 64, 72, 64), Vector4(22, 18, 22, 18), fallback)


func _progress_summary() -> String:
	var room_count: int = dungeon.get("rooms", []).size()
	var visited_count: int = run_state.get("visited_room_ids", []).size()
	var cleared_count: int = run_state.get("cleared_room_ids", []).size()
	var totals := DungeonStateModel.reward_totals(run_state)
	return "Rooms visited %s/%s | Secured %s/%s | Light %s/%s %s | Torch %s | Pickaxe %s | Trap Tools %s | Bandage %s | Camp %s | Food %s | Effects %s | Gold %s | Items %s | XP %s" % [
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
		DungeonStateModel.supply_count(run_state, "bandage"),
		DungeonStateModel.supply_count(run_state, "camping_kit"),
		DungeonStateModel.supply_count(run_state, "food"),
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
	return _preferred_recovery_supply_id() != ""


func _preferred_recovery_supply_id() -> String:
	if not DungeonStateModel.active_debuff_summary(run_state).is_empty() and DungeonStateModel.supply_count(run_state, "antidote") > 0:
		return "antidote"
	if int(run_state.get("party_effects", {}).get("hp_loss", 0)) > 0 and DungeonStateModel.supply_count(run_state, "bandage") > 0:
		return "bandage"
	return ""


func _can_use_camp() -> bool:
	if bool(run_state.get("completed", false)):
		return false
	if DungeonStateModel.supply_count(run_state, "camping_kit") <= 0:
		return false
	if DungeonStateModel.supply_count(run_state, "food") <= 0:
		return false
	if int(run_state.get("party_effects", {}).get("hp_loss", 0)) > 0:
		return true
	return not DungeonStateModel.active_debuff_summary(run_state).is_empty()


func _apply_hud_visual_style() -> void:
	var panel_style := _fantasy_panel_style(Color(0.045, 0.040, 0.035, 0.98), Color(0.62, 0.44, 0.20), 2, 6)
	panel_style.shadow_color = Color(0, 0, 0, 0.50)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0, 4)
	detail_panel.add_theme_stylebox_override("panel", _dungeon_ui_stylebox(
		DUNGEON_UI_DETAIL_PANEL_PATH,
		Vector4(54, 54, 54, 54),
		Vector4(34, 52, 34, 30),
		panel_style
	))
	var detail_margin := detail_panel.get_node_or_null("MarginContainer") as MarginContainer
	if detail_margin != null:
		detail_margin.add_theme_constant_override("margin_left", 34)
		detail_margin.add_theme_constant_override("margin_top", 52)
		detail_margin.add_theme_constant_override("margin_right", 34)
		detail_margin.add_theme_constant_override("margin_bottom", 30)
	panel_title.add_theme_font_size_override("font_size", 22)
	detail_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_font_size_override("font_size", 17)
	progress_label.add_theme_font_size_override("font_size", 14)


func _button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	return _fantasy_panel_style(bg_color, border_color, 2, 6)


func _fantasy_panel_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return PixelSkin.flat_frame(bg_color, border_color, border_width, radius)


func _dungeon_ui_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if dungeon_ui_texture_cache.has(path):
		return dungeon_ui_texture_cache[path]
	var texture := AssetCatalog.texture(path)
	dungeon_ui_texture_cache[path] = texture
	return texture


func _dungeon_ui_stylebox(path: String, texture_margins: Vector4, content_margins: Vector4, fallback: StyleBox) -> StyleBox:
	return pixel_skin.frame(path, texture_margins, content_margins, fallback)


func _asset_index_path(prefix: String, index: int) -> String:
	return "%s%02d.png" % [prefix, index]


func _resource_tile_frame_path(tile_id: String) -> String:
	var index := 1
	match tile_id:
		"torch":
			index = 2
		"pickaxe":
			index = 3
		"bandage":
			index = 4
		"trap_tools":
			index = 5
		"camping_kit":
			index = 5
		"food":
			index = 6
		"effects":
			index = 6
	return _asset_index_path(DUNGEON_UI_TILE_PREFIX, index)


func _resource_icon_path(tile_id: String) -> String:
	match tile_id:
		"torch":
			return _dedicated_icon_path("icon_lamp_oil")
		"pickaxe":
			return _dedicated_icon_path("icon_pickaxe")
		"bandage":
			return _dedicated_icon_path("icon_bandage")
		"trap_tools":
			return _dedicated_icon_path("icon_trap")
		"camping_kit":
			return _dedicated_icon_path("icon_camping_kit")
		"food":
			return _dedicated_icon_path("icon_food")
		"effects":
			return _dedicated_icon_path("icon_room_event")
		_:
			return _dedicated_icon_path("icon_light_source")


func _room_icon_path(room: Dictionary) -> String:
	if room.has("locked_by_item_id"):
		return _dedicated_icon_path("icon_locked_room")
	var kind := str(room.get("kind", ""))
	match kind:
		"treasure":
			return _dedicated_icon_path("icon_treasure")
		"combat":
			return _dedicated_icon_path("icon_combat_room")
		"guarded_treasure":
			return _dedicated_icon_path("icon_treasure")
		"exit":
			return _dedicated_icon_path("icon_exit_room")
		_:
			if str(room.get("id", "")) == str(dungeon.get("start_room_id", "")):
				return _dedicated_icon_path("icon_light_source")
			for content: Dictionary in room.get("content", []):
				if str(content.get("type", "")) == "room_event":
					return _dedicated_icon_path("icon_room_event")
			return _dedicated_icon_path("icon_light_source")


func _dedicated_icon_path(icon_name: String) -> String:
	return "%s%s.png" % [DUNGEON_DEDICATED_ICON_DIR, icon_name]


func _room_frame_path(room_id: String, kind: String) -> String:
	var index := 0
	if room_id == str(run_state.get("current_room_id", "")):
		index = 1
	elif kind == "combat" or kind == "guarded_treasure":
		index = 2
	elif kind == "treasure":
		index = 3
	elif kind == "exit":
		index = 4
	elif DungeonStateModel.room_is_cleared(run_state, room_id):
		index = 5
	elif DungeonStateModel.room_is_visited(run_state, room_id):
		index = 6
	return _asset_index_path(DUNGEON_ROOM_FRAME_PREFIX, index)


func _party_slot_tint(slot_index: int) -> Color:
	var tints := [
		Color(1.0, 0.94, 0.84),
		Color(0.86, 0.94, 1.0),
		Color(1.0, 0.86, 0.82),
		Color(0.84, 1.0, 0.88),
	]
	return tints[slot_index % tints.size()]


func _party_slot_bar_color(slot_index: int) -> Color:
	var colors := [
		Color(0.55, 0.18, 0.13),
		Color(0.50, 0.38, 0.18),
		Color(0.20, 0.46, 0.34),
		Color(0.22, 0.34, 0.58),
	]
	return colors[slot_index % colors.size()]


func _party_members_for_ui() -> Array:
	var formation: Array = run_state.get("party_formation", [])
	if formation.is_empty():
		formation = PartyRoster.default_party_formation()
	return PartyRoster.heroes_for_formation(formation)


func _party_log_text() -> String:
	if _loadout_pending():
		return "Prepare the expedition loadout before entering the mine."
	if last_feedback != "":
		return last_feedback
	return "%s\n%s" % [_route_state_text(), _progress_summary()]


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


func _room_style(room_id: String, kind: String) -> StyleBox:
	if expedition_chrome!=null: return expedition_chrome.room_style(self,room_id,kind)
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
	return _dungeon_ui_stylebox(_room_frame_path(room_id, kind), Vector4(32, 30, 32, 30), Vector4(10, 10, 10, 10), style)


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
