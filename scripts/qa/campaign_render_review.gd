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
var region_motion_frames:=0
var region_motion_samples:=0
var region_motion_violations:=0
var region_bridge_samples:=0
var inspect_region_motion:=false
func _ready() -> void:
	root=get_tree().root
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-output="): output=arg.trim_prefix("--review-output=")
		if arg.begins_with("--review-views="): views=arg.trim_prefix("--review-views=")
		if arg.begins_with("--review-sizes="): sizes=arg.trim_prefix("--review-sizes=")
		if arg=="--review-exercise": exercise=true
	_run.call_deferred()
func frames(count: int = 6) -> void:
	for frame in range(count):
		await get_tree().process_frame
		if inspect_region_motion and is_instance_valid(app) and app.get_script().resource_path.ends_with("/living_world_view.gd"):
			var state: Dictionary=root.get_node("CampaignSession").state.living_world
			var world:=load("res://scripts/domain/living_world.gd")
			var nav: RefCounted=world.navigation(state)
			var ids: Array=["company"]
			for actor: Dictionary in state.actors: ids.append(actor.id)
			for id: String in ids:
				region_motion_samples+=1
				if not nav.passable(app.map.displayed(id)): region_motion_violations+=1
				if id=="company" and nav.code_at(app.map.displayed(id))=="B": region_bridge_samples+=1
			region_motion_frames+=1
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
			if tab=="regions":
				await exercise_regions(campaign,pixels)
				continue
			if tab=="motion":
				await exercise_motion(campaign,pixels)
				continue
			if tab=="terrain":
				await exercise_terrain(campaign,pixels)
				continue
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
	app.map.reveal(load("res://scripts/domain/living_world.gd").point(load("res://scripts/domain/living_world.gd").site(id,campaign.state.living_world).position))
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
	campaign.load_profile("",true)
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
	for iteration in range(1200):
		await frames(4)
		if int(campaign.state.living_world.politics.skirmishes)>0: break
	await click(app.buttons.pause)
	check(campaign.state.living_world.politics.phase=="border_war" and campaign.state.living_world.politics.skirmishes>0,"native elapsed days move faction patrols into a real border clash")
	check(campaign.state.living_world.factions.iron_march.strength<80 and campaign.state.living_world.factions.river_league.strength<80,"native faction contact changes actual strength")
	await capture("living-border-conflict",pixels)

func terrain_drag(from: Vector2,to: Vector2) -> void:
	var first: Vector2=app.canvas.get_global_position()+app.canvas.point(from)
	var last: Vector2=app.canvas.get_global_position()+app.canvas.point(to)
	var down:=InputEventMouseButton.new();down.position=first;down.global_position=first;down.button_index=MOUSE_BUTTON_LEFT;down.button_mask=MOUSE_BUTTON_MASK_LEFT;down.pressed=true
	viewport.push_input(down,true);await frames(2)
	for index in range(1,9):
		var motion:=InputEventMouseMotion.new();motion.position=first.lerp(last,float(index)/8);motion.global_position=motion.position;motion.button_mask=MOUSE_BUTTON_MASK_LEFT
		viewport.push_input(motion,true);await frames(1)
	var up:=InputEventMouseButton.new();up.position=last;up.global_position=last;up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false
	viewport.push_input(up,true);await frames(3);clicks+=1

func exercise_motion(campaign: Node,pixels: Vector2i) -> void:
	var Terrain:=load("res://scripts/domain/terrain_navigation.gd")
	var World:=load("res://scripts/domain/living_world.gd")
	var records: Array=[]
	for rate in [1,2,4]:
		campaign.load_profile("",true);campaign.enable_living_world()
		# Isolated motion measurement holds contact grace, not gameplay rules.
		campaign.state.living_world.encounter_until=99999
		await embedded_route("res://scenes/world/LivingWorld.tscn")
		await click(app.map.site_buttons.saltwatch)
		if rate>1: await click(app.buttons["speed_%d" % rate])
		var previous: Dictionary={}
		var safe:=true;var bounded:=true;var stalled:=0;var moving:=0
		var last_usec: int=Time.get_ticks_usec()
		var previous_clock: float=(float(campaign.state.living_world.tick)+app.map.blend)*.6/rate
		for frame in range(90):
			await frames(1)
			var now: int=Time.get_ticks_usec()
			var wall_delta: float=maxf(.000001,float(now-last_usec)/1000000.0);last_usec=now
			# GPU readback/PNG encoding may run between process_frame and node
			# processing. Bound by the clock actually presented, not wall sampling.
			var clock: float=(float(campaign.state.living_world.tick)+app.map.blend)*.6/rate
			var delta: float=maxf(0,clock-previous_clock);previous_clock=clock
			var positions: Dictionary={}
			for id: String in ["company"]+app.map.actor_buttons.keys():
				var position: Vector2=app.map.displayed(id)
				positions[id]=World.packed(position)
				safe=safe and Terrain.current().passable(position)
				if previous.has(id):
					var distance: float=((position-World.point(previous[id]))*Vector2(16.0/9.0,1)).length()
					var maximum: float=(.045 if id=="company" else .022*1.3)*rate/.6
					bounded=bounded and distance<=maximum*delta*1.8+.00015
					if id=="company" and int(campaign.state.living_world.tick)>2 and not campaign.state.living_world.party.path.is_empty():
						moving+=1
						if distance<.0000001: stalled+=1
			previous=positions
			records.append({"rate":rate,"frame":frame,"delta":delta,"wall_delta":wall_delta,"tick":campaign.state.living_world.tick,"phase":app.map.blend,"positions":positions})
			if rate==1 and frame in [20,45,70]: await capture("smooth-sequence-%02d" % frame,pixels)
		check(safe,"native every-frame company/NPC positions avoid blocked cells / %dx" % rate)
		check(bounded,"native per-frame displacement has no tick-boundary jump / %dx" % rate)
		check(moving>20 and stalled==0,"native moving company has no reset/stall frames / %dx (%d/%d)" % [rate,stalled,moving])
		await click(app.buttons.pause)
		var held: Vector2=app.map.displayed("company")
		var clock: int=int(campaign.state.living_world.tick)
		var phase: float=app.accumulated
		await frames(12)
		check(app.map.displayed("company").is_equal_approx(held) and int(campaign.state.living_world.tick)==clock and app.accumulated==phase,"native pause freezes current visual phase / %dx" % rate)
		await click(app.buttons.speed_2)
		check(app.map.displayed("company").distance_to(held)>.0000001,"native resume continues without a full-tick delay / %dx" % rate)
		await click(app.buttons.pause)
		if rate==4: await capture("smooth-pause-resume",pixels)
	var file:=FileAccess.open(output+"/motion-samples-%sx%s.json" % [pixels.x,pixels.y],FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind":"native per-frame committed-motion sampling","records":records},"\t",true,true));file.close()

func exercise_regions(campaign: Node,pixels: Vector2i) -> void:
	region_motion_frames=0;region_motion_samples=0;region_motion_violations=0;region_bridge_samples=0
	campaign.load_profile("",true);campaign.enable_living_world()
	var original: Dictionary=campaign.state.duplicate(true)
	await embedded_route("res://scenes/world/RegionFoundry.tscn")
	for frame in range(12):
		if not app.busy and not app.geography.is_empty(): break
		await frames(2)
	for item: Array in [[2087,0],[42,1],[170717,2]]:
		app.seed_input.value=item[0];app.preset_input.select(item[1])
		await click(app.buttons.generate)
		await frames(10)
		check(not app.geography.is_empty() and not app.buttons.play.disabled,"native valid generated region")
		check(campaign.same_data(campaign.state,original),"native preview preserves current company")
		await capture("generated-%s-%s" % [item[0],item[1]],pixels)
		check(int(app.geography.version)==2 and app.map.camera.zoom>2,"larger generated preview opens local view")
		await click(app.map.camera_buttons.overview)
		await capture("large-overview-%s-%s" % [item[0],item[1]],pixels)
		await click(app.map.camera_buttons.company)
		var local: Vector2=app.map.size*Vector2(.46,.50)
		var anchor: Vector2=app.map.camera.world_at(local,app.map.size)
		var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;wheel.position=app.map.get_global_position()+local;wheel.global_position=wheel.position
		viewport.push_input(wheel,true);await frames(4)
		var release: InputEventMouseButton=wheel.duplicate();release.pressed=false;viewport.push_input(release,true);await frames(2)
		check(app.map.camera.world_at(local,app.map.size).distance_to(anchor)<.0001 and app.map.camera.zoom>2.6,"native wheel zoom stays anchored to pointer")
		var before_center: Vector2=app.map.camera.center
		for pressed in [true,false]:
			var drag:=InputEventMouseButton.new();drag.button_index=MOUSE_BUTTON_RIGHT;drag.pressed=pressed;drag.button_mask=MOUSE_BUTTON_MASK_RIGHT if pressed else 0;drag.position=app.map.get_global_position()+local;drag.global_position=drag.position
			viewport.push_input(drag,true);await frames(2)
			if pressed:
				var motion:=InputEventMouseMotion.new();motion.position=drag.position+Vector2(-120,45);motion.global_position=motion.position;motion.relative=Vector2(-120,45);motion.button_mask=MOUSE_BUTTON_MASK_RIGHT
				viewport.push_input(motion,true);await frames(4)
		check(app.map.camera.center.distance_to(before_center)>.01 and app.map.drag_button==0,"native RMB drag pans and releases")
		check(campaign.same_data(campaign.state,original),"native pan/zoom does not advance/mutate company")
		await pointer(app.map.minimap.get_global_position()+Vector2(4,4)+(app.map.minimap.size-Vector2(8,8))*Vector2(.3,.4))
		check(app.map.camera.center.distance_to(Vector2(.3,.4))<.01 and campaign.same_data(campaign.state,original),"native overview-chart click moves view without travel")
		await capture("large-pan-%s-%s" % [item[0],item[1]],pixels)
		await click(app.map.camera_buttons.overview)
		await click(app.map.site_buttons.saltwatch)
		check(not app.preview_profile.living_world.party.path.is_empty(),"native generated route preview")
		await capture("generated-route-%s-%s" % [item[0],item[1]],pixels)
	await click(app.buttons.play)
	check(campaign.living_active() and campaign.state.living_world.has("geography") and app.has_method("set_speed"),"native Play enters generated living pilot")
	await capture("generated-live",pixels)
	var signature: String=campaign.state.living_world.geography.checksum
	var bar: TabBar=app.tabs.get_tab_bar()
	await pointer(bar.get_global_position()+bar.get_tab_rect(1).get_center())
	await click(app.buttons.accept_restore_mine)
	check(campaign.state.living_world.contracts.restore_mine.stage=="accepted","generated company accepts actual mine contract")
	await pointer(bar.get_global_position()+bar.get_tab_rect(0).get_center())
	inspect_region_motion=true
	var bridge: Dictionary=campaign.state.living_world.geography.bridges[0]
	for bank: String in ["from","to"]:
		var position:=Vector2(float(bridge[bank].x),float(bridge[bank].y))
		app.map.reveal(position);await frames(2)
		await pointer(app.map.get_global_position()+app.map.paper_rect().position+app.map.paper_rect().size*position)
		await click(app.buttons.speed_4)
		for iteration in range(600):
			await frames(2)
			if not campaign.state.world.pending_event.is_empty():
				await click(app.buttons.event_pay);await click(app.buttons.speed_4)
			if campaign.state.living_world.party.path.is_empty(): break
		await click(app.buttons.pause)
		var actual:=Vector2(float(campaign.state.living_world.party.position.x),float(campaign.state.living_world.party.position.y))
		check(actual.distance_to(position)<.015,"generated actual pointer travel reaches bridge bank: "+bank)
	check(region_bridge_samples>0,"generated rendered company crosses actual semantic bridge")
	await capture("generated-crossing",pixels)
	await living_travel("dungeon_old_mine",campaign)
	await capture("generated-mine-arrival",pixels)
	check(app.buttons.food.disabled and not app.buttons.prepare.disabled,"generated actual mine position gates town services and entry")
	original=campaign.state.duplicate(true)
	await click(app.buttons.stash)
	check(app.get_script().resource_path.ends_with("/app.gd") and app.inventory_view and campaign.same_data(campaign.state,original),"generated equipment keeps exact paused geography/company")
	await click(app.shell.nav_buttons.region)
	await click(app.buttons.prepare)
	check(root.get_node("DungeonRunSession").town_preparation,"generated mine uses owned packing")
	await capture("generated-mine-packing",pixels)
	var start: Button=null
	for button: Button in app.find_children("*","Button",true,false):
		if button.text=="Start Expedition": start=button
	check(start!=null,"generated packing Start exists")
	if start!=null: await click(start)
	check(not campaign.state.active_run.is_empty(),"generated Start creates ordinary managed receipt")
	await click(app.retreat_button);await frames(16)
	check(app.get_script().resource_path.ends_with("/living_world_view.gd") and campaign.state.active_run.is_empty(),"generated ordinary retreat returns to living map")
	check(campaign.state.living_world.mine.status=="occupied" and campaign.state.living_world.contracts.restore_mine.stage=="accepted","generated retreat cannot award victory")
	await living_travel("town_ravenford",campaign)
	inspect_region_motion=false
	check(region_motion_frames>100 and region_motion_samples>600 and region_motion_violations==0,"generated every-frame rendered company/NPC stays on passable terrain: %dframes/%dsamples/%dviolations" % [region_motion_frames,region_motion_samples,region_motion_violations])
	check(campaign.state.living_world.geography.checksum==signature,"generated native travel/gear/mine preserves immutable snapshot")
	await capture("generated-return",pixels)
	original=campaign.state.duplicate(true)
	await click(app.buttons.regions)
	await click(app.buttons.play)
	check(campaign.same_data(campaign.state,original),"generated selector resumes current company without reset")
	await click(app.buttons.regions)
	await click(app.buttons.authored)
	check(not campaign.state.living_world.has("geography") and not app.buttons.terrain.disabled,"authored Marches and designer map remain available")
	await capture("generated-authored-return",pixels)

func exercise_terrain(campaign: Node,pixels: Vector2i) -> void:
	var Terrain:=load("res://scripts/domain/terrain_navigation.gd")
	var World:=load("res://scripts/domain/living_world.gd")
	campaign.load_profile("",true);campaign.enable_living_world()
	var before: Dictionary=campaign.state.duplicate(true)
	await embedded_route("res://scenes/world/TerrainEditor.tscn")
	app.qa_memory=true;app.file_path="user://qa_terrain_native_%s.json" % pixels.x
	check(app.canvas.size.x>app.size.x*.65 and app.canvas.size.y>app.size.y*.6,"native terrain editor retains large map")
	for id: String in ["save","reload","paint","probe","undo","redo","terrain_B"]:
		check(Rect2(Vector2.ZERO,app.size).encloses(app.buttons[id].get_global_rect()),"native terrain control fits: "+id)
	await capture("terrain-overview",pixels)
	var rows: Array=app.data.rows.duplicate()
	await click(app.palette.W)
	await terrain_drag(Vector2(.1,.86),Vector2(.15,.86))
	check(app._code(Vector2(.125,.86))=="W" and app.history.size()==1,"native pointer drag paints one continuous stroke")
	await capture("terrain-painted",pixels)
	await click(app.buttons.undo);check(app.data.rows==rows,"native Undo restores original cells")
	await click(app.buttons.redo);check(app.data.rows!=rows,"native Redo restores stroke")
	await click(app.buttons.undo)
	await click(app.buttons.probe)
	await pointer(app.canvas.get_global_position()+app.canvas.point(World.point(World.site("town_ravenford").position)))
	await pointer(app.canvas.get_global_position()+app.canvas.point(World.point(World.site("saltwatch").position)))
	check(not app.canvas.route.is_empty() and app.status.text.begins_with("Safe route"),"native route probe finds safe river crossings")
	await capture("terrain-route-probe",pixels)
	await pointer(app.canvas.get_global_position()+app.canvas.point(Vector2(.95,.9)))
	check(app.status.text.begins_with("Blocked"),"native sea destination is rejected")
	var sampled: Vector2=World.point(World.site("town_ravenford").position)
	for pressed in [true,false]:
		var right:=InputEventMouseButton.new();right.button_index=MOUSE_BUTTON_RIGHT;right.pressed=pressed;right.button_mask=MOUSE_BUTTON_MASK_RIGHT if pressed else 0;right.position=app.canvas.get_global_position()+app.canvas.point(sampled);right.global_position=right.position
		viewport.push_input(right,true);await frames(2)
	check(app.selected==app._code(sampled) and not app.canvas.probe_mode,"native right click samples terrain and selects paint mode")
	# Wheel zoom is engine input too; the anchor must stay under the pointer.
	var coordinate:=Vector2(.38,.42)
	var pixel: Vector2=app.canvas.point(coordinate)
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;wheel.position=app.canvas.get_global_position()+pixel;wheel.global_position=wheel.position
	viewport.push_input(wheel,true);await frames(2)
	var wheel_release: InputEventMouseButton=wheel.duplicate();wheel_release.pressed=false
	viewport.push_input(wheel_release,true);await frames()
	check(app.canvas.zoom>1 and app.canvas.normalized(pixel).distance_to(coordinate)<.0001,"native wheel zoom preserves input alignment")
	for pressed in [true,false]:
		var middle:=InputEventMouseButton.new();middle.button_index=MOUSE_BUTTON_MIDDLE;middle.pressed=pressed;middle.button_mask=MOUSE_BUTTON_MASK_MIDDLE if pressed else 0;middle.position=app.canvas.get_global_position()+pixel;middle.global_position=middle.position
		viewport.push_input(middle,true);await frames(2)
		if pressed:
			var old_pan: Vector2=app.canvas.pan
			var motion:=InputEventMouseMotion.new();motion.position=middle.position+Vector2(25,15);motion.global_position=motion.position;motion.relative=Vector2(25,15);motion.button_mask=MOUSE_BUTTON_MASK_MIDDLE
			viewport.push_input(motion,true);await frames(2)
			check(app.canvas.pan.distance_to(old_pan+Vector2(25,15))<.001,"native middle drag pans map")
	await click(app.buttons.fit)
	check(app.canvas.zoom==1 and app.canvas.pan==Vector2.ZERO,"native Fit restores map after zoom/pan")
	await click(app.buttons.save)
	if not app.status.text.begins_with("Saved revision"): print("TERRAIN_SAVE_DIAGNOSTIC ",app.status.text," path=",app.file_path)
	check(FileAccess.file_exists(app.file_path) and app.status.text.begins_with("Saved revision"),"native Save writes only isolated terrain QA data")
	var bytes:=FileAccess.get_file_as_string(app.file_path)
	await click(app.palette.W)
	await terrain_drag(World.point(World.site("town_ravenford").position),World.point(World.site("town_ravenford").position))
	await click(app.buttons.save)
	check(app.status.text.begins_with("Not saved") and FileAccess.get_file_as_string(app.file_path)==bytes,"native invalid mask cannot replace saved terrain")
	await capture("terrain-save-refused",pixels)
	await click(app.buttons.undo)
	await click(app.buttons.reload)
	check(app.data.rows==rows,"native Reload restores saved terrain")
	var path: String=app.file_path
	await click(app.buttons.back)
	check(app.has_method("set_speed") and app.speed==0 and campaign.same_data(campaign.state,before),"native return preserves paused company and world clock")
	await click(app.map.site_buttons.saltwatch)
	check(not campaign.state.living_world.party.path.is_empty(),"native world plans a terrain-aware course")
	await click(app.buttons.pause)
	await capture("terrain-runtime-course",pixels)
	var safe:=true
	app.set_speed(4)
	for iteration in range(650):
		await frames(2)
		for actor: Dictionary in campaign.state.living_world.actors: safe=safe and Terrain.current().passable(World.point(actor.position))
		safe=safe and Terrain.current().passable(app.map.displayed("company"))
		if not campaign.state.world.pending_event.is_empty():
			await click(app.buttons.event_pay);app.set_speed(4)
		if campaign.state.living_world.party.path.is_empty(): break
	app.set_speed(0)
	check(safe and World.at_site(campaign.state.living_world,"saltwatch"),"native interpolated company/NPC movement stays on accessible terrain and arrives")
	await capture("terrain-runtime-arrival",pixels)
	for file: String in [path,path+".previous"]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)

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
