"""Verify the completed isolated motion review delivery and hash its files."""
import hashlib
import json
from pathlib import Path
import struct

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets_src/characters/warden_motion_pilot/2026-11-03'


def main():
    for name in ('rig_verification.json','motion_verification.json','preview_verification.json','render_pixel_verification.json'):
        doc=json.loads((OUT/name).read_text());assert doc['status'].startswith(('PASS','TECHNICAL_PASS'))
    for clip,count in [('Idle',48),('Walk',32),('Sword',40)]:
        for view in ('three_quarter','front','side','rear'):
            path=OUT/'aseprite'/(clip+'_'+view+'.aseprite')
            raw=path.read_bytes();header=raw[:128]
            assert struct.unpack_from('<HHHH',header,4)==(0xA5E0,count,384,384),str(path)
            offset=128;durations=set()
            for _ in range(count):
                size,magic=struct.unpack_from('<IH',raw,offset);assert magic==0xF1FA
                durations.add(struct.unpack_from('<H',raw,offset+8)[0]);offset+=size
            assert durations=={42} and offset==len(raw),'Aseprite frame timing '+str(path)
    for name in ('motion_review.png','motion_review.aseprite','direction_review.png','direction_review.aseprite',
                 'warden_bound.blend','warden_motion.blend','warden_motion.fbx','README.md','preview.html','player.js','visual_review.json'):
        assert (OUT/name).stat().st_size>0,name
    scripts=['tools/blender/build_warden_motion.py','tools/blender/verify_warden_motion.py','tools/aseprite/warden_motion.lua',
             'tools/qa/build_warden_motion_preview.py','tools/qa/warden_motion_player.html','tools/qa/warden_motion_player.js',
             'tools/qa/start_warden_motion_preview.ps1','tools/qa/finalize_warden_motion.py']
    source=ROOT/'assets_src/characters/mpfb_warden_boots_only/2026-11-02/warden_restored.blend'
    provenance=dict(owner='presentation018 / slice018 / milestone013',baseline=source.relative_to(ROOT).as_posix(),
        baseline_blend_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),tools=dict(blender='5.2.3 LTS',aseprite='1.3.17.2'),
        method='Manual fitted29-bone FK rig, explicit semantic weights, authored analytic FK motion; no purchased/generated external motion',
        retained_maps_and_licences='Byte-identical selected stage43 maps; inherited licences copied in licenses/',
        sword='Original code-authored separate prop in build_warden_motion.py',
        scripts_sha256={n:hashlib.sha256((ROOT/n).read_bytes()).hexdigest() for n in scripts},
        runtime_changed=False,paid_calls=0,downloads=0,os_input_used=False)
    (OUT/'provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
    files=[]
    for p in sorted(OUT.rglob('*')):
        if not p.is_file() or p.name=='delivery.json' or p.suffix in ('.blend1','.blend2'):continue
        files.append(dict(path=p.relative_to(OUT).as_posix(),bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
    delivery=dict(schema='sdd.warden-motion-pilot-v1',completed='2026-11-03',status='TECHNICAL_PASS_AWAITING_USER_MOTION_REVIEW',
        source_art_only=True,runtime_replaced=False,continuous_playback_reviewed=False,browser_ui_tested=False,
        file_count=len(files),total_bytes=sum(f['bytes'] for f in files),files=files)
    (OUT/'delivery.json').write_text(json.dumps(delivery,indent=2)+'\n')
    print('WARDEN_DELIVERY_PASS',len(files),'files',delivery['total_bytes'],'bytes; user motion/browser/game review pending')


if __name__=='__main__':main()
