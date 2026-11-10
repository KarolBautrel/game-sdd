extends SceneTree
const Art := preload("res://scripts/presentation/combat/environment_art.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:failures.append(label)
func _initialize() -> void:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets_src/tactical_environment/2026-11-05/manifest.json"))
	check(manifest.assets.size()==16,"cohesive16prop family")
	for row: Dictionary in manifest.assets:
		var record: Dictionary=Art.prop(row.path)
		check(record.path==row.path and record.size==row.size and record.pivot==row.pivot,"current semantic alias "+row.id)
		var texture: Texture2D=load(row.path)
		var image: Image=texture.get_image()
		check(image.get_size()==Vector2i(row.size[0],row.size[1]),"declared canvas "+row.id)
		check(image.detect_alpha()!=Image.ALPHA_NONE,"real alpha "+row.id)
		var transparent_border:=true
		for x in image.get_width():
			if image.get_pixel(x,0).a>0.001 or image.get_pixel(x,image.get_height()-1).a>0.001:transparent_border=false
		for y in image.get_height():
			if image.get_pixel(0,y).a>0.001 or image.get_pixel(image.get_width()-1,y).a>0.001:transparent_border=false
		check(transparent_border,"unclipped padded silhouette "+row.id)
		check(FileAccess.get_sha256(row.path)==row.sha256,"export provenance "+row.id)
		check(FileAccess.get_sha256("res://"+row.retained_original)==row.retained_original_sha256,"original unchanged "+row.id)
		check(float(row.pivot[0])>0 and float(row.pivot[1])<image.get_height(),"ground anchor "+row.id)
	check(Art.terrain_explanation("cover_low").contains("-20") and Art.terrain_explanation("cover_low").contains("1 MP"),"cover024 semantics")
	check(Art.terrain_explanation("highground").contains("+10") and Art.terrain_explanation("highground").contains("+1") and Art.terrain_explanation("highground").contains("2 MP"),"height024 semantics")
	check(Art.terrain_explanation("blocked").contains("Impassable") and Art.terrain_explanation("blocked").contains("Blocks ranged line of sight"),"blocked follows grid022 LOS")
	var scene: Control=load("res://scenes/combat/CombatDebug.tscn").instantiate()
	root.add_child.call_deferred(scene)
	await process_frame;await process_frame
	# The terrain assertions require the showcase, independent of QA launch settings.
	scene.selected_scenario_id = "full_combat_showcase"
	scene._load_selected_scenario()
	await process_frame
	for kind: String in ["floor","blocked","cover_low","highground"]:
		var found:=false
		for tile: Dictionary in scene.state.grid.tiles:
			if tile.type==kind:
				found=true
				var tooltip: String=scene._tile_tooltip({"x":tile.x,"y":tile.y})
				check(not tooltip.contains("999") and tooltip.contains("MP") if kind!="blocked" else tooltip.contains("Impassable"),"real HUD tooltip "+kind)
				break
		check(found,"representative terrain "+kind)
	scene.queue_free();await process_frame
	for label: String in failures:push_error(label)
	print("Tactical environment: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
