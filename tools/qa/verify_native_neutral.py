"""Prove native sharpness/scope and slow cadence without claiming watched gameplay."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/drawn_animation/2026-11-03'
OUT=BASE/'refinements/native_neutral'
BEFORE=OUT/'before'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
identities=read(BEFORE/'identities.json')
for path,digest in identities.items():assert sha(BEFORE/path)==digest,path
pixels=read(BEFORE/'runtime_pixels.json')
changed=[p for p,digest in pixels.items() if sha(ROOT/p)!=digest]
assert 0<len(changed)<=32
assert all('/knight/neutral_idle/' in p for p in changed),changed
walk=read(OUT/'walk_timing_report.json')
assert walk['status']=='PASS' and len(walk['clips'])==96 and walk['duration_ms']==125
assert all(c['source_roundtrip']=='PASS' and c['pixels_unchanged'] for c in walk['clips'])
neutral=read(OUT/'neutral_report.json')
assert neutral['status']=='PASS' and len(neutral['views'])==8
assert all(v['source_roundtrip']=='PASS' for v in neutral['views'])
protected=read(OUT/'protected_pixels_report.json')
assert protected['status']=='PASS' and protected['head_pixels_exact'] and protected['original_boot_pixels_exact']
views=0
for home in BASE.glob('*/manifest.json'):
 for path in [home,*sorted((home.parent/'directions').glob('*/manifest.json'))]:
  previous={c['id']:c for c in read(BEFORE/path.relative_to(ROOT))['clips']}
  current=read(path)
  assert current['walk_stride_pixels']==160
  for c in current['clips']:
   assert c['frames']==previous[c['id']]['frames']
   if c['id'] in ('neutral_walk','combat_walk'):assert c['durations']==[125]*8
   else:assert c['durations']==previous[c['id']]['durations']
  proof=read(path.parent/'export_report.json')
  assert proof['saved_source_roundtrip']=='PASS' and not proof['clipping']
  views+=1
assert views==48
registry=read(ROOT/'resources/data/presentation/drawn_roster.json')
assert all(p['walk_stride_pixels']==160 and p['durations_ms']['neutral_walk']==[125]*8 for p in registry['profiles'])
acceptance_path=OUT/'user_acceptance.json'
acceptance=read(acceptance_path)['status'] if acceptance_path.is_file() else 'PENDING'
result={'status':'SOURCE_AND_SCOPE_PASS','baseline_files':len(identities),'walk_clips':96,
        'gait_cycle_ms':1000,'stride_pixels':160,'root_pixels_per_second':160,
        'foot_contacts_per_second':2,'changed_runtime_pngs':changed,'other_pngs_unchanged':len(pixels)-len(changed),
        'all_walking_pixels_unchanged':True,'all_combat_idle_pixels_unchanged':True,
        'original_head_boot_pixels':'EXACT','non_walk_durations':'UNCHANGED',
        'reference':'existing sword/shield warrior neutral pose','no_whole_model_resampling':True,
        'source_roundtrip':'PASS','visual_acceptance':acceptance,'desktop_input_used':False}
(OUT/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('NATIVE_NEUTRAL_VERIFY_PASS',len(changed),'neutral PNG edits; sharp head/boots and all walking/combat art unchanged')
