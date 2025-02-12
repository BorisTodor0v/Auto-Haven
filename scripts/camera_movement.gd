extends Node3D

@onready var camera_pivot : Node3D = $"."

var rotation_amount : float = 1.25
@export var movement_speed : float = 25
@export var rotation_enabled : bool
@export var movement_enabled : bool

@export_group("Movement Limits", "limit")
@export var limit_x_pos : float = 120
@export var limit_x_neg : float = -136
@export var limit_z_pos : float = 120
@export var limit_z_neg : float = -136

func _process(delta):
	## Camera rotation
	if Input.is_action_pressed("CameraRotateLeft"):
		if rotation_enabled:
			camera_pivot.rotate_y(deg_to_rad(rotation_amount))
	if Input.is_action_pressed("CameraRotateRight"):
		if rotation_enabled:
			camera_pivot.rotate_y(deg_to_rad(-rotation_amount))
	
	## Camera movement
	var input_direction : Vector2 = Input.get_vector("CameraMoveLeft", "CameraMoveRight", "CameraMoveForward", "CameraMoveBackward")
	var direction : Vector3 = Vector3(input_direction.x, 0, input_direction.y).normalized()
	if direction != Vector3.ZERO:
		if movement_enabled:
			var new_position = self.global_transform.origin + (self.global_transform.basis * direction * movement_speed * delta)

			if (limit_x_neg <= new_position.x and new_position.x <= limit_x_pos) and \
			(limit_z_neg <= new_position.z and new_position.z <= limit_z_pos):
				self.global_transform.origin = new_position
