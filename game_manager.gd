extends Node

# Signals
signal energy_changed(new_energy: int)
signal particle_collected(value: int)
signal upgrade_applied(upgrade_id: String)
signal compression_occurred(compression_count: int)
signal pile_height_changed(current_height: float, max_height: float)
signal upgrade_points_changed(new_points: int)
signal damage_dealt(damage_amount: int)
signal prestige_performed()
signal game_won()

# Currency
var total_energy: int = 0
var upgrade_points: int = 0

# Damage system
var click_damage: int = 1
var critical_chance: float = 0.0
var critical_multiplier: float = 2.0
var auto_damage_amount: int = 0
var auto_damage_interval: float = 0.5
var auto_damage_timer: float = 0.0

# Particle system
var particles_per_hit: int = 5
var particle_value: int = 1
var particle_lifetime: float = 8.0
var click_radius: float = 30.0

# Collection system
var auto_collection_enabled: bool = false
var auto_collection_interval: float = 0.3
var auto_collection_radius: float = 30.0
var auto_collection_timer: float = 0.0
var particle_magnet_strength: float = 0.0

# Compression system
var pile_height: float = 0.0
var compression_threshold: float = 100.0
var compression_count: int = 0
var compression_resistance_bonus: float = 0.0

# Combo system
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_window: float = 0.5
var combo_damage_bonus: float = 0.0

# DPS tracking
var total_damage_dealt: int = 0
var damage_this_second: int = 0
var dps_timer: float = 0.0
var current_dps: int = 0

# Win condition
var sun_thrower_purchased: bool = false

# Skill tree (permanent upgrades from prestige)
var active_skills = {
	# Tier 1
	"quick_start": false,
	"extended_reach": false,
	"sturdy_particles": false,
	# Tier 2
	"auto_efficiency": false,
	"bulk_discount": false,
	"particle_magnetism": false,
	# Tier 3
	"critical_mastery": false,
	"combo_power": false,
	"collection_burst": false,
	# Tier 4
	"compression_resistance": false,
	"value_surge": false,
	"cascade_effect": false
}

var skill_definitions = {
	"quick_start": {"name": "Quick Start", "tier": 1, "cost": 1, "description": "Begin runs with 50 energy"},
	"extended_reach": {"name": "Extended Reach", "tier": 1, "cost": 1, "description": "+20% base click radius"},
	"sturdy_particles": {"name": "Sturdy Particles", "tier": 1, "cost": 1, "description": "+2 seconds base particle lifetime"},
	"auto_efficiency": {"name": "Auto-Efficiency", "tier": 2, "cost": 1, "description": "Auto-damage and auto-collection are 25% more effective", "requires_points": 3},
	"bulk_discount": {"name": "Bulk Discount", "tier": 2, "cost": 1, "description": "All upgrade costs reduced by 10%", "requires_points": 3},
	"particle_magnetism": {"name": "Particle Magnetism", "tier": 2, "cost": 1, "description": "Particles slowly drift toward collector", "requires_points": 3},
	"critical_mastery": {"name": "Critical Mastery", "tier": 3, "cost": 1, "description": "Critical hits spawn 3 bonus particles", "requires_points": 6},
	"combo_power": {"name": "Combo Power", "tier": 3, "cost": 1, "description": "Consecutive clicks within 0.5s deal +10% damage (stacks)", "requires_points": 6},
	"collection_burst": {"name": "Collection Burst", "tier": 3, "cost": 1, "description": "5% chance collected particles spawn a bonus particle", "requires_points": 6},
	"compression_resistance": {"name": "Compression Resistance", "tier": 4, "cost": 1, "description": "+25% pile threshold before compression", "requires_points": 10},
	"value_surge": {"name": "Value Surge", "tier": 4, "cost": 1, "description": "Particles collected during combos worth +50%", "requires_points": 10},
	"cascade_effect": {"name": "Cascade Effect", "tier": 4, "cost": 1, "description": "Critical hits have 20% chance to trigger another hit", "requires_points": 10}
}

# Upgrade definitions (in-run currency)
var upgrades = {
	# Damage upgrades
	"click_damage": {"cost": 10, "level": 0, "category": "damage"},
	"particles_per_hit": {"cost": 25, "level": 0, "category": "damage"},
	"critical_chance": {"cost": 50, "level": 0, "category": "damage"},
	"auto_damage": {"cost": 100, "level": 0, "category": "damage"},
	"auto_damage_speed": {"cost": 75, "level": 0, "category": "damage"},
	"auto_damage_power": {"cost": 50, "level": 0, "category": "damage"},

	# Collection upgrades
	"particle_value": {"cost": 20, "level": 0, "category": "collection"},
	"click_radius": {"cost": 30, "level": 0, "category": "collection"},
	"particle_lifetime": {"cost": 40, "level": 0, "category": "collection"},
	"auto_collection": {"cost": 100, "level": 0, "category": "collection"},
	"auto_collection_speed": {"cost": 75, "level": 0, "category": "collection"},
	"auto_collection_radius": {"cost": 50, "level": 0, "category": "collection"},
	"particle_magnet": {"cost": 150, "level": 0, "category": "collection"},

	# Special upgrades
	"compression_resistance": {"cost": 200, "level": 0, "category": "special"},
	"sun_thrower": {"cost": 1000, "level": 0, "category": "special", "unlocked": false}
}

func _ready():
	load_game_state()
	_apply_skill_bonuses()
	energy_changed.emit(total_energy)
	upgrade_points_changed.emit(upgrade_points)
	print("GameManager ready. Initial energy: ", total_energy, " Upgrade Points: ", upgrade_points)

func _process(delta):
	# Auto-damage system
	if auto_damage_amount > 0:
		auto_damage_timer += delta
		if auto_damage_timer >= auto_damage_interval:
			auto_damage_timer = 0.0
			deal_damage(auto_damage_amount, false)

	# Auto-collection system
	if auto_collection_enabled:
		auto_collection_timer += delta
		if auto_collection_timer >= auto_collection_interval:
			auto_collection_timer = 0.0
			_perform_auto_collection()

	# Combo decay
	if combo_count > 0:
		combo_timer += delta
		if combo_timer >= combo_window:
			combo_count = 0
			combo_damage_bonus = 0.0

	# DPS calculation
	dps_timer += delta
	if dps_timer >= 1.0:
		current_dps = damage_this_second
		damage_this_second = 0
		dps_timer = 0.0

func deal_damage(base_damage: int, is_click: bool = true) -> int:
	var final_damage = base_damage

	# Apply combo bonus if clicking
	if is_click and combo_count > 0:
		final_damage = int(final_damage * (1.0 + combo_damage_bonus))

	# Check for critical hit
	var is_critical = randf() < critical_chance
	if is_critical:
		final_damage = int(final_damage * critical_multiplier)

	# Track damage for DPS
	total_damage_dealt += final_damage
	damage_this_second += final_damage

	# Update combo if clicking
	if is_click:
		if combo_timer < combo_window:
			combo_count += 1
			if active_skills["combo_power"]:
				combo_damage_bonus = combo_count * 0.1
		else:
			combo_count = 1
			combo_damage_bonus = 0.0
		combo_timer = 0.0

	# Emit signal to spawn particles
	damage_dealt.emit(final_damage)

	# Check for cascade effect
	if is_critical and active_skills["cascade_effect"] and randf() < 0.2:
		# Trigger another hit after a short delay
		get_tree().create_timer(0.1).timeout.connect(func(): deal_damage(base_damage, false))

	print("Damage dealt: ", final_damage, " Critical: ", is_critical, " Combo: ", combo_count)
	return final_damage

func calculate_particles_to_spawn(damage: int, is_critical: bool) -> int:
	var particles = int(damage * particles_per_hit / float(click_damage))

	# Critical mastery bonus
	if is_critical and active_skills["critical_mastery"]:
		particles += 3

	return max(1, particles)

func add_energy(amount: int) -> void:
	var final_amount = amount

	# Value surge bonus
	if combo_count > 1 and active_skills["value_surge"]:
		final_amount = int(final_amount * 1.5)

	total_energy += final_amount
	print("Energy added: +", final_amount, " Total: ", total_energy)
	energy_changed.emit(total_energy)
	particle_collected.emit(final_amount)

	# Collection burst chance
	if active_skills["collection_burst"] and randf() < 0.05:
		# Spawn a bonus particle (signal to spawn system)
		print("Collection burst! Bonus particle spawned")

func add_to_pile(particle_count: int) -> void:
	pile_height += particle_count
	var effective_threshold = compression_threshold * (1.0 + compression_resistance_bonus)
	if active_skills["compression_resistance"]:
		effective_threshold *= 1.25

	pile_height_changed.emit(pile_height, effective_threshold)

	# Check for compression
	if pile_height >= effective_threshold:
		trigger_compression()

func remove_from_pile(particle_count: int) -> void:
	pile_height = max(0, pile_height - particle_count)
	var effective_threshold = compression_threshold * (1.0 + compression_resistance_bonus)
	if active_skills["compression_resistance"]:
		effective_threshold *= 1.25
	pile_height_changed.emit(pile_height, effective_threshold)

func trigger_compression() -> void:
	compression_count += 1
	upgrade_points += 1
	pile_height = 0.0

	print("COMPRESSION EVENT! Count: ", compression_count, " Upgrade Points: ", upgrade_points)

	compression_occurred.emit(compression_count)
	upgrade_points_changed.emit(upgrade_points)

	# Unlock sun thrower after 5 compressions
	if compression_count >= 5:
		upgrades["sun_thrower"]["unlocked"] = true
		print("Sun Thrower unlocked!")

	save_game_state()

func can_afford_upgrade(upgrade_id: String) -> bool:
	if not upgrades.has(upgrade_id):
		return false

	# Check if upgrade is unlocked
	if upgrades[upgrade_id].has("unlocked") and not upgrades[upgrade_id]["unlocked"]:
		return false

	return total_energy >= get_upgrade_cost(upgrade_id)

func get_upgrade_cost(upgrade_id: String) -> int:
	if upgrades.has(upgrade_id):
		var cost = upgrades[upgrade_id].cost
		# Apply bulk discount skill
		if active_skills["bulk_discount"]:
			cost = int(cost * 0.9)
		return cost
	return 0

func apply_upgrade(upgrade_id: String) -> bool:
	if not can_afford_upgrade(upgrade_id):
		print("Cannot afford upgrade: ", upgrade_id)
		return false

	var upgrade = upgrades[upgrade_id]
	total_energy -= get_upgrade_cost(upgrade_id)
	upgrade.level += 1
	upgrade.cost = int(upgrade.cost * 1.5)  # Exponential cost increase

	# Apply upgrade effects
	match upgrade_id:
		"click_damage":
			click_damage += 1
			print("Upgraded click damage to: ", click_damage)
		"particles_per_hit":
			particles_per_hit += 2
			print("Upgraded particles per hit to: ", particles_per_hit)
		"critical_chance":
			critical_chance = min(0.95, critical_chance + 0.05)
			print("Upgraded critical chance to: ", critical_chance * 100, "%")
		"auto_damage":
			auto_damage_amount += 1
			print("Upgraded auto-damage to: ", auto_damage_amount)
		"auto_damage_speed":
			auto_damage_interval = max(0.1, auto_damage_interval - 0.05)
			print("Upgraded auto-damage interval to: ", auto_damage_interval)
		"auto_damage_power":
			auto_damage_amount += 1
			print("Upgraded auto-damage amount to: ", auto_damage_amount)
		"particle_value":
			particle_value += 1
			print("Upgraded particle value to: ", particle_value)
		"click_radius":
			click_radius += 10.0
			print("Upgraded click radius to: ", click_radius)
		"particle_lifetime":
			particle_lifetime += 2.0
			print("Upgraded particle lifetime to: ", particle_lifetime)
		"auto_collection":
			auto_collection_enabled = true
			print("Auto-collection enabled!")
		"auto_collection_speed":
			auto_collection_interval = max(0.1, auto_collection_interval - 0.05)
			print("Upgraded auto-collection interval to: ", auto_collection_interval)
		"auto_collection_radius":
			auto_collection_radius += 10.0
			print("Upgraded auto-collection radius to: ", auto_collection_radius)
		"particle_magnet":
			particle_magnet_strength += 25.0
			print("Upgraded particle magnet to: ", particle_magnet_strength)
		"compression_resistance":
			compression_resistance_bonus += 0.25
			print("Upgraded compression resistance to: ", compression_resistance_bonus * 100, "%")
		"sun_thrower":
			sun_thrower_purchased = true
			print("SUN THROWER PURCHASED! Preparing to win...")
			game_won.emit()
			return true

	energy_changed.emit(total_energy)
	upgrade_applied.emit(upgrade_id)
	save_game_state()
	return true

func get_upgrade_level(upgrade_id: String) -> int:
	if upgrades.has(upgrade_id):
		return upgrades[upgrade_id].level
	return 0

func can_afford_skill(skill_id: String) -> bool:
	if not skill_definitions.has(skill_id):
		return false
	if active_skills[skill_id]:
		return false  # Already purchased

	var skill = skill_definitions[skill_id]

	# Check tier requirements
	if skill.has("requires_points"):
		var total_skills_purchased = 0
		for s in active_skills.values():
			if s:
				total_skills_purchased += 1
		if total_skills_purchased < skill["requires_points"]:
			return false

	return upgrade_points >= skill.cost

func purchase_skill(skill_id: String) -> bool:
	if not can_afford_skill(skill_id):
		return false

	var skill = skill_definitions[skill_id]
	upgrade_points -= skill.cost
	active_skills[skill_id] = true

	print("Skill purchased: ", skill.name)
	upgrade_points_changed.emit(upgrade_points)
	save_game_state()
	return true

func _apply_skill_bonuses() -> void:
	# Apply permanent skill bonuses
	if active_skills["quick_start"]:
		total_energy = 50
	if active_skills["extended_reach"]:
		click_radius = int(click_radius * 1.2)
	if active_skills["sturdy_particles"]:
		particle_lifetime += 2.0
	if active_skills["auto_efficiency"]:
		# Applied in _process when dealing auto damage/collection
		pass
	if active_skills["particle_magnetism"]:
		particle_magnet_strength = 50.0

func perform_prestige() -> void:
	# Keep: upgrade_points, active_skills
	# Reset: everything else
	total_energy = 0
	click_damage = 1
	critical_chance = 0.0
	auto_damage_amount = 0
	auto_damage_interval = 0.5
	particles_per_hit = 5
	particle_value = 1
	particle_lifetime = 8.0
	click_radius = 30.0
	auto_collection_enabled = false
	auto_collection_interval = 0.3
	auto_collection_radius = 30.0
	particle_magnet_strength = 0.0
	pile_height = 0.0
	compression_threshold = 100.0
	compression_count = 0
	compression_resistance_bonus = 0.0
	combo_count = 0
	total_damage_dealt = 0
	damage_this_second = 0
	current_dps = 0
	sun_thrower_purchased = false

	# Reset upgrade levels and costs
	for upgrade_id in upgrades.keys():
		upgrades[upgrade_id].level = 0
		# Reset to base costs
		match upgrade_id:
			"click_damage": upgrades[upgrade_id].cost = 10
			"particles_per_hit": upgrades[upgrade_id].cost = 25
			"critical_chance": upgrades[upgrade_id].cost = 50
			"auto_damage": upgrades[upgrade_id].cost = 100
			"auto_damage_speed": upgrades[upgrade_id].cost = 75
			"auto_damage_power": upgrades[upgrade_id].cost = 50
			"particle_value": upgrades[upgrade_id].cost = 20
			"click_radius": upgrades[upgrade_id].cost = 30
			"particle_lifetime": upgrades[upgrade_id].cost = 40
			"auto_collection": upgrades[upgrade_id].cost = 100
			"auto_collection_speed": upgrades[upgrade_id].cost = 75
			"auto_collection_radius": upgrades[upgrade_id].cost = 50
			"particle_magnet": upgrades[upgrade_id].cost = 150
			"compression_resistance": upgrades[upgrade_id].cost = 200
			"sun_thrower":
				upgrades[upgrade_id].cost = 1000
				upgrades[upgrade_id]["unlocked"] = false

	_apply_skill_bonuses()

	print("PRESTIGE! Starting new run with ", upgrade_points, " Upgrade Points")
	prestige_performed.emit()
	energy_changed.emit(total_energy)
	save_game_state()

func _perform_auto_collection() -> void:
	# Signal to collect particles in radius
	# This will be handled by the particle system
	pass

func save_game_state() -> void:
	var save_data = {
		"energy": total_energy,
		"upgrade_points": upgrade_points,
		"click_damage": click_damage,
		"critical_chance": critical_chance,
		"auto_damage_amount": auto_damage_amount,
		"auto_damage_interval": auto_damage_interval,
		"particles_per_hit": particles_per_hit,
		"particle_value": particle_value,
		"particle_lifetime": particle_lifetime,
		"click_radius": click_radius,
		"auto_collection_enabled": auto_collection_enabled,
		"auto_collection_interval": auto_collection_interval,
		"auto_collection_radius": auto_collection_radius,
		"particle_magnet_strength": particle_magnet_strength,
		"pile_height": pile_height,
		"compression_threshold": compression_threshold,
		"compression_count": compression_count,
		"compression_resistance_bonus": compression_resistance_bonus,
		"total_damage_dealt": total_damage_dealt,
		"sun_thrower_purchased": sun_thrower_purchased,
		"upgrades": upgrades,
		"active_skills": active_skills
	}

	var save_file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data, "\t"))
		save_file.close()
		print("Game saved successfully")
	else:
		print("Failed to save game")

func load_game_state() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		print("No save file found, starting fresh")
		return

	var save_file = FileAccess.open("user://savegame.json", FileAccess.READ)
	if not save_file:
		print("Failed to load save file")
		return

	var json_string = save_file.get_as_text()
	save_file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Failed to parse save file")
		return

	var save_data = json.data

	# Load all saved values
	total_energy = save_data.get("energy", 0)
	upgrade_points = save_data.get("upgrade_points", 0)
	click_damage = save_data.get("click_damage", 1)
	critical_chance = save_data.get("critical_chance", 0.0)
	auto_damage_amount = save_data.get("auto_damage_amount", 0)
	auto_damage_interval = save_data.get("auto_damage_interval", 0.5)
	particles_per_hit = save_data.get("particles_per_hit", 5)
	particle_value = save_data.get("particle_value", 1)
	particle_lifetime = save_data.get("particle_lifetime", 8.0)
	click_radius = save_data.get("click_radius", 30.0)
	auto_collection_enabled = save_data.get("auto_collection_enabled", false)
	auto_collection_interval = save_data.get("auto_collection_interval", 0.3)
	auto_collection_radius = save_data.get("auto_collection_radius", 30.0)
	particle_magnet_strength = save_data.get("particle_magnet_strength", 0.0)
	pile_height = save_data.get("pile_height", 0.0)
	compression_threshold = save_data.get("compression_threshold", 100.0)
	compression_count = save_data.get("compression_count", 0)
	compression_resistance_bonus = save_data.get("compression_resistance_bonus", 0.0)
	total_damage_dealt = save_data.get("total_damage_dealt", 0)
	sun_thrower_purchased = save_data.get("sun_thrower_purchased", false)

	if save_data.has("upgrades"):
		upgrades = save_data.upgrades
	if save_data.has("active_skills"):
		active_skills = save_data.active_skills

	print("Game loaded successfully")
