extends Control

const DEFAULT_ENCOUNTER_PATH := "res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json"
const TILE_TYPES := ["floor", "blocked", "cover_low", "highground"]
const BRUSH_MODES := ["Tile + Decoration", "Tile", "Decoration", "Erase Decoration"]
const TERRAIN_ROOT := "res://assets/combat/terrain/processed"
const CELL_SIZE := Vector2(76, 56)
const CELL_GAP := 2
const DECORATION_PREVIEW_SIZE := Vector2(44, 34)
const TILE_COLORS := {
	"floor": Color(0.16, 0.18, 0.16, 1.0),
	"blocked": Color(0.12, 0.10, 0.09, 1.0),
	"cover_low": Color(0.18, 0.15, 0.10, 1.0),
	"highground": Color(0.22, 0.20, 0.12, 1.0),
}
const TILE_BORDER_COLORS := {
	"floor": Color(0.28, 0.30, 0.28, 1.0),
	"blocked": Color(0.62, 0.24, 0.20, 1.0),
	"cover_low": Color(0.76, 0.58, 0.26, 1.0),
	"highground": Color(0.86, 0.76, 0.34, 1.0),
}

var encounter_path := DEFAULT_ENCOUNTER_PATH
var encounter: Dictionary = {}
var tile_by_key: Dictionary = {}
var decoration_by_key: Dictionary = {}
var decoration_paths: Array[String] = []
var decoration_texture_cache: Dictionary = {}
var selected_tile_type := "floor"
var selected_brush_mode := "Tile + Decoration"
var selected_decoration_path := ""
var is_dragging := false

var path_edit: LineEdit
var status_label: Label
var tile_type_option: OptionButton
var brush_mode_option: OptionButton
var decoration_option: OptionButton
var grid_container: GridContainer
var board_scroll: ScrollContainer
var selected_decoration_preview: TextureRect
var selected_decoration_path_label: Label


func _ready() -> void:
	_build_ui()
	_load_decoration_paths()
	_populate_decoration_option()
	_load_encounter(encounter_path)


func _build_ui() -> void:
	var root := HBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var tools := VBoxContainer.new()
	tools.custom_minimum_size = Vector2(430, 0)
	tools.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tools.add_theme_constant_override("separation", 8)
	root.add_child(tools)

	var title := Label.new()
	title.text = "Combat Map Editor"
	title.add_theme_font_size_override("font_size", 22)
	tools.add_child(title)

	var path_label := Label.new()
	path_label.text = "Encounter JSON path"
	tools.add_child(path_label)

	path_edit = LineEdit.new()
	path_edit.text = encounter_path
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(path_edit)

	var path_buttons := HBoxContainer.new()
	path_buttons.add_theme_constant_override("separation", 6)
	tools.add_child(path_buttons)

	var load_button := Button.new()
	load_button.text = "Load"
	load_button.pressed.connect(func() -> void:
		_load_encounter(path_edit.text.strip_edges())
	)
	path_buttons.add_child(load_button)

	var save_button := Button.new()
	save_button.text = "Save JSON"
	save_button.pressed.connect(func() -> void:
		_save_encounter(path_edit.text.strip_edges())
	)
	path_buttons.add_child(save_button)

	var reload_assets_button := Button.new()
	reload_assets_button.text = "Reload Assets"
	reload_assets_button.pressed.connect(func() -> void:
		_load_decoration_paths()
		_populate_decoration_option()
		_set_status("Reloaded %s terrain decoration assets." % decoration_paths.size())
	)
	path_buttons.add_child(reload_assets_button)

	brush_mode_option = OptionButton.new()
	for mode: String in BRUSH_MODES:
		brush_mode_option.add_item(mode)
	brush_mode_option.item_selected.connect(func(index: int) -> void:
		selected_brush_mode = brush_mode_option.get_item_text(index)
	)
	tools.add_child(_labeled_control("Brush mode", brush_mode_option))

	tile_type_option = OptionButton.new()
	for tile_type: String in TILE_TYPES:
		tile_type_option.add_item(tile_type)
	tile_type_option.item_selected.connect(func(index: int) -> void:
		selected_tile_type = tile_type_option.get_item_text(index)
	)
	tools.add_child(_labeled_control("Tile type", tile_type_option))

	decoration_option = OptionButton.new()
	decoration_option.item_selected.connect(func(index: int) -> void:
		selected_decoration_path = str(decoration_option.get_item_metadata(index))
		if selected_decoration_path != "" and selected_brush_mode == "Tile":
			selected_brush_mode = "Tile + Decoration"
			brush_mode_option.select(0)
		_update_selected_decoration_preview()
	)
	tools.add_child(_labeled_control("Decoration asset", decoration_option))

	selected_decoration_preview = TextureRect.new()
	selected_decoration_preview.custom_minimum_size = Vector2(150, 110)
	selected_decoration_preview.size = Vector2(150, 110)
	selected_decoration_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selected_decoration_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tools.add_child(selected_decoration_preview)

	selected_decoration_path_label = Label.new()
	selected_decoration_path_label.text = "Selected decoration: none"
	selected_decoration_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_decoration_path_label.add_theme_font_size_override("font_size", 11)
	tools.add_child(selected_decoration_path_label)

	var help := Label.new()
	help.text = "Left click/drag paints selected brush.\nRight click clears decoration on a tile.\nTile types affect gameplay. Decorations are visual props.\nTile mode ignores selected assets. Use Tile + Decoration for blockers/cover with exact art."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 13)
	tools.add_child(help)

	status_label = Label.new()
	status_label.text = "Ready."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 13)
	tools.add_child(status_label)

	board_scroll = ScrollContainer.new()
	board_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(board_scroll)

	grid_container = GridContainer.new()
	grid_container.add_theme_constant_override("h_separation", CELL_GAP)
	grid_container.add_theme_constant_override("v_separation", CELL_GAP)
	board_scroll.add_child(grid_container)


func _labeled_control(label_text: String, control: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	box.add_child(label)
	box.add_child(control)
	return box


func _load_encounter(path: String) -> void:
	if path == "":
		_set_status("Cannot load: path is empty.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_set_status("Cannot open encounter: %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_set_status("Invalid encounter JSON: %s" % path)
		return
	encounter_path = path
	path_edit.text = encounter_path
	encounter = parsed
	_rebuild_lookup_tables()
	_render_board()
	_set_status("Loaded %s. Board %sx%s, %s decorations." % [
		encounter_path,
		int(encounter.get("grid", {}).get("width", 0)),
		int(encounter.get("grid", {}).get("height", 0)),
		decoration_by_key.size(),
	])


func _save_encounter(path: String) -> void:
	if path == "":
		_set_status("Cannot save: path is empty.")
		return
	if encounter.is_empty():
		_set_status("Cannot save: no encounter loaded.")
		return
	_write_lookup_tables_to_encounter()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_set_status("Cannot write encounter: %s" % path)
		return
	file.store_string(JSON.stringify(encounter, "  "))
	_set_status("Saved %s" % path)


func _rebuild_lookup_tables() -> void:
	tile_by_key.clear()
	decoration_by_key.clear()
	var grid: Dictionary = encounter.get("grid", {})
	for tile: Dictionary in grid.get("tiles", []):
		var position := {"x": int(tile.get("x", 0)), "y": int(tile.get("y", 0))}
		tile_by_key[_position_key(position)] = str(tile.get("type", "floor"))
	for decoration: Dictionary in encounter.get("terrain_decorations", []):
		var position := {"x": int(decoration.get("x", 0)), "y": int(decoration.get("y", 0))}
		decoration_by_key[_position_key(position)] = decoration.duplicate(true)


func _write_lookup_tables_to_encounter() -> void:
	var width := int(encounter.get("grid", {}).get("width", 0))
	var height := int(encounter.get("grid", {}).get("height", 0))
	var tiles: Array[Dictionary] = []
	for y in range(height):
		for x in range(width):
			var position := {"x": x, "y": y}
			tiles.append({
				"x": x,
				"y": y,
				"type": _tile_type(position),
			})
	encounter["grid"]["tiles"] = tiles

	var decorations: Array[Dictionary] = []
	for y in range(height):
		for x in range(width):
			var key := _position_key({"x": x, "y": y})
			if decoration_by_key.has(key):
				decorations.append(decoration_by_key[key])
	if decorations.is_empty():
		encounter.erase("terrain_decorations")
	else:
		encounter["terrain_decorations"] = decorations


func _render_board() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	var grid: Dictionary = encounter.get("grid", {})
	var width := int(grid.get("width", 0))
	var height := int(grid.get("height", 0))
	grid_container.columns = width
	for y in range(height):
		for x in range(width):
			grid_container.add_child(_create_cell({"x": x, "y": y}))


func _create_cell(position: Dictionary) -> Button:
	var cell := Button.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.size = CELL_SIZE
	cell.text = _cell_label(position)
	cell.tooltip_text = _cell_tooltip(position)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_cell_style(cell, position)
	_add_decoration_preview(cell, position)
	cell.gui_input.connect(func(event: InputEvent) -> void:
		_on_cell_gui_input(event, position)
	)
	cell.mouse_entered.connect(func() -> void:
		if is_dragging:
			_apply_brush(position)
	)
	return cell


func _on_cell_gui_input(event: InputEvent, position: Dictionary) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = mouse_event.pressed
			if mouse_event.pressed:
				_apply_brush(position)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_clear_decoration(position)
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_dragging = true


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			is_dragging = false


func _apply_brush(position: Dictionary) -> void:
	match selected_brush_mode:
		"Tile":
			_set_tile_type(position, selected_tile_type)
			_set_status("Painted tile %s at %s. Selected decoration was ignored because brush mode is Tile." % [selected_tile_type, _position_key(position)])
		"Decoration":
			_set_decoration(position, selected_decoration_path)
		"Tile + Decoration":
			_set_tile_type(position, selected_tile_type)
			_set_decoration(position, selected_decoration_path)
		"Erase Decoration":
			_clear_decoration(position)
	_refresh_cell(position)


func _set_tile_type(position: Dictionary, tile_type: String) -> void:
	if not TILE_TYPES.has(tile_type):
		return
	tile_by_key[_position_key(position)] = tile_type


func _set_decoration(position: Dictionary, path: String) -> void:
	if path == "":
		_set_status("No decoration selected. Pick an asset or use Tile brush.")
		return
	decoration_by_key[_position_key(position)] = {
		"x": int(position.get("x", 0)),
		"y": int(position.get("y", 0)),
		"path": path,
		"kind": _decoration_kind_from_path(path),
	}
	_set_status("Painted decoration %s at %s" % [_asset_label(path), _position_key(position)])


func _clear_decoration(position: Dictionary) -> void:
	decoration_by_key.erase(_position_key(position))
	_refresh_cell(position)
	_set_status("Cleared decoration at %s" % _position_key(position))


func _refresh_cell(position: Dictionary) -> void:
	var width := int(encounter.get("grid", {}).get("width", 0))
	var index := int(position.get("y", 0)) * width + int(position.get("x", 0))
	if index < 0 or index >= grid_container.get_child_count():
		return
	var old_cell := grid_container.get_child(index)
	var new_cell := _create_cell(position)
	grid_container.remove_child(old_cell)
	old_cell.queue_free()
	grid_container.add_child(new_cell)
	grid_container.move_child(new_cell, index)


func _apply_cell_style(cell: Button, position: Dictionary) -> void:
	var tile_type := _tile_type(position)
	var style := StyleBoxFlat.new()
	style.bg_color = TILE_COLORS.get(tile_type, TILE_COLORS["floor"])
	style.border_color = TILE_BORDER_COLORS.get(tile_type, TILE_BORDER_COLORS["floor"])
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	cell.add_theme_stylebox_override("normal", style)
	cell.add_theme_stylebox_override("hover", _hover_style(style))
	cell.add_theme_stylebox_override("pressed", _hover_style(style))
	cell.add_theme_stylebox_override("focus", style)
	cell.add_theme_color_override("font_color", Color(0.94, 0.90, 0.78))
	cell.add_theme_font_size_override("font_size", 10)


func _hover_style(base: StyleBoxFlat) -> StyleBoxFlat:
	var style := base.duplicate() as StyleBoxFlat
	style.bg_color = base.bg_color.lightened(0.08)
	style.border_color = Color(1.0, 0.82, 0.34, 1.0)
	return style


func _add_decoration_preview(cell: Button, position: Dictionary) -> void:
	var decoration := _decoration_at(position)
	if decoration.is_empty():
		return
	var texture := _decoration_texture(str(decoration.get("path", "")))
	if texture == null:
		return
	var preview := TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = DECORATION_PREVIEW_SIZE
	preview.size = DECORATION_PREVIEW_SIZE
	preview.position = Vector2((CELL_SIZE.x - DECORATION_PREVIEW_SIZE.x) / 2.0, 15)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(preview)


func _cell_label(position: Dictionary) -> String:
	var decoration := _decoration_at(position)
	var decoration_label := ""
	if not decoration.is_empty():
		decoration_label = "\n%s" % _short_asset_label(str(decoration.get("path", "")))
	return "%s,%s\n%s%s" % [
		int(position.get("x", 0)),
		int(position.get("y", 0)),
		_tile_short_label(_tile_type(position)),
		decoration_label,
	]


func _cell_tooltip(position: Dictionary) -> String:
	var decoration := _decoration_at(position)
	var text := "(%s,%s) %s" % [position.get("x", 0), position.get("y", 0), _tile_type(position)]
	if not decoration.is_empty():
		text += "\n%s" % str(decoration.get("path", ""))
	return text


func _tile_short_label(tile_type: String) -> String:
	match tile_type:
		"blocked":
			return "BLK"
		"cover_low":
			return "COV"
		"highground":
			return "HIGH"
		_:
			return "FLR"


func _tile_type(position: Dictionary) -> String:
	return str(tile_by_key.get(_position_key(position), "floor"))


func _decoration_at(position: Dictionary) -> Dictionary:
	return decoration_by_key.get(_position_key(position), {})


func _position_key(position: Dictionary) -> String:
	return "%s,%s" % [int(position.get("x", 0)), int(position.get("y", 0))]


func _load_decoration_paths() -> void:
	decoration_paths.clear()
	_collect_png_paths(TERRAIN_ROOT, decoration_paths)
	decoration_paths.sort()


func _collect_png_paths(root: String, output: Array[String]) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
		var path := "%s/%s" % [root, file_name]
		if dir.current_is_dir():
			_collect_png_paths(path, output)
		elif file_name.to_lower().ends_with(".png"):
			output.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _populate_decoration_option() -> void:
	decoration_option.clear()
	decoration_option.add_item("(no decoration selected)")
	decoration_option.set_item_metadata(0, "")
	for path: String in decoration_paths:
		var index := decoration_option.item_count
		decoration_option.add_item(_asset_label(path))
		decoration_option.set_item_metadata(index, path)
	if decoration_option.item_count > 0:
		decoration_option.select(0)
	selected_decoration_path = ""
	_update_selected_decoration_preview()


func _asset_label(path: String) -> String:
	return path.replace("res://assets/combat/terrain/processed/", "")


func _short_asset_label(path: String) -> String:
	var file_name := path.get_file().get_basename()
	if file_name == "":
		return "*"
	return file_name


func _update_selected_decoration_preview() -> void:
	selected_decoration_preview.texture = _decoration_texture(selected_decoration_path)
	if selected_decoration_path_label != null:
		selected_decoration_path_label.text = "Selected decoration: %s" % ("none" if selected_decoration_path == "" else _asset_label(selected_decoration_path))


func _decoration_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if decoration_texture_cache.has(path):
		return decoration_texture_cache[path]
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	decoration_texture_cache[path] = texture
	return texture


func _decoration_kind_from_path(path: String) -> String:
	var file_name := path.get_file().get_basename()
	if file_name == "":
		return "decoration"
	return file_name.replace("-", "_").replace(" ", "_").to_lower()


func _set_status(message: String) -> void:
	status_label.text = message
