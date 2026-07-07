# Wrist Grapple

A standalone Rojo building block for a Roblox wrist grappling hook.

## What It Does

- Spawns pickup pads in the map
- Gives players a `Wrist Grapple` tool with 10 uses
- Removes the pickup version when uses hit 0
- Grapples to normal map geometry: trees, builds, cliffs, floors, and walls
- Enforces a server-side max range
- Shows the tether line only after the server accepts the grapple and spends a use
- Uses server-authoritative movement so the grapple cannot be trusted only from the client
- Includes a placeholder wrist-mounted model that can be replaced later
- Can generate a small test arena with trees, buildings, walls, a ramp, and ground targets

## Rojo Layout

- `src/ReplicatedStorage/LTW_GrappleSystem`: shared config
- `src/ServerScriptService/LTW_GrappleSystemServer`: pickup, tool, validation, and physics
- `src/StarterPlayer/StarterPlayerScripts/LTW_GrappleSystemClient`: input, HUD, aiming, and beam preview

## Controls

- Equip `Wrist Grapple`
- Click to grapple
- Press `E` to grapple
- Mobile players get a `GRAPPLE` button

## Config

Edit `src/ReplicatedStorage/LTW_GrappleSystem/Shared/GrappleConfig.lua`.

Useful values:

- `PickupUses`: default `10`
- `MaxRange`: default `300`
- `CooldownSeconds`: default `0.55`
- `PullSpeed`: default `172`
- `TestArenaEnabled`: default `true`
- `ShopEnabled`: default `false`
- `GamePassId`: set later when adding the Robux infinite-use version

## Test Arena

With `TestArenaEnabled = true`, the server creates a sample arena while the game is running. Press Play in Studio to test:

- Tree trunks and canopies
- Short and tall buildings
- Roof targets
- Ground traversal target
- Low wall
- Ramp

The arena is named `LTW_GrappleTestArena` in Workspace during runtime.

## Placing Pickups

The system creates one fallback pickup near the map spawn.

For custom pickup spots:

1. In Workspace, create a folder named `LTW_GrapplePickupSpawns`
2. Add parts where pickups should appear
3. The parts can be transparent markers
4. Restart playtest or reconnect Rojo

## Project Hygiene

This repo is intentionally just the grapple system. Keep each new idea in its own Rojo project/repo when possible, then copy finished systems into game projects as building blocks.
