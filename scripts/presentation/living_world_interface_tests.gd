extends SceneTree
const Living := preload("res://scripts/domain/living_world.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frames() -> void:
	for frame in range(8): await process_frame
func _run() -> void:
	var campaign:=root.get_node("CampaignSession")
	for action in ["living_pause","living_speed_1","living_speed_2","living_speed_4"]: check(InputMap.has_action(action),"named input action: "+action)
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		campaign.load_profile("",true)
		campaign.enable_living_world()
		var viewport:=SubViewport.new()
		viewport.size=dimensions
		root.add_child(viewport)
		var world: Control=load("res://scenes/world/LivingWorld.tscn").instantiate()
		var routes: Array[String]=[]
		world.scene_requested.connect(func(path: String) -> void: routes.append(path))
		viewport.add_child(world)
		await frames()
		check(world.size==Vector2(dimensions) and world.speed==0,"world fills viewport and starts paused")
		check(world.map.size.y>dimensions.y*.5 and world.header_label.get_global_rect().end.y<180,"map has usable height; header never wraps to letter column")
		var bar: TabBar=world.tabs.get_tab_bar()
		check(bar.get_tab_rect(2).end.x<=bar.size.x,"all inspector tabs fit without hidden Chronicle")
		campaign.state=JSON.parse_string(JSON.stringify(campaign.state,"",true,true))
		world._refresh()
		check(not world.stock_label.text.contains(".0"),"integer stock display survives JSON reload")
		var previous: Array[Rect2]=[]
		for button: Button in world.map.site_buttons.values():
			check(Rect2(Vector2.ZERO,world.map.size).encloses(button.get_rect()),"site hit target inside map")
			for rect in previous: check(not rect.intersects(button.get_rect()),"site labels do not overlap")
			previous.append(button.get_rect())
		var before: Dictionary=campaign.state.duplicate(true)
		await frames()
		check(campaign.state==before,"paused rendering changes no campaign state")
		world.buttons.accept_restore_mine.pressed.emit()
		check(campaign.state.living_world.contracts.restore_mine.stage=="accepted","contract control uses campaign owner")
		world.map.site_buttons.dungeon_old_mine.pressed.emit()
		check(world.speed==1 and campaign.state.world.location_id=="town_ravenford" and not campaign.state.living_world.party.path.is_empty(),"map control starts a course without teleport")
		world.buttons.pause.pressed.emit()
		before=campaign.state.duplicate(true)
		world.buttons.stash.pressed.emit()
		check(routes.back()=="res://scenes/app/App.tscn" and campaign.state==before,"equipment scene navigation preserves paused world")
		var app: Control=load("res://scenes/app/App.tscn").instantiate()
		app.scene_requested.connect(func(path: String) -> void: routes.append(path))
		viewport.add_child(app)
		await frames()
		check(app.inventory_view and campaign.state==before,"App opens existing equipment for living company")
		app.action_buttons.close_stash.pressed.emit()
		check(routes.back()=="res://scenes/world/LivingWorld.tscn","equipment Back returns to living map")
		app.queue_free();world.queue_free();viewport.queue_free()
		await frames()
	campaign.load_profile("",true)
	for failure in failures: push_error(failure)
	print("living_world_interface_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
