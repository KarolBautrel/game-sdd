extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/combat/CombatDebug.tscn").instantiate() as Control
	root.add_child(scene)
	await process_frame
	var actor_id: String = scene.state.turn_state.active_unit_id
	var ap_before: int = scene._unit_by_id(actor_id).resources.ap
	scene._run_command(scene._build_command("defend", {}))
	await _expect_fallback(scene, "Defend")
	if int(scene._unit_by_id(actor_id).resources.ap) != ap_before - 1:
		failures.append("Defend did not retain resolver AP cost")
	if not str(scene.state.event_log).contains("defending"):
		failures.append("Defend did not retain resolver status")
	await process_frame

	var next_state: Dictionary = scene.state.duplicate(true)
	var next_log: Array = next_state.event_log.duplicate(true)
	scene.animation_locked = true
	scene._play_combat_animation([
		{"type": "hit_roll_resolved", "actor_id": "absent_actor", "target_unit_id": "absent_target", "outcome": "miss"},
	], scene.state.duplicate(true), next_state, next_log)
	await _expect_fallback(scene, "Absent attack visual")
	await process_frame

	for missing_visual in [false, true]:
		var event := {"type": "unit_moved", "actor_id": "absent_actor" if missing_visual else actor_id, "path": [], "from": {"x": 0, "y": 0}, "to": {"x": 0, "y": 0}}
		scene.animation_locked = true
		scene._play_movement_animation([event], scene.state.duplicate(true), next_state.duplicate(true), next_log.duplicate(true))
		await _expect_fallback(scene, "Movement fallback %s" % missing_visual)
		await process_frame

	scene.queue_free()
	await process_frame
	for failure: String in failures:
		push_error(failure)
	if failures.is_empty():
		print("combat_animation_lifecycle_tests: OK")
	quit(0 if failures.is_empty() else 1)


func _expect_fallback(scene: Control, context: String) -> void:
	if scene.animation_locked:
		failures.append("%s left input locked" % context)
	# Allow legitimate status floating text to expire. The verifier also rejects
	# engine diagnostics emitted while these frames process an unused Tween.
	await create_timer(0.8).timeout
	await process_frame
	if not get_processed_tweens().is_empty():
		failures.append("%s left an unused Tween scheduled" % context)
