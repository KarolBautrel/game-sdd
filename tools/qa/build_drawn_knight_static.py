"""Reproduce the authorized static knight exports with background Aseprite."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets_src/characters/drawn_knight/2026-11-03"
SOURCE = ROOT / "assets_src/aseprite/characters/drawn_knight/2026-11-03"
ASEPRITE = Path("C:/Program Files/Aseprite/Aseprite.exe")


def main():
    command = [str(ASEPRITE), "-b", "--script-param", "root=" + ROOT.as_posix(),
               "--script", "tools/aseprite/drawn_knight_static.lua"]
    process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                             creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
                             timeout=60)
    if process.returncode or "DRAWN_KNIGHT_ASEPRITE_PASS" not in process.stdout:
        raise RuntimeError(process.stdout + process.stderr)
    normalization = json.loads((BASE / "normalization.json").read_text())
    receipt = {"status": "PASS", "scope": "static asset properties; user selection pending",
               "command": command, "normalization": normalization, "files": {}}
    expected_pngs = {"comparison.png": (1600, 1180), "closeup.png": (1600, 1120),
                     "board_scale.png": (1600, 790)}
    for variant in ("pixel", "painted"):
        for layer in ("assembled", "body", "sword"):
            expected_pngs[f"{variant}_{layer}.png"] = (280, 280)
        expected_pngs[f"{variant}_board_1x.png"] = (740, 320)
    for name, size in expected_pngs.items():
        data = (BASE / name).read_bytes()
        assert data[:8] == b"\x89PNG\r\n\x1a\n", name
        assert struct.unpack(">II", data[16:24]) == size, name
    for path in sorted([*BASE.rglob("*.png"), *SOURCE.glob("*.aseprite")]):
        data = path.read_bytes()
        if path.suffix == ".aseprite":
            assert struct.unpack_from("<H", data, 4)[0] == 0xA5E0, path
            assert struct.unpack_from("<H", data, 6)[0] == 1, path
        receipt["files"][path.relative_to(ROOT).as_posix()] = {
            "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}
    assert normalization["variants"]["pixel"]["stats"]["visible_rgba_colors"] <= 47
    assert normalization["variants"]["pixel"]["stats"]["alpha_levels"] == 2
    assert all(v["aseprite_roundtrip_exact"] for v in normalization["variants"].values())
    (BASE / "verification.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("DRAWN_KNIGHT_STATIC_PASS", len(receipt["files"]), "files; source roundtrip exact")


if __name__ == "__main__":
    main()
