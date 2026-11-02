"""Normalize completed Blender deliveries with the installed Aseprite in background."""
import argparse
import json
from pathlib import Path
import subprocess
import time

ROOT=Path(__file__).resolve().parents[2]
ASEPRITE=Path("C:/Program Files/Aseprite/Aseprite.exe")


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ids",required=True)
    parser.add_argument("--watch",action="store_true")
    parser.add_argument("--directions")
    parser.add_argument("--timeout",type=int,default=3600)
    args=parser.parse_args()
    pending=args.ids.split(",");deadline=time.monotonic()+args.timeout
    while pending:
        for ident in pending[:]:
            model=ROOT/"assets_src/characters/roster"/ident/"model.json"
            report=ROOT/"artifacts/roster"/ident/"aseprite-report.json"
            if (model.parent/".rendering").exists():continue
            try:meta=json.loads(model.read_text())
            except (OSError,ValueError):continue
            if meta["preview_only"]:continue
            if report.exists() and report.stat().st_mtime>model.stat().st_mtime:
                previous=json.loads(report.read_text())
                if not previous["clipped"] and previous["frame_count"]==256:
                    pending.remove(ident);continue
            command=[str(ASEPRITE),"-b","--script-param","root="+ROOT.as_posix(),"--script-param","ids="+ident,"--script","tools/aseprite/roster.lua"]
            if args.directions:command[-2:-2]=["--script-param","directions="+args.directions]
            result=subprocess.run(command,cwd=ROOT,capture_output=True,text=True,creationflags=getattr(subprocess,"CREATE_NO_WINDOW",0))
            (report.parent/"normalization.log").write_text(result.stdout+result.stderr)
            if result.returncode or "ROSTER_ASEPRITE_PASS" not in result.stdout:
                print(result.stdout+result.stderr,flush=True);return 1
            print(result.stdout.strip(),flush=True);pending.remove(ident)
        if not pending:break
        if not args.watch:raise RuntimeError("Incomplete Blender deliveries: "+",".join(pending))
        if time.monotonic()>deadline:raise TimeoutError(",".join(pending))
        time.sleep(2)
    print("ROSTER_NORMALIZATION_COMPLETE",args.ids,flush=True)
    return 0


if __name__=="__main__":raise SystemExit(main())
