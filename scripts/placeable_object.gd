class_name PlaceableObject
extends Node

@onready var collision_area : Area3D = $Area3D
@onready var edge_rays : Node3D = $EdgeDetectionRays

@export var internal_name : String

func is_unobstructed() -> bool:
	if collision_area.get_overlapping_areas().is_empty():
		for ray : RayCast3D in edge_rays.get_children():
			if ray.is_colliding() && ray.get_collider().visible == false || not ray.is_colliding():
				return false
		return true
	else:
		return false

func can_afford() -> bool:
	if PlayerStats.get_cash() < FurnitureData.get_values_from_key(internal_name)["price"]:
		return false
	else:
		return true

func disable_collision():
	$CollisionShape3D.disabled = true

func enable_collision():
	$CollisionShape3D.disabled = false

func disable_area_3d():
	$Area3D/CollisionShape3D.disabled = true

func enable_area_3d():
	$Area3D/CollisionShape3D.disabled = false

func set_internal_name(_name : String):
	internal_name = _name

func get_internal_name():
	return internal_name
