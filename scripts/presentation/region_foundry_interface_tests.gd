extends SceneTree
const World:=preload("res://scripts/domain/living_world.gd")
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frames() -> void:
	for frame in range(10): await process_frame
func run() -> void:
	var campaign:=root.get_node("CampaignSession")
	var authored_bytes:=FileAccess.get_file_as_string(Terrain.PATH)
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		campaign.load_profile("",true);campaign.enable_living_world()
		var original: Dictionary=campaign.state.duplicate(true)
		var viewport:=SubViewport.new();viewport.size=dimensions;root.add_child(viewport)
		var view: Control=load("res://scenes/world/RegionFoundry.tscn").instantiate()
		view.qa_memory=true
		var routes: Array[String]=[]
		view.scene_requested.connect(func(path: String) -> void: routes.append(path))
		viewport.add_child(view);await frames()
		check(not view.geography.is_empty() and not view.busy and not view.buttons.play.disabled,"foundry initializes validated preview")
		check(campaign.same_data(campaign.state,original),"preview generation does not mutate or save company")
		view.map._camera_action("overview");await frames()
		check(view.map.size.y>dimensions.y*.60,"large independent preview map")
		for button: Button in view.buttons.values(): check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(button.get_global_rect()),"foundry control fits viewport")
		var occupied: Array[Rect2]=[]
		for button: Button in view.map.site_buttons.values():
			check(Rect2(Vector2.ZERO,view.map.size).encloses(button.get_rect()),"generated site label fits map")
			for previous: Rect2 in occupied: check(not previous.intersects(button.get_rect()),"generated site labels do not overlap")
			occupied.append(button.get_rect())
		view.map.site_buttons.saltwatch.pressed.emit()
		check(not view.preview_profile.living_world.party.path.is_empty() and campaign.same_data(campaign.state,original),"safe route preview is read-only")
		view.seed_input.value=42
		check(view.buttons.play.disabled,"dirty seed cannot play stale preview")
		view.preset_input.select(1);view.buttons.generate.pressed.emit();await frames()
		check(view.geography.seed==42 and view.geography.preset=="woodland" and not view.buttons.play.disabled,"seed/preset generation updates preview")
		view.overlay_button.button_pressed=true
		check(view.map.semantic_overlay,"semantic overlay control reaches renderer")
		view.buttons.play.pressed.emit();await frames()
		check(routes.back()=="res://scenes/world/LivingWorld.tscn" and campaign.state.living_world.geography.checksum==view.geography.checksum,"Play opens exact preview geography through session owner")
		var live: Control=load("res://scenes/world/LivingWorld.tscn").instantiate()
		live.scene_requested.connect(func(path: String) -> void: routes.append(path))
		viewport.add_child(live);await frames()
		check(live.buttons.terrain.disabled and not live.buttons.regions.disabled,"generated geography immutable; selector available")
		check(live.map.region_state.geography.checksum==view.geography.checksum,"live renderer and preview share saved snapshot")
		original=campaign.state.duplicate(true)
		view.buttons.play.pressed.emit();await frames()
		check(campaign.same_data(campaign.state,original),"repeated Play resumes current company without reset")
		view.buttons.back.pressed.emit()
		check(routes.back()=="res://scenes/world/LivingWorld.tscn" and campaign.same_data(campaign.state,original),"Current company preserves progress")
		live.queue_free();view.queue_free();viewport.queue_free();await frames()
	check(FileAccess.get_file_as_string(Terrain.PATH)==authored_bytes,"foundry leaves hand-painted revision9 byte-identical")
	campaign.load_profile("",true)
	for failure in failures: push_error(failure)
	print("region_foundry_interface_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
