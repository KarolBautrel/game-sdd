extends SceneTree

const SOURCE_ROOT := "res://assets/combat/terrain/to_process"
const OUTPUT_ROOT := "res://assets/combat/terrain/processed"
const MANIFEST_PATH := "res://assets/combat/terrain/processed/processed_terrain_manifest.json"
const MIN_COMPONENT_AREA := 900
const MARGIN := 4
const FLOOR_ATLAS_COLUMNS := 4
const FLOOR_ATLAS_ROWS := 4


func _init() -> void:
	var records: Array[Dictionary] = []
	_ensure_dir(OUTPUT_ROOT)
	for theme: String in _subdirs(SOURCE_ROOT):
		for sheet_path: String in _png_files_recursive("%s/%s" % [SOURCE_ROOT, theme]):
			records.append_array(_process_sheet(sheet_path, theme))
	var manifest := {
		"source_root": SOURCE_ROOT,
		"output_root": OUTPUT_ROOT,
		"asset_count": records.size(),
		"assets": records,
	}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write terrain manifest.")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	print("Extracted %s terrain assets into %s" % [records.size(), OUTPUT_ROOT])
	quit(0)


func _process_sheet(sheet_path: String, theme: String) -> Array[Dictionary]:
	var image := Image.load_from_file(sheet_path)
	if image == null or image.is_empty():
		push_error("Cannot load terrain sheet: %s" % sheet_path)
		return []
	image.convert(Image.FORMAT_RGBA8)
	var sheet_id := sheet_path.get_file().get_basename()
	if sheet_id.begins_with("floor_"):
		return _process_floor_atlas(image, sheet_path, theme, sheet_id)

	var width := image.get_width()
	var height := image.get_height()
	var mask: Array[bool] = []
	mask.resize(width * height)
	for y in range(height):
		for x in range(width):
			mask[y * width + x] = not _is_green_screen(image.get_pixel(x, y))
	var bounds := _component_bounds(mask, width, height)
	var output_dir := "%s/%s/%s" % [OUTPUT_ROOT, theme, sheet_id]
	_ensure_dir(output_dir)
	var records: Array[Dictionary] = []
	for index in range(bounds.size()):
		var bound: Dictionary = bounds[index]
		var crop := _transparent_crop(image, bound)
		var output_path := "%s/%s_%02d.png" % [output_dir, sheet_id, index]
		var error := crop.save_png(output_path)
		if error != OK:
			push_error("Cannot save terrain asset: %s" % output_path)
			continue
		records.append({
			"id": "%s_%02d" % [sheet_id, index],
			"theme": theme,
			"source": sheet_path,
			"path": output_path,
			"width": crop.get_width(),
			"height": crop.get_height(),
			"area": int(bound["area"]),
		})
	return records


func _process_floor_atlas(image: Image, sheet_path: String, theme: String, sheet_id: String) -> Array[Dictionary]:
	var output_dir := "%s/%s/%s" % [OUTPUT_ROOT, theme, sheet_id]
	_ensure_dir(output_dir)
	var tile_width := image.get_width() / FLOOR_ATLAS_COLUMNS
	var tile_height := image.get_height() / FLOOR_ATLAS_ROWS
	var records: Array[Dictionary] = []
	for row in range(FLOOR_ATLAS_ROWS):
		for column in range(FLOOR_ATLAS_COLUMNS):
			var index := row * FLOOR_ATLAS_COLUMNS + column
			var source_rect := Rect2i(
				Vector2i(column * tile_width, row * tile_height),
				Vector2i(tile_width, tile_height)
			)
			var crop := image.get_region(source_rect)
			var output_path := "%s/%s_%02d.png" % [output_dir, sheet_id, index]
			var error := crop.save_png(output_path)
			if error != OK:
				push_error("Cannot save floor asset: %s" % output_path)
				continue
			records.append({
				"id": "%s_%02d" % [sheet_id, index],
				"theme": theme,
				"category": "floor",
				"source": sheet_path,
				"path": output_path,
				"width": crop.get_width(),
				"height": crop.get_height(),
				"area": crop.get_width() * crop.get_height(),
				"atlas_column": column,
				"atlas_row": row,
			})
	return records


func _component_bounds(mask: Array[bool], width: int, height: int) -> Array[Dictionary]:
	var visited: Array[bool] = []
	visited.resize(width * height)
	var bounds: Array[Dictionary] = []
	for y in range(height):
		for x in range(width):
			var start_index := y * width + x
			if visited[start_index] or not mask[start_index]:
				continue
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			var cursor := 0
			visited[start_index] = true
			var min_x := x
			var max_x := x
			var min_y := y
			var max_y := y
			var area := 0
			while cursor < queue.size():
				var current := queue[cursor]
				cursor += 1
				area += 1
				min_x = mini(min_x, current.x)
				max_x = maxi(max_x, current.x)
				min_y = mini(min_y, current.y)
				max_y = maxi(max_y, current.y)
				for ny in range(current.y - 1, current.y + 2):
					for nx in range(current.x - 1, current.x + 2):
						if nx == current.x and ny == current.y:
							continue
						if nx < 0 or ny < 0 or nx >= width or ny >= height:
							continue
						var next_index := ny * width + nx
						if visited[next_index] or not mask[next_index]:
							continue
						visited[next_index] = true
						queue.append(Vector2i(nx, ny))
			if area >= MIN_COMPONENT_AREA:
				bounds.append({
					"min_x": min_x,
					"min_y": min_y,
					"max_x": max_x,
					"max_y": max_y,
					"area": area,
				})
	bounds.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["min_y"]) == int(b["min_y"]):
			return int(a["min_x"]) < int(b["min_x"])
		return int(a["min_y"]) < int(b["min_y"])
	)
	return bounds


func _transparent_crop(image: Image, bound: Dictionary) -> Image:
	var min_x: int = maxi(0, int(bound["min_x"]) - MARGIN)
	var min_y: int = maxi(0, int(bound["min_y"]) - MARGIN)
	var max_x: int = mini(image.get_width() - 1, int(bound["max_x"]) + MARGIN)
	var max_y: int = mini(image.get_height() - 1, int(bound["max_y"]) + MARGIN)
	var crop := image.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
	for y in range(crop.get_height()):
		for x in range(crop.get_width()):
			if _is_green_screen(crop.get_pixel(x, y)):
				crop.set_pixel(x, y, Color(0, 0, 0, 0))
	return crop


func _is_green_screen(pixel: Color) -> bool:
	if pixel.a <= 0.01:
		return true
	return pixel.g >= 0.58 and pixel.r <= 0.44 and pixel.b <= 0.44 and pixel.g - maxf(pixel.r, pixel.b) >= 0.17


func _subdirs(root: String) -> Array[String]:
	var dir := DirAccess.open(root)
	if dir == null:
		return []
	var names: Array[String] = []
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir() and not name.begins_with("."):
			names.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	return names


func _png_files_recursive(root: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(root)
	if dir == null:
		return files
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var path := "%s/%s" % [root, name]
		if dir.current_is_dir() and not name.begins_with("."):
			files.append_array(_png_files_recursive(path))
		elif name.get_extension().to_lower() == "png":
			files.append(path)
		name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files


func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
