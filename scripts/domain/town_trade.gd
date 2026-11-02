extends RefCounted
## Trusted offers and unassigned-copy quotes. CampaignSession owns transactions.

const PATH := "res://resources/data/town_trade/ravenford.json"
const Items := preload("res://scripts/domain/item_catalog.gd")
const Gear := preload("res://scripts/domain/campaign_equipment.gd")


static func catalogue() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not data is Dictionary or not validation_errors(data).is_empty():
		push_error("Invalid Ravenford trade catalogue")
		return {}
	return data


static func offers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for offer: Dictionary in catalogue().get("offers", []):
		var row := Items.item(offer.item_id)
		row.buy_price = int(offer.buy_price)
		result.append(row)
	return result


static func buy_offer(item_id: String) -> Dictionary:
	for offer: Dictionary in offers():
		if offer.id == item_id:
			return offer
	return {}


static func sale(item_id: String, owned: Array, equipment: Dictionary) -> Dictionary:
	var row := Items.item(item_id)
	if row.category not in ["valuable", "equipment"] or int(row.value) <= 0:
		return {}
	var free_count := owned.count(item_id) - Gear.assigned(equipment, item_id)
	if free_count <= 0:
		return {}
	row.free_count = free_count
	row.quantity = owned.count(item_id)
	return row


static func sale_options(owned: Array, equipment: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for stack: Dictionary in Items.stacks(owned):
		var quote := sale(stack.id, owned, equipment)
		if not quote.is_empty():
			result.append(quote)
	return result


static func validation_errors(data: Variant) -> Array[String]:
	if not data is Dictionary or data.get("schema") != "sdd.town-trade-v1" or data.get("town_id") != "town_ravenford" or not data.get("offers") is Array or data.offers.is_empty():
		return ["Invalid trade catalogue shape"]
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for offer in data.offers:
		if not offer is Dictionary or not offer.get("item_id") is String or seen.has(offer.item_id):
			errors.append("Missing/duplicate offer id")
			continue
		seen[offer.item_id] = true
		var item := Items.item(offer.item_id)
		if item.category != "equipment":
			errors.append("Offer must reference known equipment")
		var price: Variant = offer.get("buy_price")
		if not (price is int or price is float) or not is_finite(float(price)) or float(price) != floor(float(price)) or float(price) < 1 or float(price) > 1000000000 or float(price) <= float(item.value):
			errors.append("Buy price must be a positive integer above resale value")
	return errors
