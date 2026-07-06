# Catch And Tame Roblox Project Blueprint

This blueprint is meant to be copied into a fresh Roblox project.
It turns the game idea into a reusable simulator-style architecture with clear folder ownership.

## Core game loop

1. Explore the world
2. Find roaming animals
3. Catch them with a lasso
4. Bring them back to your pen
5. Earn passive money
6. Buy upgrades and unlock zones
7. Breed stronger animals
8. Chase rare, event, and secret pets

## Recommended Rojo structure

```text
src/
  ReplicatedStorage/
    CatchAndTame/
      Shared/
        Config/
          Animals.lua
          AnimalTiers.lua
          BreedingRecipes.lua
          Lassos.lua
          Upgrades.lua
          Zones.lua
          Weather.lua
          Economy.lua
          Settings.lua
        Types/
          AnimalTypes.lua
          PlayerDataTypes.lua
        Utilities/
          TableUtil.lua
          MathUtil.lua
          TimerUtil.lua
          WeightedRandom.lua
        Remotes.lua
        GameConstants.lua
        init.lua
      Assets/
        UI/
          AnimalCardTemplate.lua
          UpgradeCardTemplate.lua
          BreedingCardTemplate.lua
        VFX/
        SFX/

  ServerScriptService/
    CatchAndTameServer/
      Bootstrap.server.lua
      Services/
        PlayerDataService.lua
        AnimalService.lua
        SpawnService.lua
        CaptureService.lua
        PenService.lua
        EconomyService.lua
        UpgradeService.lua
        ZoneService.lua
        WeatherService.lua
        BreedingService.lua
        RewardService.lua
        QuestService.lua
        CodeService.lua
        AntiExploitService.lua
      Components/
        AnimalSpawner.lua
        AnimalBrain.lua
        CaptureSession.lua
      Libraries/
        ProfileStoreAdapter.lua

  StarterPlayer/
    StarterPlayerScripts/
      CatchAndTameClient/
        Bootstrap.client.lua
        Controllers/
          HUDController.lua
          InputController.lua
          LassoController.lua
          CaptureController.lua
          PenController.lua
          UpgradeShopController.lua
          BreedingController.lua
          CollectionController.lua
          WeatherController.lua
          NotificationController.lua
        UI/
          MainHUD.lua
          CapturePrompt.lua
          PenScreen.lua
          UpgradeShopScreen.lua
          BreedingScreen.lua
          CollectionScreen.lua
          CodeScreen.lua
        Camera/
          ZoneCameraEffects.lua

  StarterGui/
    CatchAndTameGui/

  Workspace/
    World/
      Zones/
        Farm/
        Forest/
        Savannah/
        Snow/
        Jungle/
        Volcano/
        SkyRuins/
      SpawnMarkers/
      DropOffs/
      Pens/
      WeatherEmitters/
    Interactive/
      UpgradeShops/
      BreedingStations/
      CodeNPCs/

  ServerStorage/
    CatchAndTameAssets/
      AnimalModels/
      LassoModels/
      PenModels/
      ZoneDecor/
```

## Folder-by-folder purpose

### `ReplicatedStorage/CatchAndTame/Shared/Config`

This is the data heart of the whole game.
If you want the project to be reusable, nearly all game balance should live here.

Files:

- `Animals.lua`: every animal definition
- `AnimalTiers.lua`: rarity metadata and color/style info
- `BreedingRecipes.lua`: parent combinations, odds, and special conditions
- `Lassos.lua`: lasso tiers, stats, unlocks, and bonuses
- `Upgrades.lua`: player upgrades, pen upgrades, storage, utility unlocks
- `Zones.lua`: zone costs, level gates, spawn pools, and requirements
- `Weather.lua`: weather types, durations, modifiers, and event weights
- `Economy.lua`: sell values, passive income, curve tuning, and reward multipliers
- `Settings.lua`: shared tuning values like spawn caps and cooldown defaults

Recommended animal schema:

```lua
return {
    Chicken = {
        Id = "Chicken",
        DisplayName = "Chicken",
        Tier = "Common",
        Zone = "Farm",
        SpawnWeight = 40,
        CapturePowerRequired = 10,
        CaptureDifficulty = 0.2,
        BaseIncomePerSecond = 3,
        MovementProfile = "Passive",
        ActiveWeather = { "Any" },
        ActiveTime = { "Day", "Night" },
        Traits = { "Starter" },
        CanBreed = true,
    },
}
```

### `ReplicatedStorage/CatchAndTame/Shared/Types`

Put optional shape definitions and field docs here so every module agrees on data layout.
Even if you stay in Luau without strict typing everywhere, this folder keeps systems aligned.

Files:

- `AnimalTypes.lua`
- `PlayerDataTypes.lua`

### `ReplicatedStorage/CatchAndTame/Shared/Utilities`

Keep this folder generic and reusable between projects.

Files:

- `TableUtil.lua`: merge, clone, shallow compare
- `MathUtil.lua`: clamp helpers, curve helpers, interpolation
- `TimerUtil.lua`: cooldowns, ticking helpers
- `WeightedRandom.lua`: choose animals, weather, loot, or rewards by weight

### `ReplicatedStorage/CatchAndTame/Shared/Remotes.lua`

One central place to create and expose all remote events and functions.

Suggested remotes:

- `RequestCatch`
- `CatchStateChanged`
- `AnimalCaptured`
- `DropOffAnimal`
- `PenUpdated`
- `RequestUpgradePurchase`
- `UpgradePurchased`
- `WeatherUpdated`
- `ZoneUnlocked`
- `RequestBreed`
- `BreedCompleted`
- `RedeemCode`
- `Notification`

### `ReplicatedStorage/CatchAndTame/Shared/GameConstants.lua`

Store constant names used across server and client.

Examples:

- collection names
- attribute keys
- default stat caps
- remote names
- zone tags

### `ReplicatedStorage/CatchAndTame/Assets`

This is for replicated UI templates and shared cosmetic references.
Do not put server-only models here.

## Server architecture

### `ServerScriptService/CatchAndTameServer/Bootstrap.server.lua`

Starts all services in the correct order.

Recommended startup order:

1. `PlayerDataService`
2. `ZoneService`
3. `WeatherService`
4. `AnimalService`
5. `SpawnService`
6. `PenService`
7. `EconomyService`
8. `UpgradeService`
9. `BreedingService`
10. `RewardService`
11. `QuestService`
12. `CodeService`
13. `AntiExploitService`
14. remote bindings last if needed

### `ServerScriptService/CatchAndTameServer/Services`

Each service should own one piece of game truth.
Avoid large god-scripts.

#### `PlayerDataService.lua`

Owns player save data and session state.

Suggested data shape:

```lua
return {
    Currency = 0,
    EquippedLasso = "BasicLasso",
    UnlockedZones = { Farm = true },
    Upgrades = {},
    OwnedAnimals = {},
    ActivePens = {},
    CodesRedeemed = {},
    QuestProgress = {},
    Stats = {
        TotalCaught = 0,
        TotalBred = 0,
        HighestTierCaught = "Common",
    },
}
```

Responsibilities:

- load and save player profiles
- session locking
- safe getters and setters
- replication payloads for UI

#### `AnimalService.lua`

Owns animal definitions and live animal records.

Responsibilities:

- validate config
- build animal lookup tables
- create live spawned animal records
- answer questions like "what can spawn here right now?"

#### `SpawnService.lua`

Owns world spawning.

Responsibilities:

- manage zone spawn caps
- pick spawn markers
- choose animals by zone, weather, and time
- despawn stale animals
- respawn after capture or timeout

#### `CaptureService.lua`

Owns catch validation and catch outcomes.

Responsibilities:

- receive catch requests
- validate distance, timing, and target
- compare lasso power against animal requirements
- resolve success, fail, breakaway, or partial progress
- prevent client spoofing

#### `PenService.lua`

Owns the player’s stored animals and pen state.

Responsibilities:

- add captured animals into inventory or pen
- assign animals to slots
- calculate pen occupancy
- expose best income layout if desired

#### `EconomyService.lua`

Owns money generation and reward pacing.

Responsibilities:

- passive income ticks
- drop-off rewards
- balancing formulas
- offline earnings support if added later

#### `UpgradeService.lua`

Owns purchases and stat unlocks.

Responsibilities:

- validate purchase requirements
- deduct currency
- unlock lasso tiers
- expand storage or pens
- unlock utilities like weather tracker

#### `ZoneService.lua`

Owns zone progression.

Responsibilities:

- unlock checks
- teleport or gate validation
- zone requirement lookup
- current accessible zone list

#### `WeatherService.lua`

Owns rotating world conditions.

Responsibilities:

- choose weather
- manage duration
- broadcast state changes
- expose modifiers used by spawn and breeding systems

#### `BreedingService.lua`

Owns parent validation and recipe resolution.

Responsibilities:

- validate ownership
- check breeding station requirements
- match recipes
- roll success chance
- create result animals

#### `RewardService.lua`

Optional but useful.
Use it for daily rewards, milestone rewards, and event rewards so reward logic does not spread everywhere.

#### `QuestService.lua`

Optional for launch, but good for retention.

Responsibilities:

- track beginner and repeatable goals
- grant rewards
- encourage progression into new zones and systems

#### `CodeService.lua`

Owns redeemable game codes.

Responsibilities:

- validate code strings
- reject reused codes
- grant rewards cleanly

#### `AntiExploitService.lua`

Small but important.

Responsibilities:

- rate limit remotes
- reject impossible catches
- reject invalid currency changes
- watch for duplicated breeding or purchase requests

### `ServerScriptService/CatchAndTameServer/Components`

Use components for object-level behaviors rather than global services.

Files:

- `AnimalSpawner.lua`: spawn point behavior
- `AnimalBrain.lua`: wandering, flee, idle, chase, or special movement
- `CaptureSession.lua`: temporary state for an in-progress catch interaction

### `ServerScriptService/CatchAndTameServer/Libraries`

Put vendor adapters or wrappers here, not your game rules.

Example:

- `ProfileStoreAdapter.lua`

## Client architecture

### `StarterPlayer/StarterPlayerScripts/CatchAndTameClient/Bootstrap.client.lua`

Starts controllers and hooks UI together.

Recommended controller order:

1. `NotificationController`
2. `HUDController`
3. `InputController`
4. `LassoController`
5. `CaptureController`
6. `PenController`
7. `UpgradeShopController`
8. `BreedingController`
9. `CollectionController`
10. `WeatherController`

### `StarterPlayer/StarterPlayerScripts/CatchAndTameClient/Controllers`

Each controller should coordinate one gameplay-facing system.

#### `HUDController.lua`

Owns:

- currency display
- equipped lasso display
- active weather display
- pen income display
- zone name display

#### `InputController.lua`

Owns:

- keybinds
- mobile button bindings
- controller-friendly input mapping

#### `LassoController.lua`

Owns:

- equip and throw feedback
- local aim feedback
- throw cooldown visuals
- hit effect preview

#### `CaptureController.lua`

Owns:

- target highlight
- catch progress bar
- fail or success feedback
- capture prompt states

#### `PenController.lua`

Owns:

- viewing pen contents
- assigning animals to slots
- collecting information about pen income

#### `UpgradeShopController.lua`

Owns:

- shop open and close
- button state updates
- price and requirement display

#### `BreedingController.lua`

Owns:

- parent selection
- recipe preview
- success rate display
- breed result reveal

#### `CollectionController.lua`

Owns:

- bestiary or pet index
- rarity filters
- discovered vs undiscovered state

#### `WeatherController.lua`

Owns:

- weather banner
- fog, lighting, and ambience feedback
- event alerts

#### `NotificationController.lua`

Owns:

- toast messages
- reward banners
- milestone announcements

### `StarterPlayer/StarterPlayerScripts/CatchAndTameClient/UI`

Keep each screen isolated.
This makes the UI easier to reuse and replace.

Files:

- `MainHUD.lua`
- `CapturePrompt.lua`
- `PenScreen.lua`
- `UpgradeShopScreen.lua`
- `BreedingScreen.lua`
- `CollectionScreen.lua`
- `CodeScreen.lua`

### `StarterGui/CatchAndTameGui`

Use this as the top-level screen container if you prefer building interface objects directly in Studio.

## World structure

### `Workspace/World/Zones`

Each zone should be easy to tune and replace.

Recommended first zones:

- `Farm`
- `Forest`
- `Savannah`
- `Snow`
- `Jungle`
- `Volcano`
- `SkyRuins`

Each zone should contain:

- spawn markers
- zone boundary
- travel entry point
- unlock sign or gate
- themed animals

### `Workspace/World/SpawnMarkers`

If you want reusable spawning, keep markers standardized with attributes.

Suggested attributes:

- `Zone`
- `SpawnWeight`
- `SpawnType`
- `MaxRadius`

### `Workspace/World/DropOffs`

Places where players turn catches into owned pen animals or instant rewards.

### `Workspace/World/Pens`

Can be a personal instanced area or a visible player plot.

Store attributes like:

- `OwnerUserId`
- `PenLevel`
- `SlotCount`

### `Workspace/Interactive`

Put world interaction points here:

- upgrade shops
- breeding stations
- quest boards
- code NPCs

## Suggested build order

### Milestone 1: first playable loop

Build only this:

1. player data
2. one lasso
3. one zone
4. three animals
5. simple spawn system
6. catch validation
7. drop-off point
8. passive pen income
9. basic HUD

If this is not fun, do not add breeding yet.

### Milestone 2: progression layer

Add:

1. second and third lasso
2. second zone
3. upgrade shop
4. more animal rarities
5. better UI feedback

### Milestone 3: strategy layer

Add:

1. weather states
2. time-of-day conditions
3. better spawn tables
4. collection index
5. code rewards

### Milestone 4: endgame layer

Add:

1. breeding station
2. recipe system
3. low-odds animals
4. secret or event pets
5. quests and milestones

## Design rules to keep the project reusable

- Keep balance in config, not hardcoded inside services.
- Keep each service focused on one job.
- Keep the client responsible for presentation, not authority.
- Never let the client award money or create animals directly.
- Prefer attributes and config-driven world markers over special-case scripts.
- Build the first version so adding a new animal is mostly a data-entry task.

## Best first animal roster

Use a tiny launch roster first:

- `Chicken`
- `Dog`
- `Goat`
- `Wolf`
- `Bear`
- `Lion`

That is enough to test:

- common to higher-tier progression
- zone differences
- capture scaling
- pen income scaling

## Best first upgrades

- stronger lasso
- bigger animal storage
- more pen slots
- faster movement
- weather tracker
- breeding unlock

## Copy-over advice from your current reusable project

You can reuse these ideas from the current morph project:

- bootstrap pattern
- shared config layout
- client controller split
- server service split
- replicated remotes module

Do not force morph-specific code into this new game.
This project should be built around animals, economy, and progression instead.

## What I would script first

If you start the new project tomorrow, script in this order:

1. `GameConstants.lua`
2. `Remotes.lua`
3. `Animals.lua`
4. `Lassos.lua`
5. `PlayerDataService.lua`
6. `AnimalService.lua`
7. `SpawnService.lua`
8. `CaptureService.lua`
9. `PenService.lua`
10. `EconomyService.lua`
11. `HUDController.lua`
12. `LassoController.lua`
13. `CaptureController.lua`

That gets you to a real playable prototype fastest.
