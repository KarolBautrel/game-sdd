extends SceneTree
## Real headless HUD/animation proof; no OS input or campaign save access.
const Resolver := preload("res://scripts/domain/combat_resolver.gd")
const Campaign := preload("res://scripts/session/campaign_session.gd")
const SOURCE := "res://resources/data/combat_encounters/drawn_roster_skirmish.json"
var checks := 0
var failures: Array[String] = []
var cases: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func button_for(hud: Control, action: String) -> Button:
	for child in hud.command_buttons.get_children():
		if child is Button and not child.is_queued_for_deletion() and child.get_meta("action_id", "") == action:
			return child
	return null

func wait_commit(hud: Control) -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while hud.animation_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not hud.animation_locked, "bounded animated commit")
	await process_frame

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	root.add_child(viewport)
	var hud: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	viewport.add_child(hud)
	await process_frame
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	for kit: Array in [["unit_player_002","ranged_attack"],["unit_player_002","aimed_shot"],["unit_rogue_pilot","basic_attack"],["unit_player_001","basic_attack"],["unit_knight_pilot","basic_attack"]]:
		for low_hp: bool in [false,true]:
			for index: int in [1,19,42,599]:
				hud.state = Resolver.simulate(source, []).state
				hud.state.turn_state.active_unit_id = kit[0]
				var actor: Dictionary = hud._unit_by_id(kit[0])
				var target: Dictionary = hud._unit_by_id("unit_enemy_spear_1")
				actor.position = {"x":0,"y":0}
				target.position = {"x":1,"y":0}
				if low_hp: target.resources.hp = 1
				hud.command_index = index
				hud.selected_action = "move"
				hud._render()
				await process_frame
				var button := button_for(hud, kit[1])
				check(button != null and not button.disabled, "real granted control " + str(kit))
				if button == null or button.disabled: continue
				if kit[1] == "aimed_shot":
					button_for(hud,"ranged_attack").pressed.emit()
					check(hud.selected_action == "ranged_attack", "basic selection before Aimed switch")
					check(hud._activate_action_slot(int(button.get_meta("action_slot"))), "Aimed shortcut after basic selection")
				else:
					button.pressed.emit()
				check(hud.selected_action == kit[1], "actual action selection")
				var before: Dictionary = hud.state.duplicate(true)
				var command: Dictionary = hud._build_command(kit[1],{"type":"unit","unit_id":target.id})
				var preview: Dictionary = hud._target_preview_for_position(target.position)
				check(preview.get("rejection", "") == "", "clear target preview legal")
				check(hud._preview_for_command(command) == preview and hud._preview_for_command(command) == preview, "same next-command identity and stable preview")
				check(hud.state == before and hud.command_index == index, "inspection is read-only")
				var label: Label = hud.unit_layer.get_node(NodePath(target.id+"/TargetPreviewPanel/TargetPreview"))
				var shown := label.text
				check(label.get_parent().visible, "actual target panel visible before submission")
				var expected: Dictionary = Resolver.simulate(before,[command]).state
				var damage := -1
				for event: Dictionary in expected.event_log:
					if event.type == "damage_applied": damage = int(event.damage)
				if damage >= 0: check(shown.contains("DMG %s" % damage), "rendered damage equals resolver event")
				else: check(not shown.contains("DMG ") and shown.contains("MISS"), "miss has no fabricated damage")
				hud._on_tile_pressed(target.position.duplicate(true))
				await wait_commit(hud)
				check(Campaign.same_data(hud.state.units,expected.units), "animated commit retains exact HP/AP/status result")
				check(hud.state.seed == expected.seed and hud.command_index == index+1, "commit uses expected seed and advances command once")
				var committed_damage := -1
				for event: Dictionary in hud.state.event_log:
					if event.type == "damage_applied" and event.get("command_id", "") == command.id: committed_damage = int(event.damage)
				check(committed_damage == damage, "shown versus actual submitted damage")
				var after: Dictionary = hud._unit_by_id(target.id)
				if int(after.resources.hp) == 0:
					var node: Control = hud.unit_layer.get_node_or_null(NodePath(target.id+"/TargetPreviewPanel"))
					check(node == null or not node.visible, "dead target does not retain legal preview")
				cases.append({"actor":kit[0],"action":kit[1],"command":index,"low_hp":low_hp,"label":shown,"preview_damage":damage,"committed_damage":committed_damage,"hp_after":after.resources.hp})
	viewport.queue_free()
	await process_frame
	print("PREVIEW_CONSISTENCY_CASES ",JSON.stringify(cases))
	for failure in failures: push_error(failure)
	print("combat_preview_consistency_tests: %s checks, %s failures, %s cases" % [checks,failures.size(),cases.size()])
	quit(0 if failures.is_empty() else 1)
