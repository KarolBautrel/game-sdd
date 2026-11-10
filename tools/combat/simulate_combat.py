from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]

RANGED_ATTACK_HIT_CHANCE = 70
MIN_HIT_CHANCE = 10
MAX_HIT_CHANCE = 95
HIGHGROUND_RANGED_HIT_MODIFIER = 10
COVER_LOW_RANGED_HIT_MODIFIER = -20
HIGHGROUND_RANGED_RANGE_BONUS = 1
AI_RANGED_MIN_HIT_CHANCE = 60
MIN_INTERCEPT_CHANCE = 20
MAX_INTERCEPT_CHANCE = 80
AI_POWER_STRIKE_CHANCE = 35
POWER_STRIKE_COOLDOWN_TURNS = 2
DEFAULT_AIMED_SHOT_COOLDOWN_TURNS = 2
DEFAULT_SHIELD_WALL_COOLDOWN_TURNS = 2


@dataclass
class SimulationResult:
    state: dict[str, Any]
    result: str
    result_payload: dict[str, Any]


class CombatSimulationError(ValueError):
    pass


def choose_enemy_command(state: dict[str, Any], command_id: str = "cmd_ai_001") -> dict[str, Any]:
    state = _state_with_archetypes(state)
    actor = _unit_by_id(state, state["turn_state"]["active_unit_id"])
    if actor is None or actor["team"] != "enemy":
        return _end_turn_command(state["turn_state"]["active_unit_id"], command_id)
    if actor["resources"]["ap"] <= 0:
        return _end_turn_command(actor["id"], command_id)

    adjacent_player = _adjacent_living_enemy(state, actor, target_team="player")
    if adjacent_player is not None and _enemy_should_use_power_strike(state, actor, adjacent_player):
        return {
            "id": command_id,
            "type": "perform_action",
            "actor_id": actor["id"],
            "action_id": "power_strike",
            "target": {
                "type": "unit",
                "unit_id": adjacent_player["id"],
            },
        }

    if adjacent_player is not None and actor["resources"]["ap"] >= 1 and _action_available(state, actor, "basic_attack"):
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

    ranged_player = _ranged_living_enemy(state, actor, target_team="player")
    if ranged_player is not None:
        return {
            "id": command_id,
            "type": "perform_action",
            "actor_id": actor["id"],
            "action_id": "ranged_attack",
            "target": {
                "type": "unit",
                "unit_id": ranged_player["id"],
            },
        }

    nearest_player = _nearest_living_enemy(state, actor, target_team="player")
    move_target = _best_move_toward(state, actor, nearest_player) if nearest_player is not None else None
    if move_target is not None and _can_pay_move(actor) and _action_available(state, actor, "move"):
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
    _apply_map_reference(state)
    _apply_enemy_archetypes(state)
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

    return SimulationResult(state=state, result=_combat_result(state), result_payload=_combat_result_payload(state))


def _resolve_command(state: dict[str, Any], command: dict[str, Any], sequence: int) -> int:
    if _combat_result(state) != "in_progress":
        return _reject(state, sequence, command, "combat_already_ended")

    if command["type"] != "perform_action":
        return _reject(state, sequence, command, "unsupported_command_type")

    if command["action_id"] == "basic_attack":
        return _resolve_attack(state, command, sequence, action_id="basic_attack", max_range=1, uses_hit_chance=False)
    if command["action_id"] == "ranged_attack":
        return _resolve_attack(state, command, sequence, action_id="ranged_attack", max_range=3, uses_hit_chance=True)
    if command["action_id"] == "aimed_shot":
        return _resolve_attack(state, command, sequence, action_id="aimed_shot", max_range=4, uses_hit_chance=True, damage_bonus=1, ap_cost=2)
    if command["action_id"] == "power_strike":
        return _resolve_attack(state, command, sequence, action_id="power_strike", max_range=1, uses_hit_chance=False, damage_bonus=2, ap_cost=2)
    if command["action_id"] == "deep_cut":
        return _resolve_attack(state, command, sequence, action_id="deep_cut", max_range=1, uses_hit_chance=False, damage_bonus=0, ap_cost=1)
    if command["action_id"] == "guard_break":
        return _resolve_attack(state, command, sequence, action_id="guard_break", max_range=1, uses_hit_chance=False, damage_bonus=0, ap_cost=1)
    if command["action_id"] == "shield_wall":
        return _resolve_self_status_action(state, command, sequence, action_id="shield_wall", ap_cost=1)
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
    damage_bonus: int = 0,
    ap_cost: int = 1,
) -> int:
    actor = _unit_by_id(state, command["actor_id"])
    target = _unit_by_id(state, command["target"].get("unit_id", ""))
    action_profile = _profile_for_action(state, actor, action_id)

    rejection = _attack_rejection(state, actor, target, action_id, max_range, ap_cost)
    if rejection is not None:
        return _reject(state, sequence, command, rejection)

    attack_range = _effective_attack_range(state, actor, action_id, _attack_range(action_profile, max_range))
    attack_ap_cost = _attack_ap_cost(action_profile, ap_cost)
    attack_damage_bonus = _attack_damage_bonus(action_profile, damage_bonus)

    rejection = _range_rejection(state, actor, target, action_id, attack_range)
    if rejection is not None:
        return _reject(state, sequence, command, rejection)

    actor["resources"]["ap"] -= attack_ap_cost

    sequence = _emit(
        state,
        sequence,
        "action_performed",
        {
            "command_id": command["id"],
            "actor_id": actor["id"],
            "action_id": command["action_id"],
            "target_unit_id": target["id"],
            "ap_spent": attack_ap_cost,
            "profile_id": action_profile.get("id", ""),
            "weapon_id": action_profile.get("id", ""),
        },
    )
    cooldown_turns = _cooldown_turns(action_profile, _default_cooldown_turns(action_id))
    if cooldown_turns > 0:
        cooldown_status = _skill_cooldown_status(actor["id"], action_id, cooldown_turns)
        actor["statuses"].append(cooldown_status)
        sequence = _emit(
            state,
            sequence,
            "status_applied",
            {
                "command_id": command["id"],
                "actor_id": actor["id"],
                "target_unit_id": actor["id"],
                "status": cooldown_status,
            },
        )

    original_target = target
    if uses_hit_chance:
        intercept = _ranged_intercept_candidate(state, actor, target)
        if intercept is not None:
            intercept_roll = _deterministic_intercept_roll(state, command)
            blocker = intercept["unit"]
            outcome = "intercepted" if intercept_roll <= intercept["chance"] else "clear"
            sequence = _emit(
                state,
                sequence,
                "shot_intercept_resolved",
                {
                    "command_id": command["id"],
                    "actor_id": actor["id"],
                    "original_target_unit_id": original_target["id"],
                    "blocker_unit_id": blocker["id"],
                    "final_target_unit_id": blocker["id"] if outcome == "intercepted" else original_target["id"],
                    "blocker_progress": intercept["progress"],
                    "intercept_chance": intercept["chance"],
                    "roll": intercept_roll,
                    "outcome": outcome,
                },
            )
            if outcome == "intercepted":
                target = blocker

    if uses_hit_chance:
        roll = _deterministic_roll(state, command)
        base_hit_chance = _base_hit_chance(action_profile)
        accuracy_modifier = _stat(actor, "accuracy")
        evasion_modifier = _stat(target, "evasion")
        terrain_modifier = _terrain_hit_modifier(state, actor, action_id)
        cover_modifier = _cover_hit_modifier(state, target, action_id)
        hit_chance = _clamp(
            base_hit_chance + accuracy_modifier - evasion_modifier + terrain_modifier + cover_modifier,
            MIN_HIT_CHANCE,
            MAX_HIT_CHANCE,
        )
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
                "terrain_modifier": terrain_modifier,
                "cover_modifier": cover_modifier,
                "hit_chance": hit_chance,
                "outcome": outcome,
            },
        )
        if outcome == "miss":
            return sequence

    raw_damage = max(1, actor["stats"]["strength"] + attack_damage_bonus - _effective_defense(target))
    reduction = _damage_reduction(state, target)
    armor_id = _armor_id(target)
    damage = max(1, raw_damage - reduction)
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
            "raw_damage": raw_damage,
            "damage_reduction": reduction,
            "damage_bonus": attack_damage_bonus,
            "armor_id": armor_id,
            "profile_id": action_profile.get("id", ""),
            "weapon_id": action_profile.get("id", ""),
            "hp_before": old_hp,
            "hp_after": target["resources"]["hp"],
        },
    )

    if target["resources"]["hp"] > 0 and _profile_applies_status(action_profile):
        status = _profile_status(actor["id"], action_profile, fallback_status_id=action_profile.get("status_id", action_id))
        target["statuses"].append(status)
        sequence = _emit(
            state,
            sequence,
            "status_applied",
            {
                "command_id": command["id"],
                "actor_id": actor["id"],
                "target_unit_id": target["id"],
                "status": status,
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
        result_payload = _combat_result_payload(state)
        sequence = _emit(
            state,
            sequence,
            "combat_ended",
            {
                "command_id": command["id"],
                "actor_id": actor["id"],
                "result": result_payload["result"],
                "result_payload": result_payload,
            },
        )

    return sequence


def _resolve_self_status_action(
    state: dict[str, Any],
    command: dict[str, Any],
    sequence: int,
    action_id: str,
    ap_cost: int,
) -> int:
    actor = _unit_by_id(state, command["actor_id"])
    action_profile = _profile_for_action(state, actor, action_id)
    required_ap = _attack_ap_cost(action_profile, ap_cost)
    rejection = _self_action_rejection(state, actor, action_id, required_ap)
    if rejection is not None:
        return _reject(state, sequence, command, rejection)

    actor["resources"]["ap"] -= required_ap
    sequence = _emit(
        state,
        sequence,
        "action_performed",
        {
            "command_id": command["id"],
            "actor_id": actor["id"],
            "action_id": action_id,
            "ap_spent": required_ap,
            "profile_id": action_profile.get("id", ""),
        },
    )

    status = _profile_status(actor["id"], action_profile, fallback_status_id=action_id)
    actor["statuses"].append(status)
    sequence = _emit(
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

    cooldown_turns = _cooldown_turns(action_profile, _default_cooldown_turns(action_id))
    if cooldown_turns > 0:
        cooldown_status = _skill_cooldown_status(actor["id"], action_id, cooldown_turns)
        actor["statuses"].append(cooldown_status)
        sequence = _emit(
            state,
            sequence,
            "status_applied",
            {
                "command_id": command["id"],
                "actor_id": actor["id"],
                "target_unit_id": actor["id"],
                "status": cooldown_status,
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
    movement_path = _movement_path(state, actor, destination)
    movement_cost = _movement_path_cost(state, movement_path)
    ap_spent = 0 if _movement_uses_mp(actor) else 1
    mp_spent = movement_cost if _movement_uses_mp(actor) else 0
    actor["resources"]["ap"] -= ap_spent
    if _movement_uses_mp(actor):
        actor["resources"]["mp"] -= mp_spent
    actor["position"] = dict(destination)

    sequence = _emit(
        state,
        sequence,
        "action_performed",
        {
            "command_id": command["id"],
            "actor_id": actor["id"],
            "action_id": command["action_id"],
            "ap_spent": ap_spent,
            "mp_spent": mp_spent,
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
            "path": [dict(position) for position in movement_path],
            "mp_spent": mp_spent,
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
    if "mp" in next_unit["resources"]:
        next_unit["resources"]["mp"] = next_unit["stats"]["move_points"]
    turn_start_status_result = _tick_turn_start_statuses(next_unit)
    status_damage_events = turn_start_status_result["damage_events"]
    expired_statuses = turn_start_status_result["expired_statuses"]

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
    sequence = _emit(
        state,
        sequence,
        "turn_started",
        {
            "command_id": command["id"],
            "actor_id": next_unit_id,
            "round": state["turn_state"]["round"],
        },
    )
    for damage_event in status_damage_events:
        damage_event["command_id"] = command["id"]
        damage_event["actor_id"] = next_unit_id
        damage_event["target_unit_id"] = next_unit_id
        sequence = _emit(state, sequence, "damage_applied", damage_event)
        if damage_event.get("hp_after") == 0:
            sequence = _emit(
                state,
                sequence,
                "unit_defeated",
                {
                    "command_id": command["id"],
                    "actor_id": next_unit_id,
                    "target_unit_id": next_unit_id,
                },
            )
            if _combat_result(state) != "in_progress":
                result_payload = _combat_result_payload(state)
                sequence = _emit(
                    state,
                    sequence,
                    "combat_ended",
                    {
                        "command_id": command["id"],
                        "actor_id": next_unit_id,
                        "result": result_payload["result"],
                        "result_payload": result_payload,
                    },
                )
    for status in expired_statuses:
        sequence = _emit(
            state,
            sequence,
            "status_expired",
            {
                "command_id": command["id"],
                "actor_id": next_unit_id,
                "target_unit_id": next_unit_id,
                "status": status,
            },
        )
    return sequence


def _attack_rejection(
    state: dict[str, Any],
    actor: dict[str, Any] | None,
    target: dict[str, Any] | None,
    action_id: str,
    max_range: int,
    required_ap: int = 1,
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
    loadout_rejection = _loadout_rejection(state, actor)
    if loadout_rejection is not None:
        return loadout_rejection
    if not _action_available(state, actor, action_id):
        return "action_not_available"
    weapon_profile = _weapon_profile_for_action(state, actor, action_id)
    if weapon_profile is None:
        return "missing_weapon_profile"
    if actor["resources"]["ap"] < _attack_ap_cost(weapon_profile, required_ap):
        return "not_enough_ap"
    if _skill_on_cooldown(actor, action_id):
        return "skill_on_cooldown"
    range_rejection = _range_rejection(state, actor, target, action_id, _effective_attack_range(state, actor, action_id, _attack_range(weapon_profile, max_range)))
    if range_rejection is not None:
        return range_rejection
    return None


def _self_action_rejection(
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
    loadout_rejection = _loadout_rejection(state, actor)
    if loadout_rejection is not None:
        return loadout_rejection
    if _skill_on_cooldown(actor, action_id):
        return "skill_on_cooldown"
    if not _action_available(state, actor, action_id):
        return "action_not_available"
    return None


def _range_rejection(
    state: dict[str, Any],
    actor: dict[str, Any],
    target: dict[str, Any],
    action_id: str,
    max_range: int,
) -> str | None:
    if _chebyshev(actor["position"], target["position"]) > max_range:
        return "target_out_of_range"
    if action_id in ("ranged_attack", "aimed_shot") and not _has_line_of_sight(state, actor["position"], target["position"]):
        return "target_not_visible"
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
    if not _action_available(state, actor, action_id):
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
    if _movement_uses_mp(actor):
        if actor["resources"]["mp"] < 1:
            return "not_enough_mp"
    elif actor["resources"]["ap"] < 1:
        return "not_enough_ap"
    if not _action_available(state, actor, "move"):
        return "action_not_available"
    if not {"x", "y"}.issubset(destination):
        return "missing_destination"
    if not _inside_grid(state, destination):
        return "destination_out_of_bounds"
    if not _is_walkable_tile(state, destination):
        return "destination_not_walkable"
    if _living_unit_at(state, destination) is not None:
        return "destination_occupied"
    if not _movement_uses_mp(actor) and _chebyshev(actor["position"], destination) != 1:
        return "destination_not_adjacent"
    movement_path = _movement_path(state, actor, destination)
    if not movement_path:
        return "destination_unreachable"
    if _movement_uses_mp(actor):
        if _movement_path_cost(state, movement_path) > actor["resources"]["mp"]:
            return "not_enough_mp"
    elif _is_diagonal_step(actor["position"], destination) and not _diagonal_step_allowed(state, actor["position"], destination):
        return "diagonal_corner_blocked"
    return None


def _movement_uses_mp(actor: dict[str, Any]) -> bool:
    return "mp" in actor.get("resources", {})


def _can_pay_move(actor: dict[str, Any]) -> bool:
    if _movement_uses_mp(actor):
        return actor["resources"]["mp"] >= 1
    return actor["resources"]["ap"] >= 1


def _movement_path_cost(state: dict[str, Any], path: list[dict[str, int]]) -> int:
    return sum(_terrain_movement_cost(state, position) for position in path)


def _movement_path(
    state: dict[str, Any],
    actor: dict[str, Any],
    destination: dict[str, int],
) -> list[dict[str, int]]:
    if not {"x", "y"}.issubset(destination):
        return []
    start = actor["position"]
    if start == destination:
        return []

    queue: list[tuple[dict[str, int], list[dict[str, int]], int]] = [(start, [], 0)]
    best_cost = {_position_key(start): 0}

    while queue:
        queue.sort(key=lambda item: (item[2], len(item[1]), _manhattan(item[0], destination), item[0]["y"], item[0]["x"]))
        current, path, cost = queue.pop(0)
        if current == destination and path:
            return path
        for neighbor in _movement_neighbors(state, actor, current):
            key = _position_key(neighbor)
            next_cost = cost + _terrain_movement_cost(state, neighbor)
            if key in best_cost and best_cost[key] <= next_cost:
                continue
            next_path = path + [neighbor]
            best_cost[key] = next_cost
            queue.append((neighbor, next_path, next_cost))

    return []


def _movement_neighbors(state: dict[str, Any], actor: dict[str, Any], position: dict[str, int]) -> list[dict[str, int]]:
    candidates = [
        {"x": position["x"] - 1, "y": position["y"]},
        {"x": position["x"] + 1, "y": position["y"]},
        {"x": position["x"], "y": position["y"] - 1},
        {"x": position["x"], "y": position["y"] + 1},
        {"x": position["x"] - 1, "y": position["y"] - 1},
        {"x": position["x"] - 1, "y": position["y"] + 1},
        {"x": position["x"] + 1, "y": position["y"] - 1},
        {"x": position["x"] + 1, "y": position["y"] + 1},
    ]
    return [
        candidate
        for candidate in candidates
        if _path_position_is_legal(state, actor, position, candidate)
    ]


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


def _deterministic_intercept_roll(state: dict[str, Any], command: dict[str, Any]) -> int:
    command_hash = sum(ord(character) for character in f'{command["id"]}_intercept')
    return ((state["seed"] + command_hash * 17) % 100) + 1


def _deterministic_ai_decision_roll(state: dict[str, Any], actor: dict[str, Any], action_id: str) -> int:
    roll_key = f'{actor["id"]}_{action_id}_{state["turn_state"]["round"]}'
    command_hash = sum(ord(character) for character in roll_key)
    return ((state["seed"] + command_hash * 13) % 100) + 1


def _stat(unit: dict[str, Any], stat_name: str) -> int:
    return int(unit["stats"].get(stat_name, 0))


def _profile_for_action(
    state: dict[str, Any],
    actor: dict[str, Any] | None,
    action_id: str,
) -> dict[str, Any] | None:
    if actor is None:
        return {}
    weapon_id = actor.get("equipped_weapon_id")
    profile: dict[str, Any] = {}
    if not weapon_id:
        profile = {}
    else:
        profiles = state.get("weapon_profiles", {})
        found_profile = profiles.get(weapon_id)
        if found_profile is None:
            return None
        if found_profile.get("action_id") == action_id:
            profile = found_profile
    if profile:
        return profile
    item_profile = _item_action_profile_for_action(state, actor, action_id)
    if item_profile is not None:
        return item_profile
    action_profile = state.get("action_profiles", {}).get(action_id)
    if action_profile is not None:
        return action_profile
    return {}


def _weapon_profile_for_action(
    state: dict[str, Any],
    actor: dict[str, Any] | None,
    action_id: str,
) -> dict[str, Any] | None:
    profile = _profile_for_action(state, actor, action_id)
    if profile is None:
        return None
    return profile


def _enemy_should_use_power_strike(state: dict[str, Any], actor: dict[str, Any], target: dict[str, Any]) -> bool:
    if not _action_available(state, actor, "power_strike"):
        return False
    profile = _profile_for_action(state, actor, "power_strike") or {}
    if _attack_rejection(state, actor, target, "power_strike", 1, _attack_ap_cost(profile, 2)) is not None:
        return False
    return _deterministic_ai_decision_roll(state, actor, "power_strike") <= AI_POWER_STRIKE_CHANCE


def _skill_on_cooldown(actor: dict[str, Any], action_id: str) -> bool:
    for status in actor["statuses"]:
        if status.get("id") == "skill_cooldown" and status.get("action_id") == action_id and status.get("remaining_turns", 0) > 0:
            return True
    return False


def _skill_cooldown_status(source_unit_id: str, action_id: str, remaining_turns: int) -> dict[str, Any]:
    return {
        "id": "skill_cooldown",
        "action_id": action_id,
        "remaining_turns": remaining_turns,
        "duration_rule": "own_turn_starts",
        "source_unit_id": source_unit_id,
    }


def _tick_turn_start_statuses(unit: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    kept_statuses: list[dict[str, Any]] = []
    expired_statuses: list[dict[str, Any]] = []
    damage_events: list[dict[str, Any]] = []
    for status in unit["statuses"]:
        next_status = deepcopy(status)
        tick_damage = int(next_status.get("tick_damage", 0))
        if tick_damage > 0 and unit["resources"]["hp"] > 0:
            old_hp = int(unit["resources"]["hp"])
            damage = min(tick_damage, old_hp)
            unit["resources"]["hp"] = max(0, old_hp - damage)
            damage_events.append(
                {
                    "damage": damage,
                    "raw_damage": tick_damage,
                    "damage_reduction": 0,
                    "damage_bonus": 0,
                    "armor_id": "",
                    "profile_id": "",
                    "weapon_id": "",
                    "hp_before": old_hp,
                    "hp_after": unit["resources"]["hp"],
                    "source_status_id": next_status.get("id", ""),
                }
            )
        if next_status.get("id") == "skill_cooldown":
            next_status["remaining_turns"] = max(0, int(next_status.get("remaining_turns", 0)) - 1)
            if next_status["remaining_turns"] == 0:
                expired_statuses.append(next_status)
                continue
        elif next_status.get("duration_rule") == "own_turn_starts":
            next_status["remaining_turns"] = max(0, int(next_status.get("remaining_turns", 0)) - 1)
            if next_status["remaining_turns"] == 0:
                expired_statuses.append(next_status)
                continue
        kept_statuses.append(next_status)
    unit["statuses"] = kept_statuses
    return {
        "damage_events": damage_events,
        "expired_statuses": expired_statuses,
    }


def _attack_range(weapon_profile: dict[str, Any], fallback: int) -> int:
    return int(weapon_profile.get("range", fallback))


def _effective_attack_range(state: dict[str, Any], actor: dict[str, Any], action_id: str, base_range: int) -> int:
    if action_id == "ranged_attack" and _tile_type(state, actor["position"]) == "highground":
        return base_range + HIGHGROUND_RANGED_RANGE_BONUS
    return base_range


def _action_available(state: dict[str, Any], actor: dict[str, Any], action_id: str) -> bool:
    if action_id in actor.get("available_actions", []):
        return True
    if action_id in actor.get("learned_actions", []):
        return True
    for item in _loadout_items(state, actor):
        if action_id in item.get("grants_actions", []):
            return True
    return False


def _item_action_profile_for_action(
    state: dict[str, Any],
    actor: dict[str, Any] | None,
    action_id: str,
) -> dict[str, Any] | None:
    if actor is None:
        return None
    for item in _loadout_items(state, actor):
        if action_id not in item.get("grants_actions", []):
            continue
        action_profiles = item.get("action_profiles", {})
        if action_id in action_profiles:
            return action_profiles[action_id]
    return None


def _state_with_archetypes(state: dict[str, Any]) -> dict[str, Any]:
    prepared = deepcopy(state)
    _apply_map_reference(prepared)
    _apply_enemy_archetypes(prepared)
    return prepared


def _apply_map_reference(state: dict[str, Any]) -> None:
    map_path = state.get("map_path")
    if not map_path:
        return
    map_data = _load_map_json(str(map_path))
    for key in ("background_path", "terrain_theme", "terrain_decorations"):
        if key not in state and key in map_data:
            state[key] = deepcopy(map_data[key])
    state["grid"] = {
        "width": map_data["width"],
        "height": map_data["height"],
        "tiles": deepcopy(map_data["tiles"]),
    }


def _load_map_json(map_path: str) -> dict[str, Any]:
    path = _resource_path(map_path)
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _resource_path(path: str) -> Path:
    if path.startswith("res://"):
        return ROOT / path.removeprefix("res://")
    return ROOT / path


def _apply_enemy_archetypes(state: dict[str, Any]) -> None:
    archetypes = state.get("enemy_archetypes", {})
    if not archetypes:
        return
    for unit in state["units"]:
        archetype_id = unit.get("archetype_id")
        if unit.get("team") != "enemy" or not archetype_id:
            continue
        archetype = archetypes.get(archetype_id)
        if archetype is None:
            continue
        unit["available_actions"] = list(dict.fromkeys(unit.get("available_actions", []) + archetype.get("available_actions", [])))
        unit["learned_actions"] = list(dict.fromkeys(unit.get("learned_actions", []) + archetype.get("learned_actions", [])))
        if "loadout" in archetype:
            loadout = dict(archetype["loadout"])
            loadout.update(unit.get("loadout", {}))
            unit["loadout"] = loadout
        if "visual" not in unit and "visual_pool" in archetype:
            visual = _archetype_visual_from_pool(archetype, unit)
            if visual:
                unit["visual"] = visual


def _archetype_visual_from_pool(archetype: dict[str, Any], unit: dict[str, Any]) -> dict[str, Any]:
    visual_pool = archetype.get("visual_pool", [])
    if not visual_pool:
        return {}
    stable_key = f"{unit.get('id', '')}:{unit.get('archetype_id', '')}"
    index = _stable_visual_pool_index(stable_key, len(visual_pool))
    visual = visual_pool[index]
    return dict(visual) if isinstance(visual, dict) else {}


def _stable_visual_pool_index(stable_key: str, pool_size: int) -> int:
    if pool_size <= 0:
        return 0
    return sum(ord(character) for character in stable_key) % pool_size


def _loadout_items(state: dict[str, Any], actor: dict[str, Any]) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    item_profiles = state.get("item_profiles", {})
    for item_id in actor.get("loadout", {}).values():
        if item_id is None:
            continue
        item = item_profiles.get(item_id)
        if item is not None:
            items.append(item)
    return items


def _loadout_rejection(state: dict[str, Any], actor: dict[str, Any]) -> str | None:
    loadout = actor.get("loadout", {})
    if not loadout:
        return None
    item_profiles = state.get("item_profiles", {})
    for slot, item_id in loadout.items():
        if item_id is None:
            continue
        item = item_profiles.get(item_id)
        if item is None:
            return "missing_item_profile"
        if item.get("slot") != slot:
            return "item_slot_mismatch"
    main_item_id = loadout.get("main_hand")
    off_item_id = loadout.get("off_hand")
    main_item = item_profiles.get(main_item_id) if main_item_id is not None else None
    if main_item is not None and main_item.get("two_handed", False) and off_item_id is not None:
        return "invalid_loadout_two_handed_with_off_hand"
    return None


def _attack_ap_cost(weapon_profile: dict[str, Any], fallback: int) -> int:
    return int(weapon_profile.get("ap_cost", fallback))


def _attack_damage_bonus(weapon_profile: dict[str, Any], fallback: int) -> int:
    return int(weapon_profile.get("damage_bonus", fallback))


def _base_hit_chance(weapon_profile: dict[str, Any]) -> int:
    return int(weapon_profile.get("base_hit_chance", RANGED_ATTACK_HIT_CHANCE))


def _cooldown_turns(action_profile: dict[str, Any], fallback: int) -> int:
    return int(action_profile.get("cooldown_turns", fallback))


def _default_cooldown_turns(action_id: str) -> int:
    if action_id == "power_strike":
        return POWER_STRIKE_COOLDOWN_TURNS
    if action_id == "aimed_shot":
        return DEFAULT_AIMED_SHOT_COOLDOWN_TURNS
    if action_id == "shield_wall":
        return DEFAULT_SHIELD_WALL_COOLDOWN_TURNS
    return 0


def _profile_status(source_unit_id: str, action_profile: dict[str, Any], fallback_status_id: str) -> dict[str, Any]:
    status = {
        "id": action_profile.get("status_id", fallback_status_id),
        "remaining_turns": int(action_profile.get("status_remaining_turns", 1)),
        "duration_rule": "own_turn_starts",
        "source_unit_id": source_unit_id,
    }
    if "damage_reduction" in action_profile:
        status["damage_reduction"] = int(action_profile["damage_reduction"])
    if "status_tick_damage" in action_profile:
        status["tick_damage"] = int(action_profile["status_tick_damage"])
    if "status_defense_modifier" in action_profile:
        status["defense_modifier"] = int(action_profile["status_defense_modifier"])
    return status


def _profile_applies_status(action_profile: dict[str, Any]) -> bool:
    return "status_id" in action_profile or "status_tick_damage" in action_profile or "status_defense_modifier" in action_profile


def _effective_defense(target: dict[str, Any]) -> int:
    defense = int(target["stats"].get("defense", 0))
    for status in target.get("statuses", []):
        defense += int(status.get("defense_modifier", 0))
    return max(0, defense)


def _damage_reduction(state: dict[str, Any], target: dict[str, Any]) -> int:
    reduction = 0
    for status in target["statuses"]:
        reduction += int(status.get("damage_reduction", 0))
    armor = _armor_item(state, target)
    if armor is not None:
        reduction += int(armor.get("armor_reduction", 0))
    return reduction


def _armor_item(state: dict[str, Any], target: dict[str, Any]) -> dict[str, Any] | None:
    armor_id = _armor_id(target)
    if armor_id is None:
        return None
    armor = state.get("item_profiles", {}).get(armor_id)
    if armor is None or armor.get("slot") != "armor":
        return None
    return armor


def _armor_id(target: dict[str, Any]) -> str | None:
    armor_id = target.get("loadout", {}).get("armor")
    if armor_id is None:
        return None
    return str(armor_id)


def _clamp(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(maximum, value))


def _terrain_hit_modifier(state: dict[str, Any], actor: dict[str, Any], action_id: str) -> int:
    if action_id == "ranged_attack" and _tile_type(state, actor["position"]) == "highground":
        return HIGHGROUND_RANGED_HIT_MODIFIER
    return 0


def _cover_hit_modifier(state: dict[str, Any], target: dict[str, Any], action_id: str) -> int:
    if action_id == "ranged_attack" and _tile_type(state, target["position"]) == "cover_low":
        return COVER_LOW_RANGED_HIT_MODIFIER
    return 0


def _has_line_of_sight(state: dict[str, Any], origin: dict[str, int], target: dict[str, int]) -> bool:
    for position in _line_between(origin, target):
        if _tile_type(state, position) == "blocked":
            return False
    return True


def _ranged_intercept_candidate(
    state: dict[str, Any],
    actor: dict[str, Any],
    target: dict[str, Any],
) -> dict[str, Any] | None:
    total_distance = _chebyshev(actor["position"], target["position"])
    if total_distance <= 1:
        return None

    candidates: list[dict[str, Any]] = []
    for position in _line_between(actor["position"], target["position"]):
        unit = _living_unit_at(state, position)
        if unit is None or unit["id"] in {actor["id"], target["id"]}:
            continue
        distance_from_actor = _chebyshev(actor["position"], unit["position"])
        progress = _clamp(round(distance_from_actor * 100 / total_distance), 1, 99)
        chance = _clamp(MIN_INTERCEPT_CHANCE + round(60 * progress / 100), MIN_INTERCEPT_CHANCE, MAX_INTERCEPT_CHANCE)
        candidates.append({"unit": unit, "progress": progress, "chance": chance})

    return sorted(candidates, key=lambda item: (-item["progress"], item["unit"]["id"]))[0] if candidates else None


def _line_between(origin: dict[str, int], target: dict[str, int]) -> list[dict[str, int]]:
    distance = _chebyshev(origin, target)
    if distance <= 1:
        return []

    positions: list[dict[str, int]] = []

    for step in range(1, distance):
        positions.append({
            "x": round(origin["x"] + (target["x"] - origin["x"]) * step / distance),
            "y": round(origin["y"] + (target["y"] - origin["y"]) * step / distance),
        })

    return positions


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
    return _tile_type(state, position) in {"floor", "highground", "cover_low"}


def _terrain_movement_cost(state: dict[str, Any], position: dict[str, int]) -> int:
    terrain_type = _tile_type(state, position)
    if terrain_type == "highground":
        return 2
    if terrain_type in {"floor", "cover_low"}:
        return 1
    return 999999


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


def _ranged_living_enemy(state: dict[str, Any], actor: dict[str, Any], target_team: str) -> dict[str, Any] | None:
    candidates = [
        unit
        for unit in state["units"]
        if unit["team"] == target_team
        and unit["resources"]["hp"] > 0
        and _attack_rejection(state, actor, unit, "ranged_attack", 3) is None
        and _ranged_hit_chance(state, actor, unit, "ranged_attack") >= AI_RANGED_MIN_HIT_CHANCE
    ]
    return sorted(candidates, key=lambda unit: (_chebyshev(actor["position"], unit["position"]), unit["id"]))[0] if candidates else None


def _best_move_toward(
    state: dict[str, Any],
    actor: dict[str, Any],
    target: dict[str, Any],
) -> dict[str, int] | None:
    if _movement_uses_mp(actor):
        multi_tile_target = _best_mp_move_toward(state, actor, target)
        if multi_tile_target is not None:
            return multi_tile_target

    path_step = _first_path_step_toward(state, actor, target)
    if path_step is not None and _move_rejection(state, actor, path_step) is None:
        return path_step

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


def _best_mp_move_toward(
    state: dict[str, Any],
    actor: dict[str, Any],
    target: dict[str, Any],
) -> dict[str, int] | None:
    max_cost = int(actor["resources"].get("mp", 0))
    if max_cost <= 0:
        return None

    start = actor["position"]
    queue: list[tuple[dict[str, int], list[dict[str, int]], int]] = [(start, [], 0)]
    best_cost = {_position_key(start): 0}
    candidates: list[tuple[dict[str, int], list[dict[str, int]], int]] = []

    while queue:
        queue.sort(key=lambda item: (item[2], len(item[1]), item[0]["y"], item[0]["x"]))
        current, path, cost = queue.pop(0)
        if path:
            candidates.append((current, path, cost))
        if cost >= max_cost:
            continue

        for neighbor in _path_neighbors(state, actor, current):
            next_cost = cost + _terrain_movement_cost(state, neighbor)
            if next_cost > max_cost:
                continue
            key = _position_key(neighbor)
            if key in best_cost and best_cost[key] <= next_cost:
                continue
            best_cost[key] = next_cost
            queue.append((neighbor, path + [neighbor], next_cost))

    candidates = [
        (position, path, cost)
        for position, path, cost in candidates
        if _move_rejection(state, actor, position) is None
    ]
    if not candidates:
        return None

    current_distance = _chebyshev(start, target["position"])
    closer_candidates = [
        (position, path, cost)
        for position, path, cost in candidates
        if _chebyshev(position, target["position"]) < current_distance
    ]
    if not closer_candidates:
        return None

    return sorted(
        closer_candidates,
        key=lambda item: (
            0 if _chebyshev(item[0], target["position"]) == 1 else 1,
            _chebyshev(item[0], target["position"]),
            _manhattan(item[0], target["position"]),
            item[2],
            len(item[1]),
            item[0]["y"],
            item[0]["x"],
        ),
    )[0][0]


def _first_path_step_toward(
    state: dict[str, Any],
    actor: dict[str, Any],
    target: dict[str, Any],
) -> dict[str, int] | None:
    start = actor["position"]
    queue: list[tuple[dict[str, int], list[dict[str, int]]]] = [(start, [])]
    visited = {_position_key(start)}

    while queue:
        current, path = queue.pop(0)
        if path and _chebyshev(current, target["position"]) == 1:
            return path[0]

        for neighbor in _path_neighbors(state, actor, current):
            key = _position_key(neighbor)
            if key in visited:
                continue
            visited.add(key)
            queue.append((neighbor, path + [neighbor]))

    return None


def _path_neighbors(state: dict[str, Any], actor: dict[str, Any], position: dict[str, int]) -> list[dict[str, int]]:
    candidates = [
        {"x": position["x"] - 1, "y": position["y"]},
        {"x": position["x"] + 1, "y": position["y"]},
        {"x": position["x"], "y": position["y"] - 1},
        {"x": position["x"], "y": position["y"] + 1},
        {"x": position["x"] - 1, "y": position["y"] - 1},
        {"x": position["x"] - 1, "y": position["y"] + 1},
        {"x": position["x"] + 1, "y": position["y"] - 1},
        {"x": position["x"] + 1, "y": position["y"] + 1},
    ]
    legal_candidates = [
        candidate
        for candidate in candidates
        if _path_position_is_legal(state, actor, position, candidate)
    ]
    return sorted(legal_candidates, key=lambda candidate: (candidate["y"], candidate["x"]))


def _path_position_is_legal(state: dict[str, Any], actor: dict[str, Any], origin: dict[str, int], position: dict[str, int]) -> bool:
    if not _inside_grid(state, position):
        return False
    if not _is_walkable_tile(state, position):
        return False
    if _is_diagonal_step(origin, position) and not _diagonal_step_allowed(state, origin, position):
        return False
    unit = _living_unit_at(state, position)
    return unit is None or unit["id"] == actor["id"]


def _ranged_hit_chance(state: dict[str, Any], actor: dict[str, Any], target: dict[str, Any], action_id: str) -> int:
    weapon_profile = _profile_for_action(state, actor, action_id) or {}
    return _clamp(
        _base_hit_chance(weapon_profile)
        + _stat(actor, "accuracy")
        - _stat(target, "evasion")
        + _terrain_hit_modifier(state, actor, action_id)
        + _cover_hit_modifier(state, target, action_id),
        MIN_HIT_CHANCE,
        MAX_HIT_CHANCE,
    )


def _is_diagonal_step(origin: dict[str, int], destination: dict[str, int]) -> bool:
    return abs(origin["x"] - destination["x"]) == 1 and abs(origin["y"] - destination["y"]) == 1


def _diagonal_step_allowed(state: dict[str, Any], origin: dict[str, int], destination: dict[str, int]) -> bool:
    side_a = {"x": destination["x"], "y": origin["y"]}
    side_b = {"x": origin["x"], "y": destination["y"]}
    return _is_walkable_tile(state, side_a) and _is_walkable_tile(state, side_b)


def _position_key(position: dict[str, int]) -> str:
    return f'{position["x"]},{position["y"]}'


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


def _combat_result_payload(state: dict[str, Any]) -> dict[str, Any]:
    result = _combat_result(state)
    payload = {
        "result": result,
        "combat_id": state["id"],
        "source_dungeon_id": state.get("source_dungeon_id", ""),
        "source_room_id": state.get("source_room_id", ""),
        "surviving_players": [],
        "defeated_player_ids": [],
        "defeated_enemy_ids": [],
        "remaining_enemies": [],
        "rewards": deepcopy(state.get("rewards", {"xp": 0, "gold": 0, "items": []})),
    }
    if result == "in_progress":
        return payload

    for unit in state["units"]:
        if unit["team"] == "player":
            if unit["resources"]["hp"] > 0:
                payload["surviving_players"].append(_unit_result_summary(unit))
            else:
                payload["defeated_player_ids"].append(unit["id"])
        elif unit["team"] == "enemy":
            if unit["resources"]["hp"] > 0:
                payload["remaining_enemies"].append(_unit_result_summary(unit))
            else:
                payload["defeated_enemy_ids"].append(unit["id"])
    return payload


def _unit_result_summary(unit: dict[str, Any]) -> dict[str, Any]:
    summary = {
        "id": unit["id"],
        "team": unit["team"],
        "hp": int(unit["resources"].get("hp", 0)),
        "max_hp": int(unit["stats"].get("max_hp", 0)),
        "statuses": deepcopy(unit.get("statuses", [])),
        "position": deepcopy(unit.get("position", {})),
    }
    if "ap" in unit.get("resources", {}):
        summary["ap"] = int(unit["resources"].get("ap", 0))
    if "mp" in unit.get("resources", {}):
        summary["mp"] = int(unit["resources"].get("mp", 0))
    return summary
