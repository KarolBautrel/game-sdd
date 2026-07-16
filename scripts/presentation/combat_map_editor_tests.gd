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
			instance.queue_free()

	if errors.is_empty():
		print("Godot combat map editor validation passed.")
		quit(0)
		return

	push_error("Godot combat map editor validation failed.")
	for error: String in errors:
		push_error(error)
	quit(1)
