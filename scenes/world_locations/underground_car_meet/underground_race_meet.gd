extends WorldLocation

@export var car_meet_camera : Camera3D
@export var race_location_camera : Camera3D

@export var car_meet : Node3D
@export var race_location : Node3D

@export var racer_car_positions : Node3D
@export var decor_car_positions : Node3D
@export var grid_positions : Node3D

var player_car : Car
var player_car_data : Dictionary
var player_car_general_data : Dictionary

# Key - Marker3D node which contains the racer as a child
# Values - See "generate_racer_cars" function
var racers_data : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	ui = $UI
	camera = $CameraPivot/Camera3D
	ui.connect("leave_location", leave_location.emit)
	ui.connect("begin_race", begin_race)
	camera.connect("pressed_on_racer", open_racer_interaction_menu)
	# TODO: Add highlights above player and racer cars to indicate clickable
	place_player_car()
	generate_racer_cars()
	generate_background_cars()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_camera():
	return $CameraPivot/Camera3D

func get_ui():
	return $UI

func place_player_car():
	if PlayerStats.get_active_car() > 0:
		player_car_data = PlayerStats.get_car(PlayerStats.get_active_car())
		player_car_general_data = CarsData.get_car(player_car_data["model"])
		
		var scene = load(player_car_general_data["scene_path"])
		var instance = scene.instantiate()
		player_car = instance
		
		## Find a spot to place the player car
		var car_position : int = randi_range(0, racer_car_positions.get_children().size()-1)
		racer_car_positions.get_child(car_position).add_child(player_car)
		
		## Add wheels to the car model
		var wheel_model = load("res://cars/wheels/"+player_car_data["wheels"]+"/"+player_car_data["wheels"]+".glb").instantiate()
		for child in instance.get_children():
			if child.name == "WheelPositions":
				for wheel_position in child.get_children():
					wheel_position.add_child(wheel_model.duplicate())
				break
	else:
		pass

func generate_racer_cars():
	for car_position in racer_car_positions.get_children():
		if randi_range(1, 10) > 6:
			if car_position.get_child_count() == 0:
				var random_car_key = CarsData.get_all_cars().keys()[randi() % CarsData.get_all_cars().size()]
				var general_car_data = CarsData.get_car(random_car_key)
				
				## Load the model for the racer's car
				var model = load(general_car_data["model_path"])
				var instance = model.instantiate()
				
				# Randomize car color
				var material : StandardMaterial3D = load("res://resources/shaders/car_base_color.tres").duplicate()
				var mesh : MeshInstance3D = null
				for child in instance.get_children():
					if child is MeshInstance3D:
						mesh = child
				if mesh != null && material != null:
					material.albedo_color = Color(randf(), randf(), randf(), 1)
					mesh.set_surface_override_material(0, material)
				
				# Add model to static body parent for raycast collision / detection
				var racer_car = instance
				var static_body_parent : StaticBody3D = StaticBody3D.new()
				static_body_parent.add_child(racer_car)
				static_body_parent.add_to_group("Racer")
				
				# Generate collision shape
				var collision_shape : CollisionShape3D =  CollisionShape3D.new()
				var convex_polygon_shape : ConvexPolygonShape3D = ConvexPolygonShape3D.new()
				var surface_array : Array = mesh.mesh.surface_get_arrays(0)
				var vertices = surface_array[ArrayMesh.ARRAY_VERTEX]
				convex_polygon_shape.points = vertices
				collision_shape.shape = convex_polygon_shape
				static_body_parent.add_child(collision_shape)
				
				car_position.add_child(static_body_parent)
				
				# Add wheels to the car model
				var wheel_model = load("res://cars/wheels/"+general_car_data["default_wheels"]+"/"+general_car_data["default_wheels"]+".glb").instantiate()
				for child in instance.get_children():
					if child.name == "WheelPositions":
						for wheel_position in child.get_children():
							wheel_position.add_child(wheel_model.duplicate())
						break
				
				## Generate racer data
				# TODO: ^ and place in the racers_data dictionary
				# Access when clicking on a racer
				# Store the marker where the racer is placed (car_position) as a key, data as value
				var wins : int = randi_range(0, 400)
				var losses : int = randi_range(0, 400)
				# TODO: Figure out how to generate rep from the winrate (Example, 50% WR should have some rep)
				var rep : int = (wins * 100) - (losses * 100)
				if rep < 0:
					rep = 0
				var racer_data : Dictionary = {
					"car": random_car_key,
					"car_data": general_car_data,
					# Handle racers having customized cars
					"rep": rep,
					"wins": wins,
					"losses": losses
				}
				racers_data.get_or_add(car_position, racer_data)
		else:
			pass

func generate_background_cars():
	for car_position in decor_car_positions.get_children():
		if randi_range(1, 10) > 4:
			if car_position.get_child_count() == 0:
				var random_car_key = CarsData.get_all_cars().keys()[randi() % CarsData.get_all_cars().size()]
				var general_car_data = CarsData.get_car(random_car_key)
			
				var model = load(general_car_data["model_path"])
				var instance = model.instantiate()
			
				# Randomize car color
				var material : StandardMaterial3D = load("res://resources/shaders/car_base_color.tres").duplicate()
				var mesh : MeshInstance3D = null
				for child in instance.get_children():
					if child is MeshInstance3D:
						mesh = child
				if mesh != null && material != null:
					material.albedo_color = Color(randf(), randf(), randf(), 1)
					mesh.set_surface_override_material(0, material)
				
				var decor_car = instance
				car_position.add_child(decor_car)
			
				## Add wheels to the car model
				var wheel_model = load("res://cars/wheels/"+general_car_data["default_wheels"]+"/"+general_car_data["default_wheels"]+".glb").instantiate()
				for child in instance.get_children():
					if child.name == "WheelPositions":
						for wheel_position in child.get_children():
							wheel_position.add_child(wheel_model.duplicate())
						break
		else:
			pass

func open_racer_interaction_menu(racer_position : Node3D):
	ui.show_racer_interact_screen(racers_data.get(racer_position))

func begin_race(wager : int):
	car_meet_camera.current = false
	race_location_camera.current = true
	car_meet.hide()
	race_location.show()
	print_debug("TODO: Transition to race location | Start race with wager of: " + str(wager))
