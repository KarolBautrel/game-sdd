"""Rebuild the two-handed static guard through background Aseprite, preserving020."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets_src/characters/drawn_knight_guard/2026-11-03"
SOURCE = ROOT / "assets_src/aseprite/characters/drawn_knight_guard/2026-11-03"
PREVIOUS = ROOT / "assets_src/characters/drawn_knight/2026-11-03/verification.json"


def verify_previous():
    previous = json.loads(PREVIOUS.read_text())
    for name, identity in previous["files"].items():
        data = (ROOT / name).read_bytes()
        assert hashlib.sha256(data).hexdigest() == identity["sha256"], name
    return len(previous["files"])


def verify():
    normalization = json.loads((BASE / "normalization.json").read_text())
    previous_count = verify_previous()
    checks = {"comparison.png": (1600, 1220), "closeup.png": (1600, 1150),
              "layer_review.png": (1600, 800), "board_scale.png": (1600, 790)}
    for variant in ("pixel", "painted"):
        for role in ("assembled", "body_gloves", "sword", "gloves"):
            checks[f"{variant}_{role}.png"] = (280, 280)
        checks[f"{variant}_board_1x.png"] = (740, 320)
        checks[f"{variant}_source_assembled.png"] = (1254, 1254)
        item = normalization["variants"][variant]
        assert item["source_roundtrip_exact"] and item["sword_removal_verified"]
        assert item["sword_axis_cross_product"] < 1e-8
        assert len(item["grip_points_canvas"]) == 2
        x, y, w, h = item["stats"]["bounds"]
        assert x > 3 and y > 3 and x+w < 276 and y+h < 276
        _, sole_y, _, sole_h = item["body_gloves_stats"]["bounds"]
        assert sole_y + sole_h - 1 == 229, "Sole not on shared ground anchor"
    assert normalization["variants"]["pixel"]["stats"]["visible_colors"] <= 47
    assert normalization["variants"]["pixel"]["stats"]["alpha_levels"] == 2
    for name, size in checks.items():
        data = (BASE / name).read_bytes()
        assert data[:8] == b"\x89PNG\r\n\x1a\n", name
        assert struct.unpack(">II", data[16:24]) == size, name
    files = {}
    for path in sorted([*BASE.rglob("*.png"), *SOURCE.glob("*.aseprite")]):
        data = path.read_bytes()
        if path.suffix == ".aseprite":
            assert struct.unpack_from("<H", data, 4)[0] == 0xA5E0
            assert struct.unpack_from("<H", data, 6)[0] == 1
        files[path.relative_to(ROOT).as_posix()] = {
            "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
    receipt = {"status": "PASS", "scope": "static layered guard file properties only",
               "appearance_review": "pending_user_feedback", "motion_review": "not_started",
               "previous020_files_unchanged": previous_count,
               "normalization": normalization, "files": files}
    (BASE / "verification.json").write_text(json.dumps(receipt, indent=2) + "\n")
    manifest = {"schema": "sdd.static-art-proposal-v1", "owner": "presentation021",
                "stage": 1, "date": "2026-11-03", "shared_art_direction": "accepted_by_user",
                "guard_appearance": "pending_user_review", "animation_delivered": False,
                "runtime_imported": False, "source_tool": "built-in image_gen.imagegen",
                "raster_editor": "Aseprite " + normalization["aseprite"],
                "canvas": [280, 280], "ground_pivot": [140, 229],
                "provenance": "Original generated knight edits; raw PNGs preserved. All layer separation and blade alignment repair performed in Aseprite.",
                "prompts": "prompts.json", "masks_and_axes": "separation.json",
                "verification": "verification.json", "collision_role": "none; static visual pilot",
                "review": ["comparison.png", "closeup.png", "board_scale.png", "layer_review.png"],
                "assets": []}
    for variant in ("pixel", "painted"):
        manifest["assets"].append({"id": "drawn_knight_guard_" + variant,
            "view": "three_quarter_screen_right", "frame_count": 1,
            "native": variant + "_assembled.png", "rigid_weapon": variant + "_sword.png",
            "body_and_gloves": variant + "_body_gloves.png",
            "foreground_gloves": variant + "_gloves.png",
            "source": (SOURCE / (variant + "_native.aseprite")).relative_to(ROOT).as_posix(),
            "master": (SOURCE / (variant + "_master.aseprite")).relative_to(ROOT).as_posix(),
            "metadata": normalization["variants"][variant]})
    (BASE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("DRAWN_KNIGHT_GUARD_PASS", len(files), "new files;", previous_count,
          "previous files unchanged; independent sword/source roundtrip PASS")


def main():
    verify_previous()
    command = ["C:/Program Files/Aseprite/Aseprite.exe", "-b", "--script-param",
               "root=" + ROOT.as_posix(), "--script", "tools/aseprite/drawn_knight_guard.lua"]
    process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                             creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
                             timeout=180)
    if process.returncode or "DRAWN_KNIGHT_GUARD_ASEPRITE_PASS" not in process.stdout:
        raise RuntimeError(process.stdout + process.stderr)
    verify()


if __name__ == "__main__":
    main()
