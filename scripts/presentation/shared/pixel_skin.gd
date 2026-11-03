extends RefCounted

const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
var _styles: Dictionary = {}
var _scaled: Dictionary = {}


func frame(path: String, texture_margins: Vector4, content_margins: Vector4, fallback: StyleBox = null) -> StyleBox:
	var key := "%s|%s|%s" % [path, texture_margins, content_margins]
	if _styles.has(key):
		return _styles[key]
	var texture := Assets.texture(path)
	if texture == null:
		return fallback
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = texture_margins.x
	style.texture_margin_top = texture_margins.y
	style.texture_margin_right = texture_margins.z
	style.texture_margin_bottom = texture_margins.w
	style.content_margin_left = content_margins.x
	style.content_margin_top = content_margins.y
	style.content_margin_right = content_margins.z
	style.content_margin_bottom = content_margins.w
	_styles[key] = style
	return style


func scaled_texture(path: String, target_size: Vector2i) -> Texture2D:
	var key := "%s|%s" % [path, target_size]
	if _scaled.has(key):
		return _scaled[key]
	var image := Assets.image_copy(path)
	if image == null:
		return null
	image.resize(maxi(1, target_size.x), maxi(1, target_size.y), Image.INTERPOLATE_NEAREST)
	var texture := ImageTexture.create_from_image(image)
	_scaled[key] = texture
	return texture


static func flat_frame(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style
