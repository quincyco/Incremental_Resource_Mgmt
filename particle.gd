extends RigidBody2D

signal particle_clicked(particle: RigidBody2D)

@onready var sprite = $Sprite2D
@onready var click_area = $Area2D
@onready var lifetime_timer = $LifetimeTimer

var is_collected: bool = false
var value: int = 1
var game_manager: Node
var target_position: Vector2 = Vector2.ZERO
var is_moving_to_collector: bool = false
var move_speed: float = 400.0

func _ready():
	add_to_group("particles")  # CRITICAL FIX: Add to group in code
	
	game_manager = get_node("/root/Main/GameManager")
	value = game_manager.particle_value
	
	click_area.input_event.connect(_on_click_area_input_event)
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start(10.0)  # Particles disappear after 10 seconds
	
	# Setup placeholder sprite if no texture
	if not sprite.texture:
		_create_placeholder_texture()
	
	# Physics properties
	gravity_scale = 0.5
	linear_damp = 2.0
	
	print("Particle created at: ", global_position)

func _create_placeholder_texture() -> void:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	for x in range(16):
		for y in range(16):
			var dist = Vector2(x - 8, y - 8).length()
			if dist < 6:
				# Glowing particle effect
				var brightness = 1.0 - (dist / 6.0) * 0.3
				img.set_pixel(x, y, Color(0.3 + brightness * 0.7, 0.5 + brightness * 0.5, 1.0, 1.0))
	
	sprite.texture = ImageTexture.create_from_image(img)

func _physics_process(delta):
	if is_moving_to_collector and target_position != Vector2.ZERO:
		var direction = (target_position - global_position).normalized()
		linear_velocity = direction * move_speed
		move_speed += 600.0 * delta  # Accelerate towards collector
		
		if global_position.distance_to(target_position) < 20:
			collect()

func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_collected:
			print("Particle clicked!")  # Debug
			start_moving_to_collector()

func start_moving_to_collector() -> void:
	if is_collected:
		return
	
	is_collected = true
	is_moving_to_collector = true
	
	# Find collector
	var collector = get_node_or_null("/root/Main/ParticleCollector")
	if collector:
		target_position = collector.global_position
		print("Particle moving to collector at: ", target_position)  # Debug
	else:
		print("ERROR: Could not find ParticleCollector!")
	
	# Disable physics collision while moving
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	gravity_scale = 0
	linear_damp = 0
	
	particle_clicked.emit(self)

func apply_initial_impulse(impulse: Vector2) -> void:
	apply_central_impulse(impulse)

func collect() -> void:
	print("Particle collected! Value: ", value)  # Debug
	game_manager.add_energy(value)
	
	# Particle collection effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free).set_delay(0.2)

func _on_lifetime_timeout() -> void:
	if not is_collected:
		print("Particle lifetime expired")  # Debug
		# Fade out and disappear
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
		tween.tween_callback(queue_free)
