extends WorldLocation

@onready var car_lifts : Node3D = $CarLifts
@onready var job_car_spots : Node3D = $JobCarSpots
@onready var garage_tiles : Node3D = $Tiles
@onready var player_cars : Node3D = $PlayerCars
@onready var furniture : Node3D = $Furniture
@onready var walls : Node3D = $Walls
@onready var camera_pivot : Node3D = $CameraPivot

var raycast_default_state_enabled : bool = false
@onready var raycast_default_state : State = $CameraStates/DefaultState
@onready var raycast_place_object_state : State = $CameraStates/PlaceObjectState
@onready var raycast_edit_floor_tiles_state : State = $CameraStates/EditFloorTilesState

signal repair_completed(cash_reward : int, rep_reward : int)
signal pressed_on_tile(tile : Tile)
signal pressed_on_object(object_node : Node3D, object_name : String, car_id : int)
signal end_placing_item
signal update_labels

var camera_initial_position : Vector3
var camera_initial_rotation : Vector3

func _ready():
	set_camera($CameraPivot/Camera3D)
	raycast_default_state.connect("pressed_on_tile", pressed_on_tile.emit)
	raycast_default_state.connect("pressed_on_object", pressed_on_object.emit)
	raycast_place_object_state.connect("item_placed", finish_placing_item)
	raycast_edit_floor_tiles_state.connect("floor_tile_changed", update_labels.emit)
	set_camera_raycast_states("default")
	camera_initial_position = camera_pivot.global_position
	camera_initial_rotation = camera_pivot.global_rotation

func get_job_car_spots() -> Node3D:
	return job_car_spots

func add_pending_car(pending_car : JobCar):
	pending_car.connect("start_repair", start_car_repair)
	pending_car.connect("repair_completed", finish_car_repair)
	pending_car.connect("ask_for_repair", process_pending_car_repair_request)

func start_car_repair(car : JobCar, is_started_by_player : bool):
	var vacant_car_lift : CarLift = find_available_car_lift()
	car.reparent(vacant_car_lift, true)
	car.global_position = vacant_car_lift.global_position
	car.global_rotation = vacant_car_lift.global_rotation
	vacant_car_lift.start(car, is_started_by_player)

func finish_car_repair(cash_reward : int, rep_reward : int, is_repaired_by_player : bool):
	repair_completed.emit(cash_reward, rep_reward, is_repaired_by_player)

func get_pending_cars() -> Array[JobCar]:
	var pending_cars : Array[JobCar] = []
	for car_spot in job_car_spots.get_children():
		if car_spot.get_child_count() != 0:
			pending_cars.append(car_spot.get_child(0))
	return pending_cars

func show_unlockable_tiles():
	for tile : Tile in garage_tiles.get_children():
		tile.check_adjacent_tiles()
		if tile.can_unlock == true:
			tile.show()

func hide_unlockable_tiles():
	for tile : Tile in garage_tiles.get_children():
		tile.check_adjacent_tiles()
		if tile.can_unlock == true:
			tile.hide()

func set_camera_raycast_states(state : String):
	match state:
		"default":
			#print_debug("ENABLING DEFAULT STATE")
			raycast_default_state.enable_state()
			raycast_place_object_state.disable_state()
			raycast_edit_floor_tiles_state.disable_state()
			raycast_edit_floor_tiles_state.selected_tile_index = -1
		"place_object":
			#print_debug("ENABLING PLACE OBJECT STATE")
			raycast_default_state.disable_state()
			raycast_place_object_state.enable_state()
			raycast_edit_floor_tiles_state.disable_state()
			raycast_edit_floor_tiles_state.selected_tile_index = -1
		"edit_floor_tiles":
			#print_debug("ENABLING EDIT FLOOR TILE STATE")
			raycast_default_state.disable_state()
			raycast_place_object_state.disable_state()
			raycast_edit_floor_tiles_state.enable_state()

func begin_placing_item(item_type : String, item):
	raycast_place_object_state.set_item(item_type, item)
	set_camera_raycast_states("place_object")

func begin_edit_item(item_node : Node3D, item_name : String, car_id : String):
	raycast_place_object_state.set_edit_item(item_node, item_name, car_id)
	set_camera_raycast_states("place_object")

func finish_placing_item(placed_successfully : bool, placed_item_type : String, placed_item_id, placed_item : Node3D): # : String):
	if placed_successfully == true && placed_item_type != "" && placed_item_id != null:
		end_placing_item.emit(placed_item_type, placed_item_id)
		#print_debug("Placed item successfully")
		match placed_item_type:
			"car":
				placed_item.reparent(player_cars, true)
			"furniture":
				if placed_item_id.begins_with("car_lift"):
					placed_item.reparent(car_lifts, true)
				else:
					placed_item.reparent(furniture, true)
			"walls":
				placed_item.reparent(walls, true)
			_:
				#print_debug("Invalid item type, can't reparent. Won't be saved")
				pass
	else:
		#print_debug("Cancelled placing item")
		raycast_place_object_state.clear_item()
		end_placing_item.emit("", null)
	set_camera_raycast_states("default")

func begin_floor_tile_edit(selected_tile_index : int):
	raycast_edit_floor_tiles_state.selected_tile_index = selected_tile_index
	set_camera_raycast_states("edit_floor_tiles")

func _on_visibility_changed():
	camera_pivot.global_position = camera_initial_position
	camera_pivot.global_rotation = camera_initial_rotation
	raycast_default_state.raycast_enabled = self.visible

func remove_car(id : String):
	for car in player_cars.get_children():
		if car.internal_id == id:
			car.queue_free()
			break

func place_player_owned_cars(player_cars_placed_in_garage : Dictionary):
	for car in player_cars_placed_in_garage:
		var player_car_data : Dictionary = PlayerStats.get_car(player_cars_placed_in_garage[car]["internal_id"])
		var general_car_data : Dictionary = CarsData.get_car(player_car_data["model"])
		
		# Load and instantiate the player car scene and assign internal variables
		var player_car_scene = load(general_car_data["scene_path"])
		var player_car = player_car_scene.instantiate()
		player_car.set_internal_name(player_car_data["model"])
		player_car.set_internal_id(player_cars_placed_in_garage[car]["internal_id"])
		
		# Place car in the garage
		player_cars.add_child(player_car)
		var position_vector : Vector3 = Vector3(player_cars_placed_in_garage[car]["position_x"], \
												player_cars_placed_in_garage[car]["position_y"], \
												player_cars_placed_in_garage[car]["position_z"])
		var rotation_vector : Vector3 = Vector3(player_cars_placed_in_garage[car]["rotation_x"], \
												player_cars_placed_in_garage[car]["rotation_y"], \
												player_cars_placed_in_garage[car]["rotation_z"])
		player_car.position = position_vector
		player_car.rotation = rotation_vector
		
		# Add wheels to the car model
		var wheel_model = load("res://cars/wheels/"+player_car_data["wheels"]+"/"+player_car_data["wheels"]+".glb").instantiate()
		for child in player_car.get_children():
			if child.name == "WheelPositions":
				for wheel_position in child.get_children():
					wheel_position.add_child(wheel_model.duplicate())
				break
		
		# Change color
		var material : StandardMaterial3D = load("res://resources/shaders/car_base_color.tres").duplicate()
		var mesh : MeshInstance3D = null
		for child in player_car.get_children():
			if child is MeshInstance3D:
				mesh = child
		if mesh != null && material != null:
			material.albedo_color = CarsData.parse_color_from_string(player_car_data["color"])
			mesh.set_surface_override_material(0, material)

func place_garage_decor(decor_items_in_garage : Dictionary):
	for decor_item in decor_items_in_garage:
		var decor_item_data : Dictionary = FurnitureData.get_values_from_key(decor_items_in_garage[decor_item]["internal_name"])
		var decor_item_scene = load(decor_item_data["scene_path"])
		var decor_item_instance = decor_item_scene.instantiate()
		decor_item_instance.set_internal_name(decor_items_in_garage[decor_item]["internal_name"])
		
		# Place decor item in the garage
		furniture.add_child(decor_item_instance)
		var position_vector : Vector3 = Vector3(decor_items_in_garage[decor_item]["position_x"], \
												decor_items_in_garage[decor_item]["position_y"], \
												decor_items_in_garage[decor_item]["position_z"])
		var rotation_vector : Vector3 = Vector3(decor_items_in_garage[decor_item]["rotation_x"], \
												decor_items_in_garage[decor_item]["rotation_y"], \
												decor_items_in_garage[decor_item]["rotation_z"])
		decor_item_instance.position = position_vector
		decor_item_instance.rotation = rotation_vector

func place_car_lifts(car_lifts_in_garage : Dictionary):
	for child in car_lifts.get_children():
		child.queue_free()
	for car_lift in car_lifts_in_garage:
		var car_lift_data : Dictionary = FurnitureData.get_values_from_key(car_lifts_in_garage[car_lift]["internal_name"])
		var car_lift_scene = load(car_lift_data["scene_path"])
		var car_lift_instance = car_lift_scene.instantiate()
		car_lift_instance.set_internal_name(car_lifts_in_garage[car_lift]["internal_name"])
		
		# Place decor item in the garage
		car_lifts.add_child(car_lift_instance)
		var position_vector : Vector3 = Vector3(car_lifts_in_garage[car_lift]["position_x"], \
												car_lifts_in_garage[car_lift]["position_y"], \
												car_lifts_in_garage[car_lift]["position_z"])
		var rotation_vector : Vector3 = Vector3(car_lifts_in_garage[car_lift]["rotation_x"], \
												car_lifts_in_garage[car_lift]["rotation_y"], \
												car_lifts_in_garage[car_lift]["rotation_z"])
		car_lift_instance.position = position_vector
		car_lift_instance.rotation = rotation_vector

func place_walls(_walls : Dictionary):
	for child in walls.get_children():
		child.queue_free()
	var wall_material : StandardMaterial3D = load("res://resources/materials/grid_pallete_material_with_backfaces.tres")
	for wall in _walls:
		var wall_data = FurnitureData.walls[_walls[wall]["internal_name"]]
		var wall_scene = load("res://garage_decorations/props/walls/wall_scene.tscn").instantiate()
		var wall_model = load(wall_data["model_path"]).instantiate()
		var wall_mesh : MeshInstance3D = wall_model.get_child(0)
		# Place decor item in the garage
		walls.add_child(wall_scene)
		wall_scene.set_internal_name(_walls[wall]["internal_name"])
		
		wall_mesh.reparent(wall_scene, true)
		wall_scene.move_child(wall_mesh, 0)
		wall_mesh.set_surface_override_material(0, wall_material)
		# Offset mesh in wall scene to match collision
		wall_mesh.global_position.z = -1
		
		var position_vector : Vector3 = Vector3(_walls[wall]["position_x"], \
												_walls[wall]["position_y"], \
												_walls[wall]["position_z"])
		var rotation_vector : Vector3 = Vector3(_walls[wall]["rotation_x"], \
												_walls[wall]["rotation_y"], \
												_walls[wall]["rotation_z"])
		wall_scene.position = position_vector
		wall_scene.rotation = rotation_vector

func load_tiles(_tiles : Dictionary):
	# Go through each tile and paint the cells from the loaded tile data
	for _tile in _tiles:
		var position_vector : Vector3 = Vector3(_tiles[_tile]["position_x"], \
												_tiles[_tile]["position_y"], \
												_tiles[_tile]["position_z"])
		for tile : Tile in garage_tiles.get_children():
			if position_vector == tile.position:
				if tile.is_unlocked == false:
					tile.unlock_tile()
					tile.show()
					tile.make_adjacent_tiles_available()
				
				var tile_grid_map : GridMap = tile.get_grid_map()
				for mesh_library_item in _tiles[_tile]["mesh_library_items"]:
					for cell in _tiles[_tile]["mesh_library_items"][mesh_library_item]:
						var remove_brackets = cell.erase(0, 1)
						remove_brackets = remove_brackets.erase(remove_brackets.length()-1, 1)
						var split_segments = remove_brackets.split(',')
						var x : float = float(split_segments[0])
						var y : float = float(split_segments[1])
						var z : float = float(split_segments[2])
						var cell_coordinates : Vector3 = Vector3(x, y, z)
						tile_grid_map.set_cell_item(cell_coordinates, int(mesh_library_item))
				break

func find_available_car_lift() -> CarLift:
	for car_lift in car_lifts.get_children():
		if car_lift.can_take_car():
			return car_lift
	return null

func process_pending_car_repair_request(pending_car : JobCar):
	var available_car_lift : CarLift = find_available_car_lift()
	if available_car_lift:
		pending_car.process_repair_response(available_car_lift != null)
		pending_car.car_lift = available_car_lift
