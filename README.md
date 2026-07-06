# LTW Morph System

A reusable Roblox morph framework built for Rojo projects and easy GitHub reuse.

## Included in v1

- Center-left morph icon with a polished in-game menu
- Data-driven morph registry
- `Dragon` morph with flight
- `Goblin` morph with faster ground movement
- Reset back to `Human`

## Project layout

- `src/ReplicatedStorage/LTW_MorphSystem`: shared modules and morph definitions
- `src/ServerScriptService/LTW_MorphSystemServer`: server bootstrap and morph application logic
- `src/StarterPlayer/StarterPlayerScripts/LTW_MorphSystemClient`: client UI and flight controller

## Add a new morph

1. Copy the shape from `MorphButtonTemplate.lua`
2. Add the new entry to `MorphDefinitions.lua`
3. Give it movement, abilities, card text, and appearance settings
4. Reuse existing cosmetics or add a new cosmetic builder in `AppearanceService.lua`

The registry and UI will pick it up automatically.

## Controls

- Open morph menu: click the left-side button or press `M`
- Toggle flight: `F`
- Fly up: `Space` or `E`
- Fly down: `Q`

## Notes

- This v1 stays on the standard humanoid character for simplicity.
- Flight is implemented as a shared client ability, not dragon-only hardcoded behavior.
- The system reapplies the active morph after respawn.
