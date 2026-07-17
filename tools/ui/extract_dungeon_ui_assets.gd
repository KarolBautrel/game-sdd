extends SceneTree

const SOURCE_ROOT := "res://assets/ui/dungeon/to_process"
const OUTPUT_ROOT := "res://assets/ui/dungeon/processed"
const MANIFEST_PATH := "res://assets/ui/dungeon/processed/manifest.json"
const MIN_COMPONENT_AREA := 700
const MARGIN := 4


func _init() -> void:
	var records: Array[Dictionary] = []
	_ensure_dir(OUTPUT_ROOT)
	for sheet_path: String in _png_files_recursive(SOURCE_ROOT):
		if sheet_path.contains("/example/"):
			continue
		records.append_array(_process_sheet(sheet_path))
	var manifest := {
		"source_root": SOURCE_ROOT,
		"output_root": OUTPUT_ROOT,
		"asset_count": records.size(),
		"assets": records,
	}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write dungeon UI manifest.")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	print("Extracted %s dungeon UI assets into %s" % [records.size(), OUTPUT_ROOT])
	quit(0)


func _process_sheet(sheet_path: String) -> Array[Dictionary]:
	var image := Image.load_from_file(sheet_path)
	if image == null or image.is_empty():
		push_error("Cannot load dungeon UI sheet: %s" % sheet_path)
		return []
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var mask: Array[bool] = []
	mask.resize(width * height)
	for y in range(height):
		for x in range(width):
			mask[y * width + x] = not _is_green_screen(image.get_pixel(x, y))
	var bounds := _component_bounds(mask, width, height)
	var sheet_id := sheet_path.get_file().get_basename()
	var output_dir := "%s/%s" % [OUTPUT_ROOT, sheet_id]
	_ensure_dir(output_dir)
	var records: Array[Dictionary] = []
	for index in range(bounds.size()):
		var bound: Dictionary = bounds[index]
		var crop := _transparent_crop(image, bound)
		var category := _category_for(sheet_id, crop.get_width(), crop.get_height())
		var output_path := "%s/%s_%02d.png" % [output_dir, sheet_id, index]
		var error := crop.save_png(output_path)
		if error != OK:
			push_error("Cannot save dungeon UI asset: %s" % output_path)
			continue
		records.append({
			"id": "%s_%02d" % [sheet_id, index],
			"category": category,
			"source": sheet_path,
			"path": output_path,
			"width": crop.get_width(),
			"height": crop.get_height(),
			"area": int(bound["area"]),
		})
		if category == "portrait":
			var head_record := _save_portrait_head_crop(sheet_id, crop, output_dir)
			if not head_record.is_empty():
				head_record["source"] = sheet_path
				records.append(head_record)
	return records


func _save_portrait_head_crop(sheet_id: String, portrait: Image, output_dir: String) -> Dictionary:
	var crop_x := int(round(float(portrait.get_width()) * 0.34))
	var crop_y := 0
	var crop_w := int(round(float(portrait.get_width()) * 0.36))
	var crop_h := int(round(float(portrait.get_height()) * 0.31))
	var head := portrait.get_region(Rect2i(crop_x, crop_y, crop_w, crop_h))
	var output_path := "%s/%s_head.png" % [output_dir, sheet_id]
	var error := head.save_png(output_path)
	if error != OK:
		push_error("Cannot save dungeon UI portrait head: %s" % output_path)
		return {}
	return {
		"id": "%s_head" % sheet_id,
		"category": "portrait_head",
		"path": output_path,
		"width": head.get_width(),
		"height": head.get_height(),
		"area": crop_w * crop_h,
	}


func _category_for(sheet_id: String, width: int, height: int) -> String:
	if sheet_id.contains("portrait") or sheet_id.contains("mercenary"):
		return "portrait"
	if sheet_id.contains("icons"):
		if width >= 110 and height >= 110:
			return "icon_large"
		if width >= 70 and height >= 70:
			return "icon_round"
		if width > height * 2:
			return "divider"
		return "icon_small"
	if width >= 850 and height >= 420:
		return "frame_map"
	if width >= 330 and height >= 320:
		return "frame_panel"
	if width >= 360 and height >= 150:
		return "frame_modal"
	if width >= 190 and height >= 70:
		return "frame_tile"
	if width >= 120 and height >= 40:
		return "button"
	return "ornament"


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
			if _is_green_screen(crop.get_pixel(x, y)) or _is_green_fringe(crop.get_pixel(x, y)):
				crop.set_pixel(x, y, Color(0, 0, 0, 0))
	return crop


func _is_green_screen(pixel: Color) -> bool:
	if pixel.a <= 0.01:
		return true
	return pixel.g >= 0.56 and pixel.r <= 0.42 and pixel.b <= 0.42 and pixel.g - maxf(pixel.r, pixel.b) >= 0.18


func _is_green_fringe(pixel: Color) -> bool:
	if pixel.a <= 0.01:
		return true
	if pixel.g < 0.22:
		return false
	var strongest_non_green := maxf(pixel.r, pixel.b)
	return pixel.g - strongest_non_green >= 0.08 and pixel.g > pixel.r * 1.20 and pixel.g > pixel.b * 1.20


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
