extends Control

const AssetCatalog := preload("res://scripts/presentation/shared/asset_catalog.gd")
const EnvironmentArt := preload("res://scripts/presentation/combat/environment_art.gd")
const PixelSkin := preload("res://scripts/presentation/shared/pixel_skin.gd")
const CombatPanelSkin := preload("res://scripts/presentation/combat/combat_panel_skin.gd")
const ResourceMeterScene := preload("res://scenes/ui/ResourceMeter.tscn")
const AuthoringDraft := preload("res://scripts/presentation/combat/authoring_draft.gd")
var authoring_draft: Dictionary = {}
var pixel_skin := PixelSkin.new()
var panel_skin := CombatPanelSkin.new()
const BattleChrome := preload("res://scripts/presentation/combat/battle_chrome.gd")
var battle_chrome: RefCounted

const CombatResolver := preload("res://scripts/domain/combat_resolver.gd")
const CombatTextUtil := preload("res://scripts/presentation/combat/combat_text.gd")
const CombatUnitArtDb := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const CombatActionModel := preload("res://scripts/presentation/combat/combat_action_model.gd")
const CombatScenarioCatalog := preload("res://scripts/presentation/combat/combat_scenario_catalog.gd")
const CombatFloatingText := preload("res://scripts/presentation/combat/combat_floating_text.gd")
const CombatTargetingPreview := preload("res://scripts/presentation/combat/combat_targeting_preview.gd")
const CombatUnitVisualState := preload("res://scripts/presentation/combat/combat_unit_visual_state.gd")
const DrawnTimeline := preload("res://scripts/presentation/combat/drawn_combat_timeline.gd")
var idle_elapsed: Dictionary = {}
var active_motion_tween: Tween

const DEFAULT_ENCOUNTER_PATH := CombatScenarioCatalog.DEFAULT_ENCOUNTER_PATH
const COMBAT_UI_SLOT_NORMAL_PATH := "res://assets/ui/combat/processed/slots/slot_normal.png"
const COMBAT_UI_SLOT_SELECTED_PATH := "res://assets/ui/combat/processed/slots/slot_selected.png"
const COMBAT_UI_SLOT_DISABLED_PATH := "res://assets/ui/combat/processed/slots/slot_disabled.png"
const COMBAT_UI_BAR_HP_PATH := "res://assets/ui/combat/processed/bars/mini_bar_hp.png"
const COMBAT_UI_BAR_AP_PATH := "res://assets/ui/combat/processed/bars/mini_bar_ap.png"
const COMBAT_UI_BAR_MP_PATH := "res://assets/ui/combat/processed/bars/mini_bar_mp.png"
const OVERLAY_RESOURCE_PANEL_SIZE := Vector2(394, 202)
const OVERLAY_RESOURCE_BAR_SIZE := Vector2(384, 56)
const OVERLAY_LOG_PANEL_SIZE := Vector2(460, 132)
const OVERLAY_MARGIN := 14.0
const ACTION_BUTTON_SIZE := Vector2(132, 118)
const ACTION_BUTTON_ICON_MAX_WIDTH := 66
const BOTTOM_HUD_MIN_HEIGHT := 142
const ACTION_ICON_PATHS := {
	"move": "res://assets/ui/combat/processed/icons/icon_boot.png",
	"basic_attack": "res://assets/ui/combat/processed/icons/icon_sword.png",
	"power_strike": "res://assets/ui/combat/processed/icons/icon_power_attack.png",
	"deep_cut": "res://assets/ui/combat/processed/icons/icon_cur_deep.png",
	"guard_break": "res://assets/ui/combat/processed/icons/icon_guard_break.png",
	"ranged_attack": "res://assets/ui/combat/processed/icons/icon_bow.png",
	"aimed_shot": "res://assets/ui/combat/processed/icons/icon_aimed_shot.png",
	"shield_wall": "res://assets/ui/combat/processed/icons/icon_shield_wall.png",
	"defend": "res://assets/ui/combat/processed/icons/icon_shield.png",
	"end_turn": "res://assets/ui/combat/processed/icons/icon_hourglass.png",
}
const ACTION_ICON_FALLBACK_PATHS := {
	"power_strike": "res://assets/ui/combat/processed/icons/icon_sword.png",
	"aimed_shot": "res://assets/ui/combat/processed/icons/icon_bow.png",
	"shield_wall": "res://assets/ui/combat/processed/icons/icon_shield.png",
}
const GRASS_FLOOR_TEXTURE_PATHS := [
	"res://assets/combat/terrain/grass/meadow_grass_floor_00.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_01.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_02.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_03.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_04.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_05.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_06.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_07.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_08.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_09.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_10.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_11.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_12.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_13.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_14.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_15.png",
]
const UNIT_ICON_SIZE := Vector2i(384, 240)
const UNIT_RESOURCE_LABEL_SIZE := Vector2(128, 54)
const UNIT_RESOURCE_LABEL_OFFSET_Y := -56.0
const UNIT_STATUS_ICON_SIZE := Vector2(20, 20)
const UNIT_STATUS_ICON_GAP := 2.0
const UNIT_TARGET_PREVIEW_LABEL_SIZE := Vector2(152, 60)
const UNIT_TARGET_PREVIEW_GAP := 3.0
const TILE_WIDTH := 140
const TILE_HEIGHT := 104
const HIGHGROUND_UNIT_OFFSET_Y := -30.0
const HIGHGROUND_UNIT_BASE_SIZE := Vector2(116, 24)
const HIGHGROUND_UNIT_BASE_OFFSET := Vector2(46, 168)
const GRASS_PATCH_SIZE := 64
const DECORATION_SIZE_BY_KIND := {
	"grass_tuft": Vector2(52, 52),
	"tree_stump": Vector2(62, 62),
	"mossy_boulder": Vector2(76, 76),
	"fallen_branch": Vector2(84, 84),
	"processed_nature_small": Vector2(104, 82),
	"processed_nature_medium": Vector2(148, 118),
	"processed_nature_wide": Vector2(210, 112),
	"processed_nature_tall": Vector2(220, 330),
	"processed_dungeon_small": Vector2(110, 92),
	"processed_dungeon_medium": Vector2(156, 128),
	"processed_dungeon_wide": Vector2(190, 112),
	"processed_dungeon_tall": Vector2(150, 280),
	"dungeon_small": Vector2(72, 72),
	"dungeon_medium": Vector2(88, 88),
	"dungeon_large": Vector2(104, 104),
	"default": Vector2(64, 64),
}
const TILE_GAP := 0
const MOVE_STEP_SECONDS := 0.52
const WALK_CYCLE_SECONDS := 0.11
const COMBAT_LUNGE_PIXELS := 20.0
const COMBAT_WINDUP_SECONDS := 0.28
const COMBAT_RETURN_SECONDS := 0.28
const COMBAT_CYCLE_SECONDS := 0.09
const HIT_SHAKE_PIXELS := 7.0
const HIT_SHAKE_SECONDS := 0.055
const HIT_CYCLE_SECONDS := 0.08
const DEATH_FALL_PIXELS := 16.0
const DEATH_SECONDS := 0.65
const DEATH_HOLD_SECONDS := 0.45
const DEATH_CYCLE_SECONDS := 0.12
const CORPSE_MODULATE := Color(0.74, 0.68, 0.62, 0.86)
const PRELOAD_UNIT_VISUAL_ACTIONS := ["pose", "combat_idle", "walk", "combat", "hit", "death", "status_reaction"]
const PRELOAD_UNIT_DIRECTIONS := ["north", "north_east", "east", "south_east", "south", "south_west", "west", "north_west"]
const UNIT_LAYER_Z_INDEX := 100
const FLOATING_TEXT_LAYER_Z_INDEX := 2000
const BOARD_OVERLAY_LAYER_Z_INDEX := 3000
const DECORATION_BY_POSITION := {
	"1,6": "res://assets/combat/terrain/processed/nature/nature_1/nature_1_03.png",
	"6,6": "res://assets/combat/terrain/processed/nature/nature_2/nature_2_02.png",
}
const BLOCKED_DECORATION_PATHS := [
	"res://assets/combat/terrain/processed/nature/nature_1/nature_1_00.png",
	"res://assets/combat/terrain/processed/nature/nature_1/nature_1_06.png",
	"res://assets/combat/terrain/processed/nature/nature_1/nature_1_08.png",
	"res://assets/combat/terrain/processed/nature/nature_2/nature_2_06.png",
]
const COVER_DECORATION_PATHS := [
	"res://assets/combat/terrain/processed/nature/nature_1/nature_1_01.png",
	"res://assets/combat/terrain/processed/nature/nature_1/nature_1_02.png",
	"res://assets/combat/terrain/processed/nature/nature_1/nature_1_05.png",
	"res://assets/combat/terrain/processed/nature/nature_1/nature_1_07.png",
]
const HIGHLAND_DECORATION_PATHS := [
	"res://assets/combat/terrain/processed/nature/nature_1/nature_1_09.png",
	"res://assets/combat/terrain/processed/nature/nature_1/nature_1_10.png",
	"res://assets/combat/terrain/processed/nature/nature_2/nature_2_04.png",
]
const DUNGEON_BLOCKED_DECORATION_PATHS := [
	"res://assets/combat/terrain/processed/dungeon/dung_1/dung_1_00.png",
	"res://assets/combat/terrain/processed/dungeon/dung_1/dung_1_02.png",
	"res://assets/combat/terrain/processed/dungeon/dung_1/dung_1_04.png",
	"res://assets/combat/terrain/processed/dungeon/dung_2/dung_2_06.png",
	"res://assets/combat/terrain/processed/dungeon/dung_2/dung_2_08.png",
]
const DUNGEON_COVER_DECORATION_PATHS := [
	"res://assets/combat/terrain/processed/dungeon/dung_1/dung_1_06.png",
	"res://assets/combat/terrain/processed/dungeon/dung_1/dung_1_07.png",
	"res://assets/combat/terrain/processed/dungeon/dung_1/dung_1_08.png",
	"res://assets/combat/terrain/processed/dungeon/dung_2/dung_2_03.png",
]
const DUNGEON_HIGHLAND_DECORATION_PATHS := [
	"res://assets/combat/terrain/processed/dungeon/dung_1/dung_1_03.png",
	"res://assets/combat/terrain/processed/dungeon/dung_1/dung_1_05.png",
	"res://assets/combat/terrain/processed/dungeon/dung_2/dung_2_04.png",
]
const DUNGEON_FLOOR_DECORATION_BY_POSITION := {
	"1,6": "res://assets/combat/terrain/processed/dungeon/dung_1/dung_1_01.png",
	"6,6": "res://assets/combat/terrain/processed/dungeon/dung_2/dung_2_10.png",
	"14,8": "res://assets/combat/terrain/processed/dungeon/dung_2/dung_2_09.png",
}
const TERRAIN_BASE_COLORS := {
	"floor": Color(0.10, 0.30, 0.10, 1.0),
	"blocked": Color(0.09, 0.25, 0.09, 1.0),
	"cover_low": Color(0.11, 0.29, 0.10, 1.0),
	"highground": Color(0.13, 0.31, 0.09, 1.0),
}
const ACTION_LABELS := CombatTextUtil.ACTION_LABELS

@onready var board_root: Control = %BoardRoot
@onready var board_backdrop: Panel = %BoardBackdrop
@onready var board_viewport: Control = %BoardViewport
@onready var encounter_panel: PanelContainer = %EncounterPanel
@onready var board_terrain: TextureRect = %BoardTerrain
@onready var grid_container: GridContainer = %GridContainer
@onready var unit_layer: Control = %UnitLayer
@onready var floating_text_layer: Control = %FloatingTextLayer
@onready var action_panel: PanelContainer = %ActionPanel
@onready var bottom_hud: PanelContainer = %BottomHud
@onready var action_title_label: Label = %ActionTitleLabel
@onready var action_detail_label: Label = %ActionDetailLabel
@onready var action_feed_label: Label = %ActionFeedLabel
@onready var status_label: Label = %StatusLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var legend_label: Label = %LegendLabel
@onready var unit_list_label: Label = %UnitListLabel
@onready var inspect_label: Label = %InspectLabel
@onready var event_log_label: Label = %EventLogLabel
@onready var command_buttons: HBoxContainer = %CommandButtons
@onready var turn_order_panel: PanelContainer = %TurnOrderPanel
@onready var turn_order_label: Label = %TurnOrderLabel

var board_overlay_layer: Control = null
var overlay_resource_panel: PanelContainer = null
var overlay_resource_label: Label = null
var overlay_resource_bars: Dictionary = {}
var overlay_log_panel: PanelContainer = null
var overlay_log_label: Label = null
var state: Dictionary = {}
var command_index := 1
var selected_action := "move"
var last_feedback := "Select an action."
var current_encounter_path := DEFAULT_ENCOUNTER_PATH
var selected_scenario_id := "full_combat_showcase"
var selected_position: Dictionary = {}
var hovered_unit_id := ""
var pending_move_position: Dictionary = {}
var pending_move_event: Dictionary = {}
var unit_facing: Dictionary = {}
var unit_visual_action: Dictionary = {}
var unit_texture_cache: Dictionary = {}
var tile_texture_cache: Dictionary = {}
var ui_texture_cache: Dictionary = {}
var grass_image_cache: Dictionary = {}
var terrain_decoration_texture_cache: Dictionary = {}
var preloaded_unit_visual_keys: Dictionary = {}
var rendered_grid_key := ""
var temporary_visual_units: Dictionary = {}
var visual_positions_px: Dictionary = {}
var temporary_resource_overrides: Dictionary = {}
var visual_generation := 0
var animation_locked := false
var current_action_title := "Combat ready"
var current_action_detail := "Select an action or step the next turn."
var action_feed: Array[String] = []
var unit_art := CombatUnitArtDb.new()
var target_preview_cache: Dictionary = {}
var presentation_cache_ready := false


func _ready() -> void:
	board_viewport.resized.connect(_resize_board)
	if get_tree().has_meta(AuthoringDraft.DRAFT_META):
		authoring_draft = get_tree().get_meta(AuthoringDraft.DRAFT_META).duplicate(true)
		get_tree().remove_meta(AuthoringDraft.DRAFT_META)
	_ensure_board_overlay_controls()
	_configure_board_layers()
	_apply_pixel_theme()
	if authoring_draft.is_empty() and _run_session().has_pending_combat_launch():
		current_encounter_path = _run_session().combat_encounter_path()
		selected_scenario_id = "dungeon_launch"
	elif authoring_draft.is_empty():
		var requested_scenario := str(ProjectSettings.get_setting("debug/qa/combat_scenario", ""))
		var requested_path := CombatScenarioCatalog.path_for_id(requested_scenario)
		if requested_path != "":
			current_encounter_path = requested_path
			selected_scenario_id = requested_scenario
	_reset_debug_encounter()
	battle_chrome = BattleChrome.new()
	battle_chrome.setup(self)
	var idle_timer := Timer.new()
	idle_timer.wait_time = 0.05
	idle_timer.timeout.connect(_advance_original_idle)
	add_child(idle_timer)
	idle_timer.start()


func _advance_original_idle() -> void:
	if animation_locked:
		return
	for unit: Dictionary in state.get("units", []):
		if int(unit.resources.hp) <= 0 or unit_art.sprite_size(unit, UNIT_ICON_SIZE) == UNIT_ICON_SIZE:
			continue
		var current := str(unit_visual_action.get(unit.id, "pose:0"))
		if not current.begins_with("pose") and not current.begins_with("combat_idle"):
			continue
		var action:=unit_art.default_visual_action(unit,state)
		var frame:=int(current.get_slice(":",1)) if current.get_slice(":",0)==action else 0
		var elapsed:=float(idle_elapsed.get(unit.id,0.0))+0.05
		if current.get_slice(":",0)!=action:elapsed=0.0
		var changed:=current.get_slice(":",0)!=action
		var count:=unit_art.processed_sheet_frame_count(str(_unit_visual_config(unit).character),action)
		while elapsed>=unit_art.frame_seconds(unit,action,0.2,frame):
			elapsed-=unit_art.frame_seconds(unit,action,0.2,frame);frame=(frame+1)%count;changed=true
		idle_elapsed[unit.id]=elapsed
		if changed:
			unit_visual_action[unit.id]="%s:%s" % [action,frame]
			_refresh_unit_sprite(unit.id)


func _reset_debug_encounter() -> void:
	visual_generation+=1
	animation_locked=false
	if active_motion_tween!=null and active_motion_tween.is_valid():active_motion_tween.kill()
	active_motion_tween=null
	state = _load_json(current_encounter_path) if authoring_draft.is_empty() else authoring_draft.duplicate(true)
	if authoring_draft.is_empty() and _run_session().has_pending_combat_launch():
		state = _run_session().apply_launch_metadata(state)
	state["event_log"] = []
	command_index = 1
	selected_action = "move"
	hovered_unit_id = ""
	_clear_move_preview()
	unit_facing.clear()
	idle_elapsed.clear()
	unit_visual_action.clear()
	temporary_visual_units.clear()
	visual_positions_px.clear()
	temporary_resource_overrides.clear()
	_clear_floating_text()
	preloaded_unit_visual_keys.clear()
	rendered_grid_key = ""
	action_feed.clear()
	current_action_title = "Battle ready"
	current_action_detail = "Choose an action, then pick a tile or target."
	last_feedback = "Encounter reset."
	_clear_units()
	var result := CombatResolver.simulate(state, [])
	state = result["state"]
	selected_position = _unit_by_id(state["turn_state"]["active_unit_id"]).get("position", {})
	_prepare_presentation_cache()
	_render()


func _input(event: InputEvent) -> void:
	if not authoring_draft.is_empty() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		get_tree().set_meta(AuthoringDraft.DRAFT_META, authoring_draft.duplicate(true))
		get_tree().change_scene_to_file("res://scenes/combat/CombatMapEditor.tscn")


func _render() -> void:
	%TitleLabel.text = "Ash-road Raiders" if str(state.get("id", "")) == "ash_road_raiders" else "Old Mine Skirmish"
	if str(state.get("id", "")) == "drawn_roster_skirmish":
		%TitleLabel.text = "Painted Six - Old Mine"
	_render_grid()
	_render_units()

	_render_action_panel()
	_render_board_overlay()
	_render_status()
	_render_feedback()
	_render_legend()
	_render_unit_list()
	_render_turn_order()
	_render_inspect()
	_render_event_log()
	_render_command_buttons()
	if battle_chrome!=null: battle_chrome.refresh(self)


func _prepare_presentation_cache() -> void:
	if not animation_locked:
		_sync_living_unit_facings_toward_opponents()
	_sync_selected_action_with_visible_actions(_visible_primary_action_ids())
	target_preview_cache = _build_target_preview_cache()
	_preload_presentation_assets()
	presentation_cache_ready = true


func _sync_living_unit_facings_toward_opponents() -> void:
	for unit: Dictionary in state.get("units", []):
		var unit_id := str(unit.get("id", ""))
		if unit_id == "" or int(unit.get("resources", {}).get("hp", 0)) <= 0:
			continue
		var nearest := _nearest_living_opponent(unit)
		if nearest.is_empty():
			unit_facing.erase(unit_id)
			continue
		unit_facing[unit_id] = _direction_between(unit.get("position", {}), nearest.get("position", {}))


func _preload_presentation_assets() -> void:
	for tile: Dictionary in state.get("grid", {}).get("tiles", []):
		var position := {"x": int(tile["x"]), "y": int(tile["y"])}
		_tile_decoration_texture(_tile_decoration_path(position))
	_board_terrain_texture()

	for unit: Dictionary in state.get("units", []):
		_preload_unit_visuals(unit)


func _preload_unit_visuals(unit: Dictionary) -> void:
	var unit_id := str(unit.get("id", ""))
	if unit_id == "":
		return
	var preload_key := "%s:%s:%s" % [unit_id, UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y]
	if preloaded_unit_visual_keys.has(preload_key):
		return
	for direction: String in PRELOAD_UNIT_DIRECTIONS:
		var facing_override := {}
		facing_override[unit_id] = direction
		for visual_action: String in PRELOAD_UNIT_VISUAL_ACTIONS:
			var visual_actions := {}
			visual_actions[unit_id] = visual_action
			unit_art.icon(unit, state, facing_override, visual_actions, UNIT_ICON_SIZE)
	preloaded_unit_visual_keys[preload_key] = true


func _render_grid() -> void:
	grid_container.columns = int(state["grid"]["width"])
	grid_container.add_theme_constant_override("h_separation", TILE_GAP)
	grid_container.add_theme_constant_override("v_separation", TILE_GAP)
	_resize_board()
	board_terrain.texture = _board_terrain_texture()

	var grid_key := _grid_render_key()
	var expected_tile_count := int(state["grid"]["width"]) * int(state["grid"]["height"])
	if rendered_grid_key != grid_key or grid_container.get_child_count() != expected_tile_count:
		_clear_grid()
		for y in range(int(state["grid"]["height"])):
			for x in range(int(state["grid"]["width"])):
				grid_container.add_child(_build_tile({"x": x, "y": y}))
		rendered_grid_key = grid_key
		return

	_update_grid_dynamic_tiles()


func _update_grid_dynamic_tiles() -> void:
	var width := int(state["grid"]["width"])
	var height := int(state["grid"]["height"])
	for y in range(height):
		for x in range(width):
			var index := y * width + x
			var tile := grid_container.get_child(index) as Button
			if tile == null:
				continue
			_update_tile_dynamic(tile, {"x": x, "y": y})


func _grid_render_key() -> String:
	var parts: Array[String] = [
		str(state.get("background_path", "")),
		str(state.get("grid", {}).get("width", 0)),
		str(state.get("grid", {}).get("height", 0)),
	]
	for tile: Dictionary in state.get("grid", {}).get("tiles", []):
		var position := {"x": int(tile["x"]), "y": int(tile["y"])}
		parts.append("%s:%s:%s" % [_position_key(position), str(tile.get("type", "")), _tile_decoration_path(position)])
	return "|".join(parts)


func _build_tile(position: Dictionary) -> Button:
	var tile := Button.new()
	tile.disabled = animation_locked
	tile.custom_minimum_size = Vector2(TILE_WIDTH, TILE_HEIGHT)
	tile.size = Vector2(TILE_WIDTH, TILE_HEIGHT)
	tile.flat = true
	tile.text = ""
	tile.tooltip_text = _tile_tooltip(position)
	_apply_tile_button_style(tile)
	tile.pressed.connect(func() -> void:
		_on_tile_pressed(position)
	)
	tile.mouse_entered.connect(func() -> void:
		_set_hovered_unit(str(_tooltip_unit_at(position).get("id", "")))
	)
	tile.mouse_exited.connect(func() -> void:
		_set_hovered_unit("")
	)

	var terrain_type := _tile_type(position)
	var decoration_path := _tile_decoration_path(position)
	var terrain_tint := _terrain_tint_color(terrain_type, decoration_path)
	if terrain_tint.a > 0.001:
		var tint := ColorRect.new()
		tint.name = "TerrainTint"
		tint.color = terrain_tint
		tint.custom_minimum_size = Vector2(TILE_WIDTH, TILE_HEIGHT)
		tint.size = Vector2(TILE_WIDTH, TILE_HEIGHT)
		tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(tint)

	if terrain_type == "highground":
		var ledge:=TextureRect.new()
		ledge.name="RaisedTerrainArt"
		ledge.texture=EnvironmentArt.ledge(_terrain_theme())
		ledge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		ledge.size=Vector2(TILE_WIDTH,TILE_HEIGHT)
		ledge.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(ledge)

	var decoration_texture := _tile_decoration_texture(decoration_path)
	if decoration_texture != null:
		var decoration_size := _decoration_size(decoration_path)
		var decoration := TextureRect.new()
		decoration.name = "TerrainDecoration"
		decoration.texture = decoration_texture
		decoration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		decoration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		decoration.position = (Vector2(TILE_WIDTH, TILE_HEIGHT) - decoration_size) / 2.0
		var prop:=EnvironmentArt.prop(decoration_path)
		if not prop.is_empty():
			var ground_y:=TILE_HEIGHT+int(HIGHGROUND_UNIT_OFFSET_Y if terrain_type=="highground" else 0)
			decoration.position=Vector2(TILE_WIDTH/2.0,ground_y)-Vector2(prop.pivot[0],prop.pivot[1])
		decoration.custom_minimum_size = decoration_size
		decoration.size = decoration_size
		decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(decoration)
	elif terrain_type in ["blocked","cover_low"]:
		var key: String=("wall" if terrain_type=="blocked" else "crate") if _is_dungeon_board() else ("boulder" if terrain_type=="blocked" else "fallen_log")
		var prop: Dictionary=EnvironmentArt.data().assets[key]
		var silhouette:=TextureRect.new()
		silhouette.name="SemanticTerrainArt"
		silhouette.texture=AssetCatalog.texture(prop.path)
		silhouette.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		silhouette.size=Vector2(prop.size[0],prop.size[1])
		silhouette.position=Vector2(TILE_WIDTH/2.0,TILE_HEIGHT)-Vector2(prop.pivot[0],prop.pivot[1])
		silhouette.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(silhouette)

	_update_tile_dynamic(tile, position)
	return tile


func _update_tile_dynamic(tile: Button, position: Dictionary) -> void:
	tile.disabled = animation_locked
	tile.tooltip_text = _tile_tooltip(position)
	_remove_child_if_present(tile, "Overlay")
	_remove_child_if_present(tile, "PreviewLabel")

	var unit := _living_unit_at(position)
	var overlay_color := _tile_overlay_color(position, unit)
	if overlay_color.a > 0.001:
		var overlay := PanelContainer.new()
		overlay.name = "Overlay"
		overlay.custom_minimum_size = Vector2(TILE_WIDTH, TILE_HEIGHT)
		overlay.size = Vector2(TILE_WIDTH, TILE_HEIGHT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_theme_stylebox_override("panel", _tile_overlay_style(position, unit, overlay_color))
		tile.add_child(overlay)

	var preview_label_text := _tile_preview_label(position)
	if preview_label_text != "":
		var preview_label := Label.new()
		preview_label.name = "PreviewLabel"
		preview_label.text = preview_label_text
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview_label.custom_minimum_size = Vector2(TILE_WIDTH, TILE_HEIGHT)
		preview_label.size = Vector2(TILE_WIDTH, TILE_HEIGHT)
		preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_label.add_theme_font_size_override("font_size", 10)
		preview_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.48))
		preview_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.02, 1.0))
		preview_label.add_theme_constant_override("shadow_offset_x", 1)
		preview_label.add_theme_constant_override("shadow_offset_y", 1)
		tile.add_child(preview_label)


func _remove_child_if_present(parent: Node, child_name: String) -> void:
	var child := parent.get_node_or_null(child_name)
	if child != null:
		parent.remove_child(child)
		child.queue_free()


func _apply_tile_button_style(tile: Button) -> void:
	var empty_style := StyleBoxEmpty.new()
	tile.add_theme_stylebox_override("normal", empty_style)
	tile.add_theme_stylebox_override("hover", empty_style)
	tile.add_theme_stylebox_override("pressed", empty_style)
	tile.add_theme_stylebox_override("disabled", empty_style)
	tile.add_theme_stylebox_override("focus", empty_style)


func _board_terrain_texture() -> Texture2D:
	return EnvironmentArt.board(state,Vector2i(int(state.grid.width)*TILE_WIDTH,int(state.grid.height)*TILE_HEIGHT),_terrain_theme())


func _legacy_board_terrain_texture() -> Texture2D:
	var background_path := str(state.get("background_path", ""))
	if background_path != "":
		return _static_board_background_texture(background_path)

	var cache_key := _board_terrain_cache_key()
	if tile_texture_cache.has(cache_key):
		return tile_texture_cache[cache_key]

	var width := int(state["grid"]["width"]) * TILE_WIDTH
	var height := int(state["grid"]["height"]) * TILE_HEIGHT
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(TERRAIN_BASE_COLORS["floor"])

	for tile_data: Dictionary in state["grid"]["tiles"]:
		var position := {"x": int(tile_data["x"]), "y": int(tile_data["y"])}
		var tile_origin := Vector2i(position["x"] * TILE_WIDTH, position["y"] * TILE_HEIGHT)
		image.fill_rect(Rect2i(tile_origin, Vector2i(TILE_WIDTH, TILE_HEIGHT)), _terrain_base_color(str(tile_data["type"])))
		for patch_index in range(5):
			var patch_image := _grass_patch_image(position, patch_index)
			var patch_position := tile_origin + Vector2i(_grass_patch_position(position, patch_index))
			_blend_patch_clipped(image, patch_image, patch_position)

	var texture := ImageTexture.create_from_image(image)
	tile_texture_cache[cache_key] = texture
	return texture


func _static_board_background_texture(path: String) -> Texture2D:
	var cache_key := "static_board_background:%s" % path
	if tile_texture_cache.has(cache_key):
		return tile_texture_cache[cache_key]
	var image := AssetCatalog.image_copy(path)
	if image == null:
		push_error("Cannot load combat board background: %s" % path)
		return null
	var expected_size := Vector2i(
		int(state["grid"]["width"]) * TILE_WIDTH,
		int(state["grid"]["height"]) * TILE_HEIGHT
	)
	if image.get_size() != expected_size:
		image.resize(expected_size.x, expected_size.y, Image.INTERPOLATE_NEAREST)
	var texture := ImageTexture.create_from_image(image)
	tile_texture_cache[cache_key] = texture
	return texture


func _board_terrain_cache_key() -> String:
	var parts: Array[String] = [
		"board_terrain",
		str(state.get("id", "unknown")),
		str(state.get("grid", {}).get("width", 0)),
		str(state.get("grid", {}).get("height", 0)),
		str(TILE_WIDTH),
		str(TILE_HEIGHT),
	]
	for tile_data: Dictionary in state.get("grid", {}).get("tiles", []):
		parts.append("%s,%s,%s" % [tile_data.get("x", 0), tile_data.get("y", 0), tile_data.get("type", "")])
	return "|".join(parts)


func _grass_patch_image(position: Dictionary, patch_index: int) -> Image:
	var index := _grass_floor_index({
		"x": int(position.get("x", 0)) + patch_index * 3,
		"y": int(position.get("y", 0)) + patch_index * 5,
	})
	if grass_image_cache.has(index):
		return grass_image_cache[index]
	var path: String = GRASS_FLOOR_TEXTURE_PATHS[index]
	var image := AssetCatalog.image_copy(path)
	if image == null:
		push_error("Cannot load grass floor image: %s" % path)
		return Image.create(GRASS_PATCH_SIZE, GRASS_PATCH_SIZE, false, Image.FORMAT_RGBA8)
	grass_image_cache[index] = image
	return image


func _blend_patch_clipped(target: Image, patch: Image, destination: Vector2i) -> void:
	var src_position := Vector2i.ZERO
	var dst_position := destination
	var size := patch.get_size()

	if dst_position.x < 0:
		src_position.x = -dst_position.x
		size.x -= src_position.x
		dst_position.x = 0
	if dst_position.y < 0:
		src_position.y = -dst_position.y
		size.y -= src_position.y
		dst_position.y = 0
	if dst_position.x + size.x > target.get_width():
		size.x = target.get_width() - dst_position.x
	if dst_position.y + size.y > target.get_height():
		size.y = target.get_height() - dst_position.y
	if size.x <= 0 or size.y <= 0:
		return

	target.blend_rect(patch, Rect2i(src_position, size), dst_position)


func _grass_patch_position(position: Dictionary, patch_index: int) -> Vector2:
	var x := int(position.get("x", 0))
	var y := int(position.get("y", 0))
	var layouts := [
		Vector2(-8, -8),
		Vector2(38, -6),
		Vector2(-6, 38),
		Vector2(40, 40),
		Vector2(18, 18),
	]
	var jitter_x := float(((x * 17 + y * 7 + patch_index * 11) % 9) - 4)
	var jitter_y := float(((x * 5 + y * 19 + patch_index * 13) % 9) - 4)
	return layouts[patch_index] + Vector2(jitter_x, jitter_y)


func _grass_floor_index(position: Dictionary) -> int:
	var x := int(position.get("x", 0))
	var y := int(position.get("y", 0))
	return absi((x * 7 + y * 11 + x * y * 3) % GRASS_FLOOR_TEXTURE_PATHS.size())


func _terrain_base_color(terrain_type: String) -> Color:
	return TERRAIN_BASE_COLORS.get(terrain_type, TERRAIN_BASE_COLORS["floor"])


func _terrain_tint_color(terrain_type: String, decoration_path: String = "") -> Color:
	if terrain_type in ["blocked","cover_low"] and decoration_path.is_empty():return Color.TRANSPARENT
	if decoration_path != "" and terrain_type != "highground":
		return Color(0, 0, 0, 0)
	if _is_dungeon_board():
		match terrain_type:
			"blocked":
				return Color(0.02, 0.02, 0.03, 0.28)
			"highground":
				return Color(0, 0, 0, 0)
			"cover_low":
				return Color(0.45, 0.43, 0.38, 0.16)
			_:
				return Color(0, 0, 0, 0)
	match terrain_type:
		"blocked":
			return Color(0.05, 0.04, 0.03, 0.24)
		"highground":
			return Color(0, 0, 0, 0)
		"cover_low":
			return Color(0.55, 0.39, 0.20, 0.13)
		_:
			return Color(0, 0, 0, 0)


func _tile_decoration_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if terrain_decoration_texture_cache.has(path):
		return terrain_decoration_texture_cache[path]
	var texture := EnvironmentArt.texture(path)
	terrain_decoration_texture_cache[path] = texture
	return texture


func _decoration_size(path: String) -> Vector2:
	var prop:=EnvironmentArt.prop(path)
	if not prop.is_empty():return Vector2(prop.size[0],prop.size[1])
	var max_size: Vector2 = DECORATION_SIZE_BY_KIND.get(_decoration_kind(path), DECORATION_SIZE_BY_KIND["default"])
	if path.contains("/terrain/processed/"):
		var texture := _tile_decoration_texture(path)
		if texture == null:
			return max_size
		var source_size := texture.get_size()
		if source_size.x <= 0.0 or source_size.y <= 0.0:
			return max_size
		var scale: float = minf(max_size.x / source_size.x, max_size.y / source_size.y)
		return Vector2(source_size.x * scale, source_size.y * scale)
	return max_size


func _decoration_kind(path: String) -> String:
	if path.contains("/terrain/processed/nature/"):
		if path.contains("nature_1_00"):
			return "processed_nature_tall"
		if path.contains("nature_1_06") or path.contains("nature_2_00") or path.contains("nature_2_08") or path.contains("nature_2_09"):
			return "processed_nature_wide"
		if path.contains("nature_1_03") or path.contains("nature_1_04") or path.contains("nature_2_02"):
			return "processed_nature_small"
		return "processed_nature_medium"
	if path.contains("/terrain/processed/dungeon/"):
		if path.contains("dung_1_00") or path.contains("dung_1_01") or path.contains("dung_1_05") or path.contains("dung_2_04"):
			return "processed_dungeon_tall"
		if path.contains("dung_1_02") or path.contains("dung_1_04") or path.contains("dung_1_10") or path.contains("dung_2_06"):
			return "processed_dungeon_wide"
		if path.contains("dung_2_03") or path.contains("dung_2_07") or path.contains("dung_2_10"):
			return "processed_dungeon_small"
		return "processed_dungeon_medium"
	if path.contains("/combat/dungeons/props/"):
		if path.contains("arched_stone_door") or path.contains("iron_spike_fence") or path.contains("bone_spike_totem"):
			return "dungeon_large"
		if path.contains("stone_chest") or path.contains("stone_coffin") or path.contains("wooden_treasure_chest") or path.contains("stone_spike_barricade"):
			return "dungeon_medium"
		return "dungeon_small"
	if path.contains("/grass_tuft/"):
		return "grass_tuft"
	if path.contains("/tree_stump/"):
		return "tree_stump"
	if path.contains("/mossy_boulder/"):
		return "mossy_boulder"
	if path.contains("/fallen_branch/"):
		return "fallen_branch"
	return "default"


func _tile_decoration_path(position: Dictionary) -> String:
	var key := "%s,%s" % [position.get("x", 0), position.get("y", 0)]
	if state.has("terrain_decorations"):
		for decoration: Dictionary in state.get("terrain_decorations", []):
			if int(decoration.get("x", -1)) == int(position.get("x", 0)) and int(decoration.get("y", -1)) == int(position.get("y", 0)):
				return str(decoration.get("path", ""))
		return ""
	var terrain_type := _tile_type(position)
	if _is_dungeon_board():
		if terrain_type == "blocked":
			return DUNGEON_BLOCKED_DECORATION_PATHS[_decoration_index(position, DUNGEON_BLOCKED_DECORATION_PATHS.size())]
		if terrain_type == "cover_low":
			return DUNGEON_COVER_DECORATION_PATHS[_decoration_index(position, DUNGEON_COVER_DECORATION_PATHS.size())]
		if terrain_type == "highground":
			return DUNGEON_HIGHLAND_DECORATION_PATHS[_decoration_index(position, DUNGEON_HIGHLAND_DECORATION_PATHS.size())]
		return DUNGEON_FLOOR_DECORATION_BY_POSITION.get(key, "")
	if terrain_type == "blocked":
		return BLOCKED_DECORATION_PATHS[_decoration_index(position, BLOCKED_DECORATION_PATHS.size())]
	if terrain_type == "cover_low":
		return COVER_DECORATION_PATHS[_decoration_index(position, COVER_DECORATION_PATHS.size())]
	if terrain_type == "highground":
		return HIGHLAND_DECORATION_PATHS[_decoration_index(position, HIGHLAND_DECORATION_PATHS.size())]
	return DECORATION_BY_POSITION.get(key, "")


func _is_dungeon_board() -> bool:
	return _terrain_theme() == "dungeon"


func _terrain_theme() -> String:
	var explicit_theme := str(state.get("terrain_theme", ""))
	if explicit_theme != "":
		return explicit_theme
	if str(state.get("background_path", "")).contains("old_mine_dungeon_"):
		return "dungeon"
	return "nature"


func _decoration_index(position: Dictionary, count: int) -> int:
	if count <= 0:
		return 0
	var x := int(position.get("x", 0))
	var y := int(position.get("y", 0))
	return absi((x * 5 + y * 13 + 1) % count)


func _tile_overlay_color(position: Dictionary, unit: Dictionary) -> Color:
	if _is_active_unit_at(position):
		return Color(1.0, 0.80, 0.22, 0.12)
	if _is_pending_move_destination(position):
		return Color(1.0, 0.72, 0.22, 0.16)
	if _is_pending_move_path(position):
		return Color(0.42, 0.78, 1.0, 0.10)
	var preview := _target_preview_for_position(position)
	if not preview.is_empty():
		if preview.get("rejection", "") == "":
			if selected_action == "move":
				return Color(0.32, 0.86, 0.62, 0.10)
			return Color(0.30, 0.92, 0.42, 0.12)
		if selected_action == "move":
			return Color(0, 0, 0, 0)
		return Color(0.95, 0.20, 0.14, 0.10)
	if _positions_equal(selected_position, position):
		return Color(0.60, 0.58, 0.95, 0.10)
	return Color(0, 0, 0, 0)


func _tile_overlay_style(position: Dictionary, unit: Dictionary, overlay_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = overlay_color
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	if _is_active_unit_at(position):
		style.border_color = Color(1.0, 0.78, 0.24, 0.78)
		_set_tile_overlay_border(style, 3)
	elif _is_pending_move_destination(position):
		style.border_color = Color(1.0, 0.72, 0.22, 0.88)
		_set_tile_overlay_border(style, 3)
	elif _is_pending_move_path(position):
		style.border_color = Color(0.52, 0.82, 1.0, 0.55)
		_set_tile_overlay_border(style, 2)
	else:
		var preview := _target_preview_for_position(position)
		if not preview.is_empty() and preview.get("rejection", "") == "":
			style.border_color = Color(0.42, 1.0, 0.58, 0.52) if selected_action != "move" else Color(0.42, 0.94, 0.70, 0.42)
			_set_tile_overlay_border(style, 2)
		elif not preview.is_empty():
			style.border_color = Color(1.0, 0.26, 0.18, 0.48)
			_set_tile_overlay_border(style, 2)
		elif _positions_equal(selected_position, position):
			style.border_color = Color(0.72, 0.70, 1.0, 0.50)
			_set_tile_overlay_border(style, 2)
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	return style


func _set_tile_overlay_border(style: StyleBoxFlat, width: int) -> void:
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width


func _tile_preview_label(position: Dictionary) -> String:
	if _is_pending_move_destination(position):
		return "MP %s\nOK?" % pending_move_event.get("mp_spent", "?")
	var preview := _target_preview_for_position(position)
	if preview.is_empty() or selected_action == "move":
		return ""
	var rejection := str(preview.get("rejection", ""))
	if rejection != "":
		return ""
	if preview.has("hit_chance"):
		return "%s%%\nHIT" % preview.get("hit_chance", "?")
	if bool(preview.get("guaranteed_hit", false)):
		return "100%\nHIT"
	if preview.has("damage"):
		return "DMG\n%s" % preview.get("damage", "?")
	return "OK"


func _preview_rejection_short_label(reason: String) -> String:
	match reason:
		"target_out_of_range":
			return "OUT\nRANGE"
		"target_not_visible":
			return "NO\nLOS"
		"not_enough_ap":
			return "NO\nAP"
		"skill_on_cooldown":
			return "COOL\nDOWN"
		"target_defeated":
			return "DOWN"
		"target_is_ally":
			return "ALLY"
		"missing_target":
			return "NO\nTARGET"
		"action_not_available":
			return "NO\nSKILL"
		_:
			return "NO"


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
	var displayed := _display_resources(active)
	status_label.text = "Round %s  |  %s\nACTIVE: %s  |  HP %s/%s  AP %s/%s  MP %s/%s%s" % [
		int(state["turn_state"]["round"]),
		_combat_result().capitalize(),
		_unit_display_name(active.get("id", "missing")),
		displayed.get("hp", "?"),
		active.get("stats", {}).get("max_hp", "?"),
		displayed.get("ap", "?"),
		active.get("stats", {}).get("max_ap", "?"),
		displayed.get("mp", "-"),
		active.get("stats", {}).get("move_points", "-"),
		_dungeon_modifier_status_line(),
	]


func _render_action_panel() -> void:
	action_title_label.text = current_action_title
	action_detail_label.text = current_action_detail
	var result := _combat_result()
	if result != "in_progress":
		action_title_label.text = result.capitalize()
		if not authoring_draft.is_empty():
			action_detail_label.text = "Battle over. Press F6 to return to the workbench."
		elif _run_session().has_pending_combat_launch():
			action_detail_label.text = "Battle over. Return to the region to settle the ambush." if _run_session().road_combat else "Battle over. Return to the dungeon to resolve the expedition."
		else:
			action_detail_label.text = "Battle over. Open Tools, choose a scenario and Load to play again."
	if action_feed.is_empty():
		action_feed_label.text = _combat_log_fallback_line()
	else:
		var recent_feed := action_feed.slice(0, mini(3, action_feed.size()))
		action_feed_label.text = "\n".join(recent_feed)


func _render_board_overlay() -> void:
	if overlay_resource_panel == null or overlay_log_label == null:
		return
	var active := _unit_by_id(state.get("turn_state", {}).get("active_unit_id", ""))
	overlay_resource_panel.visible = not active.is_empty()
	if not active.is_empty():
		overlay_resource_label.text = "%s  /  %s" % [_unit_display_name(active.id), str(active.get("team", "")).capitalize()]
		var active_resources := _display_resources(active)
		_update_resource_bar(overlay_resource_bars["hp"], active_resources.get("hp", 0), active.get("stats", {}).get("max_hp", 1))
		_update_resource_bar(overlay_resource_bars["ap"], active_resources.get("ap", 0), active.get("stats", {}).get("max_ap", 1))
		_update_resource_bar(overlay_resource_bars["mp"], active_resources.get("mp", 0), active.get("stats", {}).get("move_points", 1))

	var log_lines := _overlay_combat_log_lines()
	overlay_log_label.text = "\n".join(log_lines)


func _overlay_combat_log_lines() -> Array[String]:
	var log_lines: Array[String] = []
	if not action_feed.is_empty():
		log_lines.append_array(action_feed.slice(0, mini(4, action_feed.size())))
	var events: Array = state.get("event_log", []).duplicate(true)
	events.reverse()
	for event: Dictionary in events:
		if log_lines.size() >= 5:
			break
		if event.get("type", "") in ["combat_started", "turn_started"]:
			continue
		log_lines.append(_compact_report_line(_event_timeline_line(event)))
	if log_lines.is_empty():
		log_lines.append(_combat_log_fallback_line())
	return log_lines


func _compact_report_line(line: String) -> String:
	var compact := line.replace("\n", " ").strip_edges()
	if compact.length() > 86:
		return "%s..." % compact.substr(0, 83)
	return compact


func _combat_log_fallback_line() -> String:
	if last_feedback.strip_edges() != "":
		return last_feedback
	return "Combat ready."


func _render_feedback() -> void:
	feedback_label.text = last_feedback


func _dungeon_modifier_status_line() -> String:
	var modifiers: Dictionary = state.get("dungeon_modifiers", {})
	if modifiers.is_empty():
		return ""
	return "\nDungeon: light %s | debuffs %s | enemy mods %s" % [
		str(modifiers.get("light_state", "bright")),
		modifiers.get("active_debuffs", {}).size(),
		modifiers.get("enemy_modifiers", []).size(),
	]


func _render_legend() -> void:
	legend_label.text = "Gold active  -  green legal target  -  blue route  -  amber confirm"


func _render_unit_list() -> void:
	var lines: Array[String] = []
	for unit: Dictionary in state["units"]:
		var marker := "> " if unit["id"] == state["turn_state"]["active_unit_id"] else "  "
		lines.append("%s%s  HP %s/%s  AP %s/%s  MP %s/%s\n  Status: %s" % [
			marker,
			_unit_display_name(unit["id"]),
			unit["resources"]["hp"],
			unit["stats"]["max_hp"],
			unit["resources"]["ap"],
			unit["stats"]["max_ap"],
			unit["resources"].get("mp", "-"),
			unit["stats"].get("move_points", "-"),
			_status_summary(unit),
		])
	unit_list_label.text = "\n".join(lines)


func _render_turn_order() -> void:
	var active_id := str(state.get("turn_state", {}).get("active_unit_id", ""))
	var labels: Array[String] = []
	for unit_id in state.get("turn_state", {}).get("turn_order", []):
		var unit := _unit_by_id(str(unit_id))
		if unit.is_empty() or unit.get("resources", {}).get("hp", 0) <= 0:
			continue
		var marker := ">" if str(unit_id) == active_id else " "
		labels.append("%s %s\nHP %s  AP %s  MP %s" % [
			marker,
			_unit_display_name(str(unit_id)),
			unit["resources"].get("hp", "-"),
			unit["resources"].get("ap", "-"),
			unit["resources"].get("mp", "-"),
		])
	turn_order_label.text = "TURN ORDER\n%s" % "\n".join(labels)


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
				if preview.has("hit_chance"):
					lines.append("Hit chance: %s%%" % preview.get("hit_chance", "?"))
					lines.append("Preview roll: %s -> %s" % [preview.get("roll", "?"), str(preview.get("hit_outcome", "?")).capitalize()])
				elif bool(preview.get("guaranteed_hit", false)):
					lines.append("Hit chance: 100% (guaranteed)")
				if preview.has("damage"):
					lines.append("Damage on hit: %s" % preview.get("damage", "?"))
					lines.append("Target HP after: %s" % preview.get("hp_after", "?"))
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

	var slot := 1
	for action_id in primary_actions:
		_add_action_button(action_id, slot)
		slot += 1

	var debug_actions := _visible_debug_action_ids()
	for action_id in debug_actions:
		_add_action_button(action_id, slot)
		slot += 1
	if _combat_result() == "in_progress":
		_add_debug_win_button()
	if authoring_draft.is_empty() and _run_session().has_pending_combat_launch() and _combat_result() != "in_progress":
		_add_return_to_dungeon_button()
	_add_scenario_picker()
	if battle_chrome != null: battle_chrome.add_gallery_button(self)


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
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34))
	label.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.03, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	command_buttons.add_child(label)


func _add_action_button(action_id: String, slot: int = 0) -> void:
	var button := Button.new()
	var label: String = ACTION_LABELS.get(action_id, action_id)
	button.text = ""
	button.tooltip_text = panel_skin.wrap_tooltip("%s%s" % [label, " [%s]" % slot if slot > 0 and slot <= 9 else ""], get_theme_font("font", "TooltipLabel"))
	button.custom_minimum_size = ACTION_BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 1)
	button.add_theme_color_override("font_color", Color(0.94, 0.88, 0.72))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.86, 0.38))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.68))
	button.add_theme_color_override("font_disabled_color", Color(0.44, 0.42, 0.38))
	var icon := _action_icon_texture(action_id)
	if icon == null:
		button.text = label
		button.add_theme_font_size_override("font_size", 12)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if icon != null:
		button.icon = icon
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.toggle_mode = true
	button.button_pressed = selected_action == action_id
	button.modulate = Color(1.0, 0.95, 0.72) if selected_action == action_id else Color(0.94, 0.90, 0.82)
	button.disabled = animation_locked or _combat_result() != "in_progress"
	_apply_skill_button_style(button, selected_action == action_id)
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
			_prepare_presentation_cache()
			_set_targeting_banner(action_id)
			last_feedback = "Select a highlighted target for %s." % ACTION_LABELS.get(action_id, action_id)
			_render()
	)
	button.mouse_entered.connect(func() -> void:
		_show_action_hover(action_id, slot)
	)
	button.mouse_exited.connect(func() -> void:
		_render_action_panel()
	)
	command_buttons.add_child(button)
	if battle_chrome!=null: battle_chrome.decorate_action(self,button,action_id,slot)


func _show_action_hover(action_id: String, slot: int) -> void:
	if animation_locked or _combat_result() != "in_progress":
		_render_action_panel()
		return
	var active := _unit_by_id(state.get("turn_state", {}).get("active_unit_id", ""))
	var displayed := _display_resources(active)
	var label: String = ACTION_LABELS.get(action_id, action_id)
	var slot_text := "Slot %s" % slot if slot > 0 and slot <= 9 else "Action"
	var resources := "AP %s/%s  MP %s/%s" % [
		displayed.get("ap", "?"),
		active.get("stats", {}).get("max_ap", "?"),
		displayed.get("mp", "-"),
		active.get("stats", {}).get("move_points", "-"),
	]
	action_title_label.text = "%s: %s" % [slot_text, label]
	var cost := "COST %s AP" % _action_ap_cost(active, action_id, 0 if action_id == "end_turn" else 1)
	if action_id == "move" and active.get("resources", {}).has("mp"):
		cost = "COST depends on destination MP"
	elif action_id in ["enemy_ai", "enemy_turn", "reset"]:
		cost = "Debug control"
	action_detail_label.text = "%s. %s. Click to select." % [cost, resources]


func _apply_skill_button_style(button: Button, selected: bool) -> void:
	var normal_texture_path := COMBAT_UI_SLOT_SELECTED_PATH if selected else COMBAT_UI_SLOT_NORMAL_PATH
	var normal_style := _combat_ui_stylebox(normal_texture_path, 24, 18)
	var hover_style := _combat_ui_stylebox(COMBAT_UI_SLOT_SELECTED_PATH, 24, 18)
	var disabled_style := _combat_ui_stylebox(COMBAT_UI_SLOT_DISABLED_PATH, 24, 18)
	if normal_style != null and hover_style != null and disabled_style != null:
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", hover_style)
		button.add_theme_stylebox_override("disabled", disabled_style)
		button.add_theme_stylebox_override("focus", hover_style)
		button.add_theme_constant_override("icon_max_width", ACTION_BUTTON_ICON_MAX_WIDTH)
		button.add_theme_constant_override("h_separation", 0)
		return

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.07, 0.045, 0.96)
	normal.border_color = Color(0.44, 0.34, 0.16) if not selected else Color(1.0, 0.76, 0.22)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.content_margin_left = 6
	normal.content_margin_top = 4
	normal.content_margin_right = 6
	normal.content_margin_bottom = 4

	var hover := normal.duplicate()
	hover.bg_color = Color(0.10, 0.11, 0.065, 0.98)
	hover.border_color = Color(0.95, 0.70, 0.28)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.13, 0.10, 0.045, 0.98)
	pressed.border_color = Color(1.0, 0.84, 0.35)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_constant_override("icon_max_width", ACTION_BUTTON_ICON_MAX_WIDTH)
	button.add_theme_constant_override("h_separation", 0)


func _add_scenario_picker() -> void:
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picker.custom_minimum_size = Vector2(210, 30)
	picker.add_theme_font_size_override("font_size", 11)

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
	load_button.text = "Load"
	load_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	load_button.disabled = animation_locked
	load_button.custom_minimum_size = Vector2(86, 30)
	load_button.add_theme_font_size_override("font_size", 11)
	load_button.pressed.connect(func() -> void:
		_load_selected_scenario()
	)
	command_buttons.add_child(load_button)


func _add_return_to_dungeon_button() -> void:
	var button := Button.new()
	button.text = "Return\nto Region" if _run_session().road_combat else "Return\nto Dungeon"
	button.custom_minimum_size = Vector2(132, 62)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 12)
	_apply_skill_button_style(button, false)
	button.pressed.connect(func() -> void:
		_return_to_dungeon()
	)
	command_buttons.add_child(button)


func _add_debug_win_button() -> void:
	var button := Button.new()
	button.text = "Debug\nWin"
	button.custom_minimum_size = Vector2(132, 62)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 12)
	_apply_skill_button_style(button, false)
	button.pressed.connect(func() -> void:
		_force_debug_victory()
	)
	command_buttons.add_child(button)


func _force_debug_victory(render_after: bool = true) -> void:
	if animation_locked:
		return
	if _combat_result() != "in_progress":
		last_feedback = "Combat already ended."
		if render_after:
			_render()
		return

	for unit: Dictionary in state.get("units", []):
		if unit.get("team", "") == "enemy" and int(unit.get("resources", {}).get("hp", 0)) > 0:
			unit["resources"]["hp"] = 0
			state["event_log"].append(_debug_event("unit_defeated", {
				"unit_id": unit.get("id", ""),
				"team": "enemy",
				"source": "debug_win",
			}))

	var payload := _combat_result_payload()
	state["event_log"].append(_debug_event("combat_ended", {
		"result": payload.get("result", "victory"),
		"result_payload": payload,
		"source": "debug_win",
	}))
	current_action_title = "Debug victory"
	current_action_detail = "All enemies defeated by debug command."
	_push_action_feed("Debug victory applied")
	last_feedback = "Debug victory applied."
	_clear_move_preview()
	_prepare_presentation_cache()
	if render_after:
		_render()


func _debug_event(event_type: String, payload: Dictionary) -> Dictionary:
	var event := payload.duplicate(true)
	event["type"] = event_type
	event["sequence"] = state.get("event_log", []).size() + 1
	return event


func _return_to_dungeon() -> void:
	if not authoring_draft.is_empty():
		return
	var result_payload := _combat_result_payload()
	if result_payload.is_empty():
		last_feedback = "No combat result payload."
		_render()
		return
	var return_scene: String = _run_session().return_scene_path()
	if not _run_session().finish_combat(result_payload):
		last_feedback = _run_session().last_feedback
		_render()
		return
	get_tree().change_scene_to_file(return_scene)


func _load_selected_scenario() -> void:
	if animation_locked:
		return
	if _run_session().has_pending_combat_launch():
		last_feedback = "Scenario picker disabled during dungeon combat."
		_render()
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
	elif selected_action == "deep_cut":
		_clear_move_preview()
		var unit := _living_unit_at(position)
		_run_command(_build_command("deep_cut", {
			"type": "unit",
			"unit_id": unit.get("id", ""),
		}))
	elif selected_action == "guard_break":
		_clear_move_preview()
		var unit := _living_unit_at(position)
		_run_command(_build_command("guard_break", {
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

	var move_event := _preview_move_event(position)
	if move_event.is_empty():
		_clear_move_preview()
		last_feedback = "Move rejected: %s" % _rejection_label("destination_unreachable")
		_render()
		return

	pending_move_position = position.duplicate(true)
	pending_move_event = move_event
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
	_clear_floating_text()
	_clear_move_preview()
	temporary_resource_overrides.clear()
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
		_play_movement_animation(new_events, previous_state, next_state, next_log)
		return

	if has_combat_flash:
		last_feedback = next_feedback
		animation_locked = true
		temporary_visual_units.clear()
		_prepare_presentation_cache()
		_render()
		_play_combat_animation(new_events, previous_state, next_state, next_log)
		return

	state = next_state
	state["event_log"] = next_log
	last_feedback = next_feedback
	_prepare_presentation_cache()
	_render()
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
	bottom_hud.custom_minimum_size = Vector2(0, BOTTOM_HUD_MIN_HEIGHT)
	bottom_hud.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ensure_board_overlay_controls()
	theme = panel_skin.popup_theme()
	var title_label := %TitleLabel as Label
	if title_label != null:
		title_label.add_theme_color_override("font_color", Color(1.0, 0.80, 0.32))
		title_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.03, 0.02, 1.0))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)

	encounter_panel.add_theme_stylebox_override("panel", panel_skin.style("panel"))
	action_panel.add_theme_stylebox_override("panel", panel_skin.style("inset"))
	bottom_hud.add_theme_stylebox_override("panel", panel_skin.style("bar"))
	turn_order_panel.add_theme_stylebox_override("panel", panel_skin.style("panel"))
	board_backdrop.add_theme_stylebox_override("panel", panel_skin.style("board"))
	if overlay_log_panel != null:
		overlay_log_panel.add_theme_stylebox_override("panel", panel_skin.style("panel"))
	if overlay_resource_panel != null:
		overlay_resource_panel.add_theme_stylebox_override("panel", _compact_resource_panel_style())

	var action_title_color := Color(1.0, 0.86, 0.38)
	var action_text_color := Color(0.96, 0.92, 0.80)
	var shadow_color := Color(0.05, 0.04, 0.03, 1.0)
	for label: Label in [title_label, action_title_label, action_detail_label, action_feed_label, status_label, feedback_label, legend_label, unit_list_label, inspect_label, event_log_label, turn_order_label]:
		label.add_theme_color_override("font_color", action_text_color)
		label.add_theme_color_override("font_shadow_color", shadow_color)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
	action_title_label.add_theme_color_override("font_color", action_title_color)
	title_label.add_theme_color_override("font_color", action_title_color)
	turn_order_label.add_theme_color_override("font_color", action_title_color)
	action_detail_label.add_theme_font_size_override("font_size", 10)
	action_detail_label.max_lines_visible = 3
	action_feed_label.add_theme_font_size_override("font_size", 9)
	action_feed_label.max_lines_visible = 4
	turn_order_label.max_lines_visible = 6
	event_log_label.max_lines_visible = 10
	status_label.max_lines_visible = 3
	title_label.max_lines_visible = 1
	# Clipped, wrapped labels can report a one-pixel minimum height. Reserve
	# real line space so containers cannot hide the HUD copy.
	for entry in [[title_label, 1], [action_title_label, 1], [action_detail_label, 3], [action_feed_label, 4], [status_label, 3], [turn_order_label, 6]]:
		var text_label := entry[0] as Label
		var font := text_label.get_theme_font("font")
		var line_height := font.get_height(text_label.get_theme_font_size("font_size"))
		text_label.custom_minimum_size.y = ceilf(line_height * int(entry[1]))
	if overlay_log_label != null:
		overlay_log_label.add_theme_color_override("font_color", action_text_color)
		overlay_log_label.add_theme_color_override("font_shadow_color", shadow_color)
		overlay_log_label.add_theme_constant_override("shadow_offset_x", 1)
		overlay_log_label.add_theme_constant_override("shadow_offset_y", 1)
		overlay_log_label.add_theme_font_size_override("font_size", 9)
		overlay_log_label.max_lines_visible = 5
	if overlay_resource_label != null:
		overlay_resource_label.add_theme_color_override("font_color", action_title_color)
		overlay_resource_label.add_theme_color_override("font_shadow_color", shadow_color)
		overlay_resource_label.add_theme_constant_override("shadow_offset_x", 1)
		overlay_resource_label.add_theme_constant_override("shadow_offset_y", 1)

	if battle_chrome!=null: battle_chrome.style_hud(self)

func _ensure_board_overlay_controls() -> void:
	if board_overlay_layer != null:
		return
	board_overlay_layer = Control.new()
	board_overlay_layer.name = "BoardOverlayLayer"
	board_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_overlay_layer.z_index = BOARD_OVERLAY_LAYER_Z_INDEX
	board_root.add_child(board_overlay_layer)

	overlay_resource_panel = PanelContainer.new()
	overlay_resource_panel.name = "OverlayResourcePanel"
	overlay_resource_panel.custom_minimum_size = OVERLAY_RESOURCE_PANEL_SIZE
	overlay_resource_panel.size = OVERLAY_RESOURCE_PANEL_SIZE
	overlay_resource_panel.position = Vector2(16, 14)
	overlay_resource_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_overlay_layer.add_child(overlay_resource_panel)

	var resource_vbox := VBoxContainer.new()
	resource_vbox.name = "OverlayResourceVBox"
	resource_vbox.add_theme_constant_override("separation", 1)
	overlay_resource_panel.add_child(resource_vbox)

	overlay_resource_label = Label.new()
	overlay_resource_label.name = "OverlayResourceLabel"
	overlay_resource_label.add_theme_font_size_override("font_size", 14)
	overlay_resource_label.clip_text = true
	overlay_resource_label.max_lines_visible = 1
	overlay_resource_label.custom_minimum_size.y = 20
	resource_vbox.add_child(overlay_resource_label)

	overlay_resource_bars["hp"] = _create_resource_bar(COMBAT_UI_BAR_HP_PATH, OVERLAY_RESOURCE_BAR_SIZE)
	overlay_resource_bars["ap"] = _create_resource_bar(COMBAT_UI_BAR_AP_PATH, OVERLAY_RESOURCE_BAR_SIZE)
	overlay_resource_bars["mp"] = _create_resource_bar(COMBAT_UI_BAR_MP_PATH, OVERLAY_RESOURCE_BAR_SIZE)
	resource_vbox.add_child(overlay_resource_bars["hp"])
	resource_vbox.add_child(overlay_resource_bars["ap"])
	resource_vbox.add_child(overlay_resource_bars["mp"])

	overlay_log_panel = PanelContainer.new()
	overlay_log_panel.name = "OverlayLogPanel"
	overlay_log_panel.custom_minimum_size = OVERLAY_LOG_PANEL_SIZE
	overlay_log_panel.size = OVERLAY_LOG_PANEL_SIZE
	overlay_log_panel.position = Vector2(16, 136)
	overlay_log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_overlay_layer.add_child(overlay_log_panel)

	overlay_log_label = Label.new()
	overlay_log_label.name = "OverlayLogLabel"
	overlay_log_label.add_theme_font_size_override("font_size", 9)
	overlay_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_log_label.clip_text = true
	overlay_log_label.custom_minimum_size = Vector2(0, 60)
	overlay_log_label.max_lines_visible = 5
	overlay_log_panel.add_child(overlay_log_label)


func _configure_board_layers() -> void:
	unit_layer.z_index = UNIT_LAYER_Z_INDEX
	floating_text_layer.z_index = FLOATING_TEXT_LAYER_Z_INDEX
	if board_overlay_layer != null:
		board_overlay_layer.z_index = BOARD_OVERLAY_LAYER_Z_INDEX


func _create_resource_bar(texture_path: String, bar_size: Vector2) -> TextureProgressBar:
	var bar := ResourceMeterScene.instantiate()
	bar.configure(pixel_skin.scaled_texture(texture_path, Vector2i(bar_size)), bar_size)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var amount := Label.new()
	amount.name = "AmountLabel"
	amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.add_theme_font_size_override("font_size", 16)
	amount.add_theme_color_override("font_color", Color.WHITE)
	amount.add_theme_color_override("font_outline_color", Color.BLACK)
	amount.add_theme_constant_override("outline_size", 3)
	amount.clip_text = true
	bar.add_child(amount)
	bar.set_meta("resource_label", "HP" if texture_path == COMBAT_UI_BAR_HP_PATH else ("AP" if texture_path == COMBAT_UI_BAR_AP_PATH else "MP"))
	return bar


func _update_resource_bar(bar: TextureProgressBar, value: Variant, max_value: Variant) -> void:
	if bar == null:
		return
	bar.set_amount(float(value), float(max_value))
	var amount := bar.get_node_or_null("AmountLabel") as Label
	if amount != null:
		amount.text = "%s %s / %s" % [bar.get_meta("resource_label", ""), int(bar.value), int(max_value)]


func _combat_ui_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ui_texture_cache.has(path):
		return ui_texture_cache[path]
	var texture := AssetCatalog.texture(path)
	ui_texture_cache[path] = texture
	return texture


func _action_icon_texture(action_id: String) -> Texture2D:
	var path := str(ACTION_ICON_PATHS.get(action_id, ""))
	if path != "" and _combat_ui_texture_has_visible_pixels(path):
		return _combat_ui_texture(path)
	var fallback_path := str(ACTION_ICON_FALLBACK_PATHS.get(action_id, ""))
	if fallback_path != "":
		return _combat_ui_texture(fallback_path)
	return _combat_ui_texture(path)


func _combat_ui_texture_has_visible_pixels(path: String) -> bool:
	if path == "":
		return false
	var cache_key := "%s:visible" % path
	if ui_texture_cache.has(cache_key):
		return bool(ui_texture_cache[cache_key])
	var image := AssetCatalog.image_copy(path)
	if image == null:
		ui_texture_cache[cache_key] = false
		return false
	var step_x := maxi(1, int(image.get_width() / 64))
	var step_y := maxi(1, int(image.get_height() / 64))
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			if image.get_pixel(x, y).a > 0.05:
				ui_texture_cache[cache_key] = true
				return true
	ui_texture_cache[cache_key] = false
	return false


func _combat_ui_stylebox(path: String, texture_margin: int, content_margin: int) -> StyleBoxTexture:
	return pixel_skin.frame(path, Vector4.ONE * texture_margin, Vector4.ONE * content_margin) as StyleBoxTexture


func _compact_resource_panel_style() -> StyleBoxFlat:
	return panel_skin.style("resource") as StyleBoxFlat


func _set_targeting_banner(action_id: String) -> void:
	current_action_title = "Targeting: %s" % ACTION_LABELS.get(action_id, action_id)
	var preview_counts := _target_preview_counts()
	if preview_counts["total"] > 0:
		current_action_detail = "Pick a highlighted target. Legal: %s. Blocked: %s." % [preview_counts["legal"], preview_counts["blocked"]]
	else:
		current_action_detail = "Pick a highlighted target on the board."


func _target_preview_counts() -> Dictionary:
	var legal := 0
	var blocked := 0
	for preview: Dictionary in target_preview_cache.values():
		if preview.get("rejection", "") == "":
			legal += 1
		else:
			blocked += 1
	return {
		"legal": legal,
		"blocked": blocked,
		"total": legal + blocked,
	}


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
			feed_line = "Rejected %s: %s" % [ACTION_LABELS.get(command.get("action_id", ""), command.get("action_id", "action")), _rejection_label(event.get("reason", "unknown"))]
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
				if int(event.get("hp_after", 1)) <= 0:
					unit_facing[target["id"]] = _direction_between(target["position"], actor["position"])


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
		_render_units()
	)


func _prepare_movement_animation(events: Array) -> bool:
	var actions := CombatUnitVisualState.movement_actions_from_events(events)
	for event: Dictionary in events:
		if event["type"] != "unit_moved":
			continue
		var actor_id := str(event.get("actor_id", ""))
		if actor_id == "" or not actions.has(actor_id):
			continue
		visual_positions_px[actor_id] = _position_to_unit_top_left(event.get("from", {}))
		unit_visual_action[actor_id] = "walk:0" if str(actions[actor_id]) == "walk" else actions[actor_id]
		var step_facings := CombatUnitVisualState.movement_step_facings(event)
		if not step_facings.is_empty():
			unit_facing[actor_id] = str(step_facings[0].get("direction", ""))
	return not actions.is_empty()


func _prepare_combat_flash(events: Array, previous_state: Dictionary) -> bool:
	var actions := CombatUnitVisualState.combat_actions_from_events(events)
	for unit_id: String in actions:
		unit_visual_action[unit_id] = actions[unit_id]

	for target_id: String in CombatUnitVisualState.defeated_target_ids(events):
		var defeated_unit := _unit_by_id_in_state(previous_state, target_id)
		if defeated_unit.is_empty():
			continue
		defeated_unit = defeated_unit.duplicate(true)
		defeated_unit["resources"]["hp"] = 0
		temporary_visual_units[target_id] = defeated_unit

	return not actions.is_empty()


func _play_combat_animation(events: Array, previous_state: Dictionary, next_state: Dictionary, next_log: Array) -> void:
	var units:=_timeline_units()
	if DrawnTimeline.uses_drawn(events,units,unit_art):
		_play_drawn_combat_animation(events,next_state,next_log,units)
		return
	visual_generation += 1
	var current_generation := visual_generation
	var tween := create_tween()
	active_motion_tween=tween
	var tween_has_steps := false
	var animated_actors: Dictionary = {}
	var animated_targets: Dictionary = {}
	_spawn_combat_floating_texts(events)

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
		_start_visual_cycle(actor_id, "combat", current_generation, COMBAT_CYCLE_SECONDS)
		tween.tween_callback(func() -> void:
			_apply_action_resource_spend(actor_id, events, previous_state)
		)
		tween.tween_property(unit_node, "position", origin + lunge, COMBAT_WINDUP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if event["type"] == "damage_applied":
			var damage_event := event.duplicate(true)
			tween.tween_callback(func() -> void:
				_apply_damage_resource_result(damage_event)
			)
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
			_start_visual_cycle(target_id, "death", current_generation, DEATH_CYCLE_SECONDS, false)
			tween.tween_property(target_node, "position", target_origin + Vector2(0, DEATH_FALL_PIXELS), DEATH_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(target_node, "modulate:a", 0.72, DEATH_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_interval(DEATH_HOLD_SECONDS)
		else:
			_start_visual_cycle(target_id, "hit", current_generation, HIT_CYCLE_SECONDS, false)
			tween.tween_property(target_node, "position", target_origin + _hit_shake_offset(actor, target_unit), HIT_SHAKE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(target_node, "position", target_origin, HIT_SHAKE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		animated_targets[target_id] = true
		tween_has_steps = true

	if not tween_has_steps:
		tween.kill()
		_finish_combat_animation(current_generation, next_state, next_log)
		return

	tween.finished.connect(func() -> void:
		_finish_combat_animation(current_generation, next_state, next_log)
	)


func _timeline_units() -> Dictionary:
	var result: Dictionary={}
	for unit: Dictionary in state.get("units",[]):result[unit.id]=unit
	for id: String in temporary_visual_units:result[id]=temporary_visual_units[id]
	return result


func _play_drawn_combat_animation(events: Array, next_state: Dictionary, next_log: Array, units: Dictionary) -> void:
	visual_generation+=1
	var generation:=visual_generation
	var plan:=DrawnTimeline.build(events,units,unit_art)
	# Reactions prepared for preloading must stay at rest until the impact cue.
	unit_visual_action.clear()
	for id: String in units:_refresh_unit_sprite(id)
	for actor: Dictionary in plan.actors:
		unit_visual_action[actor.id]="combat:0"
		_apply_action_resource_spend(actor.id,events,state)
		_start_visual_cycle(actor.id,"combat",generation,COMBAT_CYCLE_SECONDS)
	var elapsed:=0.0
	for impact: Dictionary in plan.impacts:
		var delay:=float(impact.at)-elapsed
		if delay>0.0:await get_tree().create_timer(delay).timeout
		if generation!=visual_generation:return
		elapsed=float(impact.at)
		for event: Dictionary in impact.events:
			if event.type=="damage_applied":_apply_damage_resource_result(event)
		for id: String in impact.reactions:
			var action:=str(impact.reactions[id])
			unit_visual_action[id]=action+":0"
			_start_visual_cycle(id,action,generation,HIT_CYCLE_SECONDS)
		_spawn_combat_floating_texts(impact.events)
	var remaining:=float(plan.duration)-elapsed
	if remaining>0.0:await get_tree().create_timer(remaining).timeout
	if generation==visual_generation:_finish_combat_animation(generation,next_state,next_log)


func _finish_combat_animation(current_generation: int, next_state: Dictionary, next_log: Array) -> void:
	if current_generation != visual_generation:
		return
	active_motion_tween=null
	unit_visual_action.clear()
	temporary_visual_units.clear()
	temporary_resource_overrides.clear()
	state = next_state
	state["event_log"] = next_log
	animation_locked = false
	_prepare_presentation_cache()
	_render()
	_schedule_visual_reset()


func _spawn_combat_floating_texts(events: Array) -> void:
	var messages: Array[Dictionary] = CombatFloatingText.messages_from_events(events)
	CombatFloatingText.spawn_messages(floating_text_layer, messages, _floating_text_position_for_unit_id)


func _floating_text_position_for_unit_id(unit_id: String) -> Variant:
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() and temporary_visual_units.has(unit_id):
		unit = temporary_visual_units[unit_id]
	if unit.is_empty():
		return null
	var unit_origin := _position_to_unit_top_left(unit["position"])
	var message_size: Vector2 = CombatFloatingText.DEFAULT_MESSAGE_SIZE
	var x := unit_origin.x + (float(UNIT_ICON_SIZE.x) - message_size.x) / 2.0
	var y := unit_origin.y - 8.0
	return Vector2(maxf(0.0, x), maxf(0.0, y))


func _clear_floating_text() -> void:
	CombatFloatingText.clear(floating_text_layer)


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


func _play_movement_animation(events: Array, previous_state: Dictionary, next_state: Dictionary, next_log: Array) -> void:
	visual_generation += 1
	var current_generation := visual_generation
	var tween := create_tween()
	active_motion_tween=tween
	var tween_has_steps := false
	for event: Dictionary in events:
		if event["type"] != "unit_moved":
			continue
		var actor_id := str(event.get("actor_id", ""))
		var path: Array = event.get("path", [event.get("to", {})])
		var unit_node := unit_layer.get_node_or_null(actor_id)
		if unit_node == null:
			continue
		_start_walk_cycle(actor_id, current_generation)
		var remaining_mp := int(_unit_by_id_in_state(previous_state, actor_id).get("resources", {}).get("mp", 0))
		var step_facings := CombatUnitVisualState.movement_step_facings(event)
		var step_index := 0
		var previous_position:=Vector2(unit_node.position)
		for step: Dictionary in path:
			if step_index < step_facings.size():
				tween.tween_callback(_movement_facing_callback(actor_id, str(step_facings[step_index].get("direction", ""))))
			var target_position := _position_to_unit_top_left(step)
			var seconds:=unit_art.movement_seconds(_unit_by_id(actor_id),previous_position.distance_to(target_position),MOVE_STEP_SECONDS)
			tween.tween_property(unit_node, "position", target_position, seconds).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
			previous_position=target_position
			var step_cost := _terrain_movement_cost(step)
			remaining_mp = maxi(0, remaining_mp - step_cost)
			var display_mp := remaining_mp
			tween.tween_callback(_resource_override_callback(actor_id, "mp", display_mp))
			step_index += 1
			tween_has_steps = true
	if not tween_has_steps:
		tween.kill()
		_finish_movement_animation(events, current_generation, next_state, next_log)
		return
	tween.finished.connect(func() -> void:
		_finish_movement_animation(events, current_generation, next_state, next_log)
	)


func _finish_movement_animation(events: Array, current_generation: int, next_state: Dictionary, next_log: Array) -> void:
	if current_generation != visual_generation:
		return
	active_motion_tween=null
	for event: Dictionary in events:
		if event["type"] != "unit_moved":
			continue
		var actor_id := str(event.get("actor_id", ""))
		visual_positions_px.erase(actor_id)
		unit_visual_action.erase(actor_id)
	temporary_visual_units.clear()
	temporary_resource_overrides.clear()
	state = next_state
	state["event_log"] = next_log
	_face_moved_units_toward_nearest_opponent(events)
	animation_locked = false
	_prepare_presentation_cache()
	_render()
	_schedule_visual_reset()


func _start_walk_cycle(actor_id: String, current_generation: int) -> void:
	var frame := 0
	var frame_count := _walk_frame_count(actor_id)
	while current_generation == visual_generation and animation_locked and str(unit_visual_action.get(actor_id, "")).begins_with("walk"):
		unit_visual_action[actor_id] = "walk:%s" % frame
		_refresh_unit_sprite(actor_id)
		frame = (frame + 1) % frame_count
		await get_tree().create_timer(unit_art.frame_seconds(_unit_by_id(actor_id), "walk", WALK_CYCLE_SECONDS,frame)).timeout


func _walk_frame_count(actor_id: String) -> int:
	var unit := _unit_by_id(actor_id)
	if unit.is_empty() and temporary_visual_units.has(actor_id):
		unit = temporary_visual_units[actor_id]
	if unit.is_empty():
		return 1
	var visual := _unit_visual_config(unit)
	return unit_art.processed_sheet_frame_count(str(visual.get("character", "")), "walk")


func _start_visual_cycle(unit_id: String, action: String, current_generation: int, frame_seconds: float, loop: bool = false) -> void:
	var frame := 0
	var frame_count := _visual_frame_count(unit_id, action)
	while current_generation == visual_generation and animation_locked and str(unit_visual_action.get(unit_id, "")).begins_with(action):
		unit_visual_action[unit_id] = "%s:%s" % [action, frame]
		_refresh_unit_sprite(unit_id)
		if not loop and frame >= frame_count - 1:
			return
		var seconds:=unit_art.frame_seconds(_unit_by_id(unit_id),action,frame_seconds,frame)
		frame = (frame + 1) % frame_count
		await get_tree().create_timer(seconds).timeout


func _visual_frame_count(unit_id: String, action: String) -> int:
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() and temporary_visual_units.has(unit_id):
		unit = temporary_visual_units[unit_id]
	if unit.is_empty():
		return 1
	var visual := _unit_visual_config(unit)
	return unit_art.processed_sheet_frame_count(str(visual.get("character", "")), action)


func _refresh_unit_sprite(actor_id: String) -> void:
	var unit := _unit_by_id(actor_id)
	if unit.is_empty() and temporary_visual_units.has(actor_id):
		unit = temporary_visual_units[actor_id]
	if unit.is_empty():
		return
	var unit_node := unit_layer.get_node_or_null(actor_id) as Control
	if unit_node == null:
		return
	var sprite := unit_node.get_node_or_null("Sprite") as TextureRect
	if sprite == null:
		return
	sprite.texture = _unit_icon(unit)


func _face_moved_units_toward_nearest_opponent(events: Array) -> void:
	for event: Dictionary in events:
		if event["type"] != "unit_moved":
			continue
		var actor_id := str(event.get("actor_id", ""))
		var actor := _unit_by_id(actor_id)
		if actor.is_empty():
			continue
		var nearest := _nearest_living_opponent(actor)
		if nearest.is_empty():
			unit_facing.erase(actor_id)
			continue
		unit_facing[actor_id] = _direction_between(actor["position"], nearest["position"])


func _clear_grid() -> void:
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()


func _clear_units() -> void:
	for child in unit_layer.get_children():
		unit_layer.remove_child(child)
		child.queue_free()


func _resize_board() -> void:
	if state.is_empty():
		return
	var width: int = int(state["grid"]["width"]) * TILE_WIDTH + maxi(0, int(state["grid"]["width"]) - 1) * TILE_GAP
	var height: int = int(state["grid"]["height"]) * TILE_HEIGHT + maxi(0, int(state["grid"]["height"]) - 1) * TILE_GAP
	var board_size := Vector2(width, height)
	board_root.custom_minimum_size = board_size
	board_root.size = board_size
	var margin := CombatPanelSkin.BOARD_FRAME_MARGIN
	board_backdrop.position = Vector2.ONE * -margin
	board_backdrop.custom_minimum_size = board_size + Vector2.ONE * margin * 2
	board_backdrop.size = board_backdrop.custom_minimum_size
	var available := (board_viewport.size - Vector2.ONE * margin * 2).max(Vector2.ONE)
	var headroom := 300.0 if battle_chrome!=null else 0.0
	var board_scale := minf(1.0, minf(available.x / board_size.x, available.y / (board_size.y+headroom)))
	board_root.scale = Vector2.ONE * board_scale
	board_root.position = (board_viewport.size - (board_size+Vector2(0,headroom)) * board_scale) / 2.0+Vector2(0,headroom*board_scale)
	board_terrain.custom_minimum_size = board_size
	board_terrain.size = board_size
	grid_container.custom_minimum_size = board_size
	grid_container.size = board_size
	unit_layer.custom_minimum_size = board_size
	unit_layer.size = board_size
	floating_text_layer.custom_minimum_size = board_size
	floating_text_layer.size = board_size
	if board_overlay_layer != null:
		board_overlay_layer.custom_minimum_size = board_size
		board_overlay_layer.size = board_size
		_position_board_overlays(board_size)


func _position_board_overlays(board_size: Vector2) -> void:
	if battle_chrome!=null: return
	if overlay_resource_panel != null:
		overlay_resource_panel.custom_minimum_size = OVERLAY_RESOURCE_PANEL_SIZE
		overlay_resource_panel.size = OVERLAY_RESOURCE_PANEL_SIZE
		overlay_resource_panel.position = Vector2(OVERLAY_MARGIN, OVERLAY_MARGIN)
	if overlay_log_panel != null:
		overlay_log_panel.custom_minimum_size = OVERLAY_LOG_PANEL_SIZE
		overlay_log_panel.size = OVERLAY_LOG_PANEL_SIZE
		overlay_log_panel.position = Vector2(
			OVERLAY_MARGIN,
			maxf(OVERLAY_RESOURCE_PANEL_SIZE.y + OVERLAY_MARGIN * 2.0, board_size.y - OVERLAY_LOG_PANEL_SIZE.y - OVERLAY_MARGIN)
		)


func _render_units() -> void:
	var desired_unit_ids: Dictionary = {}
	for unit: Dictionary in _visual_units_for_render():
		var unit_id := str(unit["id"])
		desired_unit_ids[unit_id] = true
		var unit_node := unit_layer.get_node_or_null(unit_id) as Control
		if unit_node == null:
			unit_node = _create_unit_node(unit_id)
			unit_layer.add_child(unit_node)
		_update_unit_node(unit_node, unit)

	for child in unit_layer.get_children():
		if not desired_unit_ids.has(child.name):
			child.queue_free()


func _create_unit_node(unit_id: String) -> Control:
	var unit_node := Control.new()
	unit_node.name = unit_id
	unit_node.custom_minimum_size = Vector2(UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y)
	unit_node.size = Vector2(UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y)
	unit_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var contact:=TextureRect.new()
	contact.name="ContactShadow"
	contact.texture=AssetCatalog.texture("res://assets/combat/environment/contact_shadow.png")
	contact.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	contact.size=Vector2(96,28)
	contact.position=Vector2(UNIT_ICON_SIZE.x/2.0-48,UNIT_ICON_SIZE.y-14)
	contact.mouse_filter=Control.MOUSE_FILTER_IGNORE
	unit_node.add_child(contact)

	var elevation_shadow := ColorRect.new()
	elevation_shadow.name = "HighgroundUnitBaseShadow"
	elevation_shadow.color = Color(0.04, 0.025, 0.01, 0.58)
	elevation_shadow.position = HIGHGROUND_UNIT_BASE_OFFSET + Vector2(0, 6)
	elevation_shadow.custom_minimum_size = HIGHGROUND_UNIT_BASE_SIZE
	elevation_shadow.size = HIGHGROUND_UNIT_BASE_SIZE
	elevation_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit_node.add_child(elevation_shadow)

	var elevation_rim := PanelContainer.new()
	elevation_rim.name = "HighgroundUnitBase"
	elevation_rim.custom_minimum_size = HIGHGROUND_UNIT_BASE_SIZE
	elevation_rim.size = HIGHGROUND_UNIT_BASE_SIZE
	elevation_rim.position = HIGHGROUND_UNIT_BASE_OFFSET
	elevation_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	elevation_rim.add_theme_stylebox_override("panel", _highground_unit_base_style())
	unit_node.add_child(elevation_rim)

	var sprite := TextureRect.new()
	sprite.name = "Sprite"
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.custom_minimum_size = Vector2(UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y)
	sprite.size = Vector2(UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit_node.add_child(sprite)
	var fallback_label := Label.new()
	fallback_label.name = "VisualFallbackLabel"
	fallback_label.size = Vector2(UNIT_ICON_SIZE)
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_label.add_theme_font_size_override("font_size", 18)
	fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit_node.add_child(fallback_label)

	var resource_panel := PanelContainer.new()
	resource_panel.name = "ResourcePanel"
	resource_panel.custom_minimum_size = UNIT_RESOURCE_LABEL_SIZE
	resource_panel.size = UNIT_RESOURCE_LABEL_SIZE
	resource_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var resource_label := Label.new()
	resource_label.name = "Resources"
	resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resource_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resource_label.custom_minimum_size = UNIT_RESOURCE_LABEL_SIZE - Vector2(6, 2)
	resource_label.size = resource_label.custom_minimum_size
	resource_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resource_label.add_theme_font_size_override("font_size", 18)
	resource_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78))
	resource_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	resource_label.add_theme_constant_override("shadow_offset_x", 1)
	resource_label.add_theme_constant_override("shadow_offset_y", 1)
	resource_panel.add_child(resource_label)
	unit_node.add_child(resource_panel)

	var target_preview_panel := PanelContainer.new()
	target_preview_panel.name = "TargetPreviewPanel"
	target_preview_panel.custom_minimum_size = UNIT_TARGET_PREVIEW_LABEL_SIZE
	target_preview_panel.size = UNIT_TARGET_PREVIEW_LABEL_SIZE
	target_preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_preview_panel.visible = false

	var target_preview_label := Label.new()
	target_preview_label.name = "TargetPreview"
	target_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target_preview_label.custom_minimum_size = UNIT_TARGET_PREVIEW_LABEL_SIZE - Vector2(8, 4)
	target_preview_label.size = target_preview_label.custom_minimum_size
	target_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_preview_label.add_theme_font_size_override("font_size", 11)
	target_preview_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78))
	target_preview_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	target_preview_label.add_theme_constant_override("shadow_offset_x", 1)
	target_preview_label.add_theme_constant_override("shadow_offset_y", 1)
	target_preview_panel.add_child(target_preview_label)
	unit_node.add_child(target_preview_panel)

	var status_icon_row := HBoxContainer.new()
	status_icon_row.name = "StatusIconRow"
	status_icon_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_icon_row.add_theme_constant_override("separation", int(UNIT_STATUS_ICON_GAP))
	unit_node.add_child(status_icon_row)
	return unit_node


func _update_unit_node(unit_node: Control, unit: Dictionary) -> void:
	unit_node.custom_minimum_size = Vector2(UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y)
	unit_node.size = Vector2(UNIT_ICON_SIZE.x, UNIT_ICON_SIZE.y)
	unit_node.position = _unit_visual_pixel_position(unit)
	var is_dead := int(unit.get("resources", {}).get("hp", 0)) <= 0
	unit_node.z_index = _unit_render_z_index(unit, is_dead)
	unit_node.modulate = CORPSE_MODULATE if is_dead else Color(1, 1, 1, 1)

	var on_highground := false
	var elevation_shadow := unit_node.get_node_or_null("HighgroundUnitBaseShadow") as ColorRect
	if elevation_shadow != null:
		elevation_shadow.visible = on_highground
		elevation_shadow.position = HIGHGROUND_UNIT_BASE_OFFSET + Vector2(0, 6)
		elevation_shadow.custom_minimum_size = HIGHGROUND_UNIT_BASE_SIZE
		elevation_shadow.size = HIGHGROUND_UNIT_BASE_SIZE

	var elevation_rim := unit_node.get_node_or_null("HighgroundUnitBase") as PanelContainer
	if elevation_rim != null:
		elevation_rim.visible = on_highground
		elevation_rim.position = HIGHGROUND_UNIT_BASE_OFFSET
		elevation_rim.custom_minimum_size = HIGHGROUND_UNIT_BASE_SIZE
		elevation_rim.size = HIGHGROUND_UNIT_BASE_SIZE
		elevation_rim.add_theme_stylebox_override("panel", _highground_unit_base_style())

	var sprite := unit_node.get_node_or_null("Sprite") as TextureRect
	if sprite != null:
		sprite.texture = _unit_icon(unit)
		var sprite_dimensions := unit_art.sprite_size(unit, UNIT_ICON_SIZE)
		sprite.custom_minimum_size = Vector2(sprite_dimensions)
		sprite.size = Vector2(sprite_dimensions)
		sprite.position = unit_art.sprite_offset(unit, UNIT_ICON_SIZE)
	var fallback_label := unit_node.get_node_or_null("VisualFallbackLabel") as Label
	if fallback_label != null:
		fallback_label.visible = sprite == null or sprite.texture == null
		fallback_label.text = "%s\n%s" % [_unit_display_name(unit.id), str(unit.get("team", "")).capitalize()]

	var resource_panel := unit_node.get_node_or_null("ResourcePanel") as PanelContainer
	if resource_panel == null:
		return
	resource_panel.custom_minimum_size = UNIT_RESOURCE_LABEL_SIZE
	resource_panel.size = UNIT_RESOURCE_LABEL_SIZE
	resource_panel.visible = not is_dead
	resource_panel.position = Vector2(
		(float(UNIT_ICON_SIZE.x) - UNIT_RESOURCE_LABEL_SIZE.x) / 2.0,
		UNIT_RESOURCE_LABEL_OFFSET_Y
	)
	resource_panel.position.x += _unit_resource_label_nudge(unit)
	resource_panel.add_theme_stylebox_override("panel", _unit_resource_style(unit))

	var resource_label := resource_panel.get_node_or_null("Resources") as Label
	if resource_label != null:
		resource_label.text = _unit_resource_text(unit)
	resource_panel.size=UNIT_RESOURCE_LABEL_SIZE.max(resource_panel.get_combined_minimum_size())
	resource_panel.position.y=unit_art.idle_top(unit,UNIT_ICON_SIZE)-resource_panel.size.y-12.0

	_update_unit_status_icons(unit_node, unit)
	_update_unit_target_preview(unit_node, unit)


func _unit_render_z_index(unit: Dictionary, is_dead: bool) -> int:
	var position: Dictionary = unit.get("position", {})
	var x := int(position.get("x", 0))
	var y := int(position.get("y", 0))
	if is_dead:
		return y * 10 + x
	return 512 + y * 24 + x


func _update_unit_status_icons(unit_node: Control, unit: Dictionary) -> void:
	var status_icon_row := unit_node.get_node_or_null("StatusIconRow") as HBoxContainer
	if status_icon_row == null:
		return
	for child in status_icon_row.get_children():
		child.queue_free()
	if int(unit.get("resources", {}).get("hp", 0)) <= 0:
		status_icon_row.visible = false
		return

	var icon_ids := _unit_status_icon_ids(unit)
	status_icon_row.visible = not icon_ids.is_empty()
	if icon_ids.is_empty():
		return

	status_icon_row.position = Vector2(
		maxf(0.0, (float(UNIT_ICON_SIZE.x) - UNIT_RESOURCE_LABEL_SIZE.x) / 2.0 - UNIT_STATUS_ICON_SIZE.x - UNIT_STATUS_ICON_GAP + _unit_resource_label_nudge(unit)),
		UNIT_RESOURCE_LABEL_OFFSET_Y
	)
	status_icon_row.position.y=unit_node.get_node("ResourcePanel").position.y
	if unit_node.position.x+status_icon_row.position.x<0:
		var readout: Control=unit_node.get_node("ResourcePanel")
		status_icon_row.position.x=readout.position.x+readout.size.x+UNIT_STATUS_ICON_GAP

	for status_id: String in icon_ids:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = UNIT_STATUS_ICON_SIZE
		panel.size = UNIT_STATUS_ICON_SIZE
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.tooltip_text = _status_icon_tooltip(status_id)
		panel.add_theme_stylebox_override("panel", _status_icon_style(status_id))

		var label := Label.new()
		label.text = _status_icon_text(status_id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = UNIT_STATUS_ICON_SIZE
		label.size = UNIT_STATUS_ICON_SIZE
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.78))
		label.add_theme_color_override("font_shadow_color", Color(0.08, 0.0, 0.0, 1.0))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		panel.add_child(label)
		status_icon_row.add_child(panel)


func _update_unit_target_preview(unit_node: Control, unit: Dictionary) -> void:
	var target_preview_panel := unit_node.get_node_or_null("TargetPreviewPanel") as PanelContainer
	if target_preview_panel == null:
		return
	var preview_text := _unit_target_preview_text(unit)
	target_preview_panel.visible = preview_text != ""
	if preview_text == "":
		return
	target_preview_panel.custom_minimum_size = UNIT_TARGET_PREVIEW_LABEL_SIZE
	target_preview_panel.size = UNIT_TARGET_PREVIEW_LABEL_SIZE
	target_preview_panel.position = Vector2(
		(float(UNIT_ICON_SIZE.x) - UNIT_TARGET_PREVIEW_LABEL_SIZE.x) / 2.0,
		UNIT_RESOURCE_LABEL_OFFSET_Y + UNIT_RESOURCE_LABEL_SIZE.y + UNIT_TARGET_PREVIEW_GAP
	)
	var resource_panel := unit_node.get_node_or_null("ResourcePanel") as Control
	if resource_panel != null:
		target_preview_panel.position.y = resource_panel.position.y - target_preview_panel.size.y - UNIT_TARGET_PREVIEW_GAP
	target_preview_panel.position.x += _unit_resource_label_nudge(unit)
	target_preview_panel.add_theme_stylebox_override("panel", _unit_target_preview_style(unit))

	var target_preview_label := target_preview_panel.get_node_or_null("TargetPreview") as Label
	if target_preview_label != null:
		target_preview_label.text = preview_text
	target_preview_panel.size=UNIT_TARGET_PREVIEW_LABEL_SIZE.max(target_preview_panel.get_combined_minimum_size())
	if resource_panel!=null:
		target_preview_panel.position.y=resource_panel.position.y-target_preview_panel.size.y-UNIT_TARGET_PREVIEW_GAP
	target_preview_panel.position.x=clampf(target_preview_panel.position.x,-unit_node.position.x,board_root.size.x-unit_node.position.x-target_preview_panel.size.x)


func _unit_target_preview_text(unit: Dictionary) -> String:
	if int(unit.get("resources", {}).get("hp", 0)) <= 0:
		return ""
	if selected_action == "move":
		return ""
	var position: Dictionary = unit.get("position", {})
	return CombatTargetingPreview.unit_preview_text(_target_preview_for_position(position))


func _unit_target_preview_style(unit: Dictionary) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.04, 0.94)
	style.border_color = Color(0.35, 0.95, 0.35)
	var preview := _target_preview_for_position(unit.get("position", {}))
	if str(preview.get("rejection", "")) != "":
		style.border_color = Color(0.95, 0.20, 0.12)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _unit_status_icon_ids(unit: Dictionary) -> Array[String]:
	var icon_ids: Array[String] = []
	for status: Dictionary in unit.get("statuses", []):
		var status_id := str(status.get("id", ""))
		if status_id == "bleeding" or status_id == "guard_broken":
			icon_ids.append(status_id)
	return icon_ids


func _status_icon_text(status_id: String) -> String:
	match status_id:
		"bleeding":
			return "B"
		"guard_broken":
			return "G"
		_:
			return "?"


func _status_icon_tooltip(status_id: String) -> String:
	match status_id:
		"bleeding":
			return "Bleeding"
		"guard_broken":
			return "Guard broken"
		_:
			return status_id.capitalize()


func _status_icon_style(status_id: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	match status_id:
		"bleeding":
			style.bg_color = Color(0.42, 0.02, 0.03, 0.96)
			style.border_color = Color(0.95, 0.24, 0.18)
		"guard_broken":
			style.bg_color = Color(0.32, 0.18, 0.02, 0.96)
			style.border_color = Color(1.0, 0.68, 0.18)
		_:
			style.bg_color = Color(0.12, 0.10, 0.08, 0.96)
			style.border_color = Color(0.90, 0.78, 0.36)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.content_margin_left = 1
	style.content_margin_right = 1
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style


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
	var resources := _display_resources(unit)
	return "HP %s/%s\nAP %s  MP %s" % [
		int(resources.get("hp", 0)),
		int(unit["stats"].get("max_hp", 0)),
		int(resources.get("ap", 0)),
		int(resources.get("mp", 0)),
	]


func _display_resources(unit: Dictionary) -> Dictionary:
	var resources: Dictionary = unit.get("resources", {}).duplicate(true)
	var unit_id := str(unit.get("id", ""))
	if temporary_resource_overrides.has(unit_id):
		var overrides: Dictionary = temporary_resource_overrides.get(unit_id, {})
		for resource_id in overrides.keys():
			resources[resource_id] = overrides[resource_id]
	return resources


func _resource_override_callback(unit_id: String, resource_id: String, value: Variant) -> Callable:
	return func() -> void:
		_set_resource_override(unit_id, resource_id, value)


func _movement_facing_callback(unit_id: String, direction: String) -> Callable:
	return func() -> void:
		if unit_id == "" or direction == "":
			return
		unit_facing[unit_id] = direction
		_refresh_unit_sprite(unit_id)


func _set_resource_override(unit_id: String, resource_id: String, value: Variant) -> void:
	if unit_id == "":
		return
	var overrides: Dictionary = temporary_resource_overrides.get(unit_id, {})
	overrides[resource_id] = value
	temporary_resource_overrides[unit_id] = overrides
	_refresh_resource_display(unit_id)


func _apply_action_resource_spend(actor_id: String, events: Array, previous_state: Dictionary) -> void:
	var actor := _unit_by_id_in_state(previous_state, actor_id)
	if actor.is_empty():
		return
	for event: Dictionary in events:
		if event.get("type", "") != "action_performed" or str(event.get("actor_id", "")) != actor_id:
			continue
		var resources: Dictionary = actor.get("resources", {})
		if int(event.get("ap_spent", 0)) > 0:
			_set_resource_override(actor_id, "ap", maxi(0, int(resources.get("ap", 0)) - int(event.get("ap_spent", 0))))
		if int(event.get("mp_spent", 0)) > 0:
			_set_resource_override(actor_id, "mp", maxi(0, int(resources.get("mp", 0)) - int(event.get("mp_spent", 0))))
		return


func _apply_damage_resource_result(event: Dictionary) -> void:
	var target_id := str(event.get("target_unit_id", ""))
	if target_id == "":
		return
	_set_resource_override(target_id, "hp", int(event.get("hp_after", 0)))


func _refresh_resource_display(unit_id: String) -> void:
	var active_id := str(state.get("turn_state", {}).get("active_unit_id", ""))
	if unit_id == active_id:
		_render_board_overlay()
		_render_status()
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() and temporary_visual_units.has(unit_id):
		unit = temporary_visual_units[unit_id]
	if unit.is_empty():
		return
	var unit_node := unit_layer.get_node_or_null(unit_id) as Control
	if unit_node == null:
		return
	var resource_label := unit_node.get_node_or_null("ResourcePanel/Resources") as Label
	if resource_label != null:
		resource_label.text = _unit_resource_text(unit)
	var resource_panel := unit_node.get_node_or_null("ResourcePanel") as PanelContainer
	if resource_panel != null:
		resource_panel.add_theme_stylebox_override("panel", _unit_resource_style(unit))


func _unit_resource_style(unit: Dictionary) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.36, 0.62, 0.90) if unit.get("team", "") == "player" else Color(0.82, 0.30, 0.24)
	if int(_display_resources(unit).get("hp", 0)) < int(unit.get("stats", {}).get("max_hp", 0)):
		style.bg_color = Color("361b19")
	if str(unit.get("id", "")) == str(state.get("turn_state", {}).get("active_unit_id", "")):
		style.border_color = CombatPanelSkin.GOLD_COLOR
		style.set_border_width_all(3)
	if str(unit.get("id", "")) == hovered_unit_id:
		style.bg_color = style.bg_color.lightened(0.2)
		if str(unit.get("id", "")) != str(state.get("turn_state", {}).get("active_unit_id", "")):
			style.border_color = Color("fff4d7")
		style.set_border_width_all(3)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 3
	style.content_margin_top = 1
	style.content_margin_right = 3
	style.content_margin_bottom = 1
	return style


func _highground_unit_base_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.24, 0.08, 0.62)
	style.border_color = Color(0.98, 0.78, 0.30, 0.88)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 4
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


func _unit_resource_label_nudge(unit: Dictionary) -> float:
	var x := int(unit.get("position", {}).get("x", 0))
	var team := str(unit.get("team", "enemy"))
	if team == "player":
		return -10.0 if x % 2 == 0 else -4.0
	return 10.0 if x % 2 == 0 else 4.0


func _unit_icon(unit: Dictionary) -> Texture2D:
	var visual_actions := unit_visual_action
	var unit_id := str(unit.get("id", ""))
	if int(unit.get("resources", {}).get("hp", 0)) <= 0 and unit_id != "" and not unit_visual_action.has(unit_id):
		visual_actions = unit_visual_action.duplicate()
		visual_actions[unit_id] = _death_final_visual_action(unit)
	return unit_art.icon(unit, state, unit_facing, visual_actions, UNIT_ICON_SIZE)


func _death_final_visual_action(unit: Dictionary) -> String:
	var visual := _unit_visual_config(unit)
	return unit_art.processed_sheet_corpse_visual_action(str(visual.get("character", "")))


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


func _run_session() -> Node:
	return get_node("/root/DungeonRunSession")


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
		"move cost: %s MP" % _terrain_movement_cost(position),
	]
	var unit := _tooltip_unit_at(position)
	if not unit.is_empty():
		lines.append("%s / %s" % [_unit_display_name(unit.id), str(unit.get("team", "")).capitalize()])
		lines.append(_unit_resource_text(unit))
		lines.append("Status: " + _status_summary(unit))
	var preview := _target_preview_for_position(position)
	if not preview.is_empty():
		lines.append("selected action: legal" if preview.get("rejection", "") == "" else "rejected: %s" % preview.get("rejection", "unknown"))
	return panel_skin.wrap_tooltip("\n".join(lines), get_theme_font("font", "TooltipLabel"))


func _tooltip_unit_at(position: Dictionary) -> Dictionary:
	var living := _living_unit_at(position)
	if not living.is_empty():
		return living
	for unit: Dictionary in state.get("units", []):
		if _positions_equal(unit.get("position", {}), position):
			return unit
	return {}


func _set_hovered_unit(unit_id: String) -> void:
	if hovered_unit_id == unit_id:
		return
	hovered_unit_id = unit_id
	for node: Control in unit_layer.get_children():
		var unit := _unit_by_id(str(node.name))
		var panel := node.get_node_or_null("ResourcePanel") as PanelContainer
		if panel != null and not unit.is_empty():
			panel.add_theme_stylebox_override("panel", _unit_resource_style(unit))


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
	var command := _build_command("move", {
		"type": "tile",
		"position": position,
	})
	var result: Dictionary = CombatResolver.simulate(_state_without_log(), [command])
	for event: Dictionary in _events_after_startup(result["state"]["event_log"]):
		if event["type"] == "unit_moved":
			return event
	var cached := _target_preview_for_position(position)
	if not cached.is_empty() and cached.has("move_event"):
		return cached["move_event"]
	return {}


func _build_target_preview_cache() -> Dictionary:
	var cache: Dictionary = {}
	if _combat_result() != "in_progress":
		return cache
	if selected_action == "move":
		return _build_move_preview_cache()
	for y in range(int(state["grid"]["height"])):
		for x in range(int(state["grid"]["width"])):
			var position := {"x": x, "y": y}
			var command := _preview_command_for_position(position)
			if command.is_empty():
				continue
			cache[_position_key(position)] = _preview_for_command(command)
	return cache


func _build_move_preview_cache() -> Dictionary:
	var cache: Dictionary = {}
	var actor := _unit_by_id(str(state["turn_state"]["active_unit_id"]))
	if actor.is_empty() or actor.get("resources", {}).get("hp", 0) <= 0:
		return cache
	if not CombatActionModel.action_granted_to_unit(state, actor, "move"):
		return cache
	var uses_mp: bool = actor.get("resources", {}).has("mp")
	var max_cost := 1
	if uses_mp:
		max_cost = int(actor["resources"].get("mp", 0))
	elif int(actor["resources"].get("ap", 0)) < 1:
		return cache
	if max_cost < 1:
		return cache

	var start: Dictionary = actor["position"]
	var queue: Array[Dictionary] = [{"position": start, "path": [], "cost": 0}]
	var best_cost := {_position_key(start): 0}

	while not queue.is_empty():
		queue.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
			if int(first["cost"]) != int(second["cost"]):
				return int(first["cost"]) < int(second["cost"])
			if first["path"].size() != second["path"].size():
				return first["path"].size() < second["path"].size()
			var first_position: Dictionary = first["position"]
			var second_position: Dictionary = second["position"]
			if int(first_position["y"]) != int(second_position["y"]):
				return int(first_position["y"]) < int(second_position["y"])
			return int(first_position["x"]) < int(second_position["x"])
		)
		var item: Dictionary = queue.pop_front()
		var current: Dictionary = item["position"]
		var path: Array = item["path"]
		var cost := int(item["cost"])
		if (uses_mp and cost >= max_cost) or (not uses_mp and path.size() >= 1):
			continue
		for neighbor: Dictionary in _move_preview_neighbors(actor, current):
			var key := _position_key(neighbor)
			var next_cost := cost + _terrain_movement_cost(neighbor)
			if uses_mp and next_cost > max_cost:
				continue
			if best_cost.has(key) and int(best_cost[key]) <= next_cost:
				continue
			var next_path := path.duplicate(true)
			next_path.append(neighbor)
			best_cost[key] = next_cost
			cache[key] = {
				"rejection": "",
				"move_event": {
					"type": "unit_moved",
					"actor_id": actor["id"],
					"from": start,
					"to": neighbor,
					"mp_spent": next_cost if uses_mp else 0,
					"path": next_path,
				},
			}
			queue.append({"position": neighbor, "path": next_path, "cost": next_cost})
	return cache


func _move_preview_neighbors(actor: Dictionary, position: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = [
		{"x": position["x"] - 1, "y": position["y"]},
		{"x": position["x"] + 1, "y": position["y"]},
		{"x": position["x"], "y": position["y"] - 1},
		{"x": position["x"], "y": position["y"] + 1},
		{"x": position["x"] - 1, "y": position["y"] - 1},
		{"x": position["x"] - 1, "y": position["y"] + 1},
		{"x": position["x"] + 1, "y": position["y"] - 1},
		{"x": position["x"] + 1, "y": position["y"] + 1},
	]
	var legal: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		if _move_preview_position_is_legal(actor, position, candidate):
			legal.append(candidate)
	return legal


func _move_preview_position_is_legal(actor: Dictionary, origin: Dictionary, position: Dictionary) -> bool:
	if not _inside_grid(position):
		return false
	if _tile_type(position) == "blocked":
		return false
	var occupant := _living_unit_at(position)
	if not occupant.is_empty() and occupant.get("id", "") != actor.get("id", ""):
		return false
	if _is_diagonal_step(origin, position) and not _diagonal_step_allowed(origin, position):
		return false
	return true


func _terrain_movement_cost(position: Dictionary) -> int:
	match _tile_type(position):
		"highground":
			return 2
		"floor", "cover_low":
			return 1
		_:
			return 999999


func _inside_grid(position: Dictionary) -> bool:
	return (
		int(position.get("x", -1)) >= 0
		and int(position.get("y", -1)) >= 0
		and int(position.get("x", -1)) < int(state["grid"]["width"])
		and int(position.get("y", -1)) < int(state["grid"]["height"])
	)


func _is_diagonal_step(origin: Dictionary, position: Dictionary) -> bool:
	return (
		absi(int(origin.get("x", 0)) - int(position.get("x", 0))) == 1
		and absi(int(origin.get("y", 0)) - int(position.get("y", 0))) == 1
	)


func _diagonal_step_allowed(origin: Dictionary, position: Dictionary) -> bool:
	var side_a := {"x": int(position["x"]), "y": int(origin["y"])}
	var side_b := {"x": int(origin["x"]), "y": int(position["y"])}
	return _tile_type(side_a) != "blocked" and _tile_type(side_b) != "blocked"


func _preview_for_command(command: Dictionary) -> Dictionary:
	var result: Dictionary = CombatResolver.simulate(_state_without_log(), [command])
	var preview := {
		"rejection": "",
	}
	for event: Dictionary in _events_after_startup(result["state"]["event_log"]):
		if event["type"] == "command_rejected":
			preview["rejection"] = event.get("reason", "unknown")
			return preview
		if event["type"] == "action_performed":
			preview["ap_cost"] = event.get("ap_spent", "?")
		if event["type"] == "hit_roll_resolved":
			preview["hit_chance"] = event.get("hit_chance", "?")
			preview["hit_outcome"] = event.get("outcome", "")
			preview["roll"] = event.get("roll", "?")
		if event["type"] == "unit_moved":
			preview["move_event"] = event
		if event["type"] == "damage_applied":
			preview["damage"] = event.get("damage", "?")
			preview["raw_damage"] = event.get("raw_damage", "?")
			preview["damage_reduction"] = event.get("damage_reduction", "?")
			preview["hp_after"] = event.get("hp_after", "?")
	if str(preview.get("rejection", "")) == "" and preview.has("damage") and not preview.has("hit_chance"):
		preview["guaranteed_hit"] = true
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
	if selected_action == "deep_cut":
		var bleed_unit := _living_unit_at(position)
		if bleed_unit.is_empty():
			return {}
		return _build_command("deep_cut", {
			"type": "unit",
			"unit_id": bleed_unit["id"],
		})
	if selected_action == "guard_break":
		var guard_unit := _living_unit_at(position)
		if guard_unit.is_empty():
			return {}
		return _build_command("guard_break", {
			"type": "unit",
			"unit_id": guard_unit["id"],
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
		int(position["x"]) * (TILE_WIDTH + TILE_GAP),
		int(position["y"]) * (TILE_HEIGHT + TILE_GAP)
	)
	var elevation_offset := Vector2(0, HIGHGROUND_UNIT_OFFSET_Y) if _tile_type(position) == "highground" else Vector2.ZERO
	return tile_origin + Vector2((float(TILE_WIDTH) - float(UNIT_ICON_SIZE.x)) / 2.0, float(TILE_HEIGHT) - float(UNIT_ICON_SIZE.y)) + elevation_offset


func _combat_result() -> String:
	return CombatActionModel.combat_result(state)


func _combat_result_payload() -> Dictionary:
	for index in range(state.get("event_log", []).size() - 1, -1, -1):
		var event: Dictionary = state["event_log"][index]
		if event.get("type", "") == "combat_ended":
			return event.get("result_payload", {}).duplicate(true)
	var payload_result: Dictionary = CombatResolver.simulate(_state_without_log(), [])
	return payload_result.get("result_payload", {}).duplicate(true)
