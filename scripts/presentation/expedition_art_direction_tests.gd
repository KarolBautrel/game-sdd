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
		root.get_node("CampaignSession").load_profile("",true)
		root.get_node("DungeonRunSession").clear()
		var viewport := SubViewport.new()
		viewport.size=dimensions
		root.add_child(viewport)
		var hud: Control=load("res://scenes/dungeon/DungeonDebug.tscn").instantiate()
		viewport.add_child(hud)
		await frames()
		var bounds:=Rect2(Vector2.ZERO,Vector2(dimensions)).grow(1)
		for panel: Control in [hud.map_frame_panel,hud.resource_tray_panel,hud.party_panel,hud.detail_panel,hud.world_button]:
			check(bounds.encloses(panel.get_global_rect()),"expedition panel stays inside "+str(dimensions)+" "+panel.name+str(panel.get_global_rect()))
		check(not hud.resource_tray_panel.get_global_rect().intersects(hud.map_frame_panel.get_global_rect()),"supplies never cover map title or rooms")
		check(not hud.party_panel.get_global_rect().intersects(hud.map_frame_panel.get_global_rect()),"company never covers map")
		check(hud.detail_panel.get_theme_stylebox("panel") is StyleBoxTexture,"native paper inspector")
		for panel: PanelContainer in hud.room_nodes.values():
			var name: Label=panel.get_node("RoomBody").get_child(1)
			check(not name.text.is_empty() and name.get_theme_font_size("font_size")>=24,"room has readable native name")
			check(name.size.y>=name.get_theme_font("font").get_height(24),"room name has real line height")
		for row: Dictionary in hud.loadout_rows.values():
			for button: Button in [row.minus_button,row.plus_button]:
				check(button.size.x>=60 and button.focus_mode==Control.FOCUS_ALL,"packing input readable and keyboard focusable")
		var snapshot: Dictionary=hud.run_state.duplicate(true)
		hud.expedition_chrome.layout(hud)
		check(hud.run_state==snapshot,"layout never mutates expedition state")
		hud._start_expedition_with_loadout()
		hud._try_enter_room("not_a_room")
		await frames()
		hud.queue_free()
		viewport.queue_free()
		await frames()
	for failure in failures: push_error(failure)
	print("expedition_art_direction_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
