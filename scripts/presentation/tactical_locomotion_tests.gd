extends SceneTree
const Art:=preload("res://scripts/presentation/combat/combat_unit_art.gd")
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func run() -> void:
	var art:=Art.new()
	for role: String in ["knight","warrior","archer_1","rogue_1","axe_bandit","bandit_spearman","painted_bandit_guard","painted_bandit_archer","painted_wolf"]:
		var unit: Dictionary={"id":"qa","team":"player","position":{"x":0,"y":0},"visual":{"character":role,"faction":"heroes"}}
		check(art.is_drawn_unit(unit),"painted locomotion mapping: "+role)
		check(is_equal_approx(art.movement_seconds(unit,160,0),1.0/1.18),"18% quicker actual160px stride: "+role)
		check(is_equal_approx(art.clip_seconds(unit,"walk",0),1.0),"source authored walk durations unchanged: "+role)
		for fps: int in [30,60,144]:
			for sample in range(fps*2):
				var distance:=float(sample)/fps*160*Art.LOCOMOTION_RATE
				var expected:=int(floor(fposmod(distance,160.0)/20.0+.0000001))%8
				check(art.walk_frame_at_distance(unit,distance)==expected,"distance-registered foot phase independent of render FPS")
		check(art.walk_frame_at_distance(unit,70+70)==7 and art.walk_frame_at_distance(unit,160)==0,"phase carries across route splits and wraps at physical stride")
	var previous: Variant=ProjectSettings.get_setting("debug/qa/combat_scenario","")
	ProjectSettings.set_setting("debug/qa/combat_scenario","painted_forest_ambush")
	var hud: Control=load("res://scenes/combat/CombatDebug.tscn").instantiate();root.add_child(hud)
	await process_frame;await process_frame
	var id: String=hud.state.turn_state.active_unit_id
	var carried:=0.0
	for x in [3,4]:
		var origin: Vector2=hud.unit_layer.get_node(id).position
		var mp: int=hud._unit_by_id(id).resources.mp
		hud._run_command(hud._build_command("move",{"type":"tile","position":{"x":x,"y":7}}))
		check(hud.animation_locked,"ordinary resolver move locks presentation")
		var samples:=0
		var until:=Time.get_ticks_msec()+4000
		while hud.animation_locked and Time.get_ticks_msec()<until:
			var node: Control=hud.unit_layer.get_node(id)
			var distance: float=carried+node.position.distance_to(origin)
			if hud.walk_distance_offsets.has(id):
				check(absf(float(hud.walk_distance_offsets[id])-distance)<.02,"root and foot phase share exact tween sample")
				check(str(hud.unit_visual_action[id])=="walk:%d" % art.walk_frame_at_distance(hud._unit_by_id(id),distance),"visible walking frame matches actual root displacement")
			samples+=1;await process_frame
		check(not hud.animation_locked and samples>2,"actual movement completes within bound")
		check(hud._unit_by_id(id).position=={"x":x,"y":7} and hud._unit_by_id(id).resources.mp==mp-1,"position and authoritative MP retain normal commit")
		carried+=140
		check(absf(float(hud.walk_distance_offsets[id])-carried)<.02,"cumulative stride phase persists across separate orders")
	var generation: int=hud.visual_generation
	hud._reset_debug_encounter()
	var location: Vector2=hud.unit_layer.get_node(id).position
	hud._sample_painted_walk(.5,id,Vector2.ZERO,Vector2(100,100),400,generation)
	check(hud.walk_distance_offsets.is_empty() and hud.unit_layer.get_node(id).position==location,"reset clears phase and stale tween samples cannot move actors")
	hud.queue_free();await process_frame
	ProjectSettings.set_setting("debug/qa/combat_scenario",previous)
	for failure in failures: push_error(failure)
	print("tactical_locomotion_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
