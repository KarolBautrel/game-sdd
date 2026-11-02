extends RefCounted
class_name DungeonStateModel

const PartyRoster := preload("res://scripts/domain/party_roster.gd")
const GraphQuality := preload("res://scripts/domain/dungeon_graph_quality.gd")
const DEFAULT_RETURN_SCENE_PATH := "res://scenes/app/App.tscn"


static func initial_state(dungeon: Dictionary, selected_supply_loadout: Dictionary = {}) -> Dictionary:
	var start_room_id := str(dungeon.get("start_room_id", ""))
	var max_light_level := int(dungeon.get("max_light_level", 4))
	var starting_supplies := _supplies_for_loadout(dungeon, selected_supply_loadout)
	var state := {
		"dungeon_id": str(dungeon.get("id", "")),
		"current_room_id": start_room_id,
		"visited_room_ids": [],
		"cleared_room_ids": [],
		"unlocked_reward_room_ids": [],
		"claimed_reward_room_ids": [],
		"claimed_rewards": [],
		"run_inventory": _empty_run_inventory(),
		"reward_totals": {"xp": 0, "gold": 0, "items": []},
		"unlocked_room_ids": [],
		"pending_combat_request": {},
		"pending_room_event": {},
		"last_combat_result": {},
		"completed": false,
		"completed_at_room_id": "",
		"run_outcome": "in_progress",
		"run_result_payload": {},
		"supplies": starting_supplies.duplicate(true),
		"selected_supply_loadout": starting_supplies.duplicate(true),
		"max_light_level": max_light_level,
		"light_level": max_light_level,
		"light_state": _light_state_for_level(max_light_level),
		"traversal_count": 0,
		"hazard_seed": int(dungeon.get("hazard_seed", 1)),
		"pending_corridor_hazard": {},
		"resolved_hazard_ids": [],
		"resolved_room_event_ids": [],
		"hazard_log": [],
		"room_event_log": [],
		"camp_log": [],
		"room_event_history": _empty_room_event_history(),
		"party_formation": _default_party_formation(dungeon),
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
	if bool(next_state.get("completed", false)):
		return _result(next_state, "rejected", "run_completed", {})
	if not next_state.get("pending_combat_request", {}).is_empty():
		return _result(next_state, "rejected", "pending_combat", {})
	if not next_state.get("pending_corridor_hazard", {}).is_empty():
		return _result(next_state, "rejected", "corridor_hazard_pending", next_state["pending_corridor_hazard"])
	if not next_state.get("pending_room_event", {}).is_empty():
		return _result(next_state, "rejected", "room_event_pending", next_state["pending_room_event"])
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


static func resolve_room_event_choice(dungeon: Dictionary, state: Dictionary, choice_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var pending: Dictionary = next_state.get("pending_room_event", {})
	if pending.is_empty():
		return _result(next_state, "rejected", "no_pending_room_event", {})
	if not _room_event_choice_is_available(pending, choice_id):
		return _result(next_state, "rejected", "room_event_choice_unavailable", pending)
	var event := _room_event_from_pending(pending)
	if event.is_empty():
		return _result(next_state, "rejected", "missing_room_event", pending)
	var outcome := _select_room_event_outcome(next_state, event, choice_id)
	if outcome.is_empty():
		return _result(next_state, "rejected", "missing_room_event_outcome", pending)
	var consequences: Array = outcome.get("consequences", []).duplicate(true)
	_apply_consequences(next_state, consequences)
	var event_id := str(pending.get("room_event_id", ""))
	if not next_state.has("resolved_room_event_ids"):
		next_state["resolved_room_event_ids"] = []
	if not next_state.has("room_event_log"):
		next_state["room_event_log"] = []
	_add_unique(next_state["resolved_room_event_ids"], event_id)
	next_state["pending_room_event"] = {}
	var room := _room_by_id(dungeon, str(pending.get("room_id", "")))
	if _room_can_clear_after_room_event(next_state, room):
		_add_unique(next_state["cleared_room_ids"], str(room.get("id", "")))
	var room_event := {
		"type": "room_event_resolved",
		"room_event_id": event_id,
		"event_id": str(pending.get("event_id", "")),
		"pool_id": str(pending.get("pool_id", "")),
		"event_type": str(event.get("type", "")),
		"tags": event.get("tags", []).duplicate(true),
		"room_id": str(pending.get("room_id", "")),
		"choice_id": choice_id,
		"outcome_id": str(outcome.get("id", "")),
		"outcome_tone": str(outcome.get("tone", "neutral")),
		"skill_check": outcome.get("skill_check", {}).duplicate(true),
		"consequences": consequences,
		"message": str(outcome.get("message", event.get("message", ""))),
	}
	next_state["room_event_log"].append(room_event)
	_record_room_event_history(next_state, room_event)
	return _result(next_state, "accepted", "", room_event)


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
	if not next_state.get("pending_room_event", {}).is_empty():
		return _result(next_state, "rejected", "room_event_pending", next_state["pending_room_event"])
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
	_apply_reward_to_run_inventory(next_state, reward_record)
	_add_unique(next_state["cleared_room_ids"], room_id)
	return _result(next_state, "accepted", "", {
		"type": "reward_claimed",
		"room_id": room_id,
		"rewards": reward_payload,
	})


static func complete_current_room(dungeon: Dictionary, state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if not next_state.get("pending_room_event", {}).is_empty():
		return _result(next_state, "rejected", "room_event_pending", next_state["pending_room_event"])
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
	next_state["run_outcome"] = "completed"
	_add_unique(next_state["cleared_room_ids"], room_id)
	var payload := run_result_payload(dungeon, next_state, "completed")
	next_state["run_result_payload"] = payload.duplicate(true)
	return _result(next_state, "accepted", "", {
		"type": "dungeon_completed",
		"room_id": room_id,
		"run_result_payload": payload,
	})


static func retreat_run(dungeon: Dictionary, state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if not bool(dungeon.get("exit_rules", {}).get("allow_retreat", false)):
		return _result(next_state, "rejected", "retreat_not_allowed", {})
	if not next_state.get("pending_combat_request", {}).is_empty():
		return _result(next_state, "rejected", "pending_combat", {})
	if not next_state.get("pending_corridor_hazard", {}).is_empty():
		return _result(next_state, "rejected", "corridor_hazard_pending", next_state["pending_corridor_hazard"])
	if not next_state.get("pending_room_event", {}).is_empty():
		return _result(next_state, "rejected", "room_event_pending", next_state["pending_room_event"])
	next_state["completed"] = true
	next_state["completed_at_room_id"] = str(next_state.get("current_room_id", ""))
	next_state["run_outcome"] = "retreated"
	var payload := run_result_payload(dungeon, next_state, "retreated")
	next_state["run_result_payload"] = payload.duplicate(true)
	return _result(next_state, "accepted", "", {
		"type": "dungeon_run_finished",
		"outcome": "retreated",
		"room_id": str(next_state.get("current_room_id", "")),
		"run_result_payload": payload,
	})


static func fail_run(dungeon: Dictionary, state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	next_state["completed"] = true
	next_state["completed_at_room_id"] = str(next_state.get("current_room_id", ""))
	next_state["run_outcome"] = "failed"
	var payload := run_result_payload(dungeon, next_state, "failed")
	next_state["run_result_payload"] = payload.duplicate(true)
	return _result(next_state, "accepted", "", {
		"type": "dungeon_run_finished",
		"outcome": "failed",
		"room_id": str(next_state.get("current_room_id", "")),
		"run_result_payload": payload,
	})


static func run_result_payload(dungeon: Dictionary, state: Dictionary, outcome: String = "") -> Dictionary:
	var resolved_outcome := str(outcome)
	if resolved_outcome == "":
		resolved_outcome = str(state.get("run_outcome", "completed" if bool(state.get("completed", false)) else "in_progress"))
	if not resolved_outcome in ["completed", "retreated", "failed", "in_progress"]:
		resolved_outcome = "failed"
	var totals := reward_totals(state)
	var claimed_inventory := run_inventory(state)
	var kept_rewards := _kept_rewards_for_outcome(claimed_inventory, resolved_outcome)
	var lost_rewards := _lost_rewards_for_outcome(claimed_inventory, resolved_outcome)
	return {
		"type": "dungeon_run_result",
		"outcome": resolved_outcome,
		"dungeon_id": str(dungeon.get("id", state.get("dungeon_id", ""))),
		"dungeon_display_name": str(dungeon.get("display_name", "")),
		"current_room_id": str(state.get("current_room_id", "")),
		"completed_at_room_id": str(state.get("completed_at_room_id", "")),
		"visited_room_ids": state.get("visited_room_ids", []).duplicate(true),
		"cleared_room_ids": state.get("cleared_room_ids", []).duplicate(true),
		"claimed_rewards": state.get("claimed_rewards", []).duplicate(true),
		"claimed_run_inventory": claimed_inventory,
		"reward_totals": totals,
		"kept_rewards": kept_rewards,
		"lost_rewards": lost_rewards,
		"inventory_delta": kept_rewards.duplicate(true),
		"persistent_effects": {
			"active_debuffs": state.get("active_debuffs", {}).duplicate(true),
			"party_effects": state.get("party_effects", {}).duplicate(true),
			"target_effects": state.get("target_effects", {}).duplicate(true),
		},
		"next_scene_path": DEFAULT_RETURN_SCENE_PATH,
	}


static func reward_totals(state: Dictionary) -> Dictionary:
	if state.has("run_inventory"):
		var inventory := run_inventory(state)
		return {
			"xp": int(inventory.get("xp", 0)),
			"gold": int(inventory.get("gold", 0)),
			"items": inventory.get("items", []).duplicate(true),
		}
	return state.get("reward_totals", {"xp": 0, "gold": 0, "items": []}).duplicate(true)


static func run_inventory(state: Dictionary) -> Dictionary:
	var inventory: Dictionary = state.get("run_inventory", _empty_run_inventory())
	return {
		"xp": int(inventory.get("xp", 0)),
		"gold": int(inventory.get("gold", 0)),
		"items": inventory.get("items", []).duplicate(true),
		"reward_records": inventory.get("reward_records", []).duplicate(true),
	}


static func room_event_history(state: Dictionary) -> Dictionary:
	var history: Dictionary = state.get("room_event_history", _empty_room_event_history())
	return {
		"resolved_count": int(history.get("resolved_count", 0)),
		"event_ids": history.get("event_ids", []).duplicate(true),
		"type_counts": history.get("type_counts", {}).duplicate(true),
		"tag_counts": history.get("tag_counts", {}).duplicate(true),
		"tone_counts": history.get("tone_counts", {}).duplicate(true),
	}


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


static func use_recovery_supply(state: Dictionary, supply_id: String = "antidote") -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if supply_count(next_state, supply_id) <= 0:
		return _result(next_state, "rejected", "missing_recovery_supply", {"supply_id": supply_id})
	var removed_debuffs := active_debuff_summary(next_state)
	if removed_debuffs.is_empty():
		return _result(next_state, "rejected", "no_active_debuff", {"supply_id": supply_id})

	_consume_supply(next_state, supply_id, 1)
	next_state["active_debuffs"] = {}
	var party_effects: Dictionary = next_state.get("party_effects", {"hp_loss": 0, "debuffs": []})
	party_effects["debuffs"] = []
	next_state["party_effects"] = party_effects
	var target_effects: Dictionary = next_state.get("target_effects", {})
	for target_id in target_effects.keys():
		var target: Dictionary = target_effects.get(target_id, {})
		target["debuffs"] = {}
		target_effects[target_id] = target
	next_state["target_effects"] = target_effects

	var event := {
		"type": "recovery_supply_used",
		"supply_consumed": supply_id,
		"removed_debuffs": removed_debuffs,
		"message": "Recovery supplies remove active dungeon debuffs.",
	}
	next_state["hazard_log"].append(event)
	return _result(next_state, "accepted", "", event)


static func use_bandage(state: Dictionary, supply_id: String = "bandage") -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if supply_count(next_state, supply_id) <= 0:
		return _result(next_state, "rejected", "missing_bandage", {"supply_id": supply_id})
	var party_effects: Dictionary = next_state.get("party_effects", {"hp_loss": 0, "debuffs": []})
	var old_hp_loss := int(party_effects.get("hp_loss", 0))
	if old_hp_loss <= 0:
		return _result(next_state, "rejected", "no_hp_loss", {"supply_id": supply_id})

	_consume_supply(next_state, supply_id, 1)
	var hp_recovered := 1
	party_effects["hp_loss"] = max(0, old_hp_loss - hp_recovered)
	next_state["party_effects"] = party_effects
	_reduce_target_hp_loss(next_state, hp_recovered)

	var event := {
		"type": "bandage_used",
		"supply_consumed": supply_id,
		"hp_recovered": hp_recovered,
		"message": "Bandages patch up one point of expedition injury.",
	}
	next_state["hazard_log"].append(event)
	return _result(next_state, "accepted", "", event)


static func use_camp(state: Dictionary, supply_id: String = "camping_kit") -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if bool(next_state.get("completed", false)):
		return _result(next_state, "rejected", "run_completed", {"supply_id": supply_id})
	if not next_state.get("pending_combat_request", {}).is_empty():
		return _result(next_state, "rejected", "pending_combat", {"supply_id": supply_id})
	if not next_state.get("pending_corridor_hazard", {}).is_empty():
		return _result(next_state, "rejected", "corridor_hazard_pending", next_state["pending_corridor_hazard"])
	if not next_state.get("pending_room_event", {}).is_empty():
		return _result(next_state, "rejected", "room_event_pending", next_state["pending_room_event"])
	if supply_count(next_state, supply_id) <= 0:
		return _result(next_state, "rejected", "missing_camping_supply", {"supply_id": supply_id})
	if supply_count(next_state, "food") <= 0:
		return _result(next_state, "rejected", "missing_camp_food", {"supply_id": "food"})
	var party_effects: Dictionary = next_state.get("party_effects", {"hp_loss": 0, "debuffs": []})
	var old_hp_loss := int(party_effects.get("hp_loss", 0))
	var removed_debuffs := active_debuff_summary(next_state)
	if old_hp_loss <= 0 and removed_debuffs.is_empty():
		return _result(next_state, "rejected", "no_recovery_needed", {"supply_id": supply_id})

	_consume_supply(next_state, supply_id, 1)
	_consume_supply(next_state, "food", 1)
	var hp_recovered: int = mini(2, old_hp_loss)
	party_effects["hp_loss"] = max(0, old_hp_loss - hp_recovered)
	party_effects["debuffs"] = []
	next_state["party_effects"] = party_effects
	_reduce_target_hp_loss(next_state, hp_recovered)
	next_state["active_debuffs"] = {}
	var target_effects: Dictionary = next_state.get("target_effects", {})
	for target_id in target_effects.keys():
		var target: Dictionary = target_effects.get(target_id, {})
		target["debuffs"] = {}
		target_effects[target_id] = target
	next_state["target_effects"] = target_effects
	next_state["light_level"] = max(0, int(next_state.get("light_level", 0)) - 1)
	_refresh_light_state(next_state)
	next_state["camp_count"] = int(next_state.get("camp_count", 0)) + 1
	if not next_state.has("camp_log"):
		next_state["camp_log"] = []
	var event := {
		"type": "camp_used",
		"supply_consumed": supply_id,
		"food_consumed": 1,
		"hp_recovered": hp_recovered,
		"removed_debuffs": removed_debuffs,
		"light_level": int(next_state.get("light_level", 0)),
		"light_state": str(next_state.get("light_state", "")),
		"message": "The party makes camp, treats wounds, and loses time in the dark.",
	}
	next_state["camp_log"].append(event)
	next_state["hazard_log"].append(event)
	return _result(next_state, "accepted", "", event)


static func apply_combat_result(dungeon: Dictionary, state: Dictionary, result_payload: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if not next_state.get("pending_room_event", {}).is_empty():
		return _result(next_state, "rejected", "room_event_pending", next_state["pending_room_event"])
	var pending: Dictionary = next_state.get("pending_combat_request", {})
	if pending.is_empty():
		return _result(next_state, "rejected", "no_pending_combat", {})
	if str(result_payload.get("result", "")) == "in_progress":
		return _result(next_state, "rejected", "combat_still_in_progress", {})
	if str(result_payload.get("source_dungeon_id", "")) != str(pending.get("dungeon_id", "")):
		return _result(next_state, "rejected", "wrong_dungeon", {})
	if str(result_payload.get("source_room_id", "")) != str(pending.get("room_id", "")):
		return _result(next_state, "rejected", "wrong_room", {})
	if str(result_payload.get("result", "")) not in ["victory", "defeat"]:
		return _result(next_state, "rejected", "unsupported_combat_result", {})

	var room_id := str(pending.get("room_id", ""))
	_apply_returned_party_hp(next_state, result_payload)
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


static func _apply_returned_party_hp(state: Dictionary, payload: Dictionary) -> void:
	var survivors := {}
	for unit: Dictionary in payload.get("surviving_players", []):
		survivors[str(unit.get("id", ""))] = unit
	var targets: Dictionary = state.get("target_effects", {})
	for slot: Dictionary in state.get("party_formation", []):
		var unit_id := str(slot.get("combat_unit_id", ""))
		var hero := PartyRoster.hero_for_combat_unit(unit_id)
		if hero.is_empty():
			continue
		var fallen: bool = payload.get("defeated_player_ids", []).has(unit_id)
		if not survivors.has(unit_id) and not fallen:
			continue # Older result fixtures may omit party summaries.
		var max_hp := int(hero.get("stats", {}).get("max_hp", 1))
		var hp := 0 if fallen else clampi(int(survivors[unit_id].get("hp", max_hp)), 1, max_hp)
		var target_id := str(slot.get("target_id", ""))
		var target: Dictionary = targets.get(target_id, {"id": target_id, "debuffs": {}})
		target["hp_loss"] = max_hp - hp
		target["incapacitated"] = fallen
		targets[target_id] = target
	state["target_effects"] = targets
	var total := 0
	for target: Dictionary in targets.values():
		total += int(target.get("hp_loss", 0))
	state["party_effects"]["hp_loss"] = total


static func returned_party_effects(effects: Dictionary, payload: Dictionary) -> Dictionary:
	var next := effects.duplicate(true)
	next.party_formation = PartyRoster.default_party_formation()
	_apply_returned_party_hp(next, payload)
	for slot: Dictionary in next.party_formation:
		var target: Dictionary = next.target_effects.get(slot.target_id, {})
		if bool(target.get("incapacitated", false)):
			target.hp_loss = int(PartyRoster.hero_for_combat_unit(slot.combat_unit_id).stats.max_hp) - 1
			target.incapacitated = false
	var total := 0
	for target: Dictionary in next.target_effects.values():
		total += int(target.get("hp_loss", 0))
	next.party_effects.hp_loss = total
	next.erase("party_formation")
	return next


static func party_member_hp(state: Dictionary, unit_id: String) -> int:
	var hero := PartyRoster.hero_for_combat_unit(unit_id)
	var max_hp := int(hero.get("stats", {}).get("max_hp", 0))
	for slot: Dictionary in state.get("party_formation", []):
		if str(slot.get("combat_unit_id", "")) == unit_id:
			var effect: Dictionary = state.get("target_effects", {}).get(str(slot.get("target_id", "")), {})
			if bool(effect.get("incapacitated", false)):
				return 0
			return maxi(1, max_hp - int(effect.get("hp_loss", 0)))
	return max_hp


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


static func default_supply_loadout(dungeon: Dictionary) -> Dictionary:
	return clamp_supply_loadout(dungeon, _raw_default_supply_loadout(dungeon))


static func _raw_default_supply_loadout(dungeon: Dictionary) -> Dictionary:
	var options: Dictionary = dungeon.get("supply_loadout_options", {})
	if options.is_empty():
		return dungeon.get("starting_supplies", {"lamp_oil": 2, "pickaxe": 1}).duplicate(true)
	var loadout := {}
	for supply_id: String in options.keys():
		var option: Dictionary = options.get(supply_id, {})
		loadout[supply_id] = clampi(int(option.get("default", 0)), int(option.get("min", 0)), int(option.get("max", 0)))
	return loadout


static func clamp_supply_loadout(dungeon: Dictionary, selected_supply_loadout: Dictionary, preferred_supply_id: String = "") -> Dictionary:
	var options: Dictionary = dungeon.get("supply_loadout_options", {})
	if options.is_empty():
		var fallback: Dictionary = dungeon.get("starting_supplies", {"lamp_oil": 2, "pickaxe": 1}).duplicate(true)
		for supply_id: String in selected_supply_loadout.keys():
			fallback[supply_id] = max(0, int(selected_supply_loadout.get(supply_id, 0)))
		return fallback
	var loadout := _raw_default_supply_loadout(dungeon)
	for supply_id: String in options.keys():
		var option: Dictionary = options.get(supply_id, {})
		loadout[supply_id] = clampi(
			int(selected_supply_loadout.get(supply_id, loadout.get(supply_id, 0))),
			int(option.get("min", 0)),
			int(option.get("max", 0))
		)
	_enforce_supply_loadout_capacity(dungeon, loadout, preferred_supply_id)
	return loadout


static func supply_loadout_capacity(dungeon: Dictionary) -> int:
	return int(dungeon.get("supply_loadout_capacity", 0))


static func supply_packing_cost(dungeon: Dictionary, supply_id: String) -> int:
	var option: Dictionary = dungeon.get("supply_loadout_options", {}).get(supply_id, {})
	return max(0, int(option.get("packing_cost", 1)))


static func loadout_packing_summary(dungeon: Dictionary, loadout: Dictionary) -> Dictionary:
	var capacity: int = supply_loadout_capacity(dungeon)
	var used: int = 0
	for supply_id: String in loadout.keys():
		used += int(loadout.get(supply_id, 0)) * supply_packing_cost(dungeon, supply_id)
	return {
		"used": used,
		"capacity": capacity,
		"remaining": max(0, capacity - used) if capacity > 0 else 0,
		"over_capacity": capacity > 0 and used > capacity,
	}


static func generated_dungeon_profiles() -> Array[Dictionary]:
	return [
		{"id": "short_mine", "display_name": "Short Mine", "difficulty": 1, "theme": "mine", "length": "short", "max_light_level": 4, "supply_loadout_capacity": 6},
		{"id": "medium_mine", "display_name": "Medium Mine", "difficulty": 2, "theme": "mine", "length": "medium", "max_light_level": 4, "supply_loadout_capacity": 7},
		{"id": "deep_mine", "display_name": "Deep Mine", "difficulty": 3, "theme": "mine", "length": "deep", "max_light_level": 5, "supply_loadout_capacity": 9},
	]


static func generated_dungeon_profile(profile_id: String = "", difficulty: int = 2) -> Dictionary:
	var fallback: Dictionary = {}
	for profile: Dictionary in generated_dungeon_profiles():
		if str(profile.get("id", "")) == profile_id:
			return profile.duplicate(true)
		if int(profile.get("difficulty", 0)) == clampi(difficulty, 1, 3):
			fallback = profile
	if not fallback.is_empty():
		return fallback.duplicate(true)
	return generated_dungeon_profiles()[1].duplicate(true)


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


static func procedural_corridor_plan(corridor: Dictionary, profile: Dictionary) -> Dictionary:
	var corridor_id := str(corridor.get("id", ""))
	var plan := {
		"corridor_id": corridor_id,
		"hazard_pool_refs": [],
	}
	var pool := _select_event_pool_for_corridor(corridor, profile)
	if pool.is_empty():
		return plan
	var ref_id := str(profile.get("id", ""))
	if ref_id == "":
		ref_id = "%s_generated_hazard" % corridor_id
	var trigger: Dictionary = {"mode": str(profile.get("trigger_mode", "first_traversal"))}
	var profile_trigger: Variant = profile.get("trigger", {})
	if typeof(profile_trigger) == TYPE_DICTIONARY:
		var profile_trigger_dictionary: Dictionary = profile_trigger
		if not profile_trigger_dictionary.is_empty():
			trigger = profile_trigger_dictionary.duplicate(true)
	plan["hazard_pool_refs"].append({
		"id": ref_id,
		"pool_id": str(pool.get("id", "")),
		"trigger": trigger,
	})
	return plan


static func procedural_dungeon_draft(config: Dictionary = {}) -> Dictionary:
	var dungeon_id := str(config.get("id", "generated_old_mine_draft"))
	var seed := int(config.get("seed", config.get("hazard_seed", 31)))
	var profile := generated_dungeon_profile(str(config.get("profile_id", config.get("generated_profile", ""))), int(config.get("difficulty", 2)))
	var difficulty := clampi(int(config.get("difficulty", profile.get("difficulty", 2))), 1, 3)
	if config.has("profile_id") or config.has("generated_profile"):
		difficulty = clampi(int(profile.get("difficulty", difficulty)), 1, 3)
	var hazard_seed := int(config.get("hazard_seed", seed))
	var theme_tags: Array = config.get("theme_tags", ["mine", "corridor"])
	var combat_encounter_path := str(config.get("combat_encounter_path", ""))
	var generated_graph := _procedural_graph(seed, difficulty, profile, theme_tags, combat_encounter_path)
	if not GraphQuality.errors(generated_graph, str(profile.get("id", "")) == "deep_mine").is_empty():
		return {}
	var profile_label := str(profile.get("display_name", "Generated Mine"))
	var display_name := str(config.get("display_name", "%s D%s S%s" % [profile_label, difficulty, seed]))
	return {
		"id": dungeon_id,
		"display_name": display_name,
		"recommended_party_level": int(config.get("recommended_party_level", 1)),
		"start_room_id": "generated_entrance",
		"max_light_level": int(config.get("max_light_level", profile.get("max_light_level", 4))),
		"hazard_seed": hazard_seed,
		"template_id": str(generated_graph.get("template_id", "")),
		"template_display_name": str(generated_graph.get("display_name", "")),
		"template_pacing": generated_graph.get("pacing", {}).duplicate(true),
		"generated_profile": {
			"id": str(profile.get("id", "medium_mine")),
			"display_name": profile_label,
			"difficulty": difficulty,
			"theme": str(profile.get("theme", "mine")),
			"length": str(profile.get("length", "medium")),
		},
		"starting_supplies": {
			"lamp_oil": 2,
			"pickaxe": 1,
			"bandage": 1,
			"trap_tools": 1,
			"food": 1,
			"camping_kit": 0,
		},
		"supply_loadout_capacity": int(config.get("supply_loadout_capacity", profile.get("supply_loadout_capacity", 8))),
		"supply_loadout_options": {
			"lamp_oil": {"min": 0, "max": 5, "default": 2, "packing_cost": 1, "label": "Torch"},
			"pickaxe": {"min": 0, "max": 2, "default": 1, "packing_cost": 2, "label": "Pickaxe"},
			"bandage": {"min": 0, "max": 3, "default": 1, "packing_cost": 1, "label": "Bandage"},
			"trap_tools": {"min": 0, "max": 3, "default": 1, "packing_cost": 1, "label": "Trap Tools"},
			"food": {"min": 0, "max": 3, "default": 1, "packing_cost": 1, "label": "Food"},
			"camping_kit": {"min": 0, "max": 1, "default": 0, "packing_cost": 3, "label": "Camping Kit"},
		},
		"default_party_formation": _default_party_formation({}),
		"rooms": generated_graph["rooms"],
		"corridors": generated_graph["corridors"],
		"exit_rules": {
			"allow_retreat": true,
			"boss_required": false,
		},
	}


static func _evaluate_room_entry(dungeon: Dictionary, state: Dictionary, room_id: String) -> void:
	state["pending_combat_request"] = {}
	state["pending_room_event"] = {}
	var room := _room_by_id(dungeon, room_id)
	if room.is_empty():
		return

	var content: Array = room.get("content", [])
	var room_event := _first_pending_room_event_content(room_id, content, state)
	if not room_event.is_empty():
		state["pending_room_event"] = _room_event_prompt(state, room_id, room_event)
		return

	if _content_has_pending_combat(state, room_id, content):
		var combat_content := _first_combat_content(content)
		state["pending_combat_request"] = {
			"dungeon_id": str(dungeon.get("id", "")),
			"room_id": room_id,
			"content_type": str(combat_content.get("type", "")),
			"combat_encounter_path": str(combat_content.get("combat_encounter_path", "")),
			"combat_encounter_pool_id": str(combat_content.get("combat_encounter_pool_id", "")),
			"combat_encounter_selection": combat_content.get("combat_encounter_selection", {}).duplicate(true),
			"exploration_modifiers": state.get("exploration_modifiers", {}).duplicate(true),
			"dungeon_modifiers": _combat_modifiers_for_state(state),
		}
		return

	if _content_is_empty(content):
		_add_unique(state["cleared_room_ids"], room_id)


static func _first_pending_room_event_content(room_id: String, content: Array, state: Dictionary) -> Dictionary:
	for item: Dictionary in content:
		if str(item.get("type", "")) != "room_event":
			continue
		var event_id := str(item.get("id", ""))
		if event_id == "":
			event_id = "%s_%s" % [room_id, str(item.get("event_id", item.get("room_event_pool_id", "room_event")))]
		if state.get("resolved_room_event_ids", []).has(event_id):
			continue
		var event := _materialize_room_event(room_id, item)
		if event.is_empty():
			continue
		event["id"] = event_id
		event["room_id"] = room_id
		return event
	return {}


static func _room_event_prompt(state: Dictionary, room_id: String, event: Dictionary) -> Dictionary:
	var choices: Array[Dictionary] = []
	for choice: Dictionary in event.get("choices", []):
		var choice_id := str(choice.get("id", ""))
		var required_supply_id := str(choice.get("requires_supply", ""))
		choices.append({
			"id": choice_id,
			"label": str(choice.get("label", choice_id)),
			"requires_supply": required_supply_id,
			"available": required_supply_id == "" or supply_count(state, required_supply_id) > 0,
		})
	return {
		"type": "room_event_choice_required",
		"room_event_id": str(event.get("id", "")),
		"event_id": str(event.get("event_id", "")),
		"pool_id": str(event.get("pool_id", "")),
		"event_type": str(event.get("type", "")),
		"room_id": room_id,
		"choices": choices,
		"message": str(event.get("message", "")),
		"event": event.duplicate(true),
	}


static func _room_event_choice_is_available(prompt: Dictionary, choice_id: String) -> bool:
	for choice: Dictionary in prompt.get("choices", []):
		if str(choice.get("id", "")) == choice_id:
			return bool(choice.get("available", false))
	return false


static func _room_event_from_pending(pending: Dictionary) -> Dictionary:
	var event: Dictionary = pending.get("event", {})
	return event.duplicate(true)


static func _select_room_event_outcome(state: Dictionary, event: Dictionary, choice_id: String) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for outcome: Dictionary in event.get("outcomes", []):
		var when: Dictionary = outcome.get("when", {})
		if str(when.get("choice_id", choice_id)) == choice_id:
			candidates.append(outcome)
	if candidates.is_empty():
		return {}
	if candidates.size() == 1:
		return candidates[0]
	var total_weight := 0
	for candidate: Dictionary in candidates:
		total_weight += max(1, int(candidate.get("weight", 1)))
	var roll := _deterministic_roll(state, str(event.get("id", "")), total_weight)
	var cursor := 0
	for candidate: Dictionary in candidates:
		cursor += max(1, int(candidate.get("weight", 1)))
		if roll < cursor:
			return candidate
	return candidates[candidates.size() - 1]


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


static func _room_can_clear_after_room_event(state: Dictionary, room: Dictionary) -> bool:
	if room.is_empty():
		return false
	var room_id := str(room.get("id", ""))
	if room_is_cleared(state, room_id):
		return false
	for item: Dictionary in room.get("content", []):
		var content_type := str(item.get("type", ""))
		if content_type == "empty":
			continue
		if content_type == "room_event":
			var event_id := str(item.get("id", ""))
			if event_id == "":
				event_id = "%s_%s" % [room_id, str(item.get("event_id", item.get("room_event_pool_id", "room_event")))]
			if state.get("resolved_room_event_ids", []).has(event_id):
				continue
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


static func _apply_reward_to_run_inventory(state: Dictionary, reward_record: Dictionary) -> void:
	if not state.has("run_inventory"):
		state["run_inventory"] = _empty_run_inventory()
	var inventory: Dictionary = state["run_inventory"]
	if not inventory.has("items"):
		inventory["items"] = []
	if not inventory.has("reward_records"):
		inventory["reward_records"] = []
	var reward_payload: Dictionary = reward_record.get("rewards", {})
	inventory["xp"] = int(inventory.get("xp", 0)) + int(reward_payload.get("xp", 0))
	inventory["gold"] = int(inventory.get("gold", 0)) + int(reward_payload.get("gold", 0))
	for item_id: String in reward_payload.get("items", []):
		inventory["items"].append(item_id)
	inventory["reward_records"].append(reward_record.duplicate(true))
	state["run_inventory"] = inventory
	state["reward_totals"] = {
		"xp": int(inventory.get("xp", 0)),
		"gold": int(inventory.get("gold", 0)),
		"items": inventory.get("items", []).duplicate(true),
	}


static func _empty_run_inventory() -> Dictionary:
	return {
		"xp": 0,
		"gold": 0,
		"items": [],
		"reward_records": [],
	}


static func _kept_rewards_for_outcome(inventory: Dictionary, outcome: String) -> Dictionary:
	if outcome == "failed":
		return _empty_run_inventory()
	return inventory.duplicate(true)


static func _lost_rewards_for_outcome(inventory: Dictionary, outcome: String) -> Dictionary:
	if outcome == "failed":
		return inventory.duplicate(true)
	return _empty_run_inventory()


static func _empty_room_event_history() -> Dictionary:
	return {
		"resolved_count": 0,
		"event_ids": [],
		"type_counts": {},
		"tag_counts": {},
		"tone_counts": {},
	}


static func _record_room_event_history(state: Dictionary, room_event: Dictionary) -> void:
	if not state.has("room_event_history"):
		state["room_event_history"] = _empty_room_event_history()
	var history: Dictionary = state["room_event_history"]
	if not history.has("event_ids"):
		history["event_ids"] = []
	if not history.has("type_counts"):
		history["type_counts"] = {}
	if not history.has("tag_counts"):
		history["tag_counts"] = {}
	if not history.has("tone_counts"):
		history["tone_counts"] = {}
	history["resolved_count"] = int(history.get("resolved_count", 0)) + 1
	var event_id := str(room_event.get("event_id", ""))
	if event_id != "":
		history["event_ids"].append(event_id)
	var event_type := str(room_event.get("event_type", "generic"))
	var type_counts: Dictionary = history["type_counts"]
	type_counts[event_type] = int(type_counts.get(event_type, 0)) + 1
	history["type_counts"] = type_counts
	var tag_counts: Dictionary = history["tag_counts"]
	for tag: String in room_event.get("tags", []):
		tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1
	history["tag_counts"] = tag_counts
	var outcome_tone := str(room_event.get("outcome_tone", "neutral"))
	var tone_counts: Dictionary = history["tone_counts"]
	tone_counts[outcome_tone] = int(tone_counts.get(outcome_tone, 0)) + 1
	history["tone_counts"] = tone_counts
	state["room_event_history"] = history


static func _room_is_locked_for_state(state: Dictionary, room: Dictionary) -> bool:
	var required_item_id := str(room.get("locked_by_item_id", ""))
	if required_item_id == "":
		return false
	if room_is_unlocked(state, str(room.get("id", ""))):
		return false
	var totals := reward_totals(state)
	return not totals.get("items", []).has(required_item_id)


static func _first_pending_corridor_hazard(state: Dictionary, corridor: Dictionary) -> Dictionary:
	for hazard: Dictionary in _corridor_hazards(corridor):
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
		"event_id": str(hazard.get("event_id", "")),
		"pool_id": str(hazard.get("pool_id", "")),
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
	for hazard: Dictionary in _corridor_hazards(corridor):
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
		supply_consumed = required_supply_id
		consequences.append({"type": "consume_supply", "supply_id": required_supply_id, "amount": 1})
	_apply_consequences(state, consequences)
	return {
		"type": "corridor_hazard_resolved",
		"hazard_id": str(hazard.get("id", "")),
		"event_id": str(hazard.get("event_id", "")),
		"pool_id": str(hazard.get("pool_id", "")),
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
			"reward":
				var reward_record := {
					"room_id": str(state.get("current_room_id", "")),
					"content_type": "room_event",
					"rewards": consequence.get("rewards", {"xp": 0, "gold": 0, "items": []}),
				}
				state["claimed_rewards"].append(reward_record)
				_apply_reward_to_run_inventory(state, reward_record)
			"consume_supply":
				_consume_supply(state, str(consequence.get("supply_id", "")), int(consequence.get("amount", 1)))
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


static func _enforce_supply_loadout_capacity(dungeon: Dictionary, loadout: Dictionary, preferred_supply_id: String) -> void:
	var capacity := supply_loadout_capacity(dungeon)
	if capacity <= 0:
		return
	var options: Dictionary = dungeon.get("supply_loadout_options", {})
	var ids: Array[String] = []
	for supply_id: String in options.keys():
		ids.append(supply_id)
	ids.sort()
	var reduction_order: Array[String] = []
	for supply_id: String in ids:
		if supply_id != preferred_supply_id:
			reduction_order.append(supply_id)
	if preferred_supply_id != "":
		reduction_order.append(preferred_supply_id)
	var guard := 0
	while bool(loadout_packing_summary(dungeon, loadout).get("over_capacity", false)) and guard < 1000:
		var reduced := false
		for supply_id: String in reduction_order:
			var option: Dictionary = options.get(supply_id, {})
			var minimum := int(option.get("min", 0))
			if int(loadout.get(supply_id, 0)) > minimum:
				loadout[supply_id] = int(loadout.get(supply_id, 0)) - 1
				reduced = true
				break
		if not reduced:
			return
		guard += 1


static func _reduce_target_hp_loss(state: Dictionary, amount: int) -> void:
	var remaining: int = max(0, amount)
	if remaining <= 0:
		return
	var target_effects: Dictionary = state.get("target_effects", {})
	var target_ids: Array = target_effects.keys()
	target_ids.sort()
	for target_id: String in target_ids:
		if remaining <= 0:
			break
		var target: Dictionary = target_effects.get(target_id, {})
		var current: int = int(target.get("hp_loss", 0))
		var recovered: int = mini(current, remaining)
		target["hp_loss"] = max(0, current - recovered)
		if recovered > 0:
			target["incapacitated"] = false
		target_effects[target_id] = target
		remaining -= recovered
	state["target_effects"] = target_effects


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
	var target_id := str(consequence.get("target_id", "party_slot_front"))
	if target_id == "":
		return "party_slot_front"
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
		"party_formation": state.get("party_formation", []).duplicate(true),
	}


static func _default_party_formation(dungeon: Dictionary) -> Array:
	var formation: Array = dungeon.get("default_party_formation", []).duplicate(true)
	if not formation.is_empty():
		return formation
	return PartyRoster.default_party_formation()


static func _supplies_for_loadout(dungeon: Dictionary, selected_supply_loadout: Dictionary) -> Dictionary:
	if selected_supply_loadout.is_empty():
		return default_supply_loadout(dungeon)
	return clamp_supply_loadout(dungeon, selected_supply_loadout)


static func _hazard_already_resolved(state: Dictionary, hazard: Dictionary) -> bool:
	var trigger: Dictionary = hazard.get("trigger", {})
	if str(trigger.get("mode", "first_traversal")) != "first_traversal":
		return false
	return state.get("resolved_hazard_ids", []).has(str(hazard.get("id", "")))


static func _hazard_by_id(corridor: Dictionary, hazard_id: String) -> Dictionary:
	for hazard: Dictionary in _corridor_hazards(corridor):
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}


static func _corridor_hazards(corridor: Dictionary) -> Array[Dictionary]:
	var hazards: Array[Dictionary] = []
	for hazard: Dictionary in corridor.get("hazards", []):
		hazards.append(hazard.duplicate(true))
	for hazard_ref: Dictionary in corridor.get("hazard_refs", []):
		var hazard := _materialize_hazard_ref(hazard_ref)
		if not hazard.is_empty():
			hazards.append(hazard)
	for hazard_pool_ref: Dictionary in corridor.get("hazard_pool_refs", []):
		var hazard := _materialize_hazard_pool_ref(corridor, hazard_pool_ref)
		if not hazard.is_empty():
			hazards.append(hazard)
	return hazards


static func _materialize_hazard_ref(hazard_ref: Dictionary) -> Dictionary:
	var template := _dungeon_event_template(str(hazard_ref.get("event_id", "")))
	if template.is_empty():
		return {}
	var hazard := template.duplicate(true)
	hazard["id"] = str(hazard_ref.get("id", template.get("id", "")))
	hazard["event_id"] = str(template.get("id", ""))
	hazard["trigger"] = hazard_ref.get("trigger", {"mode": "first_traversal"}).duplicate(true)
	return hazard


static func _materialize_hazard_pool_ref(corridor: Dictionary, hazard_pool_ref: Dictionary) -> Dictionary:
	var pool := _dungeon_event_pool(str(hazard_pool_ref.get("pool_id", "")))
	if pool.is_empty():
		return {}
	var event_id := _select_event_id_from_pool(corridor, hazard_pool_ref, pool)
	if event_id == "":
		return {}
	var hazard := _materialize_hazard_ref({
		"id": str(hazard_pool_ref.get("id", event_id)),
		"event_id": event_id,
		"trigger": hazard_pool_ref.get("trigger", {"mode": "first_traversal"}),
	})
	if not hazard.is_empty():
		hazard["pool_id"] = str(pool.get("id", ""))
	return hazard


static func _select_event_id_from_pool(corridor: Dictionary, hazard_pool_ref: Dictionary, pool: Dictionary) -> String:
	var entries: Array = pool.get("entries", [])
	if entries.is_empty():
		return ""
	var total_weight := 0
	for entry: Dictionary in entries:
		total_weight += max(1, int(entry.get("weight", 1)))
	var roll := _pool_roll(str(corridor.get("id", "")), str(hazard_pool_ref.get("id", "")), total_weight)
	var cursor := 0
	for entry: Dictionary in entries:
		cursor += max(1, int(entry.get("weight", 1)))
		if roll < cursor:
			return str(entry.get("event_id", ""))
	return str(entries[entries.size() - 1].get("event_id", ""))


static func _pool_roll(corridor_id: String, hazard_ref_id: String, modulo: int) -> int:
	if modulo <= 0:
		return 0
	var value := 146959810
	var key := "%s:%s" % [corridor_id, hazard_ref_id]
	for index in range(key.length()):
		value += key.unicode_at(index) * (index + 31)
	return abs(value) % modulo


static func _select_event_pool_for_corridor(corridor: Dictionary, profile: Dictionary) -> Dictionary:
	var required_tags: Array = profile.get("required_tags", [])
	var danger := float(corridor.get("danger", 0.0))
	var matches: Array[Dictionary] = []
	for pool: Dictionary in _all_dungeon_event_pools():
		if _pool_matches_corridor(pool, required_tags, danger):
			matches.append(pool)
	if matches.is_empty():
		return {}
	var profile_id := str(profile.get("id", "procedural_pool"))
	var selected_index := _pool_roll(str(corridor.get("id", "")), profile_id, matches.size())
	return matches[selected_index]


static func _pool_matches_corridor(pool: Dictionary, required_tags: Array, danger: float) -> bool:
	var pool_tags: Array = pool.get("tags", [])
	for tag in required_tags:
		if not pool_tags.has(str(tag)):
			return false
	var danger_min := float(pool.get("danger_min", 0.0))
	var danger_max := float(pool.get("danger_max", 1.0))
	return danger >= danger_min and danger <= danger_max


static func _procedural_graph(seed: int, difficulty: int, profile: Dictionary, theme_tags: Array, combat_encounter_path: String) -> Dictionary:
	var template := _select_dungeon_template(seed, difficulty, str(profile.get("id", "")))
	if template.is_empty():
		return {"rooms": [], "corridors": []}
	var rooms: Array = template.get("rooms", []).duplicate(true)
	_apply_generated_room_events(seed, rooms)
	var selected_hazard_pool_ids := _selected_template_hazard_pool_ids(seed, template)
	var corridors: Array[Dictionary] = []
	for template_corridor: Dictionary in template.get("corridors", []):
		var corridor := template_corridor.duplicate(true)
		var hazard_profile := str(corridor.get("hazard_profile", "none"))
		corridor.erase("hazard_profile")
		var corridor_id := str(corridor.get("id", ""))
		if hazard_profile == "planned" and selected_hazard_pool_ids.has(corridor_id):
			corridor["hazard_pool_refs"] = [{
				"id": "%s_generated_hazard" % corridor_id,
				"pool_id": str(selected_hazard_pool_ids.get(corridor_id, "")),
				"trigger": {"mode": "first_traversal"},
			}]
		corridors.append(corridor)
	_apply_template_combat_paths(seed, profile, rooms, combat_encounter_path)
	return {
		"rooms": rooms,
		"corridors": corridors,
		"template_id": str(template.get("id", "")),
		"display_name": str(template.get("display_name", "Generated Old Mine")),
		"pacing": template.get("pacing", {}).duplicate(true),
	}


static func _selected_template_hazard_pool_ids(seed: int, template: Dictionary) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for corridor: Dictionary in template.get("corridors", []):
		if str(corridor.get("hazard_profile", "none")) != "planned":
			continue
		candidates.append(corridor)
	var selected := {}
	if candidates.is_empty():
		return selected
	var first_index := _seeded_int(seed, "hazard_slot_a", 0, candidates.size() - 1)
	var first_id := str(candidates[first_index].get("id", ""))
	var second_id := ""
	if candidates.size() > 1:
		var remaining: Array[Dictionary] = []
		for index in range(candidates.size()):
			if index != first_index:
				remaining.append(candidates[index])
		var second_index := _seeded_int(seed, "hazard_slot_b", 0, remaining.size() - 1)
		second_id = str(remaining[second_index].get("id", ""))
	var pool_order := ["old_mine_rubble_pool", "old_mine_trap_pool"]
	if _seeded_int(seed, "hazard_pool_order", 0, 1) == 1:
		pool_order.reverse()
	if first_id != "":
		selected[first_id] = pool_order[0]
	if second_id != "":
		selected[second_id] = pool_order[1]
	return selected


static func _select_dungeon_template(seed: int, difficulty: int, profile_id: String = "") -> Dictionary:
	return select_accepted_template(seed, difficulty, profile_id, _all_dungeon_templates())


static func select_accepted_template(seed: int, difficulty: int, profile_id: String, templates: Array) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for template: Dictionary in templates:
		if template.get("acceptance_state", "candidate") != "accepted":
			continue
		if profile_id != "" and not template.get("profile_ids", []).has(profile_id):
			continue
		if int(template.get("difficulty", 1)) == difficulty:
			candidates.append(template)
	if candidates.is_empty():
		for template: Dictionary in templates:
			if template.get("acceptance_state", "candidate") != "accepted":
				continue
			if profile_id != "" and not template.get("profile_ids", []).has(profile_id):
				continue
			if int(template.get("difficulty", 1)) <= difficulty:
				candidates.append(template)
	if candidates.is_empty():
		return {}
	var selected_index := _seeded_int(seed, "template", 0, candidates.size() - 1)
	return candidates[selected_index].duplicate(true)


static func _all_dungeon_templates() -> Array[Dictionary]:
	var templates: Array[Dictionary] = []
	for template_path: String in _dungeon_template_paths():
		var catalogue := _load_json_dictionary(template_path)
		for template: Dictionary in catalogue.get("templates", []):
			templates.append(template)
	return templates


static func _dungeon_template_paths() -> Array[String]:
	return [
		"res://resources/data/dungeon_templates/generated_old_mine_templates.json",
	]


static func _apply_template_combat_paths(seed: int, profile: Dictionary, rooms: Array, combat_encounter_path: String) -> void:
	var used_paths_by_pool := {}
	var combat_slot_index := 0
	for room: Dictionary in rooms:
		for content: Dictionary in room.get("content", []):
			if not (str(content.get("type", "")) in ["combat", "guarded_treasure"]):
				continue
			if combat_encounter_path != "":
				content["combat_encounter_path"] = combat_encounter_path
				combat_slot_index += 1
				continue
			if str(content.get("combat_encounter_path", "")) != "":
				combat_slot_index += 1
				continue
			var pool_id := str(content.get("combat_encounter_pool_id", ""))
			if pool_id != "" and not used_paths_by_pool.has(pool_id):
				used_paths_by_pool[pool_id] = []
			var used_paths: Array = used_paths_by_pool.get(pool_id, [])
			var selected_entry := _select_combat_encounter_entry(seed, room, content, profile, used_paths, combat_slot_index)
			if not selected_entry.is_empty():
				var selected_path := str(selected_entry.get("encounter_path", ""))
				content["combat_encounter_path"] = str(selected_entry.get("encounter_path", ""))
				content["combat_encounter_selection"] = {
					"pool_id": str(content.get("combat_encounter_pool_id", "")),
					"entry_id": str(selected_entry.get("id", "")),
					"tactical_role": str(selected_entry.get("tactical_role", "")),
				}
				if pool_id != "" and selected_path != "" and not used_paths.has(selected_path):
					used_paths.append(selected_path)
					used_paths_by_pool[pool_id] = used_paths
				combat_slot_index += 1
				continue
			content["combat_encounter_path"] = "res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json"
			combat_slot_index += 1


static func _select_combat_encounter_entry(seed: int, room: Dictionary, content: Dictionary, profile: Dictionary, used_paths: Array = [], combat_slot_index: int = 0) -> Dictionary:
	var candidates := _combat_encounter_candidates(content, profile)
	if candidates.is_empty():
		return {}
	var fresh_candidates: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		if not used_paths.has(str(candidate.get("encounter_path", ""))):
			fresh_candidates.append(candidate)
	if not fresh_candidates.is_empty():
		candidates = fresh_candidates
	var selected_index := absi(seed + combat_slot_index) % candidates.size()
	return candidates[selected_index]


static func _combat_encounter_candidates(content: Dictionary, profile: Dictionary) -> Array[Dictionary]:
	var pool_id := str(content.get("combat_encounter_pool_id", ""))
	if pool_id == "":
		return []
	var pool := _dungeon_combat_encounter_pool(pool_id)
	if pool.is_empty():
		return []
	var profile_id := str(profile.get("id", ""))
	var difficulty := int(profile.get("difficulty", 1))
	var theme := str(profile.get("theme", ""))
	if str(pool.get("theme", theme)) != theme:
		return []
	var room_kind := str(content.get("type", "combat"))
	var candidates: Array[Dictionary] = []
	for entry: Dictionary in pool.get("entries", []):
		if not entry.get("profile_ids", []).has(profile_id):
			continue
		if difficulty < int(entry.get("difficulty_min", 1)) or difficulty > int(entry.get("difficulty_max", 3)):
			continue
		if not entry.get("room_kinds", []).has(room_kind):
			continue
		candidates.append(entry)
	if candidates.is_empty() and str(pool.get("theme", "")) == theme:
		for entry: Dictionary in pool.get("entries", []):
			if entry.get("room_kinds", []).has(room_kind):
				candidates.append(entry)
	return _unique_combat_encounter_path_candidates(candidates)


static func _unique_combat_encounter_path_candidates(candidates: Array[Dictionary]) -> Array[Dictionary]:
	var unique: Array[Dictionary] = []
	var seen_paths: Array[String] = []
	for candidate: Dictionary in candidates:
		var path := str(candidate.get("encounter_path", ""))
		if seen_paths.has(path):
			continue
		seen_paths.append(path)
		unique.append(candidate)
	return unique


static func _apply_generated_room_events(seed: int, rooms: Array) -> void:
	var candidates: Array[Dictionary] = []
	for room: Dictionary in rooms:
		if str(room.get("kind", "")) in ["entrance", "exit", "combat", "guarded_treasure"]:
			continue
		candidates.append(room)
	if candidates.is_empty():
		return
	var event_count := mini(2, candidates.size())
	var used_indices: Array[int] = []
	for slot in range(event_count):
		var index := _seeded_int(seed, "room_event_slot_%s" % slot, 0, candidates.size() - 1)
		var guard := 0
		while used_indices.has(index) and guard < candidates.size():
			index = (index + 1) % candidates.size()
			guard += 1
		used_indices.append(index)
		var room: Dictionary = candidates[index]
		var content: Array = room.get("content", [])
		content.append({
			"type": "room_event",
			"id": "%s_generated_room_event" % str(room.get("id", "")),
			"room_event_pool_id": "old_mine_room_event_pool",
		})
		room["content"] = content


static func _materialize_room_event(room_id: String, content: Dictionary) -> Dictionary:
	if content.has("event_id"):
		var event := _dungeon_room_event_template(str(content.get("event_id", ""))).duplicate(true)
		if event.is_empty():
			return {}
		event["event_id"] = str(content.get("event_id", ""))
		return event
	if content.has("room_event_pool_id"):
		var pool := _dungeon_room_event_pool(str(content.get("room_event_pool_id", "")))
		if pool.is_empty():
			return {}
		var event_id := _select_room_event_id_from_pool(room_id, str(content.get("id", "")), pool)
		var event := _dungeon_room_event_template(event_id).duplicate(true)
		if event.is_empty():
			return {}
		event["event_id"] = event_id
		event["pool_id"] = str(pool.get("id", ""))
		return event
	return {}


static func _select_room_event_id_from_pool(room_id: String, ref_id: String, pool: Dictionary) -> String:
	var entries: Array = pool.get("entries", [])
	if entries.is_empty():
		return ""
	var total_weight := 0
	for entry: Dictionary in entries:
		total_weight += max(1, int(entry.get("weight", 1)))
	var roll := _pool_roll(room_id, ref_id, total_weight)
	var cursor := 0
	for entry: Dictionary in entries:
		cursor += max(1, int(entry.get("weight", 1)))
		if roll < cursor:
			return str(entry.get("event_id", ""))
	return str(entries[entries.size() - 1].get("event_id", ""))


static func _seeded_int(seed: int, salt: String, minimum: int, maximum: int) -> int:
	if maximum <= minimum:
		return minimum
	var value: int = abs(seed) + 146959810
	for index in range(salt.length()):
		value += salt.unicode_at(index) * (index + 31)
	return minimum + abs(value) % (maximum - minimum + 1)


static func _corridor_with_plan(corridor_id: String, from_room_id: String, to_room_id: String, danger: float, theme_tags: Array) -> Dictionary:
	var corridor := {
		"id": corridor_id,
		"from": from_room_id,
		"to": to_room_id,
		"danger": danger,
		"light_decay": 1,
	}
	var plan := procedural_corridor_plan(corridor, {
		"id": "%s_generated_hazard" % corridor_id,
		"required_tags": theme_tags,
	})
	if not plan.get("hazard_pool_refs", []).is_empty():
		corridor["hazard_pool_refs"] = plan["hazard_pool_refs"]
	return corridor


static func _dungeon_event_template(event_id: String) -> Dictionary:
	if event_id == "":
		return {}
	for catalogue_path: String in _dungeon_event_catalogue_paths():
		var catalogue := _load_json_dictionary(catalogue_path)
		for event: Dictionary in catalogue.get("events", []):
			if str(event.get("id", "")) == event_id:
				return event
	return {}


static func _dungeon_event_catalogue_paths() -> Array[String]:
	return [
		"res://resources/data/dungeon_events/base_corridor_hazards.json",
	]


static func _dungeon_event_pool(pool_id: String) -> Dictionary:
	if pool_id == "":
		return {}
	for pool: Dictionary in _all_dungeon_event_pools():
		if str(pool.get("id", "")) == pool_id:
			return pool
	return {}


static func _all_dungeon_event_pools() -> Array[Dictionary]:
	var pools: Array[Dictionary] = []
	for pool_path: String in _dungeon_event_pool_paths():
		var catalogue := _load_json_dictionary(pool_path)
		for pool: Dictionary in catalogue.get("pools", []):
			pools.append(pool)
	return pools


static func _dungeon_event_pool_paths() -> Array[String]:
	return [
		"res://resources/data/dungeon_event_pools/base_old_mine_pools.json",
	]


static func _dungeon_room_event_template(event_id: String) -> Dictionary:
	if event_id == "":
		return {}
	for catalogue_path: String in _dungeon_room_event_catalogue_paths():
		var catalogue := _load_json_dictionary(catalogue_path)
		for event: Dictionary in catalogue.get("events", []):
			if str(event.get("id", "")) == event_id:
				return event
	return {}


static func _dungeon_room_event_catalogue_paths() -> Array[String]:
	return [
		"res://resources/data/dungeon_room_events/base_old_mine_room_events.json",
	]


static func _dungeon_room_event_pool(pool_id: String) -> Dictionary:
	if pool_id == "":
		return {}
	for pool: Dictionary in _all_dungeon_room_event_pools():
		if str(pool.get("id", "")) == pool_id:
			return pool
	return {}


static func _all_dungeon_room_event_pools() -> Array[Dictionary]:
	var pools: Array[Dictionary] = []
	for pool_path: String in _dungeon_room_event_pool_paths():
		var catalogue := _load_json_dictionary(pool_path)
		for pool: Dictionary in catalogue.get("pools", []):
			pools.append(pool)
	return pools


static func _dungeon_room_event_pool_paths() -> Array[String]:
	return [
		"res://resources/data/dungeon_room_event_pools/base_old_mine_room_event_pools.json",
	]


static func _dungeon_combat_encounter_pool(pool_id: String) -> Dictionary:
	if pool_id == "":
		return {}
	for pool: Dictionary in _all_dungeon_combat_encounter_pools():
		if str(pool.get("id", "")) == pool_id:
			return pool
	return {}


static func _all_dungeon_combat_encounter_pools() -> Array[Dictionary]:
	var pools: Array[Dictionary] = []
	for pool_path: String in _dungeon_combat_encounter_pool_paths():
		var catalogue := _load_json_dictionary(pool_path)
		for pool: Dictionary in catalogue.get("pools", []):
			pools.append(pool)
	return pools


static func _dungeon_combat_encounter_pool_paths() -> Array[String]:
	return [
		"res://resources/data/dungeon_combat_encounter_pools/old_mine_combat_pools.json",
	]


static func _load_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


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
