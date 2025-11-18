extends Camera2D

@export var pan_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.3
@export var max_zoom: float = 2.0
@export var smooth_speed: float = 5.0

var target_zoom: float = 1.0
var is_panning: bool = false
var pan_start_position: Vector2
var camera_start_position: Vector2

# Screen shake
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var base_offset: Vector2 = Vector2.ZERO

func _ready():
	zoom = Vector2(1.0, 1.0)
	target_zoom = 1.0

func _unhandled_input(event):
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
			get_viewport().set_input_as_handled()
		
		# Pan with middle mouse button
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_start_position = event.position
				camera_start_position = position
			else:
				is_panning = false
			get_viewport().set_input_as_handled()
	
	# Pan camera while middle mouse is held
	if event is InputEventMouseMotion and is_panning:
		var mouse_delta = (event.position - pan_start_position) / zoom.x
		position = camera_start_position - mouse_delta
		get_viewport().set_input_as_handled()

func _process(delta):
	# Smooth zoom
	var current_zoom = zoom.x
	current_zoom = lerp(current_zoom, target_zoom, smooth_speed * delta)
	zoom = Vector2(current_zoom, current_zoom)

	# Screen shake
	if shake_timer > 0:
		shake_timer -= delta
		var shake_amount = shake_intensity * (shake_timer / shake_duration)
		offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
	else:
		offset = Vector2.ZERO

	# Keyboard panning
	var pan_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		pan_direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		pan_direction.x += 1
	if Input.is_action_pressed("ui_up"):
		pan_direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		pan_direction.y += 1

	if pan_direction != Vector2.ZERO:
		position += pan_direction.normalized() * pan_speed * delta / zoom.x

func focus_on_position(target_position: Vector2, duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, duration)

func reset_camera() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", Vector2.ZERO, 0.5)
	tween.tween_property(self, "zoom", Vector2.ONE, 0.5)
	target_zoom = 1.0

func apply_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
