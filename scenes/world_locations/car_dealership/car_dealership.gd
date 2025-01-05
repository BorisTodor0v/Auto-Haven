extends WorldLocation

@onready var background_cars : Node3D = $dealership/BackgroundCars
@onready var car_position : Node3D = $dealership/Podium/CarPosition

var selected_car_color : Color
var current_car_material : StandardMaterial3D

## Time in seconds for the podium to complete one full rotation
@export var podium_rotation_time : float = 10 # Seconds
var rotation_speed : float
@onready var podium : Node3D = $dealership/Podium

signal player_bought_car(car_key : String, car_color : Color)

# Called when the node enters the scene tree for the first time.
func _ready():
	rotation_speed = (2 * PI) / podium_rotation_time
	set_camera($Camera3D)
	set_ui($UI)
	ui.connect("leave_location", leave_location.emit)
	ui.connect("selected_car", player_selected_car)
	ui.connect("player_bought_car", buy_car)
	ui.connect("color_changed", car_color_changed)
	set_background_cars()
	set_initial_car()

func _process(delta):
	podium.rotation_degrees.y += rad_to_deg(rotation_speed * delta)

func set_background_cars():
	for spot : Node3D in background_cars.get_children():
		if spot.get_child_count() == 0:
			var size = CarsData.get_all_cars().size()
			#var random_car_key = CarsData.get_all_cars().keys()[randi() % size]
			var random_car_key
			while random_car_key == null:
				var key = CarsData.get_all_cars().keys()[randi() % size]
				if CarsData.get_car(key)["can_buy_in_dealership"] == true:
					random_car_key = key
			var random_car = CarsData.get_car(random_car_key)
			var instance = load(random_car["model_path"]).instantiate()
			var material : StandardMaterial3D = load("res://resources/shaders/car_base_color.tres").duplicate()
			var mesh : MeshInstance3D = null
			for child in instance.get_children():
				if child is MeshInstance3D:
					mesh = child
			if mesh != null && material != null:
				material.albedo_color = Color(randf(), randf(), randf(), 1)
				mesh.set_surface_override_material(0, material)
			## Add wheels to the car model
			var wheel_model = load("res://cars/wheels/"+random_car["default_wheels"]+"/"+random_car["default_wheels"]+".glb").instantiate()
			for child in instance.get_children():
				if child.name == "WheelPositions":
					for wheel_position in child.get_children():
						wheel_position.add_child(wheel_model.duplicate())
					break
			spot.add_child(instance)

func set_initial_car():
	for car in CarsData.get_all_cars():
		if CarsData.get_car(car)["can_buy_in_dealership"] == true:
			player_selected_car(car)
			break

func player_selected_car(car_key : String):
	ui.display_car_stats(car_key)
	var car_data = CarsData.get_car(car_key)
	var car = load(car_data["model_path"]).instantiate()
	if car_position.get_child_count() > 0:
		car_position.get_child(0).queue_free()
	## Add wheels to the car model
	var wheel_model = load("res://cars/wheels/"+car_data["default_wheels"]+"/"+car_data["default_wheels"]+".glb").instantiate()
	for child in car.get_children():
		if child.name == "WheelPositions":
			for wheel_position in child.get_children():
				wheel_position.add_child(wheel_model.duplicate())
			break
	car_position.add_child(car)
	## Pass the car color
	var mesh : MeshInstance3D = null
	for child in car.get_children():
		if child is MeshInstance3D:
			mesh = child
	if mesh != null:
		selected_car_color = mesh.get_active_material(0).albedo_color
		ui.set_car_color_picker_button_color(selected_car_color)
		current_car_material = mesh.get_active_material(0)

func buy_car(car_key : String):
	player_bought_car.emit(car_key, selected_car_color)

func car_color_changed(color : Color):
	selected_car_color = color
	current_car_material.albedo_color = color
