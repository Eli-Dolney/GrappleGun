local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local packageRoot = ReplicatedStorage:WaitForChild("LTW_MorphSystem")
local shared = require(packageRoot.Shared)
local MorphRegistry = shared.MorphRegistry

local AppearanceService = require(script.Parent.AppearanceService)

local MorphService = {}
MorphService.__index = MorphService

local DEFAULT_STATE = {
	walkSpeed = 16,
	jumpPower = 50,
}
local SAFE_GROUND_OFFSET = 7
local SAFE_RAY_START_Y = 600
local SAFE_RAY_DEPTH = 1400
local MORPH_COOLDOWN_SECONDS = 0.35

local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getFallbackCFrame()
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation then
		return spawnLocation.CFrame + Vector3.new(0, SAFE_GROUND_OFFSET, 0)
	end

	return CFrame.new(0, 12, 0)
end

local function getSafeMorphCFrame(character)
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return getFallbackCFrame()
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.IgnoreWater = false

	local origin = Vector3.new(rootPart.Position.X, math.max(rootPart.Position.Y + 50, SAFE_RAY_START_Y), rootPart.Position.Z)
	local result = Workspace:Raycast(origin, Vector3.new(0, -SAFE_RAY_DEPTH, 0), raycastParams)
	if result then
		local lookVector = rootPart.CFrame.LookVector
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
		if flatLook.Magnitude < 0.001 then
			flatLook = Vector3.zAxis
		end

		local safePosition = result.Position + Vector3.new(0, SAFE_GROUND_OFFSET, 0)
		return CFrame.lookAt(safePosition, safePosition + flatLook.Unit)
	end

	return getFallbackCFrame()
end

local function setCharacterAnchored(character, isAnchored)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = isAnchored
		end
	end
end

local function clearCharacterVelocity(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function stabilizeCharacter(character, shouldMoveToSafeGround)
	local humanoid = getHumanoid(character)
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.AutoRotate = true
	end

	if rootPart then
		setCharacterAnchored(character, true)
		clearCharacterVelocity(character)

		if shouldMoveToSafeGround then
			character:PivotTo(getSafeMorphCFrame(character))
		end
	end

	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	if rootPart then
		task.delay(0.08, function()
			if character.Parent then
				clearCharacterVelocity(character)
				setCharacterAnchored(character, false)
			end
		end)
	end
end

function MorphService.new(definitions, remoteNames)
	local registry = MorphRegistry.new()
	registry:RegisterMany(definitions)

	return setmetatable({
		_registry = registry,
		_remoteNames = remoteNames,
		_activeMorphs = {},
		_connections = {},
		_lastMorphRequestAt = {},
	}, MorphService)
end

function MorphService:Start()
	local remoteFolder = Instance.new("Folder")
	remoteFolder.Name = self._remoteNames.FolderName
	remoteFolder.Parent = ReplicatedStorage
	self._remoteFolder = remoteFolder

	local requestMorph = Instance.new("RemoteEvent")
	requestMorph.Name = self._remoteNames.RequestMorph
	requestMorph.Parent = remoteFolder
	self._requestMorph = requestMorph

	local getMorphState = Instance.new("RemoteFunction")
	getMorphState.Name = self._remoteNames.GetMorphState
	getMorphState.Parent = remoteFolder
	self._getMorphState = getMorphState

	requestMorph.OnServerEvent:Connect(function(player, morphId)
		self:ApplyMorph(player, morphId)
	end)

	getMorphState.OnServerInvoke = function(player)
		return self:GetClientState(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:HandlePlayerAdded(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:HandlePlayerAdded(player)
	end
end

function MorphService:HandlePlayerAdded(player)
	self._activeMorphs[player.UserId] = self._activeMorphs[player.UserId] or "human"

	local characterAddedConnection = player.CharacterAdded:Connect(function(character)
		self:HandleCharacterAdded(player, character)
	end)

	self._connections[player] = characterAddedConnection

	if player.Character then
		self:HandleCharacterAdded(player, player.Character)
	end
end

function MorphService:HandlePlayerRemoving(player)
	local connection = self._connections[player]
	if connection then
		connection:Disconnect()
		self._connections[player] = nil
	end

	self._activeMorphs[player.UserId] = nil
	self._lastMorphRequestAt[player.UserId] = nil
end

function MorphService:HandleCharacterAdded(player, character)
	local humanoid = getHumanoid(character)
	if not humanoid then
		return
	end

	self:RestoreDefaults(character)

	local activeMorphId = self._activeMorphs[player.UserId]
	if activeMorphId and activeMorphId ~= "human" then
		self:ApplyMorph(player, activeMorphId, true)
	else
		player:SetAttribute("LTW_ActiveMorphId", "human")
		player:SetAttribute("LTW_CanFly", false)
		player:SetAttribute("LTW_FlightSpeed", 0)
	end
end

function MorphService:GetClientState(player)
	local serializedMorphs = {}

	for _, definition in ipairs(self._registry:List()) do
		table.insert(serializedMorphs, {
			id = definition.id,
			displayName = definition.displayName,
			icon = definition.icon,
			description = definition.description,
			themeColor = definition.appearance.themeColor,
			canFly = definition.abilities.flight == true,
		})
	end

	return {
		morphs = serializedMorphs,
		activeMorphId = self._activeMorphs[player.UserId] or "human",
	}
end

function MorphService:RestoreDefaults(character)
	local humanoid = getHumanoid(character)
	if not humanoid then
		return
	end

	humanoid.UseJumpPower = true
	humanoid.WalkSpeed = DEFAULT_STATE.walkSpeed
	humanoid.JumpPower = DEFAULT_STATE.jumpPower
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.AutoRotate = true

	AppearanceService.Clear(character)
end

function MorphService:ApplyMorph(player, morphId, isRespawnApply)
	local character = player.Character
	local humanoid = getHumanoid(character)
	if not character or not humanoid then
		return
	end

	if not isRespawnApply then
		local now = os.clock()
		local lastRequestAt = self._lastMorphRequestAt[player.UserId] or 0
		if now - lastRequestAt < MORPH_COOLDOWN_SECONDS then
			return
		end
		self._lastMorphRequestAt[player.UserId] = now
	end

	if morphId == nil or morphId == "" or morphId == "human" then
		self._activeMorphs[player.UserId] = "human"
		stabilizeCharacter(character, true)
		self:RestoreDefaults(character)
		player:SetAttribute("LTW_CanFly", false)
		player:SetAttribute("LTW_FlightSpeed", 0)
		player:SetAttribute("LTW_ActiveMorphId", "human")
		return
	end

	local definition = self._registry:Get(morphId)
	if not definition then
		warn(("Unknown morph requested: %s"):format(tostring(morphId)))
		return
	end

	self._activeMorphs[player.UserId] = definition.id

	stabilizeCharacter(character, true)
	self:RestoreDefaults(character)

	humanoid.WalkSpeed = definition.movement.walkSpeed or DEFAULT_STATE.walkSpeed
	humanoid.JumpPower = definition.movement.jumpPower or DEFAULT_STATE.jumpPower

	AppearanceService.Apply(character, definition)

	player:SetAttribute("LTW_CanFly", definition.abilities.flight == true)
	player:SetAttribute("LTW_FlightSpeed", definition.movement.flightSpeed or 0)
	player:SetAttribute("LTW_ActiveMorphId", definition.id)

	if isRespawnApply then
		player:SetAttribute("LTW_ReappliedMorph", definition.id)
	end
end

return MorphService
