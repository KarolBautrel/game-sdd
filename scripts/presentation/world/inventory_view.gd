extends VBoxContainer
signal item_selected(item_id: String)
signal category_changed(category: String)
const Items := preload("res://scripts/domain/item_catalog.gd")
const Gear := preload("res://scripts/domain/campaign_equipment.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Grid := preload("res://scripts/presentation/world/item_grid.gd")
const FILTERS := {"all":"All","equipment":"Gear","valuable":"Loot","quest":"Quest","legacy":"Legacy"}
var _items: Array = []
var _equipment: Dictionary = {}
var category := "all"
var selected_id := ""
var compatible_slot := ""
var shown_ids: Array[String] = []
var filter_buttons: Dictionary = {}
var entries_scroll: ScrollContainer
var grid: GridContainer

func configure(items: Array,equipment: Dictionary = {},selected: String = "",filter: String = "all") -> void:
	_items = items.duplicate(true)
	_equipment = equipment.duplicate(true)
	selected_id = selected if items.has(selected) else ""
	category = filter if FILTERS.has(filter) else "all"
	_render()

func select_item(id: String) -> void:
	selected_id = id if _items.has(id) else ""
	_render()

func highlight_slot(slot: String) -> void:
	compatible_slot = slot
	_render()

func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	shown_ids.clear()
	filter_buttons.clear()
	add_theme_constant_override("separation",12)
	UI.label(self,"%s items  /  %s stacks" % [_items.size(),Items.stacks(_items).size()],20,UI.MUTED)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation",5)
	add_child(tabs)
	for key: String in FILTERS:
		var button := UI.button(FILTERS[key],category == key)
		button.add_theme_font_size_override("font_size",24)
		button.custom_minimum_size.y = 58
		tabs.add_child(button)
		button.pressed.connect(func() -> void:
			category = key
			_render()
			category_changed.emit(key)
		)
		filter_buttons[key] = button
	entries_scroll = ScrollContainer.new()
	entries_scroll.custom_minimum_size.y = 470
	entries_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	entries_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(entries_scroll)
	grid = Grid.new()
	entries_scroll.add_child(grid)
	var rows: Array[Dictionary] = []
	for row: Dictionary in Items.stacks(_items):
		if category != "all" and row.category != category: continue
		shown_ids.append(row.id)
		row.assigned = Gear.assigned(_equipment,row.id)
		rows.append(row)
	grid.configure(rows,selected_id,compatible_slot)
	grid.chosen.connect(func(id: String) -> void:
		selected_id = id
		_render()
		item_selected.emit(id)
	)
	if shown_ids.is_empty(): UI.label(self,"Nothing in this category.",20,UI.MUTED)
