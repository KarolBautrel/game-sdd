"""Export Windows and test the produced executable from its own directory."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools.qa.verify_project import DEFAULT_GODOT, ERROR_PATTERN, WARNING_PATTERN, SCENES, source_fingerprint
from tools.assets.build_catalogue import catalogue_errors

ENCOUNTER_TOKEN = "SDD_EXPORT_ENCOUNTER_PASS clearing_crossfire"
CAMPAIGN_TOKEN = "SDD_EXPORT_CAMPAIGN_PASS travel_stash_equipment_road"
TRADE_TOKEN = "SDD_EXPORT_TRADE_PASS ravenford_buy_sell"
INTERFACE_TOKEN = "SDD_EXPORT_INTERFACE_PASS shell_training"
POLISH_TOKEN = "SDD_EXPORT_POLISH_PASS inventory_services_map"


def probe_complete(stdout: str) -> bool:
    return "SDD_EXPORT_SMOKE_PASS" in stdout and ENCOUNTER_TOKEN in stdout and CAMPAIGN_TOKEN in stdout and TRADE_TOKEN in stdout and INTERFACE_TOKEN in stdout and POLISH_TOKEN in stdout and all(
        f"SDD_EXPORT_SCENE_PASS res://{scene}" in stdout for scene in SCENES
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, default=DEFAULT_GODOT)
    parser.add_argument("--run-id", default=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ"))
    parser.add_argument("--release", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_-]+", args.run_id) or not args.godot.is_file():
        parser.error("Valid run-id and existing Godot executable required")
    output = ROOT / "artifacts/export-smoke" / args.run_id
    if output.exists():
        parser.error("Run directory already exists; use a new run-id")
    errors = catalogue_errors()
    if errors:
        parser.error("; ".join(errors))
    output.mkdir(parents=True)
    report = {"schema": "sdd.export-smoke-v1", "release": args.release,
              "local_profile_excluded": True,
              "source_sha256": source_fingerprint(), "checks": [],
              "interactive": "NOT_RUN", "started_utc": datetime.now(timezone.utc).isoformat()}

    def run(name: str, command: list[str], cwd: Path, timeout: int = 120) -> bool:
        start = time.monotonic()
        with (output / f"{name}.stdout.log").open("wb") as stdout, (output / f"{name}.stderr.log").open("wb") as stderr:
            try:
                child = subprocess.Popen(command, cwd=cwd, stdout=stdout, stderr=stderr)
                try:
                    code = child.wait(timeout=timeout)
                    problem = None
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
                    code, problem = None, "timeout"
            except OSError as error:
                code, problem = None, str(error)
        diagnostic = "\n".join((output / f"{name}.{stream}.log").read_text(encoding="utf-8", errors="replace") for stream in ("stdout", "stderr"))
        passed = code == 0 and not problem and not ERROR_PATTERN.search(diagnostic)
        report["checks"].append({"name": name, "command": command, "cwd": str(cwd),
                                 "exit_code": code, "problem": problem, "errors": len(ERROR_PATTERN.findall(diagnostic)),
                                 "warnings": len(WARNING_PATTERN.findall(diagnostic)),
                                 "duration_seconds": round(time.monotonic() - start, 3), "status": "PASS" if passed else "FAIL"})
        print(f"{'PASS' if passed else 'FAIL'} {name}", flush=True)
        return passed

    executable = output / "sdd-game.exe"
    profile = ROOT / "override.cfg"
    saved_profile = output / "local-profile.cfg"
    moved_profile = False
    if profile.exists():
        profile_bytes = profile.read_bytes()
        if not profile_bytes.decode("utf-8-sig").startswith("; sdd QA launcher local profile"):
            parser.error("Unmanaged override.cfg: export needs an explicit reproducible project profile")
        report["local_profile_sha256"] = hashlib.sha256(profile_bytes).hexdigest()
        profile.rename(saved_profile)
        moved_profile = True
    try:
        built = run("export", [str(args.godot), "--headless", "--path", str(ROOT),
                                "--export-release" if args.release else "--export-debug",
                                "Windows Desktop", str(executable)], ROOT, timeout=300)
    finally:
        if moved_profile:
            saved_profile.rename(profile)
    console = output / "sdd-game.console.exe"
    package = output / "sdd-game.pck"
    files_present = all(path.is_file() for path in (executable, console, package))
    report["files_present"] = files_present
    if built and files_present:
        report["artifacts"] = {path.name: {"bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
                               for path in (executable, package)}
        # No --path to the source tree, nor source directory as the working directory.
        run("runtime", [str(executable), "--headless", "--max-fps", "60", "--quit-after", "600", "--", "--qa-export-smoke"], output)
        runtime_text = (output / "runtime.stdout.log").read_text(encoding="utf-8", errors="replace")
        report["probe_confirmed"] = probe_complete(runtime_text)
    report["status"] = "PASS" if files_present and report.get("probe_confirmed") and len(report["checks"]) == 2 and all(item["status"] == "PASS" for item in report["checks"]) else "FAIL"
    report["finished_utc"] = datetime.now(timezone.utc).isoformat()
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Export smoke: {report['status']}; interactive: NOT_RUN; {output}")
    return int(report["status"] != "PASS")


if __name__ == "__main__":
    raise SystemExit(main())
