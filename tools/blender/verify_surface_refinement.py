"""Reuse the pinned actual FBX/source harness; add refinement preservation gates."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
BEFORE=ROOT/'assets_src/characters/painted_candidates/2026-11-02'
AFTER=ROOT/'assets_src/characters/surface_refinement/2026-11-02'


def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()


delivery=json.loads((BEFORE/'delivery.json').read_text())
harness=ROOT/'tools/blender/verify_painted_candidates.py'
assert digest(harness)==delivery['source_tools'][harness.relative_to(ROOT).as_posix()]
source=harness.read_text()
replacements={
    "BASE=ROOT/'assets_src/characters/painted_candidates/2026-11-02'":"BASE=ROOT/'assets_src/characters/surface_refinement/2026-11-02'",
    "0<meta['triangles']<50000":"0<meta['triangles']<120000",
}
for old,new in replacements.items():
    assert source.count(old)==1,'harness contract changed'
    source=source.replace(old,new)
scope={'__file__':str(harness)}
exec(compile(source,'<pinned FBX and source harness>', 'exec'),scope)
require=scope['require'];before_checks=scope['checks']
for item in delivery['files']:require(digest(BEFORE/item['path'])==item['sha256'],'stage39 unchanged '+item['path'])
for path,sha in delivery['source_tools'].items():require(digest(ROOT/path)==sha,'stage39 tool unchanged '+path)
comparisons=[]
for ident in ['01_mercenary','02_warden','03_wayfarer']:
    old=json.loads((BEFORE/ident/'model.json').read_text())
    new=json.loads((AFTER/ident/'model.json').read_text())
    ref=new['refinement']
    require(ref['baseline_model_sha256']==digest(BEFORE/ident/'model.json'),ident+' exact before identity')
    require(ref['baseline_delivery_sha256']==digest(BEFORE/'delivery.json'),ident+' exact package reference')
    require(old['camera']==new['camera'],ident+' matched review camera')
    drift=max(abs(a-b) for ra,rb in zip(old['bounds'],new['bounds']) for a,b in zip(ra,rb))
    require(drift<.015,ident+' no silhouette inflation: bounding extremes under15mm')
    require(any(x['operation'].startswith('monotone') for x in ref['changes']),ident+' curved profiles')
    require(any(x['operation'].startswith('Catmull') for x in ref['changes']),ident+' actual curved cage')
    for name in ['concept.png','projection-padded.png','projection-silhouette.json']:
        require(digest(BEFORE/ident/name)==digest(AFTER/ident/name),ident+' original reference preserved '+name)
    comparisons.append(dict(id=ident,before_triangles=old['triangles'],after_triangles=new['triangles'],
                            maximum_bounds_drift_metres=drift,camera_matched=True,baseline_preserved=True))
result=json.loads((AFTER/'verification.json').read_text())
result.update(checks=scope['checks'],refinement_additional_checks=scope['checks']-before_checks,
              original_stage39_delivery_files=len(delivery['files']),comparisons=comparisons,
              independent_reviewer=False,user_art_acceptance='PENDING')
(AFTER/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print('SURFACE_REFINEMENT_PASS '+str(result['checks'])+' checks; 3 actual FBX reimports; stage39 unchanged')
