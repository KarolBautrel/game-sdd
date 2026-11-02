extends SceneTree

const Campaign := preload("res://scripts/session/campaign_session.gd")
const Gear := preload("res://scripts/domain/campaign_equipment.gd")
const Items := preload("res://scripts/domain/item_catalog.gd")
const Resolver := preload("res://scripts/domain/combat_resolver.gd")
const Travel := preload("res://scripts/domain/world_travel.gd")
const Selection := preload("res://scripts/domain/dungeon_entry_selection.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const BRAN := "unit_player_001"
const TORIN := "unit_player_002"
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func unit(data: Dictionary, id: String) -> Dictionary:
	for row: Dictionary in data.units:
		if row.id == id:
			return row
	return {}


func event(result: Dictionary, type: String) -> Dictionary:
	for row: Dictionary in result.state.event_log:
		if row.type == type:
			return row
	return {}


func command(action: String, actor: String = BRAN, target: String = "unit_enemy_001") -> Dictionary:
	return {"id":"gear_test_1","type":"perform_action","actor_id":actor,"action_id":action,"target":{"type":"unit","unit_id":target}}


func _run() -> void:
	var path := "user://qa-gear-%s.json" % Time.get_ticks_usec()
	var campaign := Campaign.new()
	for version in [1, 2]:
		var legacy := Campaign.initial_profile()
		legacy.version = version
		legacy.erase("equipment")
		if version == 1:
			legacy.erase("world")
		legacy.items = ["legacy_relic", "legacy_relic", "hero_sword"]
		legacy.gold = 83
		legacy.effects.target_effects = {"party_slot_front":{"hp_loss":3,"debuffs":{}}}
		write(path, legacy)
		var bytes := FileAccess.get_file_as_string(path)
		check(campaign.load_profile(path), "load legacy %s" % version)
		check(campaign.state.version == 4 and campaign.state.items == legacy.items + ["hero_bow"] and campaign.state.gold == 83 and Campaign.same_data(campaign.state.effects,legacy.effects) and campaign.state.equipment == Gear.defaults(), "preserve loot/injury and grant missing starter only")
		check(FileAccess.get_file_as_string(path) == bytes, "no load-time rewrite")
		check(campaign.equip(BRAN, "main_hand", null), "migration commit")
		check(campaign.load_profile(path) and campaign.state.items.count("hero_sword") == 1 and campaign.state.equipment[BRAN].main_hand == null, "v3 reload does not regrant/re-equip")
	var corrupt := Campaign.initial_profile()
	corrupt.items = []
	write(path, corrupt)
	check(not campaign.load_profile(path) and not campaign.equip(BRAN,"main_hand",null), "invalid owned v3 blocked")
	campaign.load_profile("", true)
	campaign.state.items.append_array(["salvaged_blade", "salvaged_shield", "patched_leather"])
	campaign.state.effects.target_effects = {"party_slot_front":{"hp_loss":3,"debuffs":{}}}
	var before := campaign.state.duplicate(true)
	for args in [["unknown","armor","patched_leather"],[BRAN,"unknown","hero_sword"],[BRAN,"armor","hero_sword"],[BRAN,"main_hand","unknown"],[BRAN,"main_hand","old_mine_blade"],[TORIN,"main_hand","hero_sword"],[TORIN,"off_hand","salvaged_shield"]]:
		check(not campaign.equip(args[0],args[1],args[2]) and campaign.state == before, "invalid equip atomic: %s" % str(args))
	check(campaign.equip(BRAN,"main_hand",null) and campaign.equip(TORIN,"main_hand","hero_sword") and campaign.equip(BRAN,"main_hand","hero_bow"), "transfer owned weapons after unequip")
	check(campaign.state.effects == before.effects and campaign.state.items == before.items, "equip never heals or consumes inventory")
	check(not campaign.equip(BRAN,"off_hand","salvaged_shield"), "two handed blocks shield")
	check(campaign.equip(BRAN,"main_hand","salvaged_blade") and campaign.equip(BRAN,"off_hand","salvaged_shield") and campaign.equip(BRAN,"armor","patched_leather"), "all three slots equipped")
	before = campaign.state.duplicate(true)
	check(not campaign.equip(BRAN,"main_hand","hero_bow") and campaign.state == before, "reverse two-handed conflict atomic")
	campaign.memory_only = false
	campaign.save_path = "user://missing-gear-%s/save.json" % Time.get_ticks_usec()
	check(not campaign.equip(BRAN,"armor",null) and campaign.state == before, "failed save rollback")
	campaign.save_path = path
	check(campaign.equip(BRAN,"armor","patched_leather") and campaign.load_profile(path) and Campaign.same_data(campaign.state,before), "gear durable")
	var singleton := root.get_node("CampaignSession")
	check(singleton.load_profile(path), "managed fixture load")
	var data := Selection.dungeon_for_payload(Selection.default_payload())
	var run_state := Model.initial_state(data)
	check(singleton.travel("dungeon_old_mine") and singleton.begin_run(data,run_state), "managed begin")
	check(singleton.state.active_run.equipment_snapshot == singleton.state.equipment, "frozen run gear")
	before = singleton.state.duplicate(true)
	check(not singleton.equip(BRAN,"armor",null) and singleton.state == before, "active run lock")
	check(singleton.load_profile(path), "active snapshot restart")
	var session := root.get_node("DungeonRunSession")
	check(session.restore_campaign(), "restore managed session")
	var template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Travel.event_definitions().ambush.encounter_path))
	session.pending_combat_request = {"dungeon_id":data.id,"room_id":"gear_fixture","dungeon_modifiers":singleton.state.active_run.state.duplicate(true)}
	session.next_combat_seed = 1234
	var launched: Dictionary = session.apply_launch_metadata(template)
	var dungeon_template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json"))
	check(Campaign.same_data(Items.item("hero_sword").combat_profile, dungeon_template.item_profiles.hero_sword), "starter preserves authored managed sword balance")
	check(unit(launched,BRAN).loadout == singleton.state.equipment[BRAN] and unit(launched,BRAN).resources.hp == 11 and unit(launched,BRAN).stats.max_hp == 14, "gear handoff preserves injuries/stats")
	check(launched.item_profiles.salvaged_blade == Items.item("salvaged_blade").combat_profile and unit(launched,BRAN).available_actions == ["move","defend","end_turn"], "trusted profiles and base actions")
	# Resolver boundary fixtures: adjacent actors, no result injection.
	unit(launched,BRAN).position = {"x":1,"y":8}
	unit(launched,"unit_enemy_001").position = {"x":2,"y":8}
	launched.turn_state.active_unit_id = BRAN
	var upgraded := Resolver.simulate(launched,[command("basic_attack")])
	var starter := launched.duplicate(true)
	starter.item_profiles.hero_sword = Items.item("hero_sword").combat_profile
	unit(starter,BRAN).loadout.main_hand = "hero_sword"
	var baseline := Resolver.simulate(starter,[command("basic_attack")])
	check(not event(upgraded,"damage_applied").is_empty() and event(upgraded,"damage_applied").damage == event(baseline,"damage_applied").damage + 1, "resolver upgraded sword +1")
	var shield := Resolver.simulate(launched,[command("shield_wall",BRAN,BRAN)])
	check(not event(shield,"status_applied").is_empty() and unit(shield.state,BRAN).resources.ap == 1, "shield grant normal action/cost")
	var incoming := launched.duplicate(true)
	incoming.turn_state.active_unit_id = "unit_enemy_001"
	unit(incoming,"unit_enemy_001").available_actions = ["basic_attack"]
	var armored := Resolver.simulate(incoming,[command("basic_attack","unit_enemy_001",BRAN)])
	unit(incoming,BRAN).loadout.armor = null
	var bare := Resolver.simulate(incoming,[command("basic_attack","unit_enemy_001",BRAN)])
	check(not event(armored,"damage_applied").is_empty() and event(armored,"damage_applied").damage == maxi(1,int(event(bare,"damage_applied").damage)-1), "resolver leather reduction1")
	var no_weapon: Dictionary = singleton.state.equipment.duplicate(true)
	no_weapon[BRAN].main_hand = null
	var empty := Gear.apply(launched,no_weapon)
	check(event(Resolver.simulate(empty,[command("basic_attack")]),"command_rejected").get("reason") == "action_not_available", "unequipped has no stale attacks")
	var swapped: Dictionary = no_weapon.duplicate(true)
	swapped[BRAN].off_hand = null
	swapped[BRAN].main_hand = "hero_bow"
	check(unit(Gear.apply(launched,swapped),BRAN).visual.character == "archer_1", "weapon visual matches transferred bow")
	var broken: Dictionary = singleton.state.duplicate(true)
	broken.active_run.equipment_snapshot[BRAN].armor = null
	write(path,broken)
	check(not campaign.load_profile(path), "changed snapshot blocked")
	# v2 in-progress migration preserves the old default gear contract.
	var legacy_active: Dictionary = singleton.state.duplicate(true)
	legacy_active.version = 2
	legacy_active.erase("equipment")
	legacy_active.active_run.erase("equipment_snapshot")
	write(path,legacy_active)
	check(campaign.load_profile(path) and campaign.state.active_run.equipment_snapshot == Gear.defaults(), "legacy active snapshot migrated")
	session.clear()
	var sandbox: Dictionary = session.apply_launch_metadata(template)
	check(sandbox == template, "sandbox loadout isolated from campaign")
	singleton.load_profile("",true)
	singleton.state.items.append("patched_leather")
	check(singleton.equip(BRAN,"armor","patched_leather"), "road chosen gear")
	singleton.state.world.seed = 1
	check(singleton.travel("dungeon_old_mine") and singleton.choose_road_event("fight"), "road frozen fight")
	check(singleton.state.world.pending_event.equipment_snapshot == singleton.state.equipment and not singleton.equip(BRAN,"armor",null), "road snapshot/lock")
	write(path,singleton.state)
	check(singleton.load_profile(path) and session.restore_road_combat(), "road restart gear resume")
	check(unit(session.apply_launch_metadata(template),BRAN).loadout.armor == "patched_leather", "road launch armor")
	session.clear()
	singleton.load_profile("",true)
	singleton.state.items.append("patched_leather")
	var app: Control = load("res://scenes/app/App.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.action_buttons.inventory.pressed.emit()
	await process_frame
	var view := app.find_child("EquipmentView",true,false)
	before = singleton.state.duplicate(true)
	app.find_child("InventoryView",true,false).grid.item_buttons.patched_leather.pressed.emit()
	check(singleton.state == before, "selection does not persist")
	view.equip_button.pressed.emit()
	await process_frame
	check(singleton.state.equipment[BRAN].armor == "patched_leather", "actual equip control")
	view = app.find_child("EquipmentView",true,false)
	app.find_child("InventoryView",true,false).grid.item_buttons.patched_leather.pressed.emit()
	view.unequip_button.pressed.emit()
	await process_frame
	check(singleton.state.equipment[BRAN].armor == null, "actual unequip control")
	app.queue_free()
	await process_frame
	campaign.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for failure in failures:
		push_error(failure)
	print("campaign_equipment_tests: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
