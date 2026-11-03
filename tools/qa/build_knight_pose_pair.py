"""Compose two user-referenced painted pose concepts without changing prior art."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets_src/characters/drawn_knight_pose_pair/2026-11-03"
SOURCE = ROOT / "assets_src/aseprite/characters/drawn_knight_pose_pair/2026-11-03"


def main():
    preserved = {}
    for name in ("drawn_knight", "drawn_knight_guard", "drawn_knight_guard_side"):
        receipt = ROOT / f"assets_src/characters/{name}/2026-11-03/verification.json"
        preserved.update({ROOT/n: d["sha256"] for n, d in json.loads(receipt.read_text())["files"].items()})
    for parent in (ROOT / "assets_src/characters/drawn_knight_waist_sample/2026-11-03",
                   ROOT / "assets_src/aseprite/characters/drawn_knight_waist_sample/2026-11-03"):
        for path in parent.iterdir():
            if path.suffix in (".png", ".aseprite"):
                preserved[path] = hashlib.sha256(path.read_bytes()).hexdigest()
    command = ["C:/Program Files/Aseprite/Aseprite.exe", "-b", "--script-param",
               "root="+ROOT.as_posix(), "--script", "tools/aseprite/knight_pose_pair.lua"]
    p = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                       creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0), timeout=60)
    assert p.returncode == 0 and "KNIGHT_POSE_PAIR_ASEPRITE_PASS" in p.stdout, p.stdout+p.stderr
    for path, identity in preserved.items():
        assert hashlib.sha256(path.read_bytes()).hexdigest() == identity, str(path)
    refs = {}
    for name in ("miecz_z_przodu.jpg", "pozycja_miecza_bok.jpg"):
        data = (BASE/"references"/name).read_bytes()
        assert data == (ROOT.parents[1]/name).read_bytes()
        refs[name] = hashlib.sha256(data).hexdigest()
    for name, dimensions in {"comparison.png": (1600,1060), "grips.png": (1600,740)}.items():
        assert struct.unpack(">II", (BASE/name).read_bytes()[16:24]) == dimensions
    files = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
             for p in [*BASE.glob("*.png"), *SOURCE.glob("*.aseprite")]}
    report = {"status": "PASS", "scope": "two painted exploratory pose plates",
              "user_confirmed_two_hands_both_poses": True, "previous_files_preserved": len(preserved),
              "reference_sha256": refs, "files": files,
              "production_alpha_or_weapon_layers_verified": False}
    (BASE/"verification.json").write_text(json.dumps(report, indent=2)+"\n")
    print("KNIGHT_POSE_PAIR_PASS", len(files), "new files;", len(preserved), "previous files preserved")


if __name__ == "__main__":
    main()
