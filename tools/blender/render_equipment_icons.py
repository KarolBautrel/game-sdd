"""Render actual authored equipment parts for the shared campaign item cards."""
import sys
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
import build_roster as base
source=ROOT/'assets_src/characters/modular/warrior/warrior.blend'
out=ROOT/'assets_src/equipment-icons';out.mkdir(parents=True,exist_ok=True)
(out/'.gdignore').write_text('Authoring renders; normalize with Aseprite\n')
for ident,channel,z,ortho in [('leather_boots','boots_leather',.29,.85),('steel_boots','boots_steel',.29,.85),('leather_cap','helmet_cap',1.86,.52),('closed_helm','helmet_closed',1.77,.62),('weathered_cuirass','armor_plate',1.23,.92)]:
    bpy.ops.wm.open_mainfile(filepath=str(source))
    for obj in list(bpy.data.objects):
        if obj.type not in ('ARMATURE','MESH'):bpy.data.objects.remove(obj,do_unlink=True)
        elif obj.type=='MESH':obj.hide_render=obj.name!='part_'+channel
    scene,camera=base.scene_setup();scene.cycles.samples=12
    scene.render.resolution_x=scene.render.resolution_y=192
    base.camera_view(camera,330,12,ortho,z)
    scene.render.filepath=str(out/(ident+'.png'));bpy.ops.render.render(write_still=True)
print('EQUIPMENT_ICONS_PASS')
