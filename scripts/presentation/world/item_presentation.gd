extends RefCounted
## Authored metadata only; never forecasts combat outcomes.
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")

static func icon_for(item: Dictionary) -> Texture2D:
	var id := str(item.get("id",""))
	var path := UI.ART+"items/"+id+".png"
	if not ResourceLoader.exists(path): path = UI.ART+"items/legacy_unknown.png"
	return UI.Assets.texture(path)

static func fields(item: Dictionary) -> Dictionary:
	var profile: Dictionary = item.get("combat_profile",{})
	var result: Dictionary = {}
	var attack: Dictionary = profile.get("action_profiles",{}).get("basic_attack",profile.get("action_profiles",{}).get("ranged_attack",{}))
	if not attack.is_empty():
		result["Attack bonus"] = int(attack.get("damage_bonus",0))
		result["Range"] = int(attack.get("range",1))
	if profile.get("slot") == "armor": result["Armor reduction"] = int(profile.get("armor_reduction",0))
	return result

static func comparison(item: Dictionary, current: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var before := fields(current)
	for key: String in fields(item):
		var after := int(fields(item)[key])
		result.append({"label":key,"before":int(before.get(key,0)),"after":after,"delta":after-int(before.get(key,0))})
	return result
