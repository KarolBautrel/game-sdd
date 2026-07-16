extends SceneTree


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
	var image := Image.new()
	if image.load(path) != OK:
		failures.append("Could not load combat UI asset for size check: %s" % path)
		return
	var actual := Vector2i(image.get_width(), image.get_height())
	if actual != expected:
		failures.append("Expected %s to be %sx%s, got %sx%s" % [path, expected.x, expected.y, actual.x, actual.y])
