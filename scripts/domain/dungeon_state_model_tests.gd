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
	_expect_equal(errors, "initial remedy supply", DungeonStateModel.supply_count(state, "remedy_kit"), 1)
	_expect_equal(errors, "initial party formation target", state["party_formation"][0]["target_id"], "party_slot_front")
	_expect_equal(errors, "initial party formation combat unit", state["party_formation"][0]["combat_unit_id"], "unit_player_001")
	_expect_equal(errors, "default loadout oil", DungeonStateModel.default_supply_loadout(dungeon)["lamp_oil"], 2)
	var custom_loadout_state := DungeonStateModel.initial_state(dungeon, {"lamp_oil": 4, "pickaxe": 0, "trap_tools": 2})
	_expect_equal(errors, "custom loadout oil", DungeonStateModel.supply_count(custom_loadout_state, "lamp_oil"), 4)
	_expect_equal(errors, "custom loadout pickaxe", DungeonStateModel.supply_count(custom_loadout_state, "pickaxe"), 0)
	_expect_equal(errors, "custom loadout trap tools", DungeonStateModel.supply_count(custom_loadout_state, "trap_tools"), 2)
	_expect_equal(errors, "selected loadout recorded", custom_loadout_state["selected_supply_loadout"]["pickaxe"], 0)
	var clamped_loadout := DungeonStateModel.clamp_supply_loadout(dungeon, {"lamp_oil": 99, "pickaxe": -4, "trap_tools": 99})
	_expect_equal(errors, "loadout oil clamps max", clamped_loadout["lamp_oil"], 4)
	_expect_equal(errors, "loadout pickaxe clamps min", clamped_loadout["pickaxe"], 0)
	_expect_equal(errors, "loadout trap tools clamps max", clamped_loadout["trap_tools"], 3)
	_expect_equal(errors, "loadout remedy clamps default", clamped_loadout["remedy_kit"], 1)
	var low_danger_plan: Dictionary = DungeonStateModel.procedural_corridor_plan(
		{"id": "generated_mine_low", "danger": 0.1},
		{"required_tags": ["mine", "corridor"], "id": "generated_low_hazard"}
	)
	_expect_equal(errors, "low danger plan corridor id", low_danger_plan["corridor_id"], "generated_mine_low")
	_expect_equal(errors, "low danger plan pool", low_danger_plan["hazard_pool_refs"][0]["pool_id"], "old_mine_rubble_pool")
	_expect_equal(errors, "low danger plan trigger", low_danger_plan["hazard_pool_refs"][0]["trigger"]["mode"], "first_traversal")
	var low_danger_hazards := DungeonStateModel._corridor_hazards({
		"id": "generated_mine_low",
		"hazard_pool_refs": low_danger_plan["hazard_pool_refs"],
	})
	_expect_equal(errors, "low danger plan materializes rubble", low_danger_hazards[0]["event_id"], "rubble_minor")
	var high_danger_plan: Dictionary = DungeonStateModel.procedural_corridor_plan(
		{"id": "generated_mine_high", "danger": 0.35},
		{"required_tags": ["mine", "corridor"], "id": "generated_high_hazard"}
	)
	_expect_equal(errors, "high danger plan pool", high_danger_plan["hazard_pool_refs"][0]["pool_id"], "old_mine_trap_pool")
	var missing_plan: Dictionary = DungeonStateModel.procedural_corridor_plan(
		{"id": "generated_crypt", "danger": 0.35},
		{"required_tags": ["crypt", "corridor"], "id": "generated_crypt_hazard"}
	)
	_expect_true(errors, "missing procedural tags produce no hazard refs", missing_plan["hazard_pool_refs"].is_empty())
	var generated_dungeon: Dictionary = DungeonStateModel.procedural_dungeon_draft({"seed": 32, "difficulty": 1})
	_expect_equal(errors, "generated dungeon id", generated_dungeon["id"], "generated_old_mine_draft")
	_expect_equal(errors, "generated dungeon start", generated_dungeon["start_room_id"], "generated_entrance")
	_expect_true(errors, "generated dungeon has finite template rooms", generated_dungeon["rooms"].size() >= 5)
	_expect_true(errors, "generated dungeon has hazard pool refs", _has_any_hazard_pool_ref(generated_dungeon))
	var generated_state := DungeonStateModel.initial_state(generated_dungeon)
	_expect_equal(errors, "generated initial current room", generated_state["current_room_id"], "generated_entrance")
	_expect_true(errors, "generated entrance cleared", DungeonStateModel.room_is_cleared(generated_state, "generated_entrance"))

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
	_expect_false(errors, "crossing waits on room event", DungeonStateModel.room_is_cleared(state, "dusty_crossing"))
	_expect_true(errors, "crossing has no pending combat", state["pending_combat_request"].is_empty())
	_expect_equal(errors, "crossing room event pending", state["pending_room_event"]["event_id"], "old_mine_damp_shrine")
	var room_event_result: Dictionary = DungeonStateModel.resolve_room_event_choice(dungeon, state, "inspect")
	_expect_equal(errors, "room event inspect accepted", room_event_result["status"], "accepted")
	_expect_true(errors, "room event marked resolved", room_event_result["state"]["resolved_room_event_ids"].has("dusty_crossing_damp_shrine"))
	_expect_equal(errors, "room event restores light", room_event_result["state"]["light_level"], 4)
	state = room_event_result["state"]
	_expect_equal(errors, "crossing traversal light restored by room event", state["light_level"], 4)
	_expect_equal(errors, "crossing traversal light still bright", state["light_state"], "bright")
	_expect_equal(errors, "crossing traversal event type", crossing_result["event"]["traversal_events"][0]["type"], "light_changed")

	var treasure_result: Dictionary = DungeonStateModel.enter_room(dungeon, state, "collapsed_cache")
	_expect_equal(errors, "treasure corridor hazard requires choice", treasure_result["status"], "choice_required")
	_expect_equal(errors, "treasure corridor hazard reason", treasure_result["rejection"], "corridor_hazard_pending")
	_expect_equal(errors, "treasure corridor hazard target", treasure_result["event"]["to_room_id"], "collapsed_cache")
	_expect_equal(errors, "treasure corridor hazard type", treasure_result["event"]["hazard_type"], "rubble")
	_expect_equal(errors, "treasure corridor hazard event template", treasure_result["event"]["event_id"], "rubble_minor")
	_expect_equal(errors, "treasure corridor hazard pool", treasure_result["event"]["pool_id"], "old_mine_rubble_pool")
	_expect_true(errors, "treasure corridor hazard use pickaxe available", treasure_result["event"]["choices"][0]["available"])
	_expect_equal(errors, "treasure stays in crossing before choice", treasure_result["state"]["current_room_id"], "dusty_crossing")
	treasure_result = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, treasure_result["state"], "use_supply")
	_expect_equal(errors, "treasure room accepted after hazard choice", treasure_result["status"], "accepted")
	var treasure_state: Dictionary = treasure_result["state"]
	_expect_equal(errors, "treasure current room", treasure_state["current_room_id"], "collapsed_cache")
	_expect_true(errors, "treasure visited", DungeonStateModel.room_is_visited(treasure_state, "collapsed_cache"))
	_expect_false(errors, "treasure not auto cleared", DungeonStateModel.room_is_cleared(treasure_state, "collapsed_cache"))
	_expect_true(errors, "treasure has no pending combat", treasure_state["pending_combat_request"].is_empty())
	_expect_equal(errors, "treasure traversal light bright after shrine", treasure_state["light_level"], 3)
	_expect_equal(errors, "treasure traversal light state bright", treasure_state["light_state"], "bright")
	_expect_equal(errors, "rubble hazard resolved", treasure_result["event"]["traversal_events"][1]["type"], "corridor_hazard_resolved")
	_expect_equal(errors, "rubble hazard outcome", treasure_result["event"]["traversal_events"][1]["outcome_id"], "cleared_with_pickaxe")
	_expect_equal(errors, "rubble hazard resolved event template", treasure_result["event"]["traversal_events"][1]["event_id"], "rubble_minor")
	_expect_equal(errors, "rubble hazard resolved pool", treasure_result["event"]["traversal_events"][1]["pool_id"], "old_mine_rubble_pool")
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
	force_with_pickaxe_state = _resolve_room_event_if_pending(dungeon, DungeonStateModel.enter_room(dungeon, force_with_pickaxe_state, "dusty_crossing")["state"])
	var force_with_pickaxe_prompt: Dictionary = DungeonStateModel.enter_room(dungeon, force_with_pickaxe_state, "collapsed_cache")
	var force_with_pickaxe_result: Dictionary = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, force_with_pickaxe_prompt["state"], "force_passage")
	_expect_equal(errors, "force passage with pickaxe accepted", force_with_pickaxe_result["status"], "accepted")
	_expect_equal(errors, "force passage with pickaxe outcome", force_with_pickaxe_result["event"]["traversal_events"][1]["outcome_id"], "bruised_by_rubble")
	_expect_equal(errors, "force passage with pickaxe keeps pickaxe", DungeonStateModel.supply_count(force_with_pickaxe_result["state"], "pickaxe"), 1)
	_expect_true(errors, "force passage with pickaxe applies bruised", DungeonStateModel.active_debuff_summary(force_with_pickaxe_result["state"]).has("bruised x1"))
	_expect_equal(errors, "force passage target hp loss", force_with_pickaxe_result["state"]["target_effects"]["party_slot_front"]["hp_loss"], 2)
	_expect_equal(errors, "force passage target bruised stacks", force_with_pickaxe_result["state"]["target_effects"]["party_slot_front"]["debuffs"]["bruised"], 1)
	var bruised_return_result: Dictionary = DungeonStateModel.enter_room(dungeon, force_with_pickaxe_result["state"], "dusty_crossing")
	_expect_equal(errors, "bruised return accepted", bruised_return_result["status"], "accepted")
	_expect_true(errors, "bruised persists after returning", DungeonStateModel.active_debuff_summary(bruised_return_result["state"]).has("bruised x1"))
	_expect_equal(errors, "bruised target hp loss persists after returning", bruised_return_result["state"]["target_effects"]["party_slot_front"]["hp_loss"], 2)
	var bruised_trap_prompt: Dictionary = DungeonStateModel.enter_room(dungeon, bruised_return_result["state"], "spider_nest")
	_expect_equal(errors, "bruised trap prompt status", bruised_trap_prompt["status"], "choice_required")
	_expect_true(errors, "bruised persists while trap pending", DungeonStateModel.active_debuff_summary(bruised_trap_prompt["state"]).has("bruised x1"))

	var oil_result: Dictionary = DungeonStateModel.use_lamp_oil(treasure_claim_state)
	_expect_equal(errors, "lamp oil accepted", oil_result["status"], "accepted")
	_expect_equal(errors, "lamp oil restores light", oil_result["state"]["light_level"], 4)
	_expect_equal(errors, "lamp oil decremented", DungeonStateModel.supply_count(oil_result["state"], "lamp_oil"), 1)
	var full_light_oil_result: Dictionary = DungeonStateModel.use_lamp_oil(oil_result["state"])
	_expect_equal(errors, "full light oil rejected", full_light_oil_result["status"], "rejected")
	_expect_equal(errors, "full light oil reason", full_light_oil_result["rejection"], "light_already_full")

	var no_pickaxe_dungeon: Dictionary = dungeon.duplicate(true)
	no_pickaxe_dungeon["starting_supplies"] = {"lamp_oil": 0, "pickaxe": 0}
	var no_pickaxe_state := DungeonStateModel.initial_state(no_pickaxe_dungeon, {"lamp_oil": 0, "pickaxe": 0, "trap_tools": 0})
	no_pickaxe_state = _resolve_room_event_if_pending(no_pickaxe_dungeon, DungeonStateModel.enter_room(no_pickaxe_dungeon, no_pickaxe_state, "dusty_crossing")["state"])
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
	_expect_true(errors, "no pickaxe active bruised target", no_pickaxe_result["state"]["active_debuffs"]["bruised"]["targets"].has("party_slot_front"))
	_expect_true(errors, "active debuff summary includes bruised", DungeonStateModel.active_debuff_summary(no_pickaxe_result["state"]).has("bruised x1"))

	var combat_result: Dictionary = DungeonStateModel.enter_room(dungeon, state, "spider_nest")
	_expect_equal(errors, "trap corridor requires choice", combat_result["status"], "choice_required")
	_expect_equal(errors, "trap hazard type", combat_result["event"]["hazard_type"], "trap")
	_expect_equal(errors, "trap hazard event template", combat_result["event"]["event_id"], "needle_trap_basic")
	_expect_equal(errors, "trap hazard pool", combat_result["event"]["pool_id"], "old_mine_trap_pool")
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
	_expect_equal(errors, "pending combat dungeon modifier light", combat_state["pending_combat_request"]["dungeon_modifiers"]["light_state"], "bright")
	_expect_equal(errors, "trap tools consumed", DungeonStateModel.supply_count(combat_state, "trap_tools"), 0)
	_expect_false(errors, "trap disarm avoids poisoned", DungeonStateModel.active_debuff_summary(combat_state).has("poisoned x1"))

	var forced_trap_state := DungeonStateModel.initial_state(dungeon)
	forced_trap_state = _resolve_room_event_if_pending(dungeon, DungeonStateModel.enter_room(dungeon, forced_trap_state, "dusty_crossing")["state"])
	var forced_trap_prompt: Dictionary = DungeonStateModel.enter_room(dungeon, forced_trap_state, "spider_nest")
	var forced_trap_result: Dictionary = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, forced_trap_prompt["state"], "force_passage")
	_expect_equal(errors, "forced trap accepted", forced_trap_result["status"], "accepted")
	_expect_equal(errors, "forced trap outcome", forced_trap_result["event"]["traversal_events"][1]["outcome_id"], "poisoned_by_needle_trap")
	_expect_equal(errors, "forced trap hp loss", forced_trap_result["state"]["party_effects"]["hp_loss"], 1)
	_expect_true(errors, "forced trap applies poisoned", DungeonStateModel.active_debuff_summary(forced_trap_result["state"]).has("poisoned x1"))
	_expect_equal(errors, "forced trap target poisoned stacks", forced_trap_result["state"]["target_effects"]["party_slot_front"]["debuffs"]["poisoned"], 1)
	var recovery_result: Dictionary = DungeonStateModel.use_recovery_supply(forced_trap_result["state"], "remedy_kit")
	_expect_equal(errors, "recovery accepted", recovery_result["status"], "accepted")
	_expect_equal(errors, "recovery consumes remedy", DungeonStateModel.supply_count(recovery_result["state"], "remedy_kit"), 0)
	_expect_true(errors, "recovery clears active debuffs", DungeonStateModel.active_debuff_summary(recovery_result["state"]).is_empty())
	_expect_true(errors, "recovery clears party debuffs", recovery_result["state"]["party_effects"]["debuffs"].is_empty())
	_expect_true(errors, "recovery clears target debuffs", recovery_result["state"]["target_effects"]["party_slot_front"]["debuffs"].is_empty())
	_expect_equal(errors, "recovery keeps hp loss", recovery_result["state"]["target_effects"]["party_slot_front"]["hp_loss"], 1)
	var recovery_without_debuff: Dictionary = DungeonStateModel.use_recovery_supply(recovery_result["state"], "remedy_kit")
	_expect_equal(errors, "recovery without supply rejected first", recovery_without_debuff["status"], "rejected")
	_expect_equal(errors, "recovery without supply reason", recovery_without_debuff["rejection"], "missing_recovery_supply")
	var no_debuff_recovery: Dictionary = DungeonStateModel.use_recovery_supply(state, "remedy_kit")
	_expect_equal(errors, "recovery without debuff rejected", no_debuff_recovery["status"], "rejected")
	_expect_equal(errors, "recovery without debuff reason", no_debuff_recovery["rejection"], "no_active_debuff")

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


func _has_any_hazard_pool_ref(dungeon: Dictionary) -> bool:
	for corridor: Dictionary in dungeon.get("corridors", []):
		if not corridor.get("hazard_pool_refs", []).is_empty():
			return true
	return false


func _enter_generated_route_until(errors: Array[String], dungeon: Dictionary, state: Dictionary, target_room_id: String) -> Dictionary:
	var route := _room_route(dungeon, str(state.get("current_room_id", "")), target_room_id)
	for index in range(1, route.size()):
		var next_id := str(route[index])
		var result: Dictionary = DungeonStateModel.enter_room(dungeon, state, next_id)
		if result["status"] == "choice_required":
			result = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, result["state"], "use_supply")
		if result["status"] != "accepted":
			errors.append("generated route traversal: expected accepted, got %s" % result["status"])
			return state
		state = result["state"]
		state = _resolve_room_event_if_pending(dungeon, state)
	if str(state.get("current_room_id", "")) != target_room_id:
		errors.append("generated route traversal: could not reach %s from %s" % [target_room_id, str(state.get("current_room_id", ""))])
	return state


func _resolve_room_event_if_pending(dungeon: Dictionary, state: Dictionary) -> Dictionary:
	if state.get("pending_room_event", {}).is_empty():
		return state
	return DungeonStateModel.resolve_room_event_choice(dungeon, state, "ignore")["state"]


func _room_route(dungeon: Dictionary, start_room_id: String, target_room_id: String) -> Array[String]:
	var queue: Array[String] = [start_room_id]
	var came_from := {start_room_id: ""}
	while not queue.is_empty():
		var current_id := str(queue.pop_front())
		if current_id == target_room_id:
			break
		for neighbor_id: String in _neighbor_room_ids(dungeon, current_id):
			if came_from.has(neighbor_id):
				continue
			came_from[neighbor_id] = current_id
			queue.append(neighbor_id)
	if not came_from.has(target_room_id):
		return [start_room_id]
	var route: Array[String] = []
	var cursor := target_room_id
	while cursor != "":
		route.push_front(cursor)
		cursor = str(came_from.get(cursor, ""))
	return route


func _neighbor_room_ids(dungeon: Dictionary, room_id: String) -> Array[String]:
	var ids: Array[String] = []
	for corridor: Dictionary in dungeon.get("corridors", []):
		if str(corridor.get("from", "")) == room_id:
			ids.append(str(corridor.get("to", "")))
		elif str(corridor.get("to", "")) == room_id:
			ids.append(str(corridor.get("from", "")))
	return ids


func _corridor_to_room(dungeon: Dictionary, room_id: String) -> Dictionary:
	for corridor: Dictionary in dungeon.get("corridors", []):
		if str(corridor.get("to", "")) == room_id:
			return corridor
	return {}


func _expect_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		errors.append("%s: expected %s, got %s" % [label, expected, actual])


func _expect_true(errors: Array[String], label: String, value: bool) -> void:
	if not value:
		errors.append("%s: expected true" % label)


func _expect_false(errors: Array[String], label: String, value: bool) -> void:
	if value:
		errors.append("%s: expected false" % label)
