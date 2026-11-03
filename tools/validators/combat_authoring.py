"""Reference integrity for data-discovered playable combat encounters."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOGUE = "resources/data/combat_scenarios/catalogue.json"
PATH_PATTERN = re.compile(r"^res://resources/data/combat_encounters/[a-z0-9_]+\.json$")


def resource_path(value: str, root: Path) -> Path:
    if not isinstance(value, str) or not value.startswith("res://"):
        raise ValueError("Expected a res:// resource path")
    target = (root / value.removeprefix("res://")).resolve()
    if not target.is_relative_to(root.resolve()):
        raise ValueError("Resource path escapes project")
    return target


def encounter_errors(data: dict, root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    grid = data.get("grid", {})
    visual = data.copy()
    if data.get("map_path"):
        try:
            mapped = json.loads(resource_path(data["map_path"], root).read_text(encoding="utf-8"))
            grid = mapped
            visual = mapped | data
        except (OSError, ValueError, TypeError) as exc:
            return [f"Invalid map reference: {exc}"]
    width, height = int(grid.get("width", 0)), int(grid.get("height", 0))
    if width < 1 or height < 1:
        return ["Missing/invalid encounter grid"]
    blocked = {(int(t["x"]), int(t["y"])) for t in grid.get("tiles", []) if t.get("type") == "blocked"}
    ids, occupied = set(), set()
    living_teams = set()
    archetypes = data.get("enemy_archetypes", {})
    items = data.get("item_profiles", {})
    weapons = data.get("weapon_profiles", {})
    for unit in data.get("units", []):
        ident = unit.get("id", "")
        if not ident or ident in ids:
            errors.append(f"Duplicate/missing unit id: {ident}")
        ids.add(ident)
        pos = unit.get("position", {})
        point = (int(pos.get("x", -1)), int(pos.get("y", -1)))
        if point in occupied:
            errors.append(f"Overlapping unit starts: {ident}")
        occupied.add(point)
        if not (0 <= point[0] < width and 0 <= point[1] < height) or point in blocked:
            errors.append(f"Invalid/blocked unit start: {ident}")
        if unit.get("resources", {}).get("hp", 0) > 0:
            living_teams.add(unit.get("team"))
        archetype_id = unit.get("archetype_id", "")
        if archetype_id and archetype_id not in archetypes:
            errors.append(f"Unknown archetype: {archetype_id}")
        archetype = archetypes.get(archetype_id, {})
        loadout = archetype.get("loadout", {}) | unit.get("loadout", {})
        for item in loadout.values():
            if item is not None and item not in items:
                errors.append(f"Unknown loadout item: {item}")
        weapon = unit.get("equipped_weapon_id", archetype.get("equipped_weapon_id"))
        if weapon is not None and weapon not in weapons:
            errors.append(f"Unknown equipped weapon: {weapon}")
    if living_teams != {"player", "enemy"}:
        errors.append("Encounter needs living player and enemy units")
    turn = data.get("turn_state", {})
    order = turn.get("turn_order", [])
    if len(order) != len(set(order)) or set(order) != ids or turn.get("active_unit_id") not in ids:
        errors.append("Invalid turn order/active unit references")
    paths = [visual.get("background_path")] + [d.get("path") for d in visual.get("terrain_decorations", [])]
    for path in filter(None, paths):
        try:
            if not resource_path(path, root).is_file():
                errors.append(f"Missing visual resource: {path}")
        except ValueError as exc:
            errors.append(str(exc))
    return errors


def catalogue_errors(data: dict | None = None, root: Path = ROOT) -> list[str]:
    if data is None:
        try:
            data = json.loads((root / CATALOGUE).read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            return [f"Invalid combat catalogue: {exc}"]
    if not isinstance(data, dict) or data.get("schema") != "sdd.combat-scenarios-v1" or not isinstance(data.get("scenarios"), list) or not data["scenarios"]:
        return ["Invalid combat catalogue shape"]
    errors, ids = [], set()
    for row in data["scenarios"]:
        if not isinstance(row, dict) or not isinstance(row.get("id"), str) or not row["id"] or not isinstance(row.get("label"), str) or not row["label"].strip():
            errors.append("Invalid combat catalogue entry")
            continue
        ident = row["id"]
        if ident in ids:
            errors.append(f"Duplicate scenario id: {ident}")
        ids.add(ident)
        path = row.get("path", "")
        if not isinstance(path, str) or not PATH_PATTERN.fullmatch(path):
            errors.append(f"Invalid scenario path: {path}")
            continue
        try:
            encounter = json.loads(resource_path(path, root).read_text(encoding="utf-8"))
            errors.extend(f"{ident}: {error}" for error in encounter_errors(encounter, root))
        except (OSError, ValueError, KeyError, TypeError) as exc:
            errors.append(f"{ident}: invalid encounter reference: {exc}")
    return errors
