extends RefCounted
## Battle chrome only. Textures and styles are isolated from gameplay state.

const PixelSkin := preload("res://scripts/presentation/shared/pixel_skin.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const SMALL_PATH := "res://assets/ui/campaign/frame_dark.png"
const LARGE_PATH := "res://assets/ui/campaign/frame_dark.png"
const TOOLTIP_FONT_SIZE := 24
const TOOLTIP_WIDTH := 560.0
const BOARD_FRAME_MARGIN := 8.0
const TEXT_COLOR := Color("f0e6c9")
const GOLD_COLOR := Color("e9c36d")

var _small_path: String
var _large_path: String
var _pixel_skin := PixelSkin.new()
var _styles: Dictionary = {}


func _init(small_path: String = SMALL_PATH, large_path: String = LARGE_PATH) -> void:
	_small_path = small_path
	_large_path = large_path


func style(role: String) -> StyleBox:
	if _styles.has(role):
		return _styles[role]
	var padding := Vector4(18, 18, 18, 18)
	if role == "bar":
		padding = Vector4(18, 18, 18, 18)
	elif role == "inset":
		padding = Vector4(12, 8, 12, 8)
	elif role == "resource":
		padding = Vector4.ONE * 2
	elif role == "board":
		padding = Vector4.ZERO
	var fallback := PixelSkin.flat_frame(Color("161611"), Color("8e7649"), 2, 0)
	fallback.content_margin_left = padding.x
	fallback.content_margin_top = padding.y
	fallback.content_margin_right = padding.z
	fallback.content_margin_bottom = padding.w
	var result: StyleBox = fallback
	if role == "resource":
		fallback.bg_color = Color(0.04, 0.035, 0.03, 0.78)
		fallback.border_color = Color(0.90, 0.66, 0.20, 0.90)
		fallback.set_border_width_all(1)
	elif role == "inset":
		fallback.bg_color = Color("10120f")
		fallback.set_border_width_all(1)
	elif role == "board":
		fallback.draw_center = false
		var texture := _pixel_skin.scaled_texture(_small_path, Vector2i(62, 57))
		if texture != null:
			var border := StyleBoxTexture.new()
			border.texture = texture
			for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: border.set_texture_margin(side,7)
			border.draw_center = false
			border.content_margin_left = 0
			border.content_margin_top = 0
			border.content_margin_right = 0
			border.content_margin_bottom = 0
			result = border
	else:
		var path := _large_path if role == "bar" else _small_path
		var texture_margins := Vector4(36, 36, 36, 36)
		# Duplicate the cached style before role-specific customization.
		result = _pixel_skin.frame(path, texture_margins, padding, fallback).duplicate() as StyleBox
	_styles[role] = result
	return result


func popup_theme() -> Theme:
	var result := UI.theme()
	result.set_stylebox("panel", "TooltipPanel", style("tooltip"))
	result.set_color("font_color", "TooltipLabel", TEXT_COLOR)
	result.set_font_size("font_size", "TooltipLabel", TOOLTIP_FONT_SIZE)
	result.set_stylebox("panel", "PopupMenu", style("popup"))
	var selected := PixelSkin.flat_frame(Color("383122"), GOLD_COLOR, 1, 0)
	result.set_stylebox("hover", "PopupMenu", selected)
	var separator := StyleBoxLine.new()
	separator.color = Color("8e7649")
	result.set_stylebox("separator", "PopupMenu", separator)
	for key in ["font_color", "font_hover_color"]:
		result.set_color(key, "PopupMenu", TEXT_COLOR)
	result.set_color("font_disabled_color", "PopupMenu", Color("918773"))
	result.set_font_size("font_size", "PopupMenu", TOOLTIP_FONT_SIZE)
	result.set_constant("v_separation", "PopupMenu", 8)
	result.set_stylebox("normal", "OptionButton", style("inset"))
	result.set_stylebox("hover", "OptionButton", selected)
	result.set_stylebox("pressed", "OptionButton", selected)
	result.set_color("font_color", "OptionButton", TEXT_COLOR)
	return result


func wrap_tooltip(text: String, font: Font) -> String:
	var lines: Array[String] = []
	for paragraph in text.split("\n", true):
		var current := ""
		for word in paragraph.split(" ", false):
			var candidate := current + (" " if not current.is_empty() else "") + word
			if _text_width(candidate, font) <= TOOLTIP_WIDTH:
				current = candidate
				continue
			if not current.is_empty():
				lines.append(current)
			current = ""
			for character in word:
				candidate = current + character
				if not current.is_empty() and _text_width(candidate, font) > TOOLTIP_WIDTH:
					lines.append(current)
					current = character
				else:
					current = candidate
		lines.append(current)
	return "\n".join(lines)


func _text_width(text: String, font: Font) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TOOLTIP_FONT_SIZE).x
