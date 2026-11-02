extends VBoxContainer
signal buy_requested(item_id: String)
signal sell_requested(item_id: String)
const Trade := preload("res://scripts/domain/town_trade.gd")
const Gear := preload("res://scripts/domain/campaign_equipment.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Columns := preload("res://scripts/presentation/world/campaign_columns.gd")
const Grid := preload("res://scripts/presentation/world/item_grid.gd")
const Items := preload("res://scripts/presentation/world/item_presentation.gd")
var buy_grid: GridContainer
var sell_grid: GridContainer
var buy_button: Button
var sell_button: Button
var buy_detail: Label
var sell_detail: Label
var buy_art: TextureRect
var sell_art: TextureRect
var _offers: Array[Dictionary] = []
var _sales: Array[Dictionary] = []
var _buy_id := ""
var _sell_id := ""
var _gold := 0
var _available := false

func configure(owned: Array,equipment: Dictionary,gold: int,available: bool,buy_id: String = "",sell_id: String = "") -> void:
	_gold = gold
	_available = available
	_offers = Trade.offers()
	_sales = Trade.sale_options(owned.duplicate(),equipment.duplicate(true))
	for row: Dictionary in _offers:
		row.quantity = owned.count(row.id)
		row.assigned = Gear.assigned(equipment,row.id)
		row.badge = "%sg" % int(row.buy_price)
	for row: Dictionary in _sales: row.badge = "%sg  /  Free %s" % [int(row.value),row.free_count]
	_buy_id = _existing(_offers,buy_id)
	_sell_id = _existing(_sales,sell_id)
	add_theme_constant_override("separation",16)
	UI.label(self,"Equipment & salvage",30,UI.GOLD)
	UI.label(self,"Stock is unlimited. Each trade exchanges one copy.",19,UI.MUTED)
	var columns := Columns.new()
	add_child(columns)
	var buy := UI.card(columns,"Merchant stock")
	buy_grid = Grid.new()
	buy.add_child(buy_grid)
	buy_grid.chosen.connect(func(id: String) -> void:
		_buy_id = id
		_refresh()
	)
	var buy_inspector := _inspector(buy)
	buy_art = buy_inspector[0]
	buy_detail = buy_inspector[1]
	buy_button = UI.button("Buy one",true)
	buy.add_child(buy_button)
	buy_button.pressed.connect(func() -> void:
		if not buy_button.disabled: buy_requested.emit(_buy_id)
	)
	var sell := UI.card(columns,"Your free loot","Assigned, quest and legacy items are kept.")
	sell_grid = Grid.new()
	sell.add_child(sell_grid)
	sell_grid.chosen.connect(func(id: String) -> void:
		_sell_id = id
		_refresh()
	)
	var sell_inspector := _inspector(sell)
	sell_art = sell_inspector[0]
	sell_detail = sell_inspector[1]
	sell_button = UI.button("Sell one",true)
	sell.add_child(sell_button)
	sell_button.pressed.connect(func() -> void:
		if not sell_button.disabled: sell_requested.emit(_sell_id)
	)
	_refresh()

func selected_buy_id() -> String: return _buy_id
func selected_sell_id() -> String: return _sell_id

func _inspector(parent: Node) -> Array:
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel",UI.paper_box(24))
	parent.add_child(paper)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	paper.add_child(row)
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(128,160)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(art)
	var detail := UI.label(row,"",24,UI.INK)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return [art,detail]

func _existing(rows: Array,id: String) -> String:
	for row: Dictionary in rows:
		if row.id == id: return id
	return "" if rows.is_empty() else str(rows[0].id)

func _row(rows: Array,id: String) -> Dictionary:
	for row: Dictionary in rows:
		if row.id == id: return row
	return {}

func _refresh() -> void:
	buy_grid.configure(_offers,_buy_id)
	sell_grid.configure(_sales,_sell_id)
	var offer := _row(_offers,_buy_id)
	var sale := _row(_sales,_sell_id)
	buy_art.texture = null if offer.is_empty() else Items.icon_for(offer)
	sell_art.texture = null if sale.is_empty() else Items.icon_for(sale)
	buy_detail.text = "No stock available." if offer.is_empty() else "%s\nOwned %s  /  Assigned %s\n%s" % [offer.name,offer.quantity,offer.assigned,offer.description]
	sell_detail.text = "No free loot to sell." if sale.is_empty() else "%s\nFree %s of %s\n%s" % [sale.name,sale.free_count,sale.quantity,sale.description]
	buy_button.disabled = not _available or offer.is_empty() or _gold < int(offer.get("buy_price",0))
	sell_button.disabled = not _available or sale.is_empty()
	buy_button.text = "Buy one" if offer.is_empty() else "Buy  /  %sg" % int(offer.buy_price)
	sell_button.text = "Sell one" if sale.is_empty() else "Sell  /  +%sg" % int(sale.value)
	buy_button.tooltip_text = "Return to Ravenford after resolving the expedition/event." if not _available else ("Not enough gold." if buy_button.disabled else "Add one copy to your stash.")
	sell_button.tooltip_text = "Return to Ravenford after resolving the expedition/event." if not _available else "Sell one unassigned copy."
