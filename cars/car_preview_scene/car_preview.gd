extends Node3D

@export var camera_fov : float = 50

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_car(car_data : Dictionary):
	var car_model = load(car_data["model_path"]).instantiate()
	var wheel_model = load("res://cars/wheels/"+car_data["default_wheels"]+"/"+car_data["default_wheels"]+".glb").instantiate()
	## Add wheels to the car model
	for child in car_model.get_children():
		if child.name == "WheelPositions":
			for wheel_position in child.get_children():
				wheel_position.add_child(wheel_model.duplicate())
			break
	$CarPosition.add_child(car_model)

func set_model(model_path : String, model_scale : float):
	var model : Node3D = load(model_path).instantiate()
	var model_mesh : MeshInstance3D = model.get_child(0)
	if model_mesh != null:
		var material : StandardMaterial3D = model_mesh.get_active_material(0)
		if material.albedo_texture == null:
			material.albedo_texture = load("res://resources/images/Gradient Pallete.png")
	model.scale = Vector3(model_scale, model_scale, model_scale)
	$CarPosition.add_child(model)
