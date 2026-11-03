"""Offline primary clips at native1x/enlargement. No engine/player-save mutation."""
import json
import os
from pathlib import Path
import re
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/tactical_batch/2026-11-03'
IDS=['painted_bandit_archer','painted_bandit_guard','painted_wolf']


def main():
    profiles=[];total=0;complete=[]
    for id in IDS:
        home=BASE/id
        if not (home/'source_proof.json').exists():continue
        proof=json.loads((home/'source_proof.json').read_text())
        assert proof['status']=='PASS' and all(c['roundtrip'] for c in proof['clips'])
        manifest=json.loads((home/'manifest.json').read_text())
        views=[]
        for view in ['south_east','south_west']:
            folder=home if view=='south_east' else home/'directions'/view
            meta=json.loads((folder/'manifest.json').read_text())
            for c in meta['clips']:
                c['frames']=int(c['frames']);c['durations']=[int(d) for d in c['durations']]
                assert struct.unpack('>II',(folder/c['atlas']).read_bytes()[16:24])==(384*c['frames'],320)
                total+=c['frames']
            views.append(dict(id=view,label='SE / rysowany' if view=='south_east' else 'SW / odbicie',
                              asset_base=os.path.relpath(folder,BASE).replace('\\','/')+'/',clips=meta['clips'],
                              direction_note='Nowy kandydat do oceny. SW jest odbiciem SE; asymetria i uchwyt broni sa odbite.'))
        profiles.append(dict(id=id,title=manifest['title'],canvas=[384,320],pivot=[192,270],walk_stride_pixels=160,
                             exported_views=['south_east','south_west'],views=views))
        complete.append(id)
    assert profiles
    data=dict(profiles=profiles,ground_base=os.path.relpath(ROOT/'assets/combat/environment/floors',BASE).replace('\\','/')+'/',
              shadow=os.path.relpath(ROOT/'assets/combat/environment/contact_shadow.png',BASE).replace('\\','/'))
    template=(ROOT/'tools/qa/drawn_animation_player.html').read_text(encoding='utf-8')
    html=template.replace('__DRAWN_ANIMATION_DATA__',json.dumps(data,ensure_ascii=False))
    html=re.sub(r'<title>.*?</title>','<title>Painted bandits and wolf</title>',html)
    html=html.replace("+' / 8 kierunków'","+' kierunki'")
    (BASE/'preview.html').write_text(html,encoding='utf-8')
    (BASE/'player_data.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    prompts=[]
    for id in complete:
        for sheet,entry in json.loads((BASE/id/'prompts.json').read_text(encoding='utf-8')).items():
            prompts.append(dict(actor=id,sheet=sheet,**entry))
    (BASE/'generation_prompts.json').write_text(json.dumps(dict(generator='built-in imagegen',prompts=prompts),indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    p=subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe','-b','--script-param','root='+ROOT.as_posix(),
                      '--script-param','ids='+','.join(complete),'--script',str(ROOT/'tools/aseprite/tactical_batch_board.lua')],
                     capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW,timeout=45)
    assert p.returncode==0 and 'TACTICAL_BATCH_BOARD_PASS' in p.stdout,(p.stdout,p.stderr)
    print('TACTICAL_BATCH_PREVIEW_PASS',len(profiles),'actors /',total,'source frames; native1x + enlargement')


if __name__=='__main__':main()
