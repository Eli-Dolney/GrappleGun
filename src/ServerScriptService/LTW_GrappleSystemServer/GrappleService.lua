local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GrappleService = {}
GrappleService.__index = GrappleService

local PICKUP_TOOL_TYPE = "Pickup"
local PERMANENT_TOOL_TYPE = "Permanent"

local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerTool(player)
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")

	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute("LTW_GrappleTool") == true then
				return child
			end
		end
	end

	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute("LTW_GrappleTool") == true then
				return child
			end
		end
	end

	return nil
end

local function destroyPickupToolIfEmpty(player)
	local tool = getPlayerTool(player)
	if tool and tool:GetAttribute("LTW_GrappleToolType") == PICKUP_TOOL_TYPE and (tool:GetAttribute("LTW_GrappleUses") or 0) <= 0 then
		tool:Destroy()
	end
end

local function weldToHandle(handle, part)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = part
	weld.Parent = handle
end

local function createToolPart(name, size, color, material, cframe, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.Massless = true
	part.CFrame = cframe
	part.Parent = parent

	return part
end

function GrappleService.new(config)
	return setmetatable({
		_config = config,
		_lastGrappleAt = {},
		_hasPermanent = {},
	}, GrappleService)
end

function GrappleService:Start()
	self:CreateRemotes()
	self:CreateTestArena()
	self:CreateFallbackPickupSpawn()
	self:CreatePickupPads()

	Players.PlayerAdded:Connect(function(player)
		self:HandlePlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._lastGrappleAt[player.UserId] = nil
		self._hasPermanent[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:HandlePlayerAdded(player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if gamePassId == self._config.GamePassId and wasPurchased then
			self._hasPermanent[player.UserId] = true
			self:GivePermanentTool(player)
			self:SendState(player)
		end
	end)
end

function GrappleService:CreateRemotes()
	local remoteFolder = Instance.new("Folder")
	remoteFolder.Name = self._config.RemoteFolderName
	remoteFolder.Parent = ReplicatedStorage
	self._remoteFolder = remoteFolder

	local requestGrapple = Instance.new("RemoteEvent")
	requestGrapple.Name = self._config.RequestGrappleRemote
	requestGrapple.Parent = remoteFolder
	self._requestGrapple = requestGrapple

	local grappleFired = Instance.new("RemoteEvent")
	grappleFired.Name = self._config.GrappleFiredRemote
	grappleFired.Parent = remoteFolder
	self._grappleFired = grappleFired

	local getState = Instance.new("RemoteFunction")
	getState.Name = self._config.GetGrappleStateRemote
	getState.Parent = remoteFolder
	self._getState = getState

	local stateChanged = Instance.new("RemoteEvent")
	stateChanged.Name = self._config.StateChangedRemote
	stateChanged.Parent = remoteFolder
	self._stateChanged = stateChanged

	requestGrapple.OnServerEvent:Connect(function(player, targetPosition)
		self:HandleGrappleRequest(player, targetPosition)
	end)

	getState.OnServerInvoke = function(player)
		return self:GetState(player)
	end
end

function GrappleService:HandlePlayerAdded(player)
	self._hasPermanent[player.UserId] = self:OwnsPermanentPass(player)

	player.CharacterAdded:Connect(function()
		task.defer(function()
			if player.Parent and self._hasPermanent[player.UserId] then
				self:GivePermanentTool(player)
				self:SendState(player)
			end
		end)
	end)

	task.defer(function()
		if player.Parent and self._hasPermanent[player.UserId] then
			self:GivePermanentTool(player)
		end
		self:SendState(player)
	end)
end

function GrappleService:OwnsPermanentPass(player)
	if self._config.GamePassId <= 0 then
		return false
	end

	local success, ownsPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, self._config.GamePassId)
	end)

	if not success then
		warn(("Could not check grapple game pass for %s"):format(player.Name))
		return false
	end

	return ownsPass
end

function GrappleService:GetState(player)
	local tool = getPlayerTool(player)
	return {
		hasPermanent = self._hasPermanent[player.UserId] == true,
		hasTool = tool ~= nil,
		uses = tool and tool:GetAttribute("LTW_GrappleUses") or 0,
		isInfinite = tool and tool:GetAttribute("LTW_GrappleInfinite") == true or false,
		gamePassId = self._config.GamePassId,
		maxRange = self._config.MaxRange,
		cooldownSeconds = self._config.CooldownSeconds,
	}
end

function GrappleService:SendState(player)
	if self._stateChanged then
		self._stateChanged:FireClient(player, self:GetState(player))
	end
end

function GrappleService:CreateTool(toolType, uses)
	local tool = Instance.new("Tool")
	tool.Name = self._config.ToolName
	tool.ToolTip = self._config.ToolName
	tool.RequiresHandle = true
	tool.CanBeDropped = toolType == PICKUP_TOOL_TYPE
	tool.Grip = CFrame.new(0, -0.25, -0.25) * CFrame.Angles(math.rad(-82), 0, 0)
	tool:SetAttribute("LTW_GrappleTool", true)
	tool:SetAttribute("LTW_GrappleToolType", toolType)
	tool:SetAttribute("LTW_GrappleInfinite", toolType == PERMANENT_TOOL_TYPE)
	tool:SetAttribute("LTW_GrappleUses", uses or 0)

	local accentColor = toolType == PERMANENT_TOOL_TYPE and Color3.fromRGB(52, 198, 255) or Color3.fromRGB(255, 183, 72)
	local baseCFrame = CFrame.new()

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 0.35, 0.35)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local brace = createToolPart("WristBrace", Vector3.new(1.55, 0.28, 1.05), Color3.fromRGB(26, 29, 36), Enum.Material.SmoothPlastic, baseCFrame * CFrame.new(0, -0.08, 0), tool)
	local topPlate = createToolPart("LauncherBody", Vector3.new(1.2, 0.32, 1.55), Color3.fromRGB(52, 58, 70), Enum.Material.Metal, baseCFrame * CFrame.new(0, 0.2, -0.08), tool)
	local reel = createToolPart("CableReel", Vector3.new(0.7, 0.22, 0.7), accentColor, Enum.Material.Neon, baseCFrame * CFrame.new(0, 0.42, 0.22), tool)
	local barrel = createToolPart("HookLauncher", Vector3.new(0.32, 0.28, 0.9), Color3.fromRGB(17, 20, 26), Enum.Material.Metal, baseCFrame * CFrame.new(0, 0.35, -0.85), tool)
	local nozzle = createToolPart("LauncherNozzle", Vector3.new(0.46, 0.38, 0.18), accentColor, Enum.Material.Neon, baseCFrame * CFrame.new(0, 0.35, -1.36), tool)
	local leftStrap = createToolPart("LeftStrap", Vector3.new(0.12, 0.36, 1.1), Color3.fromRGB(10, 12, 16), Enum.Material.SmoothPlastic, baseCFrame * CFrame.new(-0.84, -0.08, 0), tool)
	local rightStrap = createToolPart("RightStrap", Vector3.new(0.12, 0.36, 1.1), Color3.fromRGB(10, 12, 16), Enum.Material.SmoothPlastic, baseCFrame * CFrame.new(0.84, -0.08, 0), tool)

	for _, part in ipairs({ brace, topPlate, reel, barrel, nozzle, leftStrap, rightStrap }) do
		weldToHandle(handle, part)
	end

	return tool
end

function GrappleService:GivePickupTool(player)
	if self._hasPermanent[player.UserId] then
		self:GivePermanentTool(player)
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	local existingTool = getPlayerTool(player)
	if existingTool then
		if existingTool:GetAttribute("LTW_GrappleInfinite") then
			return
		end

		local uses = existingTool:GetAttribute("LTW_GrappleUses") or 0
		existingTool:SetAttribute("LTW_GrappleUses", math.min(uses + self._config.PickupUses, self._config.PickupUses))
		self:SendState(player)
		return
	end

	self:CreateTool(PICKUP_TOOL_TYPE, self._config.PickupUses).Parent = backpack
	self:SendState(player)
end

function GrappleService:GivePermanentTool(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	local existingTool = getPlayerTool(player)
	if existingTool then
		if existingTool:GetAttribute("LTW_GrappleInfinite") then
			return
		end
		existingTool:Destroy()
	end

	self:CreateTool(PERMANENT_TOOL_TYPE, 0).Parent = backpack
end

function GrappleService:CreateArenaPart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.Parent = parent

	return part
end

function GrappleService:CreateTree(parent, name, position, height)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local trunkHeight = height
	local trunk = self:CreateArenaPart(
		model,
		"Trunk",
		Vector3.new(3.5, trunkHeight, 3.5),
		CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)),
		Color3.fromRGB(111, 73, 45),
		Enum.Material.Wood
	)

	local canopy = self:CreateArenaPart(
		model,
		"Canopy",
		Vector3.new(12, 10, 12),
		CFrame.new(position + Vector3.new(0, trunkHeight + 4, 0)),
		Color3.fromRGB(41, 126, 73),
		Enum.Material.Grass
	)

	model.PrimaryPart = trunk

	return model, canopy
end

function GrappleService:CreateTestArena()
	if self._config.TestArenaEnabled ~= true then
		return
	end

	if Workspace:FindFirstChild(self._config.TestArenaFolderName) then
		return
	end

	local arena = Instance.new("Folder")
	arena.Name = self._config.TestArenaFolderName
	arena.Parent = Workspace

	local floorColor = Color3.fromRGB(78, 88, 102)
	self:CreateArenaPart(arena, "GrappleTestFloor", Vector3.new(210, 1, 170), CFrame.new(0, -0.5, -18), floorColor, Enum.Material.Concrete)

	local spawnPad = self:CreateArenaPart(arena, "StartPad", Vector3.new(16, 1.2, 16), CFrame.new(0, 0.2, 0), Color3.fromRGB(226, 229, 237), Enum.Material.SmoothPlastic)
	spawnPad.TopSurface = Enum.SurfaceType.Smooth

	local lowWall = self:CreateArenaPart(arena, "LowPracticeWall", Vector3.new(48, 12, 4), CFrame.new(-18, 6, -44), Color3.fromRGB(132, 139, 150), Enum.Material.Brick)
	lowWall.TopSurface = Enum.SurfaceType.Smooth

	self:CreateArenaPart(arena, "SmallBuilding", Vector3.new(24, 34, 24), CFrame.new(42, 17, -62), Color3.fromRGB(96, 105, 120), Enum.Material.Concrete)
	self:CreateArenaPart(arena, "SmallBuildingRoofTarget", Vector3.new(16, 2, 16), CFrame.new(42, 35, -62), Color3.fromRGB(52, 198, 255), Enum.Material.Metal)
	self:CreateArenaPart(arena, "TallBuilding", Vector3.new(30, 58, 30), CFrame.new(78, 29, 12), Color3.fromRGB(70, 78, 92), Enum.Material.Concrete)
	self:CreateArenaPart(arena, "TallBuildingRoofTarget", Vector3.new(18, 2, 18), CFrame.new(78, 59, 12), Color3.fromRGB(255, 183, 72), Enum.Material.Metal)
	self:CreateArenaPart(arena, "SideBuilding", Vector3.new(22, 28, 34), CFrame.new(-68, 14, 22), Color3.fromRGB(88, 94, 105), Enum.Material.Concrete)

	self:CreateArenaPart(arena, "GroundTraversalTarget", Vector3.new(18, 1, 18), CFrame.new(-44, 0.05, -78), Color3.fromRGB(52, 198, 255), Enum.Material.Neon)
	self:CreateArenaPart(arena, "Ramp", Vector3.new(30, 2, 24), CFrame.new(-8, 5, -86) * CFrame.Angles(math.rad(-18), 0, 0), Color3.fromRGB(119, 128, 143), Enum.Material.Metal)

	self:CreateTree(arena, "OakGrappleTree", Vector3.new(-44, 0, 48), 30)
	self:CreateTree(arena, "PineGrappleTree", Vector3.new(-12, 0, 72), 42)
	self:CreateTree(arena, "FarTree", Vector3.new(36, 0, 74), 36)

	local spawnFolder = Instance.new("Folder")
	spawnFolder.Name = self._config.PickupSpawnFolderName
	spawnFolder.Parent = Workspace

	local pickupSpawn = Instance.new("Part")
	pickupSpawn.Name = "TestArenaPickupSpawn"
	pickupSpawn.Size = Vector3.new(4, 1, 4)
	pickupSpawn.CFrame = CFrame.new(0, 1.8, -10)
	pickupSpawn.Transparency = 1
	pickupSpawn.Anchored = true
	pickupSpawn.CanCollide = false
	pickupSpawn.Parent = spawnFolder
end

function GrappleService:CreateFallbackPickupSpawn()
	local spawnFolder = Workspace:FindFirstChild(self._config.PickupSpawnFolderName)
	if spawnFolder then
		return
	end

	spawnFolder = Instance.new("Folder")
	spawnFolder.Name = self._config.PickupSpawnFolderName
	spawnFolder.Parent = Workspace

	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local position = spawnLocation and (spawnLocation.Position + Vector3.new(8, 3, 0)) or Vector3.new(0, 6, 0)

	local marker = Instance.new("Part")
	marker.Name = "GrapplePickupSpawn"
	marker.Size = Vector3.new(4, 1, 4)
	marker.Position = position
	marker.Transparency = 1
	marker.Anchored = true
	marker.CanCollide = false
	marker.Parent = spawnFolder
end

function GrappleService:GetPickupSpawnParts()
	local spawnParts = {}
	local spawnFolder = Workspace:FindFirstChild(self._config.PickupSpawnFolderName)

	if spawnFolder then
		for _, descendant in ipairs(spawnFolder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(spawnParts, descendant)
			end
		end
	end

	for _, taggedPart in ipairs(CollectionService:GetTagged(self._config.PickupSpawnTag)) do
		if taggedPart:IsA("BasePart") then
			table.insert(spawnParts, taggedPart)
		end
	end

	return spawnParts
end

function GrappleService:CreatePickupPads()
	local pickupFolder = Instance.new("Folder")
	pickupFolder.Name = self._config.PickupFolderName
	pickupFolder.Parent = Workspace

	for _, spawnPart in ipairs(self:GetPickupSpawnParts()) do
		self:CreatePickupPad(spawnPart, pickupFolder)
	end
end

function GrappleService:CreatePickupPad(spawnPart, pickupFolder)
	local pad = Instance.new("Part")
	pad.Name = "GrapplePickupPad"
	pad.Size = Vector3.new(3, 1, 3)
	pad.CFrame = spawnPart.CFrame + Vector3.new(0, 1.2, 0)
	pad.Anchored = true
	pad.CanCollide = false
	pad.Color = Color3.fromRGB(255, 183, 72)
	pad.Material = Enum.Material.Neon
	pad.Parent = pickupFolder

	local model = Instance.new("Model")
	model.Name = "WristGrappleDisplay"
	model.Parent = pad

	local pickupCore = createToolPart("DisplayBody", Vector3.new(2.05, 0.34, 1.25), Color3.fromRGB(34, 38, 47), Enum.Material.Metal, pad.CFrame * CFrame.new(0, 0.9, 0), model)
	pickupCore.Anchored = true
	local pickupReel = createToolPart("DisplayReel", Vector3.new(0.78, 0.22, 0.78), Color3.fromRGB(255, 183, 72), Enum.Material.Neon, pad.CFrame * CFrame.new(0, 1.18, 0.18), model)
	pickupReel.Anchored = true
	local pickupNozzle = createToolPart("DisplayNozzle", Vector3.new(0.44, 0.35, 0.82), Color3.fromRGB(16, 19, 25), Enum.Material.Metal, pad.CFrame * CFrame.new(0, 1.07, -0.85), model)
	pickupNozzle.Anchored = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = ("%s (%d uses)"):format(self._config.ToolName, self._config.PickupUses)
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.Parent = pad

	local available = true
	prompt.Triggered:Connect(function(player)
		if not available then
			return
		end

		available = false
		pad.Transparency = 1
		model.Parent = nil
		prompt.Enabled = false
		self:GivePickupTool(player)

		task.delay(self._config.RespawnSeconds, function()
			if pad.Parent then
				available = true
				pad.Transparency = 0
				model.Parent = pad
				prompt.Enabled = true
			end
		end)
	end)
end

function GrappleService:CanUseTool(player)
	local tool = getPlayerTool(player)
	if not tool then
		return false
	end

	if tool:GetAttribute("LTW_GrappleInfinite") then
		return true
	end

	return (tool:GetAttribute("LTW_GrappleUses") or 0) > 0
end

function GrappleService:ConsumeUse(player)
	local tool = getPlayerTool(player)
	if not tool or tool:GetAttribute("LTW_GrappleInfinite") then
		return
	end

	local remainingUses = math.max((tool:GetAttribute("LTW_GrappleUses") or 0) - 1, 0)
	tool:SetAttribute("LTW_GrappleUses", remainingUses)
	self:SendState(player)

	if remainingUses <= 0 then
		task.defer(function()
			destroyPickupToolIfEmpty(player)
			self:SendState(player)
		end)
	end
end

function GrappleService:HandleGrappleRequest(player, targetPosition)
	if typeof(targetPosition) ~= "Vector3" then
		return
	end

	if not self:CanUseTool(player) then
		self:SendState(player)
		return
	end

	local now = os.clock()
	local lastGrappleAt = self._lastGrappleAt[player.UserId] or 0
	if now - lastGrappleAt < self._config.CooldownSeconds then
		return
	end

	local character = player.Character
	local humanoid = getHumanoid(character)
	local rootPart = getRootPart(character)
	if not character or not humanoid or humanoid.Health <= 0 or not rootPart then
		return
	end

	local offset = targetPosition - rootPart.Position
	if offset.Magnitude > self._config.MaxRange or offset.Magnitude < self._config.MinRange then
		return
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.IgnoreWater = false

	local result = Workspace:Raycast(rootPart.Position, offset, raycastParams)
	if not result or (result.Position - targetPosition).Magnitude > 8 then
		return
	end

	self._lastGrappleAt[player.UserId] = now
	self:ConsumeUse(player)
	self._grappleFired:FireAllClients(player, result.Position)
	self:PullCharacter(character, rootPart, result.Position)
end

function GrappleService:PullCharacter(character, rootPart, targetPosition)
	local existingPull = rootPart:FindFirstChild("LTW_GrapplePull")
	if existingPull then
		existingPull:Destroy()
	end
	local existingAttachment = rootPart:FindFirstChild("LTW_GrappleAttachment")
	if existingAttachment then
		existingAttachment:Destroy()
	end

	local humanoid = getHumanoid(character)
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end

	rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, math.max(rootPart.AssemblyLinearVelocity.Y, self._config.UpwardBoost), rootPart.AssemblyLinearVelocity.Z)

	local attachment = Instance.new("Attachment")
	attachment.Name = "LTW_GrappleAttachment"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "LTW_GrapplePull"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 120000
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart

	local startedAt = os.clock()
	local heartbeatConnection
	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not rootPart.Parent or not linearVelocity.Parent then
			heartbeatConnection:Disconnect()
			return
		end

		local offset = targetPosition - rootPart.Position
		local distance = offset.Magnitude
		if distance <= self._config.CloseEnoughDistance or os.clock() - startedAt >= self._config.PullSeconds then
			heartbeatConnection:Disconnect()
			linearVelocity:Destroy()
			attachment:Destroy()
			return
		end

		local direction = offset.Unit
		local speedScale = math.clamp(distance / 70, 0.45, 1)
		local arcTime = math.clamp((os.clock() - startedAt) / self._config.PullSeconds, 0, 1)
		local arcBoost = math.sin(arcTime * math.pi) * self._config.UpwardBoost
		local upwardBoost = direction.Y < -0.2 and arcBoost * 0.25 or arcBoost
		linearVelocity.VectorVelocity = direction * (self._config.PullSpeed * speedScale) + Vector3.new(0, upwardBoost, 0)
	end)

	task.delay(self._config.PullSeconds + 0.1, function()
		if heartbeatConnection.Connected then
			heartbeatConnection:Disconnect()
		end
		if linearVelocity.Parent then
			linearVelocity:Destroy()
		end
		if attachment.Parent then
			attachment:Destroy()
		end
	end)
end

return GrappleService
