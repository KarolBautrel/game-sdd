extends SceneTree

const CombatDebugScript := preload("res://scripts/presentation/combat_debug.gd")


func _init() -> void:
	var errors: Array[String] = []
	var combat := CombatDebugScript.new()
	combat.state = _load_json("res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json")
	combat.state["event_log"] = []

	_expect_equal(errors, "initial result", combat._combat_result(), "in_progress")
	combat._force_debug_victory(false)
	_expect_equal(errors, "debug victory result", combat._combat_result(), "victory")

	var payload: Dictionary = combat._combat_result_payload()
	_expect_equal(errors, "payload result", payload.get("result", ""), "victory")
	_expect_true(errors, "defeated enemies present", payload.get("defeated_enemy_ids", []).size() > 0)
	_expect_true(errors, "combat ended event present", _has_event(combat.state.get("event_log", []), "combat_ended"))

	combat.free()
	if errors.is_empty():
		print("Combat debug force victory validation passed.")
	else:
		for error: String in errors:
			push_error(error)
		quit(1)
		return
	quit(0)


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


func _has_event(events: Array, event_type: String) -> bool:
	for event: Dictionary in events:
		if event.get("type", "") == event_type:
			return true
	return false


func _expect_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		errors.append("%s: expected %s, got %s" % [label, expected, actual])


func _expect_true(errors: Array[String], label: String, value: bool) -> void:
	if not value:
		errors.append("%s: expected true" % label)
