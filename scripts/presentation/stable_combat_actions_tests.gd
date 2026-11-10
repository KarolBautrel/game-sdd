extends SceneTree
## Resource/cooldown fixtures prove tray behavior, not physical/user acceptance.
const Actions := preload("res://scripts/presentation/combat/combat_action_model.gd")
const Resolver := preload("res://scripts/domain/combat_resolver.gd")
const SOURCE := "res://resources/data/combat_encounters/drawn_roster_skirmish.json"
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func frames() -> void:
	for i in range(5): await process_frame

func button_for(hud: Control, id: String) -> Button:
	for child in hud.command_buttons.get_children():
		if child is Button and not child.is_queued_for_deletion() and child.get_meta("action_id", "") == id:
			return child
	return null

func tray(hud: Control) -> Dictionary:
	var result := {}
	for child in hud.command_buttons.get_children():
		if child is Button and not child.is_queued_for_deletion() and child.has_meta("action_id") and not child.get_meta("developer_action", false):
			result[child.get_meta("action_id")] = [child.get_meta("action_slot"), child.get_global_rect()]
	return result

func _run() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var state: Dictionary = Resolver.simulate(source, []).state
	var roles := 0
	for unit: Dictionary in state.units:
		if unit.team != "player": continue
		roles += 1
		state.turn_state.active_unit_id = unit.id
		var granted := Actions.visible_primary_action_ids(state)
		check(granted.has("end_turn") and granted.has("move"), unit.id + " has primary controls")
		for action: String in Actions.PRIMARY_ACTION_IDS:
			check(granted.has(action) == Actions.action_granted_to_unit(state, unit, action), unit.id + " exact grants " + action)
		unit.resources.ap = 0
		unit.resources.mp = 0
		check(Actions.visible_primary_action_ids(state) == granted, unit.id + " resource exhaustion preserves order")
		for action: String in granted:
			check(Actions.action_can_be_shown_now(state, unit, action) == (action == "end_turn"), unit.id + " exhausted enablement " + action)
		unit.resources.ap = 1
		for action: String in granted:
			if action in ["move", "end_turn"]: continue
			var cost := Actions.action_ap_cost(state, unit, action, 2 if action in ["aimed_shot", "power_strike"] else 1)
			check(Actions.action_can_be_shown_now(state, unit, action) == (cost <= 1), "exact equipment AP cost " + action)
		unit.resources.ap = 3
		for action: String in granted:
			if action not in ["shield_wall", "power_strike", "deep_cut", "aimed_shot"]: continue
			unit.statuses.append({"id":"skill_cooldown", "action_id":action, "remaining_turns":2})
			check(Actions.action_unavailability_reason(state, unit, action) == "Cooldown: 2 turns.", "cooldown reason " + action)
			check(Actions.visible_primary_action_ids(state) == granted, "cooldown retains " + action)
			unit.statuses.clear()
	check(roles == 4, "four distinct player kits checked")

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	root.add_child(viewport)
	var hud: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	viewport.add_child(hud)
	await frames()
	hud.selected_scenario_id = "drawn_roster_skirmish"
	hud._load_selected_scenario()
	await frames()
	var active: Dictionary = hud._unit_by_id(hud.state.turn_state.active_unit_id)
	var initial := tray(hud)
	active.resources.ap = 0
	active.resources.mp = 0
	hud.selected_action = "basic_attack"
	hud._render()
	await frames()
	check(tray(hud) == initial, "resource exhaustion retains real slot numbers and positions")
	check(hud.selected_action == "end_turn", "exhaustion selects usable End turn")
	for id: String in initial:
		var button := button_for(hud, id)
		check(button.disabled == (id != "end_turn"), "button lock " + id)
		if id != "end_turn":
			check(button.tooltip_text.contains("Need "), "disabled reason in tooltip " + id)
			var before: Dictionary = hud.state.duplicate(true)
			var selection: String = hud.selected_action
			button.pressed.emit()
			hud._activate_action_slot(int(button.get_meta("action_slot")))
			check(hud.state == before and hud.selected_action == selection, "disabled click/key cannot submit or select " + id)
	hud._show_action_hover("move", 1)
	check(hud.action_detail_label.text.contains("Need 1 MP"), "disabled hover explains resource")
	var ending_slot := int(button_for(hud, "end_turn").get_meta("action_slot"))
	var old_actor: String = active.id
	check(hud._activate_action_slot(ending_slot), "original End turn key resolves")
	await frames()
	check(hud.state.turn_state.active_unit_id != old_actor, "ordinary End turn advances")
	var attack := button_for(hud, "basic_attack")
	check(attack != null and not attack.disabled, "next hero refreshes attack availability")
	var key := InputEventKey.new()
	key.keycode = KEY_1 + int(attack.get_meta("action_slot")) - 1
	key.pressed = true
	hud._unhandled_key_input(key)
	check(hud.selected_action == "basic_attack", "number selects its actual displayed action")
	var before: Dictionary = hud.state.duplicate(true)
	hud.animation_locked = true
	check(not hud._activate_action_slot(ending_slot) and hud.state == before, "busy input is inert")
	hud.animation_locked = false
	hud.set_process_input(false)
	hud._unhandled_key_input(key)
	check(not hud._activate_action_slot(1) and hud.state == before, "gallery input suspension includes shortcuts")
	hud.set_process_input(true)
	for modified in ["echo", "ctrl_pressed", "alt_pressed", "meta_pressed", "shift_pressed"]:
		hud.selected_action = "move"
		key.set(modified, true)
		hud._unhandled_key_input(key)
		check(hud.selected_action == "move", "ignore repeat/modified key " + modified)
		key.set(modified, false)
	for child in hud.command_buttons.get_children():
		if child is Button and not child.is_queued_for_deletion() and child.get_meta("developer_action", false):
			check(not hud._activate_action_slot(int(child.get_meta("action_slot"))), "developer command excluded from primary shortcuts")
	# Real ordinary Shield wall establishes its actual cooldown and cost.
	var shield := button_for(hud, "shield_wall")
	check(shield != null, "shield hero has actual Shield wall")
	if shield != null:
		var shield_slot := int(shield.get_meta("action_slot"))
		shield.pressed.emit()
		await frames()
		shield = button_for(hud, "shield_wall")
		check(shield.disabled and int(shield.get_meta("action_slot")) == shield_slot, "real cooldown retains disabled slot")
		check(shield.tooltip_text.contains("Cooldown:"), "real cooldown has truthful reason")
	hud.queue_free()
	viewport.queue_free()
	await frames()
	for failure in failures: push_error(failure)
	print("stable_combat_actions_tests: %s checks, %s failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
