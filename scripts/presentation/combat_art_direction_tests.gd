extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frames() -> void:
	for i in range(12): await process_frame
func _run() -> void:
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		root.get_node("DungeonRunSession").clear()
		var viewport := SubViewport.new()
		viewport.size=dimensions
		root.add_child(viewport)
		var hud: Control=load("res://scenes/combat/CombatDebug.tscn").instantiate()
		viewport.add_child(hud)
		await frames()
		hud._reset_debug_encounter()
		await frames()
		for unit: Dictionary in hud.state.units:
			check(hud.unit_layer.get_node_or_null(NodePath(unit.id))!=null,"reload retains every unit visual after deferred frees")
		var bounds:=Rect2(Vector2.ZERO,Vector2(dimensions)).grow(1)
		for panel: Control in [hud.encounter_panel,hud.turn_order_panel,hud.bottom_hud,hud.board_viewport,hud.battle_chrome.side_scroll]:
			check(bounds.encloses(panel.get_global_rect()),"combat panel in viewport "+str(dimensions)+panel.name+str(panel.get_global_rect()))
		check(not hud.board_root.is_ancestor_of(hud.overlay_resource_panel),"resources outside tile hit space")
		check(not hud.board_root.is_ancestor_of(hud.overlay_log_panel),"chronicle outside tile hit space")
		check(hud.board_viewport.clip_contents and hud.board_root.position.y>=100*hud.board_root.scale.y,"actor headroom and clipping protect header")
		check(not hud.battle_chrome.side_scroll.get_global_rect().intersects(hud.board_viewport.get_global_rect()),"inspector never covers playable board")
		check(hud.action_panel.get_theme_stylebox("panel") is StyleBoxTexture,"shared paper action inspector")
		for button: Button in hud.command_buttons.get_children():
			if button.is_queued_for_deletion() or not button.has_meta("action_id"): continue
			var labels:=button.find_children("*","Label",true,false)
			check(labels.size()==2,"native action name and cost")
			for label: Label in labels:
				var minimum:=18 if dimensions.x<1500 or dimensions.y<900 else 24
				check(label.get_theme_font_size("font_size")>=minimum and label.size.y>=label.get_theme_font("font").get_height(minimum)-1,"action has legible responsive line height")
			check(button.focus_mode==Control.FOCUS_ALL,"actions support keyboard focus")
		var snapshot: Dictionary=hud.state.duplicate(true)
		hud.battle_chrome.style_hud(hud)
		hud.battle_chrome.refresh(hud)
		check(snapshot==hud.state,"battle chrome never changes simulation state")
		hud.queue_free()
		viewport.queue_free()
		await frames()
	for failure in failures: push_error(failure)
	print("combat_art_direction_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
