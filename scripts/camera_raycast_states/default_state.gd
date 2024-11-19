extends State

@onready var camera : Camera3D = $"../../CameraPivot/Camera3D"

signal pressed_on_tile(tile : Tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var mouse_position : Vector2 = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_end = camera.project_ray_normal(mouse_position) * 2000
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var space_state = get_world_3d().direct_space_state
	var intersection = space_state.intersect_ray(ray_query)
	var collider
	
	if(Input.is_action_just_pressed("mouse1")):
		if intersection:
			collider = intersection["collider"]
			if collider is Interactable:
				collider.interact()
			if collider is Tile:
				pressed_on_tile.emit(collider)
			if collider is PlaceableObject or collider is Car:
				print_debug("Can move this object")
