"""Activate only complete, source-verified eight-direction painted profiles."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/drawn_animation/2026-11-03'
VIEWS=('south','south_west','west','north_west','north','north_east','east','south_east')
ACTIONS=('neutral_idle','combat_idle','neutral_walk','combat_walk','attack','hit','death')
KNIGHT_EXTRAS=('draw','sheathe','attack_alt','block','dodge')

def read(path):return json.loads(path.read_text(encoding='utf-8'))

def inspect(profile):
    home=BASE/profile
    main=read(home/'manifest.json')
    clips={c['id']:c for c in main['clips']}
    actions=ACTIONS+KNIGHT_EXTRAS if profile=='knight' else ACTIONS
    result=dict(id=profile,label=main['title'],enabled=True,root='res://assets/combat/characters/drawn/'+profile,
        canvas=main['canvas'],pivot=main['pivot'],facings=list(VIEWS),
        frame_counts={a:clips[a]['frames'] for a in actions},
        durations_ms={a:clips[a]['durations'] for a in actions},
        impact_frame=5 if profile=='archer_1' else 4,walk_stride_pixels=80,
        pixels_per_metre=100,source_roundtrip=True,view_sources={})
    files=[];first_hashes=[]
    for view in VIEWS:
        folder=home if view=='south_east' else home/'directions'/view
        manifest=read(folder/'manifest.json');proof=read(folder/'export_report.json')
        assert proof['saved_source_roundtrip']=='PASS' and not proof['clipping'],folder
        assert manifest['canvas']==main['canvas'] and manifest['pivot']==main['pivot'],folder
        view_clips={c['id']:c for c in manifest['clips']}
        result['view_sources'][view]=dict(source=str(folder.relative_to(ROOT)).replace('\\','/'),
            kind='mirror' if manifest.get('mirror_of') else 'drawn',mirror_of=manifest.get('mirror_of'),
            handedness='reflected' if manifest.get('mirror_of') else 'source drawing')
        for action in actions:
            c=view_clips[action]
            assert c['frames']==result['frame_counts'][action],(folder,action)
            assert c['durations']==result['durations_ms'][action],(folder,action,'timing mismatch')
            for frame in range(c['frames']):
                src=folder/'frames'/action/f'{frame:03}.png'
                data=src.read_bytes()
                assert data[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',data[16:24])==tuple(main['canvas']),src
                dst=ROOT/'assets/combat/characters/drawn'/profile/action/f'{profile}_{view}_{action}_{frame:03}.png'
                files.append((src,dst,hashlib.sha256(data).hexdigest()))
        first_hashes.append(hashlib.sha256((folder/'frames/neutral_idle/000.png').read_bytes()).hexdigest())
    assert len(set(first_hashes))==8,'Duplicate facing images: '+profile
    return result,files

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('profiles',nargs='+')
    args=parser.parse_args()
    inspected=[inspect(profile) for profile in args.profiles]
    registry=ROOT/'resources/data/presentation/drawn_roster.json'
    current=read(registry) if registry.exists() else {'schema':'sdd.drawn-roster-v1','profiles':[]}
    by_id={p['id']:p for p in current['profiles']}
    identities={}
    for profile,files in inspected:
        for src,dst,sha in files:
            dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
            assert hashlib.sha256(dst.read_bytes()).hexdigest()==sha,dst
            identities[dst.relative_to(ROOT).as_posix()]=sha
        by_id[profile['id']]=profile
    current['profiles']=list(by_id.values())
    registry.write_text(json.dumps(current,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    report={'status':'RUNTIME_ASSET_PACKAGE_PASS','profiles':args.profiles,'frames':len(identities),
            'identities':identities,'user_directional_acceptance':'pending',
            'reuse':'five drawings plus three reflected views; handedness/costume reflected'}
    (BASE/'runtime_package_verification.json').write_text(json.dumps(report,indent=2)+'\n')
    print('DRAWN_RUNTIME_PACKAGE_PASS',len(args.profiles),'profiles',len(identities),'frames')

if __name__=='__main__':main()
