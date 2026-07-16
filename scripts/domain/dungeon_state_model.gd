extends RefCounted
class_name DungeonStateModel


static func initial_state(dungeon: Dictionary) -> Dictionary:
	var start_room_id := str(dungeon.get("start_room_id", ""))
	var max_light_level := int(dungeon.get("max_light_level", 4))
	var state := {
		"dungeon_id": str(dungeon.get("id", "")),
		"current_room_id": start_room_id,
		"visited_room_ids": [],
		"cleared_room_ids": [],
		"unlocked_reward_room_ids": [],
		"claimed_reward_room_ids": [],
		"claimed_rewards": [],
		"reward_totals": {"xp": 0, "gold": 0, "items": []},
		"unlocked_room_ids": [],
		"pending_combat_request": {},
		"last_combat_result": {},
		"completed": false,
		"completed_at_room_id": "",
		"supplies": dungeon.get("starting_supplies", {"lamp_oil": 2, "pickaxe": 1}).duplicate(true),
		"max_light_level": max_light_level,
		"light_level": max_light_level,
		"light_state": _light_state_for_level(max_light_level),
		"traversal_count": 0,
		"hazard_seed": int(dungeon.get("hazard_seed", 1)),
		"pending_corridor_hazard": {},
		"resolved_hazard_ids": [],
		"hazard_log": [],
		"party_effects": {"hp_loss": 0, "debuffs": []},
		"target_effects": {},
		"active_debuffs": {},
		"exploration_modifiers": _exploration_modifiers_for_light(max_light_level),
	}
	_add_unique(state["visited_room_ids"], start_room_id)
	_evaluate_room_entry(dungeon, state, start_room_id)
	return state


static func enter_room(dungeon: Dictionary, state: Dictionary, target_room_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if not next_state.get("pending_corridor_hazard", {}).is_empty():
		return _result(next_state, "rejected", "corridor_hazard_pending", next_state["pending_corridor_hazard"])
	var current_room_id := str(next_state.get("current_room_id", ""))
	var target_room := _room_by_id(dungeon, target_room_id)
	if target_room.is_empty():
		return _result(next_state, "rejected", "missing_room", {})
	var corridor := _corridor_between(dungeon, current_room_id, target_room_id)
	if corridor.is_empty():
		return _result(next_state, "rejected", "room_not_adjacent", {})
	if _room_is_locked_for_state(next_state, target_room):
		return _result(next_state, "rejected", "locked_missing_key", {})

	var pending_hazard := _first_pending_corridor_hazard(next_state, corridor)
	if not pending_hazard.is_empty():
		var prompt := _corridor_hazard_prompt(next_state, corridor, pending_hazard, current_room_id, target_room_id)
		next_state["pending_corridor_hazard"] = prompt
		return _result(next_state, "choice_required", "corridor_hazard_pending", prompt)

	return _complete_corridor_traversal(dungeon, next_state, corridor, current_room_id, target_room_id, {})


static func resolve_corridor_hazard_choice(dungeon: Dictionary, state: Dictionary, choice_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var pending: Dictionary = next_state.get("pending_corridor_hazard", {})
	if pending.is_empty():
		return _result(next_state, "rejected", "no_pending_corridor_hazard", {})
	var from_room_id := str(pending.get("from_room_id", ""))
	var target_room_id := str(pending.get("to_room_id", ""))
	var target_room := _room_by_id(dungeon, target_room_id)
	if target_room.is_empty():
		return _result(next_state, "rejected", "missing_room", {})
	var corridor := _corridor_between(dungeon, from_room_id, target_room_id)
	if corridor.is_empty():
		return _result(next_state, "rejected", "room_not_adjacent", {})
	var hazard := _hazard_by_id(corridor, str(pending.get("hazard_id", "")))
	if hazard.is_empty():
		return _result(next_state, "rejected", "missing_hazard", {})
	if not _choice_is_available(pending, choice_id):
		return _result(next_state, "rejected", "choice_unavailable", pending)

	next_state["pending_corridor_hazard"] = {}
	return _complete_corridor_traversal(dungeon, next_state, corridor, from_room_id, target_room_id, {
		"hazard_id": str(hazard.get("id", "")),
		"choice_id": choice_id,
	})


static func _complete_corridor_traversal(dungeon: Dictionary, state: Dictionary, corridor: Dictionary, current_room_id: String, target_room_id: String, hazard_choice: Dictionary) -> Dictionary:
	var target_room := _room_by_id(dungeon, target_room_id)
	var traversal_events := _resolve_corridor_traversal(dungeon, state, corridor, current_room_id, target_room_id, hazard_choice)
	for event: Dictionary in traversal_events:
		if bool(event.get("blocks_traversal", false)):
			return _result(state, "rejected", "hazard_blocked", event)

	state["current_room_id"] = target_room_id
	_add_unique(state["visited_room_ids"], target_room_id)
	if str(target_room.get("locked_by_item_id", "")) != "":
		_add_unique(state["unlocked_room_ids"], target_room_id)
	_evaluate_room_entry(dungeon, state, target_room_id)
	return _result(state, "accepted", "", {
		"type": "room_entered",
		"from_room_id": current_room_id,
		"to_room_id": target_room_id,
		"content": current_room_content(dungeon, state),
		"pending_combat_request": state["pending_combat_request"],
		"traversal_events": traversal_events,
	})


static func current_room_content(dungeon: Dictionary, state: Dictionary) -> Array:
	var room := _room_by_id(dungeon, str(state.get("current_room_id", "")))
	if room.is_empty():
		return []
	return room.get("content", []).duplicate(true)


static func claim_current_reward(dungeon: Dictionary, state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var room_id := str(next_state.get("current_room_id", ""))
	var room := _room_by_id(dungeon, room_id)
	if room.is_empty():
		return _result(next_state, "rejected", "missing_room", {})
	if room_reward_is_claimed(next_state, room_id):
		return _result(next_state, "rejected", "reward_already_claimed", {})
	var reward_content := _claimable_reward_content(next_state, room_id, room.get("content", []))
	if reward_content.is_empty():
		return _result(next_state, "rejected", "no_claimable_reward", {})

	var reward_payload: Dictionary = reward_content.get("rewards", {}).duplicate(true)
	var reward_record := {
		"room_id": room_id,
		"content_type": str(reward_content.get("type", "")),
		"rewards": reward_payload,
	}
	_add_unique(next_state["claimed_reward_room_ids"], room_id)
	next_state["claimed_rewards"].append(reward_record)
	_apply_reward_totals(next_state, reward_payload)
	_add_unique(next_state["cleared_room_ids"], room_id)
	return _result(next_state, "accepted", "", {
		"type": "reward_claimed",
		"room_id": room_id,
		"rewards": reward_payload,
	})


static func complete_current_room(dungeon: Dictionary, state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var room_id := str(next_state.get("current_room_id", ""))
	var room := _room_by_id(dungeon, room_id)
	if room.is_empty():
		return _result(next_state, "rejected", "missing_room", {})
	if not next_state.get("pending_combat_request", {}).is_empty():
		return _result(next_state, "rejected", "pending_combat", {})
	if str(room.get("kind", "")) != "exit":
		return _result(next_state, "rejected", "not_exit_room", {})
	next_state["completed"] = true
	next_state["completed_at_room_id"] = room_id
	_add_unique(next_state["cleared_room_ids"], room_id)
	return _result(next_state, "accepted", "", {
		"type": "dungeon_completed",
		"room_id": room_id,
	})


static func reward_totals(state: Dictionary) -> Dictionary:
	return state.get("reward_totals", {"xp": 0, "gold": 0, "items": []}).duplicate(true)


static func use_lamp_oil(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var supplies: Dictionary = next_state.get("supplies", {})
	var oil_count := int(supplies.get("lamp_oil", 0))
	var max_light := int(next_state.get("max_light_level", 4))
	if oil_count <= 0:
		return _result(next_state, "rejected", "missing_lamp_oil", {})
	if int(next_state.get("light_level", max_light)) >= max_light:
		return _result(next_state, "rejected", "light_already_full", {})
	supplies["lamp_oil"] = oil_count - 1
	next_state["supplies"] = supplies
	next_state["light_level"] = max_light
	_refresh_light_state(next_state)
	var event := {
		"type": "lamp_oil_used",
		"supply_consumed": "lamp_oil",
		"light_level": next_state["light_level"],
		"light_state": next_state["light_state"],
		"message": "Lamp oil restores the expedition light.",
	}
	next_state["hazard_log"].append(event)
	return _result(next_state, "accepted", "", event)


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


static func room_reward_is_claimed(state: Dictionary, room_id: String) -> bool:
	return state.get("claimed_reward_room_ids", []).has(room_id)


static func room_is_unlocked(state: Dictionary, room_id: String) -> bool:
	return state.get("unlocked_room_ids", []).has(room_id)


static func supply_count(state: Dictionary, supply_id: String) -> int:
	return int(state.get("supplies", {}).get(supply_id, 0))


static func active_debuff_summary(state: Dictionary) -> Array[String]:
	var summary: Array[String] = []
	var debuffs: Dictionary = state.get("active_debuffs", {})
	var ids := debuffs.keys()
	ids.sort()
	for debuff_id: String in ids:
		var debuff: Dictionary = debuffs.get(debuff_id, {})
		var stacks := int(debuff.get("stacks", 0))
		if stacks <= 0:
			continue
		summary.append("%s x%s" % [debuff_id, stacks])
	return summary


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
			"exploration_modifiers": state.get("exploration_modifiers", {}).duplicate(true),
			"dungeon_modifiers": _combat_modifiers_for_state(state),
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


static func _claimable_reward_content(state: Dictionary, room_id: String, content: Array) -> Dictionary:
	for item: Dictionary in content:
		var content_type := str(item.get("type", ""))
		if not item.has("rewards"):
			continue
		if content_type == "treasure":
			return item
		if content_type == "guarded_treasure" and room_reward_is_unlocked(state, room_id):
			return item
	return {}


static func _apply_reward_totals(state: Dictionary, reward_payload: Dictionary) -> void:
	if not state.has("reward_totals"):
		state["reward_totals"] = {"xp": 0, "gold": 0, "items": []}
	var totals: Dictionary = state["reward_totals"]
	totals["xp"] = int(totals.get("xp", 0)) + int(reward_payload.get("xp", 0))
	totals["gold"] = int(totals.get("gold", 0)) + int(reward_payload.get("gold", 0))
	if not totals.has("items"):
		totals["items"] = []
	for item_id: String in reward_payload.get("items", []):
		totals["items"].append(item_id)


static func _room_is_locked_for_state(state: Dictionary, room: Dictionary) -> bool:
	var required_item_id := str(room.get("locked_by_item_id", ""))
	if required_item_id == "":
		return false
	if room_is_unlocked(state, str(room.get("id", ""))):
		return false
	var totals := reward_totals(state)
	return not totals.get("items", []).has(required_item_id)


static func _first_pending_corridor_hazard(state: Dictionary, corridor: Dictionary) -> Dictionary:
	for hazard: Dictionary in corridor.get("hazards", []):
		if not _hazard_already_resolved(state, hazard):
			return hazard
	return {}


static func _corridor_hazard_prompt(state: Dictionary, corridor: Dictionary, hazard: Dictionary, from_room_id: String, to_room_id: String) -> Dictionary:
	var required_supply_id := str(hazard.get("required_supply_id", ""))
	var supply_available := required_supply_id == "" or supply_count(state, required_supply_id) > 0
	var choices: Array[Dictionary] = []
	for choice: Dictionary in hazard.get("choices", []):
		var choice_id := str(choice.get("id", ""))
		var requires_supply := bool(choice.get("requires_supply", false))
		choices.append({
			"id": choice_id,
			"label": str(choice.get("label", choice_id)),
			"available": not requires_supply or supply_available,
			"requires_supply": requires_supply,
		})
	if choices.is_empty():
		choices.append({
			"id": "use_supply",
			"label": "Use %s" % required_supply_id,
			"available": supply_available and required_supply_id != "",
			"requires_supply": true,
		})
		choices.append({
			"id": "force_passage",
			"label": "Force passage",
			"available": true,
			"requires_supply": false,
		})
	return {
		"type": "corridor_hazard_choice_required",
		"hazard_id": str(hazard.get("id", "")),
		"hazard_type": str(hazard.get("type", "")),
		"corridor_id": str(corridor.get("id", "")),
		"from_room_id": from_room_id,
		"to_room_id": to_room_id,
		"required_supply_id": required_supply_id,
		"supply_available": supply_available,
		"choices": choices,
		"message": str(hazard.get("message", "")),
	}


static func _choice_is_available(prompt: Dictionary, choice_id: String) -> bool:
	for choice: Dictionary in prompt.get("choices", []):
		if str(choice.get("id", "")) == choice_id:
			return bool(choice.get("available", false))
	return false


static func _resolve_corridor_traversal(dungeon: Dictionary, state: Dictionary, corridor: Dictionary, from_room_id: String, to_room_id: String, hazard_choice: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	state["traversal_count"] = int(state.get("traversal_count", 0)) + 1
	var light_event := _apply_light_decay(state, corridor, from_room_id, to_room_id)
	if not light_event.is_empty():
		events.append(light_event)
		state["hazard_log"].append(light_event)
	for hazard: Dictionary in corridor.get("hazards", []):
		if _hazard_already_resolved(state, hazard):
			continue
		if str(hazard_choice.get("hazard_id", "")) != str(hazard.get("id", "")):
			continue
		var hazard_event := _resolve_hazard(state, corridor, hazard, from_room_id, to_room_id, str(hazard_choice.get("choice_id", "")))
		if hazard_event.is_empty():
			continue
		events.append(hazard_event)
		state["hazard_log"].append(hazard_event)
		_add_unique(state["resolved_hazard_ids"], str(hazard.get("id", "")))
	return events


static func _apply_light_decay(state: Dictionary, corridor: Dictionary, from_room_id: String, to_room_id: String) -> Dictionary:
	var decay := int(corridor.get("light_decay", 1))
	if decay <= 0:
		return {}
	var old_level := int(state.get("light_level", state.get("max_light_level", 4)))
	var new_level = max(0, old_level - decay)
	state["light_level"] = new_level
	_refresh_light_state(state)
	return {
		"type": "light_changed",
		"corridor_id": str(corridor.get("id", "")),
		"from_room_id": from_room_id,
		"to_room_id": to_room_id,
		"old_light_level": old_level,
		"light_level": new_level,
		"light_state": str(state.get("light_state", "")),
		"consequences": [{"type": "reduce_light", "amount": decay}],
		"exploration_modifiers": state.get("exploration_modifiers", {}).duplicate(true),
		"message": "The lamp dims during corridor traversal.",
	}


static func _resolve_hazard(state: Dictionary, corridor: Dictionary, hazard: Dictionary, from_room_id: String, to_room_id: String, selected_choice_id: String) -> Dictionary:
	var required_supply_id := str(hazard.get("required_supply_id", ""))
	var has_supply := required_supply_id == "" or supply_count(state, required_supply_id) > 0
	var choice_id := selected_choice_id
	if choice_id == "":
		choice_id = "use_supply" if has_supply and required_supply_id != "" else "force_passage"
	var outcome := _select_hazard_outcome(state, hazard, choice_id, has_supply)
	if outcome.is_empty():
		return {}
	var consequences: Array = outcome.get("consequences", []).duplicate(true)
	var supply_consumed := ""
	if has_supply and required_supply_id != "" and bool(outcome.get("consume_required_supply", false)):
		_consume_supply(state, required_supply_id, 1)
		supply_consumed = required_supply_id
		consequences.append({"type": "consume_supply", "supply_id": required_supply_id, "amount": 1})
	_apply_consequences(state, consequences)
	return {
		"type": "corridor_hazard_resolved",
		"hazard_id": str(hazard.get("id", "")),
		"hazard_type": str(hazard.get("type", "")),
		"corridor_id": str(corridor.get("id", "")),
		"from_room_id": from_room_id,
		"to_room_id": to_room_id,
		"required_supply_id": required_supply_id,
		"supply_available": has_supply,
		"supply_consumed": supply_consumed,
		"choice_id": choice_id,
		"outcome_id": str(outcome.get("id", "")),
		"consequences": consequences,
		"message": str(outcome.get("message", hazard.get("message", ""))),
		"blocks_traversal": bool(outcome.get("blocks_traversal", false)),
	}


static func _select_hazard_outcome(state: Dictionary, hazard: Dictionary, choice_id: String, has_supply: bool) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for outcome: Dictionary in hazard.get("outcomes", []):
		var when: Dictionary = outcome.get("when", {})
		if str(when.get("choice_id", choice_id)) != choice_id:
			continue
		if when.has("has_supply") and bool(when.get("has_supply", false)) != has_supply:
			continue
		candidates.append(outcome)
	if candidates.is_empty():
		return {}
	if candidates.size() == 1:
		return candidates[0]
	var total_weight := 0
	for candidate: Dictionary in candidates:
		total_weight += max(1, int(candidate.get("weight", 1)))
	var roll := _deterministic_roll(state, str(hazard.get("id", "")), total_weight)
	var cursor := 0
	for candidate: Dictionary in candidates:
		cursor += max(1, int(candidate.get("weight", 1)))
		if roll < cursor:
			return candidate
	return candidates[candidates.size() - 1]


static func _deterministic_roll(state: Dictionary, hazard_id: String, modulo: int) -> int:
	if modulo <= 0:
		return 0
	var value := int(state.get("hazard_seed", 1)) + int(state.get("traversal_count", 0)) * 1103515245
	for index in range(hazard_id.length()):
		value += hazard_id.unicode_at(index) * (index + 17)
	return abs(value) % modulo


static func _apply_consequences(state: Dictionary, consequences: Array) -> void:
	for consequence: Dictionary in consequences:
		match str(consequence.get("type", "")):
			"hp_loss":
				var party_effects: Dictionary = state.get("party_effects", {"hp_loss": 0, "debuffs": []})
				var amount := int(consequence.get("amount", 0))
				var target_id := _consequence_target_id(consequence)
				party_effects["hp_loss"] = int(party_effects.get("hp_loss", 0)) + amount
				state["party_effects"] = party_effects
				_apply_target_hp_loss(state, target_id, amount)
			"apply_debuff":
				_apply_debuff(state, str(consequence.get("debuff_id", "")), int(consequence.get("stacks", 1)), _consequence_target_id(consequence))
			"reduce_light":
				state["light_level"] = max(0, int(state.get("light_level", 0)) - int(consequence.get("amount", 0)))
				_refresh_light_state(state)
			"restore_light":
				state["light_level"] = min(int(state.get("max_light_level", 4)), int(state.get("light_level", 0)) + int(consequence.get("amount", 0)))
				_refresh_light_state(state)


static func _consume_supply(state: Dictionary, supply_id: String, amount: int) -> void:
	var supplies: Dictionary = state.get("supplies", {})
	supplies[supply_id] = max(0, int(supplies.get(supply_id, 0)) - amount)
	state["supplies"] = supplies


static func _apply_debuff(state: Dictionary, debuff_id: String, stacks: int, target_id: String) -> void:
	if debuff_id == "":
		return
	var applied_stacks = max(1, stacks)
	var party_effects: Dictionary = state.get("party_effects", {"hp_loss": 0, "debuffs": []})
	if not party_effects.has("debuffs"):
		party_effects["debuffs"] = []
	_add_unique(party_effects["debuffs"], debuff_id)
	state["party_effects"] = party_effects

	var active_debuffs: Dictionary = state.get("active_debuffs", {})
	var current: Dictionary = active_debuffs.get(debuff_id, {"id": debuff_id, "stacks": 0, "targets": []})
	current["id"] = debuff_id
	current["stacks"] = int(current.get("stacks", 0)) + applied_stacks
	if not current.has("targets"):
		current["targets"] = []
	_add_unique(current["targets"], target_id)
	active_debuffs[debuff_id] = current
	state["active_debuffs"] = active_debuffs
	_apply_target_debuff(state, target_id, debuff_id, applied_stacks)


static func _apply_target_hp_loss(state: Dictionary, target_id: String, amount: int) -> void:
	var target_effects: Dictionary = state.get("target_effects", {})
	var target: Dictionary = target_effects.get(target_id, {"id": target_id, "hp_loss": 0, "debuffs": {}})
	target["id"] = target_id
	target["hp_loss"] = int(target.get("hp_loss", 0)) + amount
	target_effects[target_id] = target
	state["target_effects"] = target_effects


static func _apply_target_debuff(state: Dictionary, target_id: String, debuff_id: String, stacks: int) -> void:
	var target_effects: Dictionary = state.get("target_effects", {})
	var target: Dictionary = target_effects.get(target_id, {"id": target_id, "hp_loss": 0, "debuffs": {}})
	var debuffs: Dictionary = target.get("debuffs", {})
	debuffs[debuff_id] = int(debuffs.get(debuff_id, 0)) + stacks
	target["id"] = target_id
	target["debuffs"] = debuffs
	target_effects[target_id] = target
	state["target_effects"] = target_effects


static func _consequence_target_id(consequence: Dictionary) -> String:
	var target_id := str(consequence.get("target_id", "party_member_0"))
	if target_id == "":
		return "party_member_0"
	return target_id


static func _combat_modifiers_for_state(state: Dictionary) -> Dictionary:
	var exploration_modifiers: Dictionary = state.get("exploration_modifiers", {})
	var enemy_advantage := int(exploration_modifiers.get("enemy_advantage", 0))
	var enemy_modifiers: Array[Dictionary] = []
	if enemy_advantage > 0:
		enemy_modifiers.append({
			"type": "initiative_bonus",
			"value": enemy_advantage,
			"source": "light:%s" % str(state.get("light_state", "")),
		})
	return {
		"light_state": str(state.get("light_state", "bright")),
		"light_level": int(state.get("light_level", 0)),
		"ambush_risk": float(exploration_modifiers.get("ambush_risk", 0.0)),
		"enemy_modifiers": enemy_modifiers,
		"active_debuffs": state.get("active_debuffs", {}).duplicate(true),
		"target_effects": state.get("target_effects", {}).duplicate(true),
		"party_effects": state.get("party_effects", {}).duplicate(true),
	}


static func _hazard_already_resolved(state: Dictionary, hazard: Dictionary) -> bool:
	var trigger: Dictionary = hazard.get("trigger", {})
	if str(trigger.get("mode", "first_traversal")) != "first_traversal":
		return false
	return state.get("resolved_hazard_ids", []).has(str(hazard.get("id", "")))


static func _hazard_by_id(corridor: Dictionary, hazard_id: String) -> Dictionary:
	for hazard: Dictionary in corridor.get("hazards", []):
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}


static func _refresh_light_state(state: Dictionary) -> void:
	var level := int(state.get("light_level", 0))
	state["light_state"] = _light_state_for_level(level)
	state["exploration_modifiers"] = _exploration_modifiers_for_light(level)


static func _light_state_for_level(level: int) -> String:
	if level >= 3:
		return "bright"
	if level == 2:
		return "dim"
	if level == 1:
		return "dark"
	return "blackout"


static func _exploration_modifiers_for_light(level: int) -> Dictionary:
	var light_state := _light_state_for_level(level)
	match light_state:
		"dim":
			return {"light_state": light_state, "hazard_risk_bonus": 0.1, "enemy_advantage": 0}
		"dark":
			return {"light_state": light_state, "hazard_risk_bonus": 0.25, "enemy_advantage": 1}
		"blackout":
			return {"light_state": light_state, "hazard_risk_bonus": 0.5, "enemy_advantage": 2, "ambush_risk": 0.35}
		_:
			return {"light_state": light_state, "hazard_risk_bonus": 0.0, "enemy_advantage": 0}


static func _corridor_between(dungeon: Dictionary, first_room_id: String, second_room_id: String) -> Dictionary:
	if first_room_id == second_room_id:
		return {"id": "same_room", "from": first_room_id, "to": second_room_id, "light_decay": 0}
	for corridor: Dictionary in dungeon.get("corridors", []):
		var from_room_id := str(corridor.get("from", ""))
		var to_room_id := str(corridor.get("to", ""))
		if from_room_id == first_room_id and to_room_id == second_room_id:
			return corridor
		if from_room_id == second_room_id and to_room_id == first_room_id:
			return corridor
	return {}


static func _rooms_are_connected(dungeon: Dictionary, first_room_id: String, second_room_id: String) -> bool:
	return not _corridor_between(dungeon, first_room_id, second_room_id).is_empty()


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
