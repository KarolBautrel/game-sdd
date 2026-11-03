extends TextureProgressBar


func configure(texture: Texture2D, meter_size: Vector2) -> void:
	custom_minimum_size = meter_size
	size = meter_size
	texture_under = texture
	texture_progress = texture
	tint_under = Color(0.18, 0.16, 0.14, 0.72)
	tint_progress = Color.WHITE


func set_amount(amount: float, maximum: float) -> void:
	max_value = maxf(1.0, maximum)
	value = clampf(amount, 0.0, max_value)
