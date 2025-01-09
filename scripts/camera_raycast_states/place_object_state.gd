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

var edit_mode_enabled : bool = false
var edit_object_original_position
var edit_object_original_rotation

var allow_placement_material : StandardMaterial3D = load("res://resources/shaders/green_transparent.tres")
var deny_placement_material : StandardMaterial3D = load("res://resources/shaders/red_transparent.tres")

func set_item(item_type : String, item):
	edit_mode_enabled = false # Placing a new item in the garage
	edit_object_original_position = null
	edit_object_original_rotation = null
	print_debug("Begin placing item:")
	if current_item != null:
		clear_item()
	current_item_type = item_type
	match item_type:
		"car":
			var player_car_data = PlayerStats.get_car(item)
			var car_model : String = player_car_data["model"]
			var car_scene_path : String = CarsData.get_car(player_car_data["model"])["scene_path"]

			var car_wheels : String = player_car_data["wheels"]
			var wheels_path : String = "res://cars/wheels/"+car_wheels+"/"+car_wheels+".glb"

			var car_instance = load(car_scene_path).instantiate()
			## Add wheels to the car model
			var wheel_model = load("res://cars/wheels/"+player_car_data["wheels"]+"/"+player_car_data["wheels"]+".glb").instantiate()
			for child in car_instance.get_children():
				if child.name == "WheelPositions":
					for wheel_position in child.get_children():
						wheel_position.add_child(wheel_model.duplicate())
					break

			current_item = car_instance
			current_item.set_internal_name(car_model)
			current_item.set_internal_id(item)
			current_item_id = item
			current_item_mesh = current_item.get_child(0)
			if current_item_mesh != null:
				current_item_default_material = current_item_mesh.get_active_material(0).duplicate()
				current_item_default_material.albedo_color = player_car_data["color"]
			else:
				print_debug("PROBLEM, MESH IS NULL")

			self.add_child(current_item)
			current_item.global_rotation.y = 0
		"furniture":
			print_debug("Furniture item")
			var furniture_item_data = FurnitureData.get_values_from_key(item)
			var furniture_item_model = furniture_item_data["model_path"]
			var furniture_item_scene = furniture_item_data["scene_path"]
			
			var furniture_item_instance = load(furniture_item_scene).instantiate()
			
			current_item = furniture_item_instance
			current_item.set_internal_name(str(item))
			if current_item.get_internal_name().begins_with("car_lift"):
				if current_item.has_car():
					current_item.disable_car_collision()
			current_item_id = item
			current_item_mesh = current_item.get_child(0)
			if current_item_mesh != null:
				current_item_default_material = current_item_mesh.get_active_material(0)
			else:
				print_debug("PROBLEM, MESH IS NULL")

			self.add_child(current_item)
			current_item.global_rotation.y = 0
		"walls":
			var wall_data = FurnitureData.walls[item]
			var wall_scene = load("res://garage_decorations/props/walls/wall_scene.tscn").instantiate()
			var wall_model = load(wall_data["model_path"]).instantiate()
			var wall_mesh : MeshInstance3D = wall_model.get_child(0)
			wall_mesh.reparent(wall_scene, true)
			wall_scene.move_child(wall_mesh, 0)
			var wall_material : StandardMaterial3D = wall_mesh.get_active_material(0)
			# Cull mode changed to render wall on both sides
			wall_material.cull_mode = BaseMaterial3D.CULL_DISABLED
			# Offset mesh in wall scene to match collision
			wall_mesh.global_position.z = -1
			
			current_item = wall_scene
			current_item.set_internal_name(str(item))
			current_item_id = item
			current_item_mesh = current_item.get_child(0)
			if current_item_mesh != null:
				current_item_default_material = current_item_mesh.get_active_material(0)
			else:
				print_debug("PROBLEM, MESH IS NULL")

			self.add_child(current_item)
			current_item.global_rotation.y = 0
		_:
			print_debug("Invalid item type")

func set_edit_item(item_node : Node3D, item_name : String, car_id : int):
	edit_mode_enabled = true # Moving an existing object in the garage
	edit_object_original_position = item_node.global_position # Memorize the previous position of the object
	edit_object_original_rotation = item_node.global_rotation # Memorize the previous rotation of the object
	if car_id == -1: # Item is a furniture object
		if item_name.begins_with("wall_"):
			current_item_type = "walls"
		else:
			current_item_type = "furniture"
		current_item = item_node
		current_item_id = item_name
		current_item_mesh = current_item.get_child(0)
		if current_item_mesh != null:
			current_item_default_material = current_item_mesh.get_active_material(0)
		else:
			print_debug("PROBLEM, MESH IS NULL")
		current_item.reparent(self, true)
	elif car_id >= 0: # Item is a player owned car
		# TODO: Instantiate wheels and add them to the car
		current_item = item_node
		current_item_type = "car"
		current_item.set_internal_name(str(item_name))
		current_item_id = car_id
		current_item_mesh = current_item.get_child(0)
		if current_item_mesh != null:
			current_item_default_material = current_item_mesh.get_active_material(0)
		else:
			print_debug("PROBLEM, MESH IS NULL")
	else:
		print_debug("Unknown item type") # Unknown item type

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
		item_placed.emit(placed_sucessfully, current_item_type, current_item_id, current_item)
		current_item_mesh.set_surface_override_material(0, current_item_default_material)

		if current_item.get_internal_name().begins_with("car_lift"):
			if current_item.has_car():
				current_item.enable_car_collision()

		current_item = null
		current_item_mesh = null
		current_item_default_material = null
		current_item_id = null
		current_item_type = ""
	else:
		if edit_mode_enabled == false:
			item_placed.emit(placed_sucessfully, "", null, null)
		else:
			current_item.global_position = edit_object_original_position
			current_item.global_rotation = edit_object_original_rotation
			item_placed.emit(true, current_item_type, current_item_id, current_item)
			current_item_mesh.set_surface_override_material(0, current_item_default_material)

			if current_item.get_internal_name().begins_with("car_lift"):
				if current_item.has_car():
					current_item.enable_car_collision()

			current_item = null
			current_item_mesh = null
			current_item_default_material = null
			current_item_id = null
			current_item_type = ""

func delete_item():
	match current_item_type:
			"car":
				if edit_mode_enabled:
					# Send the car to storage
					PlayerStats.get_car(current_item_id)["is_stored"] = true
					clear_item()
					item_placed.emit(false, "", null, null)
			"walls":
				if edit_mode_enabled:
					# Refund the player the price of the wall
					PlayerStats.add_cash(FurnitureData.walls[current_item_id]["price"])
					clear_item()
					item_placed.emit(false, "", null, null)
			"furniture":
				if edit_mode_enabled:
					# Refund the player the price of the wall
					PlayerStats.add_cash(FurnitureData.get_values_from_key(current_item_id)["price"])
					clear_item()
					item_placed.emit(false, "", null, null)
			_:
				print_debug("Unknown item type")

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
				## Position is in the same position of the cursor, no snapping
				#current_item.global_position = intersection["position"]
				## Snap current item position to integer values.
				current_item.global_position.x = int(intersection["position"][0])
				current_item.global_position.y = int(intersection["position"][1])
				current_item.global_position.z = int(intersection["position"][2])
				## Check for obstructions while moving the item
	
	if current_item != null:
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

	if(Input.is_action_just_pressed("ObjectPlaceDelete")):
		delete_item()
