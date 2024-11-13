extends Node3D

@onready var camera_pivot : Node3D = $"."

var rotation_amount : float = 1.25
@export var movement_speed : float = 25
var movement_z : int = 0 # Front to Back
var movement_x : int = 0 # Left to Right


func _process(delta):
	## Camera rotation
	if Input.is_action_pressed("CameraRotateLeft"):
		camera_pivot.rotate_y(deg_to_rad(rotation_amount))
	if Input.is_action_pressed("CameraRotateRight"):
		camera_pivot.rotate_y(deg_to_rad(-rotation_amount))
	
	## Camera movement
	var input_direction : Vector2 = Input.get_vector("CameraMoveLeft", "CameraMoveRight", "CameraMoveForward", "CameraMoveBackward")
	var direction : Vector3 = Vector3(input_direction.x, 0, input_direction.y).normalized()
	
	if direction != Vector3.ZERO:
		self.global_transform.origin += self.global_transform.basis * direction * movement_speed * delta
