extends SceneTree
const View := preload("res://scenes/world/StrategistWorld.tscn")
const P := preload("res://scripts/domain/strategist_protocol.gd")
const M := preload("res://scripts/domain/strategist_campaign.gd")
const Feedback := preload("res://scripts/presentation/world/strategist_feedback.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func _initialize() -> void: run.call_deferred()
func frames() -> void:
	for i in range(4): await process_frame
func run() -> void:
	feedback_projection()
	var owner := root.get_node("StrategicSession")
	for pixels: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		check(owner.open_model_seed(2087,"marches",true),"explicit native model campaign")
		var viewport := SubViewport.new();viewport.size=pixels;root.add_child(viewport)
		var view := View.instantiate();view.qa_memory=true;var routes: Array=[]
		view.scene_requested.connect(func(path): routes.append(path));viewport.add_child(view);await frames()
		check(owner.session.state.version==4 and owner.world_return_scene()=="res://scenes/world/StrategistWorld.tscn","v4 owner and return route")
		check(view.model_input!=null and owner.session.state.strategist.mode=="classic","new optional campaign defaults classic")
		view.tabs.current_tab=1;await frames()
		check(view.model_input.get_item_text(1).contains("offline"),"truthful offline label")
		view.set_speed(4);view.model_input.select(1);view.model_input.item_selected.emit(1);await frames()
		check(view.speed==0 and owner.session.state.strategist.mode=="recorded" and owner.session.state.strategist.generation==1,"mode control pauses and commits generation")
		check(view.model_status.text.contains("No live model") and view.model_status.text.contains("Next review"),"authored provenance and next boundary visible")
		check(view.model_notice.is_visible_in_tree() and view.map.size.x>=450 and view.map.size.y>=300,"passive result strip preserves a usable map")
		check(owner.order("advance",{"ticks":192}) and owner.order("advance",{"ticks":72}),"actual world reaches first request")
		var tick: int=owner.session.state.strategy_world.core.tick
		view._process(.01);await frames()
		check(owner.session.state.strategy_world.core.tick==tick and owner.session.state.strategist.budget.calls==1,"paused asynchronous fixture pump spends no strategic time")
		if owner.session.state.strategist.pending.is_empty():
			check(false,"a real model request must remain queued");view.queue_free();viewport.queue_free();await frames();continue
		check(owner.session.state.strategist.pending.values()[0].status=="replied","native pump queues valid protocol reply")
		check(view.model_status.text.contains("Next result due: "+view.clock(288)),"pending display uses actual reply deadline instead of a later faction review")
		check(owner.order("advance",{"ticks":24}),"normal fixed boundary advance")
		view._refresh();await frames()
		check(view.model_status.text.contains("Plans accepted: 1") and owner.session.state.strategist.totals.accepted==1,"actual accepted decision status")
		view.tabs.current_tab=0;await frames()
		check(view.model_notice.is_visible_in_tree() and view.model_notice.text.contains("0 applied, 1 blocked") and view.model_notice.text.contains("resources"),"real first accepted plan exposes its blocked action on the map")
		check(not view.model_status.text.contains("reserve_deficit") and not view.factions.text.contains("claim"),"no private plan or reason-text leak")
		for control: Control in [view.model_input,view.model_status,view.faction_input,view.model_notice]:
			check(control.get_global_rect().position.x>=0 and control.get_global_rect().end.x<=pixels.x+1,"model controls stay on screen")
		view.tabs.current_tab=2;await frames();view.set_speed(4)
		check(view.speed==0 and view.buttons.speed4.disabled,"jobs retain clock isolation")
		check(view.model_notice.is_visible_in_tree(),"result remains visible on Jobs")
		var before: Dictionary=owner.session.state.duplicate(true);view.map.camera_action("overview");view.map.camera_action("company")
		check(P.encoded(before)==P.encoded(owner.session.state),"camera never changes model/company facts")
		view.queue_free();await frames();view=View.instantiate();view.qa_memory=true
		view.scene_requested.connect(func(path): routes.append(path));viewport.add_child(view);await frames()
		check(view.model_notice.text.contains("0 applied, 1 blocked") and owner.session.state.strategy_world.core.tick==288,"reopening displays retained result immediately without waiting again")
		view._open_seed();check(routes.back()=="res://scenes/world/StrategistWorld.tscn" and owner.session.state.version==4,"seed/resume stays in optional format")
		view.queue_free();viewport.queue_free();await frames()
	owner.deactivate()
	for failure: String in failures: push_error(failure)
	print("strategist_interface_tests: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func feedback_projection() -> void:
	var cp: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/strategist_campaigns/reference_2087.json"))
	var pending := Feedback.project(cp)
	check(pending.due==288 and pending.due_label=="Next result due","saved pending deadline is the next result")
	var result := M.replay(cp,[M.command(cp,"advance",{"ticks":24})])
	var before := P.encoded(result.state);var info := Feedback.project(result.state)
	check(result.ok and info.plans==1 and info.applied==0 and info.blocked==1,"actual authority distinguishes plan acceptance from failed operation")
	check(info.last_tick==288 and info.last.contains("Cinder Compact") and info.why.contains("resources"),"diagnosis names public faction/time and readable constraint")
	check(P.encoded(result.state)==before,"feedback projection is read-only")
	var missing := cp.duplicate(true);missing.request_seq-=1;missing.request_receipts.pop_back()
	missing.strategist.pending.cinder_compact.status="sent";missing.strategist.pending.cinder_compact.reply={}
	var fallback := M.apply(missing,M.command(missing,"advance",{"ticks":24}))
	var fallback_info := Feedback.project(fallback.state)
	check(fallback.ok and fallback_info.last.contains("classic policy") and fallback_info.fallback_reason.contains("No reply"),"actual missing reply preserves a readable fallback reason")
	result.state.strategist.journal[0].reply.public_summary="SECRET_PRIVATE_MODEL_TEXT"
	info=Feedback.project(result.state)
	check(not P.encoded(info).contains("SECRET_PRIVATE_MODEL_TEXT") and not P.encoded(info).contains("protect_route") and not P.encoded(info).contains("mobilization_unfunded"),"raw response/private intent/internal code never becomes player feedback")
