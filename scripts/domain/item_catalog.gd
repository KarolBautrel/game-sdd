extends RefCounted
## Read-only metadata/grouping. Saved inventory remains owned by CampaignSession.

const PATH := "res://resources/data/items/catalogue.json"
static var _loaded := false
static var _items: Dictionary = {}


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var errors := validation_errors(data)
	if not errors.is_empty():
		push_error("Invalid campaign item catalogue: " + "; ".join(errors))
		return
	for row: Dictionary in data.items:
		_items[row.id] = row.duplicate(true)


static func item(id: String) -> Dictionary:
	_load()
	if _items.has(id):
		return _items[id].duplicate(true)
	return {"id":id,"name":id.replace("_", " ").replace("/", " ").capitalize() if not id.is_empty() else "Uncatalogued item","description":"A keepsake retained from an earlier journey.","category":"legacy","value":0}


static func stacks(items: Array) -> Array[Dictionary]:
	var counts: Dictionary = {}
	for id: String in items:
		counts[id] = int(counts.get(id, 0)) + 1
	var result: Array[Dictionary] = []
	for id: String in counts:
		var row := item(id)
		row.quantity = counts[id]
		result.append(row)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var comparison := str(a.name).nocasecmp_to(str(b.name))
		return str(a.id).nocasecmp_to(str(b.id)) < 0 if comparison == 0 else comparison < 0
	)
	return result


static func validation_errors(data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary or data.get("schema") != "sdd.campaign-items-v1" or not data.get("items") is Array or data.items.is_empty():
		return ["Invalid item catalogue shape"]
	var seen: Dictionary = {}
	for row in data.items:
		if not row is Dictionary or not row.get("id") is String or row.id.is_empty() or seen.has(row.id):
			errors.append("Missing/duplicate item id")
			continue
		seen[row.id] = true
		for key in ["name", "description"]:
			if not row.get(key) is String or str(row[key]).strip_edges().is_empty():
				errors.append("Empty item " + key)
		if row.get("category") not in ["valuable", "quest", "equipment"]:
			errors.append("Invalid item category")
		if row.get("category") == "equipment":
			var profile: Variant = row.get("combat_profile")
			if not profile is Dictionary or profile.get("id") != row.id or profile.get("slot") not in ["main_hand", "off_hand", "armor", "boots", "helmet"] or not profile.get("grants_actions") is Array:
				errors.append("Invalid equipment combat profile")
		var value: Variant = row.get("value")
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > 1000000000 or float(value) != floor(float(value)):
			errors.append("Invalid item value")
	return errors
