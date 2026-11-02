"""Build or verify the deterministic runtime PNG catalogue (standard library only)."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
CATALOGUE = Path("resources/catalogues/textures.json")


def build_catalogue(root: Path) -> dict:
    entries = []
    for path in sorted((root / "assets").rglob("*.png")):
        data = path.read_bytes()
        if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
            raise ValueError(f"Invalid PNG header: {path.relative_to(root)}")
        width, height = struct.unpack(">II", data[16:24])
        if not width or not height:
            raise ValueError(f"Invalid PNG dimensions: {path.relative_to(root)}")
        entries.append({"path": "res://" + path.relative_to(root).as_posix(),
                        "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
                        "width": width, "height": height})
    if not entries:
        raise ValueError("No PNG assets found")
    return {"schema": "sdd.texture-catalogue-v1", "textures": entries}


def catalogue_errors(root: Path = ROOT) -> list[str]:
    try:
        actual = json.loads((root / CATALOGUE).read_text(encoding="utf-8"))
        expected = build_catalogue(root)
    except (OSError, ValueError) as error:
        return [f"Texture catalogue: {error}"]
    return [] if actual == expected else ["Texture catalogue is stale: run python tools/assets/build_catalogue.py"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        errors = catalogue_errors()
        for error in errors:
            print(error)
        if not errors:
            print("Texture catalogue matches source assets.")
        return int(bool(errors))
    catalogue = build_catalogue(ROOT)
    target = ROOT / CATALOGUE
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(catalogue, indent=2) + "\n", encoding="utf-8")
    print(f"Catalogued {len(catalogue['textures'])} PNG textures.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
