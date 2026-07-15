extends SceneTree

const CombatFloatingText := preload("res://scripts/presentation/combat/combat_floating_text.gd")


func _init() -> void:
	var errors: Array[String] = []
	errors.append_array(_test_damage_message())
	errors.append_array(_test_miss_message())
	errors.append_array(_test_status_message())
	errors.append_array(_test_status_message_with_word_separator())
	errors.append_array(_test_damage_suppresses_miss_for_same_target())

	if errors.is_empty():
		print("Godot combat floating text validation passed.")
		quit(0)
		return

	push_error("Godot combat floating text validation failed.")
	for error: String in errors:
		push_error(error)
	quit(1)


func _test_damage_message() -> Array[String]:
	var messages := CombatFloatingText.messages_from_events([
		{
			"type": "damage_applied",
			"target_unit_id": "unit_enemy_001",
			"damage": 3,
		},
	])
	return _expect_message("damage", messages, 0, "unit_enemy_001", "-3 DMG", CombatFloatingText.DAMAGE_COLOR)


func _test_miss_message() -> Array[String]:
	var messages := CombatFloatingText.messages_from_events([
		{
			"type": "hit_roll_resolved",
			"target_unit_id": "unit_enemy_001",
			"outcome": "miss",
		},
	])
	return _expect_message("miss", messages, 0, "unit_enemy_001", "MISS", CombatFloatingText.MISS_COLOR)


func _test_status_message() -> Array[String]:
	var messages := CombatFloatingText.messages_from_events([
		{
			"type": "status_applied",
			"target_unit_id": "unit_enemy_001",
			"status": {"id": "bleeding"},
		},
	])
	return _expect_message("status", messages, 0, "unit_enemy_001", "BLEEDING", CombatFloatingText.STATUS_COLOR)


func _test_status_message_with_word_separator() -> Array[String]:
	var messages := CombatFloatingText.messages_from_events([
		{
			"type": "status_applied",
			"target_unit_id": "unit_enemy_001",
			"status": {"id": "guard_broken"},
		},
	])
	return _expect_message("status words", messages, 0, "unit_enemy_001", "GUARD BROKEN", CombatFloatingText.STATUS_COLOR)


func _test_damage_suppresses_miss_for_same_target() -> Array[String]:
	var messages := CombatFloatingText.messages_from_events([
		{
			"type": "hit_roll_resolved",
			"target_unit_id": "unit_enemy_001",
			"outcome": "miss",
		},
		{
			"type": "damage_applied",
			"target_unit_id": "unit_enemy_001",
			"damage": 4,
		},
	])
	var errors: Array[String] = []
	if messages.size() != 1:
		errors.append("combined: expected one message, got %s" % messages.size())
		return errors
	errors.append_array(_expect_message("combined", messages, 0, "unit_enemy_001", "-4 DMG", CombatFloatingText.DAMAGE_COLOR))
	return errors


func _expect_message(test_name: String, messages: Array[Dictionary], index: int, unit_id: String, text: String, color: Color) -> Array[String]:
	var errors: Array[String] = []
	if messages.size() <= index:
		errors.append("%s: expected message at index %s, got %s messages" % [test_name, index, messages.size()])
		return errors

	var message: Dictionary = messages[index]
	if str(message.get("unit_id", "")) != unit_id:
		errors.append("%s: expected unit_id %s, got %s" % [test_name, unit_id, message.get("unit_id", "")])
	if str(message.get("text", "")) != text:
		errors.append("%s: expected text %s, got %s" % [test_name, text, message.get("text", "")])
	if message.get("color", Color()) != color:
		errors.append("%s: expected color %s, got %s" % [test_name, color, message.get("color", Color())])
	if int(message.get("order", -1)) != index:
		errors.append("%s: expected order %s, got %s" % [test_name, index, message.get("order", -1)])
	return errors
