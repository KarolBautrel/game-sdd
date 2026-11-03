"""New enemy sources only: existing Aseprite normalizer -> planted idle -> SW."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT/'assets_src/characters/tactical_batch/2026-11-03'
ASEPRITE = 'C:/Program Files/Aseprite/Aseprite.exe'
IDS = ['painted_bandit_archer', 'painted_bandit_guard', 'painted_wolf']
LABELS = ['Bandit archer', 'Bandit shield fighter', 'Grey wolf']
ACTIONS = ['neutral_idle','neutral_walk','combat_idle','combat_walk','attack','hit','death']


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')


def source_config(id):
    wolf = id == 'painted_wolf'
    archer = id == 'painted_bandit_archer'
    clips = []
    specs = [('neutral_idle','locomotion',1,4,250,True),
             ('neutral_walk','locomotion',5,8,125,True),
             ('combat_idle','locomotion',13,4,250,True),
             ('combat_walk','actions',1,8,125,True),
             ('attack','actions',9,8,[160,200,220,300,380,80,200,260] if archer else ([180,160,120,80,80,120,160,200] if wolf else [160,120,100,70,60,100,170,190]),False),
             ('hit','reactions',5,4,[90,90,130,180],False),
             ('death','reactions',9,8,[150,150,140,130,130,150,200,1000],False)]
    for action,sheet,start,count,durations,loop in specs:
        c = dict(id=action,title=action.replace('_',' ').title(),mode='neutral' if action.startswith('neutral') else 'combat',sheet=sheet,start=start,count=count,durations=durations,loop=loop)
        if 'walk' in action:
            c['align_head' if not wolf else 'align_feet'] = True
        if action == 'attack' and archer:
            c['align_feet'] = True
        if action == 'death':
            c['reference_index'] = 1
        if action in ['neutral_idle','combat_idle']:
            c['reference_index'] = 1
        # Last-column ready wolf has its muzzle on the raw sheet edge. Retain
        # three complete drawings with an explicitly held second drawing instead.
        if wolf and action == 'combat_idle':
            c['indices'] = [13,14,15,14]
        clips.append(c)
    if id == 'painted_bandit_guard':
        clips.append(dict(id='block',title='Shield brace',mode='combat',sheet='reactions',start=1,count=4,
                          durations=[120,160,220,180],loop=False,reference_index=1,align_feet=True))
    result = dict(title=LABELS[IDS.index(id)],body_scale=not wolf,body_height_target=95 if wolf else 171,
                  walk_stride_pixels=160,idle_lock_y=250 if wolf else 232,cleanup_neon=True,
                  sheets={s:dict(cols=4,rows=4) for s in ['locomotion','actions','reactions']},clips=clips)
    if wolf:
        result['scale_reference_sheet'] = 'locomotion'
    return result


def run_lua(script, id, **params):
    args=[ASEPRITE,'-b','--script-param','root='+ROOT.as_posix(),'--script-param','id='+id]
    for key,value in params.items():
        args += ['--script-param',key+'='+str(value)]
    args += ['--script',str(ROOT/'tools/aseprite'/script)]
    p=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW,timeout=180)
    print(p.stdout,flush=True)
    assert p.returncode==0 and '_PASS' in p.stdout,(id,p.stderr,p.stdout)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('ids',nargs='*',choices=IDS)
    parser.add_argument('--configure-only',action='store_true')
    parser.add_argument('--package-only',action='store_true',help='Keep canonical Aseprite/PNG edits; refresh only runtime metadata')
    args=parser.parse_args()
    selected=[] if args.package_only else args.ids or IDS
    for id in selected:
        home=BASE/id
        write(home/'clips_source.json',source_config(id))
        if args.configure_only:continue
        for name in ['locomotion','actions','reactions']:
            assert (home/'raw'/(name+'.png')).is_file(),f'Missing generated sheet {id}/{name}'
        source=ROOT/'assets_src/aseprite/characters/tactical_batch/2026-11-03'/id/'south_east'
        run_lua('drawn_action_sheets.lua',id,base=home.as_posix(),source=source.as_posix(),view='south_east')
        run_lua('tactical_actor_finish.lua',id)
        proof=json.loads((home/'source_proof.json').read_text())
        assert proof['status']=='PASS' and len(proof['clips'])==len(source_config(id)['clips'])*2 and all(c['roundtrip'] for c in proof['clips'])
        proof['source_hashes']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in source.parent.rglob('*.aseprite')}
        write(home/'source_proof.json',proof)
        print('TACTICAL_ENEMY_SOURCE_PASS',id,flush=True)
    # Only publish a complete three-role batch after all canonical source proofs.
    if args.configure_only or any(not (BASE/id/'source_proof.json').is_file() for id in IDS):return
    profiles=[]
    for id in IDS:
        home=BASE/id;manifest=json.loads((home/'manifest.json').read_text())
        proof=json.loads((home/'source_proof.json').read_text())
        hashes={(ROOT/'assets_src/aseprite/characters/tactical_batch/2026-11-03'/id/view/(c['id']+'.aseprite')).relative_to(ROOT).as_posix():hashlib.sha256((ROOT/'assets_src/aseprite/characters/tactical_batch/2026-11-03'/id/view/(c['id']+'.aseprite')).read_bytes()).hexdigest() for view in ['south_east','south_west'] for c in manifest['clips']}
        assert hashes==proof.get('source_hashes'), 'Changed/unverified canonical source; use export_tactical_sources.py or rebuild explicitly'
        profiles.append(dict(id=id,label=manifest['title'],enabled=True,root='res://assets/combat/characters/tactical/'+id,
                             canvas=[384,320],pivot=[192,270],facings=['south_east','south_west'],
                             frame_counts={c['id']:int(c['frames']) for c in manifest['clips']},
                             durations_ms={c['id']:[int(d) for d in c['durations']] for c in manifest['clips']},
                             impact_frame=5 if id.endswith('archer') else (3 if id=='painted_wolf' else 4),walk_stride_pixels=160,
                             pixels_per_metre=100,body_height=manifest['body_height'],idle_lock_y=manifest['idle_lock_y'],source_roundtrip=True,
                             view_sources={v:dict(source=(home if v=='south_east' else home/'directions'/v).relative_to(ROOT).as_posix(),kind='drawn' if v=='south_east' else 'mirror',mirror_of=None if v=='south_east' else 'south_east',handedness='source drawing' if v=='south_east' else 'reflected') for v in ['south_east','south_west']}))
        if id == 'painted_bandit_guard':
            profiles[-1]['action_aliases'] = {'status_reaction':'block'}
    write(ROOT/'resources/data/presentation/tactical_roster.json',dict(schema='sdd.drawn-roster-v1',profiles=profiles,
            replacements={'bandit_archer':'painted_bandit_archer','wolf_atlas':'painted_wolf'},
            archetype_replacements={'raider_archer':'painted_bandit_archer','raider_shieldman':'painted_bandit_guard'}))
    # Retain the accepted six-role graphics and previously authored Bran variant.
    accepted=json.loads((ROOT/'assets_src/characters/hero_identity/bran/accepted_roster_hashes.json').read_text())
    assert len(accepted)==2304 and all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in accepted.items())
    print('TACTICAL_BATCH_PACKAGE_PASS 3 roles / 44 sources / 272 frames; accepted2304 unchanged')


if __name__=='__main__':main()
