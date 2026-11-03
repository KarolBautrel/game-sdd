"""Quick Aseprite preview of the user's lower/inward sword-pose request."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets_src/characters/drawn_knight_waist_sample/2026-11-03"


def main():
    previous = []
    for name in ("drawn_knight", "drawn_knight_guard", "drawn_knight_guard_side"):
        receipt = ROOT / f"assets_src/characters/{name}/2026-11-03/verification.json"
        previous.extend(json.loads(receipt.read_text())["files"].items())
    command = ["C:/Program Files/Aseprite/Aseprite.exe", "-b", "--script-param",
               "root="+ROOT.as_posix(), "--script", "tools/aseprite/waist_guard_sample.lua"]
    p = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                       creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0), timeout=60)
    assert p.returncode == 0 and "WAIST_GUARD_SAMPLE_PASS" in p.stdout, p.stdout+p.stderr
    for name, identity in previous:
        assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest() == identity["sha256"], name
    report = {"status": "PASS", "scope": "quick painted pose study, pending user review",
              "previous_files_unchanged": len(previous),
              "prompt": "prompt.json", "preview": "before_after.png", "sample": "sample.png"}
    (BASE/"verification.json").write_text(json.dumps(report, indent=2)+"\n")
    print("WAIST_GUARD_SAMPLE_PASS", len(previous), "previous files preserved")


if __name__ == "__main__":
    main()
