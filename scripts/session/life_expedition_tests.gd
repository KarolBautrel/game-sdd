extends "res://scripts/session/regional_expedition_tests.gd"
const F := Session.Life
func _suite() -> String: return "life_expedition_tests"
func go_life(id: String) -> void:
	var catalog := R.sites(owner.session.state,owner.session.state.life.sites)
	check(owner.order("course",{"site":id,"position":catalog[id].position}),"course / "+id)
	for i in range(1000):
		if owner.session.state.travel.path.is_empty(): break
		if not owner.order("advance",{"ticks":1}): check(false,"travel / "+owner.last_feedback);return
	check(F.current(owner.session.state)==id,"actual life arrival / "+id)
func run() -> void:
	owner=root.get_node("StrategicSession");run_session=root.get_node("DungeonRunSession")
	path="user://qa_strategy_world_life_expedition_%d.json" % Time.get_ticks_usec()
	var session := Session.new();check(session.create_life(2087,path,false,"marches",2),"new independent disk campaign")
	if not session.loaded: finish();return
	owner.session=session;owner.active=true;run_session.clear()
	check(owner.order("advance",{"ticks":48}),"scouts report camp")
	var id: String=session.state.life.sites.road_camp.episode
	check(owner.order("accept_life",{"id":id}),"issuer reserves company exclusivity")
	go_life("road_camp")
	viewport=SubViewport.new();viewport.size=Vector2i(1920,1080);root.add_child(viewport)
	run_session.town_preparation=true
	var hud := Dungeon.instantiate();viewport.add_child(hud);await frames()
	check(hud.dungeon.generated_profile.theme=="forest" and hud.expedition_chrome.archetype=="forest","actual forest content and accepted Ashen skin")
	check(not hud.source_toggle_button.visible and not hud.generated_reroll_button.visible,"fixed site has no reroll controls")
	hud.expedition_chrome.pinned_start.pressed.emit();await frames()
	check(run_session.managed_run and owner.state.active_run.data.id==hud.dungeon.id,"ordinary packing owns actual site")
	room(hud,"watchfire");room(hud,"stockade")
	check(run_session.start_combat(hud.dungeon,hud.run_state,20261107),"normal guarded forest battle")
	var restored := Session.new();check(restored.load_profile(path),"pending forest fight reload")
	owner.session=restored;check(run_session.restore_campaign(),"owned forest continuation")
	var battle := Battle.instantiate();viewport.add_child(battle);await frames(5)
	for i in range(600):
		if battle._combat_result()!="in_progress": break
		var policy: Dictionary=battle.state.duplicate(true)
		if battle._unit_by_id(policy.turn_state.active_unit_id).team=="player":
			for unit: Dictionary in policy.units: unit.team="enemy" if unit.team=="player" else "player"
		var cmd: Dictionary=battle.CombatResolver.choose_enemy_command(policy,"cmd_%03d" % battle.command_index)
		commands.append(cmd.duplicate(true));battle._run_command_without_render(cmd)
	check(battle._combat_result()=="victory","ordinary resolver policy wins actual forest encounter")
	for e: Dictionary in battle.state.event_log: check(e.type!="command_rejected" and e.get("source","")!="debug_win","legal normal commands")
	check(run_session.finish_combat(battle._combat_result_payload()),"ordinary battle result owns clearance")
	battle.queue_free();hud.queue_free();await frames()
	hud=Dungeon.instantiate();viewport.add_child(hud);await frames()
	hud.reward_button.pressed.emit();check(hud.run_state.run_inventory.gold==7,"owned stockade loot once")
	room(hud,"exit")
	var before: Dictionary=owner.session.state.duplicate(true)
	check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(path+".tmp"))==OK,"owned failed-save blocker")
	hud.finish_button.pressed.emit()
	check(R.Legacy.same_data(before,owner.session.state) and owner.session.state.life.sites.road_camp.status=="occupied","failed save grants neither clearing nor loot")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path+".tmp"))
	var routes: Array=[];hud.scene_requested.connect(func(destination): routes.append(destination))
	hud.world_button.pressed.emit();await frames()
	check(routes==["res://scenes/world/AutonomousLargeWorld.tscn"] and owner.state.active_run.is_empty(),"return to correct world owner")
	check(owner.session.state.life.sites.road_camp.status=="cleared" and owner.session.state.life.episodes[id].contract.status=="objective","real success readies one commission")
	check(owner.session.state.mine.status=="occupied","new target never restores legacy mine")
	hud.queue_free();await frames();go_life("town_ravenford")
	var gold: int=owner.state.gold;var xp: int=owner.state.xp
	check(owner.order("report_life",{"id":id}) and owner.state.gold==gold+24 and owner.state.xp==xp+8,"one frozen reward at issuer")
	before=owner.session.state.duplicate(true)
	check(not owner.order("report_life",{"id":id}) and R.Legacy.same_data(before,owner.session.state),"no double payment")
	restored=Session.new();check(restored.load_profile(path) and R.Legacy.same_data(restored.state,owner.session.state),"complete episode/loot/payment reload")
	var output := "res://artifacts/qa-runs/life-expedition"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var file := FileAccess.open(output+"/ordinary-commands.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"headless":true,"physical":"NOT_RUN","debug_win":false,"commands":commands,"site":owner.session.state.life.sites.road_camp},"\t",true,true));file.close()
	owner.deactivate();viewport.queue_free();await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path));finish()
