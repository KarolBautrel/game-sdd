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
	_expect_equal(errors, "initial light full", state["light_level"], 4)
	_expect_equal(errors, "initial light bright", state["light_state"], "bright")
	_expect_equal(errors, "initial oil supply", DungeonStateModel.supply_count(state, "lamp_oil"), 2)
	_expect_equal(errors, "initial pickaxe supply", DungeonStateModel.supply_count(state, "pickaxe"), 1)
	_expect_equal(errors, "initial trap tools supply", DungeonStateModel.supply_count(state, "trap_tools"), 1)

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
	_expect_equal(errors, "crossing traversal light decayed", state["light_level"], 3)
	_expect_equal(errors, "crossing traversal light still bright", state["light_state"], "bright")
	_expect_equal(errors, "crossing traversal event type", crossing_result["event"]["traversal_events"][0]["type"], "light_changed")

	var treasure_result: Dictionary = DungeonStateModel.enter_room(dungeon, state, "collapsed_cache")
	_expect_equal(errors, "treasure corridor hazard requires choice", treasure_result["status"], "choice_required")
	_expect_equal(errors, "treasure corridor hazard reason", treasure_result["rejection"], "corridor_hazard_pending")
	_expect_equal(errors, "treasure corridor hazard target", treasure_result["event"]["to_room_id"], "collapsed_cache")
	_expect_equal(errors, "treasure corridor hazard type", treasure_result["event"]["hazard_type"], "rubble")
	_expect_true(errors, "treasure corridor hazard use pickaxe available", treasure_result["event"]["choices"][0]["available"])
	_expect_equal(errors, "treasure stays in crossing before choice", treasure_result["state"]["current_room_id"], "dusty_crossing")
	treasure_result = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, treasure_result["state"], "use_supply")
	_expect_equal(errors, "treasure room accepted after hazard choice", treasure_result["status"], "accepted")
	var treasure_state: Dictionary = treasure_result["state"]
	_expect_equal(errors, "treasure current room", treasure_state["current_room_id"], "collapsed_cache")
	_expect_true(errors, "treasure visited", DungeonStateModel.room_is_visited(treasure_state, "collapsed_cache"))
	_expect_false(errors, "treasure not auto cleared", DungeonStateModel.room_is_cleared(treasure_state, "collapsed_cache"))
	_expect_true(errors, "treasure has no pending combat", treasure_state["pending_combat_request"].is_empty())
	_expect_equal(errors, "treasure traversal light dim", treasure_state["light_level"], 2)
	_expect_equal(errors, "treasure traversal light state dim", treasure_state["light_state"], "dim")
	_expect_equal(errors, "rubble hazard resolved", treasure_result["event"]["traversal_events"][1]["type"], "corridor_hazard_resolved")
	_expect_equal(errors, "rubble hazard outcome", treasure_result["event"]["traversal_events"][1]["outcome_id"], "cleared_with_pickaxe")
	_expect_equal(errors, "rubble consumes pickaxe", DungeonStateModel.supply_count(treasure_state, "pickaxe"), 0)
	_expect_true(errors, "rubble marked resolved", treasure_state["resolved_hazard_ids"].has("rubble_crossing_cache"))
	var treasure_content: Array = DungeonStateModel.current_room_content(dungeon, treasure_state)
	_expect_equal(errors, "treasure content type", treasure_content[0]["type"], "treasure")
	var treasure_claim_result: Dictionary = DungeonStateModel.claim_current_reward(dungeon, treasure_state)
	_expect_equal(errors, "treasure claim accepted", treasure_claim_result["status"], "accepted")
	var treasure_claim_state: Dictionary = treasure_claim_result["state"]
	_expect_true(errors, "treasure reward claimed", DungeonStateModel.room_reward_is_claimed(treasure_claim_state, "collapsed_cache"))
	_expect_true(errors, "treasure room cleared after claim", DungeonStateModel.room_is_cleared(treasure_claim_state, "collapsed_cache"))
	_expect_equal(errors, "treasure claim gold", treasure_claim_state["claimed_rewards"][0]["rewards"]["gold"], 9)
	_expect_equal(errors, "treasure totals gold", DungeonStateModel.reward_totals(treasure_claim_state)["gold"], 9)
	_expect_equal(errors, "treasure totals item", DungeonStateModel.reward_totals(treasure_claim_state)["items"][0], "old_mine_trinket")
	var treasure_claim_again: Dictionary = DungeonStateModel.claim_current_reward(dungeon, treasure_claim_state)
	_expect_equal(errors, "treasure claim twice rejected", treasure_claim_again["status"], "rejected")
	_expect_equal(errors, "treasure claim twice reason", treasure_claim_again["rejection"], "reward_already_claimed")

	var force_with_pickaxe_state := DungeonStateModel.initial_state(dungeon)
	force_with_pickaxe_state = DungeonStateModel.enter_room(dungeon, force_with_pickaxe_state, "dusty_crossing")["state"]
	var force_with_pickaxe_prompt: Dictionary = DungeonStateModel.enter_room(dungeon, force_with_pickaxe_state, "collapsed_cache")
	var force_with_pickaxe_result: Dictionary = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, force_with_pickaxe_prompt["state"], "force_passage")
	_expect_equal(errors, "force passage with pickaxe accepted", force_with_pickaxe_result["status"], "accepted")
	_expect_equal(errors, "force passage with pickaxe outcome", force_with_pickaxe_result["event"]["traversal_events"][1]["outcome_id"], "bruised_by_rubble")
	_expect_equal(errors, "force passage with pickaxe keeps pickaxe", DungeonStateModel.supply_count(force_with_pickaxe_result["state"], "pickaxe"), 1)
	_expect_true(errors, "force passage with pickaxe applies bruised", DungeonStateModel.active_debuff_summary(force_with_pickaxe_result["state"]).has("bruised x1"))
	_expect_equal(errors, "force passage target hp loss", force_with_pickaxe_result["state"]["target_effects"]["party_member_0"]["hp_loss"], 2)
	_expect_equal(errors, "force passage target bruised stacks", force_with_pickaxe_result["state"]["target_effects"]["party_member_0"]["debuffs"]["bruised"], 1)

	var oil_result: Dictionary = DungeonStateModel.use_lamp_oil(treasure_claim_state)
	_expect_equal(errors, "lamp oil accepted", oil_result["status"], "accepted")
	_expect_equal(errors, "lamp oil restores light", oil_result["state"]["light_level"], 4)
	_expect_equal(errors, "lamp oil decremented", DungeonStateModel.supply_count(oil_result["state"], "lamp_oil"), 1)
	var full_light_oil_result: Dictionary = DungeonStateModel.use_lamp_oil(oil_result["state"])
	_expect_equal(errors, "full light oil rejected", full_light_oil_result["status"], "rejected")
	_expect_equal(errors, "full light oil reason", full_light_oil_result["rejection"], "light_already_full")

	var no_pickaxe_dungeon: Dictionary = dungeon.duplicate(true)
	no_pickaxe_dungeon["starting_supplies"] = {"lamp_oil": 0, "pickaxe": 0}
	var no_pickaxe_state := DungeonStateModel.initial_state(no_pickaxe_dungeon)
	no_pickaxe_state = DungeonStateModel.enter_room(no_pickaxe_dungeon, no_pickaxe_state, "dusty_crossing")["state"]
	var no_pickaxe_result: Dictionary = DungeonStateModel.enter_room(no_pickaxe_dungeon, no_pickaxe_state, "collapsed_cache")
	_expect_equal(errors, "no pickaxe rubble requires choice", no_pickaxe_result["status"], "choice_required")
	_expect_false(errors, "no pickaxe use supply unavailable", no_pickaxe_result["event"]["choices"][0]["available"])
	no_pickaxe_result = DungeonStateModel.resolve_corridor_hazard_choice(no_pickaxe_dungeon, no_pickaxe_result["state"], "force_passage")
	_expect_equal(errors, "no pickaxe rubble accepted", no_pickaxe_result["status"], "accepted")
	_expect_equal(errors, "no pickaxe rubble outcome", no_pickaxe_result["event"]["traversal_events"][1]["outcome_id"], "bruised_by_rubble")
	_expect_equal(errors, "no pickaxe hp loss", no_pickaxe_result["state"]["party_effects"]["hp_loss"], 2)
	_expect_true(errors, "no pickaxe bruised debuff", no_pickaxe_result["state"]["party_effects"]["debuffs"].has("bruised"))
	_expect_equal(errors, "no pickaxe active bruised id", no_pickaxe_result["state"]["active_debuffs"]["bruised"]["id"], "bruised")
	_expect_equal(errors, "no pickaxe active bruised stacks", no_pickaxe_result["state"]["active_debuffs"]["bruised"]["stacks"], 1)
	_expect_true(errors, "no pickaxe active bruised target", no_pickaxe_result["state"]["active_debuffs"]["bruised"]["targets"].has("party_member_0"))
	_expect_true(errors, "active debuff summary includes bruised", DungeonStateModel.active_debuff_summary(no_pickaxe_result["state"]).has("bruised x1"))

	var combat_result: Dictionary = DungeonStateModel.enter_room(dungeon, state, "spider_nest")
	_expect_equal(errors, "trap corridor requires choice", combat_result["status"], "choice_required")
	_expect_equal(errors, "trap hazard type", combat_result["event"]["hazard_type"], "trap")
	_expect_equal(errors, "trap hazard supply", combat_result["event"]["required_supply_id"], "trap_tools")
	_expect_true(errors, "trap tools choice available", combat_result["event"]["choices"][0]["available"])
	combat_result = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, combat_result["state"], "use_supply")
	_expect_equal(errors, "combat room accepted", combat_result["status"], "accepted")
	var combat_state: Dictionary = combat_result["state"]
	_expect_equal(errors, "combat current room", combat_state["current_room_id"], "spider_nest")
	_expect_true(errors, "combat visited", DungeonStateModel.room_is_visited(combat_state, "spider_nest"))
	_expect_false(errors, "combat not cleared", DungeonStateModel.room_is_cleared(combat_state, "spider_nest"))
	_expect_equal(errors, "pending combat dungeon id", combat_state["pending_combat_request"]["dungeon_id"], "dungeon_old_mine")
	_expect_equal(errors, "pending combat room id", combat_state["pending_combat_request"]["room_id"], "spider_nest")
	_expect_equal(errors, "pending combat content type", combat_state["pending_combat_request"]["content_type"], "combat")
	_expect_equal(errors, "pending combat path", combat_state["pending_combat_request"]["combat_encounter_path"], "res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json")
	_expect_equal(errors, "pending combat dungeon modifier light", combat_state["pending_combat_request"]["dungeon_modifiers"]["light_state"], "dim")
	_expect_equal(errors, "trap tools consumed", DungeonStateModel.supply_count(combat_state, "trap_tools"), 0)
	_expect_false(errors, "trap disarm avoids poisoned", DungeonStateModel.active_debuff_summary(combat_state).has("poisoned x1"))

	var forced_trap_state := DungeonStateModel.initial_state(dungeon)
	forced_trap_state = DungeonStateModel.enter_room(dungeon, forced_trap_state, "dusty_crossing")["state"]
	var forced_trap_prompt: Dictionary = DungeonStateModel.enter_room(dungeon, forced_trap_state, "spider_nest")
	var forced_trap_result: Dictionary = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, forced_trap_prompt["state"], "force_passage")
	_expect_equal(errors, "forced trap accepted", forced_trap_result["status"], "accepted")
	_expect_equal(errors, "forced trap outcome", forced_trap_result["event"]["traversal_events"][1]["outcome_id"], "poisoned_by_needle_trap")
	_expect_equal(errors, "forced trap hp loss", forced_trap_result["state"]["party_effects"]["hp_loss"], 1)
	_expect_true(errors, "forced trap applies poisoned", DungeonStateModel.active_debuff_summary(forced_trap_result["state"]).has("poisoned x1"))
	_expect_equal(errors, "forced trap target poisoned stacks", forced_trap_result["state"]["target_effects"]["party_member_0"]["debuffs"]["poisoned"], 1)

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
	var guarded_claim_before_victory: Dictionary = DungeonStateModel.claim_current_reward(dungeon, guarded_state)
	_expect_equal(errors, "guarded claim before victory rejected", guarded_claim_before_victory["status"], "rejected")
	_expect_equal(errors, "guarded claim before victory reason", guarded_claim_before_victory["rejection"], "no_claimable_reward")
	var guarded_victory_result: Dictionary = DungeonStateModel.apply_combat_result(dungeon, guarded_state, _combat_payload("victory", "dungeon_old_mine", "guarded_cache"))
	_expect_equal(errors, "guarded victory accepted", guarded_victory_result["status"], "accepted")
	var guarded_victory_state: Dictionary = guarded_victory_result["state"]
	_expect_true(errors, "guarded room cleared after victory", DungeonStateModel.room_is_cleared(guarded_victory_state, "guarded_cache"))
	_expect_true(errors, "guarded reward unlocked after victory", DungeonStateModel.room_reward_is_unlocked(guarded_victory_state, "guarded_cache"))
	var guarded_claim_result: Dictionary = DungeonStateModel.claim_current_reward(dungeon, guarded_victory_state)
	_expect_equal(errors, "guarded claim after victory accepted", guarded_claim_result["status"], "accepted")
	var guarded_claim_state: Dictionary = guarded_claim_result["state"]
	_expect_true(errors, "guarded reward claimed", DungeonStateModel.room_reward_is_claimed(guarded_claim_state, "guarded_cache"))
	_expect_equal(errors, "guarded claim item", guarded_claim_state["claimed_rewards"][0]["rewards"]["items"][0], "rusty_key")
	_expect_equal(errors, "guarded totals xp", DungeonStateModel.reward_totals(guarded_claim_state)["xp"], 12)
	_expect_equal(errors, "guarded totals gold", DungeonStateModel.reward_totals(guarded_claim_state)["gold"], 7)

	var locked_without_key: Dictionary = DungeonStateModel.enter_room(dungeon, guarded_victory_state, "sealed_armory")
	_expect_equal(errors, "locked room without key rejected", locked_without_key["status"], "rejected")
	_expect_equal(errors, "locked room without key reason", locked_without_key["rejection"], "locked_missing_key")
	var locked_with_key: Dictionary = DungeonStateModel.enter_room(dungeon, guarded_claim_state, "sealed_armory")
	_expect_equal(errors, "locked room with key accepted", locked_with_key["status"], "accepted")
	_expect_true(errors, "locked room unlocked after enter", DungeonStateModel.room_is_unlocked(locked_with_key["state"], "sealed_armory"))
	var armory_claim: Dictionary = DungeonStateModel.claim_current_reward(dungeon, locked_with_key["state"])
	_expect_equal(errors, "armory reward claim accepted", armory_claim["status"], "accepted")
	_expect_equal(errors, "armory totals item", DungeonStateModel.reward_totals(armory_claim["state"])["items"][1], "old_mine_blade")

	var no_pending_result: Dictionary = DungeonStateModel.apply_combat_result(dungeon, state, _combat_payload("victory", "dungeon_old_mine", "spider_nest"))
	_expect_equal(errors, "no pending result rejected", no_pending_result["status"], "rejected")
	_expect_equal(errors, "no pending reason", no_pending_result["rejection"], "no_pending_combat")

	var non_exit_complete: Dictionary = DungeonStateModel.complete_current_room(dungeon, state)
	_expect_equal(errors, "non exit completion rejected", non_exit_complete["status"], "rejected")
	_expect_equal(errors, "non exit completion reason", non_exit_complete["rejection"], "not_exit_room")

	var exit_path_state: Dictionary = DungeonStateModel.enter_room(dungeon, state, "guarded_cache")["state"]
	exit_path_state = DungeonStateModel.apply_combat_result(dungeon, exit_path_state, _combat_payload("victory", "dungeon_old_mine", "guarded_cache"))["state"]
	exit_path_state = DungeonStateModel.enter_room(dungeon, exit_path_state, "lower_exit")["state"]
	var exit_complete: Dictionary = DungeonStateModel.complete_current_room(dungeon, exit_path_state)
	_expect_equal(errors, "exit completion accepted", exit_complete["status"], "accepted")
	var completed_state: Dictionary = exit_complete["state"]
	_expect_true(errors, "dungeon completed", completed_state["completed"])
	_expect_equal(errors, "completed room id", completed_state["completed_at_room_id"], "lower_exit")
	_expect_true(errors, "exit room cleared on completion", DungeonStateModel.room_is_cleared(completed_state, "lower_exit"))

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
