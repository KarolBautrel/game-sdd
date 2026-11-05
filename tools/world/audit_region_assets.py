"""Verify the editable Aseprite exports and record region-art provenance."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SOURCE = "assets_src/region_symbols/2026-11-04/"
RUNTIME = ("assets/ui/world/region_symbols.png", "assets/ui/world/ground_wash.png")
FILES = (
    SOURCE + "generated-source.png", SOURCE + "ground-wash-source.png",
    SOURCE + "prompts.json", SOURCE + "ground-prompt.json",
    "assets_src/aseprite/region_symbols/region_symbols.aseprite",
    "assets_src/aseprite/region_symbols/ground_wash.aseprite",
    *RUNTIME, "tools/aseprite/region_symbols.lua",
)


def digest(relative):
    return hashlib.sha256((ROOT / relative).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--export", action="store_true")
    parser.add_argument("--write-manifest", action="store_true")
    parser.add_argument("--aseprite", default="C:/Program Files/Aseprite/Aseprite.exe")
    args = parser.parse_args()
    before = {path: digest(path) for path in RUNTIME}
    if args.export:
        subprocess.run([args.aseprite, "-b", "--script-param", "root=" + ROOT.as_posix(),
                        "--script-param", "from_editable=1", "--script",
                        str(ROOT / "tools/aseprite/region_symbols.lua")], check=True, timeout=60)
        if before != {path: digest(path) for path in RUNTIME}:
            raise SystemExit("Editable exports differ from the approved runtime PNGs")
    manifest = {"schema": "sdd.region-art-provenance-v1", "generator": "builtin imagegen",
                "normalization": "Aseprite Lua", "files": [
                    {"path": path, "sha256": digest(path)} for path in FILES]}
    destination = ROOT / SOURCE / "manifest.json"
    if args.write_manifest:
        destination.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    elif json.loads(destination.read_text(encoding="utf-8")) != manifest:
        raise SystemExit("Art provenance manifest differs")
    print("PASS:9 provenance hashes; editable export byte equality" if args.export else "PASS:9 provenance hashes")


if __name__ == "__main__":
    main()
