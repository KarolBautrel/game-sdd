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
