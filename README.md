# Wizard Beater

An incremental resource management game built in Godot 4.5 with GDScript.

## Game Concept

Beat up a wizard and watch the visual spectacle as you manage resources, balancing destruction with collection to ultimately make him explode.

The wizard angered the people with his magical mischief, so they've decided to beat him up and collect his magical essence. The win condition is to compress the wizard five times, then build a unit that creates a sun to throw at him, causing a spectacular explosion.

## Core Mechanics

- **Attack**: Click the wizard to deal damage
- **Spawn**: Damage causes magical particles to burst out
- **Pile**: Particles fall and accumulate in a pile
- **Collect**: Click particles to send them toward the collector
- **Currency**: Collected particles become currency for upgrades
- **Compress**: If pile gets too high, particles compress back into wizard (awards Upgrade Points)
- **Progress**: After 5 compressions, unlock the sun thrower to win!

## Features

### In-Run Upgrades (Energy Currency)
- **Damage Upgrades**: Click damage, particles per hit, critical chance, auto-damage
- **Collection Upgrades**: Particle value, click radius, lifetime, auto-collection, particle magnet
- **Special Upgrades**: Compression resistance, Sun Thrower (win condition)

### Prestige System
- Earn Upgrade Points from compression events
- Prestige to reset the run while keeping Upgrade Points
- Spend Upgrade Points on permanent skill tree upgrades

### Skill Tree (4 Tiers)
- **Tier 1**: Quick Start, Extended Reach, Sturdy Particles
- **Tier 2**: Auto-Efficiency, Bulk Discount, Particle Magnetism
- **Tier 3**: Critical Mastery, Combo Power, Collection Burst
- **Tier 4**: Compression Resistance, Value Surge, Cascade Effect

### Visual Effects
- Screen shake on big hits
- Compression meter with color warnings
- Combo counter
- DPS tracking
- Colorful particle cascades

## Development

**Engine**: Godot 4.5
**Language**: GDScript
**Platform**: PC (Steam target)
**Art Style**: Pixel art

## How to Play

1. Click the wizard to deal damage and spawn particles
2. Click particles to collect them for energy
3. Purchase upgrades to improve damage and collection
4. Balance attacking vs collecting to avoid compression
5. Earn Upgrade Points through compression events
6. Use Upgrade Points to unlock permanent skills
7. Reach 5 compressions to unlock the Sun Thrower
8. Purchase the Sun Thrower to win the game!

## Project Structure

See [CLAUDE.md](CLAUDE.md) for detailed codebase documentation.

## License

All rights reserved.
