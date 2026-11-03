extends GridContainer
var collapse_width := 1120
## Switch cards between two columns and a readable single-column flow.
func _ready() -> void:
	add_theme_constant_override("h_separation",18)
	add_theme_constant_override("v_separation",18)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	columns = 2 if size.x >= collapse_width else 1
