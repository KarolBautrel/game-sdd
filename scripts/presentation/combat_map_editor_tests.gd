extends SceneTree


func _init() -> void:
	var errors: Array[String] = []
	var scene := load("res://scenes/combat/CombatMapEditor.tscn") as PackedScene
	if scene == null:
		errors.append("CombatMapEditor scene should load")
	else:
		var instance := scene.instantiate()
		if instance == null:
			errors.append("CombatMapEditor scene should instantiate")
		else:
			root.add_child(instance)
			await process_frame
			var script: Script = instance.get_script()
			if script == null:
				errors.append("CombatMapEditor should have script")
			if not instance.has_method("_save_encounter"):
				errors.append("CombatMapEditor should expose save helper")
			if not instance.has_method("_load_encounter"):
				errors.append("CombatMapEditor should expose load helper")
			_expect_true(errors, "floor assets loaded separately", instance.floor_asset_paths.size() >= 32)
			_expect_true(errors, "decoration assets exclude floor assets", not _any_floor_asset(instance.decoration_paths))
			instance.encounter = {"background_path": "", "grid": {"width": 1, "height": 1, "tiles": [{"x": 0, "y": 0, "type": "floor"}]}}
			instance.selected_floor_asset_path = "res://assets/combat/terrain/processed/dungeon/floor_dungeon/floor_dungeon_00.png"
			instance._apply_selected_floor_background()
			_expect_equal(errors, "floor applies background", instance.encounter.get("background_path", ""), "res://assets/combat/terrain/backgrounds/old_mine_dungeon_00_stone.png")
			_expect_true(errors, "floor apply does not create decorations", not instance.encounter.has("terrain_decorations"))
			instance.queue_free()

	if errors.is_empty():
		print("Godot combat map editor validation passed.")
		quit(0)
		return

	push_error("Godot combat map editor validation failed.")
	for error: String in errors:
		push_error(error)
	quit(1)


func _any_floor_asset(paths: Array) -> bool:
	for path in paths:
		if str(path).contains("/floor_"):
			return true
	return false


func _expect_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		errors.append("%s: expected %s, got %s" % [label, expected, actual])


func _expect_true(errors: Array[String], label: String, value: bool) -> void:
	if not value:
		errors.append("%s: expected true" % label)
