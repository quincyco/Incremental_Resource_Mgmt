extends Node2D

signal particle_collected(value: int)

@onready var sprite = $Sprite2D

var game_manager: Node

func _ready():
	game_manager = get_node("/root/Main/GameManager")

	# Setup placeholder sprite if no texture
	if not sprite.texture:
		_create_placeholder_texture()

	print("ParticleCollector ready at: ", global_position)

func _create_placeholder_texture() -> void:
	# Create a bucket/basket shape
	var img = Image.create(160, 120, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Draw bucket shape
	for x in range(160):
		for y in range(120):
			var rel_x = x - 80
			var rel_y = y - 10

			# Bucket sides and bottom
			if abs(rel_x) > 50 and abs(rel_x) < 70 and rel_y > 0 and rel_y < 100:
				img.set_pixel(x, y, Color(0.6, 0.4, 0.2, 1.0))
			elif abs(rel_x) <= 50 and rel_y > 90 and rel_y < 100:
				img.set_pixel(x, y, Color(0.6, 0.4, 0.2, 1.0))
			# Inner shadow
			elif abs(rel_x) < 50 and rel_y > 20 and rel_y < 90:
				img.set_pixel(x, y, Color(0.3, 0.2, 0.1, 0.3))

	sprite.texture = ImageTexture.create_from_image(img)
	sprite.offset.y = -60  # Center the bucket

func get_collection_position() -> Vector2:
	return global_position
