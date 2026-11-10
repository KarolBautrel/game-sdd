extends RefCounted
## Native ordinary campaign integration. No OS input or player profile access.
var review
var campaign: Node
var session: Node
var commands: Array[Dictionary] = []

func run(host, pixels: Vector2i) -> void:
	review=host
	campaign=review.root.get_node("CampaignSession")
	session=review.root.get_node("DungeonRunSession")
	var profile := "user://qa_living_world_generated_v2_%s_%s.json" % [review.output.get_file(),pixels.x]
	review.check(not FileAccess.file_exists(profile),"full loop uses a fresh isolated QA profile")
	if FileAccess.file_exists(profile): return
	review.check(campaign.load_profile(profile,false) and campaign.enable_generated_region(20261105,"marches",2),"ordinary Large company persists to QA-only profile")
	session.clear()
	# Actual scene changes briefly attach to root; give their ready/layout code the
	# correct logical size before adopting them into the offscreen GPU viewport.
	review.root.size=review.viewport.size_2d_override if review.viewport.size_2d_override.x>0 else pixels
	review.root.mode=Window.MODE_MINIMIZED
	review.app=load("res://scenes/world/LivingWorld.tscn").instantiate()
	review.app.scene_requested.connect(review.embedded_route)
	review.viewport.add_child(review.app)
	await review.frames(12)
	await _pan_without_travel()
	await _tab(1)
	await review.click(review.app.buttons.accept_restore_mine)
	review.check(campaign.state.living_world.contracts.restore_mine.stage=="accepted","full loop accepts actual issuer contract")
	await _tab(0)
	await review.living_travel("dungeon_old_mine",campaign)
	await review.capture("contract-mine-arrival",pixels)
	await review.click(review.app.buttons.prepare)
	if review.app.dungeon_source!=review.app.DUNGEON_SOURCE_AUTHORED:
		await review.click(review.app.source_toggle_button)
	review.check(review.app.dungeon_source==review.app.DUNGEON_SOURCE_AUTHORED,"owned preparation selects ordinary authored mine through UI")
	await review.click(review._button_named("Start Expedition"))
	review.check(session.managed_run and not campaign.state.active_run.is_empty(),"full loop starts real managed expedition")
	await _room("dusty_crossing")
	await review.click(review._button_named("Move on"))
	await _room("guarded_cache")
	review.check(not review.app.run_state.pending_combat_request.is_empty(),"guarded room requires a real tactical battle")
	var previous_seed: Variant=ProjectSettings.get_setting("debug/qa/combat_seed",0)
	ProjectSettings.set_setting("debug/qa/combat_seed",2087)
	await review.click(review.app.start_combat_button)
	if not await _adopt_scene("res://scenes/combat/CombatDebug.tscn"): return
	await review.capture("contract-battle-start",pixels)
	await _battle()
	ProjectSettings.set_setting("debug/qa/combat_seed",previous_seed)
	review.check(review.app._combat_result()=="victory","ordinary managed mine combat wins without forced result")
	if review.app._combat_result()!="victory": return
	await review.capture("contract-battle-victory",pixels)
	await review.click(review._button_named("Return\nto Dungeon"))
	if not await _adopt_scene("res://scenes/dungeon/DungeonDebug.tscn"): return
	review.check(review.app.run_state.cleared_room_ids.has("guarded_cache"),"real combat payload clears guarded room")
	await review.click(review.app.reward_button)
	review.check(review.app.run_state.claimed_reward_room_ids.has("guarded_cache"),"full loop claims actual guarded loot once")
	await _room("lower_exit")
	await review.click(review.app.finish_button)
	review.check(review.app.run_state.completed and review.app.run_state.run_outcome=="completed","full loop exits by normal completion")
	var payload: Dictionary=session.pending_world_return_payload.duplicate(true)
	await review.click(review.app.world_button)
	await review.frames(12)
	review.check(campaign.state.active_run.is_empty() and campaign.state.living_world.mine.status=="cleared","ordinary return settles and restores mine")
	review.check(campaign.state.living_world.contracts.restore_mine.stage=="objective","real restoration unlocks reporting, not immediate contract payment")
	review.check(not campaign.state.living_world.actors[3].active,"restored mine stops raider departures")
	await review.capture("contract-restored-mine",pixels)
	await review.living_travel("town_ravenford",campaign)
	await _tab(1)
	var gold: int=campaign.state.gold
	var xp: int=campaign.state.xp
	var relation: int=campaign.state.living_world.factions.river_league.relation
	await review.click(review.app.buttons.report_restore_mine)
	review.check(campaign.state.gold==gold+45 and campaign.state.xp==xp+20,"issuer pays exactly45 gold and20 XP")
	review.check(campaign.state.living_world.factions.river_league.relation==relation+10,"contract improves River League relation by10")
	review.check(campaign.state.living_world.contracts.restore_mine.stage=="completed" and review.app.buttons.report_restore_mine.disabled,"paid contract disables report control")
	await review.capture("contract-paid",pixels)
	var saved: Dictionary=campaign.state.duplicate(true)
	review.check(not campaign.report_living_contract("restore_mine") and campaign.same_data(campaign.state,saved),"duplicate report is rejected atomically")
	review.check(not campaign.settle(payload) and campaign.same_data(campaign.state,saved),"duplicate expedition settlement cannot pay again")
	session.clear()
	review.check(campaign.load_profile(profile,false) and campaign.same_data(campaign.state,saved),"exact paid company/mine persists after disk reload")
	await review.embedded_route("res://scenes/world/LivingWorld.tscn")
	review.check(review.app.speed==0,"reloaded paid company resumes paused")
	await review.living_travel("dungeon_old_mine",campaign)
	review.check(review.app.buttons.prepare.disabled,"restored mine cannot be farmed after reload")
	await review.capture("contract-reloaded-cleared",pixels)
	var file:=FileAccess.open(review.output+"/campaign-loop.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind":"ordinary native controls with deterministic existing AI policy", "uses_debug_win":false,"physical_gameplay":"NOT_RUN","profile":profile,"commands":commands,"final_state":campaign.state},"  ",true,true))
	file.close()
	review.app.queue_free();await review.frames(8)
	# Subsequent review dimensions also start in memory unless explicitly isolated.
	campaign.load_profile("",true)

func _tab(index: int) -> void:
	var bar: TabBar=review.app.tabs.get_tab_bar()
	await review.pointer(bar.get_global_position()+bar.get_tab_rect(index).get_center())

func _room(id: String) -> void:
	await review.click(review.app.room_nodes[id].find_children("*","Button",true,false)[0])
	await review.click(review.app.expedition_chrome.travel_button)
	review.check(review.app.run_state.current_room_id==id,"native ordinary dungeon arrival: "+id)

func _adopt_scene(path: String) -> bool:
	var tree: SceneTree=review.get_tree()
	for i in range(120):
		if tree.current_scene!=null and tree.current_scene.scene_file_path==path: break
		await review.frames(1)
	var arrived: Node=tree.current_scene
	var valid: bool=arrived!=null and arrived.scene_file_path==path
	review.check(valid,"actual production scene transition: "+path)
	if not valid: return false
	tree.current_scene=null
	review.app.queue_free()
	arrived.reparent(review.viewport)
	review.app=arrived
	if arrived.has_signal("scene_requested"): arrived.scene_requested.connect(review.embedded_route)
	await review.frames(12)
	return true

func _battle() -> void:
	for index in range(400):
		if review.app._combat_result()!="in_progress": break
		var policy: Dictionary=review.app.state.duplicate(true)
		if review.app._unit_by_id(policy.turn_state.active_unit_id).team=="player":
			for unit: Dictionary in policy.units: unit.team="enemy" if unit.team=="player" else "player"
		var command: Dictionary=review.app.CombatResolver.choose_enemy_command(policy,"cmd_%03d" % review.app.command_index)
		var before: int=review.app.command_index
		await review.click(review._action_button(command.action_id))
		if command.target.type=="tile":
			await review.click(review._tile_button(command.target.position))
			await review.click(review._tile_button(command.target.position))
		elif command.target.type=="unit":
			await review.click(review._tile_button(review.app._unit_by_id(command.target.unit_id).position))
		var deadline:=Time.get_ticks_msec()+10000
		while review.app.animation_locked and Time.get_ticks_msec()<deadline: await review.frames(1)
		review.check(not review.app.animation_locked and review.app.command_index==before+1,"ordinary campaign battle command completes once: "+str(index))
		commands.append(command)
		if not review.errors.is_empty(): return
	for event: Dictionary in review.app.state.event_log:
		review.check(event.type!="command_rejected" and event.get("source","")!="debug_win","campaign battle has no rejected or forced result")

func _pan_without_travel() -> void:
	var map: Control=review.app.map
	var before: Dictionary=campaign.state.duplicate(true)
	map.camera.zoom_at(map.size*.5,3.0,map.size);map._layout()
	await review.frames(4)
	for button: int in [MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]:
		var center: Vector2=map.camera.center
		var start: Vector2=map.get_global_position()+map.size*.5
		var delta:=Vector2(-80,35)
		var mask: int=MOUSE_BUTTON_MASK_RIGHT if button==MOUSE_BUTTON_RIGHT else MOUSE_BUTTON_MASK_MIDDLE
		var down:=InputEventMouseButton.new();down.button_index=button;down.pressed=true;down.button_mask=mask;down.position=start;down.global_position=start
		review.viewport.push_input(down,true);await review.frames(2)
		var motion:=InputEventMouseMotion.new();motion.position=start+delta;motion.global_position=motion.position;motion.relative=delta;motion.button_mask=mask
		review.viewport.push_input(motion,true);await review.frames(2)
		var up:=InputEventMouseButton.new();up.button_index=button;up.pressed=false;up.position=start+delta;up.global_position=up.position
		review.viewport.push_input(up,true);await review.frames(2)
		review.check(map.camera.center.distance_to(center)>.001 and map.drag_button==0,"native map pan and release button"+str(button))
		review.check(campaign.same_data(campaign.state,before) and review.app.speed==0,"native pan leaves time/resources/course unchanged")
