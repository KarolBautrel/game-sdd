"""Test installed art tools in an owned factory-startup Blender, no GUI."""
import bpy
import sys
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
SKILLS=Path.home()/'.codex/skills'
for name in ['expert','sculpting','hard-surface','texturing-shading','uv-baking']:
    sys.path.insert(0,str(SKILLS/('scenario-blender-'+name)/'scripts'))
import bx_audit as audit
import bx_sculpt as sculpt
import bx_hardsurface as hard
import bx_materials as materials
import bx_uvbake as uv
sys.path.insert(0,str(Path.home()/'.codex/tools/character-art/profile/scripts/addons'))
import addon_utils
addon_utils.enable('ucupaint',default_set=True,persistent=False)
assert 'ucupaint' in bpy.context.preferences.addons
bpy.ops.mesh.primitive_cube_add()
cube=bpy.context.object;cube.name='ToolSmoke'
bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
result=bpy.ops.wm.y_quick_ypaint_node_setup(type='EMISSION',tree_name='Painted tool smoke',
    enable_metallic=False,enable_roughness=False,enable_height=False,enable_normal=False,switch_to_material_view=False)
assert result=={'FINISHED'}
groups=[n for n in bpy.data.node_groups if hasattr(n,'yp') and n.yp.is_ypaint_node]
assert groups
cube.data.uv_layers.active.name='BakedAtlas'
layer_result=bpy.ops.wm.y_new_layer(name='Painted diffuse',type='IMAGE',width=64,height=64,
    channel_idx='0',uv_map='BakedAtlas',blend_type='MIX')
assert layer_result=={'FINISHED'}
from ucupaint.common import get_layer_source
root_group=groups[0]
assert root_group.yp.layers
image_layer=root_group.yp.layers[root_group.yp.active_layer_index]
assert get_layer_source(image_layer).image is not None
gate=audit.deliverable([cube],profile='render')
assert gate['pass'],gate
clay=sculpt.Clay((-.05,-.04,-.06),(.05,.04,.06),.004)
clay.add(sculpt.sd_round_box((0,0,0),(.035,.025,.045),.006))
obj=clay.to_object('Closed_anatomical_form',symmetric=False)
report=sculpt.stage_report(obj)
assert report['components']==1,report
out=ROOT/'artifacts/painted-tool-smoke';out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'tools.blend'))
data=dict(status='PASS',blender=bpy.app.version_string,skill_modules=['bx_audit','bx_sculpt','bx_hardsurface','bx_materials','bx_uvbake'],
          ucupaint='3.0.0 no-auto-update',ucupaint_nodes=len(groups),ucupaint_setup=True,ucupaint_image_layer=True,audit=gate,sculpt=report,
          gui_brush_strokes=False)
(out/'report.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
print('PAINTED_TOOL_SMOKE_PASS')
