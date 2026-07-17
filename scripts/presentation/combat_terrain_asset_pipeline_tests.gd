extends SceneTree

const CombatScenarioCatalog := preload("res://scripts/presentation/combat/combat_scenario_catalog.gd")
const CombatDebugScript := preload("res://scripts/presentation/combat_debug.gd")

const MANIFEST_PATH := "res://assets/combat/terrain/processed/processed_terrain_manifest.json"
const GRASS_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_terrain_grass_showcase.json"
const DUNGEON_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_terrain_dungeon_showcase.json"
const NATURE_BACKGROUND_PATH := "res://assets/combat/terrain/backgrounds/old_mine_meadow_01_deep_green.png"
const DUNGEON_BACKGROUND_PATH := "res://assets/combat/terrain/backgrounds/old_mine_dungeon_00_stone.png"
const EXPECTED_BACKGROUND_SIZE := Vector2i(2520, 1144)


func _init() -> void:
	var errors: Array[String] = []
	var manifest := _load_json(MANIFEST_PATH)
	_expect_true(errors, "terrain manifest count", int(manifest.get("asset_count", 0)) >= 40)
	_expect_true(errors, "nature terrain assets exist", _theme_count(manifest, "nature") >= 20)
	_expect_true(errors, "dungeon terrain assets exist", _theme_count(manifest, "dungeon") >= 20)
	_expect_true(errors, "floor terrain assets exist", _category_count(manifest, "floor") >= 48)
	_expect_true(errors, "manifest has tall nature asset", _has_asset_at_least(manifest, "nature", 200, 300))
	_expect_true(errors, "manifest has tall dungeon asset", _has_asset_at_least(manifest, "dungeon", 120, 250))
	_expect_true(errors, "processed prop transparency", _transparent_non_floor_count(manifest) >= 40)
	_expect_equal(errors, "nature background combat scale", _image_size(NATURE_BACKGROUND_PATH), EXPECTED_BACKGROUND_SIZE)
	_expect_equal(errors, "dungeon background combat scale", _image_size(DUNGEON_BACKGROUND_PATH), EXPECTED_BACKGROUND_SIZE)
	for asset: Dictionary in manifest.get("assets", []):
		var path := str(asset.get("path", ""))
		_expect_true(errors, "asset exists %s" % path, FileAccess.file_exists(path))

	var grass_showcase := _load_json(GRASS_SHOWCASE_PATH)
	var dungeon_showcase := _load_json(DUNGEON_SHOWCASE_PATH)
	_expect_equal(errors, "grass showcase theme", grass_showcase.get("terrain_theme", ""), "nature")
	_expect_equal(errors, "dungeon showcase theme", dungeon_showcase.get("terrain_theme", ""), "dungeon")
	_expect_equal(errors, "grass showcase grid width", grass_showcase.get("grid", {}).get("width", 0), 18)
	_expect_equal(errors, "dungeon showcase grid width", dungeon_showcase.get("grid", {}).get("width", 0), 18)
	_expect_true(errors, "grass handmade decorations", grass_showcase.get("terrain_decorations", []).size() >= 8)
	_expect_true(errors, "dungeon handmade decorations", dungeon_showcase.get("terrain_decorations", []).size() >= 8)
	_expect_equal(errors, "catalog grass path", CombatScenarioCatalog.path_for_id("terrain_grass_showcase"), GRASS_SHOWCASE_PATH)
	_expect_equal(errors, "catalog dungeon path", CombatScenarioCatalog.path_for_id("terrain_dungeon_showcase"), DUNGEON_SHOWCASE_PATH)
	var debug := CombatDebugScript.new()
	debug.state = {
		"terrain_theme": "nature",
		"terrain_decorations": [{"x": 0, "y": 0, "path": "res://assets/combat/terrain/processed/nature/nature_1/nature_1_03.png"}],
		"grid": {"tiles": [{"x": 0, "y": 0, "type": "blocked"}]},
	}
	_expect_true(errors, "nature decoration uses processed asset", debug._tile_decoration_path({"x": 0, "y": 0}).contains("/terrain/processed/nature/"))
	_expect_equal(errors, "nature handmade empty tile has no fallback", debug._tile_decoration_path({"x": 1, "y": 0}), "")
	debug.state = {
		"terrain_theme": "dungeon",
		"terrain_decorations": [{"x": 0, "y": 0, "path": "res://assets/combat/terrain/processed/dungeon/dung_1/dung_1_04.png"}],
		"grid": {"tiles": [{"x": 0, "y": 0, "type": "blocked"}]},
	}
	_expect_true(errors, "dungeon decoration uses processed asset", debug._tile_decoration_path({"x": 0, "y": 0}).contains("/terrain/processed/dungeon/"))
	_expect_equal(errors, "dungeon handmade empty tile has no fallback", debug._tile_decoration_path({"x": 1, "y": 0}), "")
	debug.free()

	if errors.is_empty():
		print("Combat terrain asset pipeline validation passed.")
	else:
		for error: String in errors:
			push_error(error)
		quit(1)
		return
	quit(0)


func _theme_count(manifest: Dictionary, theme: String) -> int:
	var count := 0
	for asset: Dictionary in manifest.get("assets", []):
		if str(asset.get("theme", "")) == theme:
			count += 1
	return count


func _category_count(manifest: Dictionary, category: String) -> int:
	var count := 0
	for asset: Dictionary in manifest.get("assets", []):
		if str(asset.get("category", "")) == category:
			count += 1
	return count


func _transparent_non_floor_count(manifest: Dictionary) -> int:
	var count := 0
	for asset: Dictionary in manifest.get("assets", []):
		if str(asset.get("category", "")) == "floor":
			continue
		if _image_has_transparency(str(asset.get("path", ""))):
			count += 1
	return count


func _has_asset_at_least(manifest: Dictionary, theme: String, width: int, height: int) -> bool:
	for asset: Dictionary in manifest.get("assets", []):
		if str(asset.get("theme", "")) != theme:
			continue
		if int(asset.get("width", 0)) >= width and int(asset.get("height", 0)) >= height:
			return true
	return false


func _image_has_transparency(path: String) -> bool:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return false
	image.convert(Image.FORMAT_RGBA8)
	var samples := [
		Vector2i(0, 0),
		Vector2i(image.get_width() - 1, 0),
		Vector2i(0, image.get_height() - 1),
		Vector2i(image.get_width() - 1, image.get_height() - 1),
	]
	for sample: Vector2i in samples:
		if image.get_pixel(sample.x, sample.y).a < 0.1:
			return true
	return false


func _image_size(path: String) -> Vector2i:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return Vector2i.ZERO
	return image.get_size()


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s" % path)
		quit(1)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON dictionary in %s" % path)
		quit(1)
		return {}
	return parsed


func _expect_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		errors.append("%s: expected %s, got %s" % [label, expected, actual])


func _expect_true(errors: Array[String], label: String, value: bool) -> void:
	if not value:
		errors.append("%s: expected true" % label)
