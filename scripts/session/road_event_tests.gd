extends SceneTree

const Campaign := preload("res://scripts/session/campaign_session.gd")
const Travel := preload("res://scripts/domain/world_travel.gd")
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)


func _result(id: String, victory: bool = true) -> Dictionary:
	return {"result":"victory" if victory else "defeat","combat_id":"roadside_ambush","source_dungeon_id":"road_region_001","source_room_id":id,
		"surviving_players":[{"id":"unit_player_001","hp":7,"max_hp":14},{"id":"unit_player_002","hp":10,"max_hp":10}] if victory else [],
		"defeated_player_ids":[] if victory else ["unit_player_001","unit_player_002"],
		"remaining_enemies":[] if victory else [{"id":"unit_enemy_001","hp":9,"max_hp":9},{"id":"unit_enemy_002","hp":7,"max_hp":7}],
		"defeated_enemy_ids":["unit_enemy_001","unit_enemy_002"] if victory else [],"rewards":{"gold":99999,"xp":99999,"items":["forged"]}}


func _run() -> void:
	var campaign := Campaign.new()
	campaign.load_profile("", true)
	check(campaign.travel("event_broken_cart") and campaign.state.world.pending_event.kind == "cart", "authored cart arrival")
	var before := campaign.state.duplicate(true)
	check(not campaign.travel("town_ravenford") and not campaign.choose_road_event("bogus") and campaign.state == before, "pending/choice guards")
	check(campaign.choose_road_event("salvage"), "cart salvage")
	check(campaign.state.items == ["hero_sword","hero_bow","salvaged_shield","patched_leather"] and campaign.state.world.elapsed_hours == 3, "cart exact reward/time")
	before = campaign.state.duplicate(true)
	check(not campaign.choose_road_event("salvage") and campaign.state == before, "cart duplicate rejected")
	check(campaign.travel("town_ravenford") and campaign.travel("event_broken_cart") and campaign.state.world.pending_event.is_empty(), "cart node not regenerated")
	campaign.load_profile("", true)
	campaign.state.world.seed = 1
	check(campaign.travel("dungeon_old_mine") and campaign.state.world.pending_event.kind == "ambush", "seeded danger produces ambush")
	campaign.state.gold = 0
	before = campaign.state.duplicate(true)
	check(not campaign.choose_road_event("pay") and campaign.state == before, "insufficient toll atomic")
	campaign.state.gold = 40
	check(campaign.choose_road_event("pay") and campaign.state.gold == 35 and campaign.state.world.pending_event.is_empty(), "toll once")
	var path := "user://qa-road-%s.json" % Time.get_ticks_usec()
	campaign.load_profile(path)
	campaign.state.world.seed = 1
	campaign.state.effects.target_effects = {"party_slot_front":{"hp_loss":3,"debuffs":{}}}
	check(campaign.travel("dungeon_old_mine") and campaign.choose_road_event("fight"), "durable fight phase")
	var pending: Dictionary = campaign.state.world.pending_event.duplicate(true)
	var singleton := root.get_node("CampaignSession")
	check(singleton.load_profile(path) and Campaign.same_data(singleton.state.world.pending_event, pending), "resume retains seed/event without charge")
	var session := root.get_node("DungeonRunSession")
	check(session.restore_road_combat() and session.road_combat and session.return_scene_path() == "res://scenes/app/App.tscn", "road session return contract")
	var template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Travel.event_definitions().ambush.encounter_path))
	var launched: Dictionary = session.apply_launch_metadata(template)
	check(launched.seed == pending.seed and launched.units.size() == 4 and launched.units[0].resources.hp == 11, "authored roster/seed/injury handoff")
	var valid := _result(pending.id)
	for invalid in ["context", "duplicate", "negative", "unknown"]:
		var bad := valid.duplicate(true)
		match invalid:
			"context": bad.source_room_id = "wrong"
			"duplicate": bad.surviving_players.append(bad.surviving_players[0].duplicate(true))
			"negative": bad.surviving_players[0].hp = -1
			"unknown": bad.surviving_players[0].id = "other"
		before = singleton.state.duplicate(true)
		check(not session.finish_combat(bad) and singleton.state == before and session.road_combat, "bad payload atomic: " + invalid)
	var bytes := FileAccess.get_file_as_string(path)
	singleton.save_path = "user://qa-missing-road-%s/save.json" % Time.get_ticks_usec()
	before = singleton.state.duplicate(true)
	check(not session.finish_combat(valid) and singleton.state == before and FileAccess.get_file_as_string(path) == bytes and session.road_combat, "road write failure retryable")
	singleton.save_path = path
	check(session.finish_combat(valid) and not session.road_combat, "road victory settlement")
	check(singleton.state.gold == 46 and singleton.state.xp == 3 and singleton.state.items == ["hero_sword","hero_bow","salvaged_blade"] and singleton.state.effects.target_effects.party_slot_front.hp_loss == 7, "authored rewards/absolute injury, not forged delta")
	before = singleton.state.duplicate(true)
	check(not singleton.finish_road_combat(valid) and singleton.state == before, "road return duplicate blocked")
	campaign.load_profile("", true)
	campaign.state.world.seed = 1
	campaign.travel("dungeon_old_mine")
	campaign.choose_road_event("fight")
	check(campaign.finish_road_combat(_result(campaign.state.world.pending_event.id, false)), "defeat settlement")
	check(campaign.state.gold == 40 and campaign.state.items == ["hero_sword","hero_bow"] and campaign.state.effects.target_effects.party_slot_front.hp_loss == 13 and not campaign.state.effects.target_effects.party_slot_front.incapacitated, "defeat no loot, fallen recover1HP")
	singleton.load_profile("", true)
	singleton.state.world.seed = 1
	singleton.travel("dungeon_old_mine")
	var app: Control = load("res://scenes/app/App.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(app.action_buttons.has("event_fight") and app.action_buttons.prepare.disabled, "pending ambush visible/gated")
	app.action_buttons.event_pay.pressed.emit()
	await process_frame
	check(singleton.state.gold == 35 and singleton.state.world.pending_event.is_empty(), "actual toll control")
	app.queue_free()
	await process_frame
	campaign.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for failure in failures:
		push_error(failure)
	print("road_event_tests: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
