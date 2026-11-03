extends SceneTree
## Real transactions, frozen snapshots, resolver commands and return; no OS input.
const Campaign := preload("res://scripts/session/campaign_session.gd")
const Gear := preload("res://scripts/domain/campaign_equipment.gd")
const Identity := preload("res://scripts/domain/hero_equipment_identity.gd")
const Party := preload("res://scripts/domain/party_roster.gd")
const Items := preload("res://scripts/domain/item_catalog.gd")
const Pilot := preload("res://scripts/qa/hero_equipment_pilot.gd")
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const Resolver := preload("res://scripts/domain/combat_resolver.gd")
const Actions := preload("res://scripts/presentation/combat/combat_action_model.gd")
const Selection := preload("res://scripts/domain/dungeon_entry_selection.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const BRAN := "unit_player_001"
var failures: Array[String] = []
var checks := 0
var paths: Array[String] = []
var battles: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func path_for(label: String) -> String:
	var path := "user://qa_hero_equipment_%s_%s.json" % [label, Time.get_ticks_usec()]
	paths.append(path)
	return path


func actor(data: Dictionary) -> Dictionary:
	return Actions.unit_by_id(data, BRAN)


func _run() -> void:
	var player_path := "user://campaign_v1.json"
	var player_existed := FileAccess.file_exists(player_path)
	var player_hash := FileAccess.get_sha256(player_path) if player_existed else ""
	var campaign: Node = root.get_node("CampaignSession")
	var session: Node = root.get_node("DungeonRunSession")
	var old_hero := Party.hero("hero_bran")
	var path := path_for("purchase")
	check(campaign.load_profile(path), "new ordinary campaign")
	check(not campaign.state.items.has("hero_greatsword"), "no automatic greatsword grant")
	check(campaign.purchase_item("salvaged_shield") and campaign.purchase_item("hero_greatsword"), "ordinary merchant sells both kits")
	check(campaign.state.gold == 8 and campaign.state.equipment == Gear.defaults(), "buy never equips and charges32 gold")
	check(campaign.equip(BRAN, "off_hand", "salvaged_shield"), "equip purchased shield")
	var before: Dictionary = campaign.state.duplicate(true)
	var bytes := FileAccess.get_file_as_string(path)
	check(not campaign.equip(BRAN, "main_hand", "hero_greatsword") and campaign.state == before and FileAccess.get_file_as_string(path) == bytes, "two hands conflict leaves state and save unchanged")
	var hero := Party.hero_for_combat_unit(BRAN)
	check(Identity.visual(hero, campaign.state.equipment[BRAN]).character == "warrior", "Bran sword/shield authored kit")
	check(campaign.equip(BRAN, "off_hand", null) and campaign.equip(BRAN, "main_hand", "hero_greatsword"), "explicit shield removal then greatsword")
	check(campaign.state.items == before.items and campaign.state.effects == before.effects, "switch does not consume or heal")
	check(campaign.load_profile(path) and campaign.state.equipment[BRAN].main_hand == "hero_greatsword", "greatsword survives restart")
	check(Party.hero("hero_bran") == old_hero and Identity.visual(hero, campaign.state.equipment[BRAN]).character == "bran_greatsword", "same roster identity and authored bearded variant")
	before = campaign.state.duplicate(true)
	campaign.save_path = "user://missing-identity-%s/save.json" % Time.get_ticks_usec()
	check(not campaign.equip(BRAN, "main_hand", "hero_sword") and campaign.state == before, "failed write cannot publish kit change")
	campaign.save_path = path
	var unsupported: Dictionary = Gear.defaults()[BRAN]
	unsupported.main_hand = "hero_bow"
	check(Identity.visual(hero, unsupported).character == "archer_1", "unsupported kit retains explicit legacy fallback")
	check(Identity.visual(Party.hero("hero_torin"), Gear.defaults().unit_player_002).character == "archer_1", "Torin unchanged")
	_check_textures()
	# Resume an actual ordinary App with native stash controls. No desktop input.
	var pilot_path := path_for("pilot")
	check(Pilot.open(campaign, pilot_path), "isolated pilot seeded once")
	var app: Control = load("res://scenes/app/App.tscn").instantiate()
	app.inventory_view = true
	root.add_child(app)
	await process_frame
	var view: Control = app.find_child("EquipmentView", true, false)
	view.slot_buttons.off_hand.pressed.emit()
	view.unequip_button.pressed.emit()
	await process_frame
	view = app.find_child("EquipmentView", true, false)
	app.find_child("InventoryView", true, false).grid.item_buttons.hero_greatsword.pressed.emit()
	view.equip_button.pressed.emit()
	await process_frame
	check(campaign.state.equipment[BRAN].main_hand == "hero_greatsword" and campaign.state.equipment[BRAN].off_hand == null, "ordinary UI equips greatsword after shield removal")
	check(Pilot.open(campaign, pilot_path) and campaign.state.items.count("hero_greatsword") == 1 and campaign.state.equipment[BRAN].main_hand == "hero_greatsword", "pilot restart resumes without reset or duplicate grants")
	app.queue_free()
	await process_frame
	var corrupt_path := path_for("corrupt")
	var file := FileAccess.open(corrupt_path, FileAccess.WRITE)
	file.store_string("{broken");file.close()
	check(not Pilot.open(campaign, corrupt_path) and not campaign.loaded and FileAccess.get_file_as_string(corrupt_path) == "{broken", "corrupt pilot fails closed without fallback or rewrite")
	for kit: String in ["sword_shield", "greatsword"]:
		_test_road(campaign, session, kit)
		_test_expedition(campaign, session, kit)
		_test_managed_victory(campaign, session, kit)
	check(FileAccess.file_exists(player_path) == player_existed and (not player_existed or FileAccess.get_sha256(player_path) == player_hash), "player campaign untouched")
	session.clear()
	campaign.load_profile("", true)
	for path_to_remove: String in paths:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path_to_remove))
	DirAccess.make_dir_recursive_absolute("res://artifacts/bran-identity")
	var report := FileAccess.open("res://artifacts/bran-identity/session-proof.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL", "checks":checks, "failures":failures, "legal_battle_simulations":battles, "physical_gameplay":"NOT_RUN", "new_art_acceptance":"AWAITING_USER_REVIEW", "player_save_unchanged":true}, "\t"));report.close()
	for failure in failures:
		push_error(failure)
	print("Hero equipment identity: %s checks, %s failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check_textures() -> void:
	var art := Art.new()
	for character: String in ["warrior", "bran_greatsword"]:
		var unit := {"id":BRAN, "visual":{"faction":"heroes", "character":character}}
		check(art.is_drawn_unit(unit), character + " painted renderer")
		check(is_equal_approx(art.clip_seconds(unit, "walk", 0.0), 1.0), character + " calm1000ms walk")
		for direction: String in ["south", "south_east", "east", "north_east", "north", "north_west", "west", "south_west"]:
			for action: String in ["neutral_idle", "combat_idle", "neutral_walk", "combat_walk", "attack", "hit", "death"]:
				for n in range(art.processed_sheet_frame_count(character, action)):
					var path := art.processed_sheet_texture_path(character, direction, "%s:%s" % [action, n])
					var texture := load(path) as Texture2D
					check(texture != null and texture.get_size() == Vector2(384, 320), "%s %s %s frame%s native texture" % [character, direction, action, n])


func _prepare(campaign: Node, kit: String, label: String) -> String:
	var path := path_for(label + kit)
	check(Pilot.open(campaign, path), kit + " fixture seeded")
	if kit == "greatsword":
		check(campaign.equip(BRAN, "off_hand", null) and campaign.equip(BRAN, "main_hand", "hero_greatsword"), kit + " equip")
	return path


func _test_road(campaign: Node, session: Node, kit: String) -> void:
	var path := _prepare(campaign, kit, "road")
	var equipment: Dictionary = campaign.state.equipment.duplicate(true)
	campaign.state.world.seed = 1
	check(campaign.travel("dungeon_old_mine") and campaign.choose_road_event("fight"), kit + " ordinary ambush pending")
	check(campaign.load_profile(path) and session.restore_road_combat(), kit + " reload frozen road fight")
	check(not campaign.equip(BRAN, "main_hand", "hero_sword") and campaign.state.equipment == equipment, kit + " pending fight locks gear")
	var template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(session.combat_encounter_path()))
	var launched: Dictionary = session.apply_launch_metadata(template)
	var expected := "warrior" if kit == "sword_shield" else "bran_greatsword"
	check(actor(launched).visual.character == expected and actor(launched).loadout == equipment[BRAN] and Party.display_name_for_combat_unit(BRAN) == "Bran", kit + " live campaign handoff keeps Bran and kit")
	check(Actions.action_granted_to_unit(launched, actor(launched), "shield_wall") == (kit == "sword_shield"), kit + " shield action matches visible equipment")
	var state: Dictionary = Resolver.simulate(launched, []).state
	var outcome: Dictionary = {}
	var command_count := 0
	for n in range(500):
		var active: Dictionary = Actions.unit_by_id(state, state.turn_state.active_unit_id)
		var policy := state.duplicate(true)
		if active.team == "player":
			for row: Dictionary in policy.units:
				row.team = "enemy" if row.team == "player" else "player"
		var command: Dictionary = Resolver.choose_enemy_command(policy, "identity_%s" % n)
		outcome = Resolver.simulate(state, [command])
		state = outcome.state
		command_count += 1
		for event: Dictionary in state.event_log:
			check(event.type != "command_rejected", kit + " legal resolver command%s" % n)
		if outcome.result != "in_progress":
			break
	check(outcome.get("result", "in_progress") != "in_progress", kit + " legal AI battle terminates")
	check(session.finish_combat(outcome.get("result_payload", {})), kit + " authoritative road return accepted")
	check(campaign.state.world.pending_event.is_empty() and campaign.state.equipment == equipment, kit + " road settled without gear mutation")
	check(campaign.load_profile(path) and campaign.state.equipment == equipment, kit + " road return persists")
	battles.append({"kit":kit, "result":outcome.get("result"), "commands":command_count, "debug_win":false, "return_accepted":campaign.state.world.pending_event.is_empty()})
	session.clear()


func _test_expedition(campaign: Node, session: Node, kit: String) -> void:
	var path := _prepare(campaign, kit, "expedition")
	var equipment: Dictionary = campaign.state.equipment.duplicate(true)
	# No road fixture is needed for this independent managed-expedition boundary.
	campaign.state.world.location_id = "dungeon_old_mine"
	var dungeon := Selection.dungeon_for_payload(Selection.default_payload())
	check(campaign.begin_run(dungeon, Model.initial_state(dungeon)), kit + " ordinary expedition begins")
	check(campaign.load_profile(path) and session.restore_campaign(), kit + " expedition restart")
	check(campaign.state.active_run.equipment_snapshot == equipment and not campaign.equip(BRAN, "main_hand", null), kit + " managed snapshot locked")
	var result: Dictionary = Model.retreat_run(dungeon, campaign.state.active_run.state)
	check(result.status == "accepted" and campaign.checkpoint(dungeon, result.state), kit + " resolver-owned retreat checkpoint")
	var payload: Dictionary = result.event.run_result_payload.duplicate(true)
	payload.run_id = campaign.state.active_run.id
	check(campaign.settle(payload) and campaign.state.equipment == equipment, kit + " expedition return preserves equipment")
	check(campaign.load_profile(path) and campaign.state.active_run.is_empty() and campaign.state.equipment == equipment, kit + " returned expedition restart")
	session.clear()


func _test_managed_victory(campaign: Node, session: Node, kit: String) -> void:
	var path := _prepare(campaign, kit, "managed_victory")
	var equipment: Dictionary = campaign.state.equipment.duplicate(true)
	check(campaign.travel("dungeon_old_mine"), kit + " normal travel before managed expedition")
	var dungeon := Selection.dungeon_for_payload(Selection.authored_payload())
	check(campaign.begin_run(dungeon, Model.initial_state(dungeon)) and session.restore_campaign(), kit + " authored expedition starts")
	var run_state: Dictionary = campaign.state.active_run.state.duplicate(true)
	var entered := Model.enter_room(dungeon, run_state, "dusty_crossing")
	check(entered.status == "accepted", kit + " ordinary room entry")
	var choice := Model.resolve_room_event_choice(dungeon, entered.state, "ignore")
	check(choice.status == "accepted", kit + " ordinary shrine choice")
	entered = Model.enter_room(dungeon, choice.state, "guarded_cache")
	check(entered.status == "accepted" and not entered.state.pending_combat_request.is_empty(), kit + " real guarded room schedules combat")
	check(session.start_combat(dungeon, entered.state, 1234), kit + " managed combat checkpoint")
	check(campaign.load_profile(path) and session.restore_campaign() and session.has_pending_combat_launch(), kit + " restart restores exact pending managed fight")
	var template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(session.combat_encounter_path()))
	var launched: Dictionary = session.apply_launch_metadata(template)
	var expected := "warrior" if kit == "sword_shield" else "bran_greatsword"
	check(actor(launched).visual.character == expected and actor(launched).loadout == equipment[BRAN], kit + " managed fight preserves Bran kit")
	var state: Dictionary = Resolver.simulate(launched, []).state
	var outcome: Dictionary = {}
	var commands := 0
	for n in range(800):
		var active: Dictionary = Actions.unit_by_id(state, state.turn_state.active_unit_id)
		var policy := state.duplicate(true)
		if active.team == "player":
			for row: Dictionary in policy.units:
				row.team = "enemy" if row.team == "player" else "player"
		var command: Dictionary = Resolver.choose_enemy_command(policy, "managed_identity_%s" % n)
		outcome = Resolver.simulate(state, [command])
		state = outcome.state
		commands += 1
		for event: Dictionary in state.event_log:
			check(event.type != "command_rejected", kit + " managed legal command%s" % n)
		if outcome.result != "in_progress":
			break
	check(outcome.get("result") == "victory", kit + " managed legal AI victory")
	check(session.finish_combat(outcome.get("result_payload", {})), kit + " managed authoritative battle return")
	check(campaign.load_profile(path) and session.restore_campaign() and Model.room_is_cleared(session.dungeon_state, "guarded_cache"), kit + " won room persists on restart")
	var reward := Model.claim_current_reward(dungeon, session.dungeon_state)
	check(reward.status == "accepted", kit + " earned guarded reward claimed")
	entered = Model.enter_room(dungeon, reward.state, "lower_exit")
	check(entered.status == "accepted" and session.finish_run(dungeon, entered.state, "completed"), kit + " normal exit completes expedition")
	var payload: Dictionary = session.pending_world_return_payload.duplicate(true)
	check(campaign.settle(payload), kit + " completed expedition settlement")
	var returned: Dictionary = campaign.state.duplicate(true)
	check(not campaign.settle(payload) and campaign.state == returned, kit + " return receipt cannot duplicate rewards")
	check(campaign.load_profile(path) and campaign.state.equipment == equipment and campaign.state.active_run.is_empty() and campaign.state.last_return.outcome == "completed", kit + " completed return and gear survive restart")
	check(campaign.state.items.count("rusty_key") == 1 and campaign.state.xp == 12 and campaign.state.gold == 47, kit + " actual guarded reward paid once")
	battles.append({"kit":kit, "kind":"managed_expedition", "result":outcome.get("result"), "commands":commands, "debug_win":false, "return_accepted":campaign.state.active_run.is_empty(), "expedition_outcome":campaign.state.last_return.outcome})
	session.clear()
