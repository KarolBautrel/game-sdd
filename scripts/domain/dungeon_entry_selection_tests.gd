extends SceneTree

const DungeonEntrySelection := preload("res://scripts/domain/dungeon_entry_selection.gd")


func _init() -> void:
	var errors: Array[String] = []

	var authored_payload := DungeonEntrySelection.default_payload()
	var authored_dungeon := DungeonEntrySelection.dungeon_for_payload(authored_payload)
	_expect_equal(errors, "default source", authored_payload["source"], DungeonEntrySelection.SOURCE_AUTHORED)
	_expect_equal(errors, "authored dungeon id", authored_dungeon["id"], "dungeon_old_mine")
	_expect_equal(errors, "authored display", DungeonEntrySelection.display_name(authored_payload), "Old Mine")

	var generated_payload := DungeonEntrySelection.generated_payload(222, 3)
	var generated_dungeon := DungeonEntrySelection.dungeon_for_payload(generated_payload)
	var same_generated_dungeon := DungeonEntrySelection.dungeon_for_payload(generated_payload)
	_expect_equal(errors, "generated source", generated_payload["source"], DungeonEntrySelection.SOURCE_GENERATED)
	_expect_equal(errors, "generated seed", generated_payload["generated_seed"], 222)
	_expect_equal(errors, "generated difficulty", generated_payload["generated_difficulty"], 3)
	_expect_equal(errors, "generated profile", generated_payload["generated_profile"], "deep_mine")
	_expect_equal(errors, "generated dungeon id", generated_dungeon["id"], "generated_old_mine_draft")
	_expect_equal(errors, "generated dungeon hazard seed", int(generated_dungeon["hazard_seed"]), 222)
	_expect_equal(errors, "generated dungeon profile metadata", generated_dungeon["generated_profile"]["id"], "deep_mine")
	_expect_equal(errors, "same payload graph", _graph_signature(generated_dungeon), _graph_signature(same_generated_dungeon))
	_expect_true(errors, "generated display", DungeonEntrySelection.display_name(generated_payload).contains("Deep Mine D3 S222"))

	var normalized := DungeonEntrySelection.normalize_payload({"source": "bad", "generated_seed": 99, "generated_difficulty": 9})
	_expect_equal(errors, "invalid source falls back authored", normalized["source"], DungeonEntrySelection.SOURCE_AUTHORED)
	_expect_equal(errors, "authored clears generated seed", normalized["generated_seed"], 0)
	_expect_equal(errors, "difficulty clamps", normalized["generated_difficulty"], 3)
	_expect_equal(errors, "profile follows clamped difficulty", normalized["generated_profile"], "deep_mine")

	var round_trip_payload := DungeonEntrySelection.payload_for_dungeon(generated_dungeon)
	_expect_equal(errors, "round trip source", round_trip_payload["source"], DungeonEntrySelection.SOURCE_GENERATED)
	_expect_equal(errors, "round trip seed", round_trip_payload["generated_seed"], 222)
	_expect_equal(errors, "round trip difficulty", round_trip_payload["generated_difficulty"], 3)
	_expect_equal(errors, "round trip profile", round_trip_payload["generated_profile"], "deep_mine")

	if errors.is_empty():
		print("Dungeon entry selection validation passed.")
	else:
		for error: String in errors:
			push_error(error)
		quit(1)
		return
	quit(0)


func _graph_signature(dungeon: Dictionary) -> String:
	var parts: Array[String] = []
	for room: Dictionary in dungeon.get("rooms", []):
		var position: Dictionary = room.get("position", {})
		parts.append("%s:%s:%s:%s" % [room.get("id", ""), room.get("kind", ""), position.get("x", 0), position.get("y", 0)])
	for corridor: Dictionary in dungeon.get("corridors", []):
		parts.append("%s:%s:%s:%s" % [corridor.get("id", ""), corridor.get("from", ""), corridor.get("to", ""), corridor.get("danger", 0.0)])
	return "|".join(parts)


func _expect_equal(errors: Array[String], label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		errors.append("%s: expected %s, got %s" % [label, expected, actual])


func _expect_true(errors: Array[String], label: String, value: bool) -> void:
	if not value:
		errors.append("%s: expected true" % label)
