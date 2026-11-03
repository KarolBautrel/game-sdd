"""Build the user-referenced side guard, preserving both prior static deliveries."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets_src/characters/drawn_knight_guard_side/2026-11-03"
SOURCE = ROOT / "assets_src/aseprite/characters/drawn_knight_guard_side/2026-11-03"
PREVIOUS = [ROOT / "assets_src/characters/drawn_knight/2026-11-03/verification.json",
            ROOT / "assets_src/characters/drawn_knight_guard/2026-11-03/verification.json"]


def verify_previous():
    count = 0
    for receipt in PREVIOUS:
        previous = json.loads(receipt.read_text())
        for name, identity in previous["files"].items():
            data = (ROOT / name).read_bytes()
            assert hashlib.sha256(data).hexdigest() == identity["sha256"], name
            count += 1
    return count


def verify():
    normalization = json.loads((BASE / "normalization.json").read_text())
    previous_count = verify_previous()
    checks = {"comparison.png": (1600, 1330), "closeup.png": (1600, 1190),
              "layer_review.png": (1600, 800), "board_scale.png": (1600, 790),
              "before_after.png": (1600, 1020)}
    for variant in ("pixel", "painted"):
        for role in ("assembled", "body_gloves", "sword", "gloves"):
            checks[f"{variant}_{role}.png"] = (280, 280)
        checks[f"{variant}_board_1x.png"] = (740, 320)
        checks[f"{variant}_source_assembled.png"] = (1254, 1554)
        item = normalization["variants"][variant]
        assert item["source_roundtrip_exact"] and item["sword_removal_verified"]
        assert item["sword_axis_cross_product"] < 1e-8
        assert len(item["grip_points_canvas"]) == 2
        assert item["grip_lateral_from_pivot"] < -20, "Grip not moved to lateral side"
        assert abs(item["sword_axis_unit"][0]) < 0.06, "Sword no longer approximately upright"
        assert 78 < item["blade_length_native"] < 83, "Longsword blade/body exposure mismatch"
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
    reference = BASE / "references/pozycja_miecza.webp"
    original_reference = ROOT.parents[1] / "pozycja_miecza.webp"
    assert reference.read_bytes() == original_reference.read_bytes(), "User pose reference changed"
    reference_hash = hashlib.sha256(reference.read_bytes()).hexdigest()
    receipt = {"status": "PASS", "scope": "static layered side guard file properties only",
               "appearance_review": "pending_user_feedback", "motion_review": "not_started",
               "previous020_021_files_unchanged": previous_count,
               "user_pose_reference_sha256": reference_hash,
               "normalization": normalization, "files": files}
    (BASE / "verification.json").write_text(json.dumps(receipt, indent=2) + "\n")
    manifest = {"schema": "sdd.static-art-proposal-v1", "owner": "presentation021",
                "stage": 1, "date": "2026-11-03", "shared_art_direction": "accepted_by_user",
                "guard_appearance": "corrected_side_guard_pending_review", "animation_delivered": False,
                "runtime_imported": False, "source_tool": "built-in image_gen.imagegen",
                "raster_editor": "Aseprite " + normalization["aseprite"],
                "canvas": [280, 280], "ground_pivot": [140, 229],
                "provenance": "Original generated side-guard edits from user pose reference; raw sources preserved. Aseprite separates layers and extends the blade onto one rigid axis with source headroom.",
                "pose_reference": "references/pozycja_miecza.webp",
                "pose_reference_sha256": reference_hash,
                "reference_use": "pose only; not a runtime costume/character asset",
                "prompts": "prompts.json", "masks_and_axes": "separation.json",
                "verification": "verification.json", "collision_role": "none; static visual pilot",
                "review": ["before_after.png", "comparison.png", "closeup.png", "board_scale.png", "layer_review.png"],
                "assets": []}
    for variant in ("pixel", "painted"):
        manifest["assets"].append({"id": "drawn_knight_guard_side_" + variant,
            "view": "three_quarter_screen_right", "frame_count": 1,
            "native": variant + "_assembled.png", "rigid_weapon": variant + "_sword.png",
            "body_and_gloves": variant + "_body_gloves.png",
            "foreground_gloves": variant + "_gloves.png",
            "source": (SOURCE / (variant + "_native.aseprite")).relative_to(ROOT).as_posix(),
            "master": (SOURCE / (variant + "_master.aseprite")).relative_to(ROOT).as_posix(),
            "metadata": normalization["variants"][variant]})
    (BASE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("DRAWN_KNIGHT_SIDE_GUARD_PASS", len(files), "new files;", previous_count,
          "previous files unchanged; independent sword/source roundtrip PASS")


def main():
    verify_previous()
    command = ["C:/Program Files/Aseprite/Aseprite.exe", "-b", "--script-param",
               "root=" + ROOT.as_posix(), "--script", "tools/aseprite/drawn_knight_guard_side.lua"]
    process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                             creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
                             timeout=180)
    if process.returncode or "DRAWN_KNIGHT_SIDE_GUARD_ASEPRITE_PASS" not in process.stdout:
        raise RuntimeError(process.stdout + process.stderr)
    verify()


if __name__ == "__main__":
    main()
