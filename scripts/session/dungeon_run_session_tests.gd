extends SceneTree

const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")
const DungeonRunSessionScript := preload("res://scripts/session/dungeon_run_session.gd")


func _init() -> void:
	var errors: Array[String] = []
	var session := DungeonRunSessionScript.new()
	var dungeon := _load_json("res://resources/data/dungeons/dungeon_old_mine.json")
	var state: Dictionary = DungeonStateModel.initial_state(dungeon)
	state = DungeonStateModel.enter_room(dungeon, state, "dusty_crossing")["state"]
	state = DungeonStateModel.resolve_room_event_choice(dungeon, state, "ignore")["state"]
	var trap_prompt: Dictionary = DungeonStateModel.enter_room(dungeon, state, "spider_nest")
	_expect_equal(errors, "trap prompt before combat room", trap_prompt["status"], "choice_required")
	state = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, trap_prompt["state"], "use_supply")["state"]

	_expect_true(errors, "start combat accepted", session.start_combat(dungeon, state))
	_expect_true(errors, "pending combat launch", session.has_pending_combat_launch())
	_expect_equal(errors, "encounter path", session.combat_encounter_path(), "res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json")

	var encounter := {"id": "debug_encounter"}
	var stamped: Dictionary = session.apply_launch_metadata(encounter)
	_expect_equal(errors, "stamped dungeon id", stamped["source_dungeon_id"], "dungeon_old_mine")
	_expect_equal(errors, "stamped room id", stamped["source_room_id"], "spider_nest")
	_expect_equal(errors, "stamped dungeon light state", stamped["dungeon_modifiers"]["light_state"], "dim")
	_expect_equal(errors, "stamped dungeon active debuffs", stamped["dungeon_modifiers"]["active_debuffs"].size(), 0)

	var showcase := _load_json("res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json")
	var randomized: Dictionary = session.apply_launch_metadata(showcase)
	_expect_equal(errors, "randomized keeps dungeon modifiers", randomized["dungeon_modifiers"]["light_state"], "dim")
	var enemy_units := _units_for_team(randomized, "enemy")
	_expect_true(errors, "random enemy count 2-3", enemy_units.size() >= 2 and enemy_units.size() <= 3)
	_expect_equal(errors, "turn order count follows randomized units", randomized["turn_state"]["turn_order"].size(), randomized["units"].size())
	for enemy: Dictionary in enemy_units:
		_expect_true(errors, "random enemy has supported archetype", enemy.get("archetype_id", "") in ["raider_swordsman", "raider_archer"])
		_expect_true(errors, "random enemy on right side", int(enemy["position"]["x"]) >= int(randomized["grid"]["width"] * 0.55))
		_expect_false(errors, "random enemy not on blocked tile", _tile_type_at(randomized, enemy["position"]) == "blocked")

	var modified_session := DungeonRunSessionScript.new()
	modified_session.pending_combat_request = {
		"dungeon_id": "dungeon_old_mine",
		"room_id": "spider_nest",
		"combat_encounter_path": "res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json",
		"dungeon_modifiers": {
			"light_state": "blackout",
			"enemy_modifiers": [{"type": "initiative_bonus", "value": 5, "source": "light:blackout"}],
			"party_formation": [{
				"slot_id": "front",
				"target_id": "party_slot_front",
				"combat_unit_id": "unit_player_001",
				"label": "Front",
			}],
			"target_effects": {
				"party_slot_front": {
					"hp_loss": 3,
					"debuffs": {"limping": 1, "bleeding": 1},
				},
			},
			"active_debuffs": {"limping": {"id": "limping", "stacks": 1}, "bleeding": {"id": "bleeding", "stacks": 1}},
			"party_effects": {"hp_loss": 3, "debuffs": ["limping", "bleeding"]},
		},
	}
	modified_session.next_combat_seed = 1234
	var modified: Dictionary = modified_session.apply_launch_metadata(showcase)
	var modified_player := _unit_by_id(modified, "unit_player_001")
	_expect_equal(errors, "dungeon hp loss applies to player", modified_player["resources"]["hp"], 11)
	_expect_equal(errors, "limping halves player mp", modified_player["resources"]["mp"], 2)
	_expect_true(errors, "bleeding starts on player", _unit_has_status(modified_player, "bleeding"))
	var modified_enemy_units := _units_for_team(modified, "enemy")
	_expect_true(errors, "enemy initiative bonus applied", int(modified_enemy_units[0]["stats"]["initiative"]) >= 12)
	_expect_true(errors, "blackout can put enemy first", str(modified["turn_state"]["active_unit_id"]).begins_with("unit_enemy_"))
	modified_session.free()

	var legacy_session := DungeonRunSessionScript.new()
	legacy_session.pending_combat_request = {
		"dungeon_id": "dungeon_old_mine",
		"room_id": "spider_nest",
		"combat_encounter_path": "res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json",
		"dungeon_modifiers": {
			"target_effects": {
				"party_member_0": {
					"hp_loss": 2,
					"debuffs": {},
				},
			},
		},
	}
	legacy_session.next_combat_seed = 1234
	var legacy_modified: Dictionary = legacy_session.apply_launch_metadata(showcase)
	_expect_equal(errors, "legacy party member target still maps first player", _unit_by_id(legacy_modified, "unit_player_001")["resources"]["hp"], 12)
	legacy_session.free()

	_expect_true(errors, "finish combat accepted", session.finish_combat(_combat_payload("victory", "dungeon_old_mine", "spider_nest")))
	_expect_false(errors, "pending cleared", session.has_pending_combat_launch())
	_expect_true(errors, "room cleared", DungeonStateModel.room_is_cleared(session.dungeon_state, "spider_nest"))
	_expect_equal(errors, "victory return feedback", session.last_feedback, "Victory in Spider Nest. Room secured. Choose an exit to continue.")
	session.free()

	var guarded_session := DungeonRunSessionScript.new()
	var guarded_state: Dictionary = DungeonStateModel.initial_state(dungeon)
	guarded_state = DungeonStateModel.enter_room(dungeon, guarded_state, "dusty_crossing")["state"]
	guarded_state = DungeonStateModel.resolve_room_event_choice(dungeon, guarded_state, "ignore")["state"]
	guarded_state = DungeonStateModel.enter_room(dungeon, guarded_state, "guarded_cache")["state"]
	_expect_true(errors, "guarded combat start accepted", guarded_session.start_combat(dungeon, guarded_state))
	_expect_true(errors, "guarded combat finish accepted", guarded_session.finish_combat(_combat_payload("victory", "dungeon_old_mine", "guarded_cache")))
	_expect_true(errors, "guarded reward unlocked", DungeonStateModel.room_reward_is_unlocked(guarded_session.dungeon_state, "guarded_cache"))
	_expect_equal(errors, "guarded return feedback", guarded_session.last_feedback, "Victory in Guarded Cache. Room secured. Reward unlocked: 7g + 12 XP + rusty_key.")
	guarded_session.free()

	var defeat_session := DungeonRunSessionScript.new()
	var defeat_state: Dictionary = DungeonStateModel.initial_state(dungeon)
	defeat_state = DungeonStateModel.enter_room(dungeon, defeat_state, "dusty_crossing")["state"]
	defeat_state = DungeonStateModel.resolve_room_event_choice(dungeon, defeat_state, "ignore")["state"]
	defeat_state = DungeonStateModel.enter_room(dungeon, defeat_state, "guarded_cache")["state"]
	_expect_true(errors, "defeat combat start accepted", defeat_session.start_combat(dungeon, defeat_state))
	_expect_true(errors, "defeat combat finish accepted", defeat_session.finish_combat(_combat_payload("defeat", "dungeon_old_mine", "guarded_cache")))
	_expect_false(errors, "defeat room not cleared", DungeonStateModel.room_is_cleared(defeat_session.dungeon_state, "guarded_cache"))
	_expect_equal(errors, "defeat return feedback", defeat_session.last_feedback, "Defeat in Guarded Cache. Room remains dangerous; reset or return later.")
	defeat_session.free()
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


func _unit_by_id(encounter: Dictionary, unit_id: String) -> Dictionary:
	for unit: Dictionary in encounter.get("units", []):
		if str(unit.get("id", "")) == unit_id:
			return unit
	return {}


func _unit_has_status(unit: Dictionary, status_id: String) -> bool:
	for status: Dictionary in unit.get("statuses", []):
		if str(status.get("id", "")) == status_id:
			return true
	return false


func _expect_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		errors.append("%s: expected %s, got %s" % [label, expected, actual])


func _expect_true(errors: Array[String], label: String, value: bool) -> void:
	if not value:
		errors.append("%s: expected true" % label)


func _expect_false(errors: Array[String], label: String, value: bool) -> void:
	if value:
		errors.append("%s: expected false" % label)
