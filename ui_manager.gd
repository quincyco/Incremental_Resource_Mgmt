extends CanvasLayer

signal upgrade_purchased(upgrade_id: String)
signal prestige_requested()

@onready var hud_container: Control
@onready var energy_label: Label
@onready var upgrade_points_label: Label
@onready var dps_label: Label
@onready var combo_label: Label
@onready var compression_meter: ProgressBar
@onready var compression_label: Label
@onready var upgrades_panel: PanelContainer
@onready var upgrade_buttons_container: VBoxContainer
@onready var prestige_button: Button
@onready var skill_tree_button: Button

var game_manager: Node
var upgrade_buttons: Dictionary = {}
var current_category: String = "damage"
var skill_tree_ui: CanvasLayer

func _ready():
	game_manager = get_node("/root/Main/GameManager")

	# Create skill tree UI
	var SkillTreeUIScript = load("res://skill_tree_ui.gd")
	skill_tree_ui = CanvasLayer.new()
	skill_tree_ui.set_script(SkillTreeUIScript)
	get_parent().add_child(skill_tree_ui)

	_setup_ui()
	_create_upgrade_buttons()

	if game_manager:
		game_manager.energy_changed.connect(update_energy_display)
		game_manager.upgrade_applied.connect(_on_upgrade_applied)
		game_manager.upgrade_points_changed.connect(update_upgrade_points_display)
		game_manager.pile_height_changed.connect(update_compression_meter)
		game_manager.compression_occurred.connect(_on_compression_occurred)
		game_manager.game_won.connect(_on_game_won)

func _setup_ui() -> void:
	# Create HUD container
	hud_container = Control.new()
	hud_container.name = "HUD"
	hud_container.anchors_preset = Control.PRESET_FULL_RECT
	add_child(hud_container)

	# Energy label (top-left)
	energy_label = Label.new()
	energy_label.name = "EnergyLabel"
	energy_label.position = Vector2(20, 20)
	energy_label.add_theme_font_size_override("font_size", 32)
	hud_container.add_child(energy_label)

	# Upgrade Points label
	upgrade_points_label = Label.new()
	upgrade_points_label.name = "UpgradePointsLabel"
	upgrade_points_label.position = Vector2(20, 60)
	upgrade_points_label.add_theme_font_size_override("font_size", 24)
	upgrade_points_label.modulate = Color(1.0, 0.8, 0.2)
	hud_container.add_child(upgrade_points_label)

	# DPS label
	dps_label = Label.new()
	dps_label.name = "DPSLabel"
	dps_label.position = Vector2(20, 90)
	dps_label.add_theme_font_size_override("font_size", 18)
	dps_label.modulate = Color(0.8, 0.8, 0.8)
	hud_container.add_child(dps_label)

	# Combo label
	combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.position = Vector2(20, 115)
	combo_label.add_theme_font_size_override("font_size", 20)
	combo_label.modulate = Color(1.0, 0.5, 0.5)
	hud_container.add_child(combo_label)

	# Compression meter (bottom of screen)
	var compression_container = VBoxContainer.new()
	compression_container.name = "CompressionContainer"
	compression_container.position = Vector2(20, 550)
	compression_container.size = Vector2(760, 60)
	hud_container.add_child(compression_container)

	compression_label = Label.new()
	compression_label.name = "CompressionLabel"
	compression_label.add_theme_font_size_override("font_size", 16)
	compression_label.text = "Compressions: 0/5"
	compression_container.add_child(compression_label)

	compression_meter = ProgressBar.new()
	compression_meter.name = "CompressionMeter"
	compression_meter.custom_minimum_size = Vector2(760, 30)
	compression_meter.show_percentage = false
	compression_meter.value = 0
	compression_meter.max_value = 100
	compression_container.add_child(compression_meter)

	# Prestige button (top-right)
	prestige_button = Button.new()
	prestige_button.name = "PrestigeButton"
	prestige_button.text = "Prestige (0 UP)"
	prestige_button.position = Vector2(620, 20)
	prestige_button.size = Vector2(160, 40)
	prestige_button.pressed.connect(_on_prestige_pressed)
	prestige_button.visible = false
	hud_container.add_child(prestige_button)

	# Skill Tree button
	skill_tree_button = Button.new()
	skill_tree_button.name = "SkillTreeButton"
	skill_tree_button.text = "Skill Tree"
	skill_tree_button.position = Vector2(620, 70)
	skill_tree_button.size = Vector2(160, 40)
	skill_tree_button.pressed.connect(_on_skill_tree_pressed)
	skill_tree_button.visible = false
	hud_container.add_child(skill_tree_button)

	# Create upgrades panel (left side)
	upgrades_panel = PanelContainer.new()
	upgrades_panel.name = "UpgradesPanel"
	upgrades_panel.position = Vector2(20, 160)
	upgrades_panel.size = Vector2(320, 380)
	add_child(upgrades_panel)

	# Category tabs
	var tab_container = VBoxContainer.new()
	tab_container.name = "TabContainer"
	upgrades_panel.add_child(tab_container)

	var tabs = HBoxContainer.new()
	tabs.name = "Tabs"
	tab_container.add_child(tabs)

	var damage_tab = Button.new()
	damage_tab.text = "Damage"
	damage_tab.custom_minimum_size.x = 100
	damage_tab.pressed.connect(_on_category_changed.bind("damage"))
	tabs.add_child(damage_tab)

	var collection_tab = Button.new()
	collection_tab.text = "Collection"
	collection_tab.custom_minimum_size.x = 100
	collection_tab.pressed.connect(_on_category_changed.bind("collection"))
	tabs.add_child(collection_tab)

	var special_tab = Button.new()
	special_tab.text = "Special"
	special_tab.custom_minimum_size.x = 100
	special_tab.pressed.connect(_on_category_changed.bind("special"))
	tabs.add_child(special_tab)

	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.custom_minimum_size = Vector2(300, 320)
	tab_container.add_child(scroll)

	upgrade_buttons_container = VBoxContainer.new()
	upgrade_buttons_container.name = "UpgradeButtons"
	scroll.add_child(upgrade_buttons_container)

func _create_upgrade_buttons() -> void:
	var upgrade_definitions = {
		# Damage upgrades
		"click_damage": {
			"title": "Click Damage",
			"description": "Increase damage per click",
			"category": "damage"
		},
		"particles_per_hit": {
			"title": "Particles per Hit",
			"description": "+2 particles spawn per damage",
			"category": "damage"
		},
		"critical_chance": {
			"title": "Critical Chance",
			"description": "+5% chance for 2x damage",
			"category": "damage"
		},
		"auto_damage": {
			"title": "Auto-Damage",
			"description": "Automatically damage wizard",
			"category": "damage"
		},
		"auto_damage_speed": {
			"title": "Auto-Damage Speed",
			"description": "Reduce auto-damage interval",
			"category": "damage"
		},
		"auto_damage_power": {
			"title": "Auto-Damage Power",
			"description": "Increase auto-damage amount",
			"category": "damage"
		},

		# Collection upgrades
		"particle_value": {
			"title": "Particle Value",
			"description": "+1 energy per particle",
			"category": "collection"
		},
		"click_radius": {
			"title": "Click Radius",
			"description": "+10 units to collection area",
			"category": "collection"
		},
		"particle_lifetime": {
			"title": "Particle Lifetime",
			"description": "+2 seconds before fade",
			"category": "collection"
		},
		"auto_collection": {
			"title": "Auto-Collection",
			"description": "Automatically collect particles",
			"category": "collection"
		},
		"auto_collection_speed": {
			"title": "Auto-Collection Speed",
			"description": "Reduce auto-collection interval",
			"category": "collection"
		},
		"auto_collection_radius": {
			"title": "Auto-Collection Radius",
			"description": "+10 units to auto-collection area",
			"category": "collection"
		},
		"particle_magnet": {
			"title": "Particle Magnet",
			"description": "Particles drift toward collector",
			"category": "collection"
		},

		# Special upgrades
		"compression_resistance": {
			"title": "Compression Resistance",
			"description": "+25% pile threshold",
			"category": "special"
		},
		"sun_thrower": {
			"title": "Sun Thrower",
			"description": "Create a sun to destroy the wizard!",
			"category": "special"
		}
	}

	for upgrade_id in upgrade_definitions.keys():
		var def = upgrade_definitions[upgrade_id]
		var button_container = _create_upgrade_button(upgrade_id, def.title, def.description, def.category)
		upgrade_buttons[upgrade_id] = button_container
		upgrade_buttons_container.add_child(button_container)
		# Initially hide buttons not in current category
		button_container.visible = (def.category == current_category)

func _create_upgrade_button(upgrade_id: String, title: String, description: String, category: String) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size.y = 80
	container.set_meta("category", category)
	container.set_meta("upgrade_id", upgrade_id)

	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	container.add_child(title_label)

	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	container.add_child(desc_label)

	var button = Button.new()
	button.text = "Cost: " + str(game_manager.get_upgrade_cost(upgrade_id))
	button.custom_minimum_size.y = 25
	button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade_id, button))
	container.add_child(button)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 5
	container.add_child(spacer)

	return container

func _on_category_changed(category: String) -> void:
	current_category = category
	for upgrade_id in upgrade_buttons.keys():
		var container = upgrade_buttons[upgrade_id]
		container.visible = (container.get_meta("category") == category)

func _on_upgrade_button_pressed(upgrade_id: String, button: Button) -> void:
	if game_manager.apply_upgrade(upgrade_id):
		upgrade_purchased.emit(upgrade_id)

func _on_upgrade_applied(upgrade_id: String) -> void:
	_update_all_buttons()

func _update_upgrade_button(upgrade_id: String, button: Button) -> void:
	if not game_manager.upgrades.has(upgrade_id):
		return

	var upgrade = game_manager.upgrades[upgrade_id]

	# Check if upgrade is locked
	if upgrade.has("unlocked") and not upgrade["unlocked"]:
		button.text = "LOCKED"
		button.disabled = true
		return

	var cost = game_manager.get_upgrade_cost(upgrade_id)
	var level = upgrade.level
	button.text = "Cost: " + str(cost) + " (Lv." + str(level) + ")"
	button.disabled = not game_manager.can_afford_upgrade(upgrade_id)

func _update_all_buttons() -> void:
	for container in upgrade_buttons_container.get_children():
		if container.get_child_count() >= 3:
			var button = container.get_child(2)
			if button is Button:
				var upgrade_id = container.get_meta("upgrade_id")
				_update_upgrade_button(upgrade_id, button)

func update_energy_display(new_energy: int) -> void:
	energy_label.text = "Energy: " + str(new_energy)
	_update_all_buttons()

func update_upgrade_points_display(new_points: int) -> void:
	upgrade_points_label.text = "Upgrade Points: " + str(new_points)
	prestige_button.text = "Prestige (" + str(new_points) + " UP)"

	# Show prestige button after first compression
	if new_points > 0:
		prestige_button.visible = true
		skill_tree_button.visible = true

func update_compression_meter(current_height: float, max_height: float) -> void:
	compression_meter.value = (current_height / max_height) * 100.0
	compression_label.text = "Compressions: " + str(game_manager.compression_count) + "/5 | Pile: " + str(int(current_height)) + "/" + str(int(max_height))

	# Change color as it fills up
	if compression_meter.value > 80:
		compression_meter.modulate = Color(1.0, 0.3, 0.3)  # Red warning
	elif compression_meter.value > 50:
		compression_meter.modulate = Color(1.0, 0.8, 0.3)  # Yellow caution
	else:
		compression_meter.modulate = Color(0.3, 1.0, 0.3)  # Green safe

func _on_compression_occurred(count: int) -> void:
	compression_label.text = "Compressions: " + str(count) + "/5 | Pile: 0/" + str(int(game_manager.compression_threshold))
	compression_meter.value = 0

	# Flash effect on compression
	var tween = create_tween()
	tween.tween_property(compression_meter, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(compression_meter, "modulate", Color(1.0, 1.0, 1.0), 0.1)

	# Update upgrade buttons to show sun thrower if unlocked
	if count >= 5:
		_update_all_buttons()

func _on_prestige_pressed() -> void:
	# Show confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Prestige will reset all in-run upgrades and currency, but you'll keep your " + str(game_manager.upgrade_points) + " Upgrade Points for the skill tree. Continue?"
	dialog.ok_button_text = "Prestige"
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(_confirm_prestige.bind(dialog))
	add_child(dialog)
	dialog.popup_centered()

func _confirm_prestige(dialog: AcceptDialog) -> void:
	game_manager.perform_prestige()
	dialog.queue_free()

	# Clear all particles from scene
	var particles = get_tree().get_nodes_in_group("particles")
	for p in particles:
		p.queue_free()

	# Reset UI
	update_energy_display(game_manager.total_energy)
	update_upgrade_points_display(game_manager.upgrade_points)
	update_compression_meter(0, game_manager.compression_threshold)
	_update_all_buttons()

func _on_skill_tree_pressed() -> void:
	if skill_tree_ui and skill_tree_ui.has_method("show_skill_tree"):
		skill_tree_ui.show_skill_tree()

func _on_game_won() -> void:
	# Show victory screen
	var victory_panel = PanelContainer.new()
	victory_panel.name = "VictoryPanel"
	victory_panel.position = Vector2(200, 150)
	victory_panel.size = Vector2(400, 300)
	add_child(victory_panel)

	var victory_container = VBoxContainer.new()
	victory_container.alignment = BoxContainer.ALIGNMENT_CENTER
	victory_panel.add_child(victory_container)

	var title = Label.new()
	title.text = "VICTORY!"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_container.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "The wizard has been destroyed!"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_container.add_child(subtitle)

	var stats = Label.new()
	stats.text = "\nTotal Damage: " + str(game_manager.total_damage_dealt)
	stats.text += "\nCompressions: " + str(game_manager.compression_count)
	stats.text += "\nUpgrade Points: " + str(game_manager.upgrade_points)
	stats.add_theme_font_size_override("font_size", 18)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_container.add_child(stats)

	# Trigger sun thrower animation
	_play_sun_thrower_animation()

func _play_sun_thrower_animation() -> void:
	# TODO: Create actual sun thrower animation
	print("SUN THROWER ANIMATION! The wizard explodes in a spectacular fashion!")

func _process(_delta):
	# Update DPS display
	if is_instance_valid(game_manager):
		dps_label.text = "DPS: " + str(game_manager.current_dps)

		# Update combo display
		if game_manager.combo_count > 1:
			combo_label.text = "Combo: x" + str(game_manager.combo_count)
			combo_label.visible = true
		else:
			combo_label.visible = false
