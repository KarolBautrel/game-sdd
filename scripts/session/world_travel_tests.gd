extends SceneTree

const Campaign := preload("res://scripts/session/campaign_session.gd")
const Travel := preload("res://scripts/domain/world_travel.gd")
const Selection := preload("res://scripts/domain/dungeon_entry_selection.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)


func _run() -> void:
	var campaign := Campaign.new()
	campaign.load_profile("", true)
	check(campaign.state.version == 4 and campaign.at_town(), "new-game v4 town")
	var before := campaign.state.duplicate(true)
	check(not campaign.travel("missing") and campaign.state == before, "bad route atomic")
	campaign.state.supplies.food = 1
	before = campaign.state.duplicate(true)
	check(not campaign.travel("dungeon_old_mine") and campaign.state == before, "return reserve rejected")
	campaign.state.supplies.food = 3
	check(campaign.travel("dungeon_old_mine"), "outward travel")
	check(campaign.state.world.location_id == "dungeon_old_mine" and campaign.state.world.elapsed_hours == 6 and campaign.state.supplies.food == 2 and campaign.state.world.journey_count == 1, "exact outward cost")
	before = campaign.state.duplicate(true)
	check(not campaign.travel("dungeon_old_mine") and not campaign.purchase("food") and not campaign.recover() and campaign.state == before, "same destination and remote services blocked")
	var data := Selection.dungeon_for_payload(Selection.default_payload())
	var state := Model.initial_state(data)
	state.selected_supply_loadout.food = 2
	state.selected_supply_loadout.bandage = 0
	state.supplies = state.selected_supply_loadout.duplicate(true)
	check(not campaign.begin_run(data, state) and campaign.last_feedback.contains("return"), "packing keeps reserve")
	check(campaign.travel("town_ravenford"), "reverse road")
	check(campaign.state.world.elapsed_hours == 12 and campaign.state.supplies.food == 1 and campaign.at_town(), "exact reverse cost")
	var path := "user://qa-travel-%s.json" % Time.get_ticks_usec()
	var legacy := Campaign.initial_profile()
	legacy.version = 1
	legacy.erase("world")
	legacy.gold = 77
	legacy.items = ["legacy_relic", "legacy_relic"]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var bytes := FileAccess.get_file_as_string(path)
	check(campaign.load_profile(path), "legacy migration")
	check(campaign.state.version == 4 and campaign.state.gold == 77 and campaign.state.items == legacy.items + ["hero_sword", "hero_bow"] and FileAccess.get_file_as_string(path) == bytes, "load migration preserves progress/file")
	check(campaign.travel("dungeon_old_mine"), "migration commit")
	var restored := Campaign.new()
	check(restored.load_profile(path) and Campaign.same_data(restored.state, campaign.state), "world state durable")
	before = restored.state.duplicate(true)
	bytes = FileAccess.get_file_as_string(path)
	restored.save_path = "user://missing-qa-travel-%s/save.json" % Time.get_ticks_usec()
	check(not restored.travel("town_ravenford") and restored.state == before and FileAccess.get_file_as_string(path) == bytes, "travel write failure rollback")
	var global_campaign := root.get_node("CampaignSession")
	global_campaign.load_profile("", true)
	var app: Control = load("res://scenes/app/App.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(app.find_child("RegionMap", true, false) != null and app.action_buttons.prepare.disabled and not app.action_buttons.town.disabled, "map and location gates")
	app.action_buttons.travel_dungeon_old_mine.pressed.emit()
	await process_frame
	check(global_campaign.state.world.location_id == "dungeon_old_mine" and not app.action_buttons.prepare.disabled and app.action_buttons.town.disabled, "actual travel control")
	app.queue_free()
	await process_frame
	campaign.free()
	restored.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for failure in failures:
		push_error(failure)
	print("world_travel_tests: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
