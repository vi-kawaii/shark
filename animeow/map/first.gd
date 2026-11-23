extends Node3D

class_name map_first

func _ready():
	var plane = PlaneMesh.new()
	plane.size = Vector2(20, 20)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = plane

	var visual = Node3D.new()
	visual.name = "Visual"
	visual.add_child(mesh_instance)
	add_child(visual)

	var box = BoxShape3D.new()
	box.size = Vector3(20, 0.5, 20)

	var collision_shape = CollisionShape3D.new()
	collision_shape.position.y = -0.25
	collision_shape.shape = box

	var static_body = StaticBody3D.new()
	static_body.name = "StaticBody3D"
	static_body.add_child(collision_shape)
	add_child(static_body)
