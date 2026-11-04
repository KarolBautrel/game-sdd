extends SceneTree
const Model := preload("res://scripts/domain/town_exploration_model.gd")
var checks:=0
var failures: Array[String]=[]

func _initialize() -> void:_run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)

func _run() -> void:
	var map: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/maps/ravenford_courtyard_pilot.json"))
	for point in [Vector2(0,0),Vector2(5.5,6.5),Vector2(11.9,9.9)]:check(Model.unproject(Model.project(point)).is_equal_approx(point),"projection roundtrip")
	for fps in [30,60,144]:
		for direction in [Vector2.RIGHT,Vector2(1,1)]:
			var point:=Vector2(2.5,4.5);var start:=point
			for i in range(fps):point=Model.move(point,direction,1.0/fps,map)
			check(absf(Model.project(point-start).length()-104.0)<0.02,"normalized one-second104px stride at"+str(fps))
	var barrier:=map.duplicate(true)
	for tile: Dictionary in barrier.tiles:tile.type="blocked" if int(tile.x)==6 else "floor"
	var stopped:=Model.move(Vector2(5.5,4.5),Model.project(Vector2.RIGHT).normalized(),2.0,barrier)
	check(stopped.x<5.85 and Model.walkable(stopped,barrier),"swept large timestep cannot tunnel through continuous wall")
	var point:=Vector2(1.5,2.5)
	for i in range(300):
		point=Model.move(point,Vector2(-1,-1),1.0/60.0,map)
		check(Model.walkable(point,map),"boundary sweep stays valid")
	var path: Array[Vector2]=[Vector2(2.5,3.5),Vector2(2.5,4.5),Vector2(3.5,4.5),Vector2(4.5,4.5)]
	for distance in range(0,160,4):check(Model.walkable(Model.trail_position(path,float(distance)),map),"breadcrumb follows valid bent route")
	var npcs: Array=[{"id":"b","position":{"x":2.5,"y":3.5}},{"id":"a","position":{"x":2.5,"y":3.5}}]
	check(Model.nearest(Vector2(2.5,3.5),npcs)=="a","nearest stable id tie")
	check(Model.nearest(Vector2(10,8),npcs).is_empty(),"distant NPC has no prompt")
	var campaign:=root.get_node("CampaignSession");campaign.load_profile("",true)
	var before: Dictionary=campaign.state.duplicate(true)
	var viewport:=SubViewport.new();viewport.size=Vector2i(1280,720);root.add_child(viewport)
	var scene: Control=load("res://scenes/town/TownExploration.tscn").instantiate();viewport.add_child(scene)
	for i in range(6):await process_frame
	scene.set_physics_process(false)
	check(scene.actors.size()==6,"three party members and three NPC stand-ins")
	check(scene.world.scale.x>0.3,"initial courtyard layout has nonzero usable scale")
	for actor: Dictionary in scene.actors:check(actor.sprite.texture!=null,"source-complete painted sprite loaded")
	scene.held.town_left=true;scene._physics_process(0.6);scene.held.clear()
	check(not scene.near_id.is_empty(),"ordinary approach produces nearby NPC prompt")
	var anchor: Vector2=scene.party_positions[0]
	scene._open_dialogue(scene.near_id)
	check(scene.blocker.visible and scene.speaker.text.contains("Varric"),"nearest watch dialogue visible")
	scene.held.town_right=true;scene._physics_process(0.8)
	check(scene.party_positions[0]==anchor,"dialogue blocks movement")
	scene._close_dialogue()
	check(scene.held.is_empty() and scene.talking_id.is_empty(),"cancel clears held movement and modal")
	# Follow around real obstacles/reversals, not only a straight path.
	for direction in ["town_right","town_up","town_left","town_down"]:
		scene.held={direction:true}
		for i in range(90):
			scene._physics_process(1.0/60.0)
			for follower: Vector2 in scene.party_positions:check(Model.walkable(follower,map),"party breadcrumb collision through turns")
	scene.held.clear()
	check(campaign.state==before,"town pilot never changes campaign profile")
	scene.queue_free();viewport.queue_free();await process_frame
	for failure in failures:push_error(failure)
	print("Town exploration: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
