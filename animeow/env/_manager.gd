extends Node3D

func _ready():
	var world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"

	var sky_material = ProceduralSkyMaterial.new()

	var sky = Sky.new()
	sky.sky_material = sky_material

	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.background_color = Color(
		0.2231029,
		0.2231029,
		0.22310287,
		1.0
	)
	environment.sky = sky

	world_environment.environment = environment
	add_child(world_environment)

	var directional_light = DirectionalLight3D.new()
	directional_light.name = "DirectionalLight3D"

	directional_light.transform = Transform3D(
		Basis(
			Vector3.RIGHT,
			Vector3.FORWARD,
			Vector3.UP
		),
		Vector3.ZERO
	)

	add_child(directional_light)
