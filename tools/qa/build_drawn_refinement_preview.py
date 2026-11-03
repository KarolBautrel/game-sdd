"""Package retained-before/current-after atlases in a focused offline player."""
import json
from pathlib import Path
import struct
import sys

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/drawn_animation/2026-11-03'
OUT=BASE/'refinements'
VIEWS={'south_east':'Przód3/4','north_east':'Tył3/4','north':'Tył','east':'Prawy profil',
       'south':'Przód','south_west':'Przód3/4 odbity','west':'Lewy profil odbity','north_west':'Tył3/4 odbity'}
cases=[]
registry=json.loads((ROOT/'resources/data/presentation/drawn_roster.json').read_text(encoding='utf-8'))
for p in registry['profiles']:
    for view,label in VIEWS.items():
        if '--drawn-only' in sys.argv and view in ('south_west','west','north_west'):continue
        folder=BASE/p['id']
        if view!='south_east':folder=folder/'directions'/view
        old=OUT/'before'/folder.relative_to(ROOT)
        current=json.loads((folder/'manifest.json').read_text(encoding='utf-8'))
        previous=json.loads((old/'manifest.json').read_text(encoding='utf-8'))
        for clip in current['clips']:
            action=clip['id']
            topic=('idle' if action in ('neutral_idle','combat_idle') else 'bow' if
                   p['id']=='archer_1' and action=='attack' else 'shield' if
                   p['id']=='warrior' and view in ('north','north_east','north_west') else None)
            if topic is None:continue
            # Rear shield idles are accessible under the shield tab as well.
            topics=[topic]
            if topic=='idle' and p['id']=='warrior' and view in ('north','north_east','north_west'):topics.append('shield')
            before=next(c for c in previous['clips'] if c['id']==action)
            entry={}
            for name,home,c in [('old',old,before),('new',folder,clip)]:
                image=home/c['atlas'];header=image.read_bytes()[:24]
                assert struct.unpack('>II',header[16:24])==(384*c['frames'],320),image
                import os
                entry[name]={'atlas':os.path.relpath(image,OUT).replace('\\','/'),'frames':c['frames'],
                             'durations':c['durations'],'loop':c['loop']}
            for topic in topics:
                note={'idle':'Stopy i dolna część goleni pozostają w jednym miejscu; oddech tułowia jest zachowany.',
                      'shield':'Od tyłu widać drewniane wnętrze, pasy i chwyt tarczy. Przednia strona zachowuje zdobienie.',
                      'bow':'Wyżej uniesiony łokieć, mocniejszy naciąg i celowanie. Atak1,80s; wypuszczenie strzały po1,26s.'}[topic]
                cases.append(dict(topic=topic,label=p['label']+' · '+label+' · '+clip['title'],note=note,**entry))
data={'cases':cases,'floor':'../../../../../assets/combat/environment/floors/woodland.png',
      'shadow':'../../../../../assets/combat/environment/contact_shadow.png'}
for key in ('floor','shadow'):assert (OUT/data[key]).is_file(),data[key]
template=(ROOT/'tools/qa/drawn_refinement_player.html').read_text(encoding='utf-8')
(OUT/'preview.html').write_text(template.replace('__REFINEMENT_DATA__',json.dumps(data,ensure_ascii=False)),encoding='utf-8')
(OUT/'player_data.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('DRAWN_REFINEMENT_PREVIEW_PASS',len(cases),'before/after samples')
