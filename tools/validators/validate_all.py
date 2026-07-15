from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

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


ID_RE = re.compile(r"^[a-z0-9_]+$")

VALIDATION_TARGETS = [
    ("resources/schemas/world_region.schema.json", "resources/data/world_regions/*.json"),
    ("resources/schemas/town.schema.json", "resources/data/towns/*.json"),
    ("resources/schemas/dungeon.schema.json", "resources/data/dungeons/*.json"),
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

        for edge in region["edges"]:
            if edge["from"] not in node_ids:
                errors.append(f"{path.relative_to(ROOT)}: edge.from references missing node {edge['from']}")
            if edge["to"] not in node_ids:
                errors.append(f"{path.relative_to(ROOT)}: edge.to references missing node {edge['to']}")

        for node in region["nodes"]:
            if not ID_RE.match(node["entry_spec"]):
                errors.append(f"{path.relative_to(ROOT)}: invalid entry_spec {node['entry_spec']}")
    return errors


def validate_dungeon_references() -> list[str]:
    errors: list[str] = []
    min_dungeon_combat_width = 10
    min_dungeon_combat_height = 8
    for path in sorted((ROOT / "resources/data/dungeons").glob("*.json")):
        dungeon = load_json(path)
        room_ids = {room["id"] for room in dungeon["rooms"]}
        if dungeon["start_room_id"] not in room_ids:
            errors.append(f"{path.relative_to(ROOT)}: start_room_id references missing room {dungeon['start_room_id']}")

        corridor_ids: set[str] = set()
        for corridor in dungeon["corridors"]:
            if corridor["id"] in corridor_ids:
                errors.append(f"{path.relative_to(ROOT)}: duplicate corridor id {corridor['id']}")
            corridor_ids.add(corridor["id"])
            if corridor["from"] not in room_ids:
                errors.append(f"{path.relative_to(ROOT)}: corridor {corridor['id']} from references missing room {corridor['from']}")
            if corridor["to"] not in room_ids:
                errors.append(f"{path.relative_to(ROOT)}: corridor {corridor['id']} to references missing room {corridor['to']}")

        for room in dungeon["rooms"]:
            for content in room["content"]:
                content_type = content["type"]
                encounter_path = content.get("combat_encounter_path")
                rewards = content.get("rewards")
                if content_type in {"combat", "guarded_treasure"}:
                    if not encounter_path:
                        errors.append(f"{path.relative_to(ROOT)}: room {room['id']} {content_type} content is missing combat_encounter_path")
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
            exported = convert_tmx(source_path)
            if exported != map_data:
                errors.append(f"{path.relative_to(ROOT)}: JSON is not in sync with {source_path.relative_to(ROOT)}")
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


def main() -> int:
    errors: list[str] = []

    for schema_rel, data_glob in VALIDATION_TARGETS:
        schema_path = ROOT / schema_rel
        data_paths = sorted(ROOT.glob(data_glob))
        if not data_paths:
            errors.append(f"No data files matched {data_glob}")
            continue
        errors.extend(validate_schema(schema_path, data_paths))

    errors.extend(validate_world_region_references())
    errors.extend(validate_dungeon_references())
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
