extends SceneTree
const Views := [preload("res://scenes/world/StrategicVastWorld.tscn"),preload("res://scenes/world/StrategistVastWorld.tscn")]
const P := preload("res://scripts/domain/strategist_protocol.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func _initialize() -> void: run.call_deferred()
func frames() -> void:
	for i in range(4): await process_frame
func run() -> void:
	var owner := root.get_node("StrategicSession")
	for pixels: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		for model: bool in [false,true]:
			check(owner.call("open_model_seed" if model else "open_seed",2087,"marches",true,3),"open new Vast size in memory")
			var viewport := SubViewport.new();viewport.size=pixels;root.add_child(viewport)
			var view: Control=Views[1 if model else 0].instantiate();view.qa_memory=true;var routes: Array=[]
			view.scene_requested.connect(func(path): routes.append(path));viewport.add_child(view);await frames()
			check(view.map.size.x>=450 and view.map.size.y>=300,"Vast map retains useful viewport")
			check(view.world_size_input.get_item_metadata(view.world_size_input.selected)==3 and view.heading.text.contains("Vast"),"current world size is visibly correct")
			check(view.map.camera.zoom==5.2 and view.map.camera.max_zoom==9,"default Vast focus preserves native scale")
			check(view.map.camera.visible_world(view.map.size).get_area()<.08 and view.map.minimap.visible,"local chart requires genuine scrolling with a minimap")
			check(view.map.illustration.reference_width==6688,"painted detail grows with the real world")
			var before := P.encoded(owner.session.state)
			view.map.camera.pan_pixels(Vector2(600,400),view.map.size);view.map.camera_action("overview")
			check(view.map.camera.zoom==1,"explicit overview fits whole Vast world")
			view.map.camera_action("company");check(view.map.camera.zoom==5.2,"Company restores local Vast framing")
			check(P.encoded(owner.session.state)==before,"camera never advances/mutates company/world")
			for control: Control in [view.world_size_input,view.buttons.open,view.buttons.exit]:
				check(control.get_global_rect().position.x>=0 and control.get_global_rect().end.x<=pixels.x+1,"size/factory controls fit the viewport")
			view.world_size_input.select(0);check(P.encoded(owner.session.state)==before,"choosing another size does not change the current company")
			view.world_size_input.select(1);view._open_seed()
			check(routes.back()==owner.world_return_scene() and routes.back().contains("VastWorld"),"open/resume and managed return retain correct format/size scene")
			view.queue_free();viewport.queue_free();await frames()
	owner.deactivate()
	for failure: String in failures: push_error(failure)
	print("vast_interface_tests: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
