extends SceneTree
const World := preload("res://scripts/domain/living_world.gd")
const Campaign := preload("res://scripts/session/campaign_session.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func profile() -> Dictionary:
	var value:=Campaign.initial_profile()
	value.living_world=World.initial(170717)
	value.supplies.food=16
	value.gold=80
	return value
func _run() -> void:
	var a:=profile()
	check(World.valid(a.living_world),"initial world validates")
	check(World.at_town(a.living_world) and World.food_price(a.living_world)==2,"real Ravenford shortage price")
	check(a.living_world.contracts.restore_mine.stage=="offered","mine threat causes restoration offer")
	for entry: Dictionary in World.definition().sites:
		check(not World.path_between(World.point(a.living_world.party.position),World.point(entry.position)).is_empty(),"passable path to "+str(entry.id))
	check(World.path_between(World.point(a.living_world.party.position),Vector2(.95,.9)).is_empty(),"sea route rejected")
	var before:=a.duplicate(true)
	check(not World.course(a,Vector2(NAN,.5)) and a==before,"non-finite destination rejected atomically")
	check(World.accept(a,"restore_mine") and not World.accept(a,"restore_mine"),"accept existing mine contract once at issuer")
	check(not World.report(a,"restore_mine"),"no reward before dungeon objective")
	var b:=a.duplicate(true)
	World.advance(a,960)
	World.advance(b,960)
	check(a==b,"identical ticks reproduce world activity and upkeep")
	check(a.gold==50 and a.supplies.food==0 and a.world.elapsed_hours==240,"exact daily wages and eight-hour food across ten terrain-aware days")
	check(a.living_world.raids>0 and a.living_world.deliveries>0,"persistent caravan raids/deliveries both occur (%s/%s)" % [a.living_world.raids,a.living_world.deliveries])
	check(a.living_world.politics.phase=="border_war" and a.living_world.politics.skirmishes>0,"faction rivalry advances to consequential conflict")
	check(a.living_world.journal.size()<=24 and World.valid(a.living_world),"bounded journal and valid long simulation")
	var run: Dictionary={"living_site":"dungeon_old_mine","data":{"rooms":[{"id":"guard","content":[{"type":"combat"}]}]},"state":{"cleared_room_ids":[]}}
	before=a.duplicate(true)
	check(not World.expedition_result(a,run,"completed") and a==before,"bypassed combat does not restore mine")
	run.state.cleared_room_ids=["guard"]
	check(not World.expedition_result(a,run,"retreated") and a==before,"retreat does not restore mine")
	check(World.expedition_result(a,run,"completed"),"completed defended mine restores world")
	check(a.living_world.mine.status=="cleared" and not a.living_world.actors[3].active and a.living_world.contracts.restore_mine.stage=="objective","raid base closes and contract objective advances")
	var raids: int=a.living_world.raids
	World.advance(a,192)
	check(a.living_world.raids==raids,"cleared mine does not spawn new raids")
	check(World.report(a,"restore_mine"),"report completed objective at Ravenford")
	before=a.duplicate(true)
	check(not World.report(a,"restore_mine") and not World.expedition_result(a,run,"completed") and a==before,"repeated reporting/clear cannot farm rewards")
	check(a.living_world.factions.river_league.relation==10,"contract changes faction relation")
	var corrupt: Dictionary=a.living_world.duplicate(true)
	corrupt.party.position.x=NAN
	check(not World.valid(corrupt),"reject non-finite save coordinates")
	corrupt=a.living_world.duplicate(true)
	corrupt.actors[0].index=999
	check(not World.valid(corrupt),"reject invalid moving actor route cursor")
	for failure in failures: push_error(failure)
	print("living_world_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
