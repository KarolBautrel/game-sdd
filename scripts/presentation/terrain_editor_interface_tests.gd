extends SceneTree
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
const Editor:=preload("res://scripts/presentation/world/terrain_editor.gd")
const World:=preload("res://scripts/domain/living_world.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frames() -> void:
	for frame in range(6): await process_frame
func _run() -> void:
	var campaign: Node=root.get_node("CampaignSession")
	campaign.load_profile("",true);campaign.enable_living_world()
	var campaign_before: Dictionary=campaign.state.duplicate(true)
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		var viewport:=SubViewport.new();viewport.size=dimensions;root.add_child(viewport)
		var editor:=Editor.new();editor.qa_memory=true
		editor.file_path="user://qa_terrain_interface_%s.json" % dimensions.x
		var routes: Array[String]=[]
		editor.scene_requested.connect(func(path: String) -> void: routes.append(path))
		viewport.add_child(editor);editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await frames()
		check(editor.size==Vector2(dimensions),"editor fills viewport "+str(dimensions))
		check(editor.canvas.size.x>dimensions.x*.65 and editor.canvas.size.y>dimensions.y*.6,"large independent map viewport")
		for button: Button in editor.buttons.values():
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(button.get_global_rect()),"control fits: "+button.text)
		var before: Array=editor.data.rows.duplicate()
		editor.select("W");editor.radius=0;editor.begin_stroke();editor.paint_at(Vector2(.10,.86));editor.paint_at(Vector2(.15,.86));editor.end_stroke()
		check(editor.data.rows!=before and editor._code(Vector2(.125,.86))=="W" and editor.history.size()==1,"continuous stroke fills drag gaps as one undo")
		editor.undo();check(editor.data.rows==before,"undo exact rows")
		editor.redo();check(editor._code(Vector2(.125,.86))=="W","redo exact stroke")
		editor.undo();editor.slider.value=0;check(editor.canvas.opacity==0,"hide overlay for geography inspection")
		var location:=Vector2(.4,.4)
		var pixel: Vector2=editor.canvas.point(location)
		editor.canvas.zoom_at(pixel,2)
		check(editor.canvas.normalized(pixel).distance_to(location)<.00001,"zoom holds map coordinate under pointer")
		editor.canvas.fit();check(editor.canvas.zoom==1 and editor.canvas.pan==Vector2.ZERO,"fit resets zoom and pan")
		editor._mode(true);editor.probe_at(World.point(World.site("town_ravenford").position));editor.probe_at(World.point(World.site("saltwatch").position))
		check(not editor.canvas.route.is_empty() and editor.status.text.begins_with("Safe route"),"probe uses actual weighted navigation")
		editor.probe_at(Vector2(.95,.9));check(editor.status.text.begins_with("Blocked"),"water probe explained")
		editor.select("W");editor.begin_stroke();editor.paint_at(World.point(World.site("town_ravenford").position));editor.end_stroke()
		check(not editor.save_changes() and editor.status.text.contains("blocked"),"save refuses blocked service destination")
		editor.undo();check(editor.save_changes(),"valid mask saves to isolated QA file")
		check(FileAccess.file_exists(editor.file_path) and JSON.parse_string(FileAccess.get_file_as_string(editor.file_path)).rows==editor.data.rows,"saved mask roundtrip")
		editor.select("X");editor.begin_stroke();editor.paint_at(Vector2(.15,.86));editor.end_stroke();editor._reload()
		check(editor.data.rows==editor.saved_rows,"reload discards unsaved rows")
		editor.undo();check(editor.data.rows!=editor.saved_rows,"reload is undoable")
		editor.redo();editor._back();check(routes==["res://scenes/world/LivingWorld.tscn"],"saved editor returns to game")
		for path: String in [editor.file_path,editor.file_path+".previous"]:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		editor.queue_free();viewport.queue_free();await frames()
	check(Campaign_same(campaign.state,campaign_before),"editor never mutates campaign, resources or strategic clock")
	for failure in failures: push_error(failure)
	print("terrain_editor_interface_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
func Campaign_same(a: Dictionary,b: Dictionary) -> bool:
	return preload("res://scripts/session/campaign_session.gd").same_data(a,b)
