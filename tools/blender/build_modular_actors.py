"""Rigged, interchangeable equipment actors for the existing2D tactical board."""
import argparse,json,math,sys
from pathlib import Path
import bpy,bmesh
from mathutils import Vector,Matrix,Quaternion
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_roster as base
from roster_geometry import Geometry,humanoid,attachments
ROOT=Path(__file__).resolve().parents[2]
DATA=base.DATA


class ModularGeometry(Geometry):
    def __init__(self,rig):
        super().__init__(rig);self.channel=None;self.channels=[]
    def mesh(self,name,verts,faces,bone,mat,weights=None):
        label=name.lower()
        channel=self.channel or ("headwear_default" if any(x in label for x in ("hood","helmet","visor","hair cap")) else
            ("boots_default" if label in ("shin","foot") else
            ("armor_default" if label in ("body","shoulder plate","right shoulder plate","steel vambrace","brigandine rivet","crossed leather harness") else "body")))
        if channel not in self.channels:self.channels.append(channel)
        obj=super().mesh(name,verts,faces,bone,mat,weights)
        attr=obj.data.attributes.new("gear_channel","INT","FACE")
        for row in attr.data:row.value=self.channels.index(channel)
        return obj
    def weapon(self,kind,hand,metal,wood,leather,trim):
        if kind=="none":return
        start=len(self.parts);b=self.rig.pose.bones[hand]
        deform=b.matrix @ self.rig.data.bones[hand].matrix_local.inverted();inverse=deform.inverted()
        grip=b.head+(b.tail-b.head).normalized()*.045
        if kind=="bow":
            up=Vector((-.17,0,.985)).normalized();shoot=Vector((.9,-.43,.16)).normalized()
            shoot=(shoot-up*shoot.dot(up)).normalized()
            points=[grip+up*z+shoot*d for z,d in [(-.63,.08),(-.34,.22),(0,0),(.34,.22),(.63,.08)]]
            bow=self.tube("Readable recurved bow",points,[.02,.028,.035,.028,.02],hand,wood)
            nock=self.rig.pose.bones["hand_r"].head.copy()
            string=self.tube("Drawn bowstring",[points[0],nock,points[-1]],.005,hand,trim,6)
            for obj in (bow,string):
                for v in obj.data.vertices:v.co=inverse @ v.co
            right=self.rig.pose.bones["hand_r"]
            ri=(right.matrix @ self.rig.data.bones["hand_r"].matrix_local.inverted()).inverted()
            middle=list(range(6,12))
            for index in middle:
                v=string.data.vertices[index];v.co=ri @ (deform @ v.co)
            string.vertex_groups[hand].remove(middle);string.vertex_groups.new(name="hand_r").add(middle,1,"REPLACE")
            axis=up
        else:
            super().weapon(kind,hand,metal,wood,leather,trim)
            old=Vector((0,-.87,.49)).normalized() if kind=="spear" else Vector((-.06,-.20,-.978)).normalized()
            axis=Vector((.5,-.72,.48)).normalized() if kind=="spear" else Vector((-.42,-.38,-.82)).normalized()
            rotate=old.rotation_difference(axis)
            for obj in self.parts[start:]:
                for v in obj.data.vertices:v.co=inverse @ (grip+rotate @ (deform @ v.co-grip))
        # Palm fingers wrap the handle; the cuff/hand remains visible behind it.
        helper=Vector((1,0,0));u=axis.cross(helper).normalized();v=axis.cross(u).normalized()
        glove=self.material("Glove finger highlights",(.26,.15,.075),atlas=2)
        for i in range(4):
            center=grip+axis*(-.032+i*.021)
            points=[center+(u*math.cos(t)+v*math.sin(t))*.030 for t in (-.65,.15,.95,1.75,2.55)]
            obj=self.tube("Curled grip finger",points,.009,hand,glove,6)
            for vertex in obj.data.vertices:vertex.co=inverse @ vertex.co


def ready_actions(rig,weapon):
    names=[]
    for action in ("pose","combat"):
        base.reset_pose(rig);clip=bpy.data.actions.new(weapon+"_"+action);clip.use_fake_user=True
        rig.animation_data.action=clip
        for frame in range(0,33,4):
            t=frame/32;burst=math.sin(math.pi*max(0,min(1,(t-.12)/.65)))**2 if action=="combat" else 0
            breathe=.012*math.sin(t*math.tau)
            for bone in rig.pose.bones:bone.matrix_basis=Matrix.Identity(4)
            if weapon=="bow":
                draw=.30+.20*burst if t<.60 else .04+.3*max(0,(t-.72)/.28)
                if action=="pose":draw=.33+breathe
                left=Vector((.23,-.34,1.46));shoot=Vector((.9,-.43,.16)).normalized()
                right=left-shoot*draw+Vector((0,0,.06))
                base.arm_ik(rig,"l",left,(1,0,.1));base.arm_ik(rig,"r",right,(-1,.1,0))
            elif weapon=="spear":
                reach=.43*burst if action=="combat" else breathe
                main=Vector((-.18,-.08-reach,1.03+.08*burst))
                support=main+Vector((.20,-.29,.19))
                base.arm_ik(rig,"r",main,(-1,.1,-.2));base.arm_ik(rig,"l",support,(1,.1,-.2))
            elif weapon=="crossbow":
                recoil=.07*burst
                base.arm_ik(rig,"r",(-.12,-.20+recoil,1.16),(-1,0,-.2))
                base.arm_ik(rig,"l",(.13,-.39+recoil,1.20),(1,0,-.2))
            else:
                base.arm_ik(rig,"r",(-.23,-.17,1.04),(-1,0,-.2))
                base.arm_ik(rig,"l",(.26,-.11,1.18),(1,0,-.2))
            # Slightly bent knees, staggered stance, shoulder/hip opposition.
            for name,angle in [("thigh_l",-.11),("calf_l",.17),("thigh_r",.10),("calf_r",.12)]:
                bone=rig.pose.bones[name]
                bone.rotation_quaternion=Quaternion((1,0,0),angle)
            rig.pose.bones["spine_02"].rotation_quaternion=Quaternion((0,0,1),.04+.10*burst+breathe)
            for bone in rig.pose.bones:
                bone.rotation_mode="QUATERNION"
                for path in ("rotation_quaternion","location","scale"):bone.keyframe_insert(data_path=path,frame=frame)
        names.append(clip.name)
    return names


def add_kit(g,mats,profile):
    # Underlayers make empty armour/boot slots a complete clothed character.
    g.channel="body"
    cloth=g.material("Base blue-grey tunic",(.16,.19,.22),atlas=3)
    g.shell("Base tunic",[(.94,.158,.10,.025),(1.08,.177,.112,.02),(1.31,.211,.13,.02),(1.45,.19,.10,.025)],"spine_02",cloth)
    for side,sign in (("l",1),("r",-1)):
        g.limb("Base calf","calf_"+side,[(0,.068),(1,.04)],cloth)
        g.ellipsoid("Base soft shoe",(sign*.089,-.05,.06),(.063,.125,.06),"foot_"+side,mats["leather"])
    for key,mat in [("armor_leather",mats["leather"]),("armor_plate",mats["iron"])]:
        g.channel=key
        g.shell("Fitted torso armour",[(.96,.19,.14,.025),(1.12,.22,.15,.02),(1.32,.25,.165,.02),(1.48,.20,.13,.02)],"spine_02",mat)
        for side in ("l","r"):
            point=g.rig.data.bones["upperarm_"+side].head_local
            g.ellipsoid("Armour pauldron",point,(.14,.13,.115),"upperarm_"+side,mat)
    for key,mat in [("boots_leather",mats["leather"]),("boots_steel",mats["iron"])]:
        g.channel=key
        for side,sign in (("l",1),("r",-1)):
            g.limb("Tall fitted boot","calf_"+side,[(.05,.085),(.20,.09),(1.02,.057)],mat)
            g.ellipsoid("Boot toe",(sign*.089,-.065,.078),(.09,.165,.08),"foot_"+side,mat)
    g.channel="helmet_cap"
    g.shell("Leather cap",[(1.78,.16,.14,.02),(1.9,.12,.12,.02),(1.96,.02,.025,.02)],"Head",mats["leather"])
    g.channel="helmet_closed"
    full_helmet(g,mats)
    g.channel=None


def full_helmet(g,mats):
    g.shell("Enclosed helmet",[(1.52,.13,.15,.01),(1.65,.18,.18,.01),(1.82,.18,.18,.01),(1.96,.12,.12,.01),(2.01,.02,.025,.01)],"Head",mats["iron"])
    g.box("Dark visor opening",(0,-.176,1.755),(.25,.02,.031),"Head",mats["black"])
    g.box("Visor nose guard",(0,-.192,1.70),(.032,.025,.18),"Head",mats["trim"])
    g.tube("Jaw reinforcing rim",[(-.14,-.12,1.57),(0,-.165,1.54),(.14,-.12,1.57)],.018,"Head",mats["trim"])


def carry_actions(rig,weapon,objects):
    """Fit long-weapon wrists on stock locomotion/reactions, preserving legs/hips."""
    hands=("hand_l","hand_r")
    ready={name:rig.pose.bones[name].matrix.copy() for name in hands}
    vertices=[]
    for obj in objects:
        for vertex in obj.data.vertices:
            group=obj.vertex_groups[vertex.groups[0].group].name
            if group in hands:vertices.append((vertex.co.copy(),group))
    result={}
    for kind,source in [("walk","Walk_Loop"),("hit","Hit_Chest"),("death","Death01")]:
        clip=bpy.data.actions[source];start,end=clip.frame_range;samples=[]
        for index in range(33):
            t=index/32;base.reset_pose(rig);rig.animation_data.action=clip
            value=start+(end-start)*t;bpy.context.scene.frame_set(math.floor(value),subframe=value%1);bpy.context.view_layer.update()
            if kind!="death":
                sway=Vector((0,.02*math.sin(t*math.tau),.025*math.sin(t*math.tau*2)))
                for side in ("l","r"):
                    matrix=ready["hand_"+side];base.arm_ik(rig,side,matrix.translation+sway,(1 if side=="l" else -1,.1,-.2))
                    hand=rig.pose.bones["hand_"+side]
                    hand.matrix=Matrix.Translation(hand.head.copy()) @ matrix.to_quaternion().to_matrix().to_4x4()
            else:
                # Keep long equipment beside the fallen torso with a horizontal socket.
                main=rig.pose.bones["hand_l" if weapon=="bow" else "hand_r"]
                origin=ready[main.name];rotation=Quaternion((0,1,0),math.radians(75)*t) @ origin.to_quaternion()
                main.matrix=Matrix.Translation(main.head.copy()) @ rotation.to_matrix().to_4x4()
            bpy.context.view_layer.update()
            lowest=min(((rig.pose.bones[group].matrix @ rig.data.bones[group].matrix_local.inverted()) @ co).z for co,group in vertices)
            if lowest<.035:
                for name in hands:
                    hand=rig.pose.bones[name];matrix=hand.matrix.copy();matrix.translation.z+=.035-lowest;hand.matrix=matrix
            bpy.context.view_layer.update()
            samples.append({bone.name:bone.matrix_basis.copy() for bone in rig.pose.bones})
        base.reset_pose(rig);fitted=bpy.data.actions.new(weapon+"_"+kind);fitted.use_fake_user=True;rig.animation_data.action=fitted
        for index,sample in enumerate(samples):
            for bone in rig.pose.bones:
                bone.matrix_basis=sample[bone.name]
                for path in ("location","rotation_quaternion","scale"):bone.keyframe_insert(data_path=path,frame=index)
        result[kind]=fitted.name
    return result


def split_channels(actor,g,rig):
    parts=[]
    for index,channel in enumerate(g.channels):
        data=actor.data.copy();bm=bmesh.new();bm.from_mesh(data)
        layer=bm.faces.layers.int.get("gear_channel")
        bmesh.ops.delete(bm,geom=[f for f in bm.faces if f[layer]!=index],context="FACES")
        loose=[v for v in bm.verts if not v.link_faces]
        if loose:bmesh.ops.delete(bm,geom=loose,context="VERTS")
        bm.to_mesh(data);bm.free()
        if not data.polygons:continue
        obj=actor.copy();obj.data=data;obj.name="part_"+channel
        bpy.context.collection.objects.link(obj);obj.parent=rig
        obj["appearance_channel"]=channel;parts.append(obj)
    bpy.data.objects.remove(actor,do_unlink=True)
    return parts


def build(profile):
    ident=profile["id"];bpy.ops.wm.read_factory_settings(use_empty=True)
    source=ROOT/"assets_src/characters/modular"/ident;source.mkdir(parents=True,exist_ok=True)
    runtime=ROOT/"assets/combat/models";runtime.mkdir(parents=True,exist_ok=True)
    library=next((Path.home()/".codex/tools/character-art/animations/universal-animation-library").rglob("UAL1_Standard.glb"))
    bpy.ops.import_scene.gltf(filepath=str(library));rig=next(o for o in bpy.data.objects if o.type=="ARMATURE")
    for obj in list(bpy.data.objects):
        if obj!=rig:bpy.data.objects.remove(obj,do_unlink=True)
    for track in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(track)
    base.reset_pose(rig)
    g=ModularGeometry(rig);mats=humanoid(g,profile)
    # A visibly smaller palm and cuff avoids an axial wrist/weapon silhouette.
    for obj in g.parts:
        if obj.name.startswith("Hand"):
            center=sum((v.co for v in obj.data.vertices),Vector())/len(obj.data.vertices)
            for v in obj.data.vertices:v.co=center+(v.co-center)*.78
    hero=ident in ("warrior","archer_1")
    if hero:add_kit(g,mats,profile)
    if ident=="armored_brute":
        for obj in list(g.parts):
            if obj.name.lower().startswith(("helmet","visor")):
                g.parts.remove(obj);bpy.data.objects.remove(obj,do_unlink=True)
        g.channel="headwear_default";full_helmet(g,mats);g.channel=None
    options=["sword","bow","axe","mace","dagger","cleaver","crossbow","spear"] if hero else [profile["weapon"]]
    actions={}
    for weapon in options:
        pose,combat=ready_actions(rig,weapon)
        rig.animation_data.action=bpy.data.actions[pose];bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
        g.channel="weapon_"+weapon;start=len(g.parts)
        g.weapon(weapon,"hand_l" if weapon=="bow" else "hand_r",mats["iron"],mats["wood"],mats["leather"],mats["trim"])
        actions[weapon]={"pose":pose,"walk":"Walk_Loop","combat":combat if weapon in ("bow","spear","crossbow") else "Sword_Attack","hit":"Hit_Chest","death":"Death01"}
        if weapon in ("bow","spear","crossbow"):
            actions[weapon].update(carry_actions(rig,weapon,g.parts[start:]))
        if profile["kind"]=="wraith":actions[weapon]["death"]=base.wraith_death(rig)
    g.channel="offhand_default"
    default=profile.copy();default["weapon"]="none";attachments(g,default,mats)
    if hero:
        g.channel="offhand_shield";shield=profile.copy();shield.update(weapon="none",offhand="round_shield");attachments(g,shield,mats)
        g.channel="quiver";quiver=profile.copy();quiver.update(weapon="none",offhand="quiver");attachments(g,quiver,mats)
    g.channel=None
    rig.scale=(profile["scale"],)*3;base.reset_pose(rig)
    actor=g.join();scene,camera=base.scene_setup()
    texture=base.bake_albedo(actor,source/(ident+"_albedo.png"));texture.pack()
    parts=split_channels(actor,g,rig)
    wanted=set(name for mapping in actions.values() for name in mapping.values())
    for action in list(bpy.data.actions):
        if action.name not in wanted:bpy.data.actions.remove(action)
        else:action.use_fake_user=True
    rig.animation_data.action=bpy.data.actions[actions[profile["weapon"]]["pose"]];scene.frame_set(0)
    bpy.ops.object.select_all(action="DESELECT");rig.select_set(True)
    for obj in parts:obj.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(runtime/(ident+".glb")),export_format="GLB",use_selection=True,
        export_animation_mode="ACTIONS",export_animations=True,export_extras=True,export_cameras=False,export_lights=False)
    defaults={"body","armor_default","boots_default","headwear_default","weapon_"+profile["weapon"],"offhand_default"}
    for obj in parts:obj.hide_render=obj.name.removeprefix("part_") not in defaults
    scene.render.resolution_x=640;scene.render.resolution_y=448;base.camera_view(camera,330,ortho=6.4)
    scene.render.filepath=str(source/"preview.png");bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(source/(ident+".blend")))
    for obj in parts:obj.select_set(not obj.hide_render)
    bpy.ops.export_scene.fbx(filepath=str(source/(ident+".fbx")),use_selection=True,object_types={"MESH","ARMATURE"},add_leaf_bones=False,bake_anim_use_all_actions=True,bake_anim_use_nla_strips=False)
    info={"id":ident,"resource":"res://assets/combat/models/"+ident+".glb","channels":g.channels,"actions":actions,"default_weapon":profile["weapon"],"hero":hero,"bones":len(rig.data.bones)}
    (source/"model.json").write_text(json.dumps(info,indent=2)+"\n")
    print("MODULAR_ACTOR_PASS",ident,len(parts),flush=True)


def export_creature(profile):
    ident=profile["id"];original=ROOT/"assets_src/characters/roster"/ident
    bpy.ops.wm.open_mainfile(filepath=str(original/(ident+".blend")))
    source=ROOT/"assets_src/characters/modular"/ident;source.mkdir(parents=True,exist_ok=True)
    rig=next(o for o in bpy.data.objects if o.type=="ARMATURE")
    actor=next(o for o in bpy.data.objects if o.type=="MESH");actor.name="part_body"
    for image in bpy.data.images:
        if image.source=="FILE":image.pack()
    bpy.ops.object.select_all(action="DESELECT");rig.select_set(True);actor.select_set(True)
    bpy.context.view_layer.objects.active=rig
    info=json.loads((original/"model.json").read_text())
    bpy.ops.export_scene.gltf(filepath=str(ROOT/"assets/combat/models"/(ident+".glb")),export_format="GLB",use_selection=True,export_animation_mode="ACTIONS",export_animations=True,export_extras=True,export_cameras=False,export_lights=False)
    bpy.ops.wm.save_as_mainfile(filepath=str(source/(ident+".blend")))
    row={"id":ident,"resource":"res://assets/combat/models/"+ident+".glb","channels":["body"],"actions":{profile["weapon"]:info["actions"]},"default_weapon":profile["weapon"],"hero":False,"bones":len(rig.data.bones),"original_source":"assets_src/characters/roster/"+ident}
    (source/"model.json").write_text(json.dumps(row,indent=2)+"\n")
    print("MODULAR_CREATURE_PASS",ident,flush=True)


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("--ids",required=True)
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    for ident in args.ids.split(","):
        profile=next(p for p in DATA["characters"] if p["id"]==ident)
        (build if profile["kind"] in ("human","skeleton","ogre","goblin","lizard","wraith") else export_creature)(profile)
