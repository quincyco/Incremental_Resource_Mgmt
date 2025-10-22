extends Node2D

signal rock_clicked(click_position: Vector2)

@export var particle_scene: PackedScene
@onready var sprite = $Sprite2D
@onready var click_area = $Area2D
@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null

var game_manager: Node

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	click_area.input_event.connect(_on_click_area_input_event)
	
	# Setup placeholder sprite
	if not sprite.texture:
		_create_placeholder_texture()

func _create_placeholder_texture() -> void:
	# Create a simple rock-like circle
	var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	for x in range(128):
		for y in range(128):
			var dist = Vector2(x - 64, y - 64).length()
			if dist < 50:
				var gray = 0.4 + randf() * 0.2
				img.set_pixel(x, y, Color(gray, gray, gray * 0.9, 1.0))
	
	sprite.texture = ImageTexture.create_from_image(img)

func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_rock_clicked()

func _on_rock_clicked() -> void:
	print("Rock clicked!")  # Debug
	
	# Play hit animation (if available)
	if animation_player and animation_player.has_animation("hit"):
		animation_player.play("hit")
	else:
		_play_simple_bounce()
	
	# Spawn particles
	spawn_particles()
	rock_clicked.emit(global_position)

func _play_simple_bounce() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)

func spawn_particles() -> void:
	if not particle_scene:
		# CRITICAL FIX: lowercase 'p' in particle.tscn
		particle_scene = load("res://particle.tscn")
	
	if not particle_scene:
		print("ERROR: Could not load particle scene!")
		return
	
	var num_particles = game_manager.particles_per_click
	print("Spawning ", num_particles, " particles")  # Debug
	
	for i in range(num_particles):
		var particle = particle_scene.instantiate()
		get_parent().add_child(particle)
		
		# Random spawn position around rock
		var angle = randf() * TAU
		var distance = randf_range(20, 50)
		var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * distance
		particle.global_position = spawn_pos
		
		# Random initial velocity
		var impulse_angle = randf() * TAU
		var impulse_strength = randf_range(100, 300)
		particle.apply_initial_impulse(Vector2(cos(impulse_angle), sin(impulse_angle)) * impulse_strength)
