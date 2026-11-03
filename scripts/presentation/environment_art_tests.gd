extends SceneTree
const Art := preload("res://scripts/presentation/combat/environment_art.gd")
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void:_run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func _run() -> void:
	var data:=Art.data()
	check(data.assets.size()==28 and data.floors.size()==4,"complete nature/dungeon original family")
	for id: String in data.assets:
		var row: Dictionary=data.assets[id];var image:=Assets.image_copy(row.path)
		check(image!=null and image.get_size()==Vector2i(row.size[0],row.size[1]),"imported original prop "+id)
		if image!=null:
			var rect:=image.get_used_rect()
			check(rect.has_area() and rect.size.x<512 and rect.size.y<512,"nonempty unclipped transparent prop "+id)
	for path: String in data.legacy_routes:check(not Art.prop(path).is_empty(),"retained authoring route "+path)
	for path: String in data.floors.values():
		var image:=Assets.image_copy(path)
		check(image!=null and image.get_size()==Vector2i(512,512),"painted floor size")
		if image!=null:
			for i in range(512):check(image.get_pixel(0,i)==image.get_pixel(511,i) and image.get_pixel(i,0)==image.get_pixel(i,511),"matched floor edges "+path+str(i))
	var viewport:=SubViewport.new();viewport.size=Vector2i(2560,1440);root.add_child(viewport)
	var app: Control=load("res://scenes/combat/CombatDebug.tscn").instantiate();viewport.add_child(app)
	for scenario: String in ["terrain_grass_showcase","terrain_dungeon_showcase"]:
		app.selected_scenario_id=scenario;app._load_selected_scenario()
		for i in range(6):await process_frame
		var before: Dictionary=app.state.duplicate(true)
		check(app._board_terrain_texture()!=null,"new board floor "+scenario)
		for tile: Dictionary in app.state.grid.tiles:
			var path: String=app._tile_decoration_path(tile)
			if not path.is_empty():check(not Art.prop(path).is_empty() and Art.texture(path)!=null,"authored decoration remapped "+path)
			if tile.type=="highground":
				var node: Button=app.grid_container.get_child(int(tile.y)*int(app.state.grid.width)+int(tile.x))
				check(node.get_node_or_null("RaisedTerrainArt")!=null and node.get_node_or_null("HighgroundLabel")==null,"painted ledge replaces debug plate")
		check(app.state==before,"art does not mutate authored grid/placement/domain")
	app.queue_free();viewport.queue_free();await process_frame
	for failure in failures:push_error(failure)
	print("Environment art: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
