extends SceneTree
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Presentation := preload("res://scripts/presentation/world/item_presentation.gd")
var errors: Array[String] = []
var checks := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: errors.append(message)
func _run() -> void:
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/items/catalogue.json"))
	var unique: Dictionary={}
	for item: Dictionary in catalogue.items:
		var icon := Presentation.icon_for(item)
		check(icon!=null,"runtime icon exists: "+item.id)
		if icon==null: continue
		check(icon.resource_path.ends_with("/"+str(item.id)+".png"),"authored mapping, not category placeholder: "+item.id)
		check(not unique.has(icon.resource_path),"distinct item art: "+item.id)
		unique[icon.resource_path]=true
		var image:=icon.get_image()
		check(image!=null and image.get_width()==96 and image.get_height()==96,"bounded normalized item asset: "+item.id)
		if image!=null: check(image.get_pixel(0,0).a<0.1,"true alpha, no background square: "+item.id)
	check(Presentation.icon_for({"id":"legacy_custom_17"}).resource_path.ends_with("/legacy_unknown.png"),"unknown legacy fallback")
	for font: Font in [UI.body_font(),UI.heading_font()]:
		var letters:="ĄĆĘŁŃÓŚŹŻąćęłńóśźż"
		for index in letters.length(): check(font.has_char(letters.unicode_at(index)),"packaged font covers Polish glyph")
	var theme:=UI.theme()
	check(theme.default_font==UI.body_font(),"packaged font used in runtime theme")
	check(theme.get_stylebox("normal","Button") is StyleBoxTexture,"runtime uses imported art family")
	check(theme.get_stylebox("focus","Button") is StyleBoxFlat,"explicit native focus outline")
	for file in ["frame_dark","frame_paper","button","leather","marches_map","divider","slot"]:
		check(UI.Assets.texture(UI.ART+file+".png")!=null,"exported texture: "+file)
	var map: Control = preload("res://scripts/presentation/world/region_map.gd").new()
	root.add_child(map)
	var region: Dictionary = preload("res://scripts/systems/data_catalog.gd").load_vertical_slice().world_region
	map.configure(region,"town_ravenford",{})
	for dimensions in [Vector2(400,360),Vector2(1100,620),Vector2(1800,1020)]:
		map.size = dimensions
		map._layout()
		var paper: Rect2 = map.paper_rect()
		check(is_equal_approx(paper.size.x/paper.size.y,1280.0/720.0),"parchment preserves illustration aspect ratio")
		check(Rect2(Vector2.ZERO,map.size).grow(1).encloses(paper),"parchment stays inside map control")
		var rects: Array[Rect2] = []
		for id: String in map.marker_buttons:
			var point: Vector2 = map._point(id)
			check(paper.has_point(point),"landmark anchored inside illustration: "+id)
			var button: Button = map.marker_buttons[id]
			var bounds := Rect2(button.position,button.size)
			check(Rect2(Vector2.ZERO,map.size).grow(1).encloses(bounds),"native marker hit rectangle remains in map")
			for previous in rects: check(not bounds.intersects(previous),"landmark hit targets never overlap")
			rects.append(bounds)
	map.queue_free()
	await process_frame
	for message in errors: push_error(message)
	print("dark_fantasy_ui_tests: ",checks," checks, ",errors.size()," failures")
	quit(0 if errors.is_empty() else 1)
