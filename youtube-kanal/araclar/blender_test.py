import bpy, math, time
bpy.ops.wm.read_factory_settings(use_empty=True)
sc=bpy.context.scene
sc.render.engine='CYCLES'; sc.cycles.device='CPU'; sc.cycles.samples=48; sc.cycles.use_denoising=True
sc.render.resolution_x=1920; sc.render.resolution_y=1080
# dünya: gün batımı gökyüzü
w=bpy.data.worlds.new("W"); sc.world=w; w.use_nodes=True
nt=w.node_tree; sky=nt.nodes.new("ShaderNodeTexSky"); sky.sun_elevation=math.radians(4); sky.sun_rotation=math.radians(200)
nt.links.new(sky.outputs[0], nt.nodes["Background"].inputs[0]); nt.nodes["Background"].inputs[1].default_value=0.6
def mat(name,col,rough=0.7,noise=False):
    m=bpy.data.materials.new(name); m.use_nodes=True; b=m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value=(*col,1); b.inputs["Roughness"].default_value=rough
    if noise:
        n=m.node_tree.nodes.new("ShaderNodeTexNoise"); n.inputs["Scale"].default_value=40
        r=m.node_tree.nodes.new("ShaderNodeValToRGB"); r.color_ramp.elements[0].color=(col[0]*0.5,col[1]*0.5,col[2]*0.5,1); r.color_ramp.elements[1].color=(*col,1)
        m.node_tree.links.new(n.outputs[0],r.inputs[0]); m.node_tree.links.new(r.outputs[0],b.inputs["Base Color"])
    return m
bpy.ops.mesh.primitive_plane_add(size=200); bpy.context.object.data.materials.append(mat("grass",(0.08,0.12,0.04),0.9,True))
bpy.ops.mesh.primitive_plane_add(size=1,location=(0,-6,0.01)); r=bpy.context.object; r.scale=(200,6,1); r.data.materials.append(mat("asphalt",(0.05,0.05,0.05),0.8,True))
for i,x in enumerate(range(-30,31,15)):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(x,18,3)); h=bpy.context.object; h.scale=(10,8,6); h.data.materials.append(mat("wall%d"%i,(0.5,0.45,0.4),0.8,True))
    bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=7.5,depth=4,location=(x,18,8)); c=bpy.context.object; c.rotation_euler[2]=math.radians(45); c.scale=(1,0.8,1); c.data.materials.append(mat("roof%d"%i,(0.2,0.08,0.06),0.7))
    bpy.ops.mesh.primitive_plane_add(size=1,location=(x-2,13.95,3),rotation=(math.radians(90),0,0)); win=bpy.context.object; win.scale=(1.6,1.4,1)
    em=bpy.data.materials.new("win%d"%i); em.use_nodes=True; e=em.node_tree.nodes["Principled BSDF"]; e.inputs["Emission Color"].default_value=(1,0.6,0.25,1); e.inputs["Emission Strength"].default_value=6; win.data.materials.append(em)
# insansı figür (kapsüller)
skin=mat("skin",(0.25,0.3,0.2),0.6)
def cap(loc,rad,depth,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=rad,depth=depth,location=loc,rotation=rot); o=bpy.context.object; bpy.ops.object.shade_smooth(); o.data.materials.append(skin); return o
cap((2,2,0.45),0.12,0.9); cap((2.35,2,0.45),0.12,0.9); cap((2.17,2,1.35),0.3,0.9)
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.22,location=(2.17,1.95,2.0)); bpy.ops.object.shade_smooth(); bpy.context.object.data.materials.append(skin)
cap((1.75,1.8,1.45),0.08,0.8,(math.radians(60),0,math.radians(-20))); cap((2.6,1.8,1.45),0.08,0.8,(math.radians(60),0,math.radians(20)))
bpy.ops.object.light_add(type='SUN',rotation=(math.radians(86),0,math.radians(200))); bpy.context.object.data.energy=3; bpy.context.object.data.color=(1,0.55,0.3)
bpy.ops.object.camera_add(location=(4.5,-6,1.6),rotation=(math.radians(84),0,math.radians(22))); sc.camera=bpy.context.object; bpy.context.object.data.lens=35
sc.render.filepath="/tmp/claude-0/-home-user-Li/e70ecee3-7ccd-56ad-a124-e08414ca6ca8/scratchpad/b_test.png"
t=time.time(); bpy.ops.render.render(write_still=True); print("RENDER_SEC", round(time.time()-t,1))
