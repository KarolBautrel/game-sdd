"""Fixed44-pose directional sheet contract: seven runtime actions in eight views."""
import argparse
import json
from pathlib import Path
from configure_drawn_roles import clip, ROLES, ATTACKS

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT/'assets_src/characters/drawn_animation/2026-11-03'
DIRECTIONS = ('south','south_west','west','north_west','north','north_east','east')

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('profiles',nargs='+')
    args=parser.parse_args()
    for role in args.profiles:
        title=ROLES.get(role,'Rycerz · miecz dwuręczny')
        for view in DIRECTIONS:
            folder=BASE/role/'directions'/view
            folder.mkdir(parents=True,exist_ok=True)
            cfg={'title':title,'body_scale':True,'walk_stride_pixels':160,'sheets':{'sequence':{'cols':4,'rows':11}},'clips':[
                clip('neutral_idle','Spoczynek','neutral','sequence',1,4,250,True),
                clip('combat_idle','Gotowość bojowa','combat','sequence',5,4,250,True),
                clip('neutral_walk','Chód spokojny','neutral','sequence',9,8,125,True,align_head=True),
                clip('combat_walk','Chód w gotowości','combat','sequence',17,8,125,True,align_head=True),
                clip('attack',ATTACKS.get(role,'Cięcie · całe ciało'),'combat','sequence',25,8,
                     [160,120,100,70,60,100,170,190] if role=='knight' else [160,130,110,90,80,100,160,170]),
                clip('hit','Reakcja na trafienie','combat','sequence',33,4,[90,90,130,180]),
                clip('death','Upadek / śmierć','combat','sequence',37,8,[150,150,140,130,130,150,200,1000],reference_index=33)
            ]}
            if role=='rogue_1' and view=='north_east':
                next(c for c in cfg['clips'] if c['id']=='death')['offset_x']=6
            if role=='knight' and (folder/'raw/showcase.png').is_file():
                cfg['sheets']['showcase']={'cols':4,'rows':6}
                main=json.loads((BASE/'knight/clips_source.json').read_text(encoding='utf-8'))
                for name,start in [('draw',1),('sheathe',5),('attack_alt',9),('block',17),('dodge',21)]:
                    entry=next(c.copy() for c in main['clips'] if c['id']==name)
                    entry['sheet']='showcase';entry['start']=start
                    cfg['clips'].append(entry)
            if (folder/'raw/attack_forward.png').is_file():
                cfg['sheets']['attack_forward']={'cols':4,'rows':2}
                attack=next(c for c in cfg['clips'] if c['id']=='attack')
                attack['sheet']='attack_forward';attack['start']=1
            if role=='archer_1' and (folder/'raw/attack_aim.png').is_file():
                cfg['sheets']['attack_aim']={'cols':4,'rows':2}
                attack=next(c for c in cfg['clips'] if c['id']=='attack')
                attack.update(sheet='attack_aim',start=1,durations=[160,200,220,300,380,80,200,260],align_feet=True)
            if role=='archer_1' and (folder/'raw/attack_aim_axial.png').is_file():
                cfg['sheets']['attack_aim_axial']={'cols':4,'rows':2}
                next(c for c in cfg['clips'] if c['id']=='attack')['sheet']='attack_aim_axial'
            if role=='warrior' and (folder/'raw/sequence_shield_inside.png').is_file():
                cfg['sheets']={'sequence_shield_inside':{'cols':4,'rows':11}}
                for entry in cfg['clips']:entry['sheet']='sequence_shield_inside'
            if role=='warrior' and view=='north' and (folder/'raw/sequence_rear_stance_clean.png').is_file():
                cfg['sheets']['sequence_rear_stance_clean']={'cols':4,'rows':11}
                cfg['cleanup_neon']=True
                for entry in cfg['clips']:
                    if entry['id']!='death':entry['sheet']='sequence_rear_stance_clean'
            (folder/'clips_source.json').write_text(json.dumps(cfg,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('DRAWN_DIRECTION_CONFIG_PASS',len(args.profiles),len(DIRECTIONS))

if __name__=='__main__': main()
