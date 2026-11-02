"""Project-authored modular geometry; no imported visible character meshes."""
import math
from pathlib import Path
import bpy
from mathutils import Vector, Matrix, Quaternion


class Geometry:
    def __init__(self, rig):
        self.rig = rig
        self.parts = []
        self.mats = {}

    def material(self, name, color, rough=.8, metal=0, emission=0, atlas=None):
        if name in self.mats:
            return self.mats[name]
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        mat.diffuse_color = (*color, 1)
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 95
        noise.inputs["Detail"].default_value = 2
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].color = (.55,.55,.55,1)
        ramp.color_ramp.elements[1].color = (1,1,1,1)
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        mix = nodes.new("ShaderNodeMixRGB")
        mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = .65
        mix.inputs[1].default_value = (*color,1)
        links.new(ramp.outputs["Color"], mix.inputs[2])
        links.new(mix.outputs[0], bsdf.inputs["Base Color"])
        if atlas is not None:
            uv=nodes.new("ShaderNodeUVMap");uv.uv_map="DesignPatch"
            mul=nodes.new("ShaderNodeVectorMath");mul.operation="MULTIPLY";mul.inputs[1].default_value=(.238,.238,1)
            add=nodes.new("ShaderNodeVectorMath");add.operation="ADD"
            add.inputs[1].default_value=((atlas%4)/4+.006,(3-atlas//4)/4+.006,0)
            tex=nodes.new("ShaderNodeTexImage")
            tex.image=bpy.data.images.load(str(Path(__file__).resolve().parents[2]/"assets_src/characters/roster/material-atlas.png"),check_existing=True)
            links.new(uv.outputs[0],mul.inputs[0]);links.new(mul.outputs[0],add.inputs[0]);links.new(add.outputs[0],tex.inputs[0])
            links.new(tex.outputs["Color"],bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        if emission:
            bsdf.inputs["Emission Color"].default_value = (*color,1)
            bsdf.inputs["Emission Strength"].default_value = emission
        self.mats[name] = mat
        return mat

    def mesh(self, name, verts, faces, bone, mat, weights=None):
        data = bpy.data.meshes.new(name)
        data.from_pydata(verts, [], faces)
        data.update()
        obj = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(obj)
        data.materials.append(mat)
        uv=data.uv_layers.new(name="DesignPatch")
        minimum=[min(p[k] for p in verts) for k in range(3)]
        span=[max(p[k] for p in verts)-minimum[k] for k in range(3)]
        for polygon in data.polygons:
            normal_axis=max(range(3),key=lambda k:abs(polygon.normal[k]))
            axes=[k for k in range(3) if k!=normal_axis]
            for loop in polygon.loop_indices:
                p=data.vertices[data.loops[loop].vertex_index].co
                uv.data[loop].uv=tuple((p[k]-minimum[k])/max(.001,span[k]) for k in axes)
        if weights:
            for index, assignments in enumerate(weights):
                for group, amount in assignments.items():
                    vg = obj.vertex_groups.get(group) or obj.vertex_groups.new(name=group)
                    vg.add([index], amount, "REPLACE")
        else:
            obj.vertex_groups.new(name=bone).add(list(range(len(verts))),1,"REPLACE")
        self.parts.append(obj)
        return obj

    def ellipsoid(self, name, center, radii, bone, mat, segments=12, rings=7):
        verts, faces = [], []
        for j in range(rings+1):
            latitude = -math.pi/2 + math.pi*(.002+.996*j/rings)
            for i in range(segments):
                a = i*2*math.pi/segments
                v = (math.cos(latitude)*math.cos(a),math.cos(latitude)*math.sin(a),math.sin(latitude))
                verts.append(tuple(center[k]+radii[k]*v[k] for k in range(3)))
        for j in range(rings):
            for i in range(segments):
                a,b = j*segments+i,j*segments+(i+1)%segments
                faces.append((a,b,b+segments,a+segments))
        faces += [tuple(reversed(range(segments))),tuple(range(rings*segments,(rings+1)*segments))]
        return self.mesh(name,verts,faces,bone,mat)

    def tube(self, name, points, radii, bone, mat, sides=8):
        points = [Vector(p) for p in points]
        verts, faces = [], []
        for j,p in enumerate(points):
            axis = (points[min(j+1,len(points)-1)]-points[max(0,j-1)]).normalized()
            helper = Vector((0,1,0)) if abs(axis.y)<.9 else Vector((1,0,0))
            u=axis.cross(helper).normalized();v=axis.cross(u).normalized()
            radius=radii[j] if isinstance(radii,(list,tuple)) else radii
            for i in range(sides):
                a=i*2*math.pi/sides
                verts.append(tuple(p+radius*(u*math.cos(a)+v*math.sin(a))))
        for j in range(len(points)-1):
            for i in range(sides):
                a,b=j*sides+i,j*sides+(i+1)%sides
                faces.append((a,b,b+sides,a+sides))
        faces += [tuple(reversed(range(sides))),tuple(range(len(verts)-sides,len(verts)))]
        return self.mesh(name,verts,faces,bone,mat)

    def shell(self,name,rings,bone,mat,gap=0,sides=16):
        verts,faces=[],[]
        for z,rx,ry,cy in rings:
            for i in range(sides):
                a=-math.pi/2+gap+(2*math.pi-2*gap)*i/(sides-1 if gap else sides)
                verts.append((rx*math.cos(a),cy+ry*math.sin(a),z))
        for j in range(len(rings)-1):
            for i in range(sides-1 if gap else sides):
                a,b=j*sides+i,j*sides+(i+1)%sides
                faces.append((a,b,b+sides,a+sides))
        if not gap:
            faces += [tuple(reversed(range(sides))),tuple(range(len(verts)-sides,len(verts)))]
        return self.mesh(name,verts,faces,bone,mat)

    def limb(self,name,bone,radii,mat):
        b=self.rig.data.bones[bone]
        return self.tube(name,[b.head_local.lerp(b.tail_local,t) for t,_ in radii],
                         [r for _,r in radii],bone,mat,12)

    def box(self,name,center,size,bone,mat):
        verts=[tuple(center[k]+sign[k]*size[k]/2 for k in range(3))
               for sign in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
        return self.mesh(name,verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],bone,mat)

    def spike(self,name,base,tip,radius,bone,mat):
        return self.tube(name,[base,tip],[radius,.001],bone,mat,6)

    def weapon(self,kind,hand,metal,wood,leather,trim):
        if kind in ("none","fangs","tusks"):
            return
        b=self.rig.pose.bones[hand]
        deform=b.matrix @ self.rig.data.bones[hand].matrix_local.inverted()
        inverse=deform.inverted()
        grip=b.head+(b.tail-b.head).normalized()*.045
        # Build in the inspected ready-pose socket, then transform to bind space.
        axis=Vector((0,-.87,.49)).normalized() if kind=="spear" else Vector((-.06,-.20,-.978)).normalized()
        wide=Vector((1,0,-.06)).normalized(); depth=axis.cross(wide).normalized()
        start_index=len(self.parts)
        string_obj=None
        def p(x,y,z=0):return tuple(grip+wide*x+axis*y+depth*z)
        def prism(name,poly,thickness,mat):
            n=len(poly);verts=[p(x,y,z) for z in (-thickness/2,thickness/2) for x,y in poly]
            return self.mesh(name,verts,[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],hand,mat)
        if kind in ("sword","dagger","cleaver"):
            length=.68 if kind=="sword" else (.33 if kind=="dagger" else .56)
            self.tube(kind+" grip",[p(0,-.12),p(0,.08)],.022,hand,leather)
            self.tube(kind+" guard",[p(-.10,.08),p(.10,.08)],.017,hand,trim)
            poly=[(-.042,.09),(.042,.09),(.038,length-.08),(0,length),(-.038,length-.08)]
            if kind=="cleaver":poly=[(-.04,.09),(.055,.09),(.14,length-.16),(.09,length),(-.065,length-.04)]
            prism(kind+" blade",poly,.024,metal)
            self.tube(kind+" glint",[p(poly[1][0],poly[1][1],-.014),p(poly[2][0],poly[2][1],-.014)],.004,hand,trim,6)
        elif kind in ("axe","mace","club","spear"):
            length=1.45 if kind=="spear" else (.73 if kind=="club" else .56)
            self.tube(kind+" shaft",[p(0,-.15),p(0,length)],[.025,.02],hand,wood)
            if kind=="axe":
                prism("Axe iron head",[(-.04,.36),(.20,.34),(.25,.62),(.02,.60),(-.04,.49)],.06,metal)
            elif kind=="spear":
                prism("Spear leaf",[(-.055,length-.05),(0,length+.25),(.055,length-.05),(0,length-.13)],.018,metal)
            else:
                c=Vector(p(0,length-.08))
                self.ellipsoid(kind+" head",c,(.11,.10,.15),hand,metal if kind=="mace" else wood)
                for i in range(7):
                    a=i*math.tau/7;v=wide*math.cos(a)+depth*math.sin(a)
                    self.spike("Weapon stud",c+v*.08,c+v*.15,.035,hand,metal)
        elif kind=="bow":
            # Upright left-hand bow with real curved limbs and taut string.
            pts=[(grip.x,grip.y-.10,grip.z-.63),(grip.x,grip.y-.25,grip.z-.36),
                 tuple(grip),(grip.x,grip.y-.25,grip.z+.36),(grip.x,grip.y-.10,grip.z+.63)]
            self.tube("Longbow limbs",pts,[.014,.022,.03,.022,.014],hand,wood)
            nock=self.rig.pose.bones["hand_r"].head.copy()
            string_obj=self.tube("Drawn bowstring",[pts[0],nock,pts[-1]],.004,hand,trim,4)
        elif kind=="crossbow":
            self.box("Crossbow stock",grip+Vector((0,-.17,0)),(.065,.58,.08),hand,wood)
            self.tube("Crossbow limbs",[grip+Vector((-.31,-.36,.01)),grip+Vector((0,-.46,.01)),grip+Vector((.31,-.36,.01))],.018,hand,wood)
            self.tube("Crossbow string",[grip+Vector((-.31,-.36,.01)),grip+Vector((0,-.12,.02)),grip+Vector((.31,-.36,.01))],.003,hand,trim,4)
        for obj in self.parts[start_index:]:
            for vertex in obj.data.vertices:vertex.co=inverse @ vertex.co
        if string_obj:
            # The two tips follow the bow; the nock follows the drawing hand.
            right=self.rig.pose.bones["hand_r"]
            right_inverse=(right.matrix @ self.rig.data.bones["hand_r"].matrix_local.inverted()).inverted()
            middle=list(range(4,8))
            for index in middle:
                v=string_obj.data.vertices[index];v.co=right_inverse @ (deform @ v.co)
            string_obj.vertex_groups[hand].remove(middle)
            string_obj.vertex_groups.new(name="hand_r").add(middle,1,"REPLACE")

    def join(self):
        bpy.ops.object.select_all(action="DESELECT")
        for obj in self.parts:obj.select_set(True)
        bpy.context.view_layer.objects.active=self.parts[0]
        bpy.ops.object.join()
        obj=bpy.context.object
        obj.name="Original_Character_Mesh"
        mod=obj.modifiers.new("Skin","ARMATURE");mod.object=self.rig
        obj.parent=self.rig
        return obj


PALETTES={"blue":(.035,.12,.27),"red":(.30,.045,.026),"brown":(.16,.075,.035),
          "charcoal":(.045,.042,.039),"olive":(.16,.20,.064),"teal":(.035,.13,.13),
          "bone":(.55,.49,.34),"ember":(.8,.09,.006)}


def humanoid(g,profile):
    rig=g.rig
    kind=profile["kind"]
    skeleton=kind=="skeleton"
    accent=g.material("Cloth accent",PALETTES[profile["accent"]],atlas={"blue":0,"red":1,"brown":2,"charcoal":3,"olive":9,"teal":15,"bone":7,"ember":11}[profile["accent"]])
    leather=g.material("Weathered leather",(.19,.095,.045),atlas=2)
    pants=g.material("Dark padded trousers",(.085,.062,.038),atlas=3)
    iron=g.material("Worn iron",(.29,.32,.32),.52,.65,atlas=4)
    trim=g.material("Steel edges",(.53,.52,.43),.42,.6,atlas=5)
    wood=g.material("Oiled wood",(.21,.11,.043),atlas=12)
    black=g.material("Deep shadows",(.016,.012,.009))
    bone=g.material("Aged bone",(.57,.51,.37),atlas=7)
    skin_color={"goblin":(.26,.32,.12),"ogre":(.38,.35,.25),"lizard":(.19,.27,.13)}.get(kind,(.53,.30,.15))
    skin=g.material("Skin",skin_color,.87,atlas=9 if kind in ("goblin","lizard") else 8)
    hair=g.material("Hair and fur",(.08,.042,.018),atlas=6)
    heavy=profile["id"] in ("armored_brute","bandit_brute","guardian")
    plated=profile["id"]=="armored_brute"
    bare=kind in ("goblin","ogre","lizard")
    width=.27 if heavy or kind=="ogre" else .225
    if skeleton:
        g.tube("Spine",[(0,.015,.97),(0,.02,1.47)],.035,"spine_02",bone)
        for z,r in [(1.08,.13),(1.16,.17),(1.24,.19),(1.32,.18),(1.4,.14)]:
            for sign in (-1,1):
                pts=[(0,.02,z+.02),(sign*r*.75,-.10,z),(sign*r,-.12,z-.06),(sign*r*.3,-.15,z-.07)]
                g.tube("Rib",pts,.016,"spine_02",bone,6)
        g.ellipsoid("Pelvis",(0,.02,.94),(.15,.085,.09),"pelvis",bone)
    elif kind=="wraith":
        g.shell("Tattered shroud",[(.10,.31,.18,.02),(.35,.28,.16,.02),(.95,.16,.11,.02),(1.35,.23,.12,.02),(1.5,.13,.09,.02)],"spine_02",accent)
        for i in range(12):
            a=i*math.tau/12;x,y=.3*math.cos(a),.16*math.sin(a)
            g.spike("Torn hanging shroud",(x,y,.28),(x*1.12,y*1.1,.015),.045,"pelvis",accent)
    else:
        g.shell("Body",[(.95,.17,.11,.025),(1.08,.19,.125,.02),(1.29,width,.145,.02),(1.43,width*.92,.12,.025),(1.5,.12,.085,.02)],"spine_02",skin if bare else (iron if profile["id"]=="armored_brute" else leather))
        g.shell("Waist sash",[(.96,.18,.125,.025),(1.02,.19,.135,.02),(1.07,.18,.12,.02)],"pelvis",accent)
        g.box("Belt buckle",(0,-.14,1.015),(.055,.025,.04),"pelvis",trim)
        for side,sign in [("l",1),("r",-1)]:
            x=sign*.11
            g.box("Split tasset",(x,-.135,.89),(.16,.025,.2),"thigh_"+side,accent if bare else leather)
        if not bare:
            for z in (1.14,1.27,1.39):
                for x in (-.13,.13):g.ellipsoid("Brigandine rivet",(x,-.135,z),(.01,.01,.01),"spine_02",trim,6,4)
        if not bare:
            g.shell("Cloth neck scarf",[(1.42,.14,.105,.02),(1.48,.15,.105,.02),(1.55,.085,.075,.02)],"spine_03",accent)
            for sign in (-1,1):
                g.tube("Crossed leather harness",[(sign*.17,-.133,1.43),(sign*.08,-.153,1.26),(-sign*.06,-.142,1.10)],.019,"spine_02",leather)
        if profile["id"]=="warrior":
            g.mesh("Blue shoulder mantle",[(-.24,.08,1.46),(.24,.08,1.46),(.21,.15,.91),(-.21,.15,.91)],[(0,1,2,3)],"spine_03",accent)

    for side,sign in [("l",1),("r",-1)]:
        radius=.13 if kind=="ogre" else (.038 if skeleton else .103)
        arm_mat=bone if skeleton or kind=="wraith" else (skin if bare else (iron if plated else leather))
        leg_mat=bone if skeleton else (skin if bare else (iron if plated else pants))
        g.limb("Upper arm", "upperarm_"+side,[(-.07,radius),(.3,radius*1.12),(.98,radius*.75)],arm_mat)
        g.limb("Forearm", "lowerarm_"+side,[(-.06,radius*.8),(.25,radius*.9),(1.03,radius*.59)],arm_mat)
        if kind!="wraith":
            g.limb("Thigh", "thigh_"+side,[(-.03,radius*1.12),(.25,radius*1.3),(1.025,radius*.85)],leg_mat)
            g.limb("Shin", "calf_"+side,[(-.02,radius*.85),(.2,radius*.95),(1.03,radius*.64)],bone if skeleton else (iron if plated else leather))
        wrist=rig.data.bones["hand_"+side].head_local
        g.ellipsoid("Hand",wrist+Vector((sign*.045,0,0)),(.075,.05,.055),"hand_"+side,bone if skeleton or kind=="wraith" else (skin if bare else leather))
        g.ellipsoid("Thumb",wrist+Vector((sign*.025,-.048,-.015)),(.025,.035,.029),"hand_"+side,bone if skeleton or kind=="wraith" else (skin if bare else leather),8,5)
        if kind!="wraith":g.ellipsoid("Foot",(sign*.089,-.055,.072),(.08,.15,.077),"foot_"+side,bone if skeleton else (iron if plated else leather))
        if heavy:
            shoulder=rig.data.bones["upperarm_"+side].head_local
            g.ellipsoid("Shoulder plate",shoulder,(.13,.12,.105),"upperarm_"+side,iron)
            g.limb("Steel vambrace","lowerarm_"+side,[(.15,.077),(.7,.061)],iron)
        elif not bare and not skeleton and kind!="wraith" and side=="r":
            shoulder=rig.data.bones["upperarm_r"].head_local
            g.ellipsoid("Right shoulder plate",shoulder,(.12,.11,.09),"upperarm_r",iron)

    # A readable open face, constructed rather than projected onto the hood.
    g.ellipsoid("Neck",(0,.005,1.52),(.07,.065,.09),"neck_01",bone if skeleton or kind=="wraith" else skin)
    head_rx=.21 if kind=="ogre" else (.18 if kind=="goblin" else .15)
    g.ellipsoid("Skull" if skeleton or kind=="wraith" else "Head",(0,-.014,1.695),(head_rx,.125,.195),"Head",bone if skeleton or kind=="wraith" else skin)
    if kind=="lizard":
        g.ellipsoid("Lizard muzzle",(0,-.16,1.66),(.10,.15,.07),"Head",skin)
    else:
        g.ellipsoid("Nose",(0,-.135,1.7),(.023,.024,.046),"Head",bone if skeleton else skin,8,5)
    for sign in (-1,1):
        g.ellipsoid("Eye socket",(sign*head_rx*.43,-.119,1.75),(.025,.012,.015),"Head",black,8,5)
        if not skeleton and kind!="wraith":
            g.ellipsoid("Eye",(sign*head_rx*.43,-.132,1.752),(.012,.005,.007),"Head",bone,8,4)
            g.ellipsoid("Pupil",(sign*head_rx*.43,-.137,1.752),(.005,.003,.007),"Head",black,6,4)
        g.ellipsoid("Brow",(sign*head_rx*.44,-.124,1.786),(.055,.026,.022),"Head",bone if skeleton else skin,8,4)
        if kind in ("goblin","lizard"):
            g.spike("Pointed ear",(sign*head_rx*.9,.0,1.74),(sign*(head_rx+.12),.02,1.83),.055,"Head",skin)
    if skeleton or kind=="wraith":
        g.ellipsoid("Jaw",(0,-.037,1.59),(.095,.08,.048),"Head",bone)
        for x in (-.06,-.035,-.012,.012,.035,.06):g.box("Tooth",(x,-.117,1.62),(.018,.022,.028),"Head",bone)
    elif profile["face"]=="beard":
        g.ellipsoid("Beard",(0,-.055,1.6),(.115,.10,.095),"Head",hair)
        for sign in (-1,1):g.ellipsoid("Moustache",(sign*.04,-.139,1.659),(.055,.026,.021),"Head",hair)
    elif profile["face"]=="mask":
        g.ellipsoid("Lower face scarf",(0,-.065,1.66),(.15,.135,.08),"Head",accent)
    elif kind=="ogre":
        for sign in (-1,1):g.spike("Ogre tusk",(sign*.09,-.12,1.61),(sign*.085,-.165,1.72),.025,"Head",bone)

    headwear=profile["headwear"]
    if headwear=="hood":
        hood_mat=accent if profile["id"] in ("archer_1","bandit_marauder","bandit_carnage","wraith") else g.material("Dark hood cloth",(.06,.045,.03),atlas=3)
        g.shell("Hood",[(1.51,head_rx+.045,.15,.025),(1.68,head_rx+.055,.17,.025),(1.85,head_rx+.025,.16,.03),(1.99,.015,.025,.03)],"Head",hood_mat,gap=.85)
        g.shell("Hood crown",[(1.86,head_rx+.02,.15,.03),(1.99,.015,.025,.03)],"Head",hood_mat)
        g.shell("Shoulder cowl",[(1.38,.25,.14,.03),(1.47,.25,.14,.03),(1.55,.13,.10,.025)],"spine_03",accent)
    elif headwear in ("helmet","closed_helmet","cap"):
        mat=leather if headwear=="cap" else iron
        g.shell("Helmet crown",[(1.77,.14,.13,.01),(1.85,.13,.12,.01),(1.92,.04,.05,.01),(1.93,.005,.008,.01)],"Head",mat)
        g.tube("Helmet brow rim",[(-.13,-.10,1.77),(0,-.14,1.77),(.13,-.10,1.77)],.013,"Head",trim)
        if headwear=="closed_helmet":
            g.box("Visor",(0,-.13,1.69),(.24,.035,.13),"Head",iron)
            g.box("Visor slit",(0,-.152,1.73),(.18,.005,.015),"Head",black)
    elif headwear=="hair":
        g.shell("Hair cap",[(1.78,head_rx+.005,.12,.02),(1.87,.105,.10,.02),(1.90,.02,.03,.02)],"Head",hair)

    if kind=="lizard":
        g.tube("Lizard tail",[(0,.08,.96),(0,.35,.75),(0,.65,.48),(.12,.9,.24)],[.10,.08,.045,.004],"pelvis",skin)
        for z in (1.56,1.65,1.74,1.83):g.spike("Dorsal crest",(0,.10,z),(0,.24,z+.05),.035,"Head",accent)
    if profile["offhand"] in ("fur","spikes"):
        for sign in (-1,1):
            for i in range(4):
                base=(sign*(.19+i*.025),.02,1.47)
                g.spike("Shoulder fur or spike",base,(base[0],.07,1.62+i*.012),.045,"spine_03",iron if profile["offhand"]=="spikes" else hair)
    return {"accent":accent,"leather":leather,"iron":iron,"trim":trim,"wood":wood,"bone":bone,"black":black,"skin":skin}


def attachments(g,profile,mats):
    rig=g.rig
    main=profile["weapon"]
    hand="hand_l" if main=="bow" else "hand_r"
    g.weapon(main,hand,mats["iron"],mats["wood"],mats["leather"],mats["trim"])
    off=profile["offhand"]
    if off=="dagger":g.weapon("dagger","hand_l",mats["iron"],mats["wood"],mats["leather"],mats["trim"])
    if off=="quiver":
        g.tube("Leather quiver",[(.12,.16,1.12),(.12,.18,1.53)],.075,"spine_03",mats["leather"])
        for x in (.09,.12,.15):
            g.tube("Arrow shaft",[(x,.18,1.27),(x,.19,1.68)],.006,"spine_03",mats["wood"],6)
            g.spike("Arrow fletching",(x,.19,1.65),(x+.025,.19,1.7),.014,"spine_03",mats["bone"])
    elif off in ("kite_shield","round_shield"):
        shield_bone="lowerarm_l"
        b=rig.pose.bones[shield_bone]
        inverse=(b.matrix @ rig.data.bones[shield_bone].matrix_local.inverted()).inverted()
        center=b.head.lerp(b.tail,.62)+Vector((.035,-.08,0))
        start=len(g.parts)
        if off=="round_shield":
            poly=[(math.cos(i*math.tau/16)*.25,math.sin(i*math.tau/16)*.25) for i in range(16)]
        else:poly=[(-.23,.24),(.23,.24),(.23,-.10),(0,-.37),(-.23,-.10)]
        verts=[tuple(center+Vector((x,y,z))) for y in (-.03,.03) for x,z in poly]
        n=len(poly)
        obj=g.mesh("Shield",verts,[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],"hand_l",mats["accent"])
        for i in range(n):
            a,bp=poly[i],poly[(i+1)%n]
            g.tube("Shield rim",[center+Vector((a[0],-.04,a[1])),center+Vector((bp[0],-.04,bp[1]))],.018,"hand_l",mats["trim"],6)
        g.ellipsoid("Shield boss",center+Vector((0,-.065,0)),(.07,.035,.07),"hand_l",mats["iron"])
        if off=="kite_shield":
            g.box("Shield cross",center+Vector((0,-.064,-.02)),(.035,.015,.39),"hand_l",mats["bone"])
            g.box("Shield crossbar",center+Vector((0,-.065,.055)),(.25,.015,.035),"hand_l",mats["bone"])
        for obj in g.parts[start:]:
            for v in obj.data.vertices:v.co=inverse @ v.co
            group=obj.vertex_groups.get("hand_l")
            if group:group.name=shield_bone
