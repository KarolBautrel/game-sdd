extends RefCounted
## Authoring checks, independent of tactical command resolution.

const DRAFT_META := &"combat_authoring_draft"
const PATH_META := &"combat_authoring_path"


static func materialize(source: Dictionary) -> Dictionary:
	var draft := source.duplicate(true)
	var path := str(draft.get("map_path", ""))
	if path != "":
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return {}
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not parsed is Dictionary:
			return {}
		draft["grid"] = {"width": parsed.get("width", 0), "height": parsed.get("height", 0), "tiles": parsed.get("tiles", []).duplicate(true)}
		for key: String in ["background_path", "terrain_theme", "terrain_decorations"]:
			if not draft.has(key) and parsed.has(key):
				draft[key] = parsed[key].duplicate(true) if parsed[key] is Array else parsed[key]
		draft.erase("map_path")
	return draft


static func errors(draft: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	var grid: Dictionary = draft.get("grid", {})
	var width := int(grid.get("width", 0))
	var height := int(grid.get("height", 0))
	if width < 1 or height < 1 or width * height > 4096:
		failures.append("Board dimensions must be positive and at most 4096 cells.")
		return failures
	var tiles: Dictionary = {}
	for tile: Dictionary in grid.get("tiles", []):
		var pos := Vector2i(int(tile.get("x", -1)), int(tile.get("y", -1)))
		if pos.x < 0 or pos.y < 0 or pos.x >= width or pos.y >= height or tiles.has(pos):
			failures.append("Duplicate/out-of-bounds tile %s." % pos)
		if not ["floor", "blocked", "cover_low", "highground"].has(str(tile.get("type", ""))):
			failures.append("Unknown tile type at %s." % pos)
		tiles[pos] = tile.get("type", "")
	if tiles.size() != width * height:
		failures.append("Board must contain every tile.")
	var occupied: Dictionary = {}
	for unit: Dictionary in draft.get("units", []):
		var point: Dictionary = unit.get("position", {})
		var pos := Vector2i(int(point.get("x", -1)), int(point.get("y", -1)))
		if not tiles.has(pos) or tiles.get(pos) == "blocked":
			failures.append("Invalid/blocked start for %s at %s." % [unit.get("id", "?"), pos])
		if occupied.has(pos):
			failures.append("Overlapping unit starts at %s." % pos)
		occupied[pos] = true
	if draft.get("units", []).is_empty():
		failures.append("Encounter needs units before play.")
	return failures
