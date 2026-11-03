"""Aseprite-authored static review boards and independent weapon reference files."""
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[2]

for script in ['drawn_roster_boards','drawn_weapon_library']:
    p=subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe','-b','--script-param',
        'root='+ROOT.as_posix(),'--script',str(ROOT/'tools/aseprite'/(script+'.lua'))],
        cwd=ROOT,capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
    print(p.stdout)
    assert p.returncode==0 and '_PASS' in p.stdout,p.stderr or p.stdout
