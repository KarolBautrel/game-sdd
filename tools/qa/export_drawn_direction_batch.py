"""Export only present directional sources; never manufacture missing facings."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT/'assets_src/characters/drawn_animation/2026-11-03'

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('profiles',nargs='+')
    args=parser.parse_args()
    count=0
    for profile in args.profiles:
        for folder in sorted((BASE/profile/'directions').glob('*')):
            source=folder/'raw/sequence.png'
            if not source.is_file(): continue
            cfg=json.loads((folder/'clips_source.json').read_text(encoding='utf-8'))
            raw=b''.join((folder/'raw'/(name+'.png')).read_bytes() for name in sorted(cfg['sheets']))
            fingerprint=hashlib.sha256(raw+(folder/'clips_source.json').read_bytes()+
                (ROOT/'tools/aseprite/drawn_action_sheets.lua').read_bytes()).hexdigest()
            stamp=folder/'export_fingerprint.txt'
            if stamp.is_file() and stamp.read_text().strip()==fingerprint: continue
            subprocess.run([sys.executable,str(ROOT/'tools/qa/export_drawn_actions.py'),
                profile,'--view',folder.name],cwd=ROOT,check=True)
            report=json.loads((folder/'export_report.json').read_text())
            assert not report['clipping'] and report['saved_source_roundtrip']=='PASS'
            stamp.write_text(fingerprint+'\n')
            count+=1
    print('DRAWN_DIRECTION_BATCH_PASS',count,'new exports')

if __name__=='__main__':main()
