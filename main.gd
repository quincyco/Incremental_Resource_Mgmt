extends Node2D

@onready var game_manager = $GameManager
@onready var camera_controller = $CameraController
@onready var ui_manager = $UIManager

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect signals between systems
	game_manager.energy_changed.connect(ui_manager.update_energy_display)
	ui_manager.upgrade_purchased.connect(game_manager.apply_upgrade)
	
	print("Wizard Beater initialized!")
