"""Build original cast members from the canonical design manifest.

--ids comma,separated selects a batch; --preview renders representative views
without replacing the runtime frames. All Blender work is an owned background job.
"""
import argparse
import json
import hashlib
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector, Matrix, Quaternion

sys.path.insert(0,str(Path(__file__).resolve().parent))
from roster_geometry import Geometry, humanoid, attachments

ROOT=Path(__file__).resolve().parents[2]
DATA=json.loads((ROOT/"resources/data/presentation/original_roster.json").read_text())


def reset_pose(rig):
    rig.animation_data.action=None
    for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()


def arm_ik(rig,side,target,pole):
    upper=rig.pose.bones["upperarm_"+side]
    lower=rig.pose.bones["lowerarm_"+side]
    shoulder=upper.head.copy();target=Vector(target)
    direction=target-shoulder;distance=min(direction.length,upper.length+lower.length-.004)
    direction.normalize()
    bend=Vector(pole)-direction*Vector(pole).dot(direction);bend.normalize()
    a=(upper.length**2-lower.length**2+distance**2)/(2*distance)
    elbow=shoulder+direction*a+bend*math.sqrt(max(.0001,upper.length**2-a*a))
    wrist=shoulder+direction*distance
    for b,start,end in [(upper,shoulder,elbow),(lower,elbow,wrist)]:
        rest=rig.data.bones[b.name]
        q=(rest.tail_local-rest.head_local).rotation_difference(end-start) @ rest.matrix_local.to_quaternion()
        b.matrix=Matrix.Translation(start) @ q.to_matrix().to_4x4()
        bpy.context.view_layer.update()
    hand=rig.pose.bones["hand_"+side];rest=rig.data.bones[hand.name]
    q=(rest.tail_local-rest.head_local).rotation_difference(Vector((0,-1,0))) @ rest.matrix_local.to_quaternion()
    hand.matrix=Matrix.Translation(wrist) @ q.to_matrix().to_4x4()
    bpy.context.view_layer.update()


def ranged_actions(rig,weapon):
    names=[]
    for label,keys in [("Ready",[(0,.55),(10,.58),(20,.55),(32,.55)]),
                       ("Release",[(0,.55),(8,1),(15,1),(19,.05),(25,.1),(32,.55)])]:
        reset_pose(rig)
        action=bpy.data.actions.new(weapon+label)
        rig.animation_data.action=action
        for frame,draw in keys:
            for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
            bpy.context.view_layer.update()
            if weapon=="bow":
                arm_ik(rig,"l",(.03,-.43,1.52),(1,0,.1))
                arm_ik(rig,"r",(.03,-.40+.30*draw,1.52+.08*draw),(-1,.1,.1))
            else:
                recoil=(-.26*draw if label=="Release" else .008*math.sin(frame/32*math.tau)) if weapon=="spear" else .04*math.sin(frame/32*math.tau)
                arm_ik(rig,"r",(-.025,-.27+recoil,1.28),(-1,0,-.2))
                arm_ik(rig,"l",(.04,-.43+recoil,1.28),(1,0,-.2))
            for b in rig.pose.bones:
                b.rotation_mode="QUATERNION"
                b.keyframe_insert(data_path="rotation_quaternion",frame=frame)
        action.use_fake_user=True;names.append(action.name)
    return names


def wraith_death(rig):
    reset_pose(rig)
    rig.animation_data.action=bpy.data.actions["Idle_Loop"]
    bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
    ready={b.name:b.matrix_basis.copy() for b in rig.pose.bones}
    clip=bpy.data.actions.new("Wraith_Dissolve");clip.use_fake_user=True
    rig.animation_data.action=clip
    for b in rig.pose.bones:b.matrix_basis=ready[b.name]
    pelvis=rig.pose.bones["pelvis"]
    origin=pelvis.location.copy()
    inverse=rig.data.bones["pelvis"].matrix_local.to_3x3().inverted()
    for frame in range(0,33,4):
        t=frame/32
        pelvis.location=origin+inverse @ Vector((0,0,-.50*t))
        pelvis.scale=(1-.30*t,1-.70*t,1-.30*t)
        for b in rig.pose.bones:
            b.keyframe_insert(data_path="location",frame=frame);b.keyframe_insert(data_path="scale",frame=frame)
            b.keyframe_insert(data_path="rotation_quaternion",frame=frame)
    return clip.name


def long_weapon_clips(rig,geometry):
    # A sword-hand clip cannot carry a1.7m spear without a fitted wrist socket.
    # Keep the shaft above the floor and preserve the original arm/body motion.
    hand=rig.pose.bones["hand_r"];rest=rig.data.bones["hand_r"].matrix_local
    ready_deform=hand.matrix @ rest.inverted()
    bind_axis=ready_deform.to_3x3().inverted() @ Vector((0,-.87,.49)).normalized()
    bind_vertices=[]
    for obj in geometry.parts:
        group=obj.vertex_groups.get("hand_r")
        if group:
            bind_vertices.extend(v.co.copy() for v in obj.data.vertices if any(w.group==group.index and w.weight>.5 for w in v.groups))
    result={}
    for kind,source_name,name,target in [
        ("walk","Walk_Loop","Spear_CarryWalk",(0,-.4,.9165)),
        ("hit","Hit_Chest","Spear_CarryHit",(0,-.5,.866)),
        ("death","Death01","Spear_GroundedDeath",(0,-1,.035))]:
        source=bpy.data.actions[source_name];samples=[]
        start,end=source.frame_range
        for index in range(33):
            reset_pose(rig);rig.animation_data.action=source
            t=index/32;value=start+(end-start)*t
            bpy.context.scene.frame_set(math.floor(value),subframe=value%1)
            bpy.context.view_layer.update()
            axis=(hand.matrix @ rest.inverted()).to_3x3() @ bind_axis
            desired=Vector(target).normalized()
            rotation=axis.rotation_difference(desired) @ hand.matrix.to_quaternion()
            hand.matrix=Matrix.Translation(hand.head.copy()) @ rotation.to_matrix().to_4x4()
            bpy.context.view_layer.update()
            deform=hand.matrix @ rest.inverted()
            lowest=min((deform @ vertex).z for vertex in bind_vertices)
            if lowest<.05:
                fitted=hand.matrix.copy();fitted.translation.z+=.05-lowest
                hand.matrix=fitted;bpy.context.view_layer.update()
            samples.append({bone.name:bone.matrix_basis.copy() for bone in rig.pose.bones})
        reset_pose(rig);clip=bpy.data.actions.new(name);clip.use_fake_user=True
        rig.animation_data.action=clip
        for index,sample in enumerate(samples):
            for bone in rig.pose.bones:
                bone.matrix_basis=sample[bone.name]
                for path in ("location","rotation_quaternion","scale"):bone.keyframe_insert(data_path=path,frame=index)
        result[kind]=clip.name
    return result


def scene_setup():
    scene=bpy.context.scene
    scene.render.engine="CYCLES"
    scene.cycles.device="CPU";scene.cycles.samples=6
    scene.render.use_persistent_data=True
    scene.render.threads_mode="FIXED";scene.render.threads=6
    scene.render.film_transparent=True
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG";scene.render.image_settings.color_mode="RGBA"
    scene.view_settings.view_transform="Khronos PBR Neutral"
    scene.world=bpy.data.worlds.new("Roster neutral studio");scene.world.use_nodes=True
    scene.world.node_tree.nodes.get("Background").inputs[0].default_value=(.28,.28,.28,1)
    scene.world.node_tree.nodes.get("Background").inputs[1].default_value=.65
    for name,loc,power,size in [("Key",(-3,-4,5),650,3),("Fill",(4,-3,3),240,4),("Rim",(1,4,4),340,3)]:
        bpy.ops.object.light_add(type="AREA",location=loc)
        obj=bpy.context.object;obj.name=name;obj.data.energy=power;obj.data.size=size
        obj.rotation_euler=(Vector((0,0,1))-obj.location).to_track_quat("-Z","Y").to_euler()
    bpy.ops.object.camera_add();camera=bpy.context.object;camera.data.type="ORTHO";scene.camera=camera
    return scene,camera


def camera_view(camera,yaw,elevation=18,ortho=5.12,z=.95):
    azimuth,pitch=math.radians(yaw),math.radians(elevation)
    target=Vector((0,0,z))
    camera.location=target+Vector((math.sin(azimuth)*6*math.cos(pitch),-math.cos(azimuth)*6*math.cos(pitch),6*math.sin(pitch)))
    camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.ortho_scale=ortho
    bpy.context.view_layer.update()


def bake_albedo(actor,destination):
    bpy.ops.object.select_all(action="DESELECT");actor.select_set(True)
    bpy.context.view_layer.objects.active=actor
    actor.data.uv_layers.new(name="BakeUV")
    actor.data.uv_layers.active=actor.data.uv_layers["BakeUV"]
    bpy.ops.object.mode_set(mode="EDIT");bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.015)
    bpy.ops.object.mode_set(mode="OBJECT")
    image=bpy.data.images.new("Baked_Albedo",width=1024,height=1024,alpha=True)
    outputs=[]
    for slot in actor.material_slots:
        mat=slot.material;nodes=mat.node_tree.nodes;links=mat.node_tree.links
        bsdf=nodes.get("Principled BSDF");output=nodes.get("Material Output")
        original=output.inputs["Surface"].links[0].from_socket
        emit=nodes.new("ShaderNodeEmission")
        source=bsdf.inputs["Base Color"].links[0].from_socket
        links.new(source,emit.inputs["Color"]);links.new(emit.outputs[0],output.inputs["Surface"])
        tex=nodes.new("ShaderNodeTexImage");tex.image=image;nodes.active=tex
        outputs.append((mat,output,original,emit,tex,bsdf))
    bpy.context.scene.cycles.samples=1
    bpy.context.scene.render.bake.margin=8
    bpy.ops.object.bake(type="EMIT")
    image.filepath_raw=str(destination);image.file_format="PNG";image.save()
    for mat,out,original,emit,tex,bsdf in outputs:
        mat.node_tree.links.new(original,out.inputs["Surface"])
        mat.node_tree.links.new(tex.outputs["Color"],bsdf.inputs["Base Color"])
        mat.node_tree.nodes.remove(emit)
    actor.data.uv_layers.remove(actor.data.uv_layers["DesignPatch"])
    return image


def build(profile):
    ident=profile["id"]
    source=ROOT/"assets_src/characters/roster"/ident
    output=ROOT/"artifacts/roster"/ident
    source.mkdir(parents=True,exist_ok=True);(source/"textures").mkdir(exist_ok=True)
    (source/".rendering").write_text("Owned background render in progress\n")
    output.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    biped=profile["kind"] in ("human","skeleton","ogre","goblin","lizard","wraith")
    reference=ROOT/"assets_src/characters/roster/references"/(ident+".png")
    expected=next(r for r in json.loads((ROOT/"assets_src/characters/roster/references.json").read_text()) if r["id"]==ident)
    assert hashlib.sha256(reference.read_bytes()).hexdigest()==expected["sha256"], "Reference changed: "+ident
    if biped:
        library=next((Path.home()/".codex/tools/character-art/animations/universal-animation-library").rglob("UAL1_Standard.glb"))
        bpy.ops.import_scene.gltf(filepath=str(library))
        rig=next(o for o in bpy.data.objects if o.type=="ARMATURE")
        for obj in list(bpy.data.objects):
            if obj!=rig:bpy.data.objects.remove(obj,do_unlink=True)
        reset_pose(rig)
        for track in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(track)
        geometry=Geometry(rig);mats=humanoid(geometry,profile)
        ready="Idle_Loop";combat="Sword_Attack"
        if profile["weapon"] in ("bow","crossbow","spear"):
            ready,combat=ranged_actions(rig,profile["weapon"])
        rig.animation_data.action=bpy.data.actions[ready]
        bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
        attachments(geometry,profile,mats)
        actions={"pose":ready,"walk":"Walk_Loop","combat":combat,"hit":"Hit_Chest","death":"Death01"}
        if profile["kind"]=="wraith":actions["death"]=wraith_death(rig)
        if profile["weapon"]=="spear":actions.update(long_weapon_clips(rig,geometry))
    else:
        from roster_creatures import create_creature
        geometry,rig,actions=create_creature(profile)
    rig.name=ident+"_Rig"
    rig.scale=(profile["scale"],)*3
    reset_pose(rig)
    actor=geometry.join();actor.name=ident+"_OriginalMesh"
    scene,camera=scene_setup()
    image=bake_albedo(actor,source/"textures"/(ident+"_albedo.png"))
    for action in list(bpy.data.actions):
        if action.name not in actions.values():bpy.data.actions.remove(action)
        else:action.use_fake_user=True
    w,h=(640,448) if profile["weapon"]=="spear" else (512,384)
    ortho=w/100.0
    pivot=[w//2,round(h/2+.95*math.cos(math.radians(18))*100)]
    scene.render.resolution_x=w;scene.render.resolution_y=h
    scene.cycles.samples=4

    def pose(action,t):
        reset_pose(rig)
        clip=bpy.data.actions[actions[action]];rig.animation_data.action=clip
        start,end=clip.frame_range;frame=float(start+(end-start)*t)
        scene.frame_set(math.floor(frame),subframe=frame%1)
        bpy.context.view_layer.update()
        rig.location=(0,0,0)
        if biped and action=="death":
            pelvis=rig.pose.bones["pelvis"].head;rest=rig.data.bones["pelvis"].head_local
            rig.location.x=(rest.x-pelvis.x)*profile["scale"]
            rig.location.y=(rest.y-pelvis.y)*profile["scale"]
        bpy.context.view_layer.update()

    pose("pose",0);camera_view(camera,315,ortho=ortho)
    image.filepath="//textures/"+ident+"_albedo.png"
    bpy.ops.wm.save_as_mainfile(filepath=str(source/(ident+".blend")))
    if args.preview:
        for label,yaw,elevation in [("front",0,5),("side",90,5),("rear",180,5),("game",DATA["camera"]["yaw"]["east"],18)]:
            pose("pose",0);camera_view(camera,yaw,elevation,ortho=ortho)
            scene.render.filepath=str(output/("preview-"+label+".png"));bpy.ops.render.render(write_still=True)
        for action in ("combat","death"):
            pose(action,.48 if action=="combat" else 1)
            camera_view(camera,315,ortho=ortho)
            scene.render.filepath=str(output/("preview-"+action+".png"));bpy.ops.render.render(write_still=True)
    else:
        for action,count in DATA["frame_counts"].items():
            if action not in args.actions.split(","):continue
            folder=output/"raw"/action;folder.mkdir(parents=True,exist_ok=True)
            for direction,yaw in DATA["camera"]["yaw"].items():
                if direction not in args.directions.split(","):continue
                camera_view(camera,yaw,ortho=ortho)
                for frame in range(count):
                    pose(action,frame/(count if action in ("pose","walk") else count-1))
                    scene.render.filepath=str(folder/f"{ident}_{direction}_{action}_{frame:03}.png")
                    bpy.ops.render.render(write_still=True)
            print("ROSTER_ACTION",ident,action,flush=True)
    pose("pose",0)
    scene.render.resolution_x=scene.render.resolution_y=256
    target_z=1.69*profile["scale"] if biped else .65
    camera_view(camera,330,5,ortho=.65*profile["scale"] if biped else 1.4,z=target_z)
    scene.render.filepath=str(output/"portrait.png");bpy.ops.render.render(write_still=True)
    # Save deliverable at the canonical tactical pose/camera, not portrait framing.
    scene.render.resolution_x=w;scene.render.resolution_y=h
    camera_view(camera,315,ortho=ortho)
    bpy.ops.wm.save_as_mainfile(filepath=str(source/(ident+".blend")))
    bpy.ops.object.select_all(action="DESELECT");actor.select_set(True);rig.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.fbx(filepath=str(source/(ident+".fbx")),use_selection=True,
        object_types={"MESH","ARMATURE"},add_leaf_bones=False,axis_forward="-Z",axis_up="Y",
        path_mode="RELATIVE",bake_anim=True,bake_anim_use_all_actions=True,bake_anim_use_nla_strips=False)
    report={"id":ident,"kind":profile["kind"],"label":profile["label"],"canvas_size":[w,h],"pivot":pivot,
        "camera_elevation":18,"pixels_per_metre":100,"triangles":sum(len(p.vertices)-2 for p in actor.data.polygons),
        "vertices":len(actor.data.vertices),"bones":len(rig.data.bones),"uv":bool(actor.data.uv_layers),
        "weighted":all(v.groups for v in actor.data.vertices),"actions":actions,"frame_counts":DATA["frame_counts"],
        "preview_only":args.preview,"legacy_reference":"../references/"+ident+".png"}
    assert report["weighted"] and report["uv"] and report["triangles"]<22000
    if not args.preview:
        assert all((output/"raw"/action/f"{ident}_{direction}_{action}_{frame:03}.png").exists()
            for action,count in DATA["frame_counts"].items() for direction in DATA["camera"]["yaw"] for frame in range(count)),"Partial action delivery"
    (source/"model.json").write_text(json.dumps(report,indent=2)+"\n")
    (source/".rendering").unlink()
    print("ROSTER_MODEL_PASS",json.dumps(report),flush=True)


def main():
    global args
    parser=argparse.ArgumentParser()
    parser.add_argument("--ids",required=True)
    parser.add_argument("--preview",action="store_true")
    parser.add_argument("--actions",default="pose,walk,combat,hit,death")
    parser.add_argument("--directions",default="south,south_west,west,north_west,north,north_east,east,south_east")
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    for selected in args.ids.split(","):
        build(next(row for row in DATA["characters"] if row["id"]==selected))


if __name__=="__main__":main()
