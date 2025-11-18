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

# Visual properties
var particle_color: Color

func _ready():
	add_to_group("particles")

	game_manager = get_node("/root/Main/GameManager")
	value = game_manager.particle_value

	click_area.input_event.connect(_on_click_area_input_event)
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start(game_manager.particle_lifetime)

	# Setup placeholder sprite
	if not sprite.texture:
		_create_placeholder_texture()

	# Physics properties
	gravity_scale = 0.5
	linear_damp = 2.0

	print("Particle created at: ", global_position)

func _create_placeholder_texture() -> void:
	# Simple pixel particle - randomly colored
	var colors = [
		Color(0, 1, 1, 1),      # Cyan
		Color(1, 0, 1, 1),      # Magenta
		Color(1, 1, 0, 1),      # Yellow
		Color(1, 1, 1, 1),      # White
		Color(0.5, 0.5, 1, 1),  # Light blue
		Color(1, 0.5, 0.5, 1)   # Light red
	]
	particle_color = colors[randi() % colors.size()]

	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Simple glowing pixel
	for x in range(8):
		for y in range(8):
			var dist = Vector2(x - 4, y - 4).length()
			if dist < 3:
				var brightness = 1.0 - (dist / 3.0) * 0.3
				img.set_pixel(x, y, particle_color * brightness)

	sprite.texture = ImageTexture.create_from_image(img)

func _physics_process(delta):
	if is_collected or is_moving_to_collector:
		return

	# Apply particle magnetism if active
	if game_manager.particle_magnet_strength > 0:
		var collector = get_node_or_null("/root/Main/ParticleCollector")
		if collector:
			var direction = (collector.global_position - global_position).normalized()
			apply_central_force(direction * game_manager.particle_magnet_strength)

func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_collected:
			print("Particle clicked!")
			# Collect this particle and nearby particles within click radius
			collect_nearby_particles()

func collect_nearby_particles() -> void:
	var particles = get_tree().get_nodes_in_group("particles")
	var collected_count = 0

	for p in particles:
		if p is RigidBody2D and not p.is_collected:
			var distance = global_position.distance_to(p.global_position)
			if distance <= game_manager.click_radius:
				p.start_moving_to_collector()
				collected_count += 1

	print("Collected ", collected_count, " particles in click radius ", game_manager.click_radius)

func start_moving_to_collector() -> void:
	if is_collected or is_moving_to_collector:
		return

	is_collected = true
	is_moving_to_collector = true

	# Find collector
	var collector = get_node_or_null("/root/Main/ParticleCollector")
	if collector:
		target_position = collector.global_position
		print("Particle moving to collector at: ", target_position)

		# Remove from pile before collecting
		game_manager.remove_from_pile(1)

		# Disable physics and make particle fly to collector
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		gravity_scale = 0
		linear_damp = 0
		linear_velocity = Vector2.ZERO

		# Animate to collector
		_animate_to_collector()
	else:
		print("ERROR: Could not find ParticleCollector!")

func _animate_to_collector() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_position, 0.3)
	tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.3)
	tween.chain().tween_callback(collect)

func apply_initial_impulse(impulse: Vector2) -> void:
	apply_central_impulse(impulse)

func collect() -> void:
	if not is_instance_valid(self):
		return

	print("Particle collected! Value: ", value)
	game_manager.add_energy(value)

	# Particle collection effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.1)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free).set_delay(0.1)

func _on_lifetime_timeout() -> void:
	if not is_collected and not is_moving_to_collector:
		print("Particle lifetime expired - compression!")
		# Particle timeout doesn't remove from pile, it stays and contributes to compression

		# Fade out and disappear (particle absorbed back into wizard)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
