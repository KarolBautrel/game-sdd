extends RefCounted
class_name CombatTargetingPreview


static func unit_preview_text(preview: Dictionary) -> String:
	if preview.is_empty():
		return ""
	if str(preview.get("rejection", "")) != "":
		return ""

	var lines: Array[String] = []
	if preview.has("hit_chance"):
		var outcome := str(preview.get("hit_outcome", "")).to_upper()
		if outcome == "MISS":
			lines.append("%s%% HIT" % preview.get("hit_chance", "?"))
			lines.append("ROLL %s MISS" % preview.get("roll", "?"))
		else:
			lines.append("%s%% HIT" % preview.get("hit_chance", "?"))
	elif bool(preview.get("guaranteed_hit", false)):
		lines.append("100% HIT")

	if preview.has("damage"):
		lines.append("DMG %s" % preview.get("damage", "?"))

	if preview.has("ap_cost"):
		lines.append("COST %s AP" % preview.get("ap_cost", "?"))

	if lines.is_empty():
		lines.append("OK")
	return "\n".join(lines)
