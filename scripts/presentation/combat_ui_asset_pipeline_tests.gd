extends SceneTree

const AssetCatalog := preload("res://scripts/presentation/shared/asset_catalog.gd")

const CombatDebugScript := preload("res://scripts/presentation/combat_debug.gd")


func _init() -> void:
	var failures: Array[String] = []
	_assert_file("res://assets/ui/combat/processed/manifest.json", failures)
	_assert_file("res://assets/ui/combat/processed/frames/panel_small.png", failures)
	_assert_file("res://assets/ui/combat/processed/slots/slot_normal.png", failures)
	_assert_file("res://assets/ui/combat/processed/slots/slot_selected.png", failures)
	_assert_file("res://assets/ui/combat/processed/slots/slot_disabled.png", failures)
	_assert_file("res://assets/ui/combat/processed/bars/bar_hp.png", failures)
	_assert_file("res://assets/ui/combat/processed/bars/bar_ap.png", failures)
	_assert_file("res://assets/ui/combat/processed/bars/bar_mp.png", failures)
	_assert_file("res://assets/ui/combat/processed/bars/mini_bar_hp.png", failures)
	_assert_file("res://assets/ui/combat/processed/bars/mini_bar_ap.png", failures)
	_assert_file("res://assets/ui/combat/processed/bars/mini_bar_mp.png", failures)
	_assert_png_size("res://assets/ui/combat/processed/bars/mini_bar_hp.png", Vector2i(384, 56), failures)
	_assert_png_size("res://assets/ui/combat/processed/bars/mini_bar_ap.png", Vector2i(384, 56), failures)
	_assert_png_size("res://assets/ui/combat/processed/bars/mini_bar_mp.png", Vector2i(384, 56), failures)
	_assert_file("res://assets/ui/combat/processed/icons/inner/icon_boot.png", failures)
	_assert_file("res://assets/ui/combat/processed/icons/inner/icon_sword.png", failures)
	_assert_file("res://assets/ui/combat/processed/icons/inner/icon_bow.png", failures)
	_assert_file("res://assets/ui/combat/processed/icons/inner/icon_shield.png", failures)
	_assert_file("res://assets/ui/combat/processed/icons/inner/icon_hourglass.png", failures)
	_assert_file("res://assets/ui/combat/processed/icons/icon_aimed_shot.png", failures)
	_assert_png_has_visible_pixels("res://assets/ui/combat/processed/icons/icon_aimed_shot.png", failures)
	_assert_file("res://assets/ui/combat/processed/icons/icon_cur_deep.png", failures)
	_assert_file("res://assets/ui/combat/processed/icons/icon_guard_break.png", failures)
	_assert_file("res://assets/ui/combat/processed/icons/icon_power_attack.png", failures)
	_assert_png_has_visible_pixels("res://assets/ui/combat/processed/icons/icon_power_attack.png", failures)
	_assert_file("res://assets/ui/combat/processed/icons/icon_shield_wall.png", failures)
	_assert_equal(CombatDebugScript.ACTION_ICON_PATHS.get("guard_break", ""), "res://assets/ui/combat/processed/icons/icon_guard_break.png", "guard break icon path", failures)
	_assert_equal(CombatDebugScript.ACTION_ICON_PATHS.get("aimed_shot", ""), "res://assets/ui/combat/processed/icons/icon_aimed_shot.png", "aimed shot icon path", failures)
	_assert_equal(CombatDebugScript.ACTION_ICON_PATHS.get("power_strike", ""), "res://assets/ui/combat/processed/icons/icon_power_attack.png", "power strike icon path", failures)
	_assert_equal(CombatDebugScript.ACTION_ICON_PATHS.get("move", ""), "res://assets/ui/combat/processed/icons/icon_boot.png", "move icon path", failures)
	_assert_equal(CombatDebugScript.ACTION_ICON_PATHS.get("basic_attack", ""), "res://assets/ui/combat/processed/icons/icon_sword.png", "basic attack icon path", failures)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("combat_ui_asset_pipeline_tests: OK")
	quit(0)


func _assert_file(path: String, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing expected combat UI asset: %s" % path)


func _assert_png_size(path: String, expected: Vector2i, failures: Array[String]) -> void:
	var image := AssetCatalog.image_copy(path)
	if image == null:
		failures.append("Could not load combat UI asset for size check: %s" % path)
		return
	var actual := Vector2i(image.get_width(), image.get_height())
	if actual != expected:
		failures.append("Expected %s to be %sx%s, got %sx%s" % [path, expected.x, expected.y, actual.x, actual.y])


func _assert_png_has_visible_pixels(path: String, failures: Array[String]) -> void:
	var image := AssetCatalog.image_copy(path)
	if image == null:
		failures.append("Could not load combat UI asset for pixel check: %s" % path)
		return
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				return
	failures.append("Expected combat UI asset to contain visible pixels: %s" % path)


func _assert_equal(actual: Variant, expected: Variant, label: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("Expected %s to be `%s`, got `%s`" % [label, expected, actual])
