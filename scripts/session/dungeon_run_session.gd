extends Node

const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")

const DUNGEON_SCENE_PATH := "res://scenes/dungeon/DungeonDebug.tscn"
const COMBAT_SCENE_PATH := "res://scenes/combat/CombatDebug.tscn"
const MIN_RANDOM_ENEMIES := 2
const MAX_RANDOM_ENEMIES := 3
const ENEMY_ARCHETYPE_POOL := ["raider_swordsman", "raider_archer"]

var dungeon_data: Dictionary = {}
var dungeon_state: Dictionary = {}
var pending_combat_request: Dictionary = {}
var last_feedback := ""
var next_combat_seed := 0


func has_dungeon_run() -> bool:
	return not dungeon_data.is_empty() and not dungeon_state.is_empty()


func set_dungeon_run(next_dungeon_data: Dictionary, next_dungeon_state: Dictionary) -> void:
	dungeon_data = next_dungeon_data.duplicate(true)
	dungeon_state = next_dungeon_state.duplicate(true)


func start_combat(next_dungeon_data: Dictionary, next_dungeon_state: Dictionary) -> bool:
	var pending: Dictionary = next_dungeon_state.get("pending_combat_request", {})
	if pending.is_empty():
		last_feedback = "No pending combat to start."
		return false
	set_dungeon_run(next_dungeon_data, next_dungeon_state)
	pending_combat_request = pending.duplicate(true)
	next_combat_seed = Time.get_ticks_msec()
	last_feedback = "Combat started from %s." % pending.get("room_id", "")
	return true


func has_pending_combat_launch() -> bool:
	return not pending_combat_request.is_empty()


func combat_encounter_path() -> String:
	return str(pending_combat_request.get("combat_encounter_path", ""))


func apply_launch_metadata(encounter: Dictionary) -> Dictionary:
	var next_encounter := encounter.duplicate(true)
	if pending_combat_request.is_empty():
		return next_encounter
	next_encounter["source_dungeon_id"] = str(pending_combat_request.get("dungeon_id", ""))
	next_encounter["source_room_id"] = str(pending_combat_request.get("room_id", ""))
	return randomize_dungeon_enemies(next_encounter, next_combat_seed)


func randomize_dungeon_enemies(encounter: Dictionary, seed: int = 0) -> Dictionary:
	var next_encounter := encounter.duplicate(true)
	if not next_encounter.has("grid") or not next_encounter.has("units") or not next_encounter.has("turn_state"):
		return next_encounter
	var rng := RandomNumberGenerator.new()
	if seed == 0:
		rng.randomize()
	else:
		rng.seed = seed

	var enemy_count := rng.randi_range(MIN_RANDOM_ENEMIES, MAX_RANDOM_ENEMIES)
	var spawn_positions := _enemy_spawn_positions(next_encounter)
	var player_units: Array = []
	for unit: Dictionary in next_encounter.get("units", []):
		if unit.get("team", "") == "player":
			player_units.append(unit)

	var enemy_units: Array = []
	for index in range(enemy_count):
		if spawn_positions.is_empty():
			break
		var archetype_id: String = ENEMY_ARCHETYPE_POOL[rng.randi_range(0, ENEMY_ARCHETYPE_POOL.size() - 1)]
		var position_index: int = rng.randi_range(0, spawn_positions.size() - 1)
		var position: Dictionary = spawn_positions.pop_at(position_index)
		enemy_units.append(_enemy_unit_for_archetype(archetype_id, index + 1, position))

	next_encounter["units"] = player_units + enemy_units
	next_encounter["turn_state"]["active_unit_id"] = player_units[0]["id"] if not player_units.is_empty() else ""
	next_encounter["turn_state"]["round"] = 1
	next_encounter["turn_state"]["turn_order"] = []
	for unit: Dictionary in next_encounter["units"]:
		next_encounter["turn_state"]["turn_order"].append(unit["id"])
	next_encounter["event_log"] = []
	return next_encounter


func finish_combat(result_payload: Dictionary) -> bool:
	if pending_combat_request.is_empty():
		last_feedback = "No pending combat launch to finish."
		return false
	if dungeon_data.is_empty() or dungeon_state.is_empty():
		last_feedback = "Dungeon run state missing."
		return false
	var result: Dictionary = DungeonStateModel.apply_combat_result(dungeon_data, dungeon_state, result_payload)
	if result.get("status", "") != "accepted":
		last_feedback = "Combat result rejected: %s." % result.get("rejection", "unknown")
		return false
	dungeon_state = result["state"]
	last_feedback = "Combat %s applied to %s." % [
		result_payload.get("result", "unknown"),
		result_payload.get("source_room_id", ""),
	]
	pending_combat_request = {}
	return true


func clear() -> void:
	dungeon_data.clear()
	dungeon_state.clear()
	pending_combat_request.clear()
	last_feedback = ""
	next_combat_seed = 0


func _enemy_spawn_positions(encounter: Dictionary) -> Array[Dictionary]:
	var grid: Dictionary = encounter.get("grid", {})
	var width := int(grid.get("width", 0))
	var occupied := {}
	for unit: Dictionary in encounter.get("units", []):
		occupied[_position_key(unit.get("position", {}))] = true

	var positions: Array[Dictionary] = []
	for tile: Dictionary in grid.get("tiles", []):
		var position := {"x": int(tile.get("x", 0)), "y": int(tile.get("y", 0))}
		if tile.get("type", "") == "blocked":
			continue
		if int(position["x"]) < int(width * 0.55):
			continue
		if occupied.has(_position_key(position)):
			continue
		positions.append(position)
	return positions


func _enemy_unit_for_archetype(archetype_id: String, index: int, position: Dictionary) -> Dictionary:
	var stats := _enemy_stats_for_archetype(archetype_id)
	return {
		"id": "unit_enemy_%03d" % index,
		"team": "enemy",
		"position": position.duplicate(true),
		"stats": stats,
		"resources": {
			"hp": stats["max_hp"],
			"ap": stats["max_ap"],
			"mp": stats["move_points"],
		},
		"statuses": [],
		"available_actions": [],
		"archetype_id": archetype_id,
	}


func _enemy_stats_for_archetype(archetype_id: String) -> Dictionary:
	match archetype_id:
		"raider_archer":
			return {
				"max_hp": 7,
				"strength": 3,
				"defense": 0,
				"initiative": 7,
				"move_points": 3,
				"max_ap": 1,
				"accuracy": 10,
				"evasion": 0,
			}
		_:
			return {
				"max_hp": 9,
				"strength": 4,
				"defense": 1,
				"initiative": 8,
				"move_points": 4,
				"max_ap": 1,
				"accuracy": 0,
				"evasion": 0,
			}


func _position_key(position: Dictionary) -> String:
	return "%s,%s" % [position.get("x", 0), position.get("y", 0)]
