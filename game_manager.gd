extends Node

# Signals
signal energy_changed(new_energy: int)
signal particle_collected(value: int)
signal upgrade_applied(upgrade_id: String)

# Game state
var total_energy: int = 0
var particles_per_click: int = 5
var particle_value: int = 1
var collection_radius: float = 50.0
var auto_collectors: int = 0

# Upgrade costs
var upgrades = {
	"more_particles": {"cost": 50, "level": 0},
	"particle_value": {"cost": 100, "level": 0},
	"collection_radius": {"cost": 75, "level": 0},
	"auto_collector": {"cost": 200, "level": 0}
}

func _ready():
	load_game_state()

func add_energy(amount: int) -> void:
	total_energy += amount
	energy_changed.emit(total_energy)
	particle_collected.emit(amount)

func can_afford_upgrade(upgrade_id: String) -> bool:
	if not upgrades.has(upgrade_id):
		return false
	return total_energy >= upgrades[upgrade_id].cost

func apply_upgrade(upgrade_id: String) -> bool:
	if not can_afford_upgrade(upgrade_id):
		return false
	
	var upgrade = upgrades[upgrade_id]
	total_energy -= upgrade.cost
	upgrade.level += 1
	upgrade.cost = int(upgrade.cost * 1.5)  # Exponential cost increase
	
	# Apply upgrade effects
	match upgrade_id:
		"more_particles":
			particles_per_click += 2
		"particle_value":
			particle_value += 1
		"collection_radius":
			collection_radius += 25.0
		"auto_collector":
			auto_collectors += 1
	
	energy_changed.emit(total_energy)
	upgrade_applied.emit(upgrade_id)
	save_game_state()
	return true

func get_upgrade_cost(upgrade_id: String) -> int:
	if upgrades.has(upgrade_id):
		return upgrades[upgrade_id].cost
	return 0

func get_upgrade_level(upgrade_id: String) -> int:
	if upgrades.has(upgrade_id):
		return upgrades[upgrade_id].level
	return 0

func save_game_state() -> void:
	var save_data = {
		"energy": total_energy,
		"particles_per_click": particles_per_click,
		"particle_value": particle_value,
		"collection_radius": collection_radius,
		"auto_collectors": auto_collectors,
		"upgrades": upgrades
	}
	# TODO: Implement actual save to file
	print("Game saved: ", save_data)

func load_game_state() -> void:
	# TODO: Implement actual load from file
	print("Game loaded (placeholder)")

func _on_energy_changed(new_energy: int) -> void:
	pass # Replace with function body.


func _on_particle_collected(value: int) -> void:
	pass # Replace with function body.


func _on_upgrade_applied(upgrade_id: String) -> void:
	pass # Replace with function body.
