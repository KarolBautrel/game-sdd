extends SceneTree

const Model := preload("res://scripts/domain/dungeon_state_model.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load("res://scenes/dungeon/DungeonDebug.tscn").instantiate() as Control
	root.add_child(scene)
	for frame in range(5):
		await process_frame
	for bar: ProgressBar in scene.party_hp_bars.values():
		if not scene.get_viewport_rect().encloses(bar.get_global_rect()):
			failures.append("Party HP bar extends beyond the game viewport: %s" % bar.get_global_rect())
	scene.run_state.target_effects = {"party_slot_front": {"hp_loss": 6, "debuffs": {}}}
	scene.run_state.party_effects.hp_loss = 6
	scene._refresh_presentation_chrome()
	if scene.party_hp_labels.unit_player_001.text != "HP 8/14" or scene.party_hp_bars.unit_player_001.value != 8:
		failures.append("Injury does not refresh visible HP")
	scene.run_state = Model.use_bandage(scene.run_state).state
	scene._refresh_presentation_chrome()
	if scene.party_hp_labels.unit_player_001.text != "HP 9/14" or scene.party_hp_bars.unit_player_001.value != 9:
		failures.append("Recovery does not refresh visible HP")
	scene.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("dungeon_party_layout_tests: OK")
	quit(0 if failures.is_empty() else 1)
