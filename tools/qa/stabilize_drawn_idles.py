"""Aseprite-only idle registration and source/provenance update."""
import argparse
import json
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/drawn_animation/2026-11-03'

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--id')
    parser.add_argument('--view')
    parser.add_argument('--report',default='refinements/idle_contact_report.json')
    args=parser.parse_args()
    command=['C:/Program Files/Aseprite/Aseprite.exe','-b','--script-param','root='+ROOT.as_posix()]
    for key,value in [('id',args.id),('view',args.view),('report',args.report)]:
        if value:command+=['--script-param',key+'='+value]
    p=subprocess.run(command+['--script',str(ROOT/'tools/aseprite/drawn_idle_contact.lua')],
        cwd=ROOT,capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
    print(p.stdout)
    assert p.returncode==0 and 'DRAWN_IDLE_CONTACT_PASS' in p.stdout,p.stderr or p.stdout
    proof=json.loads((BASE/args.report).read_text())
    for view in proof['views']:
        folder=BASE/view['id']
        if view['view']!='south_east':folder=folder/'directions'/view['view']
        path=folder/'export_report.json'
        report=json.loads(path.read_text())
        report['idle_contact']={'lock_y':proof['lock_y'],'status':'PASS','source_roundtrip':'PASS'}
        for action,clip in view['clips'].items():
            for old,new in zip(report['clips'][action]['metrics'],clip['frames']):
                old.update(new)
        path.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        path=folder/'manifest.json';manifest=json.loads(path.read_text(encoding='utf-8'))
        for clip in manifest['clips']:
            if clip['id'] in view['clips']:clip['idle_contact']={'lock_y':proof['lock_y'],'planted':True}
        path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__':main()
