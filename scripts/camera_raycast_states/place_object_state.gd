extends State

@onready var camera : Camera3D = $"../../CameraPivot/Camera3D"

signal item_placed(successfully : bool, item)

var current_item = null
var current_item_id = null
var current_item_type : String = ""
var current_item_mesh : MeshInstance3D = null
# When holding an item its material changes depending on whether or not the item can be placed
# This variable stores the original material of the item, so that when it is placed it can be restored
var current_item_default_material

var allow_placement_material : StandardMaterial3D = load("res://resources/shaders/green_transparent.tres")
var deny_placement_material : StandardMaterial3D = load("res://resources/shaders/red_transparent.tres")

func set_item(item_type : String, item):
	print("Begin placing item:")
	current_item_type = item_type
	match item_type:
		"car":
			if current_item != null:
				clear_item()
			var player_car_data = PlayerStats.get_car(item)
			var car_model : String = player_car_data["model"]
			var car_scene_path : String = CarsData.get_car(player_car_data["model"])["scene_path"]

			var car_wheels : String = player_car_data["wheels"]
			var wheels_path : String = "res://cars/wheels/"+car_wheels+"/"+car_wheels+".glb"

			var car_instance = load(car_scene_path).instantiate()
			# TODO: Instantiate wheels and add them to the car

			current_item = car_instance
			current_item_id = item
			current_item_mesh = current_item.get_child(0)
			if current_item_mesh != null:
				current_item_default_material = current_item_mesh.get_active_material(0)
				current_item_default_material.albedo_color = player_car_data["color"]
			else:
				print_debug("PROBLEM, MESH IS NULL")

			self.add_child(current_item)
			current_item.global_rotation.y = 0
		_:
			print_debug("Invalid item type")

func clear_item():
	if current_item != null:
		current_item.queue_free()
	current_item = null
	current_item_mesh = null
	current_item_default_material = null
	current_item_id = null
	current_item_type = ""

func place_item(placed_sucessfully : bool):
	if placed_sucessfully && current_item.is_unobstructed():
		item_placed.emit(placed_sucessfully, current_item_type, current_item_id)
		current_item_mesh.set_surface_override_material(0, current_item_default_material)

		current_item = null
		current_item_mesh = null
		current_item_default_material = null
		current_item_id = null
		current_item_type = ""
	else:
		item_placed.emit(placed_sucessfully, "", null)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var mouse_position : Vector2 = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_end = camera.project_ray_normal(mouse_position) * 2000
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var space_state = get_world_3d().direct_space_state
	var intersection = space_state.intersect_ray(ray_query)
	var collider
	#var position
	
	if intersection:
		collider = intersection["collider"]
		if collider is Tile:
			if collider.get_is_unlocked() == true:
				#position = intersection["position"]
				## Snap current item position to integer values.
				current_item.global_position.x = int(intersection["position"][0])
				current_item.global_position.y = int(intersection["position"][1])
				current_item.global_position.z = int(intersection["position"][2])
				## Check for obstructions while moving the item
				if current_item.is_unobstructed():
					current_item_mesh.set_surface_override_material(0, allow_placement_material)
				else:
					current_item_mesh.set_surface_override_material(0, deny_placement_material)
					
	
	if(Input.is_action_just_pressed("mouse1")):
		place_item(true)
	
	if(Input.is_action_just_pressed("mouse2")):
		place_item(false)

	if(Input.is_action_just_pressed("ObjectRotate")):
		current_item.rotate_y(deg_to_rad(90))
