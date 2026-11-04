extends "res://scripts/qa/campaign_render_review.gd"
## Same no-focus/input/save boundary as the campaign renderer, for play screens.
const MODEL := preload("res://scripts/domain/dungeon_state_model.gd")
var keys:=0
func _run() -> void:
	await frames(2)
	check(DisplayServer.get_name()!="headless","native play display")
	check(not root.has_focus() and root.mode==Window.MODE_MINIMIZED,"no-focus minimized play host")
	var session:=get_node("/root/DungeonRunSession")
	var campaign:=get_node("/root/CampaignSession")
	for dimensions in sizes.split(","):
		var values:=dimensions.split("x")
		var pixels:=Vector2i(int(values[0]),int(values[1]))
		campaign.load_profile("",true)
		session.clear()
		viewport=SubViewport.new()
		viewport.size=pixels
		viewport.size_2d_override=Vector2i(2560,1440) if pixels.x>=1920 else pixels
		viewport.size_2d_override_stretch=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		if "atlasbounds" in views:
			await _exercise_atlas_bounds()
		if "modular" in views:
			await _exercise_modular(pixels)
		if "environment" in views:
			await _exercise_environment(pixels)
		if "arenas" in views:
			await _exercise_arenas(pixels)
		if "arenabattles" in views:
			await _exercise_arena_battles(pixels)
		if "townpilot" in views:
			await _exercise_town_pilot(pixels)
		if "dungeon" in views:
			app=load("res://scenes/dungeon/DungeonDebug.tscn").instantiate()
			viewport.add_child(app)
			await frames(10)
			app._set_dungeon_source(app.DUNGEON_SOURCE_AUTHORED)
			await frames(10)
			await capture("dungeon-prep",pixels)
			if exercise:
				await click(_button_named("Start Expedition"))
				check(app.expedition_started,"native expedition start")
			else: app._start_expedition_with_loadout()
			await frames(8)
			await capture("dungeon-route",pixels)
			if exercise:
				var before_preview: Dictionary=app.run_state.duplicate(true)
				await click(app.room_nodes.dusty_crossing.find_children("*","Button",true,false)[0])
				check(app.run_state==before_preview,"native room preview spends no resources")
				await capture("dungeon-preview",pixels)
				await click(app.expedition_chrome.travel_button)
			else: app._try_enter_room("dusty_crossing")
			await frames(8)
			await capture("dungeon-event",pixels)
			if exercise:
				check(not app.run_state.pending_room_event.is_empty(),"native travel opens authored room event")
				await click(_button_named("Move on"))
				check(app.run_state.pending_room_event.is_empty(),"native event choice resolves and releases map")
				var oil: int=app.run_state.supplies.lamp_oil
				await click(app.oil_button)
				check(app.run_state.supplies.lamp_oil==oil-1 and app.run_state.light_level==4,"native oil action spends exactly one supply")
				await click(app.room_nodes.collapsed_cache.find_children("*","Button",true,false)[0])
				await click(app.expedition_chrome.travel_button)
				check(not app.run_state.pending_corridor_hazard.is_empty(),"native room input opens real corridor hazard")
				await capture("dungeon-hazard",pixels)
				for choice: Button in app.corridor_hazard_choice_buttons:
					if not choice.disabled:
						await click(choice)
						break
				check(app.run_state.current_room_id=="collapsed_cache","native hazard resolution enters destination")
				await click(app.reward_button)
				check(MODEL.run_inventory(app.run_state).gold==9,"native loot claim preserves trusted rewards")
				await capture("dungeon-loot",pixels)
			app.queue_free()
			await frames(8)
			session.clear()
		if "combat" in views:
			app=load("res://scenes/combat/CombatDebug.tscn").instantiate()
			viewport.add_child(app)
			await frames(10)
			app.selected_scenario_id="clearing_crossfire"
			app._load_selected_scenario()
			await frames(10)
			await capture("combat",pixels)
			for unit: Dictionary in app.state.units:
				var node: Control=app.unit_layer.get_node(NodePath(unit.id))
				var panel: Control=node.get_node("ResourcePanel")
				check(panel.position.y+panel.size.y<=app.unit_art.idle_top(unit,app.UNIT_ICON_SIZE)-10,"native resource panel clears actor silhouette")
			app._show_action_hover("move",1)
			await frames(6)
			await capture("combat-context",pixels)
			if exercise: await _exercise_battle(pixels)
			app.queue_free()
			await frames(8)
		if "raider" in views:
			app=load("res://scenes/combat/CombatDebug.tscn").instantiate()
			viewport.add_child(app)
			await frames(10)
			app.selected_scenario_id="ash_road_raiders"
			app._load_selected_scenario()
			await frames(10)
			await capture("raider-board",pixels)
			var original: Dictionary=app.state.duplicate(true)
			for direction in ["south","south_west","west","north_west","north","north_east","east","south_east"]:
				app.unit_facing.unit_enemy_001=direction
				app.unit_visual_action.unit_enemy_001="pose:0"
				app._refresh_unit_sprite("unit_enemy_001")
				await frames(2)
				await capture("raider-facing-"+direction,pixels)
			for action in ["walk:3","combat:4","hit:2","death:7"]:
				app.unit_facing.unit_enemy_001="south_east"
				app.unit_visual_action.unit_enemy_001=action
				app._refresh_unit_sprite("unit_enemy_001")
				await frames(2)
				await capture("raider-"+action.replace(":","-"),pixels)
			check(app.state==original,"native sampled raider poses do not mutate simulation")
			app.queue_free()
			await frames(8)
		if "roster" in views:
			app=load("res://scenes/combat/CombatDebug.tscn").instantiate()
			viewport.add_child(app)
			await frames(10)
			var snapshot: Dictionary=app.state.duplicate(true)
			await click(app.battle_chrome.tools_button)
			await click(_button_named("Character gallery"))
			var gallery: Control=app.get_node_or_null("OriginalRosterGallery")
			check(gallery!=null,"native Tools opens character gallery")
			if gallery!=null:
				await frames(4)
				check(gallery.z_index>app.FLOATING_TEXT_LAYER_Z_INDEX,"native gallery covers battle overlays")
				check(gallery.scroll.size.y>600 and gallery.grid.size.y<=gallery.scroll.size.y,"native gallery shows both actor rows")
				if "rosterhuman" in views:
					gallery.profiles=gallery.profiles.filter(func(profile: Dictionary) -> bool:return profile.kind=="human")
					gallery._build_page()
				await frames(10)
				gallery.playing=false
				var pages: int=ceili(gallery.profiles.size()/6.0)
				for page_index in range(pages):
					check(gallery.page==page_index,"native gallery page navigation")
					for card: Dictionary in gallery.cards:check(card.sprite.texture!=null,"native original actor: "+str(card.id))
					await capture("roster-page-%s" % (page_index+1),pixels)
					for motion in ["walk","combat","hit","death"]:
						gallery.action=motion
						gallery.frame=7 if motion in ["death","combat"] else 2
						gallery._refresh()
						gallery.find_child("GalleryMotion",true,false).select(gallery.ACTIONS.find(motion))
						await frames(6)
						await capture("roster-page-%s-%s" % [page_index+1,motion],pixels)
					gallery.action="pose";gallery.frame=0
					gallery.find_child("GalleryMotion",true,false).select(0)
					if page_index<pages-1:await click(_button_named("Next"))
				await click(_button_named("Close"))
				await frames(2)
				check(app.get_node_or_null("OriginalRosterGallery")==null and app.is_processing_input(),"native gallery close restores battle input")
			check(app.state==snapshot,"native gallery leaves combat state untouched")
			if not "rosterhuman" in views:
				await _capture_roster_boards(pixels)
			app.queue_free()
			await frames(8)
		viewport.queue_free()
		await frames(8)
	check(not root.has_focus(),"play review acquired no focus")
	var report: Dictionary={"status":"PASS" if errors.is_empty() else "FAIL","kind":"native play GPU and engine-local input fixture","display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"window_minimized":root.mode==Window.MODE_MINIMIZED,"window_focused":root.has_focus(),"uses_desktop_input":false,"player_save_used":false,"engine_clicks":clicks,"captures":captures,"checks":checks,"failures":errors,"texture_memory_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)}
	report.engine_key_events=keys
	var file:=FileAccess.open(output+"/native-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	for message in errors: push_error(message)
	print("Native play review: ",checks.size()," checks, ",errors.size()," failures")
	get_tree().quit(0 if errors.is_empty() else 1)


func _capture_roster_boards(pixels: Vector2i) -> void:
	# Isolated presentation fixtures: no campaign saves, AI/balance or victory claim.
	var profiles: Array=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/presentation/original_roster.json")).characters
	var original: Dictionary=app.state.duplicate(true)
	var prototype: Dictionary=app._unit_by_id("unit_enemy_001").duplicate(true)
	for page in range(ceili(profiles.size()/6.0)):
		app.state=original.duplicate(true)
		app.state.units=app.state.units.filter(func(unit: Dictionary) -> bool:return unit.team=="player")
		app.state.terrain_decorations=[]
		for tile: Dictionary in app.state.grid.tiles:tile.type="floor"
		var order: Array=[]
		for unit: Dictionary in app.state.units:order.append(unit.id)
		for index in range(page*6,mini(page*6+6,profiles.size())):
			var profile: Dictionary=profiles[index]
			var unit: Dictionary=prototype.duplicate(true)
			unit.id="qa_roster_"+str(profile.id)
			unit.visual={"faction":"original","character":profile.id}
			unit.position={"x":roundi(float(app.state.grid.width)*(index%3+1)/4),"y":1+(index%6)/3*4}
			app.state.units.append(unit);order.append(unit.id)
		app.state.turn_state.turn_order=order
		app.state.turn_state.active_unit_id="unit_player_001"
		app._prepare_presentation_cache()
		for unit: Dictionary in app.state.units:app.unit_facing[unit.id]="east"
		app._render()
		await frames(10)
		for unit: Dictionary in app.state.units:
			var sprite: TextureRect=app.unit_layer.get_node(NodePath(str(unit.id)+"/Sprite"))
			check(sprite.texture!=null,"native board original: "+str(app.unit_art.unit_visual_config(unit).character))
		await capture("roster-board-%s" % (page+1),pixels)


func _exercise_modular(pixels: Vector2i) -> void:
	app=Control.new()
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(app)
	var background:=ColorRect.new()
	background.color=Color("242a28");background.size=Vector2(2560,1440)
	app.add_child(background)
	var atlas: Node=load("res://scripts/presentation/combat/modular_actor_atlas.gd").new()
	app.add_child(atlas)
	var ids: Array=["warrior","archer_1","bandit_spearman","armored_brute"]
	var sprites: Array[TextureRect]=[]
	for index in ids.size():
		var id: String=ids[index]
		check(atlas.available(id),"native modular resource: "+id)
		var sprite:=TextureRect.new()
		sprite.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		sprite.size=Vector2(640,448);sprite.position=Vector2((index%2)*960+160,(index/2)*600+60)
		app.add_child(sprite);sprites.append(sprite)
		var label:=Label.new();label.text=id;label.position=sprite.position+Vector2(240,360);label.add_theme_font_size_override("font_size",28);app.add_child(label)
	for direction: String in ["south","east","north"]:
		for index in ids.size():sprites[index].texture=atlas.texture({"id":ids[index]},ids[index],direction,"pose:0")
		await frames(8)
		for index in ids.size():
			var record: Dictionary=atlas.actors[ids[index]]
			check(not str(record.clip).is_empty(),"native modular clip resolves: "+ids[index]+" "+direction)
			check(record.texture.get_image().get_used_rect().has_area(),"native modular alpha silhouette: "+ids[index]+" "+direction)
		await capture("modular-pose-"+direction,pixels)
	for action: String in ["walk:3","combat:4","hit:2","death:7"]:
		for index in ids.size():sprites[index].texture=atlas.texture({"id":ids[index]},ids[index],"east",action)
		await frames(8)
		await capture("modular-"+action.replace(":","-"),pixels)
	app.queue_free();await frames(8)


func _town_key(code: Key, pressed: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	viewport.push_input(event,true);keys+=1
	await frames(2)

func _exercise_town_pilot(pixels: Vector2i) -> void:
	var campaign:=get_node("/root/CampaignSession")
	var before: Dictionary=campaign.state.duplicate(true)
	app=load("res://scenes/town/TownExploration.tscn").instantiate();viewport.add_child(app)
	await frames(12)
	check(app.actors.size()==6,"town native party and NPC stand-ins")
	check(app.world.scale.x>0.3,"town ground layout settled before first input")
	for actor: Dictionary in app.actors:check(actor.sprite.texture!=null,"town native painted actor texture")
	await capture("town-courtyard",pixels)
	var start: Vector2=app.party_positions[0]
	var walk_frames: Dictionary={}
	var watch: Callable=func() -> void:
		var path: String=app.actors[0].path
		if "/neutral_walk/" in path:walk_frames[path]=true
	get_tree().process_frame.connect(watch)
	await _town_key(KEY_A,true)
	await get_tree().create_timer(1.1).timeout
	await _town_key(KEY_A,false)
	get_tree().process_frame.disconnect(watch)
	check(app.Model.project(app.party_positions[0]-start).length()>70,"town native held A moves left")
	check(walk_frames.size()==8,"town native complete eight-cel calm walk")
	check(app.near_id=="watch","town native proximity selects gate watch")
	for point: Vector2 in app.party_positions:check(app.Model.walkable(point,app.map),"town followers stay on walkable breadcrumbs")
	var anchor: Vector2=app.party_positions[0]
	await frames(8)
	check(app.party_positions[0]==anchor,"town key release stops without sliding")
	await capture("town-approach",pixels)
	await _town_key(KEY_E,true);await _town_key(KEY_E,false)
	check(app.blocker.visible and app.talking_id=="watch","town native E opens nearest dialogue")
	check(app.dialogue.get_global_rect().encloses(app.close_dialogue.get_global_rect()),"town dialogue action stays inside parchment")
	check(Rect2(Vector2.ZERO,app.size).encloses(app.dialogue.get_global_rect()),"town dialogue parchment stays in viewport")
	await _town_key(KEY_D,true);await get_tree().create_timer(0.4).timeout
	check(app.party_positions[0]==anchor,"town modal blocks native movement input")
	await capture("town-dialogue",pixels)
	await _town_key(KEY_ESCAPE,true);await _town_key(KEY_ESCAPE,false);await _town_key(KEY_D,false)
	await frames(8)
	check(not app.blocker.visible and app.held.is_empty(),"town Escape closes and clears held movement")
	check(app.party_positions[0]==anchor,"town close never resumes stale held key")
	check(campaign.state==before,"town native actions never change campaign save state")
	app.queue_free();await frames(8)


func _exercise_arena_battles(pixels: Vector2i) -> void:
	for scenario: String in ["painted_forest_ambush","painted_mine_breach"]:
		app=load("res://scenes/combat/CombatDebug.tscn").instantiate();viewport.add_child(app)
		await frames(6)
		app.selected_scenario_id=scenario;app._load_selected_scenario()
		await frames(12)
		var observations: Dictionary={}
		var watch: Callable=func() -> void:
			if not is_instance_valid(app):return
			for id: String in app.unit_visual_action:
				observations[str(app.unit_visual_action[id])]=true
		get_tree().process_frame.connect(watch)
		var count:=0
		while app._combat_result()=="in_progress" and count<100:
			var policy: Dictionary=app.state.duplicate(true)
			if app._unit_by_id(policy.turn_state.active_unit_id).team=="player":
				for unit: Dictionary in policy.units:unit.team="enemy" if unit.team=="player" else "player"
			var command: Dictionary=app.CombatResolver.choose_enemy_command(policy,"cmd_%03d" % app.command_index)
			var expected: Dictionary=app.CombatResolver.simulate(app._state_without_log(),[command]).state
			var before_index: int=app.command_index
			await click(_action_button(command.action_id))
			if command.target.type=="tile":
				await click(_tile_button(command.target.position))
				await click(_tile_button(command.target.position))
			elif command.target.type=="unit":
				await click(_tile_button(app._unit_by_id(command.target.unit_id).position))
			var deadline:=Time.get_ticks_msec()+10000
			while app.animation_locked and Time.get_ticks_msec()<deadline:await frames(1)
			check(not app.animation_locked,"arena full battle animation unlocks: "+scenario+str(count))
			check(app.command_index==before_index+1,"arena control submits exactly one command: "+scenario+str(count))
			# TMX JSON numbers are floats; native tile controls use integer coords.
			# Compare their serialized domain values, not Dictionary numeric types.
			var actual_units: Variant=JSON.parse_string(JSON.stringify(app.state.units))
			var expected_units: Variant=JSON.parse_string(JSON.stringify(expected.units))
			check(actual_units==expected_units and app.state.turn_state==expected.turn_state and app.state.seed==expected.seed,"arena controls match trusted resolver: "+scenario+str(count))
			if not errors.is_empty():break
			count+=1
		get_tree().process_frame.disconnect(watch)
		check(app._combat_result()=="victory","arena ordinary controls reach normal victory: "+scenario)
		check(observations.has("combat:7") and observations.has("death:7"),"arena full attack/death frames sampled: "+scenario)
		for event: Dictionary in app.state.event_log:
			check(event.type!="command_rejected" and event.get("source","")!="debug_win","arena no rejected or forced command: "+scenario)
		print("ARENA_NATIVE_BATTLE ",scenario," result=",app._combat_result()," commands=",count," sampled=",observations.keys())
		await capture("arena-victory-"+scenario,pixels)
		app.queue_free();await frames(8)


func _exercise_arenas(pixels: Vector2i) -> void:
	for scenario: String in ["painted_forest_ambush","painted_mine_breach"]:
		app=load("res://scenes/combat/CombatDebug.tscn").instantiate();viewport.add_child(app)
		await frames(6)
		app.selected_scenario_id=scenario;app._load_selected_scenario()
		await frames(12)
		var before: Dictionary=app.state.duplicate(true)
		check(app.board_terrain.texture!=null,"arena painted floor: "+scenario)
		check(app.state.units.size()==7,"arena seven accepted actors: "+scenario)
		for unit: Dictionary in app.state.units:
			check(app.unit_art.is_drawn_unit(unit),"arena accepted painted actor: "+unit.id)
			var node: Control=app.unit_layer.get_node_or_null(NodePath(unit.id))
			check(node!=null and node.get_node("Sprite").texture!=null,"arena visible actor: "+unit.id)
		for tile: Dictionary in app.state.grid.tiles:
			var path: String=app._tile_decoration_path(tile)
			if not path.is_empty():check(not app.EnvironmentArt.prop(path).is_empty(),"arena semantic prop: "+path)
		app._render();await frames(8)
		check(app.state==before,"arena render preserves domain: "+scenario)
		if pixels==Vector2i(1280,720):
			check(app.board_root.size.x*app.board_root.scale.x>=500 and app.board_root.size.y*app.board_root.scale.y>=280,"arena720p retains readable floor area: "+scenario)
		await capture("arena-"+scenario,pixels)
		if exercise:
			await click(_action_button("move"))
			await click(_tile_button({"x":3,"y":7}))
			await click(_tile_button({"x":3,"y":7}))
			var deadline:=Time.get_ticks_msec()+8000
			while app.animation_locked and Time.get_ticks_msec()<deadline:await frames(1)
			check(not app.animation_locked,"arena move finishes without turn lock: "+scenario)
			check(app._unit_by_id("unit_knight_pilot").position=={"x":3,"y":7},"arena real control reaches destination: "+scenario)
			check(app._unit_by_id("unit_knight_pilot").resources.mp==3,"arena real control spends1MP: "+scenario)
			await capture("arena-"+scenario+"-moved",pixels)
		app.queue_free();await frames(8)


func _exercise_environment(pixels: Vector2i) -> void:
	for scenario: String in ["terrain_grass_showcase","terrain_dungeon_showcase","clearing_crossfire","ash_road_raiders"]:
		app=load("res://scenes/combat/CombatDebug.tscn").instantiate();viewport.add_child(app)
		await frames(6)
		app.selected_scenario_id=scenario;app._load_selected_scenario()
		await frames(10)
		var before: Dictionary=app.state.duplicate(true)
		check(app.board_terrain.texture!=null,"native painted floor: "+scenario)
		for tile: Dictionary in app.state.grid.tiles:
			var path: String=app._tile_decoration_path(tile)
			if not path.is_empty():
				check(not app.EnvironmentArt.prop(path).is_empty(),"native original prop mapping: "+path)
		check(app.state==before,"environment presentation leaves map/domain untouched: "+scenario)
		await capture("environment-"+scenario,pixels)
		app.queue_free();await frames(8)
	app=Control.new();app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);viewport.add_child(app)
	var background:=ColorRect.new();background.color=Color("2b2b25");background.size=Vector2(2560,1440);app.add_child(background)
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/presentation/world_art.json"))
	var index:=0
	for id: String in catalogue.assets:
		var row: Dictionary=catalogue.assets[id]
		var sprite:=TextureRect.new();sprite.texture=load(row.path);sprite.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;sprite.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.position=Vector2((index%7)*365+20,(index/7)*350+12);sprite.size=Vector2(325,290);app.add_child(sprite)
		var label:=Label.new();label.text=id;label.add_theme_font_size_override("font_size",26);label.position=sprite.position+Vector2(80,300);app.add_child(label)
		check(sprite.texture!=null,"native world family asset: "+id);index+=1
	await frames(8);await capture("environment-prop-family",pixels)
	app.queue_free();await frames(8)


func _exercise_atlas_bounds() -> void:
	# One GPU readback per sample, covering every actor/cell together. This catches
	# native rig/root-motion clipping that headless PNG fallback cannot establish.
	app=Control.new();viewport.add_child(app)
	var atlas: Node=load("res://scripts/presentation/combat/modular_actor_atlas.gd").new();app.add_child(atlas)
	var roster: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/presentation/original_roster.json"))
	for profile: Dictionary in roster.characters:atlas.texture({"id":profile.id},profile.id,"east","pose:0")
	for direction: String in roster.camera.yaw:
		for kind: String in roster.frame_counts:
			for frame in [0,int(roster.frame_counts[kind])-1]:
				for profile: Dictionary in roster.characters:atlas.texture({"id":profile.id},profile.id,direction,"%s:%s" % [kind,frame])
				await frames(2);RenderingServer.force_draw(false)
				var canvas: Image=atlas.viewport.get_texture().get_image()
				for profile: Dictionary in roster.characters:
					var record: Dictionary=atlas.actors[profile.id]
					var cell: Image=canvas.get_region(Rect2i(record.texture.region))
					var used:=cell.get_used_rect()
					check(used.has_area() and used.position.x>2 and used.position.y>2 and used.end.x<638 and used.end.y<446,"native atlas unclipped: %s/%s/%s/%s %s" % [profile.id,direction,kind,frame,used])
				if direction=="east" and ((kind=="pose" and frame==0) or (kind in ["combat","death"] and frame==7)):
					var file: String=output+"/atlas-bounds-"+kind+".png"
					check(canvas.save_png(file)==OK,"save native full-atlas contact sheet "+kind)
					captures.append({"view":"atlas-bounds-"+kind,"file":file,"pixels":[canvas.get_width(),canvas.get_height()]})
	app.queue_free();await frames(8)
func _button_named(text: String) -> Button:
	for button: Button in app.find_children("*","Button",true,false):
		if button.text==text: return button
	return null

func _action_button(id: String) -> Button:
	for button: Button in app.command_buttons.get_children():
		if not button.is_queued_for_deletion() and button.get_meta("action_id","")==id: return button
	return null

func _tile_button(position: Dictionary) -> Button:
	return app.grid_container.get_child(int(position.y)*int(app.state.grid.width)+int(position.x)) as Button

func _exercise_battle(pixels: Vector2i) -> void:
	for unit: Dictionary in app.state.units:
		check(app.unit_layer.get_node_or_null(NodePath(unit.id))!=null,"native reload keeps unit visual: "+unit.id)
		var sprite: TextureRect=app.unit_layer.get_node(NodePath(str(unit.id)+"/Sprite"))
		check(sprite.texture.resource_path.begins_with("res://assets/combat/characters/original/"),"restored stage33 sprite in native battle: "+str(unit.id))
	check(app.find_children("ActorAtlasViewport","SubViewport",true,false).is_empty(),"battle has no rejected modular model renderer")
	await click(_action_button("move"))
	await click(_tile_button({"x":1,"y":9}))
	var walk_frames: Dictionary={}
	var watch: Callable=func() -> void:
		var sprite: TextureRect=app.unit_layer.get_node("unit_player_001/Sprite")
		if sprite.texture!=null and sprite.texture.resource_path.contains("/walk/"):
			walk_frames[sprite.texture.resource_path]=true
	get_tree().process_frame.connect(watch)
	await click(_tile_button({"x":1,"y":9}))
	await frames(36)
	get_tree().process_frame.disconnect(watch)
	check(walk_frames.size()>=3,"actual movement advances restored walk animation: %s distinct frames" % walk_frames.size())
	check(app._unit_by_id("unit_player_001").position=={"x":1,"y":9},"native transformed tile move reaches real destination")
	check(app._unit_by_id("unit_player_001").resources.mp==3,"native movement spends trusted MP")
	await capture("combat-moved",pixels)
	await click(_action_button("end_turn"))
	check(app.state.turn_state.active_unit_id=="unit_player_002","native end turn changes active hero")
	await click(_action_button("ranged_attack"))
	check(app.selected_action=="ranged_attack","native post-turn action survives delayed pose cleanup")
	var before: Array=app.state.units.duplicate(true)
	await click(_tile_button(app._unit_by_id("unit_enemy_002").position))
	await frames(12)
	check(app.state.units==before and app.current_action_title=="Action rejected","native illegal ranged target is atomic")
	await capture("combat-rejected",pixels)
	# Same isolated terminal fixture used by feedback acceptance, now via pointer.
	# This verifies real resolver/animation/result UI, never an ordinary playthrough.
	for winning_team in ["player","enemy"]:
		app._reset_debug_encounter()
		await frames(8)
		var hero: Dictionary=app._unit_by_id("unit_player_001").duplicate(true)
		var enemy: Dictionary=app._unit_by_id("unit_enemy_001").duplicate(true)
		hero.position={"x":0,"y":0}
		enemy.position={"x":1,"y":0}
		var attacker: Dictionary=hero if winning_team=="player" else enemy
		var target: Dictionary=enemy if winning_team=="player" else hero
		attacker.stats.strength=100
		attacker.resources.ap=2
		attacker.loadout={"main_hand":"hero_sword"}
		attacker.available_actions=["move","basic_attack","end_turn"]
		target.resources.hp=1
		target.statuses=[]
		app.state.units=[hero,enemy]
		app.state.turn_state.active_unit_id=attacker.id
		app.state.turn_state.turn_order=[attacker.id,target.id]
		app._prepare_presentation_cache()
		app._render()
		await frames(8)
		await click(_action_button("basic_attack"))
		await click(_tile_button(target.position))
		await frames(90)
		var expected: String="Victory" if winning_team=="player" else "Defeat"
		check(app.action_title_label.text==expected and not app.animation_locked,"native resolver terminal banner: "+expected)
		await capture("combat-"+expected.to_lower(),pixels)
	await click(app.battle_chrome.tools_button)
	check(app.battle_chrome.tools_open,"native developer tray opens")
	await click(_button_named("Load"))
	check(app.state.units.size()==4,"native encounter reload restores authored roster")
	for unit: Dictionary in app.state.units:
		check(app.unit_layer.get_node_or_null(NodePath(unit.id))!=null,"native reload visual survives: "+unit.id)
	await click(app.battle_chrome.tools_button)
