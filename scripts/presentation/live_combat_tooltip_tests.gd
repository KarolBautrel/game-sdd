extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func run() -> void:
	var previous: Variant = ProjectSettings.get_setting("debug/qa/combat_scenario", "")
	ProjectSettings.set_setting("debug/qa/combat_scenario", "painted_forest_ambush")
	var hud: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	root.add_child(hud)
	await process_frame; await process_frame
	# Bounded normal move puts the first actor in melee range of the guard.
	hud._run_command(hud._build_command("move", {"type":"tile", "position":{"x":6,"y":7}}))
	await wait_unlocked(hud)
	# Keep the remaining fixture setup explicit: move the guard beside the actor.
	# Only the attack and popup refresh are under test, not encounter balance.
	var target: Dictionary
	for unit: Dictionary in hud.state.units:
		if str(unit.get("id", "")) == "unit_bandit_guard_pilot": target = unit
	check(not target.is_empty(), "forest guard fixture exists")
	if target.is_empty():
		for failure in failures: push_error(failure)
		hud.queue_free(); quit(1); return
	target.position = {"x":7,"y":7}
	target.resources.hp = 7
	hud._render()
	var tile: Button = hud.grid_container.get_child(7 * int(hud.state.grid.width) + 7)
	var popup: Label = tile._make_custom_tooltip(tile.tooltip_text)
	root.add_child(popup)
	check(popup.text.contains("HP 7/"), "open popup starts with current HP")
	check(popup.theme_type_variation == &"TooltipLabel" and popup.mouse_filter == Control.MOUSE_FILTER_IGNORE, "native tooltip theme and input contract")
	for expected_hp: int in [1,0]:
		hud._run_command(hud._build_command("basic_attack", {"type":"unit", "unit_id":target.id}))
		await wait_unlocked(hud)
		check(popup.text == tile.tooltip_text, "existing popup refreshes without pointer movement")
		check(popup.text.contains("HP %d/" % expected_hp), "existing popup shows committed damage or corpse HP")
	popup.queue_free(); await process_frame
	hud._render()
	var reopened: Label = tile._make_custom_tooltip(tile.tooltip_text)
	root.add_child(reopened)
	check(reopened.text == tile.tooltip_text, "closed popup can be safely recreated")
	reopened.queue_free(); hud.queue_free(); await process_frame
	ProjectSettings.set_setting("debug/qa/combat_scenario", previous)
	for failure in failures: push_error(failure)
	print("live_combat_tooltip_tests: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
func wait_unlocked(hud: Control) -> void:
	var until := Time.get_ticks_msec() + 7000
	while hud.animation_locked and Time.get_ticks_msec() < until: await process_frame
	check(not hud.animation_locked, "normal animation completed")
