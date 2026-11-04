extends Node
## Real GPU rendering and engine-local pointer events. Never OS input or saves.
var viewport: SubViewport
var app: Control
var output := ""
var views := "stash"
var sizes := "1920x1080"
var exercise := false
var errors: Array[String] = []
var clicks := 0
var captures: Array[Dictionary] = []
var checks: Array[Dictionary] = []
var root: Window
func _ready() -> void:
	root=get_tree().root
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-output="): output=arg.trim_prefix("--review-output=")
		if arg.begins_with("--review-views="): views=arg.trim_prefix("--review-views=")
		if arg.begins_with("--review-sizes="): sizes=arg.trim_prefix("--review-sizes=")
		if arg=="--review-exercise": exercise=true
	_run.call_deferred()
func frames(count: int = 6) -> void:
	for frame in range(count): await get_tree().process_frame
func check(ok: bool,message: String) -> void:
	checks.append({"pass":ok,"scenario":message})
	if not ok: errors.append(message)
func click(button: Button) -> void:
	if not is_instance_valid(button):
		check(false,"native click target exists")
		return
	check(not button.disabled,"enabled native click: "+button.text)
	if button.disabled: return
	var ancestor := button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(button)
			await frames(2)
		ancestor=ancestor.get_parent()
	# in_local_coords=true expects the logical canvas coordinates under override.
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position=point
	motion.global_position=point
	viewport.push_input(motion,true)
	await frames(2)
	var hovered:=viewport.gui_get_hovered_control()
	if hovered!=button and (hovered==null or not button.is_ancestor_of(hovered)):
		print("NATIVE_HIT_TRACE ",button.text," at ",point," hovered=",hovered.get_path() if hovered!=null else "none"," button=",button.get_path())
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position=point
		event.global_position=point
		event.button_index=MOUSE_BUTTON_LEFT
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed=pressed
		viewport.push_input(event,true)
		await frames(2)
	clicks+=1
	await frames()
func capture(tab: String,pixels: Vector2i) -> void:
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	var file := "%s/%s-%sx%s.png" % [output,tab,pixels.x,pixels.y]
	check(image!=null and not image.is_empty(),"native image: "+tab)
	if image!=null:
		check(image.save_png(file)==OK,"save native image: "+tab)
		captures.append({"view":tab,"pixels":[pixels.x,pixels.y],"logical_size":[int(app.size.x),int(app.size.y)],"file":file})
func _run() -> void:
	await frames(2)
	root.mode=Window.MODE_MINIMIZED
	check(DisplayServer.get_name()!="headless","native display backend")
	check(ProjectSettings.get_setting("display/window/size/no_focus",false),"no-focus before window creation")
	check(not root.has_focus() and root.mode==Window.MODE_MINIMIZED,"native host stays minimized and unfocused")
	var campaign := root.get_node("CampaignSession")
	for dimensions in sizes.split(","):
		var values:=dimensions.split("x")
		var pixels:=Vector2i(int(values[0]),int(values[1]))
		campaign.load_profile("",true)
		campaign.state.items.append_array(["generated_old_mine_trinket","generated_old_mine_trinket","patched_leather","rusty_key","salvaged_blade","salvaged_shield"])
		campaign.state.xp=35
		viewport=SubViewport.new()
		viewport.size=pixels
		viewport.size_2d_override=Vector2i(2560,1440) if pixels.x>=1920 else pixels
		viewport.size_2d_override_stretch=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		viewport.gui_disable_input=false
		root.add_child(viewport)
		app=load("res://scenes/app/App.tscn").instantiate()
		viewport.add_child(app)
		await frames(12)
		for tab in views.split(","):
			if tab=="living":
				await exercise_living(campaign,pixels)
				continue
			if tab=="atlas":
				await exercise_atlas(campaign,pixels)
				continue
			if tab=="gear":
				await exercise_equipment(campaign,pixels)
				continue
			await click(app.shell.nav_buttons[tab])
			check(app.shell.selected_tab==tab,"native navigation: "+tab)
			if app.shell.selected_tab!=tab:
				await capture("navigation-failed-"+tab,pixels)
				continue
			if tab=="stash":
				var inventory:=app.find_child("InventoryView",true,false)
				await click(inventory.grid.item_buttons.salvaged_blade)
				check(app.inventory_item_id=="salvaged_blade","native inventory selection")
			if tab=="training":
				for label: Label in app.shell.content.find_children("*","Label",true,false):
					if label.text in ["Strength","Defense","Accuracy"]:
						check(label.size.x >= label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x,"native training word has usable width: "+label.text)
			await capture(tab,pixels)
		if exercise: await exercise_campaign(campaign,pixels)
		app.queue_free()
		viewport.queue_free()
		await frames()
	check(not root.has_focus(),"no focus acquired during review")
	var report: Dictionary={"status":"PASS" if errors.is_empty() else "FAIL","kind":"native GPU render and engine-local pointer fixture","display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"window_minimized":root.mode==Window.MODE_MINIMIZED,"window_focused":root.has_focus(),"uses_desktop_input":false,"player_save_used":false,"engine_clicks":clicks,"captures":captures,"checks":checks,"failures":errors}
	var file:=FileAccess.open(output+"/native-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	for message in errors: push_error(message)
	print("Native campaign review: ",checks.size()," checks, ",errors.size()," failures")
	await frames(2)
	get_tree().quit(0 if errors.is_empty() else 1)

func pointer(point: Vector2) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.position=point;motion.global_position=point
	viewport.push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=point;event.global_position=point
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		viewport.push_input(event,true)
		await frames(2)
	clicks+=1
	await frames()

func embedded_route(path: String) -> void:
	app.queue_free()
	await frames(2)
	app=load(path).instantiate()
	if app.has_signal("scene_requested"): app.scene_requested.connect(embedded_route)
	viewport.add_child(app)
	await frames(12)

func living_travel(id: String,campaign: Node) -> void:
	await click(app.map.site_buttons[id])
	await click(app.buttons.speed_4)
	for iteration in range(300):
		await frames(2)
		if not campaign.state.world.pending_event.is_empty():
			await click(app.buttons.event_pay)
			await click(app.buttons.speed_4)
		if campaign.state.living_world.party.path.is_empty(): break
	await click(app.buttons.pause)
	check(load("res://scripts/domain/living_world.gd").at_site(campaign.state.living_world,id),"native continuous arrival: "+id)

func exercise_living(campaign: Node,pixels: Vector2i) -> void:
	await embedded_route("res://scenes/world/LivingWorld.tscn")
	check(campaign.living_active() and app.speed==0,"native living pilot starts paused in memory")
	check(app.map.get_global_rect().end.x<=app.side.get_global_rect().position.x,"native map and inspector have independent bounds")
	check(app.header_label.get_global_rect().end.y<180 and app.stock_label.get_line_count()<=2,"native header stock fits two readable lines")
	check(app.map.size.y>=app.size.y*.5,"native living map retains at least half the viewport height")
	check(app.tabs.get_tab_bar().get_tab_rect(2).end.x<=app.tabs.get_tab_bar().size.x,"native inspector tabs all fit")
	for button: Button in app.map.site_buttons.values():
		check(Rect2(Vector2.ZERO,app.map.size).encloses(button.get_rect()),"living-map label stays inside map")
	var original: Dictionary=campaign.state.duplicate(true)
	await frames(24)
	check(campaign.state==original,"paused native world does not mutate time or actors")
	await capture("living-paused",pixels)
	await click(app.buttons.food)
	check(campaign.state.gold==78 and campaign.state.supplies.food==17,"native shortage food quote equals purchase")
	var bar: TabBar=app.tabs.get_tab_bar()
	await pointer(bar.get_global_position()+bar.get_tab_rect(1).get_center())
	check(app.tabs.current_tab==1,"native contract-tab pointer input")
	await click(app.buttons.accept_restore_mine)
	check(campaign.state.living_world.contracts.restore_mine.stage=="accepted","native mine threat contract accepted at issuer")
	await capture("living-contract",pixels)
	bar=app.tabs.get_tab_bar()
	await pointer(bar.get_global_position()+bar.get_tab_rect(0).get_center())
	await click(app.map.site_buttons.dungeon_old_mine)
	check(not campaign.state.living_world.party.path.is_empty() and app.speed==1,"native map sets a continuous path without teleport")
	await capture("living-course",pixels)
	for pressed in [true,false]:
		var key:=InputEventKey.new()
		key.keycode=KEY_SPACE;key.pressed=pressed
		viewport.push_input(key,true)
		await frames(2)
	check(app.speed==0,"Space pauses even when a map Button owns focus")
	original=campaign.state.duplicate(true)
	var sea: Vector2=app.map.get_global_position()+app.map.paper_rect().position+app.map.paper_rect().size*Vector2(.94,.9)
	await pointer(sea)
	check(campaign.state==original and app.speed==0,"native sea click rejects without mutation")
	await living_travel("dungeon_old_mine",campaign)
	check(app.buttons.food.disabled and not app.buttons.prepare.disabled,"actual mine arrival gates provisions and opens managed preparation")
	await capture("living-mine-arrival",pixels)
	original=campaign.state.duplicate(true)
	await click(app.buttons.stash)
	check(app.get_script().resource_path.ends_with("/app.gd") and app.inventory_view,"native pilot opens existing equipment scene")
	check(campaign.state==original,"equipment is a paused view over existing campaign")
	await click(app.shell.nav_buttons.region)
	check(app.get_script().resource_path.ends_with("/living_world_view.gd") and app.speed==0,"native equipment Map returns to paused living company")
	await click(app.buttons.prepare)
	check(app.get_script().resource_path.ends_with("/dungeon_debug.gd") and root.get_node("DungeonRunSession").town_preparation,"native mine entry uses existing owned-supply preparation")
	await capture("living-mine-packing",pixels)
	var start: Button=null
	for button: Button in app.find_children("*","Button",true,false):
		if button.text=="Start Expedition": start=button
	check(start!=null,"native owned packing Start exists")
	if start!=null: await click(start)
	check(not campaign.state.active_run.is_empty(),"native Start creates normal managed campaign receipt")
	await click(app.retreat_button)
	await frames(16)
	check(app.get_script().resource_path.ends_with("/living_world_view.gd") and campaign.state.active_run.is_empty(),"native retreat settles and returns through App to living world")
	check(campaign.state.living_world.mine.status=="occupied" and campaign.state.living_world.contracts.restore_mine.stage=="accepted","ordinary retreat does not falsely clear mine or award contract")
	await capture("living-retreat",pixels)
	await living_travel("town_ravenford",campaign)
	await click(app.buttons.camp)
	await frames(36)
	await click(app.buttons.pause)
	check(campaign.state.living_world.party.camping,"native camp command establishes actual timed camp")
	await capture("living-camp",pixels)
	# World activity continues independently while the company camps.
	await click(app.buttons.speed_4)
	await frames(180)
	await click(app.buttons.pause)
	check(campaign.state.living_world.deliveries+campaign.state.living_world.raids>0,"native live time produces independent caravan activity")
	bar=app.tabs.get_tab_bar()
	await pointer(bar.get_global_position()+bar.get_tab_rect(2).get_center())
	await capture("living-chronicle",pixels)
	await click(app.buttons.speed_4)
	for iteration in range(600):
		await frames(4)
		if int(campaign.state.living_world.politics.skirmishes)>0: break
	await click(app.buttons.pause)
	check(campaign.state.living_world.politics.phase=="border_war" and campaign.state.living_world.politics.skirmishes>0,"native elapsed days move faction patrols into a real border clash")
	check(campaign.state.living_world.factions.iron_march.strength<80 and campaign.state.living_world.factions.river_league.strength<80,"native faction contact changes actual strength")
	await capture("living-border-conflict",pixels)

func exercise_atlas(campaign: Node,pixels: Vector2i) -> void:
	var travel := preload("res://scripts/domain/world_travel.gd")
	campaign.load_profile("",true)
	campaign.state.supplies.food=30
	campaign.state.gold=200
	app._navigate("region")
	await frames()
	var before: Dictionary=campaign.state.duplicate(true)
	await click(app.action_buttons.world_overview)
	var map:=app.find_child("RegionMap",true,false)
	check(map.marker_buttons.size()==4,"native world contains four province markers")
	await capture("atlas-world",pixels)
	for province: String in ["marches","blackwood","highlands","coast"]:
		map=app.find_child("RegionMap",true,false)
		await click(map.marker_buttons[province])
		check(app.viewed_province==province and campaign.state==before,"native province browsing is free: "+province)
		map=app.find_child("RegionMap",true,false)
		check(map.marker_buttons.size()==5,"five native destination controls: "+province)
		var markers: Array=map.marker_buttons.values()
		for index in range(markers.size()):
			var button: Button=markers[index]
			check(Rect2(Vector2.ZERO,map.size).encloses(button.get_rect()),"map label inside bounds: "+button.text)
			var lines:=button.text.split("\n")
			for line in lines:
				check(button.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x+14<=button.size.x,"map label text fits: "+line)
			for other in range(index+1,markers.size()):
				check(not button.get_rect().intersects(markers[other].get_rect()),"native marker labels do not overlap")
		await capture("atlas-"+province,pixels)
		await click(app.action_buttons.world_overview)
	map=app.find_child("RegionMap",true,false)
	await click(map.marker_buttons.highlands)
	map=app.find_child("RegionMap",true,false)
	# Keyboard goes through the native focused Button, not a callback invocation.
	map.marker_buttons.black_keep.grab_focus()
	for pressed in [true,false]:
		var key:=InputEventKey.new()
		key.keycode=KEY_ENTER
		key.pressed=pressed
		viewport.push_input(key,true)
		await frames(2)
	await frames()
	check(app.journey_destination=="black_keep" and campaign.state==before,"native keyboard selection previews distant route without mutation")
	await capture("atlas-itinerary",pixels)
	await click(app.action_buttons.travel_cancel)
	check(campaign.state==before and app.journey_destination.is_empty(),"native distant cancel leaves campaign unchanged")
	map=app.find_child("RegionMap",true,false)
	await click(map.marker_buttons.black_keep)
	for leg in range(12):
		if campaign.state.world.location_id=="black_keep": break
		var plan: Dictionary=travel.plan(campaign.state.world,"black_keep")
		var next: Dictionary=plan.legs[0]
		var hours:=int(campaign.state.world.elapsed_hours)
		var count:=int(campaign.state.world.journey_count)
		await click(app.action_buttons.travel_confirm)
		check(campaign.state.world.location_id==next.to and campaign.state.world.elapsed_hours==hours+int(next.time_hours) and campaign.state.world.journey_count==count+1,"native itinerary advances exactly one adjacent leg")
		if not campaign.state.world.pending_event.is_empty():
			check(not app.action_buttons.has("travel_confirm"),"native road event suspends itinerary confirmation")
			await capture("atlas-road-event",pixels)
			await click(app.action_buttons.event_pay)
	check(campaign.state.world.location_id=="black_keep" and app.journey_destination.is_empty(),"native multi-province journey reaches final destination")
	check(app.action_buttons.town.disabled and app.action_buttons.prepare.disabled,"remote keep has no invented town or dungeon service")
	await click(app.action_buttons.company_location)
	check(app.viewed_province=="highlands","native find company returns actual province")
	await capture("atlas-arrived",pixels)
	# Prove the displayed return is playable with exactly the retained reserve.
	campaign.state.supplies.food=travel.return_food(travel.region(),"black_keep")
	await click(app.action_buttons.province_marches)
	map=app.find_child("RegionMap",true,false)
	await click(map.marker_buttons.town_ravenford)
	await capture("atlas-return-plan",pixels)
	check(travel.plan(campaign.state.world,"town_ravenford").food==3,"native return plan uses exactly the three-food reserve")
	for leg in range(12):
		if campaign.state.world.location_id=="town_ravenford": break
		var next: Dictionary=travel.plan(campaign.state.world,"town_ravenford").legs[0]
		var food:=int(campaign.state.supplies.food)
		await click(app.action_buttons.travel_confirm)
		check(campaign.state.world.location_id==next.to and campaign.state.supplies.food==food-int(next.food),"native return advances one provision-safe leg")
		if not campaign.state.world.pending_event.is_empty(): await click(app.action_buttons.event_pay)
	check(campaign.at_town() and campaign.state.supplies.food==0 and app.journey_destination.is_empty(),"native global return succeeds with exactly reserved provisions")
	check(not app.action_buttons.town.disabled,"town services reopen only after actual global return")
	await click(app.action_buttons.company_location)
	await capture("atlas-returned",pixels)
func exercise_campaign(campaign: Node,pixels: Vector2i) -> void:
	await click(app.shell.nav_buttons.stash)
	var inventory:=app.find_child("InventoryView",true,false)
	var gear:=app.find_child("EquipmentView",true,false)
	await click(inventory.grid.item_buttons.salvaged_blade)
	await click(gear.equip_button)
	check(campaign.state.equipment.unit_player_001.main_hand=="salvaged_blade","native equip mutates trusted gear")
	await capture("stash-equipped",pixels)
	gear=app.find_child("EquipmentView",true,false)
	await click(gear.unequip_button)
	check(campaign.state.equipment.unit_player_001.main_hand==null,"native unequip clears assigned slot")
	gear=app.find_child("EquipmentView",true,false)
	await click(gear.equip_button)
	await click(app.shell.nav_buttons.trade)
	var trade:=app.find_child("TradingView",true,false)
	await click(trade.buy_grid.item_buttons.patched_leather)
	var before:=int(campaign.state.gold)
	await click(trade.buy_button)
	check(int(campaign.state.gold)<before,"native buy transaction")
	trade=app.find_child("TradingView",true,false)
	await click(trade.sell_grid.item_buttons.generated_old_mine_trinket)
	before=int(campaign.state.gold)
	var copies: int = campaign.state.items.count("generated_old_mine_trinket")
	await click(trade.sell_button)
	check(int(campaign.state.gold)>before and campaign.state.items.count("generated_old_mine_trinket")==copies-1,"native free loot sale transaction")
	await click(app.shell.nav_buttons.town)
	var food:=int(campaign.state.supplies.food)
	await click(app.action_buttons.buy_food)
	check(int(campaign.state.supplies.food)==food+1,"native provisioner tile purchase")
	await click(app.shell.nav_buttons.training)
	var training:=app.find_child("TrainingView",true,false)
	await click(training.train_buttons.unit_player_001)
	check(campaign.state.advancement.unit_player_001==2,"native training transaction")
	await click(app.shell.nav_buttons.region)
	var map:=app.find_child("RegionMap",true,false)
	var before_journey: Dictionary=campaign.state.duplicate(true)
	await click(map.marker_buttons.dungeon_old_mine)
	check(campaign.state==before_journey,"native Old Mine preview preserves campaign")
	await capture("region-journey",pixels)
	await click(app.action_buttons.travel_cancel)
	check(campaign.state==before_journey,"native plan cancellation is free")
	map=app.find_child("RegionMap",true,false)
	await click(map.marker_buttons.event_broken_cart)
	check(campaign.state==before_journey,"native journey preview spends no time/food or risk seed")
	await capture("region-plan",pixels)
	await click(app.action_buttons.travel_confirm)
	check(campaign.state.world.pending_event.get("kind")=="cart","native landmark travel opens real event")
	await capture("region-event",pixels)
	await click(app.action_buttons.event_help)
	map=app.find_child("RegionMap",true,false)
	await click(map.marker_buttons.town_ravenford)
	await click(app.action_buttons.travel_confirm)
	check(campaign.state.world.location_id=="town_ravenford","native road event return")


func exercise_equipment(campaign: Node,pixels: Vector2i) -> void:
	campaign.state.items.append_array(["leather_boots","steel_boots","leather_cap","closed_helm","weathered_cuirass"])
	await click(app.shell.nav_buttons.stash)
	var effects: Dictionary=campaign.state.effects.duplicate(true)
	for id: String in ["patched_leather","leather_boots","leather_cap","weathered_cuirass","steel_boots","closed_helm","salvaged_shield"]:
		var inventory:=app.find_child("InventoryView",true,false)
		await click(inventory.grid.item_buttons[id])
		var gear:=app.find_child("EquipmentView",true,false)
		await click(gear.equip_button)
		gear=app.find_child("EquipmentView",true,false)
		var item: Dictionary=load("res://scripts/domain/item_catalog.gd").item(id)
		check(campaign.state.equipment.unit_player_001[item.combat_profile.slot]==id,"native five-slot equip: "+id)
		check(gear.hero_portrait.texture!=null and gear.find_child("EquippedActorPreview",true,false)==null,"retained illustrated portrait and no rejected3D preview: "+id)
		await frames(6)
	await capture("gear-all-slots",pixels)
	for slot: String in ["armor","boots","helmet","off_hand"]:
		var gear:=app.find_child("EquipmentView",true,false)
		await click(gear.slot_buttons[slot]);gear=app.find_child("EquipmentView",true,false)
		await click(gear.unequip_button)
		check(campaign.state.equipment.unit_player_001[slot]==null,"native five-slot unequip: "+slot)
	var gear:=app.find_child("EquipmentView",true,false)
	await click(gear.hero_buttons.unit_player_002);gear=app.find_child("EquipmentView",true,false)
	await click(gear.slot_buttons.main_hand);gear=app.find_child("EquipmentView",true,false)
	await click(gear.unequip_button)
	gear=app.find_child("EquipmentView",true,false)
	await click(gear.hero_buttons.unit_player_001)
	var inventory:=app.find_child("InventoryView",true,false)
	await click(inventory.grid.item_buttons.hero_bow);gear=app.find_child("EquipmentView",true,false)
	await click(gear.equip_button);gear=app.find_child("EquipmentView",true,false)
	check(campaign.state.equipment.unit_player_001.main_hand=="hero_bow" and gear.hero_portrait.texture.resource_path.ends_with("/bran.png"),"weapon transfer retains hero portrait without rejected3D preview")
	check(campaign.state.effects==effects,"native equipment changes preserve wounds")
	await capture("gear-bran-bow",pixels)
