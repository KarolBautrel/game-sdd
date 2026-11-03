"""Original environment family using the actors' materials and tactical camera."""
import json,math,random,sys
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
import build_roster as base
from roster_geometry import Geometry

NAMES=['oak','pine','dead_tree','bush','stump','fallen_log','branches','boulder','rock_cluster','grass','flowers','mushrooms','crate','barrel','chest','coffin','pillar','broken_pillar','arch','wall','rubble','brazier','altar','statue','bones','spike_fence','bone_totem','sacks']

def build(ident):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    folder=ROOT/'assets_src/environment/props'/ident;folder.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.armature_add();rig=bpy.context.object;rig.data.bones[0].name='root'
    g=Geometry(rig);random.seed(ident)
    wood=g.material('Oiled worn wood',(.18,.09,.035),atlas=12)
    stone=g.material('Warm-grey worn stone',(.24,.25,.23))
    stone_light=g.material('Stone chipped edges',(.31,.32,.285))
    iron=g.material('Worn actor iron',(.29,.32,.32),.52,.65,atlas=4)
    brass=g.material('Aged actor brass',(.36,.27,.11),.65,.35,atlas=14)
    bone=g.material('Aged actor bone',(.55,.49,.34),atlas=7)
    cloth=g.material('Rough woven sack',(.23,.20,.13))
    leaves=[g.material('Olive foliage '+str(i),colour) for i,colour in enumerate([(.12,.155,.06),(.18,.22,.085),(.23,.26,.11)])]
    # Broad painted material clusters, shared with the floor, avoid toy-like flat
    # green spheres and white procedural rocks under the neutral studio lights.
    def painted(mat,offset,tint):
        nodes=mat.node_tree.nodes;links=mat.node_tree.links
        uv=nodes.new('ShaderNodeUVMap');uv.uv_map='DesignPatch'
        mul=nodes.new('ShaderNodeVectorMath');mul.operation='MULTIPLY';mul.inputs[1].default_value=(.48,.48,1)
        add=nodes.new('ShaderNodeVectorMath');add.operation='ADD';add.inputs[1].default_value=offset
        tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(ROOT/'assets_src/environment/floors-source.png'),check_existing=True)
        mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(*tint,1)
        links.new(uv.outputs[0],mul.inputs[0]);links.new(mul.outputs[0],add.inputs[0]);links.new(add.outputs[0],tex.inputs[0]);links.new(tex.outputs[0],mix.inputs[1]);links.new(mix.outputs[0],nodes.get('Principled BSDF').inputs['Base Color'])
    for i,mat in enumerate(leaves):painted(mat,(.01,.51,0),(.40+i*.08,1.35+i*.12,.15+i*.05))
    painted(stone,(.51,.01,0),(.90,.94,.91));painted(stone_light,(.51,.01,0),(1.12,1.15,1.09))
    flame=g.material('Warm flame',(.92,.25,.035),emission=2)
    core=g.material('Flame core',(1,.67,.13),emission=3)
    def ball(name,center,size,mat):
        obj=g.ellipsoid(name,center,size,'root',mat,12,6)
        if 'foliage' in name or 'leaf cluster' in name:
            origin=Vector(center)
            for vertex in obj.data.vertices:vertex.co=origin+(vertex.co-origin)*random.uniform(.82,1.13)
        return obj
    def box(name,center,size,mat):return g.box(name,center,size,'root',mat)
    def tube(name,points,radii,mat,sides=10):return g.tube(name,points,radii,'root',mat,sides)
    def rock(x=0,y=0,z=.25,r=.4):
        obj=ball('Broken irregular stone',(x,y,z),(r,r*.75,r*.8),stone)
        for vertex in obj.data.vertices:
            vertex.co.x+=random.uniform(-.045,.045);vertex.co.z=max(.01,vertex.co.z+random.uniform(-.045,.045))
        return obj
    def skull(center,scale=.14):
        x,y,z=center
        ball('Skull cranium',center,(scale*.85,scale*.7,scale),bone)
        box('Skull jaw',(x,y-.02,z-scale*.72),(scale*1.05,scale*.95,scale*.44),bone)
        dark=g.material('Deep eye sockets',(.025,.022,.018))
        for sign in [-1,1]:ball('Eye socket',(x+sign*scale*.34,y-scale*.65,z),(scale*.21,.025,scale*.25),dark)
    def stone_stack(height=1.7,broken=False):
        box('Foundation',(0,0,.11),(.73,.64,.22),stone_light)
        for level in range(5 if not broken else 3):
            box('Worn pillar course',(0,0,.28+level*.28),(.45,.43,.27),stone)
        top=.28+(4 if not broken else 2)*.28+.18
        box('Capital',(0,0,top),(.68,.61,.16),stone_light)
        if broken:
            for i in range(5):rock(random.uniform(-.6,.6),random.uniform(-.3,.4),.09,.12)
    if ident in ('oak','pine','dead_tree'):
        tube('Crooked main trunk',[(0,0,0),(.04,.02,.9),(-.10,.02,1.8),(.08,.02,2.8)],[.19,.145,.10,.035],wood)
        for i in range(7):
            a=i*math.tau/7
            tube('Spreading root',[(0,0,.2),(.39*math.cos(a),.31*math.sin(a),.025)],[.105,.018],wood)
        for i in range(8):
            a=i*2.4;z=1.3+i*.16
            end=Vector((math.cos(a)*.72,math.sin(a)*.58,z+.54))
            tube('Gnarled branch',[(0,0,z),tuple(end*.8+Vector((0,0,.3))),tuple(end)],[.075,.045,.012],wood)
            if ident=='oak':
                ball('Broad painted foliage',tuple(end+Vector((0,0,.15))),(.45,.40,.39),leaves[i%3])
                for sign in [-1,1]:ball('Irregular leaf cluster',tuple(end+Vector((sign*.25,.10,.28))),(.31,.28,.28),leaves[(i+1)%3])
        if ident=='oak':ball('Crown foliage',(.04,.02,2.9),(.64,.56,.50),leaves[1])
        elif ident=='pine':
            for level in range(5):
                z=.9+level*.43;r=.87-level*.13
                tube('Layered pine canopy',[(0,0,z),(0,0,z+.75)],[r,.02],leaves[level%3],12)
    elif ident=='bush':
        for i in range(7):
            a=i*2.4;p=(math.cos(a)*.28,math.sin(a)*.23,.35+random.random()*.18)
            tube('Shrub branch',[(0,0,.02),p],[.025,.012],wood)
            ball('Shrub leaf cluster',p,(.30,.27,.27),leaves[i%3])
    elif ident=='stump':
        tube('Broken stump',[(0,0,.02),(0,0,.4)],[.25,.21],wood,12)
        tube('Cut end',[(0,0,.401),(0,0,.417)],[.20,.20],cloth,14)
        for i in range(6):
            a=i*math.tau/6;tube('Root',[(0,0,.12),(.38*math.cos(a),.31*math.sin(a),.02)],[.07,.02],wood)
    elif ident in ('fallen_log','branches'):
        r=.18 if ident=='fallen_log' else .045
        for i in range(1 if ident=='fallen_log' else 5):
            y=(i-2)*.08;z=r+.015
            tube('Fallen weathered wood',[(-.65,y,z),(.62,y+.10,z+.025)],[r,r*.85],wood)
            tube('Snapped branch',[(-.10,y,z),(.18,y+.30,z+.18)],[r*.45,.018],wood)
        if ident=='fallen_log':
            for i in range(4):ball('Moss on log',(-.35+i*.22,.02,.31),(.18,.13,.05),leaves[i%3])
    elif ident in ('boulder','rock_cluster','rubble'):
        for i in range(1 if ident=='boulder' else (5 if ident=='rock_cluster' else 9)):
            r=.47 if ident=='boulder' else random.uniform(.12,.29)
            rock(random.uniform(-.40,.40) if i else 0,random.uniform(-.25,.25),r*.62,r)
    elif ident in ('grass','flowers','mushrooms'):
        for i in range(11):
            x,y=random.uniform(-.33,.33),random.uniform(-.23,.23);z=random.uniform(.09,.30)
            if ident=='mushrooms':
                tube('Mushroom stem',[(x,y,.01),(x,y,z)],[.015,.012],bone,7)
                ball('Mushroom cap',(x,y,z),(.065,.057,.033),wood if i%2 else cloth)
            else:
                tube('Grass blade',[(x,y,0),(x+.03,y+.03,z)],[.018,.002],leaves[i%3],5)
                if ident=='flowers' and i%2==0:ball('Small warm flower',(x+.03,y+.03,z),(.022,.022,.016),bone)
    elif ident in ('crate','chest','coffin'):
        sx,sy,sz=(.7,.62,.67) if ident=='crate' else ((.8,.52,.38) if ident=='chest' else (.75,1.45,.43))
        material=stone if ident=='coffin' else wood
        for i in range(5):box('Individual timber or stone plank',(-sx/2+sx*(i+.5)/5,0,sz/2),(sx/5-.012,sy,sz),material)
        for x in [-sx*.37,sx*.37]:box('Strap',(x,0,sz/2),(.048,sy+.035,sz+.025),iron)
        if ident=='coffin':
            box('Stone lid',(0,0,sz+.035),(sx+.06,sy+.055,.11),stone_light)
            box('Tomb cross',(0,-.02,sz+.098),(.08,.75,.015),stone)
            box('Tomb crossbar',(0,-.16,sz+.098),(.38,.07,.015),stone)
        else:box('Iron latch',(0,-sy/2-.025,sz*.85),(.09,.04,.16),brass)
        if ident=='chest':
            for i in range(5):
                left=-sx/2+sx*i/5+.005;right=left+sx/5-.010
                points=[(x,sy/2*math.cos(j*math.pi/8),sz+.22*math.sin(j*math.pi/8)) for x in [left,right] for j in range(9)]
                g.mesh('Vaulted chest lid stave',points,[(j,j+1,j+10,j+9) for j in range(8)]+[tuple(reversed(range(9))),tuple(range(9,18))],'root',wood)
            for x in [-sx*.36,sx*.36]:tube('Curved chest iron band',[(x,sy/2*math.cos(j*math.pi/16),sz+.225*math.sin(j*math.pi/16)) for j in range(17)],.018,iron,6)
        elif ident=='crate':
            for sign in [-1,1]:tube('Crate diagonal brace',[(-sx*.4,-sy/2-.025,.10 if sign==1 else sz-.10),(sx*.4,-sy/2-.025,sz-.10 if sign==1 else .10)],.035,wood,6)
    elif ident=='barrel':
        tube('Oak stave barrel',[(0,0,.02),(0,0,.16),(0,0,.48),(0,0,.70)],[.22,.27,.27,.22],wood,16)
        for z in [.12,.55]:tube('Iron barrel hoop',[(0,0,z),(0,0,z+.04)],[.274,.274],iron,16)
        tube('Oak lid',[(0,0,.705),(0,0,.715)],[.22,.22],wood,16)
    elif ident in ('pillar','broken_pillar'):stone_stack(broken=ident=='broken_pillar')
    elif ident=='arch':
        for sign in [-1,1]:
            for level in range(6):box('Arch upright masonry',(sign*.59,0,.15+level*.28),(.34,.48,.27),stone)
        for i in range(11):
            a0=i*math.pi/11+.004;a1=(i+1)*math.pi/11-.004
            outline=[(.47*math.cos(a0),1.65+.47*math.sin(a0)),(.79*math.cos(a0),1.65+.79*math.sin(a0)),(.79*math.cos(a1),1.65+.79*math.sin(a1)),(.47*math.cos(a1),1.65+.47*math.sin(a1))]
            vertices=[(x,y,z) for y in [-.25,.25] for x,z in outline]
            g.mesh('Fitted arch voussoir',vertices,[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'root',stone_light if i%3==0 else stone)
    elif ident=='wall':
        for level in range(4):
            for i in range(4):box('Staggered ruined masonry',(-.58+i*.38+(level%2)*.12,0,.14+level*.27),(.365,.38,.255),stone if i%2 else stone_light)
        for i in range(5):rock(random.uniform(-.75,.75),random.uniform(-.25,.25),.06,.10)
    elif ident=='brazier':
        tube('Brazier foot',[(0,0,.02),(0,0,.10)],[.25,.18],iron)
        tube('Brazier stem',[(0,0,.10),(0,0,1.08)],[.065,.045],iron)
        tube('Brazier bowl',[(0,0,.94),(0,0,1.15)],[.10,.27],iron,12)
        for i in range(6):
            a=i*math.tau/6;tube('Basket bars',[(.24*math.cos(a),.24*math.sin(a),1.03),(.24*math.cos(a),.24*math.sin(a),1.32)],[.018,.018],iron,6)
            tube('Flame tongue',[(.1*math.cos(a),.1*math.sin(a),1.15),(.05*math.cos(a),.05*math.sin(a),1.47+random.random()*.15)],[.07,.001],flame,7)
        tube('Flame heart',[(0,0,1.15),(0,0,1.49)],[.10,.001],core,8)
    elif ident in ('altar','statue'):
        box('Stone plinth',(0,0,.10),(.95,.72,.20),stone_light)
        if ident=='altar':
            box('Altar base',(0,0,.34),(.68,.51,.55),stone)
            box('Altar slab',(0,0,.65),(1.02,.74,.14),stone_light)
            skull((0,-.10,.83),.13)
            for sign in [-1,1]:tube('Beeswax candle',[(sign*.32,0,.72),(sign*.32,0,.97)],[.035,.035],bone)
        else:
            g.shell('Weathered statue robes',[(.2,.34,.23,0),(.65,.25,.19,0),(1.25,.21,.15,0),(1.5,.31,.15,0)],'root',stone)
            ball('Statue hood',(0,0,1.70),(.19,.17,.24),stone_light)
            for sign in [-1,1]:tube('Statue folded arms',[(sign*.28,0,1.40),(sign*.22,-.2,1.1),(0,-.24,1.2)],[.09,.08,.07],stone)
            tube('Stone sword',[(0,-.29,.28),(0,-.29,1.21)],[.026,.026],stone_light,8)
    elif ident=='bones':
        skull((-.16,-.03,.16),.14)
        for i in range(6):
            x,y=random.uniform(-.38,.38),random.uniform(-.24,.24)
            tube('Scattered old bone',[(x,y,.05),(x+.24,y+.12,.06)],[.025,.023],bone,8)
    elif ident=='spike_fence':
        for i in range(7):tube('Iron fence spike',[(-.6+i*.2,0,.02),(-.6+i*.2,0,1.0)],[.025,.003],iron,8)
        for z in [.25,.69]:box('Fence rail',(0,0,z),(1.38,.05,.06),iron)
    elif ident=='bone_totem':
        tube('Totem stake',[(0,0,0),(0,0,1.45)],[.08,.035],wood)
        for z in [.65,1.2]:skull((0,-.06,z),.18)
        for sign in [-1,1]:tube('Ritual bone',[(0,0,.9),(sign*.36,0,1.15)],[.04,.025],bone)
    elif ident=='sacks':
        for x,y,z,r in [(-.22,0,.25,.25),(.23,.06,.21,.21),(.02,.1,.54,.18)]:
            obj=g.shell('Folded provision sack',[(0,r*.65,r*.6,0),(r*.4,r,r*.8,0),(r*1.4,r*.85,r*.7,0),(r*1.85,r*.24,r*.20,0),(r*2.05,r*.34,r*.23,0)],'root',cloth,sides=12)
            for vertex in obj.data.vertices:vertex.co+=Vector((x,y,z-r))
            tube('Tied sack cord',[(x-r*.26,y-r*.2,z+r*.86),(x+r*.26,y-r*.2,z+r*.86)],.012,wood,6)
            for sign in [-1,1]:tube('Visible sack fold',[(x+sign*r*.2,y-r*.72,z-r*.45),(x+sign*r*.13,y-r*.75,z+r*.30)],[.006,.003],wood,5)
    actor=g.join();actor.name=ident+'_OriginalWorldMesh'
    scene,camera=base.scene_setup();scene.cycles.samples=8
    tex=base.bake_albedo(actor,folder/(ident+'_albedo.png'));tex.pack()
    # Aseprite adds a bounded, shared soft contact shadow. A Cycles shadow-catcher
    # plane produces noisy alpha across the canvas and contaminates sprite bounds.
    scene.render.resolution_x=scene.render.resolution_y=512
    base.camera_view(camera,330,18,ortho=5.12,z=1.7)
    scene.render.filepath=str(folder/'render.png');bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/(ident+'.blend')))
    bpy.ops.object.select_all(action='DESELECT');actor.select_set(True)
    bpy.context.view_layer.objects.active=actor
    bpy.ops.export_scene.fbx(filepath=str(folder/(ident+'.fbx')),use_selection=True,object_types={'MESH'},add_leaf_bones=False,bake_anim=False)
    (folder/'model.json').write_text(json.dumps({'id':ident,'pixels_per_metre':100,'camera_elevation':18,'triangles':sum(len(p.vertices)-2 for p in actor.data.polygons),'uv':bool(actor.data.uv_layers),'original':True},indent=2)+'\n')
    print('WORLD_PROP_PASS',ident,flush=True)

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser();parser.add_argument('--ids')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    for ident in args.ids.split(',') if args.ids else NAMES:build(ident)
