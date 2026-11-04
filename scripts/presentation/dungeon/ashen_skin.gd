extends RefCounted
## Painted production components, local to expedition UI.
const ROOT := "res://assets/ui/dungeon/ashen/"
const FONT := preload("res://assets/ui/fonts/EBGaramond.ttf")
const ITALIC := preload("res://assets/ui/fonts/EBGaramond-Italic.ttf")
const SYMBOL_FONT := preload("res://assets/ui/fonts/SourceSans3-Semibold.ttf")
const INK := Color("251e18")
const IVORY := Color("e6dcc9")

static func texture(id: String) -> Texture2D:
	return load(ROOT+id+".png") as Texture2D

static func frame(id: String, padding: float=16, margin: float=24) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture(id)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: box.set_texture_margin(side,margin)
	box.set_content_margin_all(padding)
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return box

static func theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 30
	theme.set_color("font_color","Label",INK)
	for type in ["Button","OptionButton"]:
		theme.set_font("font",type,FONT)
		theme.set_color("font_color",type,INK)
		theme.set_color("font_hover_color",type,Color("332118"))
		theme.set_color("font_disabled_color",type,Color("777166"))
		theme.set_stylebox("normal",type,frame("button-secondary"))
		var hover := frame("button-secondary")
		hover.modulate_color = Color(1.15,1.1,1.02)
		theme.set_stylebox("hover",type,hover)
		var pressed := frame("button-secondary")
		pressed.modulate_color = Color(.8,.76,.72)
		theme.set_stylebox("pressed",type,pressed)
		var disabled := frame("button-secondary")
		disabled.modulate_color = Color(.65,.65,.65)
		theme.set_stylebox("disabled",type,disabled)
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = Color("d5b683")
		focus.set_border_width_all(2)
		theme.set_stylebox("focus",type,focus)
	return theme

static func picture(parent: Node, id: String, name: String="") -> TextureRect:
	var image := TextureRect.new()
	image.name = name if not name.is_empty() else id
	image.texture = texture(id)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image
