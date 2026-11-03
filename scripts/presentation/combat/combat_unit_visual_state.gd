extends RefCounted
class_name CombatUnitVisualState

const WALK := "walk"
const COMBAT := "combat"
const HIT := "hit"
const DEATH := "death"
const STATUS_REACTION := "status_reaction"


static func movement_actions_from_events(events: Array) -> Dictionary:
	var actions: Dictionary = {}
	for event: Dictionary in events:
		if event["type"] != "unit_moved":
			continue
		var actor_id := str(event.get("actor_id", ""))
		if actor_id != "":
			actions[actor_id] = WALK
	return actions


static func movement_step_facings(event: Dictionary) -> Array[Dictionary]:
	if event.get("type", "") != "unit_moved":
		return []
	var step_facings: Array[Dictionary] = []
	var current: Dictionary = event.get("from", {})
	var path: Array = event.get("path", [event.get("to", {})])
	for step: Dictionary in path:
		if not _has_position(current) or not _has_position(step):
			current = step
			continue
		var direction := direction_between(current, step)
		if direction != "":
			step_facings.append({
				"from": current.duplicate(true),
				"to": step.duplicate(true),
				"direction": direction,
			})
		current = step
	return step_facings


static func combat_actions_from_events(events: Array) -> Dictionary:
	var actions: Dictionary = {}
	for event: Dictionary in events:
		match event["type"]:
			"damage_applied":
				var actor_id := str(event.get("actor_id", ""))
				if actor_id != "" and not event.has("source_status_id"):
					actions[actor_id] = COMBAT
				var target_id := str(event.get("target_unit_id", ""))
				if target_id != "":
					actions[target_id] = DEATH if int(event.get("hp_after", 1)) <= 0 else HIT
			"hit_roll_resolved":
				var actor_id := str(event.get("actor_id", ""))
				if actor_id != "":
					actions[actor_id] = COMBAT
			"status_applied":
				var target_id := str(event.get("target_unit_id", ""))
				if target_id != "":
					actions[target_id] = STATUS_REACTION
	return actions


static func defeated_target_ids(events: Array) -> Array[String]:
	var target_ids: Array[String] = []
	for event: Dictionary in events:
		if event["type"] != "damage_applied":
			continue
		if int(event.get("hp_after", 1)) > 0:
			continue
		var target_id := str(event.get("target_unit_id", ""))
		if target_id != "" and not target_ids.has(target_id):
			target_ids.append(target_id)
	return target_ids


static func has_movement_state(events: Array) -> bool:
	return not movement_actions_from_events(events).is_empty()


static func has_combat_state(events: Array) -> bool:
	return not combat_actions_from_events(events).is_empty()


static func direction_between(from_position: Dictionary, to_position: Dictionary) -> String:
	if not _has_position(from_position) or not _has_position(to_position):
		return ""
	var dx := int(to_position["x"]) - int(from_position["x"])
	var dy := int(to_position["y"]) - int(from_position["y"])
	if dx == 0 and dy == 0:
		return ""
	if dy < 0 and dx == 0:
		return "north"
	if dy > 0 and dx == 0:
		return "south"
	if dx < 0 and dy == 0:
		return "west"
	if dx > 0 and dy == 0:
		return "east"
	if dx < 0 and dy < 0:
		return "north_west"
	if dx > 0 and dy < 0:
		return "north_east"
	if dx < 0 and dy > 0:
		return "south_west"
	if dx > 0 and dy > 0:
		return "south_east"
	return ""


static func _has_position(position: Dictionary) -> bool:
	return position.has("x") and position.has("y")
