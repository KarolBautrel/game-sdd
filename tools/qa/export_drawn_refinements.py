"""Export only source views changed by the idle/shield/bow correction batch."""
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
for role,view in [('warrior','north_east'),('warrior','north'),('archer_1',None),
                  ('archer_1','south'),('archer_1','east'),('archer_1','north_east'),('archer_1','north')]:
    args=[sys.executable,str(ROOT/'tools/qa/export_drawn_actions.py'),role]
    if view:args+=['--view',view]
    subprocess.run(args,cwd=ROOT,check=True)
print('DRAWN_REFINEMENT_EXPORT_PASS 7 changed source views')
