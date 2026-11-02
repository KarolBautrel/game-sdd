extends "res://scripts/qa/campaign_render_review.gd"
## Same no-focus/input/save boundary as the campaign renderer, for play screens.
const MODEL := preload("res://scripts/domain/dungeon_state_model.gd")
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
				await click(app.room_nodes.dusty_crossing.find_children("*","Button",true,false)[0])
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
			app._show_action_hover("move",1)
			await frames(6)
			await capture("combat-context",pixels)
			if exercise: await _exercise_battle(pixels)
			app.queue_free()
			await frames(8)
		viewport.queue_free()
		await frames(8)
	check(not root.has_focus(),"play review acquired no focus")
	var report: Dictionary={"status":"PASS" if errors.is_empty() else "FAIL","kind":"native play GPU and engine-local input fixture","display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"window_minimized":root.mode==Window.MODE_MINIMIZED,"window_focused":root.has_focus(),"uses_desktop_input":false,"player_save_used":false,"engine_clicks":clicks,"captures":captures,"checks":checks,"failures":errors}
	var file:=FileAccess.open(output+"/native-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	for message in errors: push_error(message)
	print("Native play review: ",checks.size()," checks, ",errors.size()," failures")
	get_tree().quit(0 if errors.is_empty() else 1)
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
	await click(_action_button("move"))
	await click(_tile_button({"x":1,"y":9}))
	await click(_tile_button({"x":1,"y":9}))
	await frames(36)
	check(app._unit_by_id("unit_player_001").position=={"x":1,"y":9},"native transformed tile move reaches real destination")
	check(app._unit_by_id("unit_player_001").resources.mp==3,"native movement spends trusted MP")
	await capture("combat-moved",pixels)
	await click(_action_button("end_turn"))
	check(app.state.turn_state.active_unit_id=="unit_player_002","native end turn changes active hero")
	await click(_action_button("ranged_attack"))
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
