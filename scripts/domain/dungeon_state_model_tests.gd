extends SceneTree

const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")


func _init() -> void:
	var errors: Array[String] = []
	var dungeon := _load_json("res://resources/data/dungeons/dungeon_old_mine.json")
	var state := DungeonStateModel.initial_state(dungeon)

	_expect_equal(errors, "initial current room", state["current_room_id"], "entrance")
	_expect_true(errors, "initial start visited", DungeonStateModel.room_is_visited(state, "entrance"))
	_expect_true(errors, "initial empty start cleared", DungeonStateModel.room_is_cleared(state, "entrance"))
	_expect_true(errors, "initial has no pending combat", state["pending_combat_request"].is_empty())

	var missing_result: Dictionary = DungeonStateModel.enter_room(dungeon, state, "missing_room")
	_expect_equal(errors, "missing room rejected", missing_result["status"], "rejected")
	_expect_equal(errors, "missing room reason", missing_result["rejection"], "missing_room")
	_expect_equal(errors, "missing room keeps current", missing_result["state"]["current_room_id"], "entrance")

	var non_adjacent_result: Dictionary = DungeonStateModel.enter_room(dungeon, state, "collapsed_cache")
	_expect_equal(errors, "non adjacent rejected", non_adjacent_result["status"], "rejected")
	_expect_equal(errors, "non adjacent reason", non_adjacent_result["rejection"], "room_not_adjacent")
	_expect_equal(errors, "non adjacent keeps current", non_adjacent_result["state"]["current_room_id"], "entrance")

	var crossing_result: Dictionary = DungeonStateModel.enter_room(dungeon, state, "dusty_crossing")
	_expect_equal(errors, "adjacent room accepted", crossing_result["status"], "accepted")
	state = crossing_result["state"]
	_expect_equal(errors, "crossing current room", state["current_room_id"], "dusty_crossing")
	_expect_true(errors, "crossing visited", DungeonStateModel.room_is_visited(state, "dusty_crossing"))
	_expect_true(errors, "crossing empty cleared", DungeonStateModel.room_is_cleared(state, "dusty_crossing"))
	_expect_true(errors, "crossing has no pending combat", state["pending_combat_request"].is_empty())

	var treasure_result: Dictionary = DungeonStateModel.enter_room(dungeon, state, "collapsed_cache")
	_expect_equal(errors, "treasure room accepted", treasure_result["status"], "accepted")
	var treasure_state: Dictionary = treasure_result["state"]
	_expect_equal(errors, "treasure current room", treasure_state["current_room_id"], "collapsed_cache")
	_expect_true(errors, "treasure visited", DungeonStateModel.room_is_visited(treasure_state, "collapsed_cache"))
	_expect_false(errors, "treasure not auto cleared", DungeonStateModel.room_is_cleared(treasure_state, "collapsed_cache"))
	_expect_true(errors, "treasure has no pending combat", treasure_state["pending_combat_request"].is_empty())
	var treasure_content: Array = DungeonStateModel.current_room_content(dungeon, treasure_state)
	_expect_equal(errors, "treasure content type", treasure_content[0]["type"], "treasure")

	var combat_result: Dictionary = DungeonStateModel.enter_room(dungeon, state, "spider_nest")
	_expect_equal(errors, "combat room accepted", combat_result["status"], "accepted")
	var combat_state: Dictionary = combat_result["state"]
	_expect_equal(errors, "combat current room", combat_state["current_room_id"], "spider_nest")
	_expect_true(errors, "combat visited", DungeonStateModel.room_is_visited(combat_state, "spider_nest"))
	_expect_false(errors, "combat not cleared", DungeonStateModel.room_is_cleared(combat_state, "spider_nest"))
	_expect_equal(errors, "pending combat dungeon id", combat_state["pending_combat_request"]["dungeon_id"], "dungeon_old_mine")
	_expect_equal(errors, "pending combat room id", combat_state["pending_combat_request"]["room_id"], "spider_nest")
	_expect_equal(errors, "pending combat content type", combat_state["pending_combat_request"]["content_type"], "combat")
	_expect_equal(errors, "pending combat path", combat_state["pending_combat_request"]["combat_encounter_path"], "res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json")

	var in_progress_result: Dictionary = DungeonStateModel.apply_combat_result(dungeon, combat_state, _combat_payload("in_progress", "dungeon_old_mine", "spider_nest"))
	_expect_equal(errors, "in progress result rejected", in_progress_result["status"], "rejected")
	_expect_equal(errors, "in progress reason", in_progress_result["rejection"], "combat_still_in_progress")

	var wrong_room_result: Dictionary = DungeonStateModel.apply_combat_result(dungeon, combat_state, _combat_payload("victory", "dungeon_old_mine", "guarded_cache"))
	_expect_equal(errors, "wrong room result rejected", wrong_room_result["status"], "rejected")
	_expect_equal(errors, "wrong room reason", wrong_room_result["rejection"], "wrong_room")

	var victory_result: Dictionary = DungeonStateModel.apply_combat_result(dungeon, combat_state, _combat_payload("victory", "dungeon_old_mine", "spider_nest"))
	_expect_equal(errors, "combat victory accepted", victory_result["status"], "accepted")
	var victory_state: Dictionary = victory_result["state"]
	_expect_true(errors, "combat room cleared after victory", DungeonStateModel.room_is_cleared(victory_state, "spider_nest"))
	_expect_true(errors, "pending combat cleared after victory", victory_state["pending_combat_request"].is_empty())
	_expect_equal(errors, "last combat result stored", victory_state["last_combat_result"]["result"], "victory")

	var defeat_result: Dictionary = DungeonStateModel.apply_combat_result(dungeon, combat_state, _combat_payload("defeat", "dungeon_old_mine", "spider_nest"))
	_expect_equal(errors, "combat defeat accepted", defeat_result["status"], "accepted")
	var defeat_state: Dictionary = defeat_result["state"]
	_expect_false(errors, "combat room not cleared after defeat", DungeonStateModel.room_is_cleared(defeat_state, "spider_nest"))
	_expect_true(errors, "pending combat cleared after defeat", defeat_state["pending_combat_request"].is_empty())

	var guarded_result: Dictionary = DungeonStateModel.enter_room(dungeon, state, "guarded_cache")
	_expect_equal(errors, "guarded room accepted", guarded_result["status"], "accepted")
	var guarded_state: Dictionary = guarded_result["state"]
	_expect_equal(errors, "guarded pending content type", guarded_state["pending_combat_request"]["content_type"], "guarded_treasure")
	var guarded_victory_result: Dictionary = DungeonStateModel.apply_combat_result(dungeon, guarded_state, _combat_payload("victory", "dungeon_old_mine", "guarded_cache"))
	_expect_equal(errors, "guarded victory accepted", guarded_victory_result["status"], "accepted")
	var guarded_victory_state: Dictionary = guarded_victory_result["state"]
	_expect_true(errors, "guarded room cleared after victory", DungeonStateModel.room_is_cleared(guarded_victory_state, "guarded_cache"))
	_expect_true(errors, "guarded reward unlocked after victory", DungeonStateModel.room_reward_is_unlocked(guarded_victory_state, "guarded_cache"))

	var no_pending_result: Dictionary = DungeonStateModel.apply_combat_result(dungeon, state, _combat_payload("victory", "dungeon_old_mine", "spider_nest"))
	_expect_equal(errors, "no pending result rejected", no_pending_result["status"], "rejected")
	_expect_equal(errors, "no pending reason", no_pending_result["rejection"], "no_pending_combat")

	if errors.is_empty():
		print("Dungeon state model validation passed.")
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


func _combat_payload(result: String, dungeon_id: String, room_id: String) -> Dictionary:
	return {
		"result": result,
		"combat_id": "debug_combat",
		"source_dungeon_id": dungeon_id,
		"source_room_id": room_id,
		"surviving_players": [],
		"defeated_player_ids": [],
		"defeated_enemy_ids": [],
		"remaining_enemies": [],
		"rewards": {"xp": 0, "gold": 0, "items": []},
	}


func _expect_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		errors.append("%s: expected %s, got %s" % [label, expected, actual])


func _expect_true(errors: Array[String], label: String, value: bool) -> void:
	if not value:
		errors.append("%s: expected true" % label)


func _expect_false(errors: Array[String], label: String, value: bool) -> void:
	if value:
		errors.append("%s: expected false" % label)
