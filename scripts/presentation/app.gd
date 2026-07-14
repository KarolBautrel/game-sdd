extends Control

const DataCatalog := preload("res://scripts/systems/data_catalog.gd")

@onready var status_label: Label = %StatusLabel
@onready var detail_label: Label = %DetailLabel


func _ready() -> void:
	var slice := DataCatalog.load_vertical_slice()
	var region: Dictionary = slice.get("world_region", {})
	var town: Dictionary = slice.get("town", {})
	var dungeon: Dictionary = slice.get("dungeon", {})
	var action: Dictionary = slice.get("basic_attack", {})

	if region.is_empty() or town.is_empty() or dungeon.is_empty() or action.is_empty():
		status_label.text = "SDD checkpoint failed"
		detail_label.text = "One or more reference data files could not be loaded."
		return

	status_label.text = "SDD checkpoint ready"
	detail_label.text = "Region: %s\nTown: %s\nDungeon: %s\nCombat action: %s" % [
		region.get("id", "missing"),
		town.get("display_name", "missing"),
		dungeon.get("id", "missing"),
		action.get("id", "missing"),
	]
