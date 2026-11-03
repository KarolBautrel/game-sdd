extends RefCounted
class_name CombatText

const PartyRoster := preload("res://scripts/domain/party_roster.gd")

const ACTION_LABELS := {
	"move": "Move",
	"basic_attack": "Melee attack",
	"ranged_attack": "Ranged attack",
	"aimed_shot": "Aimed shot",
	"power_strike": "Power strike",
	"deep_cut": "Deep cut",
	"guard_break": "Guard break",
	"shield_wall": "Shield wall",
	"defend": "Defend",
	"end_turn": "End turn",
	"enemy_ai": "Enemy AI once",
	"enemy_turn": "Next turn step",
	"reset": "Reset encounter",
	"full_combat_showcase": "Full combat showcase",
	"load_los_test": "Load LoS test",
	"load_cover_test": "Load Cover test",
	"load_ranged_ai_test": "Load Ranged AI test",
	"load_pathfinding_test": "Load Pathfinding test",
	"load_low_chance_ai_test": "Load Low Chance AI test",
	"load_multi_enemy_test": "Load Multi Enemy test",
	"load_bottleneck_test": "Load Bottleneck test",
	"load_mixed_roles_test": "Load Mixed Roles test",
	"load_target_selection_test": "Load Target Selection test",
	"load_intercept_test": "Load Intercept test",
	"load_weapon_melee_test": "Load Weapon Melee test",
	"load_weapon_ranged_test": "Load Weapon Ranged test",
	"load_weapon_ap_cost_test": "Load Weapon AP Cost blocked test",
	"load_power_strike_test": "Load Power Strike test",
	"load_weapon_ap_cost_success_test": "Load Weapon AP Cost success test",
	"load_enemy_power_strike_test": "Load Enemy Power Strike test",
	"load_enemy_power_strike_cooldown_test": "Load Enemy Power Strike cooldown test",
	"load_skill_cooldown_expires_test": "Load Skill Cooldown expires test",
}


static func action_label(action_id: String) -> String:
	return ACTION_LABELS.get(action_id, action_id)


static func event_timeline_line(event: Dictionary, state: Dictionary) -> String:
	match event["type"]:
		"action_performed":
			return "%s uses %s" % [unit_display_name(state, event.get("actor_id", "")), action_label(event.get("action_id", ""))]
		"unit_moved":
			return "%s moves %s -> %s, MP %s" % [unit_display_name(state, event.get("actor_id", "")), position_label(event.get("from", {})), position_label(event.get("to", {})), event.get("mp_spent", 0)]
		"damage_applied":
			return "%s hits %s for %s damage (HP %s -> %s)" % [unit_display_name(state, event.get("actor_id", "")), unit_display_name(state, event.get("target_unit_id", "")), event.get("damage", "?"), event.get("hp_before", "?"), event.get("hp_after", "?")]
		"hit_roll_resolved":
			return "%s rolls %s vs %s%%: %s" % [unit_display_name(state, event.get("actor_id", "")), event.get("roll", "?"), event.get("hit_chance", "?"), event.get("outcome", "?")]
		"status_applied":
			return "%s gains %s" % [unit_display_name(state, event.get("target_unit_id", "")), status_label(event.get("status", {}))]
		"status_expired":
			return "%s loses %s" % [unit_display_name(state, event.get("target_unit_id", "")), status_label(event.get("status", {}))]
		"turn_ended":
			return "%s ends turn" % unit_display_name(state, event.get("actor_id", ""))
		"turn_started":
			return "%s starts turn, round %s" % [unit_display_name(state, event.get("actor_id", "")), event.get("round", "?")]
		"command_rejected":
			return "%s rejected: %s" % [unit_display_name(state, event.get("actor_id", "")), rejection_label(event.get("reason", "unknown"))]
		"combat_ended":
			return "Combat ended: %s" % event.get("result", "?")
		_:
			return "%s %s" % [event["type"], event_summary(event)]


static func event_summary(event: Dictionary) -> String:
	if event["type"] == "command_rejected":
		return "(%s)" % event.get("reason", "")
	if event["type"] == "damage_applied":
		return "(%s damage to %s, reduction %s)" % [event.get("damage", "?"), event.get("target_unit_id", "?"), event.get("damage_reduction", 0)]
	if event["type"] == "status_applied":
		var status: Dictionary = event.get("status", {})
		return "(%s on %s, turns %s)" % [status.get("id", "?"), event.get("target_unit_id", "?"), status.get("remaining_turns", "?")]
	if event["type"] == "status_expired":
		var expired_status: Dictionary = event.get("status", {})
		return "(%s on %s)" % [expired_status.get("id", "?"), event.get("target_unit_id", "?")]
	if event["type"] == "hit_roll_resolved":
		return "(%s: roll %s vs %s%%, base %s + acc %s - eva %s + terrain %s + cover %s)" % [
			event.get("outcome", "?"),
			event.get("roll", "?"),
			event.get("hit_chance", "?"),
			event.get("base_hit_chance", "?"),
			event.get("accuracy_modifier", "?"),
			event.get("evasion_modifier", "?"),
			event.get("terrain_modifier", "?"),
			event.get("cover_modifier", "?"),
		]
	if event["type"] == "shot_intercept_resolved":
		return "(%s: %s -> %s via %s, roll %s vs %s%%)" % [
			event.get("outcome", "?"),
			event.get("original_target_unit_id", "?"),
			event.get("final_target_unit_id", "?"),
			event.get("blocker_unit_id", "?"),
			event.get("roll", "?"),
			event.get("intercept_chance", "?"),
		]
	if event["type"] == "unit_moved":
		return "(%s -> %s, MP %s)" % [event.get("from", {}), event.get("to", {}), event.get("mp_spent", 0)]
	if event.has("action_id"):
		return "(%s)" % event["action_id"]
	return ""


static func event_marker(event: Dictionary) -> String:
	match event["type"]:
		"command_rejected":
			return "!"
		"damage_applied", "unit_defeated", "combat_ended":
			return "*"
		"status_applied", "status_expired":
			return "#"
		"hit_roll_resolved":
			return "%"
		"shot_intercept_resolved":
			return "~"
		"unit_moved":
			return ">"
		"turn_started", "turn_ended":
			return "-"
		_:
			return "."


static func feedback_from_events(events: Array) -> String:
	for event: Dictionary in events:
		if event["type"] == "command_rejected":
			return "Rejected: %s" % event.get("reason", "unknown")
	for event: Dictionary in events:
		if event["type"] == "combat_ended":
			return "Combat ended: %s" % event.get("result", "unknown")
	for event: Dictionary in events:
		if event["type"] == "hit_roll_resolved" and event.get("outcome", "") == "miss":
			return "Miss: roll %s vs %s%%" % [event.get("roll", "?"), event.get("hit_chance", "?")]
	for event: Dictionary in events:
		if event["type"] == "damage_applied":
			return "Damage: %s to %s" % [event.get("damage", "?"), event.get("target_unit_id", "?")]
	for event: Dictionary in events:
		if event["type"] == "unit_moved":
			return "Moved to %s" % event.get("to", {})
	for event: Dictionary in events:
		if event["type"] == "status_applied":
			return "Status applied: %s" % event.get("status", {}).get("id", "unknown")
	return "Command accepted."


static func unit_display_name(state: Dictionary, unit_id: String) -> String:
	if unit_id == "":
		return "Unknown"
	if str(state.get("id", "")) == "drawn_roster_skirmish":
		var review_names := {
			"unit_knight_pilot": "Knight", "unit_player_001": "Bran", "unit_player_002": "Torin",
			"unit_rogue_pilot": "Rogue", "unit_enemy_axe_1": "Axe Raider I",
			"unit_enemy_axe_2": "Axe Raider II", "unit_enemy_spear_1": "Spearman I",
			"unit_enemy_spear_2": "Spearman II",
		}
		if review_names.has(unit_id):
			return review_names[unit_id]
	var hero_name := PartyRoster.display_name_for_combat_unit(unit_id)
	if hero_name != "":
		return hero_name
	for unit: Dictionary in state.get("units", []):
		if unit["id"] == unit_id:
			if unit["team"] == "player":
				return "Hero"
			if str(unit.get("visual", {}).get("character", "")) == "ash_raider":
				return "Ash-road Raider"
			return "Enemy %s" % unit_id.trim_prefix("unit_enemy_")
	return unit_id


static func position_label(position: Dictionary) -> String:
	if position.is_empty():
		return "(?,?)"
	return "(%s,%s)" % [position.get("x", "?"), position.get("y", "?")]


static func status_label(status: Dictionary) -> String:
	if status.is_empty():
		return "status"
	if status.get("id", "") == "skill_cooldown":
		return "%s cooldown" % action_label(status.get("action_id", "skill"))
	var status_id := str(status.get("id", "status")).replace("_", " ")
	if status.has("damage_reduction"):
		return "%s (%s DR)" % [status_id, status.get("damage_reduction", "?")]
	if status.has("defense_modifier"):
		return "%s (%s DEF)" % [status_id, status.get("defense_modifier", "?")]
	return status_id


static func rejection_label(reason: String) -> String:
	match reason:
		"not_enough_ap":
			return "not enough AP"
		"not_enough_mp":
			return "not enough MP"
		"target_out_of_range":
			return "target out of range"
		"target_not_visible":
			return "line of sight is blocked"
		"destination_occupied":
			return "destination occupied"
		"destination_not_walkable":
			return "destination blocked"
		"destination_unreachable":
			return "destination unreachable"
		"action_not_available":
			return "action not available"
		"missing_weapon_profile":
			return "missing weapon profile"
		"skill_on_cooldown":
			return "skill on cooldown"
		"combat_already_ended":
			return "combat already ended"
		_:
			return reason.replace("_", " ")
