class_name Car
extends Node

@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var collision_area : Area3D = $Area3D
@onready var edge_rays : Node3D = $EdgeDetectionRays
@onready var animation_player : AnimationPlayer
@onready var wheel_positions : Node3D = $WheelPositions

@export var internal_name : String

var internal_id : int

# Called when the node enters the scene tree for the first time.
func _ready():
	## Check to avoid crash
	for child in self.get_children():
		if child is AnimationPlayer and animation_player == null:
			animation_player = child
	if animation_player == null:
		#print_debug("Create an animation player node for this car: " + str(name))
		pass

func is_unobstructed():
	if collision_area.get_overlapping_areas().is_empty():
		for ray : RayCast3D in edge_rays.get_children():
			if ray.is_colliding() && ray.get_collider().visible == false || not ray.is_colliding():
				return false
		return true
	else:
		return false

### The idea is these decorative cars are bought previously before they can be 
### placed freely. Using the same methods from the furniture script, the decor
### cars can always be afforded.
func can_afford():
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

func play_gearshift_animation():
	animation_player.play("gear_shift")

func get_wheels():
	return wheel_positions

func get_mesh() -> MeshInstance3D:
	print_debug(mesh)
	return mesh

func set_internal_id(id : int):
	internal_id = id

func get_internal_id() -> int:
	return internal_id

func set_wheels(wheel_name : String):
	var wheel_model = load("res://cars/wheels/"+wheel_name+"/"+wheel_name+".glb").instantiate()
	for wheel_position in wheel_positions.get_children():
		if wheel_position.get_child_count() > 0:
			wheel_position.get_child(0).queue_free()
		wheel_position.add_child(wheel_model.duplicate())

func set_color(color : Color):
	var material : StandardMaterial3D = mesh.get_active_material(0)
	material.albedo_color = color
