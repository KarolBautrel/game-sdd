extends SceneTree
## Supplementary native Foundry -> Vast -> legacy/strategic memory-only proof.
const Foundry := preload("res://scenes/world/RegionFoundry.tscn")
const P := preload("res://scripts/domain/strategist_protocol.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
func _initialize() -> void: run.call_deferred()
func frames() -> void:
	for i in range(5): await process_frame
func run() -> void:
	var campaign := root.get_node("CampaignSession");campaign.load_profile("",true)
	var before := P.encoded(campaign.state)
	var viewport := SubViewport.new();viewport.size=Vector2i(1920,1080);root.add_child(viewport)
	var view := Foundry.instantiate();view.qa_memory=true;var routes: Array=[]
	view.scene_requested.connect(func(path): routes.append(path));viewport.add_child(view);await frames()
	view.size_input.select(2);view.size_input.item_selected.emit(2)
	check(view.buttons.play.disabled,"new size cannot play a stale preview")
	view.generate_region();await frames()
	check(view.geography.version==3 and view.geography.terrain.width==768,"actual foundry generates Vast")
	check(view.summary.text.contains("Vast: 16x area"),"actual size summary")
	check(view.map.camera.zoom==5.2 and view.map.illustration.reference_width==6688,"native preview uses proper local paint/camera scale")
	check(P.encoded(campaign.state)==before,"generation changes no company progress")
	view.map.site_buttons.saltwatch.pressed.emit()
	check(not view.preview_profile.living_world.party.path.is_empty() and view.status.text.contains("campaign hours"),"safe preview route uses physical trip estimates")
	check(P.encoded(campaign.state)==before,"preview route is not actual travel")
	view.buttons.play.pressed.emit();await frames()
	check(campaign.memory_only and campaign.state.living_world.geography.checksum==view.geography.checksum,"Play opens exact preview in a memory-only company")
	check(routes.back()=="res://scenes/world/LivingWorld.tscn","legacy Vast entry remains functional")
	view.buttons.strategy.pressed.emit();await frames()
	var owner := root.get_node("StrategicSession")
	check(owner.regional_active() and owner.session.state.region.base.version==3,"Faction campaign honors the selected Vast size")
	check(routes.back()=="res://scenes/world/StrategicVastWorld.tscn","strategic Vast entry routes correctly")
	owner.deactivate();view.queue_free();viewport.queue_free();await frames()
	var file := FileAccess.open("res://docs/design/living-world/2026-11-10/vast/foundry.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"checks":checks,"failures":failures,"headless":true,"player_save_access":"NONE"},"\t",true,true)+"\n");file.close()
	for failure: String in failures: push_error(failure)
	print("vast_foundry_probe: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
