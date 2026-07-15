extends SceneTree

const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")
const DungeonRunSessionScript := preload("res://scripts/session/dungeon_run_session.gd")


func _init() -> void:
	var errors: Array[String] = []
	var session := DungeonRunSessionScript.new()
	var dungeon := _load_json("res://resources/data/dungeons/dungeon_old_mine.json")
	var state: Dictionary = DungeonStateModel.initial_state(dungeon)
	state = DungeonStateModel.enter_room(dungeon, state, "dusty_crossing")["state"]
	state = DungeonStateModel.enter_room(dungeon, state, "spider_nest")["state"]

	_expect_true(errors, "start combat accepted", session.start_combat(dungeon, state))
	_expect_true(errors, "pending combat launch", session.has_pending_combat_launch())
	_expect_equal(errors, "encounter path", session.combat_encounter_path(), "res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json")

	var encounter := {"id": "debug_encounter"}
	var stamped: Dictionary = session.apply_launch_metadata(encounter)
	_expect_equal(errors, "stamped dungeon id", stamped["source_dungeon_id"], "dungeon_old_mine")
	_expect_equal(errors, "stamped room id", stamped["source_room_id"], "spider_nest")

	var showcase := _load_json("res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json")
	var randomized: Dictionary = session.randomize_dungeon_enemies(showcase, 1234)
	var enemy_units := _units_for_team(randomized, "enemy")
	_expect_true(errors, "random enemy count 2-3", enemy_units.size() >= 2 and enemy_units.size() <= 3)
	_expect_equal(errors, "turn order count follows randomized units", randomized["turn_state"]["turn_order"].size(), randomized["units"].size())
	for enemy: Dictionary in enemy_units:
		_expect_true(errors, "random enemy has supported archetype", enemy.get("archetype_id", "") in ["raider_swordsman", "raider_archer"])
		_expect_true(errors, "random enemy on right side", int(enemy["position"]["x"]) >= int(randomized["grid"]["width"] * 0.55))
		_expect_false(errors, "random enemy not on blocked tile", _tile_type_at(randomized, enemy["position"]) == "blocked")

	_expect_true(errors, "finish combat accepted", session.finish_combat(_combat_payload("victory", "dungeon_old_mine", "spider_nest")))
	_expect_false(errors, "pending cleared", session.has_pending_combat_launch())
	_expect_true(errors, "room cleared", DungeonStateModel.room_is_cleared(session.dungeon_state, "spider_nest"))
	session.free()
	if errors.is_empty():
		print("Dungeon run session validation passed.")
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


func _units_for_team(encounter: Dictionary, team: String) -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	for unit: Dictionary in encounter.get("units", []):
		if unit.get("team", "") == team:
			units.append(unit)
	return units


func _tile_type_at(encounter: Dictionary, position: Dictionary) -> String:
	for tile: Dictionary in encounter.get("grid", {}).get("tiles", []):
		if int(tile.get("x", -1)) == int(position.get("x", -2)) and int(tile.get("y", -1)) == int(position.get("y", -2)):
			return str(tile.get("type", "missing"))
	return "missing"


func _expect_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		errors.append("%s: expected %s, got %s" % [label, expected, actual])


func _expect_true(errors: Array[String], label: String, value: bool) -> void:
	if not value:
		errors.append("%s: expected true" % label)


func _expect_false(errors: Array[String], label: String, value: bool) -> void:
	if value:
		errors.append("%s: expected false" % label)
