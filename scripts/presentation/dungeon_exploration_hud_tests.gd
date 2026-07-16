extends SceneTree

const DungeonDebugScript := preload("res://scripts/presentation/dungeon_debug.gd")
const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")


func _init() -> void:
	var errors: Array[String] = []
	var dungeon := _load_json("res://resources/data/dungeons/dungeon_old_mine.json")
	var hud := DungeonDebugScript.new()
	hud.dungeon = dungeon
	hud.run_state = DungeonStateModel.initial_state(dungeon)
	hud.selected_room_id = "entrance"

	var entrance_lines := "\n".join(hud._detail_lines_for_room(_room_by_id(dungeon, "entrance")))
	_expect_false(errors, "detail omits visited ids", entrance_lines.contains("Visited:"))
	_expect_false(errors, "detail omits cleared ids", entrance_lines.contains("Cleared:"))
	_expect_false(errors, "detail omits internal dungeon id", entrance_lines.contains("dungeon_old_mine"))
	_expect_true(errors, "detail shows light and supplies", entrance_lines.contains("Light: bright 4/4 | Oil: 2 | Pickaxe: 1 | Trap Tools: 1"))
	var entrance_exits := hud._connected_room_options("entrance")
	_expect_equal(errors, "entrance exit count", entrance_exits.size(), 1)
	_expect_equal(errors, "entrance exit slot", entrance_exits[0].get("slot", 0), 1)
	_expect_equal(errors, "entrance exit target", entrance_exits[0].get("id", ""), "dusty_crossing")

	hud.run_state = DungeonStateModel.enter_room(dungeon, hud.run_state, "dusty_crossing")["state"]
	hud.selected_room_id = "dusty_crossing"
	var crossing_exits := hud._connected_room_options("dusty_crossing")
	_expect_equal(errors, "crossing exit count", crossing_exits.size(), 4)
	_expect_equal(errors, "crossing first exit", crossing_exits[0].get("id", ""), "entrance")
	_expect_equal(errors, "crossing third exit", crossing_exits[2].get("id", ""), "spider_nest")
	var treasure_prompt: Dictionary = DungeonStateModel.enter_room(dungeon, hud.run_state, "collapsed_cache")
	_expect_equal(errors, "rubble prompt status", treasure_prompt["status"], "choice_required")
	_expect_equal(errors, "rubble prompt still in corridor source", treasure_prompt["state"]["current_room_id"], "dusty_crossing")
	_expect_true(errors, "rubble prompt text mentions corridor", hud._corridor_hazard_popup_text(treasure_prompt["event"]).contains("corridor before the party reaches Collapsed Cache"))
	hud.run_state = treasure_prompt["state"]
	var pending_lines := "\n".join(hud._detail_lines_for_room(_room_by_id(dungeon, "dusty_crossing")))
	_expect_true(errors, "pending corridor event shown in detail", pending_lines.contains("Corridor event: A collapsed pile of mine stone blocks the cache passage."))
	var treasure_state: Dictionary = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, hud.run_state, "use_supply")["state"]
	hud.run_state = treasure_state
	hud.selected_room_id = "collapsed_cache"
	_expect_true(errors, "treasure reward claimable", hud._current_room_has_claimable_reward())
	hud.run_state = DungeonStateModel.claim_current_reward(dungeon, hud.run_state)["state"]
	_expect_false(errors, "claimed reward no longer claimable", hud._current_room_has_claimable_reward())
	_expect_equal(errors, "claimed reward progress summary", hud._progress_summary(), "Rooms visited 3/7 | Secured 3/7 | Light 2/4 dim | Oil 2 | Pickaxe 0 | Trap Tools 1 | Debuffs 0 | Gold 9 | Items 1 | XP 0")
	_expect_true(errors, "oil action available after light decay", hud._can_use_lamp_oil())
	var hazard_lines := "\n".join(hud._detail_lines_for_room(_room_by_id(dungeon, "collapsed_cache")))
	_expect_true(errors, "rubble feedback summarized", hazard_lines.contains("Last hazard: cleared_with_pickaxe"))
	hud.run_state = DungeonStateModel.use_lamp_oil(hud.run_state)["state"]
	_expect_equal(errors, "oil restores progress light", hud._progress_summary(), "Rooms visited 3/7 | Secured 3/7 | Light 4/4 bright | Oil 1 | Pickaxe 0 | Trap Tools 1 | Debuffs 0 | Gold 9 | Items 1 | XP 0")
	var bruised_dungeon: Dictionary = dungeon.duplicate(true)
	bruised_dungeon["starting_supplies"] = {"lamp_oil": 0, "pickaxe": 0}
	var bruised_hud := DungeonDebugScript.new()
	bruised_hud.dungeon = bruised_dungeon
	bruised_hud.run_state = DungeonStateModel.initial_state(bruised_dungeon)
	bruised_hud.run_state = DungeonStateModel.enter_room(bruised_dungeon, bruised_hud.run_state, "dusty_crossing")["state"]
	var bruised_prompt: Dictionary = DungeonStateModel.enter_room(bruised_dungeon, bruised_hud.run_state, "collapsed_cache")
	bruised_hud.run_state = DungeonStateModel.resolve_corridor_hazard_choice(bruised_dungeon, bruised_prompt["state"], "force_passage")["state"]
	bruised_hud.selected_room_id = "collapsed_cache"
	_expect_equal(errors, "debuff line copy", bruised_hud._active_debuff_line(), "Debuffs: bruised x1")
	bruised_hud.free()
	hud.run_state = DungeonStateModel.enter_room(dungeon, hud.run_state, "dusty_crossing")["state"]
	var trap_prompt: Dictionary = DungeonStateModel.enter_room(dungeon, hud.run_state, "spider_nest")
	_expect_equal(errors, "trap prompt status", trap_prompt["status"], "choice_required")
	_expect_equal(errors, "trap prompt type", trap_prompt["event"]["hazard_type"], "trap")
	_expect_true(errors, "trap prompt text mentions corridor", hud._corridor_hazard_popup_text(trap_prompt["event"]).contains("corridor before the party reaches Spider Nest"))
	hud.run_state = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, trap_prompt["state"], "use_supply")["state"]
	hud.selected_room_id = "spider_nest"
	var combat_lines := "\n".join(hud._detail_lines_for_room(_room_by_id(dungeon, "spider_nest")))
	_expect_true(errors, "pending combat warning shown", combat_lines.contains("Threat: enemies are waiting here."))
	_expect_false(errors, "pending path hidden after combat room", combat_lines.contains("res://"))
	_expect_equal(errors, "combat action label", DungeonDebugScript.ENTER_COMBAT_LABEL, "Enter Combat")
	_expect_equal(errors, "progress summary", hud._progress_summary(), "Rooms visited 4/7 | Secured 3/7 | Light 2/4 dim | Oil 1 | Pickaxe 0 | Trap Tools 0 | Debuffs 0 | Gold 9 | Items 1 | XP 0")

	var exit_state: Dictionary = DungeonStateModel.initial_state(dungeon)
	exit_state = DungeonStateModel.enter_room(dungeon, exit_state, "dusty_crossing")["state"]
	exit_state = DungeonStateModel.enter_room(dungeon, exit_state, "guarded_cache")["state"]
	exit_state = DungeonStateModel.apply_combat_result(dungeon, exit_state, _combat_payload("victory", "dungeon_old_mine", "guarded_cache"))["state"]
	var guarded_exit_label_before_claim_hud := DungeonDebugScript.new()
	guarded_exit_label_before_claim_hud.dungeon = dungeon
	guarded_exit_label_before_claim_hud.run_state = exit_state
	guarded_exit_label_before_claim_hud.selected_room_id = "guarded_cache"
	_expect_true(errors, "locked exit marked before key", guarded_exit_label_before_claim_hud._connected_room_labels("guarded_cache").has("Sealed Armory (locked, reward)"))
	guarded_exit_label_before_claim_hud.free()
	exit_state = DungeonStateModel.claim_current_reward(dungeon, exit_state)["state"]
	var armory_result: Dictionary = DungeonStateModel.enter_room(dungeon, exit_state, "sealed_armory")
	_expect_equal(errors, "locked armory entered with key", armory_result["status"], "accepted")
	exit_state = DungeonStateModel.enter_room(dungeon, exit_state, "lower_exit")["state"]
	hud.run_state = exit_state
	hud.selected_room_id = "lower_exit"
	_expect_true(errors, "exit can finish expedition", hud._current_room_can_finish_expedition())
	_expect_equal(errors, "finish action label", DungeonDebugScript.FINISH_EXPEDITION_LABEL, "Finish Expedition")
	hud.run_state = DungeonStateModel.complete_current_room(dungeon, hud.run_state)["state"]
	_expect_false(errors, "completed run hides finish action", hud._current_room_can_finish_expedition())
	_expect_true(errors, "completed status copy", hud._status_summary().contains("Expedition complete"))
	var summary := "\n".join(hud._post_run_summary_lines())
	_expect_true(errors, "post run summary has completed room", summary.contains("Completed at: Lower Exit"))
	_expect_true(errors, "post run summary has gold", summary.contains("Gold claimed: 7"))
	_expect_true(errors, "post run summary has item", summary.contains("rusty_key"))
	var armory_room := _room_by_id(dungeon, "sealed_armory")
	_expect_equal(errors, "spatial room marker", hud._room_map_label(armory_room), "[$] Sealed Armory")
	_expect_equal(errors, "spatial room position", hud._room_position_summary(armory_room), "x4 y0")
	hud.free()

	if errors.is_empty():
		print("Dungeon exploration HUD validation passed.")
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


func _room_by_id(dungeon: Dictionary, room_id: String) -> Dictionary:
	for room: Dictionary in dungeon.get("rooms", []):
		if room.get("id", "") == room_id:
			return room
	return {}


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
