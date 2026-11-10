extends SceneTree
const View := preload("res://scenes/world/AutonomousWorld.tscn")
const F := preload("res://scripts/domain/life_campaign.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok: failures.append(text)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var owner := root.get_node("StrategicSession")
	for pixels: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		check(owner.open_life_seed(2087,"marches",true,3),"new memory-only Vast life campaign")
		var viewport := SubViewport.new();viewport.size=pixels;root.add_child(viewport)
		var view := View.instantiate();view.qa_memory=true;var routes: Array=[]
		view.scene_requested.connect(func(path): routes.append(path));viewport.add_child(view)
		for i in range(5): await process_frame
		check(view.tabs.get_tab_count()==6 and view.map.site_buttons.size()==14,"native world tab and real extra sites")
		check(view.map.size.x>=450 and view.map.size.y>=300,"usable map / "+str(pixels))
		var before: Dictionary=owner.session.state.duplicate(true)
		view.tabs.current_tab=5;view._refresh();view.buttons.district_highlands.pressed.emit()
		check(F.R.Legacy.same_data(before,owner.session.state),"district report/focus is read-only")
		view.buttons.life_wait.pressed.emit();await process_frame
		check(owner.session.state.strategy_world.core.tick==96,"explicit day wait advances exactly ordinary time")
		var id: String=owner.session.state.life.sites.road_camp.episode
		var row: Dictionary=view.life_panel.rows[id]
		check(not row.accept.disabled and row.report.disabled,"issuer/claim affordances match domain")
		row.accept.pressed.emit();await process_frame
		check(owner.session.state.life.episodes[id].contract.status=="company" and row.accept.disabled,"native exclusive claim persists once")
		var position: Dictionary=owner.session.state.life.sites.road_camp.position
		view.select_life_site("road_camp")
		check(view.selected=="road_camp" and owner.session.state.travel.path.is_empty(),"inspection does not issue a course")
		view.buttons.travel.pressed.emit();await process_frame
		check(owner.session.state.travel.goal=="road_camp","explicit extra-site route")
		check(owner.order("advance",{"ticks":1}),"ordinary tick for party trace")
		view._refresh();view.map.set_phase(.5)
		for aid: String in owner.session.state.life.actors:
			check(view.map.actor_buttons.has(aid),"rival has one native marker")
			check(F.R.G.Gen.navigation(owner.session.state.region.base).passable(view.map.actor_position(aid)),"interpolated actor stays on safe terrain")
		for i in range(80):
			if owner.session.state.travel.path.is_empty(): break
			if not owner.order("advance",{"ticks":1}): break
		view._refresh()
		check(F.current(owner.session.state)=="road_camp" and not view.buttons.prepare.disabled,"native preparation enabled at claimed camp")
		for button: Button in view.buttons.values():
			if not button.is_visible_in_tree(): continue
			check(button.get_global_rect().position.x>=-1 and button.get_global_rect().end.x<=pixels.x+1,"action remains within screen")
		view.buttons.prepare.pressed.emit()
		check(routes==["res://scenes/dungeon/DungeonDebug.tscn"] and root.get_node("DungeonRunSession").town_preparation,"owned dungeon route")
		check(owner.world_return_scene()=="res://scenes/world/AutonomousWorld.tscn","Vast return preserves profile")
		check(not view.life_panel.activity.text.contains("wallet") and not view.life_panel.activity.text.contains("treasury"),"private resources not exposed")
		viewport.queue_free();owner.deactivate();await process_frame
	for f: String in failures: push_error(f)
	print("world_life_interface_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
