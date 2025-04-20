extends Node
@onready var rotate_camera_pivot: Node3D = $RotateCameraPivot
@onready var rotate_camera: Camera3D = $RotateCameraPivot/RotateCamera
@onready var main_camera: Camera3D = $MainCamera


var current_camera: Camera3D

func _ready() -> void:
	current_camera = get_viewport().get_camera_3d()
	camera_loop()
	
func _process(delta: float) -> void:
	rotate_camera_pivot.rotate_y(delta * deg_to_rad(30.0))
	
func camera_loop() -> void:
	while true:
		await get_tree().create_timer(10.0).timeout
		switch_camera()

func switch_camera() -> void:
	if current_camera == main_camera:
		current_camera = rotate_camera	
	else:
		current_camera = main_camera
	current_camera.current = true
	
