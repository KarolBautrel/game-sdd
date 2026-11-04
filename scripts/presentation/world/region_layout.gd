extends BoxContainer
## Wide parchment with a journey column; one-column fallback keeps labels useful.
func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",18)
	resized.connect(_fit)
	_fit()
func _fit() -> void:
	vertical = size.x < 1100
