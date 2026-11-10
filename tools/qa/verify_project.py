"""Run repository validation and Godot checks, preserving inspectable evidence."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_GODOT = ROOT.parents[1] / "installers/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe"
SCENES = (
    "scenes/world/StrategicVastWorld.tscn",
    "scenes/world/StrategistVastWorld.tscn",
    "scenes/world/StrategistWorld.tscn",
    "scenes/world/StrategicWorld.tscn",
    "scenes/world/RegionFoundry.tscn",
    "scenes/world/TerrainEditor.tscn",
    "scenes/world/LivingWorld.tscn",
    "scenes/app/App.tscn",
    "scenes/town/town_shell.tscn",
    "scenes/town/TownExploration.tscn",
    "scenes/dungeon/DungeonDebug.tscn",
    "scenes/combat/CombatDebug.tscn",
    "scenes/combat/CombatMapEditor.tscn",
)
ERROR_PATTERN = re.compile(r"^\s*(?:SCRIPT ERROR:|ERROR:|Assertion failed)", re.MULTILINE)
WARNING_PATTERN = re.compile(r"^\s*WARNING:", re.MULTILINE)


def run_check(name: str, command: list[str], output: Path, timeout: float) -> dict:
    started = time.monotonic()
    output.mkdir(parents=True, exist_ok=True)
    stdout_path = output / f"{name}.stdout.log"
    stderr_path = output / f"{name}.stderr.log"
    timed_out = False
    launch_error = None
    with stdout_path.open("wb") as stdout, stderr_path.open("wb") as stderr:
        try:
            process = subprocess.Popen(command, cwd=ROOT, stdout=stdout, stderr=stderr)
            try:
                exit_code = process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                timed_out = True
                process.kill()
                process.wait()
                exit_code = None
        except OSError as error:
            exit_code = None
            launch_error = str(error)
    diagnostic_text = stdout_path.read_text(encoding="utf-8", errors="replace") + "\n" + stderr_path.read_text(encoding="utf-8", errors="replace")
    errors = len(ERROR_PATTERN.findall(diagnostic_text))
    warnings = len(WARNING_PATTERN.findall(diagnostic_text))
    return {
        "name": name, "command": command, "exit_code": exit_code,
        "timed_out": timed_out, "launch_error": launch_error,
        "duration_seconds": round(time.monotonic() - started, 3),
        "errors": errors, "warnings": warnings,
        "status": "PASS" if exit_code == 0 and not errors and not timed_out and not launch_error else "FAIL",
        "stdout": str(stdout_path.relative_to(ROOT)),
        "stderr": str(stderr_path.relative_to(ROOT)),
    }


def git_output(*arguments: str) -> str:
    try:
        return subprocess.check_output(["git", *arguments], cwd=ROOT, text=True, stderr=subprocess.DEVNULL).strip()
    except (OSError, subprocess.CalledProcessError):
        return "unavailable"


def source_fingerprint() -> str:
    digest = hashlib.sha256()
    paths = [ROOT / "project.godot", ROOT / "requirements-dev.txt", ROOT / "export_presets.cfg"]
    for folder in ("scripts", "scenes", "resources", "tools", "tests", "docs/specs"):
        paths.extend(path for path in (ROOT / folder).rglob("*") if path.is_file() and path.suffix in {".gd", ".gdshader", ".tscn", ".json", ".py", ".ps1", ".md", ".tmx", ".tsx"})
    for path in sorted(paths):
        digest.update(path.relative_to(ROOT).as_posix().encode())
        digest.update(b"\0")
        digest.update(path.read_bytes())
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, default=Path(os.environ.get("SDD_GODOT", DEFAULT_GODOT)))
    parser.add_argument("--run-id", default=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ"))
    parser.add_argument("--timeout", type=float, default=120)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_-]+", args.run_id):
        parser.error("run-id may contain only letters, digits, hyphens and underscores")
    if args.timeout <= 0 or args.timeout > 1800:
        parser.error("timeout must be greater than zero and at most 1800 seconds")
    if not args.godot.is_file():
        parser.error(f"Godot executable not found: {args.godot}")
    output = ROOT / "artifacts/qa-runs" / args.run_id
    if output.exists():
        parser.error(f"run directory already exists; use a new run-id: {output}")
    output.mkdir(parents=True)
    report = {
        "schema": "sdd.stage-verification-v1", "run_id": args.run_id,
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "python": {"executable": sys.executable, "version": sys.version},
        "godot": str(args.godot.resolve()), "git_head": git_output("rev-parse", "HEAD"),
        "git_status": git_output("status", "--short"),
        "source_sha256": source_fingerprint(), "checks": [],
        "interactive": {"status": "NOT_RUN", "required_display": "DISPLAY1"},
    }
    checks = report["checks"]

    def check(name: str, command: list[str]) -> dict:
        result = run_check(name, command, output, args.timeout)
        checks.append(result)
        print(f"{result['status']} {name} (exit={result['exit_code']}, errors={result['errors']}, warnings={result['warnings']})", flush=True)
        return result

    check("python_validation", [sys.executable, "tools/validators/validate_all.py"])
    check("python_tests", [sys.executable, "-m", "unittest", "discover", "-s", "tests"])
    version = check("godot_version", [str(args.godot), "--headless", "--version"])
    version_text = (ROOT / version["stdout"]).read_text(encoding="utf-8", errors="replace").strip()
    report["godot_version"] = version_text
    if not re.match(r"^4\.7\.(?:stable)(?:\.|$)", version_text):
        version["status"] = "FAIL"
        version["version_error"] = "Expected Godot 4.7 stable"
    if version["status"] == "PASS":
        imported = check("godot_import", [str(args.godot), "--headless", "--path", str(ROOT), "--import"])
        if imported["status"] == "PASS":
            for script in sorted((ROOT / "scripts").rglob("*tests.gd")):
                relative = script.relative_to(ROOT).as_posix()
                check(script.stem, [str(args.godot), "--headless", "--path", str(ROOT), "--script", f"res://{relative}"])
            for scene in SCENES:
                check(f"scene_{Path(scene).stem}", [str(args.godot), "--headless", "--path", str(ROOT), f"res://{scene}", "--quit-after", "5"])
    # Check coverage explicitly instead of accepting a partial execution as success.
    expected = 4 + len(list((ROOT / "scripts").rglob("*tests.gd"))) + len(SCENES)
    report["expected_check_count"] = expected
    report["automated_status"] = "PASS" if len(checks) == expected and all(item["status"] == "PASS" for item in checks) else "FAIL"
    report["stage_status"] = "AWAITING_INTERACTIVE" if report["automated_status"] == "PASS" else "FAIL"
    report["finished_utc"] = datetime.now(timezone.utc).isoformat()
    report_path = output / "report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Automated: {report['automated_status']}; interactive: NOT_RUN; report: {report_path}")
    return 0 if report["automated_status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
