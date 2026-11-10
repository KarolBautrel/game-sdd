extends SceneTree
const View := preload("res://scenes/world/StrategicWorld.tscn")
const R := preload("res://scripts/domain/strategic_region.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var owner := root.get_node("StrategicSession")
	for pixels: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		check(owner.open_seed(2087,"marches",true),"fresh memory-only native region")
		var viewport := SubViewport.new();viewport.size=pixels;root.add_child(viewport)
		var view := View.instantiate();view.qa_memory=true;var routes: Array=[]
		view.scene_requested.connect(func(path): routes.append(path));viewport.add_child(view)
		for i in range(5): await process_frame
		check(view.map.site_buttons.size()==9 and view.tabs.get_tab_count()==5,"native nine sites and five inspector tabs")
		check(view.map.size.x>=450 and view.map.size.y>=300,"map remains usable at "+str(pixels))
		for button: Button in view.buttons.values():
			if not button.is_visible_in_tree(): continue
			check(button.get_global_rect().position.x>=-1 and button.get_global_rect().end.x<=pixels.x+1,"visible action stays horizontally on screen")
		var snapshot: Dictionary=owner.session.state.duplicate(true)
		view.faction_input.select(1);view._refresh()
		check(R.Legacy.same_data(snapshot,owner.session.state),"inspector/chronicle queries are read-only")
		check(not view.factions.text.contains("claim") and not view.factions.text.contains("treasury"),"public inspector excludes secret plan/treasury")
		view.tabs.current_tab=2;await process_frame
		view.set_speed(4);check(view.speed==0 and view.buttons.speed4.disabled,"jobs pause and block accidental clock restart")
		var job_id := ""
		for j: Dictionary in owner.session.state.jobs.values():
			if j.kind=="restoration": job_id=j.id
		var row: Dictionary=view.job_rows[job_id];check(not row.accept.disabled and row.report.disabled,"actual issuer contract uses correct enablement")
		row.accept.pressed.emit();await process_frame
		check(owner.session.state.jobs[job_id].status=="accepted" and row.accept.disabled,"native accept dispatches durable command once")
		check(row.panel==view.job_rows[job_id].panel,"job row identity survives refresh")
		view.tabs.current_tab=0;await process_frame
		var food: int=owner.state.supplies.food;view.buttons.buy.pressed.emit()
		check(owner.state.supplies.food==food+1,"real native provisions exchange")
		var before: Dictionary=owner.session.state.duplicate(true)
		view.map.camera_action("overview");view.map.camera_action("in");view.map.camera_action("company")
		check(R.Legacy.same_data(before,owner.session.state),"camera controls never issue a travel order")
		var button: Button=view.map.site_buttons.dungeon_old_mine
		button.pressed.emit();check(not owner.session.state.travel.path.is_empty(),"site button issues terrain-safe company course")
		view.set_speed(1)
		view._process(.25);view._process(.25);view._process(.25)
		check(owner.session.state.strategy_world.core.tick>before.strategy_world.core.tick,"native clock commits real simulation ticks")
		view.set_speed(0)
		var tick: int=owner.session.state.strategy_world.core.tick
		view._process(5);check(owner.session.state.strategy_world.core.tick==tick,"paused native map advances no time")
		check(view.map.actor_buttons.size()>=4,"actual mobile faction actors have native controls")
		view.queue_free();viewport.queue_free();await process_frame;await process_frame
	owner.deactivate()
	for failure: String in failures: push_error(failure)
	print("strategic_interface_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
