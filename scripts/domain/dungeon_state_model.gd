extends RefCounted
class_name DungeonStateModel


static func initial_state(dungeon: Dictionary) -> Dictionary:
	var start_room_id := str(dungeon.get("start_room_id", ""))
	var state := {
		"dungeon_id": str(dungeon.get("id", "")),
		"current_room_id": start_room_id,
		"visited_room_ids": [],
		"cleared_room_ids": [],
		"unlocked_reward_room_ids": [],
		"pending_combat_request": {},
		"last_combat_result": {},
	}
	_add_unique(state["visited_room_ids"], start_room_id)
	_evaluate_room_entry(dungeon, state, start_room_id)
	return state


static func enter_room(dungeon: Dictionary, state: Dictionary, target_room_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var current_room_id := str(next_state.get("current_room_id", ""))
	if _room_by_id(dungeon, target_room_id).is_empty():
		return _result(next_state, "rejected", "missing_room", {})
	if not _rooms_are_connected(dungeon, current_room_id, target_room_id):
		return _result(next_state, "rejected", "room_not_adjacent", {})

	next_state["current_room_id"] = target_room_id
	_add_unique(next_state["visited_room_ids"], target_room_id)
	_evaluate_room_entry(dungeon, next_state, target_room_id)
	return _result(next_state, "accepted", "", {
		"type": "room_entered",
		"from_room_id": current_room_id,
		"to_room_id": target_room_id,
		"content": current_room_content(dungeon, next_state),
		"pending_combat_request": next_state["pending_combat_request"],
	})


static func current_room_content(dungeon: Dictionary, state: Dictionary) -> Array:
	var room := _room_by_id(dungeon, str(state.get("current_room_id", "")))
	if room.is_empty():
		return []
	return room.get("content", []).duplicate(true)


static func apply_combat_result(dungeon: Dictionary, state: Dictionary, result_payload: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var pending: Dictionary = next_state.get("pending_combat_request", {})
	if pending.is_empty():
		return _result(next_state, "rejected", "no_pending_combat", {})
	if str(result_payload.get("result", "")) == "in_progress":
		return _result(next_state, "rejected", "combat_still_in_progress", {})
	if str(result_payload.get("source_dungeon_id", "")) != str(pending.get("dungeon_id", "")):
		return _result(next_state, "rejected", "wrong_dungeon", {})
	if str(result_payload.get("source_room_id", "")) != str(pending.get("room_id", "")):
		return _result(next_state, "rejected", "wrong_room", {})

	var room_id := str(pending.get("room_id", ""))
	next_state["pending_combat_request"] = {}
	next_state["last_combat_result"] = result_payload.duplicate(true)
	if str(result_payload.get("result", "")) == "victory":
		_add_unique(next_state["cleared_room_ids"], room_id)
		if str(pending.get("content_type", "")) == "guarded_treasure":
			_add_unique(next_state["unlocked_reward_room_ids"], room_id)
		return _result(next_state, "accepted", "", {
			"type": "combat_result_applied",
			"result": "victory",
			"room_id": room_id,
			"room_cleared": true,
			"reward_unlocked": str(pending.get("content_type", "")) == "guarded_treasure",
		})
	if str(result_payload.get("result", "")) == "defeat":
		return _result(next_state, "accepted", "", {
			"type": "combat_result_applied",
			"result": "defeat",
			"room_id": room_id,
			"room_cleared": false,
			"reward_unlocked": false,
		})
	return _result(next_state, "rejected", "unsupported_combat_result", {})


static func room_is_visited(state: Dictionary, room_id: String) -> bool:
	return state.get("visited_room_ids", []).has(room_id)


static func room_is_cleared(state: Dictionary, room_id: String) -> bool:
	return state.get("cleared_room_ids", []).has(room_id)


static func room_reward_is_unlocked(state: Dictionary, room_id: String) -> bool:
	return state.get("unlocked_reward_room_ids", []).has(room_id)


static func _evaluate_room_entry(dungeon: Dictionary, state: Dictionary, room_id: String) -> void:
	state["pending_combat_request"] = {}
	var room := _room_by_id(dungeon, room_id)
	if room.is_empty():
		return

	var content: Array = room.get("content", [])
	if _content_has_pending_combat(state, room_id, content):
		var combat_content := _first_combat_content(content)
		state["pending_combat_request"] = {
			"dungeon_id": str(dungeon.get("id", "")),
			"room_id": room_id,
			"content_type": str(combat_content.get("type", "")),
			"combat_encounter_path": str(combat_content.get("combat_encounter_path", "")),
		}
		return

	if _content_is_empty(content):
		_add_unique(state["cleared_room_ids"], room_id)


static func _content_has_pending_combat(state: Dictionary, room_id: String, content: Array) -> bool:
	if room_is_cleared(state, room_id):
		return false
	for item: Dictionary in content:
		if item.get("type", "") in ["combat", "guarded_treasure"] and str(item.get("combat_encounter_path", "")) != "":
			return true
	return false


static func _first_combat_content(content: Array) -> Dictionary:
	for item: Dictionary in content:
		if item.get("type", "") in ["combat", "guarded_treasure"] and str(item.get("combat_encounter_path", "")) != "":
			return item
	return {}


static func _content_is_empty(content: Array) -> bool:
	if content.is_empty():
		return true
	for item: Dictionary in content:
		if item.get("type", "") != "empty":
			return false
	return true


static func _rooms_are_connected(dungeon: Dictionary, first_room_id: String, second_room_id: String) -> bool:
	if first_room_id == second_room_id:
		return true
	for corridor: Dictionary in dungeon.get("corridors", []):
		var from_room_id := str(corridor.get("from", ""))
		var to_room_id := str(corridor.get("to", ""))
		if from_room_id == first_room_id and to_room_id == second_room_id:
			return true
		if from_room_id == second_room_id and to_room_id == first_room_id:
			return true
	return false


static func _room_by_id(dungeon: Dictionary, room_id: String) -> Dictionary:
	for room: Dictionary in dungeon.get("rooms", []):
		if room.get("id", "") == room_id:
			return room
	return {}


static func _add_unique(items: Array, value: String) -> void:
	if value == "":
		return
	if not items.has(value):
		items.append(value)


static func _result(state: Dictionary, status: String, rejection: String, event: Dictionary) -> Dictionary:
	return {
		"status": status,
		"rejection": rejection,
		"state": state,
		"event": event,
	}
