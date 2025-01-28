extends WorldLocation

@onready var car_lifts : Node3D = $CarLifts
@onready var job_car_spots : Node3D = $JobCarSpots
@onready var pending_cars : Array = []
@onready var garage_tiles : Node3D = $Tiles
@onready var player_cars : Node3D = $PlayerCars
@onready var furniture : Node3D = $Furniture
@onready var walls : Node3D = $Walls

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
	camera_initial_position = camera.global_position
	camera_initial_rotation = camera.global_rotation

func get_job_car_spots() -> Node3D:
	return job_car_spots

func add_pending_car(pending_car : StaticBody3D):
	if pending_cars.size() < job_car_spots.get_child_count():
		pending_cars.append(pending_car)
		pending_car.connect("start_repair", start_car_repair)
		pending_car.connect("repair_completed", finish_car_repair)

func start_car_repair(car : StaticBody3D, is_started_by_player : bool):
	# Find first available car lift
	for lift : Node3D in car_lifts.get_children():
		if lift.can_take_car():
			car.global_position = lift.global_position
			car.global_rotation = lift.global_rotation
			car.reparent(lift, true)
			lift.start(car, is_started_by_player)
			pending_cars.erase(car)
			break

func finish_car_repair(cash_reward : int, rep_reward : int, is_repaired_by_player : bool):
	repair_completed.emit(cash_reward, rep_reward, is_repaired_by_player)

func get_pending_cars() -> Array:
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
			print_debug("ENABLING DEFAULT STATE")
			raycast_default_state.enable_state()
			raycast_place_object_state.disable_state()
			raycast_edit_floor_tiles_state.disable_state()
			raycast_edit_floor_tiles_state.selected_tile_index = -1
		"place_object":
			print_debug("ENABLING PLACE OBJECT STATE")
			raycast_default_state.disable_state()
			raycast_place_object_state.enable_state()
			raycast_edit_floor_tiles_state.disable_state()
			raycast_edit_floor_tiles_state.selected_tile_index = -1
		"edit_floor_tiles":
			print_debug("ENABLING EDIT FLOOR TILE STATE")
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
		print_debug("Placed item successfully")
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
				print_debug("Invalid item type, can't reparent. Won't be saved")
	else:
		print_debug("Cancelled placing item")
		raycast_place_object_state.clear_item()
		end_placing_item.emit("", null)
	set_camera_raycast_states("default")
	
func begin_floor_tile_edit(selected_tile_index : int):
	raycast_edit_floor_tiles_state.selected_tile_index = selected_tile_index
	set_camera_raycast_states("edit_floor_tiles")

func _on_visibility_changed():
	camera.global_position = camera_initial_position
	camera.global_rotation = camera_initial_rotation

func remove_car(id : int):
	for car in player_cars.get_children():
		if car.internal_id == id:
			car.queue_free()
			break
