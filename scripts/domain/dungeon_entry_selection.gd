extends RefCounted
class_name DungeonEntrySelection

const DungeonStateModel := preload("res://scripts/domain/dungeon_state_model.gd")

const DUNGEON_PATH := "res://resources/data/dungeons/dungeon_old_mine.json"
const SOURCE_AUTHORED := "authored"
const SOURCE_GENERATED := "generated"
const DEFAULT_GENERATED_DUNGEON_DIFFICULTY := 2


static func default_payload() -> Dictionary:
	return authored_payload()


static func authored_payload() -> Dictionary:
	return {
		"source": SOURCE_AUTHORED,
		"dungeon_path": DUNGEON_PATH,
		"generated_seed": 0,
		"generated_difficulty": DEFAULT_GENERATED_DUNGEON_DIFFICULTY,
	}


static func generated_payload(seed: int, difficulty: int = DEFAULT_GENERATED_DUNGEON_DIFFICULTY) -> Dictionary:
	return {
		"source": SOURCE_GENERATED,
		"dungeon_path": DUNGEON_PATH,
		"generated_seed": maxi(1, seed),
		"generated_difficulty": clampi(difficulty, 1, 3),
	}


static func normalize_payload(payload: Dictionary) -> Dictionary:
	var source := str(payload.get("source", SOURCE_AUTHORED))
	if source != SOURCE_GENERATED:
		source = SOURCE_AUTHORED
	var generated_seed := int(payload.get("generated_seed", payload.get("seed", 0)))
	if source == SOURCE_GENERATED:
		generated_seed = maxi(1, generated_seed)
	else:
		generated_seed = 0
	return {
		"source": source,
		"dungeon_path": str(payload.get("dungeon_path", DUNGEON_PATH)),
		"generated_seed": generated_seed,
		"generated_difficulty": clampi(int(payload.get("generated_difficulty", payload.get("difficulty", DEFAULT_GENERATED_DUNGEON_DIFFICULTY))), 1, 3),
	}


static func payload_for_dungeon(dungeon: Dictionary) -> Dictionary:
	if source_for_dungeon(dungeon) == SOURCE_GENERATED:
		return generated_payload(
			int(dungeon.get("hazard_seed", 1)),
			_generated_difficulty_for_name(str(dungeon.get("display_name", "")))
		)
	return authored_payload()


static func dungeon_for_payload(payload: Dictionary) -> Dictionary:
	var normalized := normalize_payload(payload)
	if str(normalized.get("source", "")) == SOURCE_GENERATED:
		return DungeonStateModel.procedural_dungeon_draft({
			"seed": int(normalized.get("generated_seed", 1)),
			"difficulty": int(normalized.get("generated_difficulty", DEFAULT_GENERATED_DUNGEON_DIFFICULTY)),
		})
	return _load_json(str(normalized.get("dungeon_path", DUNGEON_PATH)))


static func source_for_dungeon(dungeon: Dictionary) -> String:
	var dungeon_id := str(dungeon.get("id", ""))
	if dungeon_id.begins_with("generated_"):
		return SOURCE_GENERATED
	return SOURCE_AUTHORED


static func display_name(payload: Dictionary) -> String:
	var normalized := normalize_payload(payload)
	if str(normalized.get("source", "")) == SOURCE_GENERATED:
		return "Generated D%s S%s" % [
			int(normalized.get("generated_difficulty", DEFAULT_GENERATED_DUNGEON_DIFFICULTY)),
			int(normalized.get("generated_seed", 1)),
		]
	return "Old Mine"


static func _generated_difficulty_for_name(display_name: String) -> int:
	for token: String in display_name.split(" ", false):
		if token.length() == 2 and token.begins_with("D") and token.substr(1, 1).is_valid_int():
			return clampi(int(token.substr(1, 1)), 1, 3)
	return DEFAULT_GENERATED_DUNGEON_DIFFICULTY


static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open dungeon data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Dungeon data is not an object: %s" % path)
		return {}
	return parsed
