extends SceneTree
var checks := 0
var failures: Array[String]=[]

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)

func frames() -> void:
	for frame in range(4): await process_frame

func _run() -> void:
	var session=root.get_node("DungeonRunSession")
	session.clear()
	var hud=load("res://scenes/dungeon/DungeonDebug.tscn").instantiate()
	root.add_child(hud)
	await frames()
	hud._set_dungeon_source(hud.DUNGEON_SOURCE_AUTHORED)
	hud._start_expedition_with_loadout()
	await frames()
	var chrome=hud.expedition_chrome
	check(not chrome.use_mine_chart(hud),"Authored graph uses independent production vignettes")
	check(hud.graph_layer.get_node_or_null("IllustratedMineChart")==null and hud.room_nodes.entrance.has_node("RoomBody/Art"),"No fixed painted graph is baked into the chart")
	var authored: Dictionary=hud.dungeon
	hud.dungeon=authored.duplicate(true)
	hud.dungeon.corridors.pop_back()
	check(not chrome.use_mine_chart(hud),"Modified graph cannot inherit false painted connections")
	hud.dungeon=authored
	var before: Dictionary=hud.run_state.duplicate(true)
	var room_hit: Button=hud.room_nodes.dusty_crossing.get_node("RoomHit")
	room_hit.pressed.emit()
	await frames()
	check(hud.run_state==before,"Map preview must not mutate or spend expedition state")
	check(chrome.preview_room_id=="dusty_crossing","Map button previews the chosen room")
	check(hud.selected_room_id=="entrance","Preview must not change current-room ownership")
	check(chrome.travel_button.visible and not chrome.travel_button.disabled,"Adjacent passage has one legal travel action")
	check(chrome.preview_label.text.contains("4 -> 3"),"Preview displays actual authored light cost")
	check(not hud.action_row.visible and not hud.exit_row.visible,"Preview exposes destination action instead of current-room actions")
	check(chrome.passages.routes.size()==hud.dungeon.corridors.size() and chrome.passages.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Passive chart ink represents actual corridors")
	chrome.preview_room(hud,"sealed_armory")
	check(chrome.travel_button.disabled,"Locked non-adjacent destination cannot travel")
	check(chrome.preview_label.text.contains("No direct passage") and chrome.preview_label.text.contains("matching key"),"Preview explains both adjacency and lock")
	chrome.travel_preview(hud)
	check(hud.run_state==before,"Disabled travel preserves state")
	chrome.preview_room(hud,"entrance")
	check(chrome.preview_room_id.is_empty() and hud.detail_label.visible,"Return to current detail is free")
	check(not hud.detail_label.text.contains("Position:") and not hud.detail_label.text.contains("Camping Kit:"),"Native inspector omits raw coordinates and duplicate supply inventory")
	check(hud.exit_row.get_child_count()>0,"Passages remain discoverable without map pipes")
	var first: Button=hud.exit_row.get_children().filter(func(b):return not b.is_queued_for_deletion())[0]
	first.pressed.emit()
	check(chrome.preview_room_id=="dusty_crossing","Passage list also previews before spending")
	chrome.travel_button.pressed.emit()
	await frames()
	check(hud.run_state.current_room_id=="dusty_crossing","Confirm travel reaches authored adjacent room")
	check(hud.run_state.light_level==3,"Travel cost is spent once")
	check(not hud.run_state.pending_room_event.is_empty(),"Real authored room choice is pending")
	check(chrome.preview_room_id.is_empty(),"Actual travel clears preview")
	check(hud.world_button.disabled,"Pending choice disables background world action")
	check(hud.world_button.focus_mode==Control.FOCUS_NONE,"Pending choice removes background Tab target")
	var focus: Control=hud.get_viewport().gui_get_focus_owner()
	check(focus!=null and hud.corridor_event_panel.is_ancestor_of(focus),"Pending choice receives native focus")
	var choices: Array[Button]=hud.corridor_hazard_choice_buttons
	check(choices.size()==2,"Actual shrine event exposes its two choices")
	check(choices[0].focus_previous==choices[1].get_path() and choices[1].focus_next==choices[0].get_path(),"Modal focus wraps through its choices")
	var pending: Dictionary=hud.run_state.duplicate(true)
	chrome.preview_room(hud,"guarded_cache")
	check(hud.run_state==pending and chrome.preview_room_id.is_empty(),"Event cannot be bypassed by preview/travel")
	hud._open_world()
	check(is_instance_valid(hud) and hud.is_inside_tree() and hud.run_state==pending,"F7/world handler cannot bypass event")
	choices[1].pressed.emit()
	await frames()
	check(hud.run_state.pending_room_event.is_empty(),"Normal choice resolves room event")
	check(not hud.world_button.disabled and hud.world_button.focus_mode==Control.FOCUS_ALL,"Resolution restores background control focus")
	check(hud.exit_row.visible,"Resolution restores normal passage navigation")
	hud.queue_free()
	await frames()
	session.clear()
	print("DUNGEON_ROUTE_PREVIEW: %s checks, %s failures" % [checks,failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
