extends SceneTree
const Campaign := preload("res://scripts/session/campaign_session.gd")
const Travel := preload("res://scripts/domain/world_travel.gd")
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func frames() -> void:
	for frame in range(5): await process_frame
func _run() -> void:
	var data := Travel.region()
	check(data.provinces.size() == 4 and data.nodes.size() == 20,"four populated provinces and twenty destinations")
	var campaign := Campaign.new()
	campaign.load_profile("",true)
	var original := campaign.state.duplicate(true)
	var legacy := Travel.quote(original.world,"dungeon_old_mine")
	check(legacy.time_hours == 6 and legacy.food == 1 and legacy.return_food == 1,"legacy mine road and reserve unchanged")
	for entry: Dictionary in data.nodes:
		check(Travel.return_food(data,entry.id) < 1000,"return town reachable: "+str(entry.id))
		if entry.id == "town_ravenford": continue
		var back := Travel.plan({"location_id":entry.id},"town_ravenford")
		check(back.food == Travel.return_food(data,entry.id) and back.required_food == back.food,"shown return plan is affordable with exactly the reserved food: "+str(entry.id))
		var plan := Travel.plan(original.world,entry.id)
		check(not plan.is_empty() and plan == Travel.plan(original.world,entry.id),"deterministic reachable plan: "+str(entry.id))
		var hours := 0
		var food := 0
		var required := 0
		for road: Dictionary in plan.legs:
			check(Travel.quote({"location_id":road.from},road.to) == road,"every planned leg is an authoritative adjacent quote")
			hours += int(road.time_hours)
			food += int(road.food)
			required = maxi(required,food+int(road.return_food))
		check(hours == plan.time_hours and food == plan.food and required == plan.required_food,"whole-plan totals and prefix return reserve")
	check(campaign.state == original,"planning all destinations is mutation-free")
	check(Travel.plan(original.world,"missing").is_empty() and Travel.plan(original.world,"town_ravenford").is_empty(),"unknown/self plans rejected")
	check(Travel.quote(original.world,"black_keep").is_empty() and not campaign.travel("black_keep") and campaign.state == original,"distant plan cannot bypass adjacent travel validation")
	# Real saved cross-province travel and interrupted continuation.
	var path := "user://qa-world-atlas-%s.json" % Time.get_ticks_usec()
	campaign.load_profile(path)
	campaign.state.supplies.food = 50
	campaign.state.gold = 200
	var plan := Travel.plan(campaign.state.world,"black_keep")
	var committed_food := 0
	var committed_hours := 0
	for road: Dictionary in plan.legs:
		check(campaign.travel(road.to),"commit adjacent leg: "+str(road.to))
		committed_food += int(road.food)
		committed_hours += int(road.time_hours)
		check(campaign.state.supplies.food == 50-committed_food and campaign.state.world.elapsed_hours == committed_hours,"only committed leg charged")
		if not campaign.state.world.pending_event.is_empty():
			var blocked := campaign.state.duplicate(true)
			check(not campaign.travel("town_ravenford") and campaign.state == blocked,"pending event blocks continued travel atomically")
			check(campaign.choose_road_event("pay"),"resolve existing road event before continuing")
	var bytes := FileAccess.get_file_as_string(path)
	var restored := Campaign.new()
	check(restored.load_profile(path) and Campaign.same_data(restored.state,campaign.state) and FileAccess.get_file_as_string(path)==bytes,"remote save reloads without rewriting")
	check(Travel.province_id(restored.state.world.location_id)=="highlands" and restored.state.world.region_id=="region_001","derived province with stable legacy atlas id")
	var return_plan := Travel.plan(restored.state.world,"town_ravenford")
	check(return_plan.food == 3 and return_plan.time_hours == 22,"keep return uses three-food mountain pass instead of four-food fastest road")
	var before := restored.state.duplicate(true)
	restored.save_path="user://missing-atlas-%s/save.json" % Time.get_ticks_usec()
	check(not restored.travel("high_pass") and restored.state==before and FileAccess.get_file_as_string(path)==bytes,"cross-province write failure preserves state and save")
	# Real UI hierarchy, no desktop input/player save.
	var global_campaign := root.get_node("CampaignSession")
	global_campaign.load_profile("",true)
	var app: Control=load("res://scenes/app/App.tscn").instantiate()
	root.add_child(app)
	await frames()
	before=global_campaign.state.duplicate(true)
	app.action_buttons.world_overview.pressed.emit()
	await frames()
	var map := app.find_child("RegionMap",true,false)
	check(map.marker_buttons.size()==4 and app.viewed_province.is_empty(),"world overview has four native province markers")
	map.marker_buttons.highlands.pressed.emit()
	await frames()
	map=app.find_child("RegionMap",true,false)
	check(app.viewed_province=="highlands" and map.marker_buttons.size()==5 and global_campaign.state==before,"province browsing never moves company")
	map.marker_buttons.black_keep.pressed.emit()
	await frames()
	check(app.journey_destination=="black_keep" and app.find_child("JourneyItinerary",true,false)!=null and global_campaign.state==before,"distant selection previews itinerary without mutation")
	app.action_buttons.travel_cancel.pressed.emit()
	await frames()
	map=app.find_child("RegionMap",true,false)
	check(app.journey_destination.is_empty() and map.marker_buttons.black_keep.has_focus() and global_campaign.state==before,"cancel returns focus without mutation")
	map.marker_buttons.black_keep.pressed.emit()
	await frames()
	var first: Dictionary=Travel.plan(global_campaign.state.world,"black_keep").legs[0]
	var stale_confirm: Callable=app.action_buttons.travel_confirm.pressed.get_connections()[0].callable
	app.action_buttons.travel_confirm.pressed.emit()
	await frames()
	check(global_campaign.state.world.location_id==first.to and app.journey_destination=="black_keep","UI confirm travels one leg and retains distant target")
	check(global_campaign.state.world.journey_count==1 and global_campaign.state.world.elapsed_hours==first.time_hours,"one UI confirmation is one saved journey")
	before=global_campaign.state.duplicate(true)
	stale_confirm.call()
	await frames()
	check(global_campaign.state==before,"duplicate stale confirmation cannot advance a second itinerary leg")
	app.action_buttons.company_location.pressed.emit()
	await frames()
	check(app.viewed_province==Travel.province_id(global_campaign.state.world.location_id),"find company uses actual position")
	app.queue_free()
	await frames()
	campaign.free()
	restored.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for failure in failures: push_error(failure)
	print("world_atlas_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
