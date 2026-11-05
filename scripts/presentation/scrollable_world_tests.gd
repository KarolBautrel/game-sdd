extends SceneTree
const Camera:=preload("res://scripts/presentation/world/map_camera.gd")
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frames() -> void:
	for frame in range(8): await process_frame
func run() -> void:
	for dimensions: Vector2 in [Vector2(800,460),Vector2(1200,800),Vector2(1900,700)]:
		var camera:=Camera.new();camera.focus(Vector2(.4,.6),dimensions)
		var pixel:=dimensions*Vector2(.42,.56)
		var anchor:=camera.world_at(pixel,dimensions)
		camera.zoom_at(pixel,1.2,dimensions)
		check(camera.world_at(pixel,dimensions).distance_to(anchor)<.00001,"pointer anchored zoom")
		for world: Vector2 in [Vector2(.1,.2),Vector2(.8,.7),Vector2(.4,.4)]:
			check(camera.world_at(camera.pixel_at(world,dimensions),dimensions).distance_to(world)<.00001,"shared forward/inverse projection")
		camera.pan_pixels(Vector2(100000,100000),dimensions)
		var rect:=camera.rect(dimensions)
		check(rect.position.x<=.01 and rect.position.y<=.01 and rect.end.x>=dimensions.x-.01 and rect.end.y>=dimensions.y-.01,"pan clamps without exposing outside map at local zoom")
		camera.overview(dimensions)
		check(camera.zoom==1 and camera.center==Vector2(.5,.5),"overview fits full world")
	var campaign:=root.get_node("CampaignSession");campaign.load_profile("",true);campaign.enable_generated_region(2087,"marches",2)
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		var viewport:=SubViewport.new();viewport.size=dimensions;root.add_child(viewport)
		var view: Control=load("res://scenes/world/LivingWorld.tscn").instantiate();view.scene_requested.connect(func(_path: String) -> void: pass);viewport.add_child(view);await frames()
		var map: Control=view.map
		check(map.camera.zoom>2 and map.paper_rect().size.x>map.size.x*2,"large live map opens at a local scale")
		var before: Dictionary=campaign.state.duplicate(true)
		map.camera.pan_pixels(Vector2(-180,80),map.size);map._layout();map._camera_action("in")
		check(campaign.same_data(before,campaign.state),"pan/zoom does not mutate company/time/course")
		map._camera_action("company")
		check(map._point(map.displayed("company")).distance_to(map.size*.5)<2,"Company returns view to displayed actual party")
		var hidden:=0
		for button: Button in map.site_buttons.values():
			if not button.visible: hidden+=1
			else: check(Rect2(Vector2.ZERO,map.size).encloses(button.get_rect()),"visible label fits local viewport")
		check(hidden>0,"offscreen site labels hide instead of stacking at edges")
		check(map.minimap.visible and Rect2(Vector2.ZERO,map.size).encloses(map.minimap.get_rect()),"overview chart fits local viewport")
		map._camera_action("overview")
		check(not map.minimap.visible and map.camera.zoom==1,"full overview hides redundant chart")
		for button: Button in map.site_buttons.values(): check(button.visible,"all six sites available in overview")
		view.queue_free();viewport.queue_free();await frames()
	campaign.load_profile("",true)
	for failure in failures: push_error(failure)
	print("scrollable_world_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
