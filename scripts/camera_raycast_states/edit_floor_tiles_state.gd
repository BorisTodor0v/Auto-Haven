extends State

@onready var camera : Camera3D = $"../../CameraPivot/Camera3D"

@export var selected_tile_index : int = -1

signal floor_tile_changed

func _process(delta):
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
			if collider.is_in_group("Tile"):
				if collider.get_grid_map_cell_item(intersection["position"]) != selected_tile_index:
					if PlayerStats.get_cash() >= 50:
						if selected_tile_index != -1:
							collider.click_on_gridmap(intersection["position"], selected_tile_index)
							PlayerStats.remove_cash(50)
							floor_tile_changed.emit()
