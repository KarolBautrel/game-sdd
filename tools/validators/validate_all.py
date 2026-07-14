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
)


ID_RE = re.compile(r"^[a-z0-9_]+$")

VALIDATION_TARGETS = [
    ("resources/schemas/world_region.schema.json", "resources/data/world_regions/*.json"),
    ("resources/schemas/town.schema.json", "resources/data/towns/*.json"),
    ("resources/schemas/dungeon.schema.json", "resources/data/dungeons/*.json"),
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

    if errors:
        print("Validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
