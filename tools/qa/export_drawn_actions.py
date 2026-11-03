"""Run the project-owned Aseprite animation exporter without taking desktop focus."""
import argparse
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('profiles', nargs='+')
    parser.add_argument('--view')
    args = parser.parse_args()
    for profile in args.profiles:
        source = ROOT/'assets_src/aseprite/characters/drawn_animation/2026-11-03'/profile
        if args.view:
            source = source/'directions'/args.view
        source.mkdir(parents=True, exist_ok=True)
        command = [
            'C:/Program Files/Aseprite/Aseprite.exe', '-b',
            '--script-param', 'root='+ROOT.as_posix(), '--script-param', 'id='+profile,
            '--script', str(ROOT/'tools/aseprite/drawn_action_sheets.lua')]
        if args.view:
            command[2:2] = ['--script-param','view='+args.view]
        result = subprocess.run(command,
            cwd=ROOT, capture_output=True, text=True,
            creationflags=subprocess.CREATE_NO_WINDOW)
        print(result.stdout)
        if result.returncode or 'DRAWN_ACTION_SHEETS_PASS' not in result.stdout:
            raise RuntimeError(result.stderr or result.stdout)

if __name__ == '__main__':
    main()
