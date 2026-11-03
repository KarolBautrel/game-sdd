"""Re-export final edited source cels, preserving every Aseprite file byte."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
IDS=['painted_bandit_archer','painted_bandit_guard','painted_wolf']


def main():
    for id in IDS:
        source=ROOT/'assets_src/aseprite/characters/tactical_batch/2026-11-03'/id
        hashes={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in source.rglob('*.aseprite')}
        assert len(hashes)==(16 if id=='painted_bandit_guard' else 14)
        p=subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe','-b','--script-param','root='+ROOT.as_posix(),
                          '--script-param','id='+id,'--script',str(ROOT/'tools/aseprite/export_tactical_sources.lua')],
                         capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW,timeout=120)
        assert p.returncode==0 and 'TACTICAL_CANONICAL_EXPORT_PASS' in p.stdout,(p.stdout,p.stderr)
        assert all(hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==sha for path,sha in hashes.items())
        home=ROOT/'assets_src/characters/tactical_batch/2026-11-03'/id
        proof=json.loads((home/'source_proof.json').read_text());proof['source_hashes']=hashes
        (home/'source_proof.json').write_text(json.dumps(proof,indent=2)+'\n')
        print(p.stdout,flush=True)
    subprocess.run([sys.executable,str(ROOT/'tools/qa/build_tactical_enemy_batch.py'),'--package-only'],check=True,cwd=ROOT)


if __name__=='__main__':main()
