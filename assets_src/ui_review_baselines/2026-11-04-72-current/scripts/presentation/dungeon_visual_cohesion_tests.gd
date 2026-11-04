extends SceneTree
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func frames() -> void:
	for frame in range(12): await process_frame

func _run() -> void:
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
		hud._start_expedition_with_loadout()
		await frames()
		var hide: TextureRect = hud.get_node("CampaignHide")
		check(hide.texture.get_width()>256 and hide.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_COVERED and hide.texture_repeat==CanvasItem.TEXTURE_REPEAT_DISABLED,"Single source-resolution hide at "+str(dimensions))
		for panel: Control in [hud.detail_panel,hud.map_frame_panel,hud.party_panel]:
			var style: StyleBoxTexture = panel.get_theme_stylebox("panel")
			check(style.axis_stretch_horizontal==StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH and style.axis_stretch_vertical==StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH,"No repeating panel centers")
		var fill_color := Color.TRANSPARENT
		for card: PanelContainer in hud.party_cards.values():
			var portrait: TextureRect = card.find_child("Portrait",true,false)
			check(portrait.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"Whole portrait is aspect fitted")
			for control: Control in [portrait,card.hp_label,card.hp_bar]:
				check(card.get_global_rect().grow(.1).encloses(control.get_global_rect()) and hud.party_panel.get_global_rect().encloses(control.get_global_rect()),"Portrait and health fit footer at "+str(dimensions))
			var hp: Label = card.hp_label
			check(hp.size.x>=hp.get_theme_font("font").get_string_size(hp.text,HORIZONTAL_ALIGNMENT_LEFT,-1,hp.get_theme_font_size("font_size")).x,"Full current/max health fits without ellipsis")
			var color: Color = card.hp_bar.get_theme_stylebox("fill").bg_color
			check(color==Color("a43f32") and (fill_color==Color.TRANSPARENT or color==fill_color),"All health fills are the same red")
			fill_color = color
		check(hud.party_panel.get_global_rect().encloses(hud.party_log_label.get_global_rect()),"Feedback fits beside party")
		check(hud.party_log_label.size.y>=hud.party_log_label.get_line_height()*2,"Feedback reserves two real lines")
		_check_routes(hud)
		hud.expedition_chrome.preview_room(hud,"dusty_crossing")
		check(hud.expedition_chrome.passages.routes.filter(func(route):return hud.expedition_chrome.passages.route_selected(route)).size()==1,"Only actual selected adjacent passage is highlighted")
		hud.expedition_chrome.preview_room(hud,"sealed_armory")
		check(hud.expedition_chrome.passages.routes.filter(func(route):return hud.expedition_chrome.passages.route_selected(route)).is_empty(),"Nonadjacent selection invents no connection")
		hud._set_dungeon_source(hud.DUNGEON_SOURCE_GENERATED)
		for difficulty in [1,2,3]:
			hud._set_generated_difficulty(difficulty)
			await frames()
			_check_routes(hud)
		var snapshot: Dictionary = hud.run_state.duplicate(true)
		hud.expedition_chrome.layout(hud)
		check(snapshot==hud.run_state,"Layout is presentation only")
		hud.queue_free()
		viewport.queue_free()
		await frames()
	root.get_node("DungeonRunSession").clear()
	for failure in failures: push_error(failure)
	print("DUNGEON_VISUAL_COHESION: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _check_routes(hud) -> void:
	var layer: Control = hud.expedition_chrome.passages
	check(layer.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Passages cannot swallow room input")
	check(layer.routes.size()==hud.dungeon.corridors.size(),"One route for every actual corridor")
	for route: Dictionary in layer.routes:
		var points: PackedVector2Array = route.points
		check(points.size()>=2,"Corridor has drawable route: "+str(route.from)+" / "+str(route.to))
		for id: String in hud.room_nodes:
			if id in [route.from,route.to]: continue
			var rect := Rect2(hud.room_nodes[id].position,hud.room_node_size).grow(4)
			var clear := true
			for index in range(1,points.size()):
				var a := points[index-1]
				var b := points[index]
				if rect.has_point(a) or rect.has_point(b): clear=false
				for edge: PackedVector2Array in [PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y)]),PackedVector2Array([Vector2(rect.end.x,rect.position.y),rect.end]),PackedVector2Array([rect.end,Vector2(rect.position.x,rect.end.y)]),PackedVector2Array([Vector2(rect.position.x,rect.end.y),rect.position])]:
					if Geometry2D.segment_intersects_segment(a,b,edge[0],edge[1])!=null: clear=false
			check(clear,"Route avoids unrelated plate "+id)
