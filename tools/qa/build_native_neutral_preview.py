"""Stage60: direct shield-warrior reference, retained knight, and calm cadence."""
import json
import os
from pathlib import Path
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/drawn_animation/2026-11-03'
OUT=BASE/'refinements/native_neutral'
BEFORE=OUT/'before'


def read(p):return json.loads(p.read_text(encoding='utf-8'))
def folder(role,view):return BASE/role if view=='south_east' else BASE/role/'directions'/view


def entry(home,action,view):
    manifest=read(home/'manifest.json')
    clip=next(c for c in manifest['clips'] if c['id']==action)
    image=home/clip['atlas']
    assert struct.unpack('>II',image.read_bytes()[16:24])==(384*clip['frames'],320)
    result={'atlas':os.path.relpath(image,OUT).replace('\\','/'),'frames':clip['frames'],
            'durations':clip['durations'],'loop':clip['loop']}
    if 'walk' in action:result.update(stride_pixels=manifest.get('walk_stride_pixels',80),direction=view)
    return result


registry=read(ROOT/'resources/data/presentation/drawn_roster.json')
cases=[]
for p in registry['profiles']:
    for action in ('neutral_walk','combat_walk'):
        home=folder(p['id'],'south_east')
        cases.append({'topic':'gait','label':p['label']+' / '+action,
                      'note':'Spokojniejszy rytm: dwa kroki na sekundę. Podłoże pokazuje rzeczywisty dystans: 160 px/s zamiast 200 px/s.',
                      'old':entry(BEFORE/home.relative_to(ROOT),action,'south_east'),
                      'new':entry(home,action,'south_east')})
for view in registry['profiles'][0]['facings']:
    home=folder('knight',view)
    cases.append({'topic':'neutral','label':'Szermierz / '+view,'note':'Ta sama ostra twarz i buty; neutralna ręka z opuszczonym mieczem.',
                  'old':entry(BEFORE/home.relative_to(ROOT),'neutral_idle',view),'new':entry(home,'neutral_idle',view)})
    cases.append({'topic':'reference','label':'Wzorzec tarczownika / '+view,'note':'Po lewej wzorzec pozy rycerza z tarczą. Po prawej neutralna poza rycerza dwuręcznego.',
                  'old_label':'Wzorzec: miecz i tarcza','new_label':'Rycerz dwuręczny',
                  'old':entry(folder('warrior',view),'neutral_idle',view),'new':entry(home,'neutral_idle',view)})
data={'cases':cases,'initial_topic':'reference','topics':[['reference','Wzorzec i rycerz'],['neutral','Poza przed i po'],['gait','Spokojniejszy chód']],
      'floor':os.path.relpath(ROOT/'assets/combat/environment/floors/woodland.png',OUT).replace('\\','/'),
      'shadow':os.path.relpath(ROOT/'assets/combat/environment/contact_shadow.png',OUT).replace('\\','/')}
template=(ROOT/'tools/qa/drawn_refinement_player.html').read_text(encoding='utf-8')
(OUT/'preview.html').write_text(template.replace('__REFINEMENT_DATA__',json.dumps(data,ensure_ascii=False)),encoding='utf-8')
(OUT/'player_data.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe','-b','--script-param','root='+ROOT.as_posix(),
                  '--script',str(ROOT/'tools/aseprite/native_neutral_samples.lua')],cwd=ROOT,capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
assert p.returncode==0 and 'NATIVE_NEUTRAL_SAMPLES_PASS' in p.stdout,p.stdout+p.stderr
print('NATIVE_NEUTRAL_PREVIEW_PASS',len(cases),'native/2x samples')
