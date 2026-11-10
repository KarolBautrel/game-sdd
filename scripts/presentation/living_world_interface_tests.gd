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
		await contract_feedback(world,campaign)
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

func contract_feedback(world: Control, campaign: Node) -> void:
	# Trusted UI boundary fixtures, separate from ordinary travel evidence.
	var saved: Dictionary = campaign.state.duplicate(true)
	world.tabs.current_tab = 1
	await frames()
	var card: Node = world.contract_nodes.supply_saltwatch.panel
	var delivery: Dictionary = world.contract_nodes.supply_saltwatch
	var state: Dictionary = campaign.state.living_world
	state.party.position = Living.site("saltwatch",state).position.duplicate()
	state.contracts.supply_saltwatch.stage = "accepted"
	campaign.state.world.location_id = "saltwatch"
	campaign.state.supplies.food = 2
	world._refresh()
	await frames()
	check(delivery.status.text.contains("Food carried: 2/3"), "contract status shows actual carried food")
	check(delivery.report.disabled and delivery.report.tooltip_text == "Need 3 food; carrying 2.", "disabled delivery explains exact shortage")
	var before: Dictionary = campaign.state.duplicate(true)
	delivery.report.pressed.emit()
	check(campaign.same_data(campaign.state,before) and world.footer.text.contains("Need 3 food"), "UI and command share shortage reason without spending stock")
	campaign.state.supplies.food = 3
	world._refresh()
	check(not delivery.report.disabled and delivery.report.tooltip_text.contains("3 owned food"), "owned stock refresh enables delivery with action tooltip")
	check(campaign.living_course(Vector2.ZERO,"black_keep"), "actual outgoing course fixture")
	world._refresh()
	check(delivery.report.disabled and delivery.report.tooltip_text.contains("Stop at Saltwatch"), "moving issuer state disables report with reason")
	check(campaign.living_camp(false), "stop fixture without advancing time")
	campaign.state.living_world.party.position = Living.site("black_keep",campaign.state.living_world).position.duplicate()
	campaign.state.world.location_id = "black_keep"
	campaign.state.living_world.contracts.scout_pass.stage = "accepted"
	world._refresh()
	await frames()
	var scout: Dictionary = world.contract_nodes.scout_pass
	check(scout.report.disabled and scout.report.tooltip_text.contains("Visit High Pass"), "recon explains unvisited objective")
	check(scout.status.text.contains("Visit High Pass, then report to Black Keep"), "recon card names target and issuer")
	campaign.state.living_world.contracts.scout_pass.stage = "objective"
	campaign.state.living_world.intelligence = true
	world._refresh()
	check(not scout.report.disabled and scout.status.text.contains("Objective complete"), "real card enables objective report")
	var gold: int = campaign.state.gold
	scout.report.pressed.emit()
	check(campaign.state.gold == gold+18 and scout.report.disabled and scout.status.text.contains("Paid"), "UI report pays once and refreshes paid card")
	check(scout.report.tooltip_text == "Contract already paid.", "paid card explains disabled state")
	before = campaign.state.duplicate(true)
	scout.report.pressed.emit()
	check(campaign.same_data(campaign.state,before), "repeated UI signal cannot duplicate payment")
	await frames()
	check(world.contract_nodes.supply_saltwatch.panel == card, "refresh preserves existing card identity")
	for widgets: Dictionary in world.contract_nodes.values():
		if not widgets.panel.visible: continue
		check(widgets.panel.get_global_rect().grow(2).encloses(widgets.status.get_global_rect()), "progress label stays inside its padded card")
		check(widgets.status.get_minimum_size().x <= widgets.status.size.x+1, "progress copy wraps within available width")
	campaign.state = saved
	world.tabs.current_tab = 0
	world._refresh()
	await frames()
