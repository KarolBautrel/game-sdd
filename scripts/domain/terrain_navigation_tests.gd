extends SceneTree
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
const World:=preload("res://scripts/domain/living_world.gd")
const Campaign:=preload("res://scripts/session/campaign_session.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func fixture(rows: Array) -> RefCounted:
	var nav:=Terrain.new()
	nav.configure({"version":1,"revision":1,"region":"living_marches_v1","width":rows[0].length(),"height":rows.size(),"rows":rows})
	return nav
func _run() -> void:
	var nav:=fixture(["PPWPPPPP","PPWPPPPP","PPWPPPPP","PPBPPPPP","PPWPPPPP","PPWPPPPP","PPWPPPPP","PPWPPPPP"])
	var start:=Vector2(.15,.18)
	var destination:=Vector2(.7,.18)
	var route: Array=nav.route(start,destination)
	check(not route.is_empty() and not nav.line_clear(start,destination),"river forces a detour")
	var bridge_seen:=false
	var safe:=true
	var previous:=start
	for step: Dictionary in route:
		var position:=World.point(step)
		bridge_seen=bridge_seen or nav.code_at(position)=="B"
		safe=safe and nav.line_clear(previous,position);previous=position
	check(bridge_seen and safe,"exact route crosses only the authored bridge with safe endpoints")
	check(nav.route(start,Vector2(.3,.1)).is_empty(),"water destination rejected")
	var corner:=fixture(["PWWW","WPWW","WWPP","WWPP"])
	check(corner.route(Vector2(.1,.1),Vector2(.3,.3)).is_empty(),"diagonal corner cutting is forbidden")
	check(corner.nearest(Vector2(.3,.3),Vector2(.1,.1)).is_equal_approx(corner.center(Vector2i.ZERO)),"recovery cannot strand a saved company on a disconnected pocket")
	var weighted:=fixture(["RRRRRRRR","RMMMMMMR","RMMMMMMR","RMMMMMMR","RMMMMMMR","RMMMMMMR","RMMMMMMR","RRRRRRRR"])
	start=weighted.center(Vector2i(0,3));destination=weighted.center(Vector2i(7,3))
	route=weighted.route(start,destination)
	var detour:=false
	for step: Dictionary in route:
		if World.point(step).y<.2 or World.point(step).y>.8: detour=true
	check(detour and weighted.route_cost(start,route)<weighted.route_cost(start,[World.packed(destination)]),"weighted A* prefers a longer road to a short difficult slope")
	var distances: Array[float]=[]
	for code: String in ["R","P","F","H","M"]:
		var flat:=fixture([code.repeat(8),code.repeat(8),code.repeat(8),code.repeat(8)])
		var unit: Dictionary={"position":{"x":.05,"y":.5}}
		flat.walk(unit,[{"x":.9,"y":.5}],.2)
		distances.append(World.point(unit.position).x-.05)
	for index in range(1,distances.size()): check(distances[index]<distances[index-1],"slower terrain grade "+str(index))
	var boundary:=fixture(["RRRRFFFF","RRRRFFFF","RRRRFFFF","RRRRFFFF"])
	var unit: Dictionary={"position":{"x":.375,"y":.5}}
	boundary.walk(unit,[{"x":.9,"y":.5}],(16.0/9.0)*(.125+.125*2))
	check(absf(World.point(unit.position).x-.625)<.00001,"one movement budget integrates both sides of a terrain boundary")
	var real: RefCounted=Terrain.current()
	check(real.connectivity_errors(World.navigation_anchors()).is_empty(),"all real sites and NPC waypoints are reachable")
	check(not real.passable(Vector2(.28,.60)) and not real.passable(Vector2(.81,.06)),"visible river and high snowy ridge are blocked")
	check(real.passable(World.point(World.site("high_pass").position)),"mountain saddle remains accessible")
	var company:=Campaign.initial_profile();company.living_world=World.initial(170717);company.supplies.food=100
	var all_safe:=true
	for tick in range(960):
		World.advance(company,1)
		for actor: Dictionary in company.living_world.actors:
			all_safe=all_safe and real.passable(World.point(actor.position))
	check(all_safe and company.living_world.deliveries>0 and company.living_world.politics.skirmishes>0,"ten-day NPC simulation respects terrain and preserves deliveries/conflict")
	var legacy:=Campaign.initial_profile();legacy.living_world=World.initial(170717)
	legacy.living_world.erase("terrain_signature")
	legacy.living_world.party.position={"x":.28,"y":.6}
	legacy.living_world.party.path=[World.site("dungeon_old_mine").position.duplicate()]
	legacy.living_world.party.goal="dungeon_old_mine"
	var before:=legacy.duplicate(true)
	check(World.valid(legacy.living_world) and legacy==before,"legacy mid-river save validates without a load-time rewrite")
	World.prepare_navigation(legacy.living_world)
	check(real.passable(World.point(legacy.living_world.party.position)) and not legacy.living_world.party.path.is_empty() and legacy.gold==before.gold and legacy.living_world.contracts==before.living_world.contracts,"explicit transaction recovers blocked position and replans without lost progress")
	check(legacy.living_world.journal.back().text.contains("nearest accessible"),"recovery is explained in persistent journal")
	before=legacy.duplicate(true);World.prepare_navigation(legacy.living_world)
	check(legacy==before,"unchanged mask does not repeatedly migrate the company")
	var profile_path: String="user://qa_living_world_terrain_%s.json" % Time.get_ticks_usec()
	var disk: Dictionary=before.duplicate(true)
	disk.living_world.terrain_signature="0".repeat(64)
	disk.living_world.party.position={"x":.28,"y":.6}
	var writer:=FileAccess.open(profile_path,FileAccess.WRITE);writer.store_string(JSON.stringify(disk,"\t",true,true));writer.close()
	var original_bytes:=FileAccess.get_file_as_string(profile_path)
	var campaign:=Campaign.new()
	check(campaign.load_profile(profile_path) and FileAccess.get_file_as_string(profile_path)==original_bytes,"stale-mask disk profile loads without rewriting progress")
	var original_state: Dictionary=campaign.state.duplicate(true)
	check(not campaign.living_course(Vector2(.95,.9)) and Campaign.same_data(campaign.state,original_state),"invalid course does not publish a mask migration")
	campaign.save_path="user://missing_terrain_%s/profile.json" % Time.get_ticks_usec()
	check(not campaign.advance_living() and Campaign.same_data(campaign.state,original_state) and FileAccess.get_file_as_string(profile_path)==original_bytes,"failed migration commit rolls back recovered positions, routes and clock")
	campaign.save_path=profile_path
	check(campaign.advance_living() and campaign.state.living_world.terrain_signature==real.signature and real.passable(World.point(campaign.state.living_world.party.position)),"next successful tick atomically persists terrain recovery")
	check(campaign.state.gold==original_state.gold and campaign.state.living_world.contracts==original_state.living_world.contracts,"mask recovery preserves campaign rewards and contract progress")
	campaign.free();DirAccess.remove_absolute(profile_path)
	var path: String="user://qa_terrain_domain_%s.json" % Time.get_ticks_usec()
	check(Terrain.save_map(path,real.data,World.navigation_anchors()).is_empty(),"validated atomic mask save")
	var bytes:=FileAccess.get_file_as_string(path)
	var invalid: Dictionary=real.data.duplicate(true);invalid.rows[0]="?"
	check(not Terrain.save_map(path,invalid,World.navigation_anchors()).is_empty() and FileAccess.get_file_as_string(path)==bytes,"invalid rows cannot overwrite a good mask")
	invalid=real.data.duplicate(true)
	var at: Vector2i=real.cell(World.point(World.site("town_ravenford").position))
	invalid.rows[at.y]=str(invalid.rows[at.y]).substr(0,at.x)+"W"+str(invalid.rows[at.y]).substr(at.x+1)
	check(not Terrain.save_map(path,invalid,World.navigation_anchors()).is_empty() and FileAccess.get_file_as_string(path)==bytes,"blocked required site cannot be saved")
	DirAccess.remove_absolute(path)
	for failure in failures: push_error(failure)
	print("terrain_navigation_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
