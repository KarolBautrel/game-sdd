from __future__ import annotations

import json
import copy
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.assets.build_catalogue import catalogue_errors
from tools.validators.hero_equipment_identity import errors as hero_identity_errors
from tools.validators.tactical_roster import errors as tactical_roster_errors
from tools.validators.town_spaces import errors as town_space_errors
from tools.validators.combat_authoring import catalogue_errors as combat_authoring_errors, encounter_errors
from tools.validators.living_region import reference_errors as living_reference_errors
from tools.validators.strategy_world import reference_errors as strategy_reference_errors
from tools.validators.classic_strategy import configuration_errors as classic_configuration_errors, reference_errors as classic_reference_errors
from tools.validators.strategic_region import rules_errors as region_rules_errors, reference_errors as strategic_reference_errors
from tools.validators.strategist import reference_errors as model_reference_errors, request_errors as model_request_errors, reply_errors as model_reply_errors, replay_errors as model_replay_errors

try:
    from jsonschema import Draft202012Validator
except ImportError:
    print("Missing dependency: jsonschema")
    print("Install it with: python -m pip install -r requirements-dev.txt")
    sys.exit(2)

from tools.validators.validate_combat_slice import (
    validate_combat_slice_01,
    validate_combat_slice_02,
    validate_combat_slice_03,
    validate_combat_slice_04,
    validate_combat_slice_05,
    validate_combat_slice_06,
    validate_combat_slice_07,
    validate_combat_slice_08,
    validate_combat_slice_09,
    validate_combat_slice_10,
    validate_combat_slice_11,
    validate_combat_slice_12,
    validate_combat_slice_13,
    validate_combat_slice_14,
    validate_combat_slice_15,
    validate_combat_slice_16,
    validate_combat_slice_19,
    validate_combat_slice_21,
    validate_combat_slice_22,
    validate_combat_slice_23,
    validate_combat_slice_24,
    validate_combat_slice_25,
    validate_combat_slice_26,
    validate_combat_slice_27,
    validate_combat_slice_28,
    validate_combat_slice_29,
    validate_combat_slice_30,
    validate_combat_slice_31,
    validate_combat_slice_32,
    validate_combat_slice_33,
    validate_combat_slice_34,
    validate_combat_slice_40,
    validate_combat_slice_41,
    validate_combat_slice_42,
    validate_combat_slice_43,
    validate_combat_slice_44,
    validate_combat_slice_45,
    validate_combat_slice_46,
    validate_combat_slice_47,
    validate_combat_slice_48,
    validate_combat_slice_49,
    validate_combat_slice_50,
    validate_combat_slice_51,
    validate_combat_slice_52,
    validate_combat_slice_53,
    validate_combat_slice_54,
    validate_combat_slice_55,
    validate_combat_slice_56,
    validate_combat_slice_57,
    validate_combat_slice_58,
    validate_combat_slice_59,
    validate_combat_slice_60,
    validate_combat_slice_61,
    validate_combat_slice_62,
    validate_combat_slice_63,
    validate_combat_slice_64,
    validate_combat_slice_65,
    validate_combat_slice_66,
    validate_combat_slice_77,
    validate_combat_slice_78,
    validate_combat_slice_79,
    validate_combat_slice_80,
    validate_combat_slice_81,
    validate_combat_slice_82,
)
from tools.maps.tiled_to_map_json import convert_tmx
from tools.validators.dungeon_quality import catalogue_errors as dungeon_quality_errors


ID_RE = re.compile(r"^[a-z0-9_]+$")

VALIDATION_TARGETS = [
    ("resources/schemas/original_roster.schema.json", "resources/data/presentation/original_roster.json"),
    ("resources/schemas/party_levels.schema.json", "resources/data/progression/*.json"),
    ("resources/schemas/town_trade.schema.json", "resources/data/town_trade/*.json"),
    ("resources/schemas/campaign_item_catalogue.schema.json", "resources/data/items/*.json"),
    ("resources/schemas/road_event_catalogue.schema.json", "resources/data/world_events/*.json"),
    ("resources/schemas/campaign_profile.schema.json", "resources/data/campaign/*.json"),
    ("resources/schemas/combat_scenario_catalogue.schema.json", "resources/data/combat_scenarios/*.json"),
    ("resources/schemas/world_region.schema.json", "resources/data/world_regions/*.json"),
    ("resources/schemas/living_region.schema.json", "resources/data/world_simulations/*.json"),
    ("resources/schemas/strategy_world.schema.json", "resources/data/strategy_worlds/*.json"),
    ("resources/schemas/classic_rules.schema.json", "resources/data/strategy_simulations/*.json"),
    ("resources/schemas/classic_world.schema.json", "resources/data/strategy_snapshots/*.json"),
    ("resources/schemas/region_rules.schema.json", "resources/data/strategy_regions/*.json"),
    ("resources/schemas/strategic_region.schema.json", "resources/data/strategic_regions/*.json"),
    ("resources/schemas/strategist_rules.schema.json", "resources/data/strategists/rules*.json"),
    ("resources/schemas/strategist_examples.schema.json", "resources/data/strategists/recorded*.json"),
    ("resources/schemas/strategist_request.schema.json", "resources/data/strategist_requests/*.json"),
    ("resources/schemas/strategist_reply.schema.json", "resources/data/strategist_replies/*.json"),
    ("resources/schemas/strategist_campaign.schema.json", "resources/data/strategist_campaigns/*.json"),
    ("resources/schemas/strategist_replay.schema.json", "resources/data/strategist_replays/*.json"),
    ("resources/schemas/world_terrain.schema.json", "resources/data/world_terrain/*.json"),
    ("resources/schemas/generated_region.schema.json", "resources/data/generated_regions/*.json"),
    ("resources/schemas/generated_region.schema.json", "resources/data/large_regions/*.json"),
    ("resources/schemas/generated_region.schema.json", "resources/data/vast_regions/*.json"),
    ("resources/schemas/town.schema.json", "resources/data/towns/*.json"),
    ("resources/schemas/dungeon.schema.json", "resources/data/dungeons/*.json"),
    ("resources/schemas/dungeon_event.schema.json", "resources/data/dungeon_events/*.json"),
    ("resources/schemas/dungeon_event_pool.schema.json", "resources/data/dungeon_event_pools/*.json"),
    ("resources/schemas/dungeon_room_event.schema.json", "resources/data/dungeon_room_events/*.json"),
    ("resources/schemas/dungeon_room_event_pool.schema.json", "resources/data/dungeon_room_event_pools/*.json"),
    ("resources/schemas/dungeon_template.schema.json", "resources/data/dungeon_templates/*.json"),
    ("resources/schemas/dungeon_combat_encounter_pool.schema.json", "resources/data/dungeon_combat_encounter_pools/*.json"),
    ("resources/schemas/dungeon_debuff.schema.json", "resources/data/dungeon_debuffs/*.json"),
    ("resources/schemas/map.schema.json", "resources/data/maps/*.json"),
    ("resources/schemas/combat_action.schema.json", "resources/data/combat_actions/*.json"),
    ("resources/schemas/combat_encounter.schema.json", "resources/data/combat_encounters/*.json"),
    ("resources/schemas/combat_command.schema.json", "tests/data/combat_commands/*.json"),
]


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def validate_schema(schema_path: Path, data_paths: list[Path]) -> list[str]:
    errors: list[str] = []
    schema = load_json(schema_path)
    validator = Draft202012Validator(schema)

    for data_path in data_paths:
        data = load_json(data_path)
        for error in sorted(validator.iter_errors(data), key=lambda item: list(item.path)):
            location = ".".join(str(part) for part in error.path) or "<root>"
            errors.append(f"{data_path.relative_to(ROOT)}:{location}: {error.message}")
    return errors


def validate_world_region_references() -> list[str]:
    errors: list[str] = []
    for path in sorted((ROOT / "resources/data/world_regions").glob("*.json")):
        region = load_json(path)
        node_ids = {node["id"] for node in region["nodes"]}
        province_ids = {province["id"] for province in region.get("provinces", [])}
        if len(node_ids) != len(region["nodes"]):
            errors.append(f"{path.relative_to(ROOT)}: duplicate node ids")
        if len(province_ids) != len(region.get("provinces", [])):
            errors.append(f"{path.relative_to(ROOT)}: duplicate province ids")
        roads: set[tuple[str, str]] = set()

        for edge in region["edges"]:
            road = tuple(sorted((edge["from"], edge["to"])))
            if edge["from"] == edge["to"] or road in roads:
                errors.append(f"{path.relative_to(ROOT)}: self or duplicate road {road}")
            roads.add(road)
            if edge["from"] not in node_ids:
                errors.append(f"{path.relative_to(ROOT)}: edge.from references missing node {edge['from']}")
            if edge["to"] not in node_ids:
                errors.append(f"{path.relative_to(ROOT)}: edge.to references missing node {edge['to']}")

        for node in region["nodes"]:
            if node.get("province") not in province_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing province for {node['id']}")
            if not ID_RE.match(node["entry_spec"]):
                errors.append(f"{path.relative_to(ROOT)}: invalid entry_spec {node['entry_spec']}")
        for province in region.get("provinces", []):
            if not any(node.get("province") == province["id"] for node in region["nodes"]):
                errors.append(f"{path.relative_to(ROOT)}: empty province {province['id']}")
            if not (ROOT / province["map"].removeprefix("res://")).is_file():
                errors.append(f"{path.relative_to(ROOT)}: missing province map {province['map']}")
        reachable = {node["id"] for node in region["nodes"] if node["type"] == "town"}
        while True:
            expanded = reachable | {b for a, b in roads if a in reachable} | {a for a, b in roads if b in reachable}
            if expanded == reachable:
                break
            reachable = expanded
        if node_ids - reachable:
            errors.append(f"{path.relative_to(ROOT)}: no town return for {sorted(node_ids - reachable)}")
    atlas_ids = {node["id"] for node in load_json(ROOT / "resources/data/world_regions/region_001.json")["nodes"]}
    for path in sorted((ROOT / "resources/data/world_simulations").glob("*.json")):
        errors.extend(f"{path.relative_to(ROOT)}: {message}" for message in living_reference_errors(load_json(path), atlas_ids, ROOT))
    return errors


def validate_dungeon_references() -> list[str]:
    errors: list[str] = []
    min_dungeon_combat_width = 10
    min_dungeon_combat_height = 8
    debuff_ids = _dungeon_debuff_ids()
    dungeon_events = _dungeon_event_templates()
    dungeon_event_pools = _dungeon_event_pools()
    dungeon_room_events = _dungeon_room_event_templates()
    dungeon_room_event_pools = _dungeon_room_event_pools()
    dungeon_combat_encounter_pools = _dungeon_combat_encounter_pools()
    errors.extend(validate_dungeon_event_pool_references(dungeon_events, dungeon_event_pools))
    errors.extend(validate_dungeon_room_event_pool_references(dungeon_room_events, dungeon_room_event_pools))
    errors.extend(validate_dungeon_combat_encounter_pool_references(dungeon_combat_encounter_pools))
    for path in sorted((ROOT / "resources/data/dungeons").glob("*.json")):
        dungeon = load_json(path)
        room_ids = {room["id"] for room in dungeon["rooms"]}
        if dungeon["start_room_id"] not in room_ids:
            errors.append(f"{path.relative_to(ROOT)}: start_room_id references missing room {dungeon['start_room_id']}")
        party_target_ids = {slot["target_id"] for slot in dungeon.get("default_party_formation", [])}
        for supply_id, option in dungeon.get("supply_loadout_options", {}).items():
            minimum = int(option["min"])
            maximum = int(option["max"])
            default = int(option["default"])
            if minimum > maximum:
                errors.append(f"{path.relative_to(ROOT)}: supply_loadout_options.{supply_id} min exceeds max")
            if default < minimum or default > maximum:
                errors.append(f"{path.relative_to(ROOT)}: supply_loadout_options.{supply_id} default is outside min/max")

        corridor_ids: set[str] = set()
        for corridor in dungeon["corridors"]:
            if corridor["id"] in corridor_ids:
                errors.append(f"{path.relative_to(ROOT)}: duplicate corridor id {corridor['id']}")
            corridor_ids.add(corridor["id"])
            if corridor["from"] not in room_ids:
                errors.append(f"{path.relative_to(ROOT)}: corridor {corridor['id']} from references missing room {corridor['from']}")
            if corridor["to"] not in room_ids:
                errors.append(f"{path.relative_to(ROOT)}: corridor {corridor['id']} to references missing room {corridor['to']}")
            for hazard_ref in corridor.get("hazard_refs", []):
                event_id = hazard_ref["event_id"]
                if event_id not in dungeon_events:
                    errors.append(f"{path.relative_to(ROOT)}: corridor {corridor['id']} references missing dungeon event {event_id}")
            for hazard_pool_ref in corridor.get("hazard_pool_refs", []):
                pool_id = hazard_pool_ref["pool_id"]
                if pool_id not in dungeon_event_pools:
                    errors.append(f"{path.relative_to(ROOT)}: corridor {corridor['id']} references missing dungeon event pool {pool_id}")
            for hazard in list(corridor.get("hazards", [])) + [
                _materialized_hazard_for_validator(hazard_ref, dungeon_events)
                for hazard_ref in corridor.get("hazard_refs", [])
            ] + [
                _materialized_pool_hazard_for_validator(hazard_pool_ref, dungeon_event_pools, dungeon_events)
                for hazard_pool_ref in corridor.get("hazard_pool_refs", [])
            ]:
                if not hazard:
                    continue
                for outcome in hazard.get("outcomes", []):
                    for consequence in outcome.get("consequences", []):
                        target_id = consequence.get("target_id", "")
                        if target_id and target_id != "party_member_0" and target_id not in party_target_ids:
                            errors.append(
                                f"{path.relative_to(ROOT)}: corridor {corridor['id']} hazard {hazard['id']} "
                                f"references missing party target {target_id}"
                            )
                        if consequence.get("type") == "apply_debuff":
                            debuff_id = consequence.get("debuff_id", "")
                            if debuff_id not in debuff_ids:
                                errors.append(
                                    f"{path.relative_to(ROOT)}: corridor {corridor['id']} hazard {hazard['id']} "
                                    f"references missing dungeon debuff {debuff_id}"
                                )

        for room in dungeon["rooms"]:
            for content in room["content"]:
                content_type = content["type"]
                encounter_path = content.get("combat_encounter_path")
                rewards = content.get("rewards")
                if content_type in {"combat", "guarded_treasure"}:
                    pool_id = content.get("combat_encounter_pool_id", "")
                    if pool_id and pool_id not in dungeon_combat_encounter_pools:
                        errors.append(f"{path.relative_to(ROOT)}: room {room['id']} references missing combat encounter pool {pool_id}")
                    if not encounter_path:
                        if not pool_id:
                            errors.append(f"{path.relative_to(ROOT)}: room {room['id']} {content_type} content is missing combat_encounter_path or combat_encounter_pool_id")
                    else:
                        resolved = ROOT / str(encounter_path).removeprefix("res://")
                        if not resolved.exists():
                            errors.append(f"{path.relative_to(ROOT)}: room {room['id']} references missing encounter {encounter_path}")
                        else:
                            encounter = load_json(resolved)
                            if resolved.name.startswith("slice_") or str(encounter.get("id", "")).startswith("slice_"):
                                errors.append(
                                    f"{path.relative_to(ROOT)}: room {room['id']} references regression slice encounter {encounter_path}; "
                                    "dungeon rooms must use presentation-ready combat encounters"
                                )
                            if not encounter.get("background_path"):
                                errors.append(
                                    f"{path.relative_to(ROOT)}: room {room['id']} encounter {encounter_path} is missing background_path"
                                )
                            width, height = _combat_encounter_dimensions(encounter)
                            if width < min_dungeon_combat_width or height < min_dungeon_combat_height:
                                errors.append(
                                    f"{path.relative_to(ROOT)}: room {room['id']} encounter {encounter_path} board is {width}x{height}; "
                                    f"dungeon combat must be at least {min_dungeon_combat_width}x{min_dungeon_combat_height}"
                                )
                if content_type == "guarded_treasure" and rewards is None:
                    errors.append(f"{path.relative_to(ROOT)}: room {room['id']} guarded_treasure content is missing rewards")
                if content_type == "treasure" and rewards is None:
                    errors.append(f"{path.relative_to(ROOT)}: room {room['id']} treasure content is missing rewards")
                if content_type == "room_event":
                    event_id = content.get("event_id", "")
                    pool_id = content.get("room_event_pool_id", "")
                    if bool(event_id) == bool(pool_id):
                        errors.append(f"{path.relative_to(ROOT)}: room {room['id']} room_event content must define exactly one of event_id or room_event_pool_id")
                    if event_id and event_id not in dungeon_room_events:
                        errors.append(f"{path.relative_to(ROOT)}: room {room['id']} references missing room event {event_id}")
                    if pool_id and pool_id not in dungeon_room_event_pools:
                        errors.append(f"{path.relative_to(ROOT)}: room {room['id']} references missing room event pool {pool_id}")
    return errors


def validate_dungeon_event_pool_references(dungeon_events: dict[str, dict], dungeon_event_pools: dict[str, dict]) -> list[str]:
    errors: list[str] = []
    for pool_id, pool in dungeon_event_pools.items():
        danger_min = pool.get("danger_min", 0.0)
        danger_max = pool.get("danger_max", 1.0)
        if danger_min > danger_max:
            errors.append(f"resources/data/dungeon_event_pools: pool {pool_id} has danger_min greater than danger_max")
        for entry in pool.get("entries", []):
            event_id = entry.get("event_id", "")
            if event_id not in dungeon_events:
                errors.append(f"resources/data/dungeon_event_pools: pool {pool_id} references missing dungeon event {event_id}")
    return errors


def validate_dungeon_room_event_pool_references(dungeon_room_events: dict[str, dict], dungeon_room_event_pools: dict[str, dict]) -> list[str]:
    errors: list[str] = []
    for pool_id, pool in dungeon_room_event_pools.items():
        for entry in pool.get("entries", []):
            event_id = entry.get("event_id", "")
            if event_id not in dungeon_room_events:
                errors.append(f"resources/data/dungeon_room_event_pools: pool {pool_id} references missing room event {event_id}")
    return errors


def validate_dungeon_combat_encounter_pool_references(dungeon_combat_encounter_pools: dict[str, dict]) -> list[str]:
    errors: list[str] = []
    min_dungeon_combat_width = 10
    min_dungeon_combat_height = 8
    for pool_id, pool in dungeon_combat_encounter_pools.items():
        for entry in pool.get("entries", []):
            if int(entry.get("difficulty_min", 1)) > int(entry.get("difficulty_max", 3)):
                errors.append(f"resources/data/dungeon_combat_encounter_pools: pool {pool_id} entry {entry.get('id', '')} difficulty_min exceeds difficulty_max")
            encounter_path = entry.get("encounter_path", "")
            resolved = ROOT / str(encounter_path).removeprefix("res://")
            if not resolved.exists():
                errors.append(f"resources/data/dungeon_combat_encounter_pools: pool {pool_id} entry {entry.get('id', '')} references missing encounter {encounter_path}")
                continue
            encounter = load_json(resolved)
            if resolved.name.startswith("slice_") or str(encounter.get("id", "")).startswith("slice_"):
                errors.append(
                    f"resources/data/dungeon_combat_encounter_pools: pool {pool_id} entry {entry.get('id', '')} "
                    f"references regression slice encounter {encounter_path}"
                )
            if not encounter.get("background_path"):
                errors.append(f"resources/data/dungeon_combat_encounter_pools: pool {pool_id} entry {entry.get('id', '')} encounter is missing background_path")
            width, height = _combat_encounter_dimensions(encounter)
            if width < min_dungeon_combat_width or height < min_dungeon_combat_height:
                errors.append(
                    f"resources/data/dungeon_combat_encounter_pools: pool {pool_id} entry {entry.get('id', '')} "
                    f"encounter board is {width}x{height}; dungeon combat must be at least {min_dungeon_combat_width}x{min_dungeon_combat_height}"
                )
    return errors


def _materialized_pool_hazard_for_validator(hazard_pool_ref: dict, dungeon_event_pools: dict[str, dict], dungeon_events: dict[str, dict]) -> dict:
    pool = dungeon_event_pools.get(hazard_pool_ref.get("pool_id", ""), {})
    if not pool:
        return {}
    entries = pool.get("entries", [])
    if not entries:
        return {}
    event_id = entries[0].get("event_id", "")
    event = dungeon_events.get(event_id, {})
    if not event:
        return {}
    hazard = copy.deepcopy(event)
    hazard["id"] = hazard_pool_ref.get("id", hazard.get("id", ""))
    hazard["trigger"] = hazard_pool_ref.get("trigger", {"mode": "first_traversal"})
    return hazard


def _materialized_hazard_for_validator(hazard_ref: dict, dungeon_events: dict[str, dict]) -> dict:
    event = dungeon_events.get(hazard_ref.get("event_id", ""), {})
    if not event:
        return {}
    hazard = copy.deepcopy(event)
    hazard["id"] = hazard_ref.get("id", hazard.get("id", ""))
    hazard["trigger"] = hazard_ref.get("trigger", {"mode": "first_traversal"})
    return hazard


def _dungeon_event_templates() -> dict[str, dict]:
    events: dict[str, dict] = {}
    for path in sorted((ROOT / "resources/data/dungeon_events").glob("*.json")):
        catalogue = load_json(path)
        for event in catalogue.get("events", []):
            event_id = event["id"]
            if event_id in events:
                continue
            events[event_id] = event
    return events


def _dungeon_event_pools() -> dict[str, dict]:
    pools: dict[str, dict] = {}
    for path in sorted((ROOT / "resources/data/dungeon_event_pools").glob("*.json")):
        catalogue = load_json(path)
        for pool in catalogue.get("pools", []):
            pool_id = pool["id"]
            if pool_id in pools:
                continue
            pools[pool_id] = pool
    return pools


def _dungeon_room_event_templates() -> dict[str, dict]:
    events: dict[str, dict] = {}
    for path in sorted((ROOT / "resources/data/dungeon_room_events").glob("*.json")):
        catalogue = load_json(path)
        for event in catalogue.get("events", []):
            event_id = event["id"]
            if event_id in events:
                continue
            events[event_id] = event
    return events


def _dungeon_room_event_pools() -> dict[str, dict]:
    pools: dict[str, dict] = {}
    for path in sorted((ROOT / "resources/data/dungeon_room_event_pools").glob("*.json")):
        catalogue = load_json(path)
        for pool in catalogue.get("pools", []):
            pool_id = pool["id"]
            if pool_id in pools:
                continue
            pools[pool_id] = pool
    return pools


def _dungeon_combat_encounter_pools() -> dict[str, dict]:
    pools: dict[str, dict] = {}
    for path in sorted((ROOT / "resources/data/dungeon_combat_encounter_pools").glob("*.json")):
        catalogue = load_json(path)
        for pool in catalogue.get("pools", []):
            pool_id = pool["id"]
            if pool_id in pools:
                continue
            pools[pool_id] = pool
    return pools


def _dungeon_debuff_ids() -> set[str]:
    debuff_ids: set[str] = set()
    for path in sorted((ROOT / "resources/data/dungeon_debuffs").glob("*.json")):
        data = load_json(path)
        for debuff in data["debuffs"]:
            debuff_ids.add(debuff["id"])
    return debuff_ids


def validate_dungeon_debuff_references() -> list[str]:
    errors: list[str] = []
    seen: set[str] = set()
    for path in sorted((ROOT / "resources/data/dungeon_debuffs").glob("*.json")):
        data = load_json(path)
        for debuff in data["debuffs"]:
            debuff_id = debuff["id"]
            if debuff_id in seen:
                errors.append(f"{path.relative_to(ROOT)}: duplicate dungeon debuff id {debuff_id}")
            seen.add(debuff_id)
    return errors


def _combat_encounter_dimensions(encounter: dict) -> tuple[int, int]:
    if "grid" in encounter:
        grid = encounter["grid"]
        return int(grid["width"]), int(grid["height"])
    map_path = encounter.get("map_path")
    if map_path:
        map_data = load_json(ROOT / str(map_path).removeprefix("res://"))
        return int(map_data["width"]), int(map_data["height"])
    return 0, 0


def validate_map_integrity() -> list[str]:
    errors: list[str] = []
    for path in sorted((ROOT / "resources/data/maps").glob("*.json")):
        map_data = load_json(path)
        source_path = ROOT / str(map_data["source"]).removeprefix("res://")
        if not source_path.exists():
            errors.append(f"{path.relative_to(ROOT)}: source TMX does not exist: {map_data['source']}")
        else:
            try:
                exported = convert_tmx(source_path)
                if exported != map_data:
                    errors.append(f"{path.relative_to(ROOT)}: JSON is not in sync with {source_path.relative_to(ROOT)}")
            except (ValueError, OSError) as error:
                errors.append(f"{path.relative_to(ROOT)}: TMX conversion failed: {error}")
        width = int(map_data["width"])
        height = int(map_data["height"])
        tiles = map_data["tiles"]
        if len(tiles) != width * height:
            errors.append(f"{path.relative_to(ROOT)}: expected {width * height} tiles, found {len(tiles)}")

        occupied: set[tuple[int, int]] = set()
        blocked: set[tuple[int, int]] = set()
        for tile in tiles:
            position = (int(tile["x"]), int(tile["y"]))
            if position in occupied:
                errors.append(f"{path.relative_to(ROOT)}: duplicate tile at {position}")
            occupied.add(position)
            if not (0 <= position[0] < width and 0 <= position[1] < height):
                errors.append(f"{path.relative_to(ROOT)}: tile out of bounds at {position}")
            if tile["type"] == "blocked":
                blocked.add(position)

        for y in range(height):
            for x in range(width):
                if (x, y) not in occupied:
                    errors.append(f"{path.relative_to(ROOT)}: missing tile at {(x, y)}")

        for spawn in map_data["test_spawns"]:
            position = (int(spawn["x"]), int(spawn["y"]))
            if not (0 <= position[0] < width and 0 <= position[1] < height):
                errors.append(f"{path.relative_to(ROOT)}: spawn {spawn['id']} out of bounds at {position}")
            if position in blocked:
                errors.append(f"{path.relative_to(ROOT)}: spawn {spawn['id']} is on blocked tile {position}")
    return errors


def validate_combat_map_references() -> list[str]:
    errors: list[str] = []
    for path in sorted((ROOT / "resources/data/combat_encounters").glob("*.json")):
        encounter = load_json(path)
        map_path = encounter.get("map_path")
        if not map_path:
            continue

        resolved_map_path = ROOT / str(map_path).removeprefix("res://")
        if not resolved_map_path.exists():
            errors.append(f"{path.relative_to(ROOT)}: map_path does not exist: {map_path}")
            continue

        map_data = load_json(resolved_map_path)
        referenced_grid = {
            "width": map_data["width"],
            "height": map_data["height"],
            "tiles": map_data["tiles"],
        }
        if "grid" in encounter and encounter["grid"] != referenced_grid:
            errors.append(f"{path.relative_to(ROOT)}: inline grid conflicts with referenced map_path {map_path}")

        width = int(map_data["width"])
        height = int(map_data["height"])
        blocked = {
            (int(tile["x"]), int(tile["y"]))
            for tile in map_data["tiles"]
            if tile["type"] == "blocked"
        }
        for unit in encounter["units"]:
            position = unit["position"]
            point = (int(position["x"]), int(position["y"]))
            if not (0 <= point[0] < width and 0 <= point[1] < height):
                errors.append(f"{path.relative_to(ROOT)}: unit {unit['id']} spawn out of referenced map bounds at {point}")
            if point in blocked:
                errors.append(f"{path.relative_to(ROOT)}: unit {unit['id']} spawn is on blocked referenced map tile {point}")
    return errors


def validate_campaign_items(data: dict | None = None) -> list[str]:
    data = load_json(ROOT / "resources/data/items/catalogue.json") if data is None else data
    errors: list[str] = []
    schema = load_json(ROOT / "resources/schemas/combat_encounter.schema.json")
    profile_validator = Draft202012Validator(schema["properties"]["item_profiles"]["additionalProperties"])
    actions = {load_json(path)["id"] for path in (ROOT / "resources/data/combat_actions").glob("*.json")}
    # Existing skill actions are resolver-owned, not standalone combat_action files.
    actions |= {"aimed_shot", "power_strike", "deep_cut", "guard_break", "shield_wall"}
    seen: set[str] = set()
    for row in data.get("items", []):
        item_id = row.get("id")
        if item_id in seen:
            errors.append(f"Duplicate campaign item {item_id}")
        seen.add(item_id)
        profile = row.get("combat_profile")
        if row.get("category") != "equipment":
            continue
        if not isinstance(profile, dict):
            errors.append(f"{item_id}: missing combat profile")
            continue
        errors.extend(f"{item_id}: {error.message}" for error in profile_validator.iter_errors(profile))
        if profile.get("id") != item_id:
            errors.append(f"{item_id}: combat profile id differs")
        for action in profile.get("grants_actions", []):
            if action not in actions:
                errors.append(f"{item_id}: unknown action {action}")
        for action, values in profile.get("action_profiles", {}).items():
            if action not in profile.get("grants_actions", []) or values.get("action_id") != action:
                errors.append(f"{item_id}: mismatched action profile {action}")
    return errors


def validate_town_trade(data: dict | None = None) -> list[str]:
    data = load_json(ROOT / "resources/data/town_trade/ravenford.json") if data is None else data
    schema = load_json(ROOT / "resources/schemas/town_trade.schema.json")
    errors = [f"Town trade: {error.message}" for error in Draft202012Validator(schema).iter_errors(data)]
    if errors:
        return errors
    town_path = ROOT / f"resources/data/towns/{data['town_id']}.json"
    if not town_path.is_file():
        errors.append("Town trade references missing town")
    items = {row['id']: row for row in load_json(ROOT / "resources/data/items/catalogue.json")['items']}
    seen: set[str] = set()
    for offer in data['offers']:
        item_id = offer['item_id']
        if item_id in seen:
            errors.append(f"Duplicate trade offer {item_id}")
        seen.add(item_id)
        item = items.get(item_id, {})
        if item.get('category') != 'equipment':
            errors.append(f"Trade offer must reference known equipment: {item_id}")
        if offer['buy_price'] <= item.get('value', 0):
            errors.append(f"Trade offer price must exceed resale value: {item_id}")
    return errors


def validate_party_levels(data: dict | None = None) -> list[str]:
    data = load_json(ROOT / "resources/data/progression/party_levels.json") if data is None else data
    errors = [str(error.message) for error in Draft202012Validator(load_json(ROOT / "resources/schemas/party_levels.schema.json")).iter_errors(data)]
    if errors:
        return errors
    if [row['level'] for row in data['levels']] != [1, 2, 3, 4]:
        errors.append('Party levels must be sequential and unique')
    if data['levels'][0]['cost'] != 0 or data['levels'][0]['bonuses']:
        errors.append('Level1 must preserve baseline stats and cost zero')
    prior: dict = {}
    for row in data['levels'][1:]:
        if row['cost'] < 1 or any(row['bonuses'].get(key, 0) < value for key, value in prior.items()):
            errors.append('Training costs must be positive and cumulative bonuses nondecreasing')
        prior = row['bonuses']
    return errors


def main() -> int:
    errors: list[str] = []
    errors.extend(catalogue_errors())
    errors.extend(dungeon_quality_errors())
    errors.extend(combat_authoring_errors())
    errors.extend(validate_campaign_items())
    errors.extend(hero_identity_errors(ROOT))
    errors.extend(tactical_roster_errors(ROOT))
    errors.extend(town_space_errors(ROOT))
    errors.extend(validate_town_trade())
    errors.extend(validate_party_levels())
    for path in sorted((ROOT / "resources/data/strategy_worlds").glob("*.json")):
        errors.extend(f"{path.relative_to(ROOT)}: {error}" for error in strategy_reference_errors(load_json(path)))
    for path in sorted((ROOT / "resources/data/strategy_simulations").glob("*.json")):
        errors.extend(f"{path.relative_to(ROOT)}: {error}" for error in classic_configuration_errors(load_json(path)))
    for path in sorted((ROOT / "resources/data/strategy_snapshots").glob("*.json")):
        errors.extend(f"{path.relative_to(ROOT)}: {error}" for error in classic_reference_errors(load_json(path)))
    for path in sorted((ROOT / "resources/data/strategy_regions").glob("*.json")):
        errors.extend(f"{path.relative_to(ROOT)}: {error}" for error in region_rules_errors(load_json(path)))
    for path in sorted((ROOT / "resources/data/strategic_regions").glob("*.json")):
        errors.extend(f"{path.relative_to(ROOT)}: {error}" for error in strategic_reference_errors(load_json(path)))
    for path in sorted((ROOT / "resources/data/strategist_campaigns").glob("*.json")):
        errors.extend(f"{path.relative_to(ROOT)}: {error}" for error in model_reference_errors(load_json(path)))
    for path in sorted((ROOT / "resources/data/strategist_requests").glob("*.json")):
        errors.extend(f"{path.relative_to(ROOT)}: {error}" for error in model_request_errors(load_json(path)))
    for path in sorted((ROOT / "resources/data/strategist_replies").glob("*.json")):
        request=ROOT/'resources/data/strategist_requests'/path.name
        errors.extend(f"{path.relative_to(ROOT)}: {error}" for error in model_reply_errors(load_json(request),load_json(path)))
    for path in sorted((ROOT / "resources/data/strategist_replays").glob("*.json")):
        errors.extend(f"{path.relative_to(ROOT)}: {error}" for error in model_replay_errors(load_json(path)))

    road = load_json(ROOT / "resources/data/world_events/catalogue.json")
    road_path = ROOT / road["ambush"]["encounter_path"].removeprefix("res://")
    if not road_path.is_file():
        errors.append("Missing road ambush encounter")
    else:
        errors.extend(encounter_errors(load_json(road_path)))

    for schema_rel, data_glob in VALIDATION_TARGETS:
        schema_path = ROOT / schema_rel
        data_paths = sorted(ROOT.glob(data_glob))
        if not data_paths:
            errors.append(f"No data files matched {data_glob}")
            continue
        errors.extend(validate_schema(schema_path, data_paths))

    errors.extend(validate_world_region_references())
    errors.extend(validate_dungeon_references())
    errors.extend(validate_dungeon_debuff_references())
    errors.extend(validate_map_integrity())
    errors.extend(validate_combat_map_references())
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
    errors.extend(validate_combat_slice_63())
    errors.extend(validate_combat_slice_64())
    errors.extend(validate_combat_slice_65())
    errors.extend(validate_combat_slice_66())
    errors.extend(validate_combat_slice_77())
    errors.extend(validate_combat_slice_78())
    errors.extend(validate_combat_slice_79())
    errors.extend(validate_combat_slice_80())
    errors.extend(validate_combat_slice_81())
    errors.extend(validate_combat_slice_82())

    if errors:
        print("Validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
