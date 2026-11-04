extends SceneTree
const Art := preload("res://scripts/presentation/dungeon/ashen_skin.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: _run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)
func frames() -> void:
	for frame in range(12): await process_frame

func _run() -> void:
	for theme in ["mine","dungeon","castle","forest"]:
		for role in ["entrance","crossing","treasure","spider","guarded_treasure","exit","locked"]:
			var texture := Art.texture(theme+"/"+role)
			var image := texture.get_image()
			if image.is_compressed(): image.decompress()
			var clear := 0
			var solid := 0
			for y in range(0,image.get_height(),3):
				for x in range(0,image.get_width(),3):
					if image.get_pixel(x,y).a<.05: clear+=1
					if image.get_pixel(x,y).a>.95: solid+=1
			check(clear>20 and solid>20,"Real alpha silhouette: "+theme+"/"+role)
	for id in ["selection","portrait-ring"]:
		var image := Art.texture(id).get_image()
		if image.is_compressed(): image.decompress()
		check(image.get_pixel(image.get_width()/2,image.get_height()/2).a<.01,"Transparent ring interior: "+id)
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]:
		root.get_node("CampaignSession").load_profile("",true)
		root.get_node("DungeonRunSession").clear()
		var viewport := SubViewport.new()
		viewport.size = dimensions
		root.add_child(viewport)
		var hud = load("res://scenes/dungeon/DungeonDebug.tscn").instantiate()
		viewport.add_child(hud)
		await frames()
		hud._set_dungeon_source(hud.DUNGEON_SOURCE_AUTHORED)
		await frames()
		var screen := Rect2(Vector2.ZERO,Vector2(dimensions))
		for control: Control in [hud.detail_panel,hud.map_frame_panel,hud.party_panel,hud.world_button,hud.resource_tray_panel]:
			check(screen.grow(1).encloses(control.get_global_rect()),"Chrome fits viewport: "+str(dimensions)+" "+str(control.name))
		check(hud.detail_box.size.x<=hud.detail_panel.size.x,"Packing cannot force inspector outside screen")
		var frame: StyleBoxTexture = hud.detail_panel.get_theme_stylebox("panel")
		check(frame.get_content_margin(SIDE_LEFT)>=frame.get_texture_margin(SIDE_LEFT)+3,"Inspector copy clears the visible iron rail")
		check(hud.corridor_event_panel.get_index()>hud.expedition_chrome.inspector_seal.get_index() and hud.expedition_chrome.shade.get_index()>hud.expedition_chrome.pinned_start.get_index(),"Modal layers cover all new root decorations")
		check(hud.corridor_event_panel.get_child(1).offset_top>=56,"Modal title clears the source frame cap")
		check(hud.expedition_chrome.pinned_start.visible and hud.detail_panel.get_global_rect().encloses(hud.expedition_chrome.pinned_start.get_global_rect()),"Start remains visible inside packing inspector")
		check(hud.theme.default_font.resource_path.ends_with("EBGaramond.ttf"),"Native reference-family serif")
		hud._start_expedition_with_loadout()
		await frames()
		var state: Dictionary = hud.run_state.duplicate(true)
		for theme in ["mine","dungeon","castle","forest"]:
			hud.expedition_chrome.apply_archetype(hud,theme)
			await frames()
			check(state==hud.run_state,"Theme changes do not mutate the run")
			check(not hud.reset_button.visible,"Debug reset is absent from normal chrome")
			check(not hud.expedition_chrome.use_mine_chart(hud),"No baked fixed graph")
			for room: Dictionary in hud.dungeon.rooms:
				var panel: Control = hud.room_nodes[str(room.id)]
				var art: TextureRect = panel.get_node("RoomBody/Art")
				var label: Label = panel.get_node("RoomBody/RoomName")
				check(art.texture.resource_path.contains("/"+theme+"/"),"Actual theme vignette: "+str(room.id))
				check(label.get_theme_font_size("font_size")>=18 and label.size.y>=label.get_line_height(),"Readable room text")
			check(hud.expedition_chrome.passages.routes.size()==hud.dungeon.corridors.size(),"Truthful native route count")
			hud.expedition_chrome.preview_room(hud,"dusty_crossing")
			check(state==hud.run_state and hud.expedition_chrome.preview_label.text.contains("4 -> 3"),"Theme preview preserves real cost")
			hud.expedition_chrome.preview_room(hud,"entrance")
		hud.queue_free()
		viewport.queue_free()
		await frames()
	root.get_node("DungeonRunSession").clear()
	for failure in failures: push_error(failure)
	print("ASHEN_EXPLORATION: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
