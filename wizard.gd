extends Node2D

signal rock_clicked(click_position: Vector2)

@export var particle_scene: PackedScene
@onready var sprite = $Sprite2D
@onready var click_area = $Area2D
@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null

var game_manager: Node
var camera: Camera2D

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	camera = get_node("/root/Main/CameraController")

	click_area.input_event.connect(_on_click_area_input_event)
	game_manager.damage_dealt.connect(_on_damage_dealt)

	# Setup placeholder sprite
	if not sprite.texture:
		_create_placeholder_texture()

func _create_placeholder_texture() -> void:
	# Create a wizard-like sprite (purple robe)
	var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for x in range(128):
		for y in range(128):
			var dist = Vector2(x - 64, y - 64).length()
			if dist < 50:
				# Purple wizard
				var brightness = 0.6 + randf() * 0.2
				img.set_pixel(x, y, Color(brightness * 0.6, brightness * 0.3, brightness * 1.0, 1.0))

	sprite.texture = ImageTexture.create_from_image(img)

func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_rock_clicked()

func _on_rock_clicked() -> void:
	print("Wizard clicked! Dealing damage...")

	# Play hit animation
	if animation_player and animation_player.has_animation("hit"):
		animation_player.play("hit")
	else:
		_play_simple_bounce()

	# Apply screen shake
	if camera and camera.has_method("apply_shake"):
		var shake_intensity = min(game_manager.click_damage * 0.5, 10.0)
		camera.apply_shake(shake_intensity, 0.2)

	# Deal damage through game manager
	game_manager.deal_damage(game_manager.click_damage, true)

	rock_clicked.emit(global_position)

func _play_simple_bounce() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)

func _on_damage_dealt(damage: int) -> void:
	# Spawn particles based on damage dealt
	spawn_particles(damage)

func spawn_particles(damage: int) -> void:
	if not particle_scene:
		particle_scene = load("res://particle.tscn")

	if not particle_scene:
		print("ERROR: Could not load particle scene!")
		return

	# Calculate number of particles to spawn based on damage
	var is_critical = randf() < game_manager.critical_chance
	var num_particles = game_manager.calculate_particles_to_spawn(damage, is_critical)

	print("Spawning ", num_particles, " particles from ", damage, " damage")

	for i in range(num_particles):
		var particle = particle_scene.instantiate()
		get_parent().add_child(particle)

		# Particles spawn from wizard and burst outward
		var angle = randf() * TAU
		var distance = randf_range(10, 30)
		var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * distance
		particle.global_position = spawn_pos

		# Burst particles outward with random velocity (they'll fall to center pile)
		var impulse_angle = randf() * TAU
		var impulse_strength = randf_range(150, 400)
		particle.apply_initial_impulse(Vector2(cos(impulse_angle), sin(impulse_angle)) * impulse_strength)

		# Add to pile tracking
		game_manager.add_to_pile(1)
