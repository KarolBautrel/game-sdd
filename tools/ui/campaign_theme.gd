@tool
extends "res://addons/theme_gen/programmatic_theme.gd"


func _type_has_property(type_name: String, property_name: String):
	# ThemeGen 1.4 probes Control properties with temporary unmanaged Nodes.
	# Release those probes here without modifying the pinned upstream library.
	if not ClassDB.class_exists(type_name):
		return false
	var instance: Object = ClassDB.instantiate(type_name)
	var properties: Array = instance.get_property_list()
	if not instance is RefCounted:
		instance.free()
	return properties.any(func(property): return property.name == property_name)
## Editor-owned base typography. Runtime state styling lives in CampaignSkin.
const UPDATE_ON_SAVE = true
const VERBOSITY = Verbosity.SILENT
func setup() -> void:
	set_save_path("res://resources/ui/campaign_theme.tres")
	define_default_font(preload("res://assets/ui/fonts/SourceSans3-Semibold.ttf"))
	define_default_font_size(26)
func define_theme() -> void:
	define_style("Label",{"font_color":Color("eee1c7")})
	define_style("Button",{"font_color":Color("eee1c7"),"font_disabled_color":Color("8c867b"),"font_size":26})
	define_style("TooltipLabel",{"font_color":Color("eee1c7"),"font_size":24})
