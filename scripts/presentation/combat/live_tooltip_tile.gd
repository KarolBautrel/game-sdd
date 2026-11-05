extends Button
## The native popup owns its Label. A weak reference lets tile renders update an
## already-open popup without retaining it after the engine closes it.
var tooltip_label_ref: WeakRef

func _make_custom_tooltip(for_text: String) -> Object:
	var label := Label.new()
	label.name = "LiveTileTooltip"
	label.theme_type_variation = &"TooltipLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = for_text
	tooltip_label_ref = weakref(label)
	return label

func set_live_tooltip_text(value: String) -> void:
	tooltip_text = value
	if tooltip_label_ref != null:
		var label := tooltip_label_ref.get_ref() as Label
		if is_instance_valid(label):
			label.text = value
