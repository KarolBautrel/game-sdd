extends SceneTree

const SKIN_PATH := "res://scripts/presentation/combat/combat_panel_skin.gd"
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _settle() -> void:
	for frame in range(8):
		await process_frame


func _run() -> void:
	if ResourceLoader.exists(SKIN_PATH):
		_test_skin(load(SKIN_PATH))
	else:
		_check(false, "S8-01 CombatPanelSkin is missing")
	var scene: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	root.add_child(scene)
	await _settle()
	_check(scene.find_child("EncounterPanel", true, false) is PanelContainer, "S8-01 encounter header is not framed")
	_check(scene.board_backdrop is Panel, "S8-01 board has no explicit panel frame")
	_check(scene.board_backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE, "S8-06 board frame intercepts tile input")
	_check(scene.theme != null and scene.theme.has_stylebox("panel", "TooltipPanel"), "S8-01 tooltip panel is not themed")
	_check(scene.theme != null and scene.theme.has_stylebox("panel", "PopupMenu"), "S8-01 scenario popup is not themed")
	var picker := scene.command_buttons.find_children("*", "OptionButton", false, false)[0] as OptionButton
	_check(picker.get_popup().get_theme_stylebox("panel") == scene.panel_skin.style("popup"), "S8-01 actual scenario popup does not inherit the battle skin")
	for viewport_size in [Vector2i(2560, 1440), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = viewport_size
		await _settle()
		_check(root.size == viewport_size, "S8-04 physical viewport resize was not applied")
		scene.action_title_label.text = "Long action title ".repeat(30)
		scene.action_detail_label.text = "Long action detail with costs and target feedback ".repeat(35)
		scene.action_feed_label.text = "A very long recent action report ".repeat(40)
		scene.status_label.text = "Persistent status with a long encounter name ".repeat(30)
		scene.turn_order_label.text = "Long unit name and status ".repeat(30)
		var title := scene.find_child("TitleLabel", true, false) as Label
		title.text = "Long encounter title ".repeat(30)
		await _settle()
		_test_scene_bounds(scene, str(viewport_size))
	var before: Dictionary = scene.state.duplicate(true)
	scene._apply_pixel_theme()
	await _settle()
	_check(scene.state == before, "S8-06 skin application changed domain state")
	var active: Dictionary = scene._unit_by_id(scene.state.turn_state.active_unit_id)
	active.resources.ap = 0
	active.resources.mp = 0
	scene._render()
	await _settle()
	_test_scene_bounds(scene, "reduced action count")
	scene._reset_debug_encounter()
	await _settle()
	_test_scene_bounds(scene, "encounter reload")
	scene.queue_free()
	await _settle()
	for failure in failures:
		push_error(failure)
	print("combat_panel_skin_tests: %s checks, %s failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _test_skin(script: Script) -> void:
	var skin = script.new()
	var other = script.new()
	var opaque: StyleBox = skin.style("panel")
	var board: StyleBox = skin.style("board")
	_check(opaque is StyleBoxTexture, "S8-01 imported panel frame did not load")
	_check(board is StyleBoxTexture, "S8-01 imported board frame did not load")
	_check(not board.draw_center, "S8-03 board frame draws over its center")
	_check(opaque.draw_center, "S8-03 board transparency leaked into opaque panel")
	var other_style: StyleBox = other.style("panel")
	opaque.content_margin_left = 99
	_check(other_style.content_margin_left != 99, "S8-03 style mutation leaked into another skin instance")
	var missing = script.new("res://missing-stage8-small.png", "res://missing-stage8-large.png")
	for role in ["panel", "bar", "inset", "resource", "board", "tooltip", "popup"]:
		var fallback: StyleBox = missing.style(role)
		var expected: StyleBox = other.style(role)
		_check(fallback is StyleBoxFlat, "S8-02 no flat fallback for " + role)
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			_check(is_equal_approx(fallback.get_content_margin(side), expected.get_content_margin(side)), "S8-02 fallback changes padding for " + role)
	_check(not missing.style("board").draw_center, "S8-02 fallback board covers its center")
	var font: Font = ThemeDB.fallback_font
	var source := "Zażółć gęślą jaźń, attack costs and target status. ".repeat(10) + "\n" + "UnbrokenToken".repeat(35)
	var wrapped: String = skin.wrap_tooltip(source, font)
	_check(wrapped.replace(" ", "").replace("\n", "") == source.replace(" ", "").replace("\n", ""), "S8-05 tooltip lost content")
	_check(wrapped.contains("\n"), "S8-05 long tooltip did not wrap")
	for line in wrapped.split("\n"):
		_check(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, script.TOOLTIP_FONT_SIZE).x <= script.TOOLTIP_WIDTH + 0.1, "S8-05 tooltip exceeds width")
	_check(skin.wrap_tooltip("", font) == "", "S8-05 empty tooltip changed")
	_check(skin.wrap_tooltip("Move [1]", font) == "Move [1]", "S8-05 short tooltip changed")


func _test_scene_bounds(scene: Control, context: String) -> void:
	var viewport := scene.get_global_rect().grow(1)
	var frame: Rect2 = scene.board_backdrop.get_global_rect()
	var board: Rect2 = scene.board_root.get_global_rect()
	var top := scene.get_node("RootMargin/RootVBox/TopHud") as Control
	print("S8_LAYOUT ", context, " viewport=", viewport, " frame=", frame, " top=", top.get_global_rect(), " bottom=", scene.bottom_hud.get_global_rect())
	_check(viewport.encloses(frame), "S8-04 board frame outside viewport: " + context)
	_check(viewport.encloses(top.get_global_rect()), "S8-04 top HUD outside viewport: " + context)
	_check(viewport.encloses(scene.bottom_hud.get_global_rect()), "S8-04 bottom HUD outside viewport: " + context)
	_check(not board.intersects(top.get_global_rect()), "S8-04 board overlaps top HUD: " + context)
	_check(not board.intersects(scene.bottom_hud.get_global_rect()), "S8-04 board overlaps bottom HUD: " + context)
	for label_name in ["TitleLabel", "StatusLabel", "TurnOrderLabel", "ActionTitleLabel", "ActionDetailLabel", "ActionFeedLabel", "OverlayLogLabel"]:
		var label := scene.find_child(label_name, true, false) as Label
		_check(label != null and label.size.y >= label.get_theme_font_size("font_size"), "S8-04 unreadable label: " + label_name)
		if label == null:
			continue
		var panel := label.get_parent()
		while panel != null and not panel is PanelContainer:
			panel = panel.get_parent()
		_check(panel is PanelContainer, "S8-01 missing parent frame: " + label_name)
		if panel is PanelContainer:
			_check(panel.get_global_rect().grow(1).encloses(label.get_global_rect()), "S8-04 label outside panel: " + label_name + " " + context)
			var style: StyleBox = panel.get_theme_stylebox("panel")
			var content := Rect2(Vector2(style.content_margin_left, style.content_margin_top), panel.size - Vector2(style.content_margin_left + style.content_margin_right, style.content_margin_top + style.content_margin_bottom))
			var local_label := Rect2(panel.get_global_transform().affine_inverse() * label.global_position, label.size)
			_check(content.grow(1).encloses(local_label), "S8-04 label intrudes into decorative padding: " + label_name + " " + context)
