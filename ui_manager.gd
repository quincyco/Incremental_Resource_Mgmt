extends CanvasLayer

signal upgrade_purchased(upgrade_id: String)

@onready var energy_label = $HUD/EnergyLabel
@onready var upgrades_panel = $UpgradesPanel
@onready var upgrade_buttons_container = $UpgradesPanel/ScrollContainer/UpgradeButtons

var game_manager: Node
var upgrade_button_scene: PackedScene

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	
	_setup_ui()
	_create_upgrade_buttons()
	
	if game_manager:
		game_manager.upgrade_applied.connect(_on_upgrade_applied)

func _setup_ui() -> void:
	# Create HUD container if needed
	if not has_node("HUD"):
		var hud = Control.new()
		hud.name = "HUD"
		hud.anchors_preset = Control.PRESET_FULL_RECT
		add_child(hud)
		
		# Energy label
		energy_label = Label.new()
		energy_label.name = "EnergyLabel"
		energy_label.position = Vector2(20, 20)
		energy_label.add_theme_font_size_override("font_size", 32)
		hud.add_child(energy_label)
	
	# Create upgrades panel if needed
	if not has_node("UpgradesPanel"):
		upgrades_panel = PanelContainer.new()
		upgrades_panel.name = "UpgradesPanel"
		upgrades_panel.position = Vector2(20, 100)
		upgrades_panel.size = Vector2(300, 500)
		add_child(upgrades_panel)
		
		var scroll = ScrollContainer.new()
		scroll.name = "ScrollContainer"
		scroll.custom_minimum_size = Vector2(280, 480)
		upgrades_panel.add_child(scroll)
		
		upgrade_buttons_container = VBoxContainer.new()
		upgrade_buttons_container.name = "UpgradeButtons"
		scroll.add_child(upgrade_buttons_container)

func _create_upgrade_buttons() -> void:
	var upgrade_definitions = {
		"more_particles": {"title": "More Particles", "description": "Spawn +2 particles per click"},
		"particle_value": {"title": "Particle Value", "description": "+1 energy per particle"},
		"collection_radius": {"title": "Collection Radius", "description": "+25 units to collection area"},
		"auto_collector": {"title": "Auto Collector", "description": "Adds 1 automatic collector"}
	}
	
	for upgrade_id in upgrade_definitions.keys():
		var button_data = upgrade_definitions[upgrade_id]
		var upgrade_button = _create_upgrade_button(upgrade_id, button_data.title, button_data.description)
		upgrade_buttons_container.add_child(upgrade_button)

func _create_upgrade_button(upgrade_id: String, title: String, description: String) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size.y = 80
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	container.add_child(title_label)
	
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	container.add_child(desc_label)
	
	var button = Button.new()
	button.text = "Cost: " + str(game_manager.get_upgrade_cost(upgrade_id))
	button.custom_minimum_size.y = 30
	button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade_id, button))
	container.add_child(button)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	container.add_child(spacer)
	
	return container

func _on_upgrade_button_pressed(upgrade_id: String, button: Button) -> void:
	if game_manager.apply_upgrade(upgrade_id):
		upgrade_purchased.emit(upgrade_id)
		_update_upgrade_button(upgrade_id, button)

func _on_upgrade_applied(upgrade_id: String) -> void:
	_update_all_buttons()

func _update_upgrade_button(upgrade_id: String, button: Button) -> void:
	var cost = game_manager.get_upgrade_cost(upgrade_id)
	var level = game_manager.get_upgrade_level(upgrade_id)
	button.text = "Cost: " + str(cost) + " (Lv." + str(level) + ")"
	button.disabled = not game_manager.can_afford_upgrade(upgrade_id)

func _update_all_buttons() -> void:
	for container in upgrade_buttons_container.get_children():
		if container.get_child_count() >= 3:
			var button = container.get_child(2)
			if button is Button:
				var upgrade_id = _get_upgrade_id_from_button(button)
				if upgrade_id:
					_update_upgrade_button(upgrade_id, button)

func _get_upgrade_id_from_button(button: Button) -> String:
	var index = button.get_parent().get_index()
	var upgrade_ids = ["more_particles", "particle_value", "collection_radius", "auto_collector"]
	if index < upgrade_ids.size():
		return upgrade_ids[index]
	return ""

func update_energy_display(new_energy: int) -> void:
	energy_label.text = "Energy: " + str(new_energy)
	_update_all_buttons()

func _process(_delta):
	# Update button states every frame (could be optimized)
	pass
