extends Control

const CombatResolver := preload("res://scripts/domain/combat_resolver.gd")
const CombatTextUtil := preload("res://scripts/presentation/combat/combat_text.gd")
const CombatUnitArtDb := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const CombatActionModel := preload("res://scripts/presentation/combat/combat_action_model.gd")
const CombatScenarioCatalog := preload("res://scripts/presentation/combat/combat_scenario_catalog.gd")

const DEFAULT_ENCOUNTER_PATH := CombatScenarioCatalog.DEFAULT_ENCOUNTER_PATH
const PIXEL_PANEL_TEXTURE_PATH := "res://assets/ui/combat/pixel_panel.png"
const TILE_ATLAS_TEXTURE_PATH := "res://assets/tilesets/combat_logic_tiles.png"
const UNIT_ICON_SIZE := Vector2i(76, 76)
const UNIT_RESOURCE_LABEL_SIZE := Vector2(64, 28)
const UNIT_RESOURCE_LABEL_OFFSET_Y := -24.0
const TILE_ATLAS_SOURCE_SIZE := 76
const TILE_SIZE := 64
const TILE_GAP := 0
const MOVE_STEP_SECONDS := 0.52
const COMBAT_LUNGE_PIXELS := 18.0
const COMBAT_WINDUP_SECONDS := 0.09
const COMBAT_RETURN_SECONDS := 0.14
const HIT_SHAKE_PIXELS := 7.0
const HIT_SHAKE_SECONDS := 0.055
const DEATH_FALL_PIXELS := 16.0
const DEATH_SECONDS := 0.65
const DEATH_HOLD_SECONDS := 0.45
const TERRAIN_DECORATIONS := {
	"3,2": "res://assets/terrain/nature/fallen_branch/fallen_branch_frame_0.png",
	"5,2": "res://assets/terrain/nature/mossy_boulder/mossy_boulder_frame_0.png",
	"10,2": "res://assets/terrain/nature/tree_stump/tree_stump_frame_2.png",
	"2,5": "res://assets/terrain/nature/mossy_boulder/mossy_boulder_frame_6.png",
	"9,5": "res://assets/terrain/nature/grass_tuft/grass_tuft_frame_4.png",
	"2,6": "res://assets/terrain/nature/grass_tuft/grass_tuft_frame_9.png",
	"4,6": "res://assets/terrain/nature/tree_stump/tree_stump_frame_5.png",
	"7,7": "res://assets/terrain/nature/fallen_branch/fallen_branch_frame_10.png",
}
const ACTION_LABELS := CombatTextUtil.ACTION_LABELS

@onready var board_root: Control = %BoardRoot
@onready var grid_container: GridContainer = %GridContainer
@onready var unit_layer: Control = %UnitLayer
@onready var action_panel: PanelContainer = %ActionPanel
@onready var action_title_label: Label = %ActionTitleLabel
@onready var action_detail_label: Label = %ActionDetailLabel
@onready var action_feed_label: Label = %ActionFeedLabel
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
var selected_scenario_id := "map_scale_showcase"
var selected_position: Dictionary = {}
var pending_move_position: Dictionary = {}
var pending_move_event: Dictionary = {}
var unit_facing: Dictionary = {}
var unit_visual_action: Dictionary = {}
var unit_texture_cache: Dictionary = {}
var tile_texture_cache: Dictionary = {}
var terrain_decoration_texture_cache: Dictionary = {}
var temporary_visual_units: Dictionary = {}
var visual_positions_px: Dictionary = {}
var visual_generation := 0
var animation_locked := false
var current_action_title := "Combat ready"
var current_action_detail := "Select an action or step the next turn."
var action_feed: Array[String] = []
var unit_art := CombatUnitArtDb.new()
var target_preview_cache: Dictionary = {}
var presentation_cache_ready := false


func _ready() -> void:
	_apply_pixel_theme()
	_reset_debug_encounter()


func _reset_debug_encounter() -> void:
	state = _load_json(current_encounter_path)
	state["event_log"] = []
	command_index = 1
	selected_action = "move"
	_clear_move_preview()
	unit_facing.clear()
	unit_visual_action.clear()
	temporary_visual_units.clear()
	visual_positions_px.clear()
	action_feed.clear()
	current_action_title = "Combat ready"
	current_action_detail = "Select an action or step the next turn."
	last_feedback = "Encounter reset."
	var result := CombatResolver.simulate(state, [])
	state = result["state"]
	selected_position = _unit_by_id(state["turn_state"]["active_unit_id"]).get("position", {})
	_prepare_presentation_cache()
	_render()


func _render() -> void:
	_clear_grid()
	_clear_units()
	grid_container.columns = int(state["grid"]["width"])
	grid_container.add_theme_constant_override("h_separation", TILE_GAP)
	grid_container.add_theme_constant_override("v_separation", TILE_GAP)
	_resize_board()

	for y in range(int(state["grid"]["height"])):
		for x in range(int(state["grid"]["width"])):
			grid_container.add_child(_build_tile({"x": x, "y": y}))
	_render_units()

	_render_action_panel()
	_render_status()
	_render_feedback()
	_render_legend()
	_render_unit_list()
	_render_inspect()
	_render_event_log()
	_render_command_buttons()


func _prepare_presentation_cache() -> void:
	_sync_selected_action_with_visible_actions(_visible_primary_action_ids())
	target_preview_cache = _build_target_preview_cache()
	_preload_presentation_assets()
	presentation_cache_ready = true


func _preload_presentation_assets() -> void:
	for tile: Dictionary in state.get("grid", {}).get("tiles", []):
		var position := {"x": int(tile["x"]), "y": int(tile["y"])}
		_tile_visual_texture(str(tile["type"]), position)
		_tile_decoration_texture(position)

	var preload_actions := ["pose", "combat_idle", "walk", "combat", "hit", "death"]
	for unit: Dictionary in state.get("units", []):
		for visual_action: String in preload_actions:
			var visual_actions := {}
			visual_actions[unit["id"]] = visual_action
			unit_art.icon(unit, state, unit_facing, visual_actions, UNIT_ICON_SIZE)


func _build_tile(position: Dictionary) -> Button:
	var tile := Button.new()
	tile.disabled = animation_locked
	tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.flat = true
	tile.text = ""
	tile.tooltip_text = _tile_tooltip(position)
	tile.pressed.connect(func() -> void:
		_on_tile_pressed(position)
	)

	var terrain_type := _tile_type(position)
	var terrain_texture := TextureRect.new()
	terrain_texture.name = "Terrain"
	terrain_texture.texture = _tile_visual_texture(terrain_type, position)
	terrain_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	terrain_texture.stretch_mode = TextureRect.STRETCH_SCALE
	terrain_texture.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	terrain_texture.size = Vector2(TILE_SIZE, TILE_SIZE)
	terrain_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(terrain_texture)

	var decoration_texture := _tile_decoration_texture(position)
	if decoration_texture != null:
		var decoration := TextureRect.new()
		decoration.name = "TerrainDecoration"
		decoration.texture = decoration_texture
		decoration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		decoration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		decoration.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		decoration.size = Vector2(TILE_SIZE, TILE_SIZE)
		decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(decoration)

	var unit := _living_unit_at(position)
	var overlay_color := _tile_overlay_color(position, unit)
	if overlay_color.a > 0.001:
		var overlay := ColorRect.new()
		overlay.name = "Overlay"
		overlay.color = overlay_color
		overlay.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		overlay.size = Vector2(TILE_SIZE, TILE_SIZE)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(overlay)

	var preview_label_text := _tile_preview_label(position)
	if preview_label_text != "":
		var preview_label := Label.new()
		preview_label.name = "PreviewLabel"
		preview_label.text = preview_label_text
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview_label.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		preview_label.size = Vector2(TILE_SIZE, TILE_SIZE)
		preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_label.add_theme_font_size_override("font_size", 10)
		preview_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.48))
		preview_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.02, 1.0))
		preview_label.add_theme_constant_override("shadow_offset_x", 1)
		preview_label.add_theme_constant_override("shadow_offset_y", 1)
		tile.add_child(preview_label)

	return tile


func _tile_visual_texture(terrain_type: String, position: Dictionary) -> Texture2D:
	var atlas_index := _tile_atlas_index(terrain_type, position)
	var cache_key := "%s:%s" % [terrain_type, atlas_index]
	if tile_texture_cache.has(cache_key):
		return tile_texture_cache[cache_key]
	if not tile_texture_cache.has("__atlas"):
		var image := Image.new()
		var error := image.load(TILE_ATLAS_TEXTURE_PATH)
		if error != OK:
			push_error("Cannot load tile atlas texture: %s" % TILE_ATLAS_TEXTURE_PATH)
			return null
		tile_texture_cache["__atlas"] = ImageTexture.create_from_image(image)
	var atlas_texture: Texture2D = tile_texture_cache["__atlas"]
	var atlas := AtlasTexture.new()
	atlas.atlas = atlas_texture
	atlas.region = Rect2(atlas_index * TILE_ATLAS_SOURCE_SIZE, 0, TILE_ATLAS_SOURCE_SIZE, TILE_ATLAS_SOURCE_SIZE)
	tile_texture_cache[cache_key] = atlas
	return atlas


func _tile_atlas_index(terrain_type: String, position: Dictionary) -> int:
	var x := int(position.get("x", 0))
	var y := int(position.get("y", 0))
	match terrain_type:
		"blocked":
			return 4 if (x + y) % 3 == 1 else 1
		"highground":
			return 2
		"cover_low":
			return 5 if (x * 2 + y) % 4 == 0 else 3
		_:
			return 0


func _tile_decoration_texture(position: Dictionary) -> Texture2D:
	var key := "%s,%s" % [position.get("x", 0), position.get("y", 0)]
	if not TERRAIN_DECORATIONS.has(key):
		return null
	var path: String = TERRAIN_DECORATIONS[key]
	if terrain_decoration_texture_cache.has(path):
		return terrain_decoration_texture_cache[path]
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_error("Cannot load terrain decoration texture: %s" % path)
		return null
	var texture := ImageTexture.create_from_image(image)
	terrain_decoration_texture_cache[path] = texture
	return texture


func _tile_overlay_color(position: Dictionary, unit: Dictionary) -> Color:
	if _is_active_unit_at(position):
		return Color(1.0, 0.83, 0.18, 0.34)
	if _is_pending_move_destination(position):
		return Color(1.0, 0.76, 0.18, 0.24)
	if _is_pending_move_path(position):
		return Color(0.36, 0.72, 1.0, 0.18)
	if not unit.is_empty() and unit["team"] == "player":
		return Color(0.18, 0.45, 0.85, 0.26)
	if not unit.is_empty():
		return Color(0.90, 0.16, 0.12, 0.26)
	if _is_legal_target_for_selected_action(position):
		return Color(0.25, 0.95, 0.35, 0.14)
	if _positions_equal(selected_position, position):
		return Color(0.50, 0.48, 0.90, 0.16)
	return Color(0, 0, 0, 0)


func _tile_preview_label(position: Dictionary) -> String:
	if not _is_pending_move_destination(position):
		return ""
	return "MP %s\nOK?" % pending_move_event.get("mp_spent", "?")


func _tile_text(position: Dictionary) -> String:
	return ""


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
	status_label.text = "Round %s | Result: %s\nActive: %s (%s) | HP %s | AP %s | MP %s | Selected: %s" % [
		state["turn_state"]["round"],
		_combat_result(),
		active.get("id", "missing"),
		active.get("team", "missing"),
		active.get("resources", {}).get("hp", "?"),
		active.get("resources", {}).get("ap", "?"),
		active.get("resources", {}).get("mp", "-"),
		ACTION_LABELS.get(selected_action, selected_action),
	]


func _render_action_panel() -> void:
	action_title_label.text = current_action_title
	action_detail_label.text = current_action_detail
	if action_feed.is_empty():
		action_feed_label.text = "Recent: no actions yet"
	else:
		var recent_feed := action_feed.slice(0, mini(3, action_feed.size()))
		action_feed_label.text = "Recent: " + "  |  ".join(recent_feed)


func _render_feedback() -> void:
	feedback_label.text = last_feedback


func _render_legend() -> void:
	legend_label.text = "Blue player | Red enemy | Active gold | Legal soft green | Preview path blue | Confirm tile amber"


func _render_unit_list() -> void:
	var lines: Array[String] = []
	for unit: Dictionary in state["units"]:
		var marker := "*" if unit["id"] == state["turn_state"]["active_unit_id"] else " "
		lines.append("%s %s [%s] HP %s/%s AP %s/%s MP %s/%s ACC %s EVA %s WPN %s pos (%s,%s)\n  Cooldowns: %s | Statuses: %s" % [
			marker,
			unit["id"],
			unit["team"],
			unit["resources"]["hp"],
			unit["stats"]["max_hp"],
			unit["resources"]["ap"],
			unit["stats"]["max_ap"],
			unit["resources"].get("mp", "-"),
			unit["stats"].get("move_points", "-"),
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
		lines.append("HP/AP/MP: %s/%s/%s" % [unit["resources"]["hp"], unit["resources"]["ap"], unit["resources"].get("mp", "-")])

	var command := _preview_command_for_position(selected_position)
	if command.is_empty():
		lines.append("Selected action: %s" % ACTION_LABELS.get(selected_action, selected_action))
	else:
		var preview := _target_preview_for_position(selected_position)
		var rejection := str(preview.get("rejection", ""))
		if rejection == "":
			lines.append("Selected action: legal")
			if selected_action == "move":
				var move_event: Dictionary = preview.get("move_event", {})
				if not move_event.is_empty():
					lines.append("Route MP: %s" % move_event.get("mp_spent", "?"))
					lines.append("Route steps: %s" % move_event.get("path", []).size())
		else:
			lines.append("Selected action: rejected")
			lines.append("Reason: %s" % rejection)

	inspect_label.text = "\n".join(lines)


func _render_event_log() -> void:
	var lines: Array[String] = []
	var events: Array = state["event_log"].duplicate(true)
	events.reverse()
	for event: Dictionary in events:
		lines.append("%s %s. %s" % [
			_event_marker(event),
			event["sequence"],
			_event_timeline_line(event),
		])
	event_log_label.text = "\n".join(lines)


func _render_command_buttons() -> void:
	for child in command_buttons.get_children():
		child.queue_free()

	var primary_actions := _visible_primary_action_ids()
	_sync_selected_action_with_visible_actions(primary_actions)

	_add_button_section("Commands")
	for action_id in primary_actions:
		_add_action_button(action_id)

	var debug_actions := _visible_debug_action_ids()
	if not debug_actions.is_empty():
		_add_button_section("Turn Tools")
		for action_id in debug_actions:
			_add_action_button(action_id)

	_add_button_section("Load Test")
	_add_scenario_picker()


func _visible_primary_action_ids() -> Array[String]:
	return CombatActionModel.visible_primary_action_ids(state)


func _visible_debug_action_ids() -> Array[String]:
	return CombatActionModel.visible_debug_action_ids(state)


func _sync_selected_action_with_visible_actions(visible_actions: Array[String]) -> void:
	if visible_actions.has(selected_action):
		return
	if visible_actions.has("move"):
		selected_action = "move"
	elif not visible_actions.is_empty():
		selected_action = visible_actions[0]
	else:
		selected_action = "end_turn"
	_clear_move_preview()


func _action_can_be_shown_now(unit: Dictionary, action_id: String) -> bool:
	return CombatActionModel.action_can_be_shown_now(state, unit, action_id)


func _add_button_section(title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 10)
	command_buttons.add_child(label)


func _add_action_button(action_id: String) -> void:
	var button := Button.new()
	button.text = ">> %s <<" % ACTION_LABELS.get(action_id, action_id) if selected_action == action_id else ACTION_LABELS.get(action_id, action_id)
	button.custom_minimum_size = Vector2(0, 24)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", Color(0.94, 0.88, 0.72))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.86, 0.38))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.68))
	button.toggle_mode = true
	button.button_pressed = selected_action == action_id
	button.modulate = Color(1.0, 0.88, 0.46) if selected_action == action_id else Color(0.86, 0.82, 0.72)
	button.disabled = animation_locked or _combat_result() != "in_progress"
	button.pressed.connect(func() -> void:
		if animation_locked:
			return
		selected_action = action_id
		_clear_move_preview()
		if action_id == "enemy_turn":
			_run_enemy_turn_helper()
		elif action_id == "enemy_ai":
			_run_command(CombatResolver.choose_enemy_command(state, "cmd_%03d" % command_index))
		elif action_id in ["shield_wall", "defend", "end_turn"]:
			_run_command(_build_command(action_id, {}))
		else:
			_set_targeting_banner(action_id)
			last_feedback = "Select a highlighted target for %s." % ACTION_LABELS.get(action_id, action_id)
			_prepare_presentation_cache()
			_render()
	)
	command_buttons.add_child(button)


func _add_scenario_picker() -> void:
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.custom_minimum_size = Vector2(0, 22)
	picker.add_theme_font_size_override("font_size", 10)

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
	load_button.disabled = animation_locked
	load_button.custom_minimum_size = Vector2(0, 22)
	load_button.add_theme_font_size_override("font_size", 10)
	load_button.pressed.connect(func() -> void:
		_load_selected_scenario()
	)
	command_buttons.add_child(load_button)


func _load_selected_scenario() -> void:
	if animation_locked:
		return
	for option: Dictionary in _scenario_options():
		if option["id"] == selected_scenario_id:
			current_encounter_path = option["path"]
			_reset_debug_encounter()
			return

	last_feedback = "Unknown test selection: %s" % selected_scenario_id
	_render()


func _scenario_options() -> Array[Dictionary]:
	return CombatScenarioCatalog.options()


func _on_tile_pressed(position: Dictionary) -> void:
	if animation_locked:
		return
	selected_position = position.duplicate(true)
	if selected_action == "move":
		_on_move_tile_pressed(position)
	elif selected_action == "basic_attack":
		_clear_move_preview()
		var unit := _living_unit_at(position)
		_run_command(_build_command("basic_attack", {
			"type": "unit",
			"unit_id": unit.get("id", ""),
		}))
	elif selected_action == "ranged_attack":
		_clear_move_preview()
		var unit := _living_unit_at(position)
		_run_command(_build_command("ranged_attack", {
			"type": "unit",
			"unit_id": unit.get("id", ""),
		}))
	elif selected_action == "aimed_shot":
		_clear_move_preview()
		var unit := _living_unit_at(position)
		_run_command(_build_command("aimed_shot", {
			"type": "unit",
			"unit_id": unit.get("id", ""),
		}))
	elif selected_action == "power_strike":
		_clear_move_preview()
		var unit := _living_unit_at(position)
		_run_command(_build_command("power_strike", {
			"type": "unit",
			"unit_id": unit.get("id", ""),
		}))


func _on_move_tile_pressed(position: Dictionary) -> void:
	var command := _build_command("move", {
		"type": "tile",
		"position": position,
	})
	var preview := _target_preview_for_position(position)
	var rejection := str(preview.get("rejection", ""))
	if rejection != "":
		_clear_move_preview()
		last_feedback = "Move rejected: %s" % _rejection_label(rejection)
		_render()
		return

	if _is_pending_move_destination(position):
		_clear_move_preview()
		_run_command(command)
		return

	pending_move_position = position.duplicate(true)
	pending_move_event = preview.get("move_event", {})
	current_action_title = "Move preview"
	current_action_detail = "Route to %s costs %s MP. Click the same tile again to move." % [
		_position_label(position),
		pending_move_event.get("mp_spent", "?"),
	]
	last_feedback = "Move preview selected. Click the destination again to confirm."
	_render()


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
	if animation_locked:
		return
	_clear_move_preview()
	if _combat_result() != "in_progress":
		last_feedback = "Combat already ended."
		_render()
		return

	var previous_log: Array = state["event_log"].duplicate(true)
	var previous_state := _state_without_log()
	var result := CombatResolver.simulate(previous_state, [command])
	var next_state: Dictionary = result["state"]
	var new_events: Array = _events_after_startup(next_state["event_log"])
	var next_log := previous_log + new_events
	var next_feedback := _feedback_from_events(new_events)
	command_index += 1
	_set_action_banner_from_events(command, new_events)
	_capture_unit_facings(new_events)
	var has_movement_animation := _prepare_movement_animation(new_events)
	var has_combat_flash := _prepare_combat_flash(new_events, previous_state)
	if has_movement_animation:
		last_feedback = next_feedback
		animation_locked = true
		_render()
		_play_movement_animation(new_events, next_state, next_log)
		return

	state = next_state
	state["event_log"] = next_log
	last_feedback = next_feedback
	_prepare_presentation_cache()
	_render()
	if has_combat_flash:
		_play_combat_animation(new_events)
	else:
		_schedule_visual_reset()


func _run_enemy_turn_helper() -> void:
	if animation_locked:
		return
	if _combat_result() != "in_progress":
		last_feedback = "Combat already ended."
		_render()
		return

	var active := _unit_by_id(state["turn_state"]["active_unit_id"])
	if active.is_empty():
		last_feedback = "No active unit."
		_render()
		return

	if active["team"] == "player":
		_run_command(_build_command("end_turn", {}))
	elif active["team"] == "enemy":
		_run_command(CombatResolver.choose_enemy_command(state, "cmd_%03d" % command_index))
	else:
		last_feedback = "Unknown active team."
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
	_capture_unit_facings(new_events)
	_set_action_banner_from_events(command, new_events)
	_prepare_presentation_cache()


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


func _apply_pixel_theme() -> void:
	var panel_texture := _load_pixel_ui_texture(PIXEL_PANEL_TEXTURE_PATH)
	if panel_texture != null:
		var panel_style := StyleBoxTexture.new()
		panel_style.texture = panel_texture
		panel_style.texture_margin_left = 8
		panel_style.texture_margin_top = 8
		panel_style.texture_margin_right = 8
		panel_style.texture_margin_bottom = 8
		panel_style.content_margin_left = 12
		panel_style.content_margin_top = 8
		panel_style.content_margin_right = 12
		panel_style.content_margin_bottom = 8
		action_panel.add_theme_stylebox_override("panel", panel_style)

	var action_title_color := Color(1.0, 0.86, 0.38)
	var action_text_color := Color(0.96, 0.92, 0.80)
	var shadow_color := Color(0.05, 0.04, 0.03, 1.0)
	for label: Label in [action_title_label, action_detail_label, action_feed_label, status_label, feedback_label, legend_label]:
		label.add_theme_color_override("font_color", action_text_color)
		label.add_theme_color_override("font_shadow_color", shadow_color)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
	action_title_label.add_theme_color_override("font_color", action_title_color)


func _load_pixel_ui_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_error("Cannot load pixel UI texture: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _set_targeting_banner(action_id: String) -> void:
	current_action_title = "Targeting: %s" % ACTION_LABELS.get(action_id, action_id)
	current_action_detail = "Pick a highlighted target on the board."


func _set_action_banner_from_events(command: Dictionary, events: Array) -> void:
	var title := ""
	var detail := ""
	var feed_line := ""

	for event: Dictionary in events:
		if event["type"] == "command_rejected":
			title = "Action rejected"
			detail = "%s could not use %s: %s" % [
				_unit_display_name(event.get("actor_id", command.get("actor_id", ""))),
				ACTION_LABELS.get(command.get("action_id", ""), command.get("action_id", "")),
				_rejection_label(event.get("reason", "unknown")),
			]
			feed_line = "Rejected %s" % ACTION_LABELS.get(command.get("action_id", ""), command.get("action_id", "action"))
			break

	for event: Dictionary in events:
		if event["type"] == "damage_applied":
			title = "%s hits %s" % [
				_unit_display_name(event.get("actor_id", "")),
				_unit_display_name(event.get("target_unit_id", "")),
			]
			detail = "%s damage dealt. HP %s -> %s. Reduction: %s." % [
				event.get("damage", "?"),
				event.get("hp_before", "?"),
				event.get("hp_after", "?"),
				event.get("damage_reduction", 0),
			]
			feed_line = "%s hit %s for %s" % [
				_unit_display_name(event.get("actor_id", "")),
				_unit_display_name(event.get("target_unit_id", "")),
				event.get("damage", "?"),
			]
			break

	if title == "":
		for event: Dictionary in events:
			if event["type"] == "hit_roll_resolved":
				var outcome := str(event.get("outcome", "?")).capitalize()
				title = "%s: %s" % [ACTION_LABELS.get(command.get("action_id", ""), command.get("action_id", "")), outcome]
				detail = "%s rolled %s vs %s%% to hit %s." % [
					_unit_display_name(event.get("actor_id", "")),
					event.get("roll", "?"),
					event.get("hit_chance", "?"),
					_unit_display_name(event.get("target_unit_id", "")),
				]
				feed_line = "%s %s %s" % [_unit_display_name(event.get("actor_id", "")), outcome.to_lower(), _unit_display_name(event.get("target_unit_id", ""))]
				break

	if title == "":
		for event: Dictionary in events:
			if event["type"] == "unit_moved":
				title = "%s moves" % _unit_display_name(event.get("actor_id", ""))
				detail = "%s -> %s. MP spent: %s. Path steps: %s." % [
					_position_label(event.get("from", {})),
					_position_label(event.get("to", {})),
					event.get("mp_spent", 0),
					event.get("path", []).size(),
				]
				feed_line = "%s moved to %s" % [_unit_display_name(event.get("actor_id", "")), _position_label(event.get("to", {}))]
				break

	if title == "":
		for event: Dictionary in events:
			if event["type"] == "status_applied":
				var status: Dictionary = event.get("status", {})
				title = "%s gains %s" % [
					_unit_display_name(event.get("target_unit_id", "")),
					_status_label(status),
				]
				detail = "Turns: %s. Source: %s." % [status.get("remaining_turns", "?"), _unit_display_name(event.get("actor_id", ""))]
				feed_line = "%s gained %s" % [_unit_display_name(event.get("target_unit_id", "")), _status_label(status)]
				break

	if title == "":
		for event: Dictionary in events:
			if event["type"] == "turn_ended":
				title = "%s ends turn" % _unit_display_name(event.get("actor_id", ""))
				detail = "Next unit is starting."
				feed_line = "%s ended turn" % _unit_display_name(event.get("actor_id", ""))
			elif event["type"] == "turn_started":
				title = "%s starts turn" % _unit_display_name(event.get("actor_id", ""))
				detail = "Round %s. AP/MP refreshed if available." % event.get("round", "?")
				feed_line = "%s started turn" % _unit_display_name(event.get("actor_id", ""))

	if title == "":
		title = "Command accepted"
		detail = "%s resolved." % ACTION_LABELS.get(command.get("action_id", ""), command.get("action_id", "Action"))
		feed_line = detail

	current_action_title = title
	current_action_detail = detail
	_push_action_feed(feed_line)


func _push_action_feed(line: String) -> void:
	if line == "":
		return
	action_feed.push_front(line)
	while action_feed.size() > 5:
		action_feed.pop_back()


func _event_timeline_line(event: Dictionary) -> String:
	return CombatTextUtil.event_timeline_line(event, state)


func _event_summary(event: Dictionary) -> String:
	return CombatTextUtil.event_summary(event)


func _event_marker(event: Dictionary) -> String:
	return CombatTextUtil.event_marker(event)


func _feedback_from_events(events: Array) -> String:
	return CombatTextUtil.feedback_from_events(events)


func _capture_unit_facings(events: Array) -> void:
	for event: Dictionary in events:
		if event["type"] == "unit_moved":
			unit_facing[event.get("actor_id", "")] = _direction_between(event.get("from", {}), event.get("to", {}))
		elif event["type"] == "damage_applied":
			var actor := _unit_by_id(event.get("actor_id", ""))
			var target := _unit_by_id(event.get("target_unit_id", ""))
			if not actor.is_empty() and not target.is_empty():
				unit_facing[actor["id"]] = _direction_between(actor["position"], target["position"])


func _schedule_visual_reset() -> void:
	if unit_facing.is_empty() and unit_visual_action.is_empty() and temporary_visual_units.is_empty():
		return
	visual_generation += 1
	var current_generation := visual_generation
	get_tree().create_timer(0.45).timeout.connect(func() -> void:
		if current_generation != visual_generation:
			return
		unit_visual_action.clear()
		temporary_visual_units.clear()
		_render()
	)


func _prepare_movement_animation(events: Array) -> bool:
	var prepared := false
	for event: Dictionary in events:
		if event["type"] != "unit_moved":
			continue
		var actor_id := str(event.get("actor_id", ""))
		if actor_id == "":
			continue
		visual_positions_px[actor_id] = _position_to_unit_top_left(event.get("from", {}))
		unit_visual_action[actor_id] = "walk"
		prepared = true
	return prepared


func _prepare_combat_flash(events: Array, previous_state: Dictionary) -> bool:
	var prepared := false
	for event: Dictionary in events:
		if event["type"] != "damage_applied" and event["type"] != "hit_roll_resolved":
			continue
		var actor_id := str(event.get("actor_id", ""))
		if actor_id == "":
			continue
		unit_visual_action[actor_id] = "combat"
		if event["type"] == "damage_applied":
			var target_id := str(event.get("target_unit_id", ""))
			if target_id != "":
				if int(event.get("hp_after", 1)) <= 0:
					var defeated_unit := _unit_by_id_in_state(previous_state, target_id)
					if not defeated_unit.is_empty():
						defeated_unit = defeated_unit.duplicate(true)
						defeated_unit["resources"]["hp"] = 0
						temporary_visual_units[target_id] = defeated_unit
					unit_visual_action[target_id] = "death"
				else:
					unit_visual_action[target_id] = "hit"
		prepared = true
	return prepared


func _play_combat_animation(events: Array) -> void:
	animation_locked = true
	visual_generation += 1
	var current_generation := visual_generation
	var tween := create_tween()
	var tween_has_steps := false
	var animated_actors: Dictionary = {}
	var animated_targets: Dictionary = {}

	for event: Dictionary in events:
		if event["type"] != "damage_applied" and event["type"] != "hit_roll_resolved":
			continue
		var actor_id := str(event.get("actor_id", ""))
		if actor_id == "" or animated_actors.has(actor_id):
			continue
		var actor := _unit_by_id(actor_id)
		if actor.is_empty():
			continue
		var unit_node := unit_layer.get_node_or_null(actor_id)
		if unit_node == null:
			continue
		var target := _unit_by_id(str(event.get("target_unit_id", "")))
		var origin := _unit_visual_pixel_position(actor)
		var lunge := _combat_lunge_offset(actor, target)
		tween.tween_property(unit_node, "position", origin + lunge, COMBAT_WINDUP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(unit_node, "position", origin, COMBAT_RETURN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		animated_actors[actor_id] = true
		tween_has_steps = true

		if event["type"] != "damage_applied":
			continue
		var target_id := str(event.get("target_unit_id", ""))
		if target_id == "" or animated_targets.has(target_id):
			continue
		var target_node := unit_layer.get_node_or_null(target_id)
		if target_node == null:
			continue
		var target_unit := _unit_by_id(target_id)
		if target_unit.is_empty() and temporary_visual_units.has(target_id):
			target_unit = temporary_visual_units[target_id]
		if target_unit.is_empty():
			continue
		var target_origin := _unit_visual_pixel_position(target_unit)
		if int(event.get("hp_after", 1)) <= 0:
			tween.tween_property(target_node, "position", target_origin + Vector2(0, DEATH_FALL_PIXELS), DEATH_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(target_node, "modulate:a", 0.72, DEATH_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_interval(DEATH_HOLD_SECONDS)
		else:
			tween.tween_property(target_node, "position", target_origin + _hit_shake_offset(actor, target_unit), HIT_SHAKE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(target_node, "position", target_origin, HIT_SHAKE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		animated_targets[target_id] = true
		tween_has_steps = true

	if not tween_has_steps:
		_finish_combat_animation(current_generation)
		return

	tween.finished.connect(func() -> void:
		_finish_combat_animation(current_generation)
	)


func _finish_combat_animation(current_generation: int) -> void:
	if current_generation != visual_generation:
		return
	unit_visual_action.clear()
	temporary_visual_units.clear()
	animation_locked = false
	_render()


func _combat_lunge_offset(actor: Dictionary, target: Dictionary) -> Vector2:
	if target.is_empty():
		return Vector2(0, -COMBAT_LUNGE_PIXELS)
	var dx := float(int(target["position"]["x"]) - int(actor["position"]["x"]))
	var dy := float(int(target["position"]["y"]) - int(actor["position"]["y"]))
	var direction := Vector2(dx, dy)
	if direction.length() <= 0.001:
		return Vector2(0, -COMBAT_LUNGE_PIXELS)
	return direction.normalized() * COMBAT_LUNGE_PIXELS


func _hit_shake_offset(actor: Dictionary, target: Dictionary) -> Vector2:
	var dx := float(int(target["position"]["x"]) - int(actor["position"]["x"]))
	var dy := float(int(target["position"]["y"]) - int(actor["position"]["y"]))
	var direction := Vector2(dx, dy)
	if direction.length() <= 0.001:
		return Vector2(HIT_SHAKE_PIXELS, 0)
	return direction.normalized() * HIT_SHAKE_PIXELS


func _play_movement_animation(events: Array, next_state: Dictionary, next_log: Array) -> void:
	visual_generation += 1
	var current_generation := visual_generation
	var tween := create_tween()
	var tween_has_steps := false
	for event: Dictionary in events:
		if event["type"] != "unit_moved":
			continue
		var actor_id := str(event.get("actor_id", ""))
		var path: Array = event.get("path", [event.get("to", {})])
		var unit_node := unit_layer.get_node_or_null(actor_id)
		if unit_node == null:
			continue
		for step: Dictionary in path:
			var target_position := _position_to_unit_top_left(step)
			tween.tween_property(unit_node, "position", target_position, MOVE_STEP_SECONDS).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
			tween_has_steps = true
	if not tween_has_steps:
		_finish_movement_animation(events, current_generation, next_state, next_log)
		return
	tween.finished.connect(func() -> void:
		_finish_movement_animation(events, current_generation, next_state, next_log)
	)


func _finish_movement_animation(events: Array, current_generation: int, next_state: Dictionary, next_log: Array) -> void:
	if current_generation != visual_generation:
		return
	for event: Dictionary in events:
		if event["type"] != "unit_moved":
			continue
		var actor_id := str(event.get("actor_id", ""))
		visual_positions_px.erase(actor_id)
		unit_visual_action.erase(actor_id)
	temporary_visual_units.clear()
	state = next_state
	state["event_log"] = next_log
	animation_locked = false
	_prepare_presentation_cache()
	_render()
	_schedule_visual_reset()


func _clear_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()


func _clear_units() -> void:
	for child in unit_layer.get_children():
		child.queue_free()


func _resize_board() -> void:
	var width: int = int(state["grid"]["width"]) * TILE_SIZE + maxi(0, int(state["grid"]["width"]) - 1) * TILE_GAP
	var height: int = int(state["grid"]["height"]) * TILE_SIZE + maxi(0, int(state["grid"]["height"]) - 1) * TILE_GAP
	var board_size := Vector2(width, height)
	board_root.custom_minimum_size = board_size
	grid_container.custom_minimum_size = board_size
	grid_container.size = board_size
	unit_layer.custom_minimum_size = board_size
	unit_layer.size = board_size


func _render_units() -> void:
	for unit: Dictionary in _visual_units_for_render():
		var is_temporary := temporary_visual_units.has(unit["id"])
		if unit["resources"]["hp"] <= 0 and not is_temporary:
			continue
		var unit_node := Control.new()
		unit_node.name = unit["id"]
		unit_node.custom_minimum_size = Vector2(UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y)
		unit_node.size = Vector2(UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y)
		unit_node.position = _unit_visual_pixel_position(unit)
		unit_node.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var sprite := TextureRect.new()
		sprite.name = "Sprite"
		sprite.texture = _unit_icon(unit)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.custom_minimum_size = Vector2(UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y)
		sprite.size = Vector2(UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y)
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		unit_node.add_child(sprite)

		var resource_panel := PanelContainer.new()
		resource_panel.name = "ResourcePanel"
		resource_panel.custom_minimum_size = UNIT_RESOURCE_LABEL_SIZE
		resource_panel.size = UNIT_RESOURCE_LABEL_SIZE
		resource_panel.position = Vector2(
			(float(UNIT_ICON_SIZE.x) - UNIT_RESOURCE_LABEL_SIZE.x) / 2.0,
			UNIT_RESOURCE_LABEL_OFFSET_Y
		)
		resource_panel.position.x += _unit_resource_label_nudge(unit)
		if unit_node.position.y + resource_panel.position.y < 0:
			resource_panel.position.y = 0
		resource_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		resource_panel.add_theme_stylebox_override("panel", _unit_resource_style(unit))

		var resource_label := Label.new()
		resource_label.name = "Resources"
		resource_label.text = _unit_resource_text(unit)
		resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		resource_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		resource_label.custom_minimum_size = UNIT_RESOURCE_LABEL_SIZE
		resource_label.size = UNIT_RESOURCE_LABEL_SIZE
		resource_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		resource_label.add_theme_font_size_override("font_size", 10)
		resource_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78))
		resource_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
		resource_label.add_theme_constant_override("shadow_offset_x", 1)
		resource_label.add_theme_constant_override("shadow_offset_y", 1)
		resource_panel.add_child(resource_label)
		unit_node.add_child(resource_panel)

		unit_layer.add_child(unit_node)


func _visual_units_for_render() -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	var added: Dictionary = {}
	for unit: Dictionary in state["units"]:
		if temporary_visual_units.has(unit["id"]):
			units.append(temporary_visual_units[unit["id"]])
			added[unit["id"]] = true
			continue
		units.append(unit)
		added[unit["id"]] = true
	for unit_id: String in temporary_visual_units.keys():
		if added.has(unit_id):
			continue
		units.append(temporary_visual_units[unit_id])
	return units


func _unit_resource_text(unit: Dictionary) -> String:
	return "HP %s/%s\nAP %s  MP %s" % [
		unit["resources"].get("hp", "-"),
		unit["stats"].get("max_hp", "-"),
		unit["resources"].get("ap", "-"),
		unit["resources"].get("mp", "-"),
	]


func _unit_resource_style(unit: Dictionary) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.36, 0.62, 0.90) if unit.get("team", "") == "player" else Color(0.82, 0.30, 0.24)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 3
	style.content_margin_top = 1
	style.content_margin_right = 3
	style.content_margin_bottom = 1
	return style


func _unit_resource_label_nudge(unit: Dictionary) -> float:
	var x := int(unit.get("position", {}).get("x", 0))
	var team := str(unit.get("team", "enemy"))
	if team == "player":
		return -10.0 if x % 2 == 0 else -4.0
	return 10.0 if x % 2 == 0 else 4.0


func _unit_icon(unit: Dictionary) -> Texture2D:
	return unit_art.icon(unit, state, unit_facing, unit_visual_action, UNIT_ICON_SIZE)


func _unit_direction(unit: Dictionary) -> String:
	return unit_art.unit_direction(unit, state, unit_facing)


func _unit_texture_path(unit: Dictionary, direction: String, visual_action: String) -> String:
	return unit_art.texture_path(unit, direction, visual_action)


func _default_visual_action(unit: Dictionary) -> String:
	return unit_art.default_visual_action(unit, state)


func _unit_visual_config(unit: Dictionary) -> Dictionary:
	return unit_art.unit_visual_config(unit)


func _legacy_character_prefix(character: String) -> String:
	return unit_art.legacy_character_prefix(character)


func _nearest_living_opponent(unit: Dictionary) -> Dictionary:
	return unit_art.nearest_living_opponent(unit, state)


func _tile_distance(from_position: Dictionary, to_position: Dictionary) -> int:
	return unit_art.tile_distance(from_position, to_position)


func _direction_between(from_position: Dictionary, to_position: Dictionary) -> String:
	return unit_art.direction_between(from_position, to_position)


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


func _unit_by_id_in_state(source_state: Dictionary, unit_id: String) -> Dictionary:
	for unit: Dictionary in source_state.get("units", []):
		if unit["id"] == unit_id:
			return unit
	return {}


func _action_granted_to_unit(unit: Dictionary, action_id: String) -> bool:
	return CombatActionModel.action_granted_to_unit(state, unit, action_id)


func _action_ap_cost(unit: Dictionary, action_id: String, fallback: int) -> int:
	return CombatActionModel.action_ap_cost(state, unit, action_id, fallback)


func _action_profile_for_unit(unit: Dictionary, action_id: String) -> Dictionary:
	return CombatActionModel.action_profile_for_unit(state, unit, action_id)


func _loadout_items_for_unit(unit: Dictionary) -> Array[Dictionary]:
	return CombatActionModel.loadout_items_for_unit(state, unit)


func _skill_on_cooldown(unit: Dictionary, action_id: String) -> bool:
	return CombatActionModel.skill_on_cooldown(unit, action_id)


func _unit_display_name(unit_id: String) -> String:
	return CombatTextUtil.unit_display_name(state, unit_id)


func _position_label(position: Dictionary) -> String:
	return CombatTextUtil.position_label(position)


func _status_label(status: Dictionary) -> String:
	return CombatTextUtil.status_label(status)


func _rejection_label(reason: String) -> String:
	return CombatTextUtil.rejection_label(reason)


func _living_unit_at(position: Dictionary) -> Dictionary:
	for unit: Dictionary in state["units"]:
		if unit["resources"]["hp"] > 0 and _positions_equal(unit["position"], position):
			return unit
	return {}


func _visual_living_unit_at(position: Dictionary) -> Dictionary:
	for unit: Dictionary in state["units"]:
		if unit["resources"]["hp"] <= 0:
			continue
		if _positions_equal(unit["position"], position):
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
	var preview := _target_preview_for_position(position)
	if not preview.is_empty():
		lines.append("selected action: legal" if preview.get("rejection", "") == "" else "rejected: %s" % preview.get("rejection", "unknown"))
	return "\n".join(lines)


func _is_active_unit_at(position: Dictionary) -> bool:
	var active := _unit_by_id(state["turn_state"]["active_unit_id"])
	return not active.is_empty() and active["resources"]["hp"] > 0 and _positions_equal(active["position"], position)


func _is_legal_target_for_selected_action(position: Dictionary) -> bool:
	var preview := _target_preview_for_position(position)
	return not preview.is_empty() and preview.get("rejection", "") == ""


func _command_would_be_accepted(command: Dictionary) -> bool:
	return _command_rejection_reason(command) == ""


func _command_rejection_reason(command: Dictionary) -> String:
	var result: Dictionary = CombatResolver.simulate(_state_without_log(), [command])
	for event: Dictionary in _events_after_startup(result["state"]["event_log"]):
		if event["type"] == "command_rejected":
			return event.get("reason", "unknown")
	return ""


func _preview_move_event(position: Dictionary) -> Dictionary:
	var cached := _target_preview_for_position(position)
	if not cached.is_empty() and cached.has("move_event"):
		return cached["move_event"]
	var command := _build_command("move", {
		"type": "tile",
		"position": position,
	})
	var result: Dictionary = CombatResolver.simulate(_state_without_log(), [command])
	for event: Dictionary in _events_after_startup(result["state"]["event_log"]):
		if event["type"] == "unit_moved":
			return event
	return {}


func _build_target_preview_cache() -> Dictionary:
	var cache: Dictionary = {}
	if _combat_result() != "in_progress":
		return cache
	for y in range(int(state["grid"]["height"])):
		for x in range(int(state["grid"]["width"])):
			var position := {"x": x, "y": y}
			var command := _preview_command_for_position(position)
			if command.is_empty():
				continue
			cache[_position_key(position)] = _preview_for_command(command)
	return cache


func _preview_for_command(command: Dictionary) -> Dictionary:
	var result: Dictionary = CombatResolver.simulate(_state_without_log(), [command])
	var preview := {
		"rejection": "",
	}
	for event: Dictionary in _events_after_startup(result["state"]["event_log"]):
		if event["type"] == "command_rejected":
			preview["rejection"] = event.get("reason", "unknown")
			return preview
		if event["type"] == "unit_moved":
			preview["move_event"] = event
	return preview


func _target_preview_for_position(position: Dictionary) -> Dictionary:
	return target_preview_cache.get(_position_key(position), {})


func _clear_move_preview() -> void:
	pending_move_position.clear()
	pending_move_event.clear()


func _is_pending_move_destination(position: Dictionary) -> bool:
	return not pending_move_position.is_empty() and _positions_equal(pending_move_position, position)


func _is_pending_move_path(position: Dictionary) -> bool:
	if pending_move_event.is_empty():
		return false
	for step: Dictionary in pending_move_event.get("path", []):
		if _positions_equal(step, position):
			return true
	return false


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


func _position_key(position: Dictionary) -> String:
	return "%s,%s" % [int(position.get("x", 0)), int(position.get("y", 0))]


func _unit_visual_pixel_position(unit: Dictionary) -> Vector2:
	if visual_positions_px.has(unit["id"]):
		return visual_positions_px[unit["id"]]
	return _position_to_unit_top_left(unit["position"])


func _position_to_unit_top_left(position: Dictionary) -> Vector2:
	var tile_origin := Vector2(
		int(position["x"]) * (TILE_SIZE + TILE_GAP),
		int(position["y"]) * (TILE_SIZE + TILE_GAP)
	)
	return tile_origin + Vector2(TILE_SIZE - UNIT_ICON_SIZE.x, TILE_SIZE - UNIT_ICON_SIZE.y) / 2.0


func _combat_result() -> String:
	return CombatActionModel.combat_result(state)
