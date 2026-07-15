extends RefCounted
class_name CombatFloatingText

const DEFAULT_MESSAGE_SIZE := Vector2(96, 30)
const DEFAULT_RISE_PIXELS := 44.0
const DEFAULT_DURATION_SECONDS := 0.62
const DEFAULT_STAGGER_SECONDS := 0.08

const DAMAGE_COLOR := Color(1.0, 0.42, 0.22)
const MISS_COLOR := Color(0.72, 0.88, 1.0)
const STATUS_COLOR := Color(0.95, 0.78, 0.30)


static func messages_from_events(events: Array) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	var damage_targets: Dictionary = {}
	var order := 0

	for event: Dictionary in events:
		if event["type"] != "damage_applied":
			continue
		var target_id := str(event.get("target_unit_id", ""))
		if target_id == "":
			continue
		damage_targets[target_id] = true
		messages.append(_message(target_id, "-%s DMG" % event.get("damage", "?"), DAMAGE_COLOR, order))
		order += 1

	for event: Dictionary in events:
		if event["type"] != "hit_roll_resolved":
			continue
		if str(event.get("outcome", "")) != "miss":
			continue
		var target_id := str(event.get("target_unit_id", ""))
		if target_id == "" or damage_targets.has(target_id):
			continue
		messages.append(_message(target_id, "MISS", MISS_COLOR, order))
		order += 1

	for event: Dictionary in events:
		if event["type"] != "status_applied":
			continue
		var target_id := str(event.get("target_unit_id", ""))
		if target_id == "":
			continue
		var status: Dictionary = event.get("status", {})
		var label := str(status.get("id", "STATUS")).replace("_", " ").to_upper()
		messages.append(_message(target_id, label, STATUS_COLOR, order))
		order += 1

	return messages


static func spawn_messages(layer: Control, messages: Array[Dictionary], unit_position_lookup: Callable, options: Dictionary = {}) -> void:
	if layer == null:
		return
	var message_size: Vector2 = options.get("message_size", DEFAULT_MESSAGE_SIZE)
	var rise_pixels := float(options.get("rise_pixels", DEFAULT_RISE_PIXELS))
	var duration_seconds := float(options.get("duration_seconds", DEFAULT_DURATION_SECONDS))
	var stagger_seconds := float(options.get("stagger_seconds", DEFAULT_STAGGER_SECONDS))

	for message: Dictionary in messages:
		var unit_id := str(message.get("unit_id", ""))
		if unit_id == "":
			continue
		var position_variant: Variant = unit_position_lookup.call(unit_id)
		if not position_variant is Vector2:
			continue
		var delay := stagger_seconds * float(message.get("order", 0))
		_spawn_message(layer, position_variant, message, message_size, rise_pixels, duration_seconds, delay)


static func clear(layer: Control) -> void:
	if layer == null:
		return
	for child in layer.get_children():
		child.queue_free()


static func _message(unit_id: String, text: String, color: Color, order: int) -> Dictionary:
	return {
		"unit_id": unit_id,
		"text": text,
		"color": color,
		"order": order,
	}


static func _spawn_message(layer: Control, start_position: Vector2, message: Dictionary, message_size: Vector2, rise_pixels: float, duration_seconds: float, delay: float) -> void:
	var color: Color = message.get("color", DAMAGE_COLOR)
	var panel := PanelContainer.new()
	panel.name = "FloatingText"
	panel.custom_minimum_size = message_size
	panel.size = message_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate = Color(1, 1, 1, 1)
	panel.add_theme_stylebox_override("panel", _style(color))

	var label := Label.new()
	label.name = "Label"
	label.text = str(message.get("text", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = message_size
	label.size = message_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.0, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(label)

	panel.position = start_position
	layer.add_child(panel)

	var tween := layer.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(panel, "position", start_position + Vector2(0, -rise_pixels), duration_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, duration_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(panel):
			panel.queue_free()
	)


static func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.035, 0.025, 0.86)
	style.border_color = color.darkened(0.25)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style
