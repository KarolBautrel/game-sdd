extends SceneTree

const CombatTargetingPreview := preload("res://scripts/presentation/combat/combat_targeting_preview.gd")


func _init() -> void:
	var errors: Array[String] = []
	errors.append_array(_expect_text(
		"melee",
		{"rejection": "", "guaranteed_hit": true, "damage": 3, "ap_cost": 1},
		"100% HIT\nDMG 3\nCOST 1 AP"
	))
	errors.append_array(_expect_text(
		"ranged",
		{"rejection": "", "hit_chance": 75, "hit_outcome": "hit", "damage": 2, "ap_cost": 1},
		"75% HIT\nDMG 2\nCOST 1 AP"
	))
	errors.append_array(_expect_text(
		"miss",
		{"rejection": "", "hit_chance": 35, "hit_outcome": "miss", "roll": 88, "ap_cost": 1},
		"35% HIT\nROLL 88 MISS\nCOST 1 AP"
	))
	errors.append_array(_expect_text(
		"rejected",
		{"rejection": "target_out_of_range", "damage": 0, "ap_cost": 1},
		""
	))

	if errors.is_empty():
		print("Godot combat targeting preview validation passed.")
		quit(0)
		return

	push_error("Godot combat targeting preview validation failed.")
	for error: String in errors:
		push_error(error)
	quit(1)


func _expect_text(test_name: String, preview: Dictionary, expected: String) -> Array[String]:
	var actual := CombatTargetingPreview.unit_preview_text(preview)
	if actual == expected:
		return []
	return ["%s: expected '%s', got '%s'" % [test_name, expected, actual]]
