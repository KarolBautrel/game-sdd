extends SceneTree

const DungeonDebugScript := preload("res://scripts/presentation/dungeon_debug.gd")
const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")
const PartyRoster := preload("res://scripts/domain/party_roster.gd")


func _init() -> void:
	var errors: Array[String] = []
	var dungeon := _load_json("res://resources/data/dungeons/dungeon_old_mine.json")
	var hud := DungeonDebugScript.new()
	hud.dungeon = dungeon
	hud.run_state = DungeonStateModel.initial_state(dungeon)
	hud.selected_room_id = "entrance"
	hud.selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	hud.expedition_started = true
	hud._apply_responsive_layout()

	var loadout_hud := DungeonDebugScript.new()
	loadout_hud.dungeon = dungeon
	loadout_hud.selected_supply_loadout = DungeonStateModel.default_supply_loadout(dungeon)
	loadout_hud.run_state = DungeonStateModel.initial_state(dungeon, loadout_hud.selected_supply_loadout)
	loadout_hud.selected_room_id = "entrance"
	loadout_hud._apply_responsive_layout()
	_expect_true(errors, "loadout pending before start", loadout_hud._loadout_pending())
	_expect_true(errors, "loadout status copy", loadout_hud._status_summary().contains("Prepare expedition supplies"))
	loadout_hud._adjust_loadout_supply("pickaxe", -1)
	_expect_equal(errors, "loadout pickaxe adjusted", int(loadout_hud.selected_supply_loadout["pickaxe"]), 0)
	_expect_equal(errors, "loadout resource tray pickaxe", loadout_hud._resource_tile_texts()["pickaxe"], "0")
	_expect_true(errors, "loadout route copy", loadout_hud._route_state_text().contains("Preparation:"))
	_expect_equal(errors, "default dungeon source", loadout_hud.dungeon_source, DungeonDebugScript.DUNGEON_SOURCE_GENERATED)
	_expect_true(errors, "loadout summary includes source", loadout_hud._status_summary().contains("Old Mine"))
	var party_members := loadout_hud._party_members_for_ui()
	_expect_equal(errors, "party ui member count", party_members.size(), 2)
	_expect_equal(errors, "party ui warrior name", party_members[0]["display_name"], "Bran")
	_expect_equal(errors, "party ui archer name", party_members[1]["display_name"], "Torin")
	_expect_true(errors, "party ui warrior portrait exists", FileAccess.file_exists(party_members[0]["portrait_path"]))
	_expect_true(errors, "party ui archer portrait exists", FileAccess.file_exists(party_members[1]["portrait_path"]))
	_expect_equal(errors, "party roster warrior visual", PartyRoster.hero_for_combat_unit("unit_player_001")["visual"]["character"], "warrior")
	loadout_hud._set_dungeon_source(DungeonDebugScript.DUNGEON_SOURCE_GENERATED)
	_expect_equal(errors, "generated source selected", loadout_hud.dungeon_source, DungeonDebugScript.DUNGEON_SOURCE_GENERATED)
	_expect_equal(errors, "generated source dungeon id", loadout_hud.dungeon["id"], "generated_old_mine_draft")
	_expect_equal(errors, "generated source selected room", loadout_hud.selected_room_id, "generated_entrance")
	_expect_true(errors, "generated source has template room count", loadout_hud.dungeon.get("rooms", []).size() >= 6)
	_expect_true(errors, "generated source has seed", loadout_hud.generated_dungeon_seed > 0)
	_expect_true(errors, "generated source status copy", loadout_hud._status_summary().contains("Medium Mine"))
	_expect_true(errors, "generated summary includes difficulty", loadout_hud._generator_summary_text().contains("Generated: Medium Mine | D2"))
	_expect_true(errors, "generated summary includes rooms", loadout_hud._generator_summary_text().contains("Rooms"))
	_expect_true(errors, "generated D2 map content is horizontally scrollable", loadout_hud.graph_content_size.x > loadout_hud._map_scroll_rect().size.x)
	loadout_hud._set_generated_difficulty(3)
	_expect_equal(errors, "generated difficulty changed", loadout_hud.generated_dungeon_difficulty, 3)
	_expect_true(errors, "generated difficulty summary changed", loadout_hud._generator_summary_text().contains("Generated: Deep Mine | D3"))
	_expect_equal(errors, "generated D3 keeps readable room size", loadout_hud.room_node_size, DungeonDebugScript.ROOM_SIZE)
	_expect_true(errors, "generated D3 map content is horizontally scrollable", loadout_hud.graph_content_size.x > loadout_hud._map_scroll_rect().size.x)
	_expect_true(errors, "generated D3 display goes right more than down", loadout_hud._display_room_position_span("x") > loadout_hud._display_room_position_span("y"))
	_expect_true(errors, "generated D3 has at least three combat rooms", _combat_room_count(loadout_hud.dungeon) >= 3)
	var scroll_hud := DungeonDebugScript.new()
	scroll_hud.dungeon = loadout_hud.dungeon
	scroll_hud.run_state = DungeonStateModel.initial_state(scroll_hud.dungeon)
	scroll_hud.selected_room_id = "generated_entrance"
	root.add_child(scroll_hud)
	scroll_hud.graph_layer = Control.new()
	scroll_hud.add_child(scroll_hud.graph_layer)
	scroll_hud._apply_responsive_layout()
	scroll_hud._create_map_chrome()
	scroll_hud._apply_positioned_chrome()
	_expect_equal(errors, "generated D3 horizontal scrollbar mode", scroll_hud.map_scroll_container.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_SHOW_ALWAYS)
	_expect_true(errors, "generated D3 graph child wider than scroll viewport", scroll_hud.graph_layer.custom_minimum_size.x > scroll_hud.map_scroll_container.size.x)
	scroll_hud._scroll_map_horizontal(220)
	_expect_true(errors, "generated D3 mouse wheel can move horizontal scroll", scroll_hud.map_scroll_container.scroll_horizontal > 0)
	scroll_hud.free()
	for room: Dictionary in loadout_hud.dungeon.get("rooms", []):
		var room_position := loadout_hud._room_screen_position(room)
		_expect_true(errors, "generated D3 room has positive graph x %s" % str(room.get("id", "")), room_position.x >= 0.0)
		_expect_true(errors, "generated D3 room has positive graph y %s" % str(room.get("id", "")), room_position.y >= 0.0)
		_expect_true(errors, "generated D3 room fits scroll content width %s" % str(room.get("id", "")), room_position.x + loadout_hud.room_node_size.x <= loadout_hud.graph_content_size.x)
		_expect_true(errors, "generated D3 room fits scroll content height %s" % str(room.get("id", "")), room_position.y + loadout_hud.room_node_size.y <= loadout_hud.graph_content_size.y)
	_expect_equal(errors, "generated toggle text target", loadout_hud._source_display_name(loadout_hud._other_dungeon_source()), "Old Mine")
	var first_generated_seed := loadout_hud.generated_dungeon_seed
	var first_generated_hazards := _hazard_signature(loadout_hud.dungeon)
	loadout_hud._reroll_generated_dungeon()
	_expect_equal(errors, "generated reroll keeps source", loadout_hud.dungeon_source, DungeonDebugScript.DUNGEON_SOURCE_GENERATED)
	_expect_equal(errors, "generated reroll keeps difficulty", loadout_hud.generated_dungeon_difficulty, 3)
	_expect_not_equal(errors, "generated reroll changes seed", loadout_hud.generated_dungeon_seed, first_generated_seed)
	_expect_not_equal(errors, "generated reroll changes hazards", _hazard_signature(loadout_hud.dungeon), first_generated_hazards)
	loadout_hud._set_dungeon_source(DungeonDebugScript.DUNGEON_SOURCE_AUTHORED)
	_expect_equal(errors, "authored source restored", loadout_hud.dungeon_source, DungeonDebugScript.DUNGEON_SOURCE_AUTHORED)
	_expect_equal(errors, "authored source dungeon id", loadout_hud.dungeon["id"], "dungeon_old_mine")
	_expect_equal(errors, "authored source selected room", loadout_hud.selected_room_id, "entrance")
	loadout_hud._adjust_loadout_supply("pickaxe", -1)
	loadout_hud._start_expedition_with_loadout()
	_expect_false(errors, "loadout no longer pending after start", loadout_hud._loadout_pending())
	_expect_equal(errors, "loadout start uses selected pickaxe", DungeonStateModel.supply_count(loadout_hud.run_state, "pickaxe"), 0)
	_expect_equal(errors, "loadout start has trap tools", DungeonStateModel.supply_count(loadout_hud.run_state, "trap_tools"), 1)
	loadout_hud.free()

	var entrance_lines := "\n".join(hud._detail_lines_for_room(_room_by_id(dungeon, "entrance")))
	_expect_false(errors, "detail omits visited ids", entrance_lines.contains("Visited:"))
	_expect_false(errors, "detail omits cleared ids", entrance_lines.contains("Cleared:"))
	_expect_false(errors, "detail omits internal dungeon id", entrance_lines.contains("dungeon_old_mine"))
	_expect_true(errors, "detail shows light and supplies", entrance_lines.contains("Light: bright 4/4 | Torch: 2 | Pickaxe: 1 | Trap Tools: 1 | Bandage: 1"))
	var entrance_exits := hud._connected_room_options("entrance")
	_expect_equal(errors, "entrance exit count", entrance_exits.size(), 1)
	_expect_equal(errors, "entrance exit slot", entrance_exits[0].get("slot", 0), 1)
	_expect_equal(errors, "entrance exit target", entrance_exits[0].get("id", ""), "dusty_crossing")
	_expect_true(errors, "map legend includes combat", hud._map_legend_lines().has("[!] combat"))
	_expect_true(errors, "rubble corridor uses hazard pool ref", _corridor_by_id(dungeon, "crossing_to_cache").has("hazard_pool_refs"))
	_expect_equal(errors, "rubble corridor marker", hud._corridor_marker_label(_corridor_by_id(dungeon, "crossing_to_cache")), "Rubble")
	_expect_equal(errors, "resource tray includes torch count", hud._resource_tile_texts()["torch"], "2")
	_expect_dungeon_icon_exists(errors, "torch icon", hud._resource_icon_path("torch"), "icon_lamp_oil.png")
	_expect_dungeon_icon_exists(errors, "pickaxe icon", hud._resource_icon_path("pickaxe"), "icon_pickaxe.png")
	_expect_dungeon_icon_exists(errors, "bandage icon", hud._resource_icon_path("bandage"), "icon_bandage.png")
	_expect_dungeon_icon_exists(errors, "trap tools icon", hud._resource_icon_path("trap_tools"), "icon_trap.png")
	_expect_dungeon_icon_exists(errors, "camping kit icon", hud._resource_icon_path("camping_kit"), "icon_camping_kit.png")
	_expect_dungeon_icon_exists(errors, "food icon", hud._resource_icon_path("food"), "icon_food.png")
	_expect_dungeon_icon_exists(errors, "treasure room icon", hud._room_icon_path(_room_by_id(dungeon, "collapsed_cache")), "icon_treasure.png")
	_expect_dungeon_icon_exists(errors, "combat room icon", hud._room_icon_path(_room_by_id(dungeon, "spider_nest")), "icon_combat_room.png")
	_expect_dungeon_icon_exists(errors, "exit room icon", hud._room_icon_path(_room_by_id(dungeon, "lower_exit")), "icon_exit_room.png")
	_expect_dungeon_icon_exists(errors, "locked room icon", hud._room_icon_path(_room_by_id(dungeon, "sealed_armory")), "icon_locked_room.png")
	_expect_dungeon_icon_exists(errors, "room event icon", hud._room_icon_path(_room_by_id(dungeon, "dusty_crossing")), "icon_room_event.png")
	_expect_true(errors, "route state exploring", hud._route_state_text().contains("Exploring from: Mine Entrance"))
	var sealed_position := hud._room_screen_position(_room_by_id(dungeon, "sealed_armory"))
	_expect_true(errors, "map room layout stays inside scroll content", sealed_position.x + DungeonDebugScript.ROOM_SIZE.x <= hud.graph_content_size.x)
	_expect_true(errors, "loadout panel stays outside map", hud.loadout_area.position.x >= hud.detail_area.position.x)

	hud.run_state = DungeonStateModel.enter_room(dungeon, hud.run_state, "dusty_crossing")["state"]
	hud.selected_room_id = "dusty_crossing"
	_expect_true(errors, "room event route state", hud._route_state_text().contains("Room event: Dusty Crossing"))
	_expect_true(errors, "room event popup text", hud._room_event_popup_text(hud.run_state["pending_room_event"]).contains("inside Dusty Crossing"))
	_expect_equal(errors, "plain room event supply summary", hud._room_event_supply_summary(hud.run_state["pending_room_event"]), "Room discovery")
	_expect_equal(errors, "required room event supply summary", hud._room_event_supply_summary({
		"choices": [{"id": "inspect", "requires_supply": "pickaxe", "available": false}]
	}), "Requires: Pickaxe missing")
	var room_event_lines := "\n".join(hud._detail_lines_for_room(_room_by_id(dungeon, "dusty_crossing")))
	_expect_true(errors, "room event shown in detail", room_event_lines.contains("Room event:"))
	hud.run_state = DungeonStateModel.resolve_room_event_choice(dungeon, hud.run_state, "ignore")["state"]
	_expect_true(errors, "room event resolved", hud.run_state["resolved_room_event_ids"].has("dusty_crossing_damp_shrine"))
	_expect_true(errors, "room event history summary", hud._last_room_event_summary().contains("Events resolved: 1"))
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
	_expect_true(errors, "pending corridor event shown in detail", pending_lines.contains("Corridor event: A collapsed pile of mine stone blocks the passage."))
	var treasure_state: Dictionary = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, hud.run_state, "use_supply")["state"]
	hud.run_state = treasure_state
	hud.selected_room_id = "collapsed_cache"
	_expect_true(errors, "treasure reward claimable", hud._current_room_has_claimable_reward())
	hud.run_state = DungeonStateModel.claim_current_reward(dungeon, hud.run_state)["state"]
	_expect_false(errors, "claimed reward no longer claimable", hud._current_room_has_claimable_reward())
	_expect_equal(errors, "hud run inventory gold", DungeonStateModel.run_inventory(hud.run_state)["gold"], 9)
	_expect_equal(errors, "claimed reward progress summary", hud._progress_summary(), "Rooms visited 3/7 | Secured 3/7 | Light 2/4 dim | Torch 2 | Pickaxe 0 | Trap Tools 1 | Bandage 1 | Camp 0 | Food 1 | Effects none | Gold 9 | Items 1 | XP 0")
	_expect_true(errors, "oil action available after light decay", hud._can_use_lamp_oil())
	var hazard_lines := "\n".join(hud._detail_lines_for_room(_room_by_id(dungeon, "collapsed_cache")))
	_expect_true(errors, "rubble feedback summarized", hazard_lines.contains("Last hazard: cleared_with_pickaxe"))
	hud.run_state = DungeonStateModel.use_lamp_oil(hud.run_state)["state"]
	_expect_equal(errors, "oil restores progress light", hud._progress_summary(), "Rooms visited 3/7 | Secured 3/7 | Light 4/4 bright | Torch 1 | Pickaxe 0 | Trap Tools 1 | Bandage 1 | Camp 0 | Food 1 | Effects none | Gold 9 | Items 1 | XP 0")
	var hazard_to_room_event_hud := DungeonDebugScript.new()
	hazard_to_room_event_hud.dungeon = _corridor_hazard_to_room_event_dungeon()
	hazard_to_room_event_hud.run_state = DungeonStateModel.initial_state(hazard_to_room_event_hud.dungeon)
	hazard_to_room_event_hud.selected_room_id = "start"
	hazard_to_room_event_hud.expedition_started = true
	_install_event_popup_controls(hazard_to_room_event_hud)
	var hazard_to_event_prompt: Dictionary = DungeonStateModel.enter_room(hazard_to_room_event_hud.dungeon, hazard_to_room_event_hud.run_state, "target")
	_expect_equal(errors, "hazard before room event prompt", hazard_to_event_prompt["status"], "choice_required")
	hazard_to_room_event_hud.run_state = hazard_to_event_prompt["state"]
	hazard_to_room_event_hud._refresh_pending_event_popup()
	_expect_equal(errors, "corridor popup shown first", hazard_to_room_event_hud.corridor_event_title_label.text, "Corridor Event")
	var hazard_to_event_result: Dictionary = DungeonStateModel.resolve_corridor_hazard_choice(hazard_to_room_event_hud.dungeon, hazard_to_room_event_hud.run_state, "use_supply")
	_expect_equal(errors, "hazard to room event accepted", hazard_to_event_result["status"], "accepted")
	hazard_to_room_event_hud.run_state = hazard_to_event_result["state"]
	hazard_to_room_event_hud._refresh_pending_event_popup()
	_expect_true(errors, "hazard to room event clears corridor pending", hazard_to_room_event_hud.run_state["pending_corridor_hazard"].is_empty())
	_expect_false(errors, "hazard to room event keeps room pending", hazard_to_room_event_hud.run_state["pending_room_event"].is_empty())
	_expect_equal(errors, "room popup shown after corridor hazard", hazard_to_room_event_hud.corridor_event_title_label.text, "Room Event")
	_expect_true(errors, "room popup visible after corridor hazard", hazard_to_room_event_hud.corridor_event_panel.visible)
	hazard_to_room_event_hud.corridor_event_panel.free()
	hazard_to_room_event_hud.free()
	var bruised_dungeon: Dictionary = dungeon.duplicate(true)
	bruised_dungeon["starting_supplies"] = {"lamp_oil": 0, "pickaxe": 0}
	var bruised_hud := DungeonDebugScript.new()
	bruised_hud.dungeon = bruised_dungeon
	bruised_hud.run_state = DungeonStateModel.initial_state(bruised_dungeon, {"lamp_oil": 0, "pickaxe": 0, "trap_tools": 0, "bandage": 0, "food": 0})
	bruised_hud.run_state["supplies"]["antidote"] = 1
	bruised_hud.expedition_started = true
	bruised_hud.run_state = DungeonStateModel.enter_room(bruised_dungeon, bruised_hud.run_state, "dusty_crossing")["state"]
	bruised_hud.run_state = DungeonStateModel.resolve_room_event_choice(bruised_dungeon, bruised_hud.run_state, "ignore")["state"]
	var bruised_prompt: Dictionary = DungeonStateModel.enter_room(bruised_dungeon, bruised_hud.run_state, "collapsed_cache")
	bruised_hud.run_state = DungeonStateModel.resolve_corridor_hazard_choice(bruised_dungeon, bruised_prompt["state"], "force_passage")["state"]
	bruised_hud.selected_room_id = "collapsed_cache"
	_expect_equal(errors, "debuff line copy", bruised_hud._active_debuff_line(), "Debuffs: bruised x1")
	bruised_hud.run_state = DungeonStateModel.enter_room(bruised_dungeon, bruised_hud.run_state, "dusty_crossing")["state"]
	bruised_hud.selected_room_id = "dusty_crossing"
	_expect_true(errors, "debuff progress persists after backtracking", bruised_hud._progress_summary().contains("Effects bruised x1"))
	_expect_true(errors, "recovery action available", bruised_hud._can_use_recovery_supply())
	bruised_hud._use_recovery_supply()
	_expect_false(errors, "recovery action unavailable after use", bruised_hud._can_use_recovery_supply())
	_expect_true(errors, "recovery clears progress effect", bruised_hud._progress_summary().contains("Effects none"))
	_expect_equal(errors, "recovery consumes antidote in hud", DungeonStateModel.supply_count(bruised_hud.run_state, "antidote"), 0)
	bruised_hud.free()
	var bandage_hud := DungeonDebugScript.new()
	bandage_hud.dungeon = dungeon
	bandage_hud.run_state = DungeonStateModel.initial_state(dungeon, {"lamp_oil": 0, "pickaxe": 0, "trap_tools": 0, "bandage": 1, "food": 0})
	bandage_hud.run_state["party_effects"]["hp_loss"] = 1
	bandage_hud.expedition_started = true
	_expect_equal(errors, "bandage selected for hp recovery", bandage_hud._preferred_recovery_supply_id(), "bandage")
	_expect_true(errors, "bandage recovery action available", bandage_hud._can_use_recovery_supply())
	bandage_hud._use_recovery_supply()
	_expect_equal(errors, "bandage recovery consumes bandage", DungeonStateModel.supply_count(bandage_hud.run_state, "bandage"), 0)
	_expect_equal(errors, "bandage recovery clears hp loss", int(bandage_hud.run_state["party_effects"].get("hp_loss", 0)), 0)
	bandage_hud.free()
	hud.run_state = DungeonStateModel.enter_room(dungeon, hud.run_state, "dusty_crossing")["state"]
	var trap_prompt: Dictionary = DungeonStateModel.enter_room(dungeon, hud.run_state, "spider_nest")
	_expect_equal(errors, "trap prompt status", trap_prompt["status"], "choice_required")
	_expect_equal(errors, "trap prompt type", trap_prompt["event"]["hazard_type"], "trap")
	_expect_equal(errors, "trap prompt event template", trap_prompt["event"]["event_id"], "needle_trap_basic")
	_expect_equal(errors, "trap prompt event pool", trap_prompt["event"]["pool_id"], "old_mine_trap_pool")
	_expect_equal(errors, "trap prompt required supply", trap_prompt["event"]["required_supply_id"], "trap_tools")
	_expect_true(errors, "trap prompt text mentions corridor", hud._corridor_hazard_popup_text(trap_prompt["event"]).contains("corridor before the party reaches Spider Nest"))
	hud.run_state = trap_prompt["state"]
	_expect_true(errors, "route state corridor event", hud._route_state_text().contains("Corridor event: Dusty Crossing -> Spider Nest"))
	hud.run_state = DungeonStateModel.resolve_corridor_hazard_choice(dungeon, trap_prompt["state"], "use_supply")["state"]
	_expect_true(errors, "trap prompt clears pending after tools", hud.run_state["pending_corridor_hazard"].is_empty())
	hud.selected_room_id = "spider_nest"
	var combat_lines := "\n".join(hud._detail_lines_for_room(_room_by_id(dungeon, "spider_nest")))
	_expect_true(errors, "pending combat warning shown", combat_lines.contains("Threat: enemies are waiting here."))
	_expect_false(errors, "pending path hidden after combat room", combat_lines.contains("res://"))
	_expect_equal(errors, "combat action label", DungeonDebugScript.ENTER_COMBAT_LABEL, "Enter Combat")
	_expect_equal(errors, "progress summary", hud._progress_summary(), "Rooms visited 4/7 | Secured 3/7 | Light 2/4 dim | Torch 1 | Pickaxe 0 | Trap Tools 0 | Bandage 1 | Camp 0 | Food 1 | Effects none | Gold 9 | Items 1 | XP 0")

	var exit_state: Dictionary = DungeonStateModel.initial_state(dungeon)
	exit_state = DungeonStateModel.enter_room(dungeon, exit_state, "dusty_crossing")["state"]
	exit_state = DungeonStateModel.resolve_room_event_choice(dungeon, exit_state, "ignore")["state"]
	exit_state = DungeonStateModel.enter_room(dungeon, exit_state, "guarded_cache")["state"]
	exit_state = DungeonStateModel.apply_combat_result(dungeon, exit_state, _combat_payload("victory", "dungeon_old_mine", "guarded_cache"))["state"]
	var guarded_exit_label_before_claim_hud := DungeonDebugScript.new()
	guarded_exit_label_before_claim_hud.dungeon = dungeon
	guarded_exit_label_before_claim_hud.run_state = exit_state
	guarded_exit_label_before_claim_hud.selected_room_id = "guarded_cache"
	guarded_exit_label_before_claim_hud.expedition_started = true
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
	_expect_true(errors, "post run summary has outcome", summary.contains("Expedition result: completed."))
	_expect_true(errors, "post run summary has completed room", summary.contains("Completed at: Lower Exit"))
	_expect_true(errors, "post run summary has gold", summary.contains("Gold claimed: 7"))
	_expect_true(errors, "post run summary has item", summary.contains("rusty_key"))
	_expect_true(errors, "post run summary has return hook", summary.contains("Return hook: res://scenes/app/App.tscn"))
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


func _combat_room_count(dungeon: Dictionary) -> int:
	var count := 0
	for room: Dictionary in dungeon.get("rooms", []):
		if str(room.get("kind", "")) == "combat":
			count += 1
	return count


func _corridor_by_id(dungeon: Dictionary, corridor_id: String) -> Dictionary:
	for corridor: Dictionary in dungeon.get("corridors", []):
		if corridor.get("id", "") == corridor_id:
			return corridor
	return {}


func _graph_signature(dungeon: Dictionary) -> String:
	var parts: Array[String] = []
	for room: Dictionary in dungeon.get("rooms", []):
		var position: Dictionary = room.get("position", {})
		parts.append("%s:%s:%s:%s" % [room.get("id", ""), room.get("kind", ""), position.get("x", 0), position.get("y", 0)])
	for corridor: Dictionary in dungeon.get("corridors", []):
		parts.append("%s:%s:%s:%s" % [corridor.get("id", ""), corridor.get("from", ""), corridor.get("to", ""), corridor.get("danger", 0.0)])
	return "|".join(parts)


func _hazard_signature(dungeon: Dictionary) -> String:
	var parts: Array[String] = []
	for corridor: Dictionary in dungeon.get("corridors", []):
		for hazard_pool_ref: Dictionary in corridor.get("hazard_pool_refs", []):
			parts.append("%s:%s" % [corridor.get("id", ""), hazard_pool_ref.get("pool_id", "")])
	return "|".join(parts)


func _corridor_hazard_to_room_event_dungeon() -> Dictionary:
	return {
		"id": "test_hazard_to_room_event",
		"display_name": "Test Hazard To Room Event",
		"recommended_party_level": 1,
		"start_room_id": "start",
		"hazard_seed": 17,
		"starting_supplies": {"lamp_oil": 0, "pickaxe": 1, "trap_tools": 0, "bandage": 0, "food": 0},
		"rooms": [
			{"id": "start", "display_name": "Start", "kind": "entrance", "position": {"x": 0, "y": 0}, "content": [{"type": "empty"}]},
			{"id": "target", "display_name": "Target", "kind": "empty", "position": {"x": 1, "y": 0}, "content": [
				{"type": "room_event", "id": "target_room_event", "event_id": "old_mine_damp_shrine"}
			]},
		],
		"corridors": [{
			"id": "start_to_target",
			"from": "start",
			"to": "target",
			"danger": 0.2,
			"light_decay": 0,
			"hazard_refs": [{"id": "test_rubble", "event_id": "rubble_minor", "trigger": {"mode": "first_traversal"}}],
		}],
		"exit_rules": {"allow_retreat": true, "boss_required": false},
	}


func _install_event_popup_controls(hud: DungeonDebugScript) -> void:
	hud.corridor_event_panel = PanelContainer.new()
	hud.corridor_event_panel.hide()
	hud.corridor_event_title_label = Label.new()
	hud.corridor_event_type_label = Label.new()
	hud.corridor_event_message_label = Label.new()
	hud.corridor_event_supply_label = Label.new()
	hud.corridor_event_result_label = Label.new()
	hud.corridor_event_choice_row = HBoxContainer.new()
	hud.corridor_event_panel.add_child(hud.corridor_event_title_label)
	hud.corridor_event_panel.add_child(hud.corridor_event_type_label)
	hud.corridor_event_panel.add_child(hud.corridor_event_message_label)
	hud.corridor_event_panel.add_child(hud.corridor_event_supply_label)
	hud.corridor_event_panel.add_child(hud.corridor_event_result_label)
	hud.corridor_event_panel.add_child(hud.corridor_event_choice_row)


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


func _expect_not_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual == expected:
		errors.append("%s: expected different values, got %s" % [label, actual])


func _expect_dungeon_icon_exists(errors: Array[String], label: String, path: String, file_name: String) -> void:
	_expect_true(errors, "%s uses dedicated file" % label, path.ends_with(file_name))
	_expect_true(errors, "%s exists" % label, FileAccess.file_exists(path))


func _expect_true(errors: Array[String], label: String, value: bool) -> void:
	if not value:
		errors.append("%s: expected true" % label)


func _expect_false(errors: Array[String], label: String, value: bool) -> void:
	if value:
		errors.append("%s: expected false" % label)
