"""Record source/editable/runtime campaign art hashes without editing pixels."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets_src/campaign_ui/manifest.json"

def main() -> None:
    paths = []
    for directory, suffix in (("assets_src/campaign_ui", ".png"),
                              ("assets_src/aseprite/campaign_ui", ".aseprite"),
                              ("assets/ui/campaign", ".png")):
        paths.extend(path for path in (ROOT / directory).rglob("*" ) if path.suffix == suffix)
    entries = [{"path": path.relative_to(ROOT).as_posix(),
                "bytes": path.stat().st_size,
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
               for path in sorted(paths)]
    record = {"schema": "sdd.campaign-art-v1", "production_date": "2026-11-02",
              "selected_concept": "A", "generated_source_brief": "assets_src/campaign_ui/prompts.md",
              "pixel_editor": "Aseprite 1.3.17.2",
              "recipe": "tools/aseprite/campaign_ui_assets.lua",
              "dependencies": "tools/assets/ui_dependencies.json",
              "licenses": "resources/licenses/campaign-ui.txt", "files": entries}
    OUTPUT.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"Campaign source/editable/export manifest: {len(entries)} files")

if __name__ == "__main__":
    main()
