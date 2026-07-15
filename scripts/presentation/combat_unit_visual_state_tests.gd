extends SceneTree

const CombatUnitVisualState := preload("res://scripts/presentation/combat/combat_unit_visual_state.gd")


func _init() -> void:
	var errors: Array[String] = []
	errors.append_array(_test_movement_action())
	errors.append_array(_test_damage_hit_actions())
	errors.append_array(_test_damage_death_actions())
	errors.append_array(_test_status_damage_target_only())
	errors.append_array(_test_miss_actor_action())
	errors.append_array(_test_status_reaction_action())

	if errors.is_empty():
		print("Godot combat unit visual state validation passed.")
		quit(0)
		return

	push_error("Godot combat unit visual state validation failed.")
	for error: String in errors:
		push_error(error)
	quit(1)


func _test_movement_action() -> Array[String]:
	var actions := CombatUnitVisualState.movement_actions_from_events([
		{"type": "unit_moved", "actor_id": "unit_player_001"},
	])
	return _expect_action("movement", actions, "unit_player_001", "walk")


func _test_damage_hit_actions() -> Array[String]:
	var actions := CombatUnitVisualState.combat_actions_from_events([
		{"type": "damage_applied", "actor_id": "unit_player_001", "target_unit_id": "unit_enemy_001", "hp_after": 4},
	])
	var errors: Array[String] = []
	errors.append_array(_expect_action("damage actor", actions, "unit_player_001", "combat"))
	errors.append_array(_expect_action("damage target", actions, "unit_enemy_001", "hit"))
	return errors


func _test_damage_death_actions() -> Array[String]:
	var events := [
		{"type": "damage_applied", "actor_id": "unit_player_001", "target_unit_id": "unit_enemy_001", "hp_after": 0},
	]
	var actions := CombatUnitVisualState.combat_actions_from_events(events)
	var errors: Array[String] = []
	errors.append_array(_expect_action("death target", actions, "unit_enemy_001", "death"))
	var defeated := CombatUnitVisualState.defeated_target_ids(events)
	if defeated != ["unit_enemy_001"]:
		errors.append("death target ids: expected [unit_enemy_001], got %s" % [defeated])
	return errors


func _test_status_damage_target_only() -> Array[String]:
	var actions := CombatUnitVisualState.combat_actions_from_events([
		{"type": "damage_applied", "actor_id": "unit_enemy_001", "target_unit_id": "unit_enemy_001", "hp_after": 3, "source_status_id": "bleeding"},
	])
	var errors: Array[String] = []
	errors.append_array(_expect_action("status damage target", actions, "unit_enemy_001", "hit"))
	if actions.get("unit_enemy_001", "") == "combat":
		errors.append("status damage actor: expected no self combat action")
	return errors


func _test_miss_actor_action() -> Array[String]:
	var actions := CombatUnitVisualState.combat_actions_from_events([
		{"type": "hit_roll_resolved", "actor_id": "unit_enemy_002", "target_unit_id": "unit_player_001", "outcome": "miss"},
	])
	return _expect_action("miss actor", actions, "unit_enemy_002", "combat")


func _test_status_reaction_action() -> Array[String]:
	var actions := CombatUnitVisualState.combat_actions_from_events([
		{"type": "status_applied", "actor_id": "unit_player_001", "target_unit_id": "unit_enemy_001", "status": {"id": "bleeding"}},
	])
	return _expect_action("status target", actions, "unit_enemy_001", "status_reaction")


func _expect_action(test_name: String, actions: Dictionary, unit_id: String, expected: String) -> Array[String]:
	var actual := str(actions.get(unit_id, ""))
	if actual == expected:
		return []
	return ["%s: expected %s -> %s, got %s" % [test_name, unit_id, expected, actual]]
