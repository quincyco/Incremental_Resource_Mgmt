extends Node2D

signal particle_collected(value: int)

@onready var sprite = $Sprite2D
@onready var collection_area = $Area2D
@onready var collection_shape = $Area2D/CollisionShape2D

var game_manager: Node

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	collection_area.body_entered.connect(_on_body_entered)
	
	# Setup placeholder sprite
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
		_create_placeholder_texture()
	
	# Update collection radius based on upgrades
	if game_manager:
		game_manager.upgrade_applied.connect(_on_upgrade_applied)
		_update_collection_radius()

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

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("start_moving_to_collector"):
		body.start_moving_to_collector()

func _on_upgrade_applied(upgrade_id: String) -> void:
	if upgrade_id == "collection_radius":
		_update_collection_radius()

func _update_collection_radius() -> void:
	if collection_shape and collection_shape.shape is CircleShape2D:
		collection_shape.shape.radius = game_manager.collection_radius

func get_collection_position() -> Vector2:
	return global_position
