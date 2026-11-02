extends SceneTree
const Campaign := preload("res://scripts/session/campaign_session.gd")
const Advancement := preload("res://scripts/domain/party_advancement.gd")
const Selection := preload("res://scripts/domain/dungeon_entry_selection.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const Resolver := preload("res://scripts/domain/combat_resolver.gd")
const BRAN := "unit_player_001"
const TORIN := "unit_player_002"
var errors: Array[String] = []
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func write(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

func damage(result: Dictionary) -> int:
	for event: Dictionary in result.state.event_log:
		if event.type == "damage_applied": return int(event.damage)
	return -100

func _run() -> void:
	var path := "user://qa-training-%s.json" % Time.get_ticks_usec()
	var campaign := Campaign.new()
	for version in [1,2,3]:
		var legacy := Campaign.initial_profile()
		legacy.version = version
		legacy.erase("advancement")
		if version == 1: legacy.erase("world")
		legacy.xp = 70
		legacy.items.append("legacy_token")
		write(path,legacy)
		var bytes := FileAccess.get_file_as_string(path)
		check(campaign.load_profile(path) and campaign.state.version == 4 and campaign.state.advancement == Advancement.defaults() and campaign.available_xp() == 70 and campaign.state.items == legacy.items and FileAccess.get_file_as_string(path) == bytes,"legacy %s preserved/no rewrite" % version)
	check(campaign.train(BRAN) and campaign.available_xp() == 60 and campaign.state.xp == 70,"first training exact allocation")
	check(campaign.train(BRAN) and campaign.train(TORIN) and campaign.available_xp() == 30,"shared XP budget")
	var before := campaign.state.duplicate(true)
	check(not campaign.train(BRAN) and not campaign.train("unknown") and campaign.state == before,"budget/unknown atomic")
	check(campaign.load_profile(path) and Campaign.same_data(campaign.state,before),"trained state durable")
	before = campaign.state.duplicate(true)
	campaign.save_path = "user://missing-training-%s/save.json" % Time.get_ticks_usec()
	check(not campaign.train(TORIN) and campaign.state == before,"training write rollback")
	var invalid := before.duplicate(true)
	invalid.xp = 1
	write(path,invalid)
	check(not campaign.load_profile(path),"overallocated v4 blocked")
	for value in [0,5,1.5,true,"2"]:
		var levels := Advancement.defaults()
		levels[BRAN] = value
		check(not Advancement.valid(levels,1000),"bad level rejected")
	campaign.load_profile("",true)
	campaign.state.xp = 1000
	for level in [2,3,4]: check(campaign.train(BRAN),"advance to %s" % level)
	before = campaign.state.duplicate(true)
	check(not campaign.train(BRAN) and campaign.state == before and campaign.available_xp() == 935,"cap no duplicate allocation")
	check(Advancement.stats(BRAN,4).strength == 7 and Advancement.stats(BRAN,4).defense == 2 and Advancement.stats(BRAN,4).max_hp == 14,"effective stats/fixed maxHP")
	var singleton := root.get_node("CampaignSession")
	singleton.load_profile("",true)
	singleton.state.xp = 10
	singleton.state.effects.target_effects = {"party_slot_front":{"hp_loss":3,"debuffs":{}}}
	check(singleton.train(BRAN) and singleton.state.effects.target_effects.party_slot_front.hp_loss == 3,"training never heals")
	check(singleton.travel("dungeon_old_mine") and not singleton.train(TORIN),"remote lock")
	var data := Selection.dungeon_for_payload(Selection.default_payload())
	check(singleton.begin_run(data,Model.initial_state(data)),"managed start")
	check(singleton.state.active_run.advancement_snapshot == singleton.state.advancement and not singleton.train(BRAN),"frozen run training")
	write(path,singleton.state)
	check(singleton.load_profile(path),"run snapshot restart")
	var session := root.get_node("DungeonRunSession")
	check(session.restore_campaign(),"restore trained run")
	session.pending_combat_request = {"dungeon_id":data.id,"room_id":"training_fixture","dungeon_modifiers":singleton.state.active_run.state.duplicate(true)}
	session.next_combat_seed = 1234
	var template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/combat_encounters/roadside_ambush.json"))
	var launched: Dictionary = session.apply_launch_metadata(template)
	check(launched.units[0].stats.strength == 6 and launched.units[0].resources.hp == 11 and launched.units[0].loadout.main_hand == "hero_sword","trained managed stats/injury/gear")
	launched.units[0].position = {"x":1,"y":8}
	launched.units[2].position = {"x":2,"y":8}
	launched.turn_state.active_unit_id = BRAN
	var attack := {"id":"trained_attack","type":"perform_action","actor_id":BRAN,"action_id":"basic_attack","target":{"type":"unit","unit_id":launched.units[2].id}}
	var baseline := launched.duplicate(true)
	baseline.units[0].stats.strength -= 1
	check(damage(Resolver.simulate(launched,[attack])) == damage(Resolver.simulate(baseline,[attack])) + 1,"ordinary resolver trained damage +1")
	var changed: Dictionary = singleton.state.duplicate(true)
	changed.active_run.advancement_snapshot[BRAN] = 1
	write(path,changed)
	check(not campaign.load_profile(path),"snapshot mismatch blocked")
	session.clear()
	check(session.apply_launch_metadata(template) == template,"sandbox isolated")
	singleton.load_profile("",true)
	singleton.state.xp = 10
	singleton.train(BRAN)
	singleton.state.world.seed = 1
	check(singleton.travel("dungeon_old_mine") and singleton.choose_road_event("fight") and session.restore_road_combat(),"trained road entry")
	check(singleton.state.world.pending_event.advancement_snapshot[BRAN] == 2 and session.apply_launch_metadata(template).units[0].stats.strength == 6 and not singleton.train(TORIN),"road snapshot/stats/lock")
	session.clear()
	singleton.load_profile("",true)
	singleton.state.xp = 10
	var app: Control = load("res://scenes/town/town_shell.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.action_buttons.training.pressed.emit()
	await process_frame
	var view := app.find_child("TrainingView",true,false)
	check(view != null and not view.train_buttons[BRAN].disabled,"training UI")
	view.train_buttons[BRAN].pressed.emit()
	await process_frame
	view = app.find_child("TrainingView",true,false)
	check(singleton.state.advancement[BRAN] == 2 and singleton.available_xp() == 0 and view.train_buttons[TORIN].disabled,"actual train/shared budget UI")
	app.queue_free()
	await process_frame
	campaign.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for error in errors: push_error(error)
	print("party_advancement_tests: ",checks," checks, ",errors.size()," failures")
	quit(0 if errors.is_empty() else 1)
