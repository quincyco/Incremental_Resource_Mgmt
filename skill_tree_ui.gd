extends CanvasLayer

var game_manager: Node
var skill_buttons: Dictionary = {}
var is_visible: bool = false

@onready var panel: PanelContainer
@onready var skill_container: VBoxContainer
@onready var close_button: Button
@onready var points_label: Label

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	_setup_ui()
	hide_skill_tree()

func _setup_ui() -> void:
	# Main panel
	panel = PanelContainer.new()
	panel.name = "SkillTreePanel"
	panel.position = Vector2(100, 50)
	panel.size = Vector2(600, 500)
	add_child(panel)

	var main_container = VBoxContainer.new()
	panel.add_child(main_container)

	# Header
	var header = HBoxContainer.new()
	main_container.add_child(header)

	var title = Label.new()
	title.text = "Skill Tree"
	title.add_theme_font_size_override("font_size", 32)
	header.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size.x = 200
	header.add_child(spacer)

	points_label = Label.new()
	points_label.add_theme_font_size_override("font_size", 24)
	points_label.modulate = Color(1.0, 0.8, 0.2)
	header.add_child(points_label)

	close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(80, 30)
	close_button.pressed.connect(hide_skill_tree)
	header.add_child(close_button)

	# Scroll container for skills
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 400)
	main_container.add_child(scroll)

	skill_container = VBoxContainer.new()
	scroll.add_child(skill_container)

	# Create skill buttons organized by tier
	_create_skill_buttons()

func _create_skill_buttons() -> void:
	# Tier 1
	var tier1_label = Label.new()
	tier1_label.text = "Tier 1 - Starting Skills"
	tier1_label.add_theme_font_size_override("font_size", 24)
	tier1_label.modulate = Color(0.7, 0.9, 1.0)
	skill_container.add_child(tier1_label)

	_create_skill_button("quick_start")
	_create_skill_button("extended_reach")
	_create_skill_button("sturdy_particles")

	# Tier 2
	var tier2_label = Label.new()
	tier2_label.text = "\nTier 2 - Requires 3 Skills"
	tier2_label.add_theme_font_size_override("font_size", 24)
	tier2_label.modulate = Color(0.7, 1.0, 0.7)
	skill_container.add_child(tier2_label)

	_create_skill_button("auto_efficiency")
	_create_skill_button("bulk_discount")
	_create_skill_button("particle_magnetism")

	# Tier 3
	var tier3_label = Label.new()
	tier3_label.text = "\nTier 3 - Requires 6 Skills"
	tier3_label.add_theme_font_size_override("font_size", 24)
	tier3_label.modulate = Color(1.0, 0.8, 0.5)
	skill_container.add_child(tier3_label)

	_create_skill_button("critical_mastery")
	_create_skill_button("combo_power")
	_create_skill_button("collection_burst")

	# Tier 4
	var tier4_label = Label.new()
	tier4_label.text = "\nTier 4 - Requires 10 Skills"
	tier4_label.add_theme_font_size_override("font_size", 24)
	tier4_label.modulate = Color(1.0, 0.5, 0.5)
	skill_container.add_child(tier4_label)

	_create_skill_button("compression_resistance")
	_create_skill_button("value_surge")
	_create_skill_button("cascade_effect")

func _create_skill_button(skill_id: String) -> void:
	var skill = game_manager.skill_definitions[skill_id]

	var container = HBoxContainer.new()
	container.custom_minimum_size.y = 60

	# Skill info
	var info_container = VBoxContainer.new()
	info_container.custom_minimum_size.x = 400

	var name_label = Label.new()
	name_label.text = skill.name
	name_label.add_theme_font_size_override("font_size", 18)
	info_container.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = skill.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_container.add_child(desc_label)

	container.add_child(info_container)

	# Purchase button
	var button = Button.new()
	button.custom_minimum_size = Vector2(150, 50)
	button.pressed.connect(_on_skill_button_pressed.bind(skill_id, button))
	container.add_child(button)

	skill_buttons[skill_id] = button
	skill_container.add_child(container)

	_update_skill_button(skill_id, button)

func _update_skill_button(skill_id: String, button: Button) -> void:
	var skill = game_manager.skill_definitions[skill_id]
	var is_active = game_manager.active_skills[skill_id]

	if is_active:
		button.text = "ACTIVE"
		button.disabled = true
		button.modulate = Color(0.5, 1.0, 0.5)
	elif game_manager.can_afford_skill(skill_id):
		button.text = "Purchase (" + str(skill.cost) + " UP)"
		button.disabled = false
		button.modulate = Color(1.0, 1.0, 1.0)
	else:
		# Check why it's locked
		if skill.has("requires_points"):
			var total_skills = 0
			for s in game_manager.active_skills.values():
				if s:
					total_skills += 1
			if total_skills < skill["requires_points"]:
				button.text = "LOCKED (Need " + str(skill["requires_points"] - total_skills) + " more)"
			else:
				button.text = "Cost: " + str(skill.cost) + " UP"
		else:
			button.text = "Cost: " + str(skill.cost) + " UP"

		button.disabled = true
		button.modulate = Color(0.6, 0.6, 0.6)

func _on_skill_button_pressed(skill_id: String, button: Button) -> void:
	if game_manager.purchase_skill(skill_id):
		_update_all_buttons()
		print("Skill purchased: ", skill_id)

func _update_all_buttons() -> void:
	for skill_id in skill_buttons.keys():
		_update_skill_button(skill_id, skill_buttons[skill_id])

	if is_instance_valid(points_label):
		points_label.text = "UP: " + str(game_manager.upgrade_points)

func show_skill_tree() -> void:
	is_visible = true
	panel.visible = true
	_update_all_buttons()

func hide_skill_tree() -> void:
	is_visible = false
	panel.visible = false

func toggle_skill_tree() -> void:
	if is_visible:
		hide_skill_tree()
	else:
		show_skill_tree()
