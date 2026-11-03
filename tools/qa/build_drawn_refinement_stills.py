"""Static native/enlarged comparisons authored in Aseprite."""
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[2]
p=subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe','-b','--script-param','root='+ROOT.as_posix(),
    '--script',str(ROOT/'tools/aseprite/drawn_refinement_samples.lua')],cwd=ROOT,capture_output=True,
    text=True,creationflags=subprocess.CREATE_NO_WINDOW)
print(p.stdout)
assert p.returncode==0 and 'DRAWN_REFINEMENT_STILLS_PASS' in p.stdout,p.stderr or p.stdout
