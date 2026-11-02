extends SceneTree
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
const Party := preload("res://scripts/domain/party_roster.gd")
var failures: Array[String] = []
var checks := 0
var human_only := false


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)


func _run() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/presentation/original_roster.json"))
	var art:=Art.new()
	human_only=OS.get_cmdline_user_args().has("--human-only")
	check(data.characters.size()==27,"entire configured roster")
	for profile: Dictionary in data.characters:
		if human_only and profile.kind!="human":continue
		var id:=str(profile.id)
		var unit: Dictionary={"id":"fixture_"+id,"team":"enemy","visual":{"faction":"legacy","character":id}}
		var size:=art.sprite_size(unit,Vector2i(384,240))
		var pivot: Vector2i=Art.PROCESSED_SHEET_VISUALS[id].pivot
		check(art.sprite_offset(unit,Vector2i(384,240))+Vector2(pivot)==Vector2(192,240),id+" board ground anchor")
		check(art.processed_sheet_corpse_visual_action(id)=="death:7",id+" terminal corpse")
		var views: Dictionary={}
		for direction: String in data.camera.yaw:
			for action: String in data.frame_counts:
				var count:=int(data.frame_counts[action])
				check(art.processed_sheet_frame_count(id,action)==count,id+action+" authored count")
				for frame in range(count):
					var path:=art.texture_path(unit,direction,"%s:%s" % [action,frame])
					check(path=="res://assets/combat/characters/original/%s/%s/%s_%s_%s_%03d.png" % [id,action,id,direction,action,frame] and FileAccess.file_exists(path),"original frame without legacy fallback: "+path)
				if action=="pose" or direction=="east":
					var path:=art.texture_path(unit,direction,"%s:%s" % [action,count-1])
					var image:=Assets.image_copy(path)
					check(image!=null,id+" imported texture")
					if image!=null:
						var used:=image.get_used_rect()
						check(image.get_size()==size and used.has_area() and used.position.x>0 and used.position.y>0 and used.end.x<size.x and used.end.y<size.y,id+" visible unclipped native canvas")
						if action=="pose":views[image.get_data().hex_encode().sha256_text()]=true
		check(views.size()==8,id+" eight rendered asymmetric directions")
		Assets.clear_texture_cache()
	for alias: String in data.aliases:
		check(art.processed_sheet_texture_path(alias,"west","combat:3")==art.processed_sheet_texture_path(data.aliases[alias],"west","combat:3"),"saved legacy alias "+alias)
	for hero: Dictionary in Party.default_party():
		check(str(hero.portrait_path).begins_with("res://assets/ui/portraits/") and Assets.texture(hero.portrait_path)!=null,"independent illustrated hero portrait "+str(hero.id))
	await _gallery_fixture()
	for message in failures:push_error(message)
	print("Original roster: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)


func _gallery_fixture() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(2560,1440)
	root.add_child(viewport)
	var hud: Control=load("res://scenes/combat/CombatDebug.tscn").instantiate()
	viewport.add_child(hud)
	for index in range(5):await process_frame
	var before: Dictionary=hud.state.duplicate(true)
	var gallery: Control=load("res://scripts/presentation/combat/roster_gallery.gd").new()
	hud.add_child(gallery)
	for index in range(3):await process_frame
	if human_only:
		gallery.profiles=gallery.profiles.filter(func(profile: Dictionary) -> bool:return profile.kind=="human")
		gallery._build_page()
	gallery.playing=false
	check(not hud.is_processing_input(),"gallery suppresses battle shortcuts")
	check(gallery.z_index>hud.FLOATING_TEXT_LAYER_Z_INDEX,"gallery covers board overlays")
	check(gallery.scroll.size.y>600,"gallery reserves visible actor area")
	check(gallery.grid.size.y<=gallery.scroll.size.y,"wide gallery fits both actor rows")
	var seen: Dictionary={}
	for page in range(ceili(gallery.profiles.size()/6.0)):
		check(gallery.page==page,"gallery navigation")
		for card: Dictionary in gallery.cards:
			seen[card.id]=true
			check(card.sprite.texture!=null,"gallery renders "+str(card.id))
		for action in gallery.ACTIONS:
			gallery.action=action
			for facing in gallery.DIRECTIONS:
				gallery.direction=facing;gallery.frame=0;gallery._refresh()
		gallery._command("Next")
	check(seen.size()==gallery.profiles.size() and gallery.page==0,"all selected families reachable with page wrap")
	gallery._command("Pause")
	gallery._tick()
	check(gallery.frame>0 or gallery.action=="death","gallery animates")
	gallery._command("Close")
	await process_frame
	check(hud.get_node_or_null("OriginalRosterGallery")==null and hud.is_processing_input(),"close restores battle controls")
	check(hud.state==before,"gallery never changes simulation")
	hud.queue_free();viewport.queue_free()
	await process_frame
