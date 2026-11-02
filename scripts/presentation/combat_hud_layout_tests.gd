extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/combat/CombatDebug.tscn").instantiate() as Control
	root.add_child(scene)
	for viewport_size in [Vector2i(2560, 1440), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for frame in range(5):
			await process_frame
		scene._show_action_hover("move", 1)
		for frame in range(3):
			await process_frame
		for label_name in ["ActionTitleLabel", "ActionDetailLabel", "ActionFeedLabel", "StatusLabel", "TurnOrderLabel"]:
			var label := scene.find_child(label_name, true, false) as Label
			print("HUD_LAYOUT ", viewport_size, " ", label_name, " ", label.size)
			if label.text.is_empty() or label.size.y < label.get_theme_font_size("font_size"):
				failures.append("%s %s has no readable text height: %s" % [viewport_size, label_name, label.size])
			var panel := label.get_parent()
			while panel != null and not panel is PanelContainer:
				panel = panel.get_parent()
			if panel is Control and not panel.get_global_rect().grow(1).encloses(label.get_global_rect()):
				failures.append("%s extends outside its panel" % label_name)
		for button: Button in scene.command_buttons.get_children():
			if button.has_meta("action_id"):
				var captions := button.find_children("*","Label",true,false)
				if captions.size()<2: failures.append("Named action lacks caption/cost: "+button.tooltip_text)
				for caption: Label in captions:
					if caption.text.is_empty() or caption.get_theme_font_size("font_size")<24 or caption.size.y<caption.get_theme_font("font").get_height(24)-1:
						failures.append("Unreadable native action caption: "+button.tooltip_text)
				continue
			if button is Button and button.icon == null and (button.text.is_empty() or button.get_theme_font_size("font_size") < 10):
				failures.append("Action button has neither icon nor readable label: %s" % button.tooltip_text)
	var previous_count: int = scene.command_buttons.get_child_count()
	var active: Dictionary = scene._unit_by_id(scene.state.turn_state.active_unit_id)
	active.resources.ap = 0
	active.resources.mp = 0
	scene._render()
	for frame in range(5):
		await process_frame
	if scene.command_buttons.get_child_count() >= previous_count:
		failures.append("Test did not exercise a reduced visible action count")
	if scene.action_title_label.size.y < 15 or scene.action_detail_label.size.y < 11:
		failures.append("Changing action count collapsed the action context")
	scene.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("combat_hud_layout_tests: OK")
	quit(0 if failures.is_empty() else 1)
