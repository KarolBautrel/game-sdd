extends RefCounted
## Dungeon-local sampling of the approved campaign skin. Shared world UI is untouched.
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const HIDE := "res://assets/ui/dungeon/materials/campaign_hide.png"

static func frame(file: String, padding: int = 24, tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _stretch(UI.frame(file,padding,tint))

static func _stretch(style: StyleBoxTexture) -> StyleBoxTexture:
	var filename := style.texture.resource_path.get_file()
	if filename in ["frame_dark.png","button.png"]:
		style.texture = UI.Assets.texture("res://assets/ui/dungeon/materials/"+filename)
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style

static func theme() -> Theme:
	var result := UI.theme()
	for type: StringName in result.get_type_list():
		for name: StringName in result.get_stylebox_list(type):
			var style := result.get_stylebox(name,type)
			if style is StyleBoxTexture:
				result.set_stylebox(name,type,_stretch(style.duplicate() as StyleBoxTexture))
	return result

static func backdrop() -> TextureRect:
	var result := TextureRect.new()
	result.name = "CampaignHide"
	result.texture = UI.Assets.texture(HIDE)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	result.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	result.modulate = Color(.07,.065,.06)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return result
