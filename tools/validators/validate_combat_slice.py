from __future__ import annotations

import json
from pathlib import Path

from tools.combat.simulate_combat import choose_enemy_command, simulate


ROOT = Path(__file__).resolve().parents[2]


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def validate_combat_slice_01() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_01_basic_attack.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_01_basic_attack_commands.json")

    result = simulate(encounter, commands)
    state = result.state

    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_01_basic_attack: expected player AP to be 0")
    if enemy["resources"]["hp"] != 4:
        errors.append("slice_01_basic_attack: expected enemy HP to be 4")
    if result.result != "in_progress":
        errors.append(f"slice_01_basic_attack: expected result in_progress, got {result.result}")

    required_prefix = ["combat_started", "turn_started", "action_performed", "damage_applied"]
    if event_types[:4] != required_prefix:
        errors.append(f"slice_01_basic_attack: expected event prefix {required_prefix}, got {event_types[:4]}")

    sequences = [event["sequence"] for event in state["event_log"]]
    if sequences != list(range(1, len(sequences) + 1)):
        errors.append(f"slice_01_basic_attack: event sequences are not stable: {sequences}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_01_basic_attack: replay event log differs")

    return errors


def validate_combat_slice_02() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_02_invalid_no_ap.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_02_invalid_no_ap_commands.json")

    initial_player = _unit_by_id(encounter, "unit_player_001")
    initial_enemy = _unit_by_id(encounter, "unit_enemy_001")

    result = simulate(encounter, commands)
    state = result.state

    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"] != initial_player["resources"]:
        errors.append("slice_02_invalid_no_ap: player resources mutated")
    if enemy["resources"] != initial_enemy["resources"]:
        errors.append("slice_02_invalid_no_ap: enemy resources mutated")
    if player["position"] != initial_player["position"]:
        errors.append("slice_02_invalid_no_ap: player position mutated")
    if enemy["position"] != initial_enemy["position"]:
        errors.append("slice_02_invalid_no_ap: enemy position mutated")
    if result.result != "in_progress":
        errors.append(f"slice_02_invalid_no_ap: expected result in_progress, got {result.result}")

    expected_events = ["combat_started", "turn_started", "command_rejected"]
    if event_types != expected_events:
        errors.append(f"slice_02_invalid_no_ap: expected events {expected_events}, got {event_types}")

    rejected_events = [event for event in state["event_log"] if event["type"] == "command_rejected"]
    if len(rejected_events) != 1:
        errors.append("slice_02_invalid_no_ap: expected exactly one command_rejected event")
    elif rejected_events[0].get("reason") != "not_enough_ap":
        errors.append(
            "slice_02_invalid_no_ap: expected rejection reason not_enough_ap, "
            f"got {rejected_events[0].get('reason')}"
        )

    forbidden = {"action_performed", "damage_applied", "unit_defeated", "combat_ended"}
    emitted_forbidden = sorted(forbidden.intersection(event_types))
    if emitted_forbidden:
        errors.append(f"slice_02_invalid_no_ap: emitted forbidden events {emitted_forbidden}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_02_invalid_no_ap: replay event log differs")

    return errors


def validate_combat_slice_03() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_03_move.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_03_move_commands.json")

    result = simulate(encounter, commands)
    state = result.state

    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_03_move: expected player AP to be 0")
    if player["position"] != {"x": 2, "y": 1}:
        errors.append(f"slice_03_move: expected player position {{'x': 2, 'y': 1}}, got {player['position']}")
    if enemy["resources"]["hp"] != 6:
        errors.append("slice_03_move: expected enemy HP to remain 6")
    if result.result != "in_progress":
        errors.append(f"slice_03_move: expected result in_progress, got {result.result}")

    expected_events = ["combat_started", "turn_started", "action_performed", "unit_moved"]
    if event_types != expected_events:
        errors.append(f"slice_03_move: expected events {expected_events}, got {event_types}")

    moved_events = [event for event in state["event_log"] if event["type"] == "unit_moved"]
    if len(moved_events) != 1:
        errors.append("slice_03_move: expected exactly one unit_moved event")
    else:
        moved = moved_events[0]
        if moved.get("from") != {"x": 1, "y": 1} or moved.get("to") != {"x": 2, "y": 1}:
            errors.append(f"slice_03_move: unexpected move payload {moved}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_03_move: replay event log differs")

    return errors


def validate_combat_slice_04() -> list[str]:
    return _validate_rejected_move(
        slice_id="slice_04_move_occupied",
        expected_reason="destination_occupied",
        expected_player_position={"x": 1, "y": 1},
        expected_enemy_position={"x": 2, "y": 1},
    )


def validate_combat_slice_05() -> list[str]:
    return _validate_rejected_move(
        slice_id="slice_05_move_blocked",
        expected_reason="destination_not_walkable",
        expected_player_position={"x": 1, "y": 1},
        expected_enemy_position={"x": 4, "y": 1},
    )


def validate_combat_slice_06() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_06_defend.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_06_defend_commands.json")

    result = simulate(encounter, commands)
    state = result.state

    player = _unit_by_id(state, "unit_player_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_06_defend: expected player AP to be 0")
    if [status["id"] for status in player["statuses"]] != ["defending"]:
        errors.append(f"slice_06_defend: expected defending status, got {player['statuses']}")
    if result.result != "in_progress":
        errors.append(f"slice_06_defend: expected result in_progress, got {result.result}")

    expected_events = ["combat_started", "turn_started", "action_performed", "status_applied"]
    if event_types != expected_events:
        errors.append(f"slice_06_defend: expected events {expected_events}, got {event_types}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_06_defend: replay event log differs")

    return errors


def validate_combat_slice_07() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_07_end_turn.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_07_end_turn_commands.json")

    result = simulate(encounter, commands)
    state = result.state

    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if state["turn_state"]["active_unit_id"] != "unit_enemy_001":
        errors.append(
            "slice_07_end_turn: expected active unit unit_enemy_001, "
            f"got {state['turn_state']['active_unit_id']}"
        )
    if enemy["resources"]["ap"] != enemy["stats"]["max_ap"]:
        errors.append("slice_07_end_turn: expected enemy AP to refresh to max_ap")
    if result.result != "in_progress":
        errors.append(f"slice_07_end_turn: expected result in_progress, got {result.result}")

    expected_events = ["combat_started", "turn_started", "action_performed", "turn_ended", "turn_started"]
    if event_types != expected_events:
        errors.append(f"slice_07_end_turn: expected events {expected_events}, got {event_types}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_07_end_turn: replay event log differs")

    return errors


def validate_combat_slice_08() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_08_enemy_ai_adjacent_attack.json")
    command = choose_enemy_command(encounter)

    if command["action_id"] != "basic_attack":
        errors.append(f"slice_08_enemy_ai_adjacent_attack: expected AI basic_attack, got {command['action_id']}")
    if command["actor_id"] != "unit_enemy_001":
        errors.append(f"slice_08_enemy_ai_adjacent_attack: expected actor unit_enemy_001, got {command['actor_id']}")
    if command["target"].get("unit_id") != "unit_player_001":
        errors.append(
            "slice_08_enemy_ai_adjacent_attack: expected target unit_player_001, "
            f"got {command['target'].get('unit_id')}"
        )

    result = simulate(encounter, [command])
    state = result.state

    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["hp"] != 8:
        errors.append("slice_08_enemy_ai_adjacent_attack: expected player HP to be 8")
    if enemy["resources"]["ap"] != 0:
        errors.append("slice_08_enemy_ai_adjacent_attack: expected enemy AP to be 0")
    if result.result != "in_progress":
        errors.append(f"slice_08_enemy_ai_adjacent_attack: expected result in_progress, got {result.result}")

    expected_events = ["combat_started", "turn_started", "action_performed", "damage_applied"]
    if event_types != expected_events:
        errors.append(f"slice_08_enemy_ai_adjacent_attack: expected events {expected_events}, got {event_types}")

    replay = simulate(encounter, [command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_08_enemy_ai_adjacent_attack: replay event log differs")

    return errors


def validate_combat_slice_09() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_09_enemy_ai_move_toward_player.json")
    command = choose_enemy_command(encounter)

    if command["action_id"] != "move":
        errors.append(f"slice_09_enemy_ai_move_toward_player: expected AI move, got {command['action_id']}")
    if command["actor_id"] != "unit_enemy_001":
        errors.append(f"slice_09_enemy_ai_move_toward_player: expected actor unit_enemy_001, got {command['actor_id']}")
    if command["target"].get("position") != {"x": 3, "y": 1}:
        errors.append(
            "slice_09_enemy_ai_move_toward_player: expected target position {'x': 3, 'y': 1}, "
            f"got {command['target'].get('position')}"
        )

    result = simulate(encounter, [command])
    state = result.state

    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if enemy["position"] != {"x": 3, "y": 1}:
        errors.append(f"slice_09_enemy_ai_move_toward_player: expected enemy position {{'x': 3, 'y': 1}}, got {enemy['position']}")
    if enemy["resources"]["ap"] != 0:
        errors.append("slice_09_enemy_ai_move_toward_player: expected enemy AP to be 0")
    if result.result != "in_progress":
        errors.append(f"slice_09_enemy_ai_move_toward_player: expected result in_progress, got {result.result}")

    expected_events = ["combat_started", "turn_started", "action_performed", "unit_moved"]
    if event_types != expected_events:
        errors.append(f"slice_09_enemy_ai_move_toward_player: expected events {expected_events}, got {event_types}")

    replay = simulate(encounter, [command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_09_enemy_ai_move_toward_player: replay event log differs")

    return errors


def validate_combat_slice_10() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_10_diagonal_move.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_10_diagonal_move_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["position"] != {"x": 2, "y": 2}:
        errors.append(f"slice_10_diagonal_move: expected player position {{'x': 2, 'y': 2}}, got {player['position']}")
    if player["resources"]["ap"] != 0:
        errors.append("slice_10_diagonal_move: expected player AP to be 0")
    if event_types != ["combat_started", "turn_started", "action_performed", "unit_moved"]:
        errors.append(f"slice_10_diagonal_move: unexpected events {event_types}")

    return errors


def validate_combat_slice_11() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_11_diagonal_attack.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_11_diagonal_attack_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_11_diagonal_attack: expected player AP to be 0")
    if enemy["resources"]["hp"] != 4:
        errors.append(f"slice_11_diagonal_attack: expected enemy HP 4, got {enemy['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "damage_applied"]:
        errors.append(f"slice_11_diagonal_attack: unexpected events {event_types}")

    return errors


def validate_combat_slice_12() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_12_enemy_ai_no_ap_end_turn.json")
    command = choose_enemy_command(encounter)

    if command["action_id"] != "end_turn":
        errors.append(f"slice_12_enemy_ai_no_ap_end_turn: expected AI end_turn, got {command['action_id']}")

    result = simulate(encounter, [command])
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if state["turn_state"]["active_unit_id"] != "unit_player_001":
        errors.append(
            "slice_12_enemy_ai_no_ap_end_turn: expected active unit unit_player_001, "
            f"got {state['turn_state']['active_unit_id']}"
        )
    if player["resources"]["ap"] != 1:
        errors.append("slice_12_enemy_ai_no_ap_end_turn: expected player AP to refresh to 1")
    if enemy["resources"]["ap"] != 0:
        errors.append("slice_12_enemy_ai_no_ap_end_turn: expected enemy AP to remain 0")
    if event_types != ["combat_started", "turn_started", "action_performed", "turn_ended", "turn_started"]:
        errors.append(f"slice_12_enemy_ai_no_ap_end_turn: unexpected events {event_types}")

    return errors


def validate_combat_slice_13() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_13_round_cycle_player_enemy_player.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_13_round_cycle_player_enemy_player_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if state["turn_state"]["active_unit_id"] != "unit_player_001":
        errors.append(
            "slice_13_round_cycle_player_enemy_player: expected active unit unit_player_001, "
            f"got {state['turn_state']['active_unit_id']}"
        )
    if state["turn_state"]["round"] != 2:
        errors.append(f"slice_13_round_cycle_player_enemy_player: expected round 2, got {state['turn_state']['round']}")
    if player["resources"]["ap"] != 1:
        errors.append("slice_13_round_cycle_player_enemy_player: expected player AP to refresh to 1")
    if enemy["resources"]["ap"] != 0:
        errors.append("slice_13_round_cycle_player_enemy_player: expected enemy AP to be 0")
    if enemy["position"] != {"x": 2, "y": 1}:
        errors.append(f"slice_13_round_cycle_player_enemy_player: expected enemy position {{'x': 2, 'y': 1}}, got {enemy['position']}")

    expected_events = [
        "combat_started",
        "turn_started",
        "action_performed",
        "turn_ended",
        "turn_started",
        "action_performed",
        "unit_moved",
        "action_performed",
        "turn_ended",
        "turn_started",
    ]
    if event_types != expected_events:
        errors.append(f"slice_13_round_cycle_player_enemy_player: unexpected events {event_types}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_13_round_cycle_player_enemy_player: replay event log differs")

    return errors


def validate_combat_slice_14() -> list[str]:
    return _validate_terminal_combat(
        slice_id="slice_14_victory_last_enemy_defeated",
        defeated_unit_id="unit_enemy_001",
        expected_result="victory",
    )


def validate_combat_slice_15() -> list[str]:
    return _validate_terminal_combat(
        slice_id="slice_15_defeat_last_player_defeated",
        defeated_unit_id="unit_player_001",
        expected_result="defeat",
    )


def validate_combat_slice_16() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_16_command_after_combat_end_rejected.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_16_command_after_combat_end_rejected_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    event_types = [event["type"] for event in state["event_log"]]

    if result.result != "victory":
        errors.append(f"slice_16_command_after_combat_end_rejected: expected result victory, got {result.result}")
    if player["position"] != {"x": 1, "y": 1}:
        errors.append(f"slice_16_command_after_combat_end_rejected: player position mutated to {player['position']}")
    if event_types != ["combat_started", "turn_started", "command_rejected"]:
        errors.append(f"slice_16_command_after_combat_end_rejected: unexpected events {event_types}")

    rejected = [event for event in state["event_log"] if event["type"] == "command_rejected"]
    if len(rejected) != 1 or rejected[0].get("reason") != "combat_already_ended":
        errors.append("slice_16_command_after_combat_end_rejected: expected combat_already_ended rejection")

    return errors


def validate_combat_slice_19() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_19_highground_walkable.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_19_highground_walkable_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["position"] != {"x": 2, "y": 1}:
        errors.append(f"slice_19_highground_walkable: expected player position {{'x': 2, 'y': 1}}, got {player['position']}")
    if player["resources"]["ap"] != 0:
        errors.append("slice_19_highground_walkable: expected player AP to be 0")
    if event_types != ["combat_started", "turn_started", "action_performed", "unit_moved"]:
        errors.append(f"slice_19_highground_walkable: unexpected events {event_types}")

    return errors


def validate_combat_slice_21() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_21_ranged_attack_in_range.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_21_ranged_attack_in_range_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_21_ranged_attack_in_range: expected player AP to be 0")
    if enemy["resources"]["hp"] != 4:
        errors.append(f"slice_21_ranged_attack_in_range: expected enemy HP 4, got {enemy['resources']['hp']}")
    if result.result != "in_progress":
        errors.append(f"slice_21_ranged_attack_in_range: expected result in_progress, got {result.result}")
    if event_types != ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"]:
        errors.append(f"slice_21_ranged_attack_in_range: unexpected events {event_types}")

    performed = [event for event in state["event_log"] if event["type"] == "action_performed"]
    if len(performed) != 1 or performed[0].get("action_id") != "ranged_attack":
        errors.append("slice_21_ranged_attack_in_range: expected ranged_attack action_performed event")

    roll_events = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll_events) != 1 or roll_events[0].get("outcome") != "hit":
        errors.append("slice_21_ranged_attack_in_range: expected hit roll outcome hit")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_21_ranged_attack_in_range: replay event log differs")

    return errors


def validate_combat_slice_22() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_22_ranged_attack_out_of_range.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_22_ranged_attack_out_of_range_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 1:
        errors.append("slice_22_ranged_attack_out_of_range: expected player AP to remain 1")
    if enemy["resources"]["hp"] != 6:
        errors.append("slice_22_ranged_attack_out_of_range: expected enemy HP to remain 6")
    if result.result != "in_progress":
        errors.append(f"slice_22_ranged_attack_out_of_range: expected result in_progress, got {result.result}")
    if event_types != ["combat_started", "turn_started", "command_rejected"]:
        errors.append(f"slice_22_ranged_attack_out_of_range: unexpected events {event_types}")

    rejected = [event for event in state["event_log"] if event["type"] == "command_rejected"]
    if len(rejected) != 1 or rejected[0].get("reason") != "target_out_of_range":
        errors.append("slice_22_ranged_attack_out_of_range: expected target_out_of_range rejection")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_22_ranged_attack_out_of_range: replay event log differs")

    return errors


def validate_combat_slice_23() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_23_ranged_attack_hit_roll.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_23_ranged_attack_hit_roll_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_23_ranged_attack_hit_roll: expected player AP to be 0")
    if enemy["resources"]["hp"] != 4:
        errors.append(f"slice_23_ranged_attack_hit_roll: expected enemy HP 4, got {enemy['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"]:
        errors.append(f"slice_23_ranged_attack_hit_roll: unexpected events {event_types}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_23_ranged_attack_hit_roll: expected one hit_roll_resolved event")
    elif roll[0].get("roll") != 40 or roll[0].get("hit_chance") != 70 or roll[0].get("outcome") != "hit":
        errors.append(f"slice_23_ranged_attack_hit_roll: unexpected roll payload {roll[0]}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_23_ranged_attack_hit_roll: replay event log differs")

    return errors


def validate_combat_slice_24() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_24_ranged_attack_miss.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_24_ranged_attack_miss_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_24_ranged_attack_miss: expected player AP to be 0")
    if enemy["resources"]["hp"] != 6:
        errors.append("slice_24_ranged_attack_miss: expected enemy HP to remain 6")
    if event_types != ["combat_started", "turn_started", "action_performed", "hit_roll_resolved"]:
        errors.append(f"slice_24_ranged_attack_miss: unexpected events {event_types}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_24_ranged_attack_miss: expected one hit_roll_resolved event")
    elif roll[0].get("roll") != 72 or roll[0].get("hit_chance") != 70 or roll[0].get("outcome") != "miss":
        errors.append(f"slice_24_ranged_attack_miss: unexpected roll payload {roll[0]}")

    if any(event["type"] == "damage_applied" for event in state["event_log"]):
        errors.append("slice_24_ranged_attack_miss: damage_applied should not be emitted")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_24_ranged_attack_miss: replay event log differs")

    return errors


def validate_combat_slice_25() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_25_accuracy_increases_hit_chance.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_25_accuracy_increases_hit_chance_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_25_accuracy_increases_hit_chance: expected player AP to be 0")
    if enemy["resources"]["hp"] != 4:
        errors.append(f"slice_25_accuracy_increases_hit_chance: expected enemy HP 4, got {enemy['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"]:
        errors.append(f"slice_25_accuracy_increases_hit_chance: unexpected events {event_types}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_25_accuracy_increases_hit_chance: expected one hit_roll_resolved event")
    elif not _hit_roll_matches(
        roll[0],
        roll=72,
        base_hit_chance=70,
        accuracy_modifier=10,
        evasion_modifier=0,
        hit_chance=80,
        outcome="hit",
    ):
        errors.append(f"slice_25_accuracy_increases_hit_chance: unexpected roll payload {roll[0]}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_25_accuracy_increases_hit_chance: replay event log differs")

    return errors


def validate_combat_slice_26() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_26_evasion_decreases_hit_chance.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_26_evasion_decreases_hit_chance_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_26_evasion_decreases_hit_chance: expected player AP to be 0")
    if enemy["resources"]["hp"] != 6:
        errors.append("slice_26_evasion_decreases_hit_chance: expected enemy HP to remain 6")
    if event_types != ["combat_started", "turn_started", "action_performed", "hit_roll_resolved"]:
        errors.append(f"slice_26_evasion_decreases_hit_chance: unexpected events {event_types}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_26_evasion_decreases_hit_chance: expected one hit_roll_resolved event")
    elif not _hit_roll_matches(
        roll[0],
        roll=40,
        base_hit_chance=70,
        accuracy_modifier=0,
        evasion_modifier=40,
        hit_chance=30,
        outcome="miss",
    ):
        errors.append(f"slice_26_evasion_decreases_hit_chance: unexpected roll payload {roll[0]}")

    if any(event["type"] == "damage_applied" for event in state["event_log"]):
        errors.append("slice_26_evasion_decreases_hit_chance: damage_applied should not be emitted")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_26_evasion_decreases_hit_chance: replay event log differs")

    return errors


def validate_combat_slice_27() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_27_highground_increases_ranged_hit_chance.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_27_highground_increases_ranged_hit_chance_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_27_highground_increases_ranged_hit_chance: expected player AP to be 0")
    if enemy["resources"]["hp"] != 4:
        errors.append(f"slice_27_highground_increases_ranged_hit_chance: expected enemy HP 4, got {enemy['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"]:
        errors.append(f"slice_27_highground_increases_ranged_hit_chance: unexpected events {event_types}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_27_highground_increases_ranged_hit_chance: expected one hit_roll_resolved event")
    elif not _hit_roll_matches(
        roll[0],
        roll=72,
        base_hit_chance=70,
        accuracy_modifier=0,
        evasion_modifier=0,
        terrain_modifier=10,
        hit_chance=80,
        outcome="hit",
    ):
        errors.append(f"slice_27_highground_increases_ranged_hit_chance: unexpected roll payload {roll[0]}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_27_highground_increases_ranged_hit_chance: replay event log differs")

    return errors


def validate_combat_slice_28() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_28_ranged_attack_blocked_by_line_of_sight.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_28_ranged_attack_blocked_by_line_of_sight_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 1:
        errors.append("slice_28_ranged_attack_blocked_by_line_of_sight: expected player AP to remain 1")
    if enemy["resources"]["hp"] != 6:
        errors.append("slice_28_ranged_attack_blocked_by_line_of_sight: expected enemy HP to remain 6")
    if event_types != ["combat_started", "turn_started", "command_rejected"]:
        errors.append(f"slice_28_ranged_attack_blocked_by_line_of_sight: unexpected events {event_types}")

    rejected = [event for event in state["event_log"] if event["type"] == "command_rejected"]
    if len(rejected) != 1 or rejected[0].get("reason") != "target_not_visible":
        errors.append("slice_28_ranged_attack_blocked_by_line_of_sight: expected target_not_visible rejection")

    if any(event["type"] == "hit_roll_resolved" for event in state["event_log"]):
        errors.append("slice_28_ranged_attack_blocked_by_line_of_sight: hit_roll_resolved should not be emitted")
    if any(event["type"] == "damage_applied" for event in state["event_log"]):
        errors.append("slice_28_ranged_attack_blocked_by_line_of_sight: damage_applied should not be emitted")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_28_ranged_attack_blocked_by_line_of_sight: replay event log differs")

    return errors


def validate_combat_slice_29() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_29_cover_reduces_ranged_hit_chance.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_29_cover_reduces_ranged_hit_chance_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_29_cover_reduces_ranged_hit_chance: expected player AP to be 0")
    if enemy["resources"]["hp"] != 6:
        errors.append("slice_29_cover_reduces_ranged_hit_chance: expected enemy HP to remain 6")
    if event_types != ["combat_started", "turn_started", "action_performed", "hit_roll_resolved"]:
        errors.append(f"slice_29_cover_reduces_ranged_hit_chance: unexpected events {event_types}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_29_cover_reduces_ranged_hit_chance: expected one hit_roll_resolved event")
    elif not _hit_roll_matches(
        roll[0],
        roll=72,
        base_hit_chance=70,
        accuracy_modifier=0,
        evasion_modifier=0,
        hit_chance=50,
        outcome="miss",
        cover_modifier=-20,
    ):
        errors.append(f"slice_29_cover_reduces_ranged_hit_chance: unexpected roll payload {roll[0]}")

    if any(event["type"] == "damage_applied" for event in state["event_log"]):
        errors.append("slice_29_cover_reduces_ranged_hit_chance: damage_applied should not be emitted")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_29_cover_reduces_ranged_hit_chance: replay event log differs")

    return errors


def validate_combat_slice_30() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_30_enemy_ai_ranged_attack.json")
    command = choose_enemy_command(encounter)

    if command["action_id"] != "ranged_attack":
        errors.append(f"slice_30_enemy_ai_ranged_attack: expected AI ranged_attack, got {command['action_id']}")
    if command["actor_id"] != "unit_enemy_001":
        errors.append(f"slice_30_enemy_ai_ranged_attack: expected actor unit_enemy_001, got {command['actor_id']}")
    if command["target"].get("unit_id") != "unit_player_001":
        errors.append(
            "slice_30_enemy_ai_ranged_attack: expected target unit_player_001, "
            f"got {command['target'].get('unit_id')}"
        )

    result = simulate(encounter, [command])
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["hp"] != 8:
        errors.append(f"slice_30_enemy_ai_ranged_attack: expected player HP 8, got {player['resources']['hp']}")
    if enemy["resources"]["ap"] != 0:
        errors.append("slice_30_enemy_ai_ranged_attack: expected enemy AP to be 0")
    if event_types != ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"]:
        errors.append(f"slice_30_enemy_ai_ranged_attack: unexpected events {event_types}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_30_enemy_ai_ranged_attack: expected one hit_roll_resolved event")
    elif not _hit_roll_matches(
        roll[0],
        roll=66,
        base_hit_chance=70,
        accuracy_modifier=0,
        evasion_modifier=0,
        hit_chance=70,
        outcome="hit",
    ):
        errors.append(f"slice_30_enemy_ai_ranged_attack: unexpected roll payload {roll[0]}")

    replay = simulate(encounter, [command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_30_enemy_ai_ranged_attack: replay event log differs")

    return errors


def validate_combat_slice_31() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_31_enemy_ai_pathfinds_around_blocked_tile.json")
    command = choose_enemy_command(encounter)

    if command["action_id"] != "move":
        errors.append(f"slice_31_enemy_ai_pathfinds_around_blocked_tile: expected AI move, got {command['action_id']}")
    if command["actor_id"] != "unit_enemy_001":
        errors.append(
            "slice_31_enemy_ai_pathfinds_around_blocked_tile: expected actor unit_enemy_001, "
            f"got {command['actor_id']}"
        )
    if command["target"].get("position") != {"x": 4, "y": 2}:
        errors.append(
            "slice_31_enemy_ai_pathfinds_around_blocked_tile: expected target position {'x': 4, 'y': 2}, "
            f"got {command['target'].get('position')}"
        )

    result = simulate(encounter, [command])
    state = result.state
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if enemy["position"] != {"x": 4, "y": 2}:
        errors.append(
            "slice_31_enemy_ai_pathfinds_around_blocked_tile: expected enemy position {'x': 4, 'y': 2}, "
            f"got {enemy['position']}"
        )
    if enemy["resources"]["ap"] != 0:
        errors.append("slice_31_enemy_ai_pathfinds_around_blocked_tile: expected enemy AP to be 0")
    if event_types != ["combat_started", "turn_started", "action_performed", "unit_moved"]:
        errors.append(f"slice_31_enemy_ai_pathfinds_around_blocked_tile: unexpected events {event_types}")

    if any(event["type"] == "hit_roll_resolved" for event in state["event_log"]):
        errors.append("slice_31_enemy_ai_pathfinds_around_blocked_tile: hit_roll_resolved should not be emitted")

    replay = simulate(encounter, [command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_31_enemy_ai_pathfinds_around_blocked_tile: replay event log differs")

    return errors


def validate_combat_slice_32() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_32_enemy_ai_multi_turn_path_pursuit.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_32_enemy_ai_multi_turn_path_pursuit_commands.json")

    first_ai_command = choose_enemy_command(encounter)
    if first_ai_command["action_id"] != "move" or first_ai_command["target"].get("position") != {"x": 4, "y": 2}:
        errors.append(f"slice_32_enemy_ai_multi_turn_path_pursuit: unexpected first AI command {first_ai_command}")

    first_result = simulate(encounter, [first_ai_command, commands[1], commands[2]])
    second_ai_command = choose_enemy_command(first_result.state)
    if second_ai_command["action_id"] != "move" or second_ai_command["target"].get("position") != {"x": 3, "y": 2}:
        errors.append(f"slice_32_enemy_ai_multi_turn_path_pursuit: unexpected second AI command {second_ai_command}")

    result = simulate(encounter, [first_ai_command, commands[1], commands[2], second_ai_command])
    state = result.state
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if enemy["position"] != {"x": 3, "y": 2}:
        errors.append(f"slice_32_enemy_ai_multi_turn_path_pursuit: expected enemy position {{'x': 3, 'y': 2}}, got {enemy['position']}")
    if enemy["resources"]["ap"] != 0:
        errors.append("slice_32_enemy_ai_multi_turn_path_pursuit: expected enemy AP to be 0")

    expected_events = [
        "combat_started",
        "turn_started",
        "action_performed",
        "unit_moved",
        "action_performed",
        "turn_ended",
        "turn_started",
        "action_performed",
        "turn_ended",
        "turn_started",
        "action_performed",
        "unit_moved",
    ]
    if event_types != expected_events:
        errors.append(f"slice_32_enemy_ai_multi_turn_path_pursuit: unexpected events {event_types}")

    replay = simulate(encounter, [first_ai_command, commands[1], commands[2], second_ai_command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_32_enemy_ai_multi_turn_path_pursuit: replay event log differs")

    return errors


def validate_combat_slice_33() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_33_diagonal_corner_cut_blocked.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_33_diagonal_corner_cut_blocked_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["position"] != {"x": 1, "y": 1}:
        errors.append(f"slice_33_diagonal_corner_cut_blocked: expected player position unchanged, got {player['position']}")
    if player["resources"]["ap"] != 1:
        errors.append("slice_33_diagonal_corner_cut_blocked: expected player AP to remain 1")
    if event_types != ["combat_started", "turn_started", "command_rejected"]:
        errors.append(f"slice_33_diagonal_corner_cut_blocked: unexpected events {event_types}")

    rejected = [event for event in state["event_log"] if event["type"] == "command_rejected"]
    if len(rejected) != 1 or rejected[0].get("reason") != "diagonal_corner_blocked":
        errors.append("slice_33_diagonal_corner_cut_blocked: expected diagonal_corner_blocked rejection")

    return errors


def validate_combat_slice_34() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_34_enemy_ai_approaches_low_chance_ranged_target.json")
    command = choose_enemy_command(encounter)

    if command["action_id"] != "move":
        errors.append(f"slice_34_enemy_ai_approaches_low_chance_ranged_target: expected AI move, got {command['action_id']}")
    if command["target"].get("position") != {"x": 3, "y": 1}:
        errors.append(
            "slice_34_enemy_ai_approaches_low_chance_ranged_target: expected target position {'x': 3, 'y': 1}, "
            f"got {command['target'].get('position')}"
        )

    result = simulate(encounter, [command])
    state = result.state
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if enemy["position"] != {"x": 3, "y": 1}:
        errors.append(f"slice_34_enemy_ai_approaches_low_chance_ranged_target: expected enemy position {{'x': 3, 'y': 1}}, got {enemy['position']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "unit_moved"]:
        errors.append(f"slice_34_enemy_ai_approaches_low_chance_ranged_target: unexpected events {event_types}")
    if any(event["type"] == "hit_roll_resolved" for event in state["event_log"]):
        errors.append("slice_34_enemy_ai_approaches_low_chance_ranged_target: hit_roll_resolved should not be emitted")

    return errors


def validate_combat_slice_40() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_40_multi_enemy_pathing_and_targeting.json")
    first_command = choose_enemy_command(encounter)

    if first_command["action_id"] != "move":
        errors.append(f"slice_40_multi_enemy_pathing_and_targeting: expected first AI move, got {first_command['action_id']}")
    if first_command["actor_id"] != "unit_enemy_001":
        errors.append(f"slice_40_multi_enemy_pathing_and_targeting: expected first actor unit_enemy_001, got {first_command['actor_id']}")
    if first_command["target"].get("position") != {"x": 3, "y": 1}:
        errors.append(
            "slice_40_multi_enemy_pathing_and_targeting: expected first target {'x': 3, 'y': 1}, "
            f"got {first_command['target'].get('position')}"
        )

    end_turn = {
        "id": "cmd_002",
        "type": "perform_action",
        "actor_id": "unit_enemy_001",
        "action_id": "end_turn",
        "target": {"type": "none"},
    }
    after_first = simulate(encounter, [first_command, end_turn]).state
    second_command = choose_enemy_command(after_first)

    if second_command["action_id"] != "move":
        errors.append(f"slice_40_multi_enemy_pathing_and_targeting: expected second AI move, got {second_command['action_id']}")
    if second_command["actor_id"] != "unit_enemy_002":
        errors.append(f"slice_40_multi_enemy_pathing_and_targeting: expected second actor unit_enemy_002, got {second_command['actor_id']}")
    if second_command["target"].get("position") != {"x": 3, "y": 2}:
        errors.append(
            "slice_40_multi_enemy_pathing_and_targeting: expected second target {'x': 3, 'y': 2}, "
            f"got {second_command['target'].get('position')}"
        )
    if second_command["target"].get("position") == first_command["target"].get("position"):
        errors.append("slice_40_multi_enemy_pathing_and_targeting: enemies chose the same destination")

    result = simulate(encounter, [first_command, end_turn, second_command])
    state = result.state
    enemy_001 = _unit_by_id(state, "unit_enemy_001")
    enemy_002 = _unit_by_id(state, "unit_enemy_002")
    event_types = [event["type"] for event in state["event_log"]]

    if enemy_001["position"] != {"x": 3, "y": 1}:
        errors.append(f"slice_40_multi_enemy_pathing_and_targeting: expected enemy 001 at {{'x': 3, 'y': 1}}, got {enemy_001['position']}")
    if enemy_002["position"] != {"x": 3, "y": 2}:
        errors.append(f"slice_40_multi_enemy_pathing_and_targeting: expected enemy 002 at {{'x': 3, 'y': 2}}, got {enemy_002['position']}")
    if enemy_001["position"] == enemy_002["position"]:
        errors.append("slice_40_multi_enemy_pathing_and_targeting: enemies stacked on the same tile")

    expected_events = [
        "combat_started",
        "turn_started",
        "action_performed",
        "unit_moved",
        "action_performed",
        "turn_ended",
        "turn_started",
        "action_performed",
        "unit_moved",
    ]
    if event_types != expected_events:
        errors.append(f"slice_40_multi_enemy_pathing_and_targeting: unexpected events {event_types}")

    replay = simulate(encounter, [first_command, end_turn, second_command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_40_multi_enemy_pathing_and_targeting: replay event log differs")

    return errors


def validate_combat_slice_41() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_41_multi_enemy_bottleneck_spacing.json")
    first_command = choose_enemy_command(encounter)

    if first_command["action_id"] != "move":
        errors.append(f"slice_41_multi_enemy_bottleneck_spacing: expected first AI move, got {first_command['action_id']}")
    if first_command["actor_id"] != "unit_enemy_001":
        errors.append(f"slice_41_multi_enemy_bottleneck_spacing: expected first actor unit_enemy_001, got {first_command['actor_id']}")
    if first_command["target"].get("position") != {"x": 3, "y": 1}:
        errors.append(
            "slice_41_multi_enemy_bottleneck_spacing: expected first target {'x': 3, 'y': 1}, "
            f"got {first_command['target'].get('position')}"
        )

    end_turn = {
        "id": "cmd_002",
        "type": "perform_action",
        "actor_id": "unit_enemy_001",
        "action_id": "end_turn",
        "target": {"type": "none"},
    }
    after_first = simulate(encounter, [first_command, end_turn]).state
    second_command = choose_enemy_command(after_first)

    if second_command["action_id"] != "move":
        errors.append(f"slice_41_multi_enemy_bottleneck_spacing: expected second AI move, got {second_command['action_id']}")
    if second_command["actor_id"] != "unit_enemy_002":
        errors.append(f"slice_41_multi_enemy_bottleneck_spacing: expected second actor unit_enemy_002, got {second_command['actor_id']}")
    if second_command["target"].get("position") != {"x": 4, "y": 1}:
        errors.append(
            "slice_41_multi_enemy_bottleneck_spacing: expected second target {'x': 4, 'y': 1}, "
            f"got {second_command['target'].get('position')}"
        )

    result = simulate(encounter, [first_command, end_turn, second_command])
    state = result.state
    enemy_001 = _unit_by_id(state, "unit_enemy_001")
    enemy_002 = _unit_by_id(state, "unit_enemy_002")
    event_types = [event["type"] for event in state["event_log"]]

    if enemy_001["position"] != {"x": 3, "y": 1}:
        errors.append(f"slice_41_multi_enemy_bottleneck_spacing: expected enemy 001 at {{'x': 3, 'y': 1}}, got {enemy_001['position']}")
    if enemy_002["position"] != {"x": 4, "y": 1}:
        errors.append(f"slice_41_multi_enemy_bottleneck_spacing: expected enemy 002 at {{'x': 4, 'y': 1}}, got {enemy_002['position']}")
    if enemy_001["position"] == enemy_002["position"]:
        errors.append("slice_41_multi_enemy_bottleneck_spacing: enemies stacked on the same tile")
    if any(event["type"] == "command_rejected" for event in state["event_log"]):
        errors.append("slice_41_multi_enemy_bottleneck_spacing: command_rejected should not be emitted")

    expected_events = [
        "combat_started",
        "turn_started",
        "action_performed",
        "unit_moved",
        "action_performed",
        "turn_ended",
        "turn_started",
        "action_performed",
        "unit_moved",
    ]
    if event_types != expected_events:
        errors.append(f"slice_41_multi_enemy_bottleneck_spacing: unexpected events {event_types}")

    replay = simulate(encounter, [first_command, end_turn, second_command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_41_multi_enemy_bottleneck_spacing: replay event log differs")

    return errors


def validate_combat_slice_42() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_42_mixed_melee_ranged_enemy_roles.json")
    first_command = choose_enemy_command(encounter)

    if first_command["action_id"] != "move":
        errors.append(f"slice_42_mixed_melee_ranged_enemy_roles: expected first AI move, got {first_command['action_id']}")
    if first_command["actor_id"] != "unit_enemy_001":
        errors.append(f"slice_42_mixed_melee_ranged_enemy_roles: expected first actor unit_enemy_001, got {first_command['actor_id']}")
    if first_command["target"].get("position") != {"x": 3, "y": 1}:
        errors.append(
            "slice_42_mixed_melee_ranged_enemy_roles: expected first target {'x': 3, 'y': 1}, "
            f"got {first_command['target'].get('position')}"
        )

    end_turn = {
        "id": "cmd_002",
        "type": "perform_action",
        "actor_id": "unit_enemy_001",
        "action_id": "end_turn",
        "target": {"type": "none"},
    }
    after_first = simulate(encounter, [first_command, end_turn]).state
    second_command = choose_enemy_command(after_first)

    if second_command["action_id"] != "ranged_attack":
        errors.append(f"slice_42_mixed_melee_ranged_enemy_roles: expected second AI ranged_attack, got {second_command['action_id']}")
    if second_command["actor_id"] != "unit_enemy_002":
        errors.append(f"slice_42_mixed_melee_ranged_enemy_roles: expected second actor unit_enemy_002, got {second_command['actor_id']}")
    if second_command["target"].get("unit_id") != "unit_player_001":
        errors.append(
            "slice_42_mixed_melee_ranged_enemy_roles: expected second target unit_player_001, "
            f"got {second_command['target'].get('unit_id')}"
        )

    result = simulate(encounter, [first_command, end_turn, second_command])
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy_001 = _unit_by_id(state, "unit_enemy_001")
    enemy_002 = _unit_by_id(state, "unit_enemy_002")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["hp"] != 8:
        errors.append(f"slice_42_mixed_melee_ranged_enemy_roles: expected player HP 8, got {player['resources']['hp']}")
    if enemy_001["position"] != {"x": 3, "y": 1}:
        errors.append(f"slice_42_mixed_melee_ranged_enemy_roles: expected enemy 001 at {{'x': 3, 'y': 1}}, got {enemy_001['position']}")
    if enemy_002["position"] != {"x": 4, "y": 2}:
        errors.append(f"slice_42_mixed_melee_ranged_enemy_roles: expected enemy 002 to remain at {{'x': 4, 'y': 2}}, got {enemy_002['position']}")
    if enemy_002["resources"]["ap"] != 0:
        errors.append("slice_42_mixed_melee_ranged_enemy_roles: expected enemy 002 AP to be 0")

    expected_events = [
        "combat_started",
        "turn_started",
        "action_performed",
        "unit_moved",
        "action_performed",
        "turn_ended",
        "turn_started",
        "action_performed",
        "hit_roll_resolved",
        "damage_applied",
    ]
    if event_types != expected_events:
        errors.append(f"slice_42_mixed_melee_ranged_enemy_roles: unexpected events {event_types}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_42_mixed_melee_ranged_enemy_roles: expected one hit_roll_resolved event")
    elif not _hit_roll_matches(
        roll[0],
        roll=8,
        base_hit_chance=70,
        accuracy_modifier=0,
        evasion_modifier=0,
        hit_chance=70,
        outcome="hit",
    ):
        errors.append(f"slice_42_mixed_melee_ranged_enemy_roles: unexpected roll payload {roll[0]}")

    replay = simulate(encounter, [first_command, end_turn, second_command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_42_mixed_melee_ranged_enemy_roles: replay event log differs")

    return errors


def validate_combat_slice_43() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_43_target_selection_multiple_players.json")
    command = choose_enemy_command(encounter)

    if command["action_id"] != "ranged_attack":
        errors.append(f"slice_43_target_selection_multiple_players: expected AI ranged_attack, got {command['action_id']}")
    if command["actor_id"] != "unit_enemy_001":
        errors.append(f"slice_43_target_selection_multiple_players: expected actor unit_enemy_001, got {command['actor_id']}")
    if command["target"].get("unit_id") != "unit_player_002":
        errors.append(
            "slice_43_target_selection_multiple_players: expected target unit_player_002, "
            f"got {command['target'].get('unit_id')}"
        )

    result = simulate(encounter, [command])
    state = result.state
    player_001 = _unit_by_id(state, "unit_player_001")
    player_002 = _unit_by_id(state, "unit_player_002")
    player_003 = _unit_by_id(state, "unit_player_003")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player_001["resources"]["hp"] != 10:
        errors.append("slice_43_target_selection_multiple_players: expected unit_player_001 HP to remain 10")
    if player_002["resources"]["hp"] != 8:
        errors.append(f"slice_43_target_selection_multiple_players: expected unit_player_002 HP 8, got {player_002['resources']['hp']}")
    if player_003["resources"]["hp"] != 0:
        errors.append("slice_43_target_selection_multiple_players: expected defeated unit_player_003 to remain 0 HP")
    if enemy["resources"]["ap"] != 0:
        errors.append("slice_43_target_selection_multiple_players: expected enemy AP to be 0")
    if event_types != ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"]:
        errors.append(f"slice_43_target_selection_multiple_players: unexpected events {event_types}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_43_target_selection_multiple_players: expected one hit_roll_resolved event")
    elif not _hit_roll_matches(
        roll[0],
        roll=9,
        base_hit_chance=70,
        accuracy_modifier=0,
        evasion_modifier=0,
        hit_chance=70,
        outcome="hit",
    ):
        errors.append(f"slice_43_target_selection_multiple_players: unexpected roll payload {roll[0]}")

    replay = simulate(encounter, [command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_43_target_selection_multiple_players: replay event log differs")

    return errors


def validate_combat_slice_44() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_44_ranged_intercept_by_unit.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_44_ranged_intercept_by_unit_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    original_target = _unit_by_id(state, "unit_enemy_001")
    blocker = _unit_by_id(state, "unit_enemy_002")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_44_ranged_intercept_by_unit: expected player AP to be 0")
    if original_target["resources"]["hp"] != 6:
        errors.append("slice_44_ranged_intercept_by_unit: expected original target HP to remain 6")
    if blocker["resources"]["hp"] != 4:
        errors.append(f"slice_44_ranged_intercept_by_unit: expected blocker HP 4, got {blocker['resources']['hp']}")

    expected_events = [
        "combat_started",
        "turn_started",
        "action_performed",
        "shot_intercept_resolved",
        "hit_roll_resolved",
        "damage_applied",
    ]
    if event_types != expected_events:
        errors.append(f"slice_44_ranged_intercept_by_unit: unexpected events {event_types}")

    intercept = [event for event in state["event_log"] if event["type"] == "shot_intercept_resolved"]
    if len(intercept) != 1:
        errors.append("slice_44_ranged_intercept_by_unit: expected one shot_intercept_resolved event")
    else:
        expected_intercept = {
            "original_target_unit_id": "unit_enemy_001",
            "blocker_unit_id": "unit_enemy_002",
            "final_target_unit_id": "unit_enemy_002",
            "blocker_progress": 67,
            "intercept_chance": 60,
            "roll": 34,
            "outcome": "intercepted",
        }
        for key, expected in expected_intercept.items():
            if intercept[0].get(key) != expected:
                errors.append(f"slice_44_ranged_intercept_by_unit: expected intercept {key} {expected}, got {intercept[0].get(key)}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_44_ranged_intercept_by_unit: expected one hit_roll_resolved event")
    elif not _hit_roll_matches(
        roll[0],
        roll=61,
        base_hit_chance=70,
        accuracy_modifier=0,
        evasion_modifier=0,
        hit_chance=70,
        outcome="hit",
    ) or roll[0].get("target_unit_id") != "unit_enemy_002":
        errors.append(f"slice_44_ranged_intercept_by_unit: unexpected hit roll payload {roll[0]}")

    damage = [event for event in state["event_log"] if event["type"] == "damage_applied"]
    if len(damage) != 1 or damage[0].get("target_unit_id") != "unit_enemy_002":
        errors.append("slice_44_ranged_intercept_by_unit: expected damage on blocker unit_enemy_002")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_44_ranged_intercept_by_unit: replay event log differs")

    return errors


def validate_combat_slice_45() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_45_weapon_profile_melee_damage.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_45_weapon_profile_melee_damage_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_45_weapon_profile_melee_damage: expected player AP to be 0")
    if enemy["resources"]["hp"] != 2:
        errors.append(f"slice_45_weapon_profile_melee_damage: expected enemy HP 2, got {enemy['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "damage_applied"]:
        errors.append(f"slice_45_weapon_profile_melee_damage: unexpected events {event_types}")

    damage = [event for event in state["event_log"] if event["type"] == "damage_applied"]
    if len(damage) != 1 or damage[0].get("weapon_id") != "iron_sword" or damage[0].get("damage_bonus") != 2:
        errors.append(f"slice_45_weapon_profile_melee_damage: unexpected damage payload {damage}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_45_weapon_profile_melee_damage: replay event log differs")

    return errors


def validate_combat_slice_46() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_46_weapon_profile_ranged_range_hit.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_46_weapon_profile_ranged_range_hit_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_46_weapon_profile_ranged_range_hit: expected player AP to be 0")
    if enemy["resources"]["hp"] != 3:
        errors.append(f"slice_46_weapon_profile_ranged_range_hit: expected enemy HP 3, got {enemy['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "hit_roll_resolved", "damage_applied"]:
        errors.append(f"slice_46_weapon_profile_ranged_range_hit: unexpected events {event_types}")

    roll = [event for event in state["event_log"] if event["type"] == "hit_roll_resolved"]
    if len(roll) != 1:
        errors.append("slice_46_weapon_profile_ranged_range_hit: expected one hit_roll_resolved event")
    elif not _hit_roll_matches(
        roll[0],
        roll=63,
        base_hit_chance=85,
        accuracy_modifier=0,
        evasion_modifier=0,
        hit_chance=85,
        outcome="hit",
    ):
        errors.append(f"slice_46_weapon_profile_ranged_range_hit: unexpected hit roll payload {roll[0]}")

    damage = [event for event in state["event_log"] if event["type"] == "damage_applied"]
    if len(damage) != 1 or damage[0].get("weapon_id") != "longbow" or damage[0].get("damage_bonus") != 1:
        errors.append(f"slice_46_weapon_profile_ranged_range_hit: unexpected damage payload {damage}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_46_weapon_profile_ranged_range_hit: replay event log differs")

    return errors


def validate_combat_slice_47() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_47_weapon_profile_ap_cost.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_47_weapon_profile_ap_cost_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 1:
        errors.append("slice_47_weapon_profile_ap_cost: expected player AP to remain 1")
    if enemy["resources"]["hp"] != 6:
        errors.append("slice_47_weapon_profile_ap_cost: expected enemy HP to remain 6")
    if event_types != ["combat_started", "turn_started", "command_rejected"]:
        errors.append(f"slice_47_weapon_profile_ap_cost: unexpected events {event_types}")

    rejected = [event for event in state["event_log"] if event["type"] == "command_rejected"]
    if len(rejected) != 1 or rejected[0].get("reason") != "not_enough_ap":
        errors.append(f"slice_47_weapon_profile_ap_cost: unexpected rejection {rejected}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_47_weapon_profile_ap_cost: replay event log differs")

    return errors


def validate_combat_slice_48() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_48_power_strike_skill.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_48_power_strike_skill_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_48_power_strike_skill: expected player AP to be 0")
    if enemy["resources"]["hp"] != 1:
        errors.append(f"slice_48_power_strike_skill: expected enemy HP 1, got {enemy['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "status_applied", "damage_applied"]:
        errors.append(f"slice_48_power_strike_skill: unexpected events {event_types}")

    performed = [event for event in state["event_log"] if event["type"] == "action_performed"]
    if len(performed) != 1 or performed[0].get("action_id") != "power_strike" or performed[0].get("ap_spent") != 2:
        errors.append(f"slice_48_power_strike_skill: unexpected action payload {performed}")

    damage = [event for event in state["event_log"] if event["type"] == "damage_applied"]
    if len(damage) != 1 or damage[0].get("weapon_id") != "warhammer" or damage[0].get("damage_bonus") != 3:
        errors.append(f"slice_48_power_strike_skill: unexpected damage payload {damage}")
    cooldown = [event for event in state["event_log"] if event["type"] == "status_applied"]
    if len(cooldown) != 1 or cooldown[0].get("status", {}).get("id") != "skill_cooldown":
        errors.append(f"slice_48_power_strike_skill: expected skill cooldown status, got {cooldown}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_48_power_strike_skill: replay event log differs")

    return errors


def validate_combat_slice_49() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_49_weapon_profile_ap_cost_success.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_49_weapon_profile_ap_cost_success_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_49_weapon_profile_ap_cost_success: expected player AP to be 0")
    if enemy["resources"]["hp"] != 4:
        errors.append(f"slice_49_weapon_profile_ap_cost_success: expected enemy HP 4, got {enemy['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "damage_applied"]:
        errors.append(f"slice_49_weapon_profile_ap_cost_success: unexpected events {event_types}")

    performed = [event for event in state["event_log"] if event["type"] == "action_performed"]
    if len(performed) != 1 or performed[0].get("weapon_id") != "heavy_axe" or performed[0].get("ap_spent") != 2:
        errors.append(f"slice_49_weapon_profile_ap_cost_success: unexpected action payload {performed}")

    damage = [event for event in state["event_log"] if event["type"] == "damage_applied"]
    if len(damage) != 1 or damage[0].get("weapon_id") != "heavy_axe" or damage[0].get("damage_bonus") != 4:
        errors.append(f"slice_49_weapon_profile_ap_cost_success: unexpected damage payload {damage}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_49_weapon_profile_ap_cost_success: replay event log differs")

    return errors


def validate_combat_slice_50() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_50_enemy_ai_power_strike.json")
    command = choose_enemy_command(encounter)

    if command["action_id"] != "power_strike":
        errors.append(f"slice_50_enemy_ai_power_strike: expected AI power_strike, got {command['action_id']}")

    result = simulate(encounter, [command])
    state = result.state
    enemy = _unit_by_id(state, "unit_enemy_001")
    player = _unit_by_id(state, "unit_player_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["hp"] != 8:
        errors.append(f"slice_50_enemy_ai_power_strike: expected player HP 8, got {player['resources']['hp']}")
    if enemy["resources"]["ap"] != 0:
        errors.append("slice_50_enemy_ai_power_strike: expected enemy AP to be 0")
    if [status["id"] for status in enemy["statuses"]] != ["skill_cooldown"]:
        errors.append(f"slice_50_enemy_ai_power_strike: expected cooldown status, got {enemy['statuses']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "status_applied", "damage_applied"]:
        errors.append(f"slice_50_enemy_ai_power_strike: unexpected events {event_types}")

    replay = simulate(encounter, [command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_50_enemy_ai_power_strike: replay event log differs")

    return errors


def validate_combat_slice_51() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_51_enemy_ai_power_strike_cooldown_blocks_repeat.json")
    command = choose_enemy_command(encounter)

    if command["action_id"] != "basic_attack":
        errors.append(f"slice_51_enemy_ai_power_strike_cooldown_blocks_repeat: expected AI basic_attack, got {command['action_id']}")

    result = simulate(encounter, [command])
    state = result.state
    enemy = _unit_by_id(state, "unit_enemy_001")
    player = _unit_by_id(state, "unit_player_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["hp"] != 11:
        errors.append(f"slice_51_enemy_ai_power_strike_cooldown_blocks_repeat: expected player HP 11, got {player['resources']['hp']}")
    if enemy["resources"]["ap"] != 1:
        errors.append(f"slice_51_enemy_ai_power_strike_cooldown_blocks_repeat: expected enemy AP 1, got {enemy['resources']['ap']}")
    if [status["id"] for status in enemy["statuses"]] != ["skill_cooldown"]:
        errors.append(f"slice_51_enemy_ai_power_strike_cooldown_blocks_repeat: expected cooldown status to remain, got {enemy['statuses']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "damage_applied"]:
        errors.append(f"slice_51_enemy_ai_power_strike_cooldown_blocks_repeat: unexpected events {event_types}")

    replay = simulate(encounter, [command])
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_51_enemy_ai_power_strike_cooldown_blocks_repeat: replay event log differs")

    return errors


def validate_combat_slice_52() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_52_skill_cooldown_expires_on_own_turn.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_52_skill_cooldown_expires_on_own_turn_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    expected_events = [
        "combat_started",
        "turn_started",
        "action_performed",
        "turn_ended",
        "turn_started",
        "action_performed",
        "turn_ended",
        "turn_started",
        "status_expired",
    ]
    if event_types != expected_events:
        errors.append(f"slice_52_skill_cooldown_expires_on_own_turn: unexpected events {event_types}")
    if enemy["statuses"] != []:
        errors.append(f"slice_52_skill_cooldown_expires_on_own_turn: expected no enemy statuses, got {enemy['statuses']}")
    if enemy["resources"]["ap"] != 2:
        errors.append(f"slice_52_skill_cooldown_expires_on_own_turn: expected enemy AP refreshed to 2, got {enemy['resources']['ap']}")

    expired = [event for event in state["event_log"] if event["type"] == "status_expired"]
    if len(expired) != 1 or expired[0].get("status", {}).get("id") != "skill_cooldown":
        errors.append(f"slice_52_skill_cooldown_expires_on_own_turn: expected skill cooldown expiration, got {expired}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_52_skill_cooldown_expires_on_own_turn: replay event log differs")

    return errors


def validate_combat_slice_53() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_53_weapon_loadout_v1.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_53_weapon_loadout_v1_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_53_weapon_loadout_v1: expected player AP to be 0")
    if enemy["resources"]["hp"] != 4:
        errors.append(f"slice_53_weapon_loadout_v1: expected enemy HP 4, got {enemy['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "damage_applied"]:
        errors.append(f"slice_53_weapon_loadout_v1: unexpected events {event_types}")

    performed = [event for event in state["event_log"] if event["type"] == "action_performed"]
    if len(performed) != 1 or performed[0].get("profile_id") != "iron_sword_basic_attack":
        errors.append(f"slice_53_weapon_loadout_v1: unexpected action payload {performed}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_53_weapon_loadout_v1: replay event log differs")

    return errors


def validate_combat_slice_54() -> list[str]:
    return _validate_rejected_action(
        "slice_54_bow_required_for_ranged_attack",
        expected_reason="action_not_available",
        expected_actor_ap=1,
        expected_target_hp=6,
    )


def validate_combat_slice_55() -> list[str]:
    return _validate_rejected_action(
        "slice_55_shield_required_for_shield_wall",
        expected_reason="action_not_available",
        expected_actor_ap=1,
        expected_target_hp=6,
    )


def validate_combat_slice_56() -> list[str]:
    return _validate_rejected_action(
        "slice_56_two_handed_blocks_shield",
        expected_reason="invalid_loadout_two_handed_with_off_hand",
        expected_actor_ap=2,
        expected_target_hp=6,
    )


def validate_combat_slice_57() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_57_weapon_grants_power_strike.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_57_weapon_grants_power_strike_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 0:
        errors.append("slice_57_weapon_grants_power_strike: expected player AP to be 0")
    if enemy["resources"]["hp"] != 4:
        errors.append(f"slice_57_weapon_grants_power_strike: expected enemy HP 4, got {enemy['resources']['hp']}")
    if [status["id"] for status in player["statuses"]] != ["skill_cooldown"]:
        errors.append(f"slice_57_weapon_grants_power_strike: expected cooldown status, got {player['statuses']}")
    if player["statuses"][0].get("remaining_turns") != 3:
        errors.append(f"slice_57_weapon_grants_power_strike: expected cooldown 3, got {player['statuses']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "status_applied", "damage_applied"]:
        errors.append(f"slice_57_weapon_grants_power_strike: unexpected events {event_types}")

    performed = [event for event in state["event_log"] if event["type"] == "action_performed"]
    if len(performed) != 1 or performed[0].get("profile_id") != "greatsword_power_strike":
        errors.append(f"slice_57_weapon_grants_power_strike: unexpected action payload {performed}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_57_weapon_grants_power_strike: replay event log differs")

    return errors


def validate_combat_slice_58() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_58_armor_reduces_damage.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_58_armor_reduces_damage_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if enemy["resources"]["ap"] != 0:
        errors.append("slice_58_armor_reduces_damage: expected enemy AP to be 0")
    if player["resources"]["hp"] != 8:
        errors.append(f"slice_58_armor_reduces_damage: expected player HP 8, got {player['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "action_performed", "damage_applied"]:
        errors.append(f"slice_58_armor_reduces_damage: unexpected events {event_types}")

    damage_events = [event for event in state["event_log"] if event["type"] == "damage_applied"]
    if len(damage_events) != 1:
        errors.append(f"slice_58_armor_reduces_damage: expected one damage event, got {damage_events}")
    else:
        damage = damage_events[0]
        if damage.get("raw_damage") != 4 or damage.get("damage_reduction") != 2 or damage.get("damage") != 2:
            errors.append(f"slice_58_armor_reduces_damage: unexpected damage payload {damage}")
        if damage.get("armor_id") != "chainmail":
            errors.append(f"slice_58_armor_reduces_damage: expected chainmail armor_id, got {damage}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_58_armor_reduces_damage: replay event log differs")

    return errors


def validate_combat_slice_59() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_59_shield_wall_applies_damage_reduction.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_59_shield_wall_applies_damage_reduction_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["hp"] != 9:
        errors.append(f"slice_59_shield_wall_applies_damage_reduction: expected player HP 9, got {player['resources']['hp']}")
    if enemy["resources"]["ap"] != 0:
        errors.append("slice_59_shield_wall_applies_damage_reduction: expected enemy AP to be 0")

    expected_events = [
        "combat_started",
        "turn_started",
        "action_performed",
        "status_applied",
        "status_applied",
        "action_performed",
        "turn_ended",
        "turn_started",
        "action_performed",
        "damage_applied",
    ]
    if event_types != expected_events:
        errors.append(f"slice_59_shield_wall_applies_damage_reduction: unexpected events {event_types}")

    shield_statuses = [status for status in player["statuses"] if status.get("id") == "shield_wall"]
    if len(shield_statuses) != 1 or shield_statuses[0].get("damage_reduction") != 2:
        errors.append(f"slice_59_shield_wall_applies_damage_reduction: expected shield_wall DR status, got {player['statuses']}")

    damage_events = [event for event in state["event_log"] if event["type"] == "damage_applied"]
    if len(damage_events) != 1:
        errors.append(f"slice_59_shield_wall_applies_damage_reduction: expected one damage event, got {damage_events}")
    else:
        damage = damage_events[0]
        if damage.get("raw_damage") != 4 or damage.get("damage_reduction") != 4 or damage.get("damage") != 1:
            errors.append(f"slice_59_shield_wall_applies_damage_reduction: unexpected damage payload {damage}")
        if damage.get("armor_id") != "chainmail":
            errors.append(f"slice_59_shield_wall_applies_damage_reduction: expected chainmail armor_id, got {damage}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_59_shield_wall_applies_damage_reduction: replay event log differs")

    return errors


def validate_combat_slice_60() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_60_movement_points_multi_tile.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_60_movement_points_multi_tile_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    event_types = [event["type"] for event in state["event_log"]]

    if result.result != "in_progress":
        errors.append(f"slice_60_movement_points_multi_tile: expected result in_progress, got {result.result}")
    if event_types != ["combat_started", "turn_started", "action_performed", "unit_moved"]:
        errors.append(f"slice_60_movement_points_multi_tile: unexpected events {event_types}")
    if player["position"] != {"x": 3, "y": 1}:
        errors.append(f"slice_60_movement_points_multi_tile: expected player at {{'x': 3, 'y': 1}}, got {player['position']}")
    if player["resources"]["ap"] != 1:
        errors.append(f"slice_60_movement_points_multi_tile: expected AP 1, got {player['resources']['ap']}")
    if player["resources"]["mp"] != 1:
        errors.append(f"slice_60_movement_points_multi_tile: expected MP 1, got {player['resources']['mp']}")

    action = next((event for event in state["event_log"] if event["type"] == "action_performed"), None)
    if action is None:
        errors.append("slice_60_movement_points_multi_tile: expected action_performed")
    elif action.get("ap_spent") != 0 or action.get("mp_spent") != 2:
        errors.append(f"slice_60_movement_points_multi_tile: unexpected action payload {action}")

    moved = next((event for event in state["event_log"] if event["type"] == "unit_moved"), None)
    expected_path = [{"x": 2, "y": 1}, {"x": 3, "y": 1}]
    if moved is None:
        errors.append("slice_60_movement_points_multi_tile: expected unit_moved")
    elif moved.get("from") != {"x": 1, "y": 1} or moved.get("to") != {"x": 3, "y": 1} or moved.get("path") != expected_path:
        errors.append(f"slice_60_movement_points_multi_tile: unexpected move payload {moved}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_60_movement_points_multi_tile: replay event log differs")

    return errors


def validate_combat_slice_61() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_61_ap_mp_turn_economy.json")
    commands = load_json(ROOT / "tests/data/combat_commands/slice_61_ap_mp_turn_economy_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    expected_events = [
        "combat_started",
        "turn_started",
        "action_performed",
        "unit_moved",
        "action_performed",
        "damage_applied",
    ]
    if result.result != "in_progress":
        errors.append(f"slice_61_ap_mp_turn_economy: expected result in_progress, got {result.result}")
    if event_types != expected_events:
        errors.append(f"slice_61_ap_mp_turn_economy: unexpected events {event_types}")
    if state["turn_state"]["active_unit_id"] != "unit_player_001":
        errors.append(f"slice_61_ap_mp_turn_economy: expected player to remain active, got {state['turn_state']['active_unit_id']}")
    if player["position"] != {"x": 3, "y": 1}:
        errors.append(f"slice_61_ap_mp_turn_economy: expected player at {{'x': 3, 'y': 1}}, got {player['position']}")
    if player["resources"]["ap"] != 0:
        errors.append(f"slice_61_ap_mp_turn_economy: expected AP 0, got {player['resources']['ap']}")
    if player["resources"]["mp"] != 1:
        errors.append(f"slice_61_ap_mp_turn_economy: expected MP 1, got {player['resources']['mp']}")
    if enemy["resources"]["hp"] != 3:
        errors.append(f"slice_61_ap_mp_turn_economy: expected enemy HP 3, got {enemy['resources']['hp']}")

    actions = [event for event in state["event_log"] if event["type"] == "action_performed"]
    if len(actions) != 2:
        errors.append(f"slice_61_ap_mp_turn_economy: expected two action_performed events, got {actions}")
    else:
        if actions[0].get("action_id") != "move" or actions[0].get("ap_spent") != 0 or actions[0].get("mp_spent") != 2:
            errors.append(f"slice_61_ap_mp_turn_economy: unexpected move action payload {actions[0]}")
        if actions[1].get("action_id") != "basic_attack" or actions[1].get("ap_spent") != 1:
            errors.append(f"slice_61_ap_mp_turn_economy: unexpected attack action payload {actions[1]}")

    moved = next((event for event in state["event_log"] if event["type"] == "unit_moved"), None)
    expected_path = [{"x": 2, "y": 1}, {"x": 3, "y": 1}]
    if moved is None:
        errors.append("slice_61_ap_mp_turn_economy: expected unit_moved")
    elif moved.get("path") != expected_path or moved.get("mp_spent") != 2:
        errors.append(f"slice_61_ap_mp_turn_economy: unexpected move payload {moved}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_61_ap_mp_turn_economy: replay event log differs")

    return errors


def validate_combat_slice_62() -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / "resources/data/combat_encounters/slice_62_enemy_ai_move_then_attack.json")

    first_command = choose_enemy_command(encounter, "cmd_001")
    if first_command["action_id"] != "move":
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected first AI move, got {first_command['action_id']}")
    if first_command["actor_id"] != "unit_enemy_001":
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected first AI actor unit_enemy_001, got {first_command['actor_id']}")
    if first_command["target"].get("position") != {"x": 3, "y": 1}:
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected first AI position {{'x': 3, 'y': 1}}, got {first_command['target'].get('position')}")

    after_first = simulate(encounter, [first_command]).state
    second_command = choose_enemy_command(after_first, "cmd_002")
    if second_command["action_id"] != "basic_attack":
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected second AI basic_attack, got {second_command['action_id']}")
    if second_command["actor_id"] != "unit_enemy_001":
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected second AI actor unit_enemy_001, got {second_command['actor_id']}")
    if second_command["target"].get("unit_id") != "unit_player_001":
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected second AI target unit_player_001, got {second_command['target'].get('unit_id')}")

    commands = [first_command, second_command]
    result = simulate(encounter, commands)
    state = result.state
    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    expected_events = [
        "combat_started",
        "turn_started",
        "action_performed",
        "unit_moved",
        "action_performed",
        "damage_applied",
    ]
    if result.result != "in_progress":
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected result in_progress, got {result.result}")
    if event_types != expected_events:
        errors.append(f"slice_62_enemy_ai_move_then_attack: unexpected events {event_types}")
    if state["turn_state"]["active_unit_id"] != "unit_enemy_001":
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected enemy to remain active, got {state['turn_state']['active_unit_id']}")
    if enemy["position"] != {"x": 3, "y": 1}:
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected enemy at {{'x': 3, 'y': 1}}, got {enemy['position']}")
    if enemy["resources"]["ap"] != 0:
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected enemy AP 0, got {enemy['resources']['ap']}")
    if enemy["resources"]["mp"] != 1:
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected enemy MP 1, got {enemy['resources']['mp']}")
    if player["resources"]["hp"] != 8:
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected player HP 8, got {player['resources']['hp']}")

    actions = [event for event in state["event_log"] if event["type"] == "action_performed"]
    if len(actions) != 2:
        errors.append(f"slice_62_enemy_ai_move_then_attack: expected two action_performed events, got {actions}")
    else:
        if actions[0].get("action_id") != "move" or actions[0].get("ap_spent") != 0 or actions[0].get("mp_spent") != 2:
            errors.append(f"slice_62_enemy_ai_move_then_attack: unexpected move action payload {actions[0]}")
        if actions[1].get("action_id") != "basic_attack" or actions[1].get("ap_spent") != 1:
            errors.append(f"slice_62_enemy_ai_move_then_attack: unexpected attack action payload {actions[1]}")

    moved = next((event for event in state["event_log"] if event["type"] == "unit_moved"), None)
    expected_path = [{"x": 2, "y": 1}, {"x": 3, "y": 1}]
    if moved is None:
        errors.append("slice_62_enemy_ai_move_then_attack: expected unit_moved")
    elif moved.get("path") != expected_path or moved.get("mp_spent") != 2:
        errors.append(f"slice_62_enemy_ai_move_then_attack: unexpected move payload {moved}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append("slice_62_enemy_ai_move_then_attack: replay event log differs")

    return errors


def _validate_terminal_combat(slice_id: str, defeated_unit_id: str, expected_result: str) -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / f"resources/data/combat_encounters/{slice_id}.json")
    commands = load_json(ROOT / f"tests/data/combat_commands/{slice_id}_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    defeated = _unit_by_id(state, defeated_unit_id)
    event_types = [event["type"] for event in state["event_log"]]

    if result.result != expected_result:
        errors.append(f"{slice_id}: expected result {expected_result}, got {result.result}")
    if defeated["resources"]["hp"] != 0:
        errors.append(f"{slice_id}: expected {defeated_unit_id} HP to be 0")

    expected_events = ["combat_started", "turn_started", "action_performed", "damage_applied", "unit_defeated", "combat_ended"]
    if event_types != expected_events:
        errors.append(f"{slice_id}: unexpected events {event_types}")

    ended_events = [event for event in state["event_log"] if event["type"] == "combat_ended"]
    if len(ended_events) != 1 or ended_events[0].get("result") != expected_result:
        errors.append(f"{slice_id}: expected combat_ended result {expected_result}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append(f"{slice_id}: replay event log differs")

    return errors


def _validate_rejected_action(
    slice_id: str,
    *,
    expected_reason: str,
    expected_actor_ap: int,
    expected_target_hp: int,
) -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / f"resources/data/combat_encounters/{slice_id}.json")
    commands = load_json(ROOT / f"tests/data/combat_commands/{slice_id}_commands.json")

    result = simulate(encounter, commands)
    state = result.state
    actor = _unit_by_id(state, "unit_player_001")
    target = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if actor["resources"]["ap"] != expected_actor_ap:
        errors.append(f"{slice_id}: expected actor AP {expected_actor_ap}, got {actor['resources']['ap']}")
    if target["resources"]["hp"] != expected_target_hp:
        errors.append(f"{slice_id}: expected target HP {expected_target_hp}, got {target['resources']['hp']}")
    if event_types != ["combat_started", "turn_started", "command_rejected"]:
        errors.append(f"{slice_id}: unexpected events {event_types}")

    rejected = [event for event in state["event_log"] if event["type"] == "command_rejected"]
    if len(rejected) != 1 or rejected[0].get("reason") != expected_reason:
        errors.append(f"{slice_id}: expected rejection {expected_reason}, got {rejected}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append(f"{slice_id}: replay event log differs")

    return errors


def _hit_roll_matches(
    event: dict,
    *,
    roll: int,
    base_hit_chance: int,
    accuracy_modifier: int,
    evasion_modifier: int,
    hit_chance: int,
    outcome: str,
    terrain_modifier: int = 0,
    cover_modifier: int = 0,
) -> bool:
    return (
        event.get("roll") == roll
        and event.get("base_hit_chance") == base_hit_chance
        and event.get("accuracy_modifier") == accuracy_modifier
        and event.get("evasion_modifier") == evasion_modifier
        and event.get("terrain_modifier") == terrain_modifier
        and event.get("cover_modifier") == cover_modifier
        and event.get("hit_chance") == hit_chance
        and event.get("outcome") == outcome
    )


def _validate_rejected_move(
    slice_id: str,
    expected_reason: str,
    expected_player_position: dict,
    expected_enemy_position: dict,
) -> list[str]:
    errors: list[str] = []
    encounter = load_json(ROOT / f"resources/data/combat_encounters/{slice_id}.json")
    commands = load_json(ROOT / f"tests/data/combat_commands/{slice_id}_commands.json")

    result = simulate(encounter, commands)
    state = result.state

    player = _unit_by_id(state, "unit_player_001")
    enemy = _unit_by_id(state, "unit_enemy_001")
    event_types = [event["type"] for event in state["event_log"]]

    if player["resources"]["ap"] != 1:
        errors.append(f"{slice_id}: expected player AP to remain 1")
    if player["position"] != expected_player_position:
        errors.append(f"{slice_id}: expected player position {expected_player_position}, got {player['position']}")
    if enemy["position"] != expected_enemy_position:
        errors.append(f"{slice_id}: expected enemy position {expected_enemy_position}, got {enemy['position']}")
    if enemy["resources"]["hp"] != 6:
        errors.append(f"{slice_id}: expected enemy HP to remain 6")
    if result.result != "in_progress":
        errors.append(f"{slice_id}: expected result in_progress, got {result.result}")

    expected_events = ["combat_started", "turn_started", "command_rejected"]
    if event_types != expected_events:
        errors.append(f"{slice_id}: expected events {expected_events}, got {event_types}")

    rejected_events = [event for event in state["event_log"] if event["type"] == "command_rejected"]
    if len(rejected_events) != 1:
        errors.append(f"{slice_id}: expected exactly one command_rejected event")
    elif rejected_events[0].get("reason") != expected_reason:
        errors.append(f"{slice_id}: expected reason {expected_reason}, got {rejected_events[0].get('reason')}")

    forbidden = {"action_performed", "unit_moved", "damage_applied", "unit_defeated", "combat_ended"}
    emitted_forbidden = sorted(forbidden.intersection(event_types))
    if emitted_forbidden:
        errors.append(f"{slice_id}: emitted forbidden events {emitted_forbidden}")

    replay = simulate(encounter, commands)
    if replay.state["event_log"] != state["event_log"]:
        errors.append(f"{slice_id}: replay event log differs")

    return errors


def _unit_by_id(state: dict, unit_id: str) -> dict:
    for unit in state["units"]:
        if unit["id"] == unit_id:
            return unit
    raise KeyError(unit_id)


def main() -> int:
    errors = []
    errors.extend(validate_combat_slice_01())
    errors.extend(validate_combat_slice_02())
    errors.extend(validate_combat_slice_03())
    errors.extend(validate_combat_slice_04())
    errors.extend(validate_combat_slice_05())
    errors.extend(validate_combat_slice_06())
    errors.extend(validate_combat_slice_07())
    errors.extend(validate_combat_slice_08())
    errors.extend(validate_combat_slice_09())
    errors.extend(validate_combat_slice_10())
    errors.extend(validate_combat_slice_11())
    errors.extend(validate_combat_slice_12())
    errors.extend(validate_combat_slice_13())
    errors.extend(validate_combat_slice_14())
    errors.extend(validate_combat_slice_15())
    errors.extend(validate_combat_slice_16())
    errors.extend(validate_combat_slice_19())
    errors.extend(validate_combat_slice_21())
    errors.extend(validate_combat_slice_22())
    errors.extend(validate_combat_slice_23())
    errors.extend(validate_combat_slice_24())
    errors.extend(validate_combat_slice_25())
    errors.extend(validate_combat_slice_26())
    errors.extend(validate_combat_slice_27())
    errors.extend(validate_combat_slice_28())
    errors.extend(validate_combat_slice_29())
    errors.extend(validate_combat_slice_30())
    errors.extend(validate_combat_slice_31())
    errors.extend(validate_combat_slice_32())
    errors.extend(validate_combat_slice_33())
    errors.extend(validate_combat_slice_34())
    errors.extend(validate_combat_slice_40())
    errors.extend(validate_combat_slice_41())
    errors.extend(validate_combat_slice_42())
    errors.extend(validate_combat_slice_43())
    errors.extend(validate_combat_slice_44())
    errors.extend(validate_combat_slice_45())
    errors.extend(validate_combat_slice_46())
    errors.extend(validate_combat_slice_47())
    errors.extend(validate_combat_slice_48())
    errors.extend(validate_combat_slice_49())
    errors.extend(validate_combat_slice_50())
    errors.extend(validate_combat_slice_51())
    errors.extend(validate_combat_slice_52())
    errors.extend(validate_combat_slice_53())
    errors.extend(validate_combat_slice_54())
    errors.extend(validate_combat_slice_55())
    errors.extend(validate_combat_slice_56())
    errors.extend(validate_combat_slice_57())
    errors.extend(validate_combat_slice_58())
    errors.extend(validate_combat_slice_59())
    errors.extend(validate_combat_slice_60())
    errors.extend(validate_combat_slice_61())
    errors.extend(validate_combat_slice_62())
    if errors:
        print("Combat slice validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Combat slice validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
