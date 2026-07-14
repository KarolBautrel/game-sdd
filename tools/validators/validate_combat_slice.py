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


def _hit_roll_matches(
    event: dict,
    *,
    roll: int,
    base_hit_chance: int,
    accuracy_modifier: int,
    evasion_modifier: int,
    hit_chance: int,
    outcome: str,
) -> bool:
    return (
        event.get("roll") == roll
        and event.get("base_hit_chance") == base_hit_chance
        and event.get("accuracy_modifier") == accuracy_modifier
        and event.get("evasion_modifier") == evasion_modifier
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
    if errors:
        print("Combat slice validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Combat slice validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
