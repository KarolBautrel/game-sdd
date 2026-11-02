"""Original creature geometry and species-specific, editable skeletal clips."""
import math
import bpy
from mathutils import Vector
from roster_geometry import Geometry


def create_creature(profile):
    kind=profile["kind"]
    data=bpy.data.armatures.new(kind+" anatomy")
    rig=bpy.data.objects.new(kind+" rig",data)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    def bone(name,head,parent="root"):
        b=data.edit_bones.new(name);b.head=head;b.tail=Vector(head)+Vector((0,0,.1))
        if parent:b.parent=data.edit_bones[parent]
    bone("root",(0,0,0),None)
    if kind in ("wolf","hound","boar"):
        bone("chest",(0,-.27,.63));bone("head",(0,-.53,.78),"chest")
        bone("jaw",(0,-.72,.66),"head");bone("tail",(0,.58,.63))
        for side,sign in (("l",1),("r",-1)):
            for end,y in (("front",-.35),("rear",.39)):
                x=sign*.20;prefix=end+"_"+side
                bone(prefix,(x,y,.60));bone(prefix+"_shin",(x,y+.055,.30),prefix)
    elif kind=="bat":
        bone("chest",(0,0,.85));bone("head",(0,-.08,1.03),"chest")
        for side,sign in (("l",1),("r",-1)):
            bone("wing_"+side,(sign*.12,0,.93),"chest")
            bone("foot_"+side,(sign*.07,.02,.64),"chest")
    elif kind=="snake":
        for i in range(7):bone("coil"+str(i),(0,0,.12))
        bone("neck",(0,-.10,.30));bone("head",(0,-.19,.83),"neck")
        bone("jaw",(0,-.31,.91),"head")
    elif kind=="spider":
        bone("chest",(0,-.13,.42));bone("head",(0,-.34,.39),"chest")
        bone("abdomen",(0,.28,.43))
        for side,sign in (("l",1),("r",-1)):
            for i in range(4):
                y=-.32+i*.19;name="leg_"+side+str(i)
                bone(name,(sign*.13,y,.40));bone(name+"_tip",(sign*(.65+(.08 if i in (1,2) else 0)),y+(i-1.5)*.18,.56),name)
        bone("jaw_l",(.09,-.45,.33),"head");bone("jaw_r",(-.09,-.45,.33),"head")
    else:raise ValueError(kind)
    bpy.ops.object.mode_set(mode="OBJECT");rig.animation_data_create()
    g=Geometry(rig)
    black=g.material("Dark eye sockets",(.006,.005,.004))
    ivory=g.material("Ivory teeth and talons",(.55,.49,.37),atlas=7)
    skin=g.material("Creature surface",(.17,.12,.08),atlas={"wolf":10,"hound":11,"boar":6,"bat":2,"snake":9,"spider":6}[kind])
    dark=g.material("Dark limbs",(.045,.026,.016),atlas=13)
    eye=g.material("Amber eyes",(.9,.26,.012),emission=.5)
    if kind in ("wolf","hound","boar"):
        boar=kind=="boar"
        g.ellipsoid("Stocky body" if boar else "Lean ribcage",(0,.02,.66),(.29 if boar else .23,.62,.32 if boar else .26),"root",skin)
        g.ellipsoid("Shoulders",(0,-.34,.74),(.29 if boar else .24,.29,.31),"chest",skin)
        g.ellipsoid("Haunch",(0,.42,.61),(.25,.26,.26),"root",skin)
        g.ellipsoid("Head",(0,-.63,.83),(.21 if boar else .16,.26,.21),"head",skin)
        g.ellipsoid("Long muzzle",(0,-.86,.72),(.15 if boar else .105,.23,.105),"head",skin)
        g.ellipsoid("Nose",(0,-1.045,.72),(.14 if boar else .09,.045,.065),"head",dark)
        g.ellipsoid("Lower jaw",(0,-.84,.65),(.11,.21,.055),"jaw",dark)
        for sign in (-1,1):
            g.ellipsoid("Eye rim",(sign*.135,-.77,.87),(.038,.045,.029),"head",black)
            g.ellipsoid("Eye",(sign*.15,-.789,.875),(.02,.018,.012),"head",eye)
            g.mesh("Pointed ear",[(sign*.12,-.57,.93),(sign*.23,-.48,1.17),(sign*.21,-.39,.91),(sign*.10,-.40,.93)],[(0,1,2),(0,2,3),(0,3,1),(1,3,2)],"head",skin)
            if boar:
                g.tube("Curved boar tusk",[(sign*.13,-.88,.63),(sign*.24,-.95,.64),(sign*.27,-.96,.82)],[.044,.03,.001],"jaw",ivory)
            else:
                for y in (-.79,-.94):g.spike("Fang",(sign*.075,y,.695),(sign*.075,y,.60),.025,"head",ivory)
            for end,y in (("front",-.35),("rear",.39)):
                name=end+("_l" if sign==1 else "_r");x=sign*.20
                g.tube("Upper leg",[(x,y,.65),(x,y+.055,.30)],[.11 if boar else .085,.06],name,skin)
                g.tube("Lower leg",[(x,y+.055,.30),(x,y-.025,.09)],[.055,.035],name+"_shin",skin)
                g.ellipsoid("Hoof" if boar else "Paw",(x,y-.06,.065),(.075,.11,.063),name+"_shin",dark)
                if not boar:
                    for dx in (-.04,0,.04):g.spike("Claw",(x+dx,y-.13,.055),(x+dx,y-.18,.035),.012,name+"_shin",ivory)
        if boar:
            g.tube("Curled boar tail",[(0,.58,.68),(.04,.76,.74),(.10,.76,.81),(.09,.68,.82)],[.025,.02,.016,.006],"tail",skin)
        else:g.tube("Tail",[(0,.54,.67),(0,.86,.69),(.07,1.07,.56)],[.08,.065,.008],"tail",skin)
        for i in range(11):
            y=-.42+i*.085;z=.97 if boar else .89
            g.spike("Bristle ridge" if boar else "Ruff",(0,y,z-.04),(0,y+.06,z+.15),.045,"chest" if i<3 else "root",dark if boar else skin)
        if kind=="hound":
            ember=g.material("Ember fissures",(.95,.09,.002),emission=1.2)
            for sign in (-1,1):
                for y in (-.22,.04,.29):g.tube("Burning flank seam",[(sign*.22,y-.05,.73),(sign*.247,y,.66),(sign*.23,y+.04,.58)],.012,"root",ember,5)
    elif kind=="bat":
        g.ellipsoid("Furred torso",(0,0,.83),(.15,.13,.25),"chest",skin)
        g.ellipsoid("Bat head",(0,-.06,1.10),(.15,.13,.13),"head",skin)
        for side,sign in (("l",1),("r",-1)):
            wing="wing_"+side
            pts=[(sign*.12,0,.94),(sign*.38,-.08,1.24),(sign*1.03,.0,1.08),(sign*.80,.08,.68),(sign*.53,.10,.55),(sign*.25,.09,.59),(sign*.13,.03,.72)]
            g.mesh("Scalloped wing membrane",pts,[(0,1,2),(0,2,3),(0,3,4),(0,4,5),(0,5,6)],wing,dark)
            for i in (2,3,4,5):g.tube("Wing finger",[pts[0],pts[1],pts[i]],[.024,.019,.008],wing,skin,6)
            g.spike("Ear",(sign*.09,-.04,1.18),(sign*.16,0,1.48),.085,"head",skin)
            g.ellipsoid("Bat eye",(sign*.07,-.178,1.115),(.025,.015,.021),"head",eye)
            g.spike("Bat fang",(sign*.045,-.17,1.03),(sign*.045,-.19,.96),.022,"head",ivory)
            g.tube("Hanging leg",[(sign*.07,.02,.66),(sign*.09,0,.49)],.025,"foot_"+side,skin)
            for dx in (-.02,.02):g.spike("Foot talon",(sign*.09+dx,0,.50),(sign*.09+dx,-.04,.44),.012,"foot_"+side,ivory)
    elif kind=="snake":
        for i in range(7):
            a=i*math.tau/7;b=(i+1)*math.tau/7
            pts=[(.40*math.cos(t),.30*math.sin(t)+.08,.12+.03*math.sin(t*2)) for t in (a,(a+b)/2,b)]
            g.tube("Coiled body",pts,.095,"coil"+str(i),skin)
        g.tube("Raised neck",[(.25,-.10,.14),(.12,-.13,.40),(0,-.16,.70),(0,-.23,.92)],[.10,.085,.065,.07],"neck",skin)
        g.ellipsoid("Cobra hood",(0,-.13,.70),(.25,.06,.29),"neck",skin)
        g.ellipsoid("Cobra head",(0,-.29,.94),(.135,.18,.09),"head",skin)
        g.ellipsoid("Lower jaw",(0,-.33,.885),(.11,.14,.035),"jaw",ivory)
        for sign in (-1,1):
            g.ellipsoid("Snake eye",(sign*.105,-.37,.98),(.023,.017,.015),"head",eye)
            g.spike("Venom fang",(sign*.06,-.42,.93),(sign*.06,-.44,.82),.021,"head",ivory)
            g.ellipsoid("Hood marking",(sign*.14,-.192,.74),(.047,.012,.085),"neck",dark)
    else:
        g.ellipsoid("Large hairy abdomen",(0,.30,.48),(.32,.43,.28),"abdomen",skin)
        g.ellipsoid("Cephalothorax",(0,-.18,.42),(.22,.28,.15),"chest",dark)
        g.ellipsoid("Spider face",(0,-.39,.38),(.16,.13,.12),"head",skin)
        for side,sign in (("l",1),("r",-1)):
            for i in range(4):
                y=-.32+i*.19;name="leg_"+side+str(i)
                joint=(sign*(.65+(.08 if i in (1,2) else 0)),y+(i-1.5)*.18,.56)
                foot=(sign*(.83+(.08 if i in (1,2) else 0)),y+(i-1.5)*.29,.035)
                g.tube("Eight upper legs",[(sign*.13,y,.40),joint],[.047,.033],name,skin)
                g.tube("Eight pointed lower legs",[joint,foot],[.035,.006],name+"_tip",dark)
            jaw="jaw_"+side
            g.tube("Hooked mandible",[(sign*.09,-.45,.33),(sign*.13,-.58,.25),(sign*.04,-.62,.25)],[.055,.035,.001],jaw,dark)
            for i in range(3):g.ellipsoid("Red eye cluster",(sign*(.035+i*.04),-.49+i*.009,.44-i*.014),(.021,.017,.021),"head",eye)
        for i in range(9):
            a=i*math.tau/9
            g.spike("Abdomen bristle",(.27*math.cos(a),.30+.32*math.sin(a),.55),(.34*math.cos(a),.30+.41*math.sin(a),.63),.022,"abdomen",skin)
    actions=animate(rig,kind)
    return g,rig,actions


def animate(rig,kind):
    result={}
    for action in ("pose","walk","combat","hit","death"):
        clip=bpy.data.actions.new(kind+"_"+action);clip.use_fake_user=True
        rig.animation_data.action=clip;result[action]=clip.name
        for frame in range(0,33,2):
            t=frame/32;s=math.sin(t*math.tau);attack=math.sin(math.pi*t)**2
            for b in rig.pose.bones:
                b.rotation_mode="XYZ";b.rotation_euler=(0,0,0);b.location=(0,0,0);b.scale=(1,1,1)
            root=rig.pose.bones["root"]
            root.location.y=.012*s
            head=rig.pose.bones.get("head")
            if head:head.rotation_euler.x=.025*s
            if kind in ("wolf","hound","boar"):
                rig.pose.bones["tail"].rotation_euler.y=.14*s
                if action=="walk":
                    for i,name in enumerate(("front_l","front_r","rear_l","rear_r")):
                        phase=t*math.tau+(math.pi if i in (1,2) else 0)
                        rig.pose.bones[name].rotation_euler.x=.48*math.sin(phase)
                        rig.pose.bones[name+"_shin"].rotation_euler.x=.4*max(0,-math.sin(phase))
                    root.location.y=.025*math.cos(t*math.tau*2)
                if action=="combat":
                    head.rotation_euler.x=-.55*attack;rig.pose.bones["jaw"].rotation_euler.x=.5*attack
                    root.location.z=.15*attack
            elif kind=="bat":
                for side,sign in (("l",1),("r",-1)):
                    rig.pose.bones["wing_"+side].rotation_euler.z=sign*(.22+.48*math.sin(t*math.tau*(2 if action=="walk" else 1)))
                root.location.y=.05*s
                if action=="combat":root.location.z=.3*attack;head.rotation_euler.x=-.4*attack
            elif kind=="snake":
                for i in range(7):rig.pose.bones["coil"+str(i)].location.x=.015*math.sin(t*math.tau+i)
                rig.pose.bones["neck"].rotation_euler.z=.08*s
                if action=="walk":root.location.z=.05*s
                if action=="combat":rig.pose.bones["neck"].rotation_euler.x=.85*attack;rig.pose.bones["jaw"].rotation_euler.x=.5*attack
            else:
                rig.pose.bones["abdomen"].scale=(1+.02*s,1+.02*s,1+.02*s)
                for side,sign in (("l",1),("r",-1)):
                    for i in range(4):
                        name="leg_"+side+str(i);phase=t*math.tau+i*math.pi+(.0 if sign==1 else math.pi)
                        if action=="walk":
                            rig.pose.bones[name].rotation_euler.y=.28*math.sin(phase)
                            rig.pose.bones[name].rotation_euler.z=sign*.12*max(0,math.cos(phase))
                        if action=="death":
                            rig.pose.bones[name].rotation_euler.z=sign*.5*t
                            rig.pose.bones[name+"_tip"].rotation_euler.z=-sign*1.1*t
                    if action=="combat":rig.pose.bones["jaw_"+side].rotation_euler.y=sign*.55*attack
                if action=="combat":root.location.y=.12*attack;root.rotation_euler.x=-.25*attack
            if action=="hit":root.rotation_euler.x=-.22*math.sin(math.pi*t);root.rotation_euler.z=.12*math.sin(math.pi*t*2)
            if action=="death":
                root.rotation_euler.z=1.45*t if kind in ("wolf","hound","boar") else 0
                root.rotation_euler.x=.65*t if kind=="bat" else .15*t
                root.location.y=.28*t if kind in ("wolf","hound","boar") else (-.30*t if kind=="bat" else -.10*t)
                if kind in ("wolf","hound","boar"):
                    for name in ("front_l","front_r","rear_l","rear_r"):
                        rig.pose.bones[name].rotation_euler.x=.5*t
                        rig.pose.bones[name+"_shin"].rotation_euler.x=-1.0*t
                if kind=="bat":
                    for side,sign in (("l",1),("r",-1)):rig.pose.bones["wing_"+side].rotation_euler.z=sign*1.0*t
                if kind=="snake":rig.pose.bones["neck"].rotation_euler.x=1.1*t
            for b in rig.pose.bones:
                for path in ("rotation_euler","location","scale"):b.keyframe_insert(data_path=path,frame=frame)
    return result
