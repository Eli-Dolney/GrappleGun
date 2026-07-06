local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

function GrappleService.new(config)
	return setmetatable({
		_config = config,
		_lastGrappleAt = {},
		_hasPermanent = {},
	}, GrappleService)
end

function GrappleService:Start()
	self:CreateRemotes()
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
	tool:SetAttribute("LTW_GrappleTool", true)
	tool:SetAttribute("LTW_GrappleToolType", toolType)
	tool:SetAttribute("LTW_GrappleInfinite", toolType == PERMANENT_TOOL_TYPE)
	tool:SetAttribute("LTW_GrappleUses", uses or 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1.5, 0.7, 2.2)
	handle.Color = toolType == PERMANENT_TOOL_TYPE and Color3.fromRGB(52, 198, 255) or Color3.fromRGB(255, 183, 72)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local grip = Instance.new("Part")
	grip.Name = "GripDetail"
	grip.Size = Vector3.new(0.34, 0.95, 0.42)
	grip.Color = Color3.fromRGB(32, 35, 45)
	grip.Material = Enum.Material.SmoothPlastic
	grip.CanCollide = false
	grip.Massless = true
	grip.Parent = tool

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = grip
	weld.Parent = handle
	grip.CFrame = handle.CFrame * CFrame.new(0, -0.72, 0.35) * CFrame.Angles(math.rad(14), 0, 0)

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
	pad.Name = "GrapplePickup"
	pad.Size = Vector3.new(3, 1, 3)
	pad.CFrame = spawnPart.CFrame + Vector3.new(0, 1.2, 0)
	pad.Anchored = true
	pad.CanCollide = false
	pad.Color = Color3.fromRGB(255, 183, 72)
	pad.Material = Enum.Material.Neon
	pad.Parent = pickupFolder

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
		prompt.Enabled = false
		self:GivePickupTool(player)

		task.delay(self._config.RespawnSeconds, function()
			if pad.Parent then
				available = true
				pad.Transparency = 0
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
	if offset.Magnitude > self._config.MaxRange or offset.Magnitude < 8 then
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
	self:PullCharacter(character, rootPart, result.Position)
end

function GrappleService:PullCharacter(character, rootPart, targetPosition)
	local attachment = Instance.new("Attachment")
	attachment.Name = "LTW_GrappleAttachment"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "LTW_GrapplePull"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 90000
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart

	local direction = targetPosition - rootPart.Position
	local upward = Vector3.new(0, self._config.UpwardBoost, 0)
	linearVelocity.VectorVelocity = direction.Unit * self._config.PullSpeed + upward

	task.delay(self._config.PullSeconds, function()
		if linearVelocity.Parent then
			linearVelocity:Destroy()
		end
		if attachment.Parent then
			attachment:Destroy()
		end
	end)
end

return GrappleService
