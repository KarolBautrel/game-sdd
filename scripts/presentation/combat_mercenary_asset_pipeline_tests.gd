extends SceneTree

const CombatUnitArt := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const CombatDebugScript := preload("res://scripts/presentation/combat_debug.gd")


func _init() -> void:
	var failures: Array[String] = []
	_assert_file("res://assets/combat/characters/heroes/mercenaries/processed/manifest.json", failures)
	_assert_file("res://assets/combat/characters/npc/processed/manifest.json", failures)
	_assert_file("res://assets/combat/characters/villains/bandits/processed/manifest.json", failures)
	_assert_file("res://assets/combat/characters/processed_character_sheets_manifest.json", failures)
	_assert_file("res://assets/combat/characters/heroes/mercenaries/processed/warrior/pose/warrior_right_pose_000.png", failures)
	_assert_file("res://assets/combat/characters/heroes/mercenaries/processed/warrior/pose/warrior_left_pose_000.png", failures)
	_assert_file("res://assets/combat/characters/npc/processed/guardian/pose/guardian_right_pose_000.png", failures)
	_assert_file("res://assets/combat/characters/villains/bandits/processed/bandit_archer/combat/bandit_archer_right_combat_000.png", failures)
	_assert_file("res://assets/combat/characters/villains/bandits/processed/bandit_brute/combat/bandit_brute_right_combat_000.png", failures)
	_assert_file("res://assets/combat/characters/villains/bandits/processed/bandit_carnage/combat/bandit_carnage_right_combat_000.png", failures)
	_assert_file("res://assets/combat/characters/villains/bandits/processed/bandit_marauder/combat/bandit_marauder_right_combat_000.png", failures)
	_assert_equal(CombatDebugScript.TILE_WIDTH, 140, "combat tile width", failures)
	_assert_equal(CombatDebugScript.TILE_HEIGHT, 104, "combat tile height", failures)
	_assert_equal(CombatDebugScript.ACTION_BUTTON_SIZE, Vector2(132, 118), "combat action button size", failures)
	_assert_equal(CombatDebugScript.ACTION_BUTTON_ICON_MAX_WIDTH, 66, "combat action icon max width", failures)

	var art := CombatUnitArt.new()
	var player_path := art.texture_path({"id": "unit_player_001", "team": "player"}, "east", "pose")
	_assert_contains(player_path, "heroes/mercenaries/processed/warrior/pose/warrior_right_pose_000.png", failures)
	var player_left_path := art.texture_path({"id": "unit_player_001", "team": "player"}, "west", "pose")
	_assert_contains(player_left_path, "heroes/mercenaries/processed/warrior/pose/warrior_left_pose_000.png", failures)
	var player_walk_path := art.texture_path({"id": "unit_player_001", "team": "player"}, "east", "walk:1")
	_assert_contains(player_walk_path, "heroes/mercenaries/processed/warrior/walk/warrior_right_walk_001.png", failures)
	var archer_path := art.texture_path({"id": "unit_player_002", "team": "player"}, "east", "pose")
	_assert_contains(archer_path, "heroes/mercenaries/processed/archer_1/pose/archer_1_right_pose_000.png", failures)
	_assert_equal(art.processed_sheet_frame_count("warrior", "walk"), 5, "warrior walk frame count", failures)
	var melee_enemy_path := art.texture_path({"id": "unit_enemy_001", "team": "enemy"}, "west", "combat")
	_assert_contains(melee_enemy_path, "villains/bandits/processed/axe_bandit/combat/axe_bandit_left_combat_000.png", failures)
	var ranged_enemy_path := art.texture_path({"id": "unit_enemy_002", "team": "enemy"}, "east", "combat")
	_assert_contains(ranged_enemy_path, "villains/bandits/processed/bandit_archer/combat/bandit_archer_right_combat_000.png", failures)
	var shuffled_archer_path := art.texture_path({"id": "unit_enemy_001", "team": "enemy", "archetype_id": "raider_archer"}, "east", "combat")
	_assert_contains(shuffled_archer_path, "villains/bandits/processed/bandit_archer/combat/bandit_archer_right_combat_000.png", failures)
	var shuffled_melee_path := art.texture_path({"id": "unit_enemy_002", "team": "enemy", "archetype_id": "raider_swordsman"}, "west", "combat")
	_assert_contains(shuffled_melee_path, "villains/bandits/processed/axe_bandit/combat/axe_bandit_left_combat_000.png", failures)
	var shieldman_path := art.texture_path({"id": "unit_enemy_003", "team": "enemy", "archetype_id": "raider_shieldman"}, "east", "combat")
	_assert_contains(shieldman_path, "villains/bandits/processed/bandit_brute/combat/bandit_brute_right_combat_000.png", failures)
	var brute_path := art.texture_path({"id": "brute", "team": "enemy", "visual": {"faction": "villains", "character": "bandit_brute"}}, "west", "combat")
	_assert_contains(brute_path, "villains/bandits/processed/bandit_brute/combat/bandit_brute_left_combat_000.png", failures)
	var carnage_path := art.texture_path({"id": "carnage", "team": "enemy", "visual": {"faction": "villains", "character": "bandit_carnage"}}, "east", "walk:5")
	_assert_contains(carnage_path, "villains/bandits/processed/bandit_carnage/walk/bandit_carnage_right_walk_005.png", failures)
	var marauder_path := art.texture_path({"id": "marauder", "team": "enemy", "visual": {"faction": "villains", "character": "bandit_marauder"}}, "west", "combat:8")
	_assert_contains(marauder_path, "villains/bandits/processed/bandit_marauder/combat/bandit_marauder_left_combat_003.png", failures)
	_assert_equal(art.processed_sheet_frame_count("bandit_marauder", "combat"), 5, "bandit marauder combat frame count", failures)
	_assert_approx(art.processed_sheet_visual_scale("warrior"), 1.0, 0.01, "warrior visual scale", failures)
	_assert_greater_than(art.processed_sheet_visual_scale("axe_bandit"), 1.0, "shorter axe bandit visual scale", failures)
	_assert_less_than(art.processed_sheet_visual_scale("bandit_brute"), 1.0, "larger bandit brute visual scale", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("combat_mercenary_asset_pipeline_tests: OK")
	quit(0)


func _assert_file(path: String, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing expected combat asset pipeline file: %s" % path)


func _assert_contains(actual: String, expected_fragment: String, failures: Array[String]) -> void:
	if not actual.contains(expected_fragment):
		failures.append("Expected path containing `%s`, got `%s`" % [expected_fragment, actual])


func _assert_equal(actual: Variant, expected: Variant, label: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("Expected %s to be `%s`, got `%s`" % [label, expected, actual])


func _assert_approx(actual: float, expected: float, tolerance: float, label: String, failures: Array[String]) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("Expected %s to be near `%s`, got `%s`" % [label, expected, actual])


func _assert_greater_than(actual: float, minimum: float, label: String, failures: Array[String]) -> void:
	if actual <= minimum:
		failures.append("Expected %s to be greater than `%s`, got `%s`" % [label, minimum, actual])


func _assert_less_than(actual: float, maximum: float, label: String, failures: Array[String]) -> void:
	if actual >= maximum:
		failures.append("Expected %s to be less than `%s`, got `%s`" % [label, maximum, actual])
