extends RefCounted
class_name CombatActionModel

const PRIMARY_ACTION_IDS := ["move", "basic_attack", "ranged_attack", "aimed_shot", "power_strike", "deep_cut", "guard_break", "shield_wall", "defend", "end_turn"]
const DEBUG_ACTION_IDS := ["enemy_ai", "enemy_turn"]


static func visible_primary_action_ids(state: Dictionary) -> Array[String]:
	var visible: Array[String] = []
	var active := unit_by_id(state, state.get("turn_state", {}).get("active_unit_id", ""))
	if active.is_empty() or combat_result(state) != "in_progress":
		return visible
	for action_id: String in PRIMARY_ACTION_IDS:
		if action_granted_to_unit(state, active, action_id):
			visible.append(action_id)
	return visible


static func visible_debug_action_ids(state: Dictionary) -> Array[String]:
	if combat_result(state) != "in_progress":
		return []
	var visible: Array[String] = ["enemy_turn"]
	var active := unit_by_id(state, state.get("turn_state", {}).get("active_unit_id", ""))
	if not active.is_empty() and active.get("team", "") == "enemy":
		visible.push_front("enemy_ai")
	return visible


static func action_can_be_shown_now(state: Dictionary, unit: Dictionary, action_id: String) -> bool:
	# Availability is independent of membership in the stable displayed tray.
	return action_unavailability_reason(state, unit, action_id).is_empty()


static func action_unavailability_reason(state: Dictionary, unit: Dictionary, action_id: String) -> String:
	if unit.is_empty() or combat_result(state) != "in_progress":
		return "Battle finished or no active unit."
	if not action_granted_to_unit(state, unit, action_id):
		return "Not available with this equipment."
	if action_id == "end_turn":
		return ""
	if action_id == "move":
		var resource := "mp" if unit.resources.has("mp") else "ap"
		return "Need 1 %s (have 0)." % resource.to_upper() if int(unit.resources.get(resource, 0)) < 1 else ""
	for status: Dictionary in unit.get("statuses", []):
		if status.get("id", "") == "skill_cooldown" and status.get("action_id", "") == action_id and int(status.get("remaining_turns", 0)) > 0:
			var turns := int(status.remaining_turns)
			return "Cooldown: %s turn%s." % [turns, "" if turns == 1 else "s"]
	var cost := action_ap_cost(state, unit, action_id, 2 if action_id in ["power_strike", "aimed_shot"] else 1)
	var ap := int(unit.resources.get("ap", 0))
	return "Need %s AP (have %s)." % [cost, ap] if ap < cost else ""


static func action_granted_to_unit(state: Dictionary, unit: Dictionary, action_id: String) -> bool:
	if unit.get("available_actions", []).has(action_id):
		return true
	if unit.get("learned_actions", []).has(action_id):
		return true
	for item: Dictionary in loadout_items_for_unit(state, unit):
		if item.get("grants_actions", []).has(action_id):
			return true
	return false


static func action_ap_cost(state: Dictionary, unit: Dictionary, action_id: String, fallback: int) -> int:
	var profile := action_profile_for_unit(state, unit, action_id)
	return int(profile.get("ap_cost", fallback))


static func action_profile_for_unit(state: Dictionary, unit: Dictionary, action_id: String) -> Dictionary:
	for item: Dictionary in loadout_items_for_unit(state, unit):
		if not item.get("grants_actions", []).has(action_id):
			continue
		var action_profiles: Dictionary = item.get("action_profiles", {})
		if action_profiles.has(action_id):
			return action_profiles[action_id]
	var action_profiles: Dictionary = state.get("action_profiles", {})
	if action_profiles.has(action_id):
		return action_profiles[action_id]
	return {}


static func loadout_items_for_unit(state: Dictionary, unit: Dictionary) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var item_profiles: Dictionary = state.get("item_profiles", {})
	for item_id: Variant in unit.get("loadout", {}).values():
		if item_id == null:
			continue
		if item_profiles.has(item_id):
			items.append(item_profiles[item_id])
	return items


static func skill_on_cooldown(unit: Dictionary, action_id: String) -> bool:
	for status: Dictionary in unit.get("statuses", []):
		if status.get("id", "") == "skill_cooldown" and status.get("action_id", "") == action_id and int(status.get("remaining_turns", 0)) > 0:
			return true
	return false


static func unit_by_id(state: Dictionary, unit_id: String) -> Dictionary:
	for unit: Dictionary in state.get("units", []):
		if unit["id"] == unit_id:
			return unit
	return {}


static func combat_result(state: Dictionary) -> String:
	var player_alive := false
	var enemy_alive := false
	for unit: Dictionary in state.get("units", []):
		if unit["team"] == "player" and unit["resources"]["hp"] > 0:
			player_alive = true
		if unit["team"] == "enemy" and unit["resources"]["hp"] > 0:
			enemy_alive = true
	if player_alive and enemy_alive:
		return "in_progress"
	if player_alive:
		return "victory"
	return "defeat"
