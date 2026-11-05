"""Register stage83's Aseprite exports; retain originals and record provenance."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets_src/tactical_environment/2026-11-05"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    normalization = json.loads((SOURCE / "normalization.json").read_text())
    path = ROOT / "resources/data/presentation/world_art.json"
    art = json.loads(path.read_text())
    for row in normalization["assets"]:
        assert isinstance(row["size"], list) and isinstance(row["pivot"], list), row["id"]
        asset = ROOT / row["path"].removeprefix("res://")
        assert asset.is_file(), asset
        old = ROOT / "assets/combat/environment/props" / (row["id"] + ".png")
        row["sha256"] = digest(asset)
        row["retained_original"] = str(old.relative_to(ROOT)).replace("\\", "/")
        row["retained_original_sha256"] = digest(old)
        row["role"] = "presentation_only_no_collision_override"
        art["assets"][row["id"]] = {k: row[k] for k in ("path", "size", "pivot")}
    path.write_text(json.dumps(art, indent=2) + "\n", encoding="utf-8")
    normalization.update({
        "tool": "OpenAI built-in imagegen + Aseprite",
        "generated_source_sha256": digest(SOURCE / "generated-source.png"),
        "prompt_file": "prompt.txt",
        "editable_source": "assets_src/aseprite/tactical_environment/painted_props.aseprite",
        "reference": "artifacts/qa-runs/locomotion-native-first/arena-painted_forest_ambush-1920x1080.png",
    })
    (SOURCE / "manifest.json").write_text(json.dumps(normalization, indent=2) + "\n", encoding="utf-8")
    print(f"Registered {len(normalization['assets'])} painted props; originals retained.")


if __name__ == "__main__":
    main()
