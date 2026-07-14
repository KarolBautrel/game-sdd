from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
from typing import Any

RANGED_ATTACK_HIT_CHANCE = 70
MIN_HIT_CHANCE = 10
MAX_HIT_CHANCE = 95


@dataclass
class SimulationResult:
    state: dict[str, Any]
    result: str


class CombatSimulationError(ValueError):
    pass


def choose_enemy_command(state: dict[str, Any], command_id: str = "cmd_ai_001") -> dict[str, Any]:
    actor = _unit_by_id(state, state["turn_state"]["active_unit_id"])
    if actor is None or actor["team"] != "enemy":
        return _end_turn_command(state["turn_state"]["active_unit_id"], command_id)

    adjacent_player = _adjacent_living_enemy(state, actor, target_team="player")
    if adjacent_player is not None and actor["resources"]["ap"] >= 1 and "basic_attack" in actor["available_actions"]:
        return {
            "id": command_id,
            "type": "perform_action",
            "actor_id": actor["id"],
            "action_id": "basic_attack",
            "target": {
                "type": "unit",
                "unit_id": adjacent_player["id"],
            },
        }

    nearest_player = _nearest_living_enemy(state, actor, target_team="player")
    move_target = _best_step_toward(state, actor, nearest_player) if nearest_player is not None else None
    if move_target is not None and actor["resources"]["ap"] >= 1 and "move" in actor["available_actions"]:
        return {
            "id": command_id,
            "type": "perform_action",
            "actor_id": actor["id"],
            "action_id": "move",
            "target": {
                "type": "tile",
                "position": move_target,
            },
        }

    return _end_turn_command(actor["id"], command_id)


def simulate(encounter: dict[str, Any], commands: list[dict[str, Any]]) -> SimulationResult:
    state = deepcopy(encounter)
    state["event_log"] = []
    sequence = 1

    sequence = _emit(state, sequence, "combat_started", {})
    sequence = _emit(
        state,
        sequence,
        "turn_started",
        {"actor_id": state["turn_state"]["active_unit_id"], "round": state["turn_state"]["round"]},
    )

    for command in commands:
        sequence = _resolve_command(state, command, sequence)

    return SimulationResult(state=state, result=_combat_result(state))


def _resolve_command(state: dict[str, Any], command: dict[str, Any], sequence: int) -> int:
    if _combat_result(state) != "in_progress":
        return _reject(state, sequence, command, "combat_already_ended")

    if command["type"] != "perform_action":
        return _reject(state, sequence, command, "unsupported_command_type")

    if command["action_id"] == "basic_attack":
        return _resolve_attack(state, command, sequence, action_id="basic_attack", max_range=1, uses_hit_chance=False)
    if command["action_id"] == "ranged_attack":
        return _resolve_attack(state, command, sequence, action_id="ranged_attack", max_range=3, uses_hit_chance=True)
    if command["action_id"] == "move":
        return _resolve_move(state, command, sequence)
    if command["action_id"] == "defend":
        return _resolve_defend(state, command, sequence)
    if command["action_id"] == "end_turn":
        return _resolve_end_turn(state, command, sequence)

    return _reject(state, sequence, command, "unsupported_action")


def _resolve_attack(
    state: dict[str, Any],
    command: dict[str, Any],
    sequence: int,
    action_id: str,
    max_range: int,
    uses_hit_chance: bool,
) -> int:
    actor = _unit_by_id(state, command["actor_id"])
    target = _unit_by_id(state, command["target"].get("unit_id", ""))

    rejection = _attack_rejection(state, actor, target, action_id, max_range)
    if rejection is not None:
        return _reject(state, sequence, command, rejection)

    actor["resources"]["ap"] -= 1

    sequence = _emit(
        state,
        sequence,
        "action_performed",
        {
            "command_id": command["id"],
            "actor_id": actor["id"],
            "action_id": command["action_id"],
            "target_unit_id": target["id"],
            "ap_spent": 1,
        },
    )

    if uses_hit_chance:
        roll = _deterministic_roll(state, command)
        base_hit_chance = RANGED_ATTACK_HIT_CHANCE
        accuracy_modifier = _stat(actor, "accuracy")
        evasion_modifier = _stat(target, "evasion")
        hit_chance = _clamp(base_hit_chance + accuracy_modifier - evasion_modifier, MIN_HIT_CHANCE, MAX_HIT_CHANCE)
        outcome = "hit" if roll <= hit_chance else "miss"
        sequence = _emit(
            state,
            sequence,
            "hit_roll_resolved",
            {
                "command_id": command["id"],
                "actor_id": actor["id"],
                "target_unit_id": target["id"],
                "roll": roll,
                "base_hit_chance": base_hit_chance,
                "accuracy_modifier": accuracy_modifier,
                "evasion_modifier": evasion_modifier,
                "hit_chance": hit_chance,
                "outcome": outcome,
            },
        )
        if outcome == "miss":
            return sequence

    damage = max(1, actor["stats"]["strength"] - target["stats"]["defense"])
    old_hp = target["resources"]["hp"]
    target["resources"]["hp"] = max(0, old_hp - damage)
    sequence = _emit(
        state,
        sequence,
        "damage_applied",
        {
            "command_id": command["id"],
            "actor_id": actor["id"],
            "target_unit_id": target["id"],
            "damage": damage,
            "hp_before": old_hp,
            "hp_after": target["resources"]["hp"],
        },
    )

    if target["resources"]["hp"] == 0:
        sequence = _emit(
            state,
            sequence,
            "unit_defeated",
            {
                "command_id": command["id"],
                "actor_id": actor["id"],
                "target_unit_id": target["id"],
            },
        )

    if _combat_result(state) != "in_progress":
        sequence = _emit(
            state,
            sequence,
            "combat_ended",
            {
                "command_id": command["id"],
                "actor_id": actor["id"],
                "result": _combat_result(state),
            },
        )

    return sequence


def _resolve_move(state: dict[str, Any], command: dict[str, Any], sequence: int) -> int:
    actor = _unit_by_id(state, command["actor_id"])
    destination = command["target"].get("position", {})

    rejection = _move_rejection(state, actor, destination)
    if rejection is not None:
        return _reject(state, sequence, command, rejection)

    old_position = dict(actor["position"])
    actor["resources"]["ap"] -= 1
    actor["position"] = dict(destination)

    sequence = _emit(
        state,
        sequence,
        "action_performed",
        {
            "command_id": command["id"],
            "actor_id": actor["id"],
            "action_id": command["action_id"],
            "ap_spent": 1,
        },
    )
    return _emit(
        state,
        sequence,
        "unit_moved",
        {
            "command_id": command["id"],
            "actor_id": actor["id"],
            "from": old_position,
            "to": dict(destination),
        },
    )


def _resolve_defend(state: dict[str, Any], command: dict[str, Any], sequence: int) -> int:
    actor = _unit_by_id(state, command["actor_id"])
    rejection = _action_rejection(state, actor, "defend", required_ap=1)
    if rejection is not None:
        return _reject(state, sequence, command, rejection)

    actor["resources"]["ap"] -= 1
    status = {
        "id": "defending",
        "duration_rule": "until_next_turn_start",
        "source_unit_id": actor["id"],
    }
    actor["statuses"].append(status)

    sequence = _emit(
        state,
        sequence,
        "action_performed",
        {
            "command_id": command["id"],
            "actor_id": actor["id"],
            "action_id": command["action_id"],
            "ap_spent": 1,
        },
    )
    return _emit(
        state,
        sequence,
        "status_applied",
        {
            "command_id": command["id"],
            "actor_id": actor["id"],
            "target_unit_id": actor["id"],
            "status": status,
        },
    )


def _resolve_end_turn(state: dict[str, Any], command: dict[str, Any], sequence: int) -> int:
    actor = _unit_by_id(state, command["actor_id"])
    rejection = _action_rejection(state, actor, "end_turn", required_ap=0)
    if rejection is not None:
        return _reject(state, sequence, command, rejection)

    previous_unit_id = actor["id"]
    next_unit_id = _next_living_unit_id(state, previous_unit_id)
    if next_unit_id is None:
        return _reject(state, sequence, command, "no_next_living_unit")

    if _turn_order_wraps(state, previous_unit_id, next_unit_id):
        state["turn_state"]["round"] += 1

    state["turn_state"]["active_unit_id"] = next_unit_id
    next_unit = _unit_by_id(state, next_unit_id)
    next_unit["resources"]["ap"] = next_unit["stats"]["max_ap"]

    sequence = _emit(
        state,
        sequence,
        "action_performed",
        {
            "command_id": command["id"],
            "actor_id": previous_unit_id,
            "action_id": command["action_id"],
            "ap_spent": 0,
        },
    )
    sequence = _emit(
        state,
        sequence,
        "turn_ended",
        {
            "command_id": command["id"],
            "actor_id": previous_unit_id,
        },
    )
    return _emit(
        state,
        sequence,
        "turn_started",
        {
            "command_id": command["id"],
            "actor_id": next_unit_id,
            "round": state["turn_state"]["round"],
        },
    )


def _attack_rejection(
    state: dict[str, Any],
    actor: dict[str, Any] | None,
    target: dict[str, Any] | None,
    action_id: str,
    max_range: int,
) -> str | None:
    if actor is None:
        return "missing_actor"
    if target is None:
        return "missing_target"
    if state["turn_state"]["active_unit_id"] != actor["id"]:
        return "actor_is_not_active_unit"
    if actor["resources"]["hp"] <= 0:
        return "actor_defeated"
    if target["resources"]["hp"] <= 0:
        return "target_defeated"
    if actor["team"] == target["team"]:
        return "target_is_not_enemy"
    if actor["resources"]["ap"] < 1:
        return "not_enough_ap"
    if _chebyshev(actor["position"], target["position"]) > max_range:
        return "target_out_of_range"
    if action_id not in actor["available_actions"]:
        return "action_not_available"
    return None


def _action_rejection(
    state: dict[str, Any],
    actor: dict[str, Any] | None,
    action_id: str,
    required_ap: int,
) -> str | None:
    if actor is None:
        return "missing_actor"
    if state["turn_state"]["active_unit_id"] != actor["id"]:
        return "actor_is_not_active_unit"
    if actor["resources"]["hp"] <= 0:
        return "actor_defeated"
    if actor["resources"]["ap"] < required_ap:
        return "not_enough_ap"
    if action_id not in actor["available_actions"]:
        return "action_not_available"
    return None


def _move_rejection(
    state: dict[str, Any],
    actor: dict[str, Any] | None,
    destination: dict[str, int],
) -> str | None:
    if actor is None:
        return "missing_actor"
    if state["turn_state"]["active_unit_id"] != actor["id"]:
        return "actor_is_not_active_unit"
    if actor["resources"]["hp"] <= 0:
        return "actor_defeated"
    if actor["resources"]["ap"] < 1:
        return "not_enough_ap"
    if "move" not in actor["available_actions"]:
        return "action_not_available"
    if not {"x", "y"}.issubset(destination):
        return "missing_destination"
    if not _inside_grid(state, destination):
        return "destination_out_of_bounds"
    if not _is_walkable_tile(state, destination):
        return "destination_not_walkable"
    if _living_unit_at(state, destination) is not None:
        return "destination_occupied"
    if _chebyshev(actor["position"], destination) != 1:
        return "destination_not_adjacent"
    return None


def _reject(state: dict[str, Any], sequence: int, command: dict[str, Any], reason: str) -> int:
    return _emit(
        state,
        sequence,
        "command_rejected",
        {
            "command_id": command.get("id", "missing"),
            "actor_id": command.get("actor_id", "missing"),
            "reason": reason,
        },
    )


def _emit(state: dict[str, Any], sequence: int, event_type: str, payload: dict[str, Any]) -> int:
    event = {
        "type": event_type,
        "sequence": sequence,
        "combat_id": state["id"],
    }
    event.update(payload)
    state["event_log"].append(event)
    return sequence + 1


def _deterministic_roll(state: dict[str, Any], command: dict[str, Any]) -> int:
    command_hash = sum(ord(character) for character in command["id"])
    return ((state["seed"] + command_hash * 17) % 100) + 1


def _stat(unit: dict[str, Any], stat_name: str) -> int:
    return int(unit["stats"].get(stat_name, 0))


def _clamp(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(maximum, value))


def _unit_by_id(state: dict[str, Any], unit_id: str) -> dict[str, Any] | None:
    for unit in state["units"]:
        if unit["id"] == unit_id:
            return unit
    return None


def _manhattan(first: dict[str, int], second: dict[str, int]) -> int:
    return abs(first["x"] - second["x"]) + abs(first["y"] - second["y"])


def _chebyshev(first: dict[str, int], second: dict[str, int]) -> int:
    return max(abs(first["x"] - second["x"]), abs(first["y"] - second["y"]))


def _inside_grid(state: dict[str, Any], position: dict[str, int]) -> bool:
    return 0 <= position["x"] < state["grid"]["width"] and 0 <= position["y"] < state["grid"]["height"]


def _tile_type(state: dict[str, Any], position: dict[str, int]) -> str | None:
    for tile in state["grid"]["tiles"]:
        if tile["x"] == position["x"] and tile["y"] == position["y"]:
            return tile["type"]
    return None


def _is_walkable_tile(state: dict[str, Any], position: dict[str, int]) -> bool:
    return _tile_type(state, position) in {"floor", "highground"}


def _living_unit_at(state: dict[str, Any], position: dict[str, int]) -> dict[str, Any] | None:
    for unit in state["units"]:
        if unit["resources"]["hp"] > 0 and unit["position"] == position:
            return unit
    return None


def _next_living_unit_id(state: dict[str, Any], current_unit_id: str) -> str | None:
    turn_order = state["turn_state"]["turn_order"]
    current_index = turn_order.index(current_unit_id)
    for offset in range(1, len(turn_order) + 1):
        candidate_id = turn_order[(current_index + offset) % len(turn_order)]
        candidate = _unit_by_id(state, candidate_id)
        if candidate is not None and candidate["resources"]["hp"] > 0:
            return candidate_id
    return None


def _turn_order_wraps(state: dict[str, Any], current_unit_id: str, next_unit_id: str) -> bool:
    turn_order = state["turn_state"]["turn_order"]
    return turn_order.index(next_unit_id) <= turn_order.index(current_unit_id)


def _adjacent_living_enemy(state: dict[str, Any], actor: dict[str, Any], target_team: str) -> dict[str, Any] | None:
    candidates = [
        unit
        for unit in state["units"]
        if unit["team"] == target_team
        and unit["resources"]["hp"] > 0
        and _chebyshev(actor["position"], unit["position"]) == 1
    ]
    return sorted(candidates, key=lambda unit: unit["id"])[0] if candidates else None


def _nearest_living_enemy(state: dict[str, Any], actor: dict[str, Any], target_team: str) -> dict[str, Any] | None:
    candidates = [
        unit
        for unit in state["units"]
        if unit["team"] == target_team and unit["resources"]["hp"] > 0
    ]
    return sorted(candidates, key=lambda unit: (_manhattan(actor["position"], unit["position"]), unit["id"]))[0] if candidates else None


def _best_step_toward(
    state: dict[str, Any],
    actor: dict[str, Any],
    target: dict[str, Any],
) -> dict[str, int] | None:
    current_distance = _manhattan(actor["position"], target["position"])
    candidates = [
        {"x": actor["position"]["x"] - 1, "y": actor["position"]["y"]},
        {"x": actor["position"]["x"] + 1, "y": actor["position"]["y"]},
        {"x": actor["position"]["x"], "y": actor["position"]["y"] - 1},
        {"x": actor["position"]["x"], "y": actor["position"]["y"] + 1},
        {"x": actor["position"]["x"] - 1, "y": actor["position"]["y"] - 1},
        {"x": actor["position"]["x"] - 1, "y": actor["position"]["y"] + 1},
        {"x": actor["position"]["x"] + 1, "y": actor["position"]["y"] - 1},
        {"x": actor["position"]["x"] + 1, "y": actor["position"]["y"] + 1},
    ]
    legal_candidates = [
        position
        for position in candidates
        if _move_rejection(state, actor, position) is None
        and _manhattan(position, target["position"]) < current_distance
    ]
    return sorted(legal_candidates, key=lambda position: (_manhattan(position, target["position"]), position["y"], position["x"]))[0] if legal_candidates else None


def _end_turn_command(actor_id: str, command_id: str) -> dict[str, Any]:
    return {
        "id": command_id,
        "type": "perform_action",
        "actor_id": actor_id,
        "action_id": "end_turn",
        "target": {"type": "none"},
    }


def _combat_result(state: dict[str, Any]) -> str:
    player_alive = any(unit["team"] == "player" and unit["resources"]["hp"] > 0 for unit in state["units"])
    enemy_alive = any(unit["team"] == "enemy" and unit["resources"]["hp"] > 0 for unit in state["units"])

    if player_alive and enemy_alive:
        return "in_progress"
    if player_alive:
        return "victory"
    return "defeat"
