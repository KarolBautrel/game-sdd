extends SceneTree
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
const World:=preload("res://scripts/domain/living_world.gd")
const Campaign:=preload("res://scripts/session/campaign_session.gd")
const Map:=preload("res://scripts/presentation/world/living_map.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func flat(width: int=192,height: int=108) -> RefCounted:
	var nav:=Terrain.new()
	var rows: Array=[]
	for y in range(height): rows.append("R".repeat(width))
	nav.configure({"version":1,"region":"living_marches_v1","revision":1,"width":width,"height":height,"rows":rows})
	return nav
func profile() -> Dictionary:
	var value:=Campaign.initial_profile();value.living_world=World.initial(170717)
	return value
func run() -> void:
	var original: RefCounted=Terrain.current()
	var nav:=flat();Terrain.cached=nav
	var map:=Map.new();root.add_child(map)
	var value:=profile()
	var start: Vector2=(Vector2(42,66)+Vector2(.65,.5))/Vector2(192,108)
	var finish: Vector2=(Vector2(42,66)+Vector2(.85,.5))/Vector2(192,108)
	var short_path: Array=nav.route(start,finish)
	check(short_path.size()==1 and World.point(short_path[0]).distance_to(finish)<.000001,"real within-cell course avoids an unnecessary center detour")
	value.living_world.party.position=World.packed(start);map.update_state(value)
	var next:=value.duplicate(true);next.living_world.tick=1;next.living_world.party.position=World.packed(finish)
	map.update_state(next,.6,{"tick":1,"units":{"company":[{"time":0.0,"position":World.packed(start)},{"time":1.0,"position":World.packed(finish)}]}})
	var previous:=start.x
	var forward:=true
	for frame in range(61):
		map.set_phase(float(frame)/60)
		forward=forward and map.displayed("company").x>=previous-.0000001
		previous=map.displayed("company").x
	check(forward and map.displayed("company").distance_to(finish)<.000001,"within-cell movement never reverses toward a cell center")
	map.queue_free()
	var mixed:=flat(8,4)
	var data: Dictionary=mixed.data.duplicate(true);data.rows=["RRRRFFFF","RRRRFFFF","RRRRFFFF","RRRRFFFF"];mixed.configure(data)
	var unit: Dictionary={"position":{"x":.375,"y":.5}}
	var detail: Dictionary={}
	var budget: float=(16.0/9.0)*(.125+.125*2)
	mixed.walk(unit,[{"x":.9,"y":.5}],budget,detail)
	var units: Dictionary={};World._trace(units,"company",detail,0,budget)
	var boundary_time: float=-1
	for sample: Dictionary in units.company:
		if absf(float(sample.position.x)-.5)<.000001: boundary_time=sample.time
	check(absf(boundary_time-1.0/3.0)<.00001,"trace spends the correct fraction before the forest boundary")
	check(absf(float(units.company.back().position.x)-.625)<.00001 and absf(float(units.company.back().time)-1)<.00001,"trace endpoint matches exact weighted-budget movement")
	var state: Dictionary=profile().living_world
	var a: Vector2=nav.center(Vector2i(40,50));var b: Vector2=nav.center(Vector2i(41,50))
	state.actors[0].position=World.packed(a)
	state.actors[0].route=[World.packed(a),World.packed(b),World.packed(nav.center(Vector2i(42,50))),World.packed(nav.center(Vector2i(70,50)))]
	state.actors[0].index=1;state.actors[0].path=[]
	units={};World._actors(state,units)
	check(World.point(state.actors[0].position).x>b.x and state.actors[0].index==2,"NPC carries remaining budget through an intermediate waypoint")
	check(float(units.caravan.back().time)>.999,"NPC trace spans the whole available movement interval")
	state.actors[1].position=World.packed(a);state.actors[1].route=[World.packed(a),World.packed(b)];state.actors[1].index=1;state.actors[1].path=[]
	World._actors(state)
	check(World.point(state.actors[1].position).distance_to(b)<.000001 and int(state.actors[1].wait_until)>int(state.tick),"patrol guard remains a deliberate endpoint stop")
	var failed:=Campaign.new();failed.load_profile("",true);failed.enable_living_world();failed.advance_living()
	var before: Dictionary=failed.state.duplicate(true);var trace_before: Dictionary=failed.living_motion.duplicate(true)
	failed.memory_only=false;failed.save_path="user://missing_motion_%s/profile.json" % Time.get_ticks_usec()
	check(not failed.advance_living() and Campaign.same_data(failed.state,before) and failed.living_motion==trace_before,"failed transaction publishes neither state nor trace")
	check(not failed.state.has("living_motion") and not failed.state.living_world.has("motion"),"motion remains transient rather than entering the save schema")
	failed.load_profile("",true);check(failed.living_motion.is_empty(),"reload discards old render traces")
	failed.free()
	var campaign: Node=root.get_node("CampaignSession")
	var results: Dictionary={}
	for rate in [1,2,4]:
		for fps in [30,60,144]:
			campaign.load_profile("",true);campaign.enable_living_world()
			# Simulation-only movement fixture, not a claimed dungeon victory.
			campaign.state.living_world.mine={"status":"cleared","threat":0}
			var viewport:=SubViewport.new();viewport.size=Vector2i(1280,720);root.add_child(viewport)
			var view: Control=load("res://scenes/world/LivingWorld.tscn").instantiate();view.scene_requested.connect(func(_path: String) -> void: pass)
			viewport.add_child(view);view.set_process(false)
			view._course(Vector2(.95,.62),"");view.set_speed(rate)
			var monotonic:=true;var last: Vector2=view.map.displayed("company")
			var zero_frames:=0
			for frame in range(fps*3):
				view._process(1.0/fps)
				var position: Vector2=view.map.displayed("company")
				monotonic=monotonic and position.x>=last.x-.000001
				if frame>fps and position.distance_to(last)<.0000001: zero_frames+=1
				last=position
			check(monotonic and zero_frames==0,"continuous forward motion across ticks / %dx / %dFPS" % [rate,fps])
			var result: Dictionary={"position":last,"tick":campaign.state.living_world.tick}
			if results.has(rate):
				check(last.distance_to(results[rate].position)<.000005 and result.tick==results[rate].tick,"frame-rate independent distance and clock / %dx / %dFPS" % [rate,fps])
			else: results[rate]=result
			view._process(.037)
			var paused: Vector2=view.map.displayed("company");var phase: float=view.accumulated
			view.set_speed(0);var stopped: Dictionary=campaign.state.duplicate(true);view._process(.8)
			check(view.map.displayed("company").is_equal_approx(paused) and view.accumulated==phase and Campaign.same_data(campaign.state,stopped),"pause freezes exact pose, phase and state")
			view.set_speed(2)
			check(view.map.displayed("company").is_equal_approx(paused) and view.accumulated==phase,"resume/speed change preserves pose and sub-tick time")
			view._process(1.0/144)
			check(view.map.displayed("company").x>paused.x,"resume continues on the next frame without another full tick wait")
			view.queue_free();viewport.queue_free()
			for frame in range(2): await process_frame
	Terrain.cached=original;campaign.load_profile("",true)
	for failure in failures: push_error(failure)
	print("living_motion_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
