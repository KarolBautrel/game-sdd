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
	next_encounter["dungeon_modifiers"] = pending_combat_request.get("dungeon_modifiers", {}).duplicate(true)
	next_encounter = randomize_dungeon_enemies(next_encounter, next_combat_seed)
	_apply_dungeon_modifier_effects(next_encounter)
	return next_encounter


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


func _apply_dungeon_modifier_effects(encounter: Dictionary) -> void:
	var modifiers: Dictionary = encounter.get("dungeon_modifiers", {})
	if modifiers.is_empty():
		return
	_apply_enemy_modifiers(encounter, modifiers.get("enemy_modifiers", []))
	_apply_target_effects(encounter, modifiers)
	_rebuild_turn_order_by_initiative(encounter)


func _apply_enemy_modifiers(encounter: Dictionary, enemy_modifiers: Array) -> void:
	for modifier: Dictionary in enemy_modifiers:
		if str(modifier.get("type", "")) != "initiative_bonus":
			continue
		var value := int(modifier.get("value", 0))
		if value == 0:
			continue
		for unit: Dictionary in encounter.get("units", []):
			if str(unit.get("team", "")) != "enemy":
				continue
			var stats: Dictionary = unit.get("stats", {})
			stats["initiative"] = int(stats.get("initiative", 0)) + value
			unit["stats"] = stats


func _apply_target_effects(encounter: Dictionary, modifiers: Dictionary) -> void:
	var target_effects: Dictionary = modifiers.get("target_effects", {})
	for target_id: String in target_effects.keys():
		var player := _player_unit_for_effect_target(encounter, modifiers, target_id)
		if player.is_empty():
			continue
		var effect: Dictionary = target_effects.get(target_id, {})
		if effect.is_empty():
			continue
		var resources: Dictionary = player.get("resources", {})
		var hp_loss := int(effect.get("hp_loss", 0))
		if hp_loss > 0:
			resources["hp"] = max(1, int(resources.get("hp", 1)) - hp_loss)
		var debuffs: Dictionary = effect.get("debuffs", {})
		if int(debuffs.get("limping", 0)) > 0 and resources.has("mp"):
			resources["mp"] = max(1, int(ceil(float(resources.get("mp", 1)) * 0.5)))
		player["resources"] = resources
		if int(debuffs.get("bleeding", 0)) > 0:
			_add_starting_status(player, {
				"id": "bleeding",
				"remaining_turns": 2,
				"tick_damage": 1,
				"source": "dungeon",
			})


func _first_player_unit(encounter: Dictionary) -> Dictionary:
	for unit: Dictionary in encounter.get("units", []):
		if str(unit.get("team", "")) == "player":
			return unit
	return {}


func _player_unit_for_effect_target(encounter: Dictionary, modifiers: Dictionary, target_id: String) -> Dictionary:
	if target_id == "party_member_0":
		return _first_player_unit(encounter)
	for slot: Dictionary in modifiers.get("party_formation", []):
		if str(slot.get("target_id", "")) != target_id:
			continue
		var unit := _unit_by_id(encounter, str(slot.get("combat_unit_id", "")))
		if not unit.is_empty() and str(unit.get("team", "")) == "player":
			return unit
	return {}


func _unit_by_id(encounter: Dictionary, unit_id: String) -> Dictionary:
	for unit: Dictionary in encounter.get("units", []):
		if str(unit.get("id", "")) == unit_id:
			return unit
	return {}


func _add_starting_status(unit: Dictionary, status: Dictionary) -> void:
	if not unit.has("statuses"):
		unit["statuses"] = []
	for existing: Dictionary in unit["statuses"]:
		if str(existing.get("id", "")) == str(status.get("id", "")):
			return
	unit["statuses"].append(status)


func _rebuild_turn_order_by_initiative(encounter: Dictionary) -> void:
	if not encounter.has("turn_state"):
		return
	var units: Array = encounter.get("units", []).duplicate()
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var initiative_a := int(a.get("stats", {}).get("initiative", 0))
		var initiative_b := int(b.get("stats", {}).get("initiative", 0))
		if initiative_a == initiative_b:
			return str(a.get("id", "")) < str(b.get("id", ""))
		return initiative_a > initiative_b
	)
	var order: Array[String] = []
	for unit: Dictionary in units:
		if int(unit.get("resources", {}).get("hp", 0)) > 0:
			order.append(str(unit.get("id", "")))
	encounter["turn_state"]["turn_order"] = order
	if not order.is_empty():
		encounter["turn_state"]["active_unit_id"] = order[0]


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
