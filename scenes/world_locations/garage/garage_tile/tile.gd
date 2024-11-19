class_name Tile
extends Node3D

@export var can_unlock : bool = false
@export var is_unlocked : bool = false

var is_editing : bool = false

@onready var ray_down : RayCast3D = $Rays/RayCast3DDown
@onready var ray_up : RayCast3D = $Rays/RayCast3DUp
@onready var ray_left : RayCast3D = $Rays/RayCast3DLeft
@onready var ray_right : RayCast3D = $Rays/RayCast3DRight
@onready var grid_map : GridMap = $GridMap

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func check_adjacent_tiles():
	if is_unlocked == false:
		var collider : Tile
		if ray_down.is_colliding():
			collider = ray_down.get_collider()
			if collider.get_is_unlocked() == true:
				can_unlock = true
		if ray_up.is_colliding():
			collider = ray_up.get_collider()
			if collider.get_is_unlocked() == true:
				can_unlock = true
		if ray_left.is_colliding():
			collider = ray_left.get_collider()
			if collider.get_is_unlocked() == true:
				can_unlock = true
		if ray_right.is_colliding():
			collider = ray_right.get_collider()
			if collider.get_is_unlocked() == true:
				can_unlock = true

func unlock_tile():
	if can_unlock:
		PlayerStats.set_tiles_owned(PlayerStats.get_tiles_owned() + 1)
		can_unlock = false
		is_unlocked = true
		make_adjacent_tiles_available()

func make_unlockable():
	if can_unlock == false && is_unlocked == false:
		can_unlock = true
		self.show()
	if is_unlocked == true:
		can_unlock = false

func make_adjacent_tiles_available():
	var collider : Tile
	if ray_down.is_colliding():
		collider = ray_down.get_collider()
		collider.make_unlockable()
	if ray_up.is_colliding():
		collider = ray_up.get_collider()
		collider.make_unlockable()
	if ray_left.is_colliding():
		collider = ray_left.get_collider()
		collider.make_unlockable()
	if ray_right.is_colliding():
		collider = ray_right.get_collider()
		collider.make_unlockable()

func get_status() -> String:
	return "Can unlock: " + str(can_unlock) + " | Is unlocked: " + str(is_unlocked)

func get_is_unlocked() -> bool:
	return is_unlocked

func get_can_unlock() -> bool:
	return can_unlock

## If the adjacent tile is unlocked, this tile can be unlocked
## Change collision mask to different layer
func check_can_unlock():
	var str_up = ""
	var str_down = ""
	var str_left = ""
	var str_right = ""
	if ray_down.is_colliding():
		str_down = "Down:" + str(ray_down.get_collider())
		return true
	if ray_up.is_colliding():
		str_up = "Up:" + str(ray_up.get_collider())
		return true
	if ray_left.is_colliding():
		str_left = "Left:" + str(ray_left.get_collider())
		return true
	if ray_right.is_colliding():
		str_right = "Right:" + str(ray_right.get_collider())
		return true
	return str_down + "|" + str_up + "|" + str_left + "|" + str_right

func start_edit():
	is_editing = true
	if is_unlocked == false:
		self.hide()

func stop_edit():
	is_editing = false
	if self.visible == false && is_unlocked == true:
		self.show()

func click_on_gridmap(intersect_position : Vector3, tile : int):
	if is_unlocked == true:
		intersect_position.y = 0
		if is_editing == true:
			var point = grid_map.local_to_map(intersect_position)
			# When getting only point.x/y it can give coordinates outside of the bounds of the grid
			# map. One grid has 10 tiles, so to get the coordinates of the tile within the bounds
			# of the grid, the point.x/y coordinate is divided by 10 and the remainder of the
			# division is taken as the local coordinate.
			point.x = point.x % 10
			point.z = point.z % 10
			grid_map.set_cell_item(point, tile)
