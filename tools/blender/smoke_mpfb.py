"""Actual background MPFB registration/human creation compatibility probe."""
from pathlib import Path
import json
import sys
import bpy

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from mpfb_runtime import enable_mpfb, ASSETS, INSTALL

human_service, target_service, location_service = enable_mpfb()
macro = target_service.get_default_macro_info_dict()
macro.update(gender=1.0, age=.57, muscle=.63, weight=.48, height=.55)
macro['race'] = dict(caucasian=1.0, asian=0.0, african=0.0)
human = human_service.create_human(macro_detail_dict=macro)
assert len(human.data.polygons) > 1000
report = dict(blender=bpy.app.version_string, module='bl_ext.sdd_mpfb.mpfb',
              user_data=location_service.get_user_data(), human=human.name,
              vertices=len(human.data.vertices), faces=len(human.data.polygons),
              bounds=[[min(v.co[i] for v in human.data.vertices), max(v.co[i] for v in human.data.vertices)] for i in range(3)],
              vertex_groups=[g.name for g in human.vertex_groups],
              eyes=[str(p.relative_to(ASSETS)) for p in ASSETS.glob('eyes/**/*.mhclo')],
              hair=[str(p.relative_to(ASSETS)) for p in ASSETS.glob('hair/**/*.mhclo')],
              skins=[str(p.relative_to(ASSETS)) for p in ASSETS.glob('skins/**/*.mhmat')])
(ROOT/'artifacts/mpfb-smoke.json').write_text(json.dumps(report, indent=2)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'artifacts/mpfb-smoke.blend'))
print('MPFB_CREATE_HUMAN_PASS '+json.dumps({k:v for k,v in report.items() if k not in ('vertex_groups','skins','hair','eyes')}))
