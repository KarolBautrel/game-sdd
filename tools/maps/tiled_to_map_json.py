from __future__ import annotations

import argparse
import json
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TILE_TYPES = {"floor", "blocked", "highground", "cover_low"}


def _repo_path(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def _properties(element: ET.Element) -> dict[str, str]:
    result: dict[str, str] = {}
    properties = element.find("properties")
    if properties is None:
        return result
    for prop in properties.findall("property"):
        name = prop.get("name")
        value = prop.get("value")
        if name is not None and value is not None:
            result[name] = value
    return result


def _load_tileset_types(tmx_path: Path, tileset_element: ET.Element) -> dict[int, str]:
    first_gid = int(tileset_element.get("firstgid", "1"))
    source = tileset_element.get("source")
    if source is None:
        raise ValueError("Only external TSX tilesets are supported for map conversion.")

    tsx_path = (tmx_path.parent / source).resolve()
    tsx_root = ET.parse(tsx_path).getroot()
    gid_to_type: dict[int, str] = {}
    for tile in tsx_root.findall("tile"):
        tile_id = int(tile.get("id", "0"))
        tile_type = _properties(tile).get("type", "floor")
        if tile_type not in TILE_TYPES:
            raise ValueError(f"{tsx_path}: unsupported tile type {tile_type!r}")
        gid_to_type[first_gid + tile_id] = tile_type
    return gid_to_type


def _csv_values(layer: ET.Element) -> list[int]:
    data = layer.find("data")
    if data is None or data.get("encoding") != "csv" or data.text is None:
        raise ValueError("Only CSV tile layer data is supported for map conversion.")
    values: list[int] = []
    for chunk in data.text.replace("\n", ",").split(","):
        chunk = chunk.strip()
        if chunk:
            values.append(int(chunk))
    return values


def convert_tmx(tmx_path: Path) -> dict:
    map_root = ET.parse(tmx_path).getroot()
    width = int(map_root.get("width", "0"))
    height = int(map_root.get("height", "0"))
    tile_width = int(map_root.get("tilewidth", "0"))
    tile_height = int(map_root.get("tileheight", "0"))
    if tile_width != tile_height:
        raise ValueError("Only square map tiles are supported.")

    map_props = _properties(map_root)
    map_id = map_props.get("id", tmx_path.stem)

    gid_to_type: dict[int, str] = {}
    for tileset in map_root.findall("tileset"):
        gid_to_type.update(_load_tileset_types(tmx_path, tileset))

    terrain_layer = None
    for layer in map_root.findall("layer"):
        if layer.get("name") == "terrain":
            terrain_layer = layer
            break
    if terrain_layer is None:
        raise ValueError("Map must contain a tile layer named 'terrain'.")

    gids = _csv_values(terrain_layer)
    expected = width * height
    if len(gids) != expected:
        raise ValueError(f"Terrain layer has {len(gids)} tiles, expected {expected}.")

    tiles: list[dict] = []
    for index, gid in enumerate(gids):
        x = index % width
        y = index // width
        tile_type = gid_to_type.get(gid)
        if tile_type is None:
            raise ValueError(f"Missing tile type for gid {gid} at ({x},{y}).")
        tiles.append({"x": x, "y": y, "type": tile_type})

    spawns: list[dict] = []
    for objectgroup in map_root.findall("objectgroup"):
        if objectgroup.get("name") != "test_spawns":
            continue
        for obj in objectgroup.findall("object"):
            spawns.append(
                {
                    "id": obj.get("name", f"spawn_{obj.get('id', 'unknown')}"),
                    "role": obj.get("type", "unknown"),
                    "x": int(float(obj.get("x", "0")) // tile_width),
                    "y": int(float(obj.get("y", "0")) // tile_height),
                }
            )

    return {
        "id": map_id,
        "source": f"res://{_repo_path(tmx_path)}",
        "tile_size": tile_width,
        "width": width,
        "height": height,
        "tiles": tiles,
        "test_spawns": spawns,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert a Tiled TMX map into SDD map JSON.")
    parser.add_argument("tmx", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    map_data = convert_tmx(args.tmx)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(map_data, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
