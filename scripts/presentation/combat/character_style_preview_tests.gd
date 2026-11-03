extends SceneTree
## Presentation011: actual widget state, asset coverage and modal isolation.
const Preview := preload("res://scripts/presentation/combat/character_style_preview.gd")
var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_run.call_deferred()


func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _run() -> void:
	var preview: Control = load("res://scenes/combat/CharacterStylePreview.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	expect(preview.stages.size() == 3, "Three simultaneous studies")
	for index in range(4):
		preview.direction_control.select(index)
		preview.direction_control.item_selected.emit(index)
		for card in range(3):
			var texture: Texture2D = preview.stages[card].actor
			expect(texture != null and texture.get_size() == Vector2(280, 280), "Actual native texture")
			expect(texture.resource_path.ends_with(Preview.IDS[card] + "/" + Preview.VIEWS[index] + ".png"), "Synchronized direction")
	for index in range(5):
		preview.zoom_control.select(index)
		preview.zoom_control.item_selected.emit(index)
		expect(preview.stages.all(func(stage: Control) -> bool: return stage.magnification == Preview.ZOOMS[index]), "Shared zoom")
	for index in range(3):
		preview.ground_control.select(index)
		preview.ground_control.item_selected.emit(index)
		expect(preview.stages.all(func(stage: Control) -> bool: return stage.floor_art.resource_path.ends_with(Preview.GROUNDS[index] + ".png")), "Shared floor")
	preview.face_control.button_pressed = true
	expect(preview.faces and preview.zoom_control.disabled and preview.direction_control.disabled, "Face mode disables body-only controls")
	for stage in preview.stages:
		expect(stage.actor.get_size() == Vector2(512, 512) and stage.face_mode, "Face crop loads")
	preview.face_control.button_pressed = false
	expect(not preview.faces and not preview.zoom_control.disabled, "Return to body view")
	preview.queue_free()
	await process_frame
	var combat: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	root.add_child(combat)
	await process_frame
	await process_frame
	var before: String = JSON.stringify(combat.state)
	var original_input: bool = combat.is_processing_input()
	var opener := combat.find_child("CharacterStylePreviewButton", true, false) as Button
	expect(opener != null, "Battle Tools entry exists")
	opener.pressed.emit()
	await process_frame
	var modal := combat.get_node_or_null("CharacterStylePreview")
	expect(modal != null and not combat.is_processing_input(), "Battle shortcuts suspended")
	modal._close_preview()
	await process_frame
	expect(combat.get_node_or_null("CharacterStylePreview") == null and combat.is_processing_input() == original_input, "Modal closes/restores input")
	expect(JSON.stringify(combat.state) == before, "Battle state unchanged")
	combat.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("STYLE_PREVIEW_TESTS_PASS ", checks)
	quit(0 if failures.is_empty() else 1)
