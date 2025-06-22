# gd_grappling_hook_3d

# license: MIT

# Information:
	Sample test for grapple hook and how mesh generator works as there couple ways making mesh.

# scenes:
- prototype_grappling_hook_3d.tscn
- rope_generator.tscn (editor tool test)
- rope_generator01.tscn( testing other rope )

# Editor
```
@tool
```
It need to reload editor scene or by closing the scene current hold @tool script and open it.

# rope_generator guide:
	You create empty mesh by using the gdscript but no uv yet. Base on youtube.
```
create MeshIstance3D
- mesh > new ImmediateMesh
```
- rope_generator00.gd

# Credits:
- How to make a GRAPPLING GUN / HOOK in Godot 4 Tutorial
	- https://www.youtube.com/watch?v=yuU6DO9-enM 
	- Mesh Rope 


# Refs:
- https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html
- https://www.youtube.com/watch?v=yWRHMOqoxGM  How to Make a 3D Grappling Hook in Godot 4
- https://www.youtube.com/watch?v=ecikN4f2bsA Godot Grappling Hook Addon
- https://www.youtube.com/watch?v=yuU6DO9-enM


- https://www.youtube.com/watch?v=2hXNkVEJu10
	- https://github.com/Elij4hMartin/Godot4-PinJoint-RopePhysics/tree/main
- https://www.youtube.com/watch?v=89er7j3-rb4
- https://www.youtube.com/watch?v=wFlolCYLf4c How To Make a GRAPPLING HOOK in GODOT 3D
- https://www.youtube.com/watch?v=q1TN649r8XQ Godot FPS Movement Tutorial - Basic Grappling Hook System
