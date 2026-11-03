extends SceneTree

const Checks := preload("res://scripts/qa/asset_catalog_checks.gd")

func _initialize() -> void:
	var failures := Checks.validate()
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("asset_catalog_tests: OK")
	quit(0 if failures.is_empty() else 1)
