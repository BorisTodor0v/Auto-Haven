extends Node3D

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

func set_model(model_path : String):
	var model : Node3D = load(model_path).instantiate()
	model.scale = Vector3(0.7, 0.7, 0.7)
	$CarPosition.add_child(model)
