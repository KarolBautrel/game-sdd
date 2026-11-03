"""Declare the reproducible non-knight source-sheet layouts and action timing."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT/'assets_src/characters/drawn_animation/2026-11-03'
ROLES = {'warrior':'Bran · miecz i tarcza','archer_1':'Torin · łuk',
         'rogue_1':'Łotr · dwa sztylety','axe_bandit':'Rabuś · topór',
         'bandit_spearman':'Włócznik · włócznia'}
ATTACKS = {'warrior':'Cięcie zza tarczy','archer_1':'Naciąg i strzał',
           'rogue_1':'Kombinacja sztyletów','axe_bandit':'Zamach toporem',
           'bandit_spearman':'Pchnięcie włócznią'}

def clip(id,title,mode,sheet,start,count,durations,loop=False,**kwargs):
    return dict(id=id,title=title,mode=mode,sheet=sheet,start=start,count=count,
                durations=durations,loop=loop,**kwargs)

def main():
    for role,title in ROLES.items():
        profile = BASE/role
        profile.mkdir(parents=True, exist_ok=True)
        cfg={'title':title,'body_scale':True,'sheets':{name:{'cols':4,'rows':4}
             for name in ('locomotion','actions','reactions')},'clips':[
          clip('neutral_idle','Spoczynek','neutral','locomotion',1,4,250,True,indices=[1,1,2,2]),
          clip('neutral_walk','Chód spokojny','neutral','locomotion',5,8,100,True,align_head=True),
          clip('combat_idle','Gotowość bojowa','combat','locomotion',13,4,250,True),
          clip('combat_walk','Chód w gotowości','combat','actions',1,8,100,True,align_head=True),
          clip('attack',ATTACKS[role],'combat','actions',9,8,[160,130,110,90,80,100,160,170]),
          clip('block','Osłona / unik','combat','reactions',1,4,[140,100,120,180]),
          clip('hit','Reakcja na trafienie','combat','reactions',5,4,[90,90,130,180]),
          clip('death','Upadek / śmierć','combat','reactions',9,8,[150,150,140,130,130,150,200,1000],reference_index=5)
        ]}
        if role=='warrior':
            cfg['sheets']['combat_walk_repair']={'cols':4,'rows':4}
            next(c for c in cfg['clips'] if c['id']=='combat_walk')['sheet']='combat_walk_repair'
        if role=='archer_1' and (profile/'raw/attack_aim.png').is_file():
            cfg['sheets']['attack_aim']={'cols':4,'rows':2,'matte':True}
            attack=next(c for c in cfg['clips'] if c['id']=='attack')
            attack.update(sheet='attack_aim',start=1,durations=[160,200,220,300,380,80,200,260],align_feet=True)
        (profile/'clips_source.json').write_text(json.dumps(cfg,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('DRAWN_ROLE_CONFIG_PASS',len(ROLES))

if __name__=='__main__':main()
