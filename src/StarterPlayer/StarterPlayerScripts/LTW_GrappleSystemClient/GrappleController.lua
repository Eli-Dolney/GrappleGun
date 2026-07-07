local ContextActionService = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GrappleController = {}

local ACTION_GRAPPLE = "LTW_FireGrapple"
local localPlayer = Players.LocalPlayer

local config
local requestGrappleRemote
local currentState = {}
local hudGui
local statusLabel
local shopButton
local mobileFireButton
local rangeLabel
local lastLocalFireAt = 0

local function getCharacter()
	return localPlayer.Character
end

local function getRootPart()
	local character = getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerRootPart(player)
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getEquippedGrappleTool()
	local character = getCharacter()
	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("LTW_GrappleTool") == true then
			return child
		end
	end

	return nil
end

local function playerHasGrapple()
	return currentState.hasTool == true or getEquippedGrappleTool() ~= nil
end

local function getAimPosition()
	local camera = Workspace.CurrentCamera
	local rootPart = getRootPart()
	if not camera or not rootPart then
		return nil
	end

	local ray
	if UserInputService.TouchEnabled then
		local viewport = camera.ViewportSize
		ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.45)
	else
		local mouse = localPlayer:GetMouse()
		ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { getCharacter() }
	raycastParams.IgnoreWater = false

	local result = Workspace:Raycast(ray.Origin, ray.Direction * (currentState.maxRange or config.MaxRange), raycastParams)
	return result and result.Position or nil
end

local function flashTether(grapplePlayer, targetPosition)
	local rootPart = getPlayerRootPart(grapplePlayer)
	if not rootPart or not targetPosition then
		return
	end

	local anchor = Instance.new("Part")
	anchor.Name = "LTW_GrappleBeamAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = targetPosition
	anchor.Parent = Workspace

	local rootAttachment = Instance.new("Attachment")
	rootAttachment.Name = "LTW_GrappleBeamRoot"
	rootAttachment.Parent = rootPart

	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "LTW_GrappleBeamTarget"
	targetAttachment.Parent = anchor

	local beam = Instance.new("Beam")
	beam.Name = "LTW_GrappleBeam"
	beam.Attachment0 = rootAttachment
	beam.Attachment1 = targetAttachment
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 219, 99), Color3.fromRGB(52, 198, 255))
	beam.FaceCamera = true
	beam.LightEmission = 0.85
	beam.Width0 = 0.2
	beam.Width1 = 0.08
	beam.Parent = rootPart

	task.delay(0.65, function()
		if beam.Parent then
			beam:Destroy()
		end
		if rootAttachment.Parent then
			rootAttachment:Destroy()
		end
		if anchor.Parent then
			anchor:Destroy()
		end
	end)
end

local function updateHud()
	if not hudGui then
		return
	end

	local hasTool = playerHasGrapple()
	statusLabel.Visible = hasTool
	rangeLabel.Visible = hasTool
	mobileFireButton.Visible = hasTool and UserInputService.TouchEnabled
	shopButton.Visible = config.ShopEnabled == true and not currentState.hasPermanent

	if currentState.isInfinite then
		statusLabel.Text = "Grapple: Infinite"
	elseif hasTool then
		statusLabel.Text = ("Grapple: %d uses"):format(currentState.uses or 0)
	end

	rangeLabel.Text = ("Max range: %d studs"):format(currentState.maxRange or config.MaxRange)
end

local function fireGrapple()
	if not playerHasGrapple() then
		return
	end

	local now = os.clock()
	local cooldown = currentState.cooldownSeconds or config.CooldownSeconds
	if now - lastLocalFireAt < cooldown then
		return
	end

	local targetPosition = getAimPosition()
	if not targetPosition then
		return
	end

	lastLocalFireAt = now
	requestGrappleRemote:FireServer(targetPosition)
end

local function createButton(parent, text, size, position)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.BackgroundColor3 = Color3.fromRGB(31, 36, 48)
	button.Position = position
	button.Size = size
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(248, 251, 255)
	button.TextSize = 15
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.82
	stroke.Parent = button

	return button
end

local function createHud()
	hudGui = Instance.new("ScreenGui")
	hudGui.Name = "LTW_GrappleHUD"
	hudGui.ResetOnSpawn = false
	hudGui.Parent = localPlayer:WaitForChild("PlayerGui")

	statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundColor3 = Color3.fromRGB(19, 23, 31)
	statusLabel.BackgroundTransparency = 0.08
	statusLabel.Position = UDim2.new(1, -220, 0, 18)
	statusLabel.Size = UDim2.new(0, 200, 0, 38)
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextColor3 = Color3.fromRGB(255, 235, 178)
	statusLabel.TextSize = 15
	statusLabel.Visible = false
	statusLabel.Parent = hudGui

	local labelCorner = Instance.new("UICorner")
	labelCorner.CornerRadius = UDim.new(0, 8)
	labelCorner.Parent = statusLabel

	rangeLabel = Instance.new("TextLabel")
	rangeLabel.BackgroundTransparency = 1
	rangeLabel.Position = UDim2.new(1, -220, 0, 56)
	rangeLabel.Size = UDim2.new(0, 200, 0, 22)
	rangeLabel.Font = Enum.Font.GothamMedium
	rangeLabel.TextColor3 = Color3.fromRGB(210, 224, 240)
	rangeLabel.TextSize = 12
	rangeLabel.TextXAlignment = Enum.TextXAlignment.Right
	rangeLabel.Visible = false
	rangeLabel.Parent = hudGui

	shopButton = createButton(hudGui, "Buy Infinite Grapple", UDim2.new(0, 176, 0, 38), UDim2.new(1, -196, 0, 64))
	shopButton.Activated:Connect(function()
		if config.GamePassId > 0 then
			MarketplaceService:PromptGamePassPurchase(localPlayer, config.GamePassId)
		else
			shopButton.Text = "Set GamePassId"
			TweenService:Create(shopButton, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(129, 63, 63) }):Play()
			task.delay(1.2, function()
				if shopButton.Parent then
					shopButton.Text = "Buy Infinite Grapple"
					TweenService:Create(shopButton, TweenInfo.new(0.16), { BackgroundColor3 = Color3.fromRGB(31, 36, 48) }):Play()
				end
			end)
		end
	end)

	mobileFireButton = createButton(hudGui, "GRAPPLE", UDim2.new(0, 96, 0, 96), UDim2.new(1, -118, 1, -228))
	mobileFireButton.Visible = false
	mobileFireButton.Activated:Connect(fireGrapple)
end

local function hookTool(tool)
	if not tool:GetAttribute("LTW_GrappleTool") then
		return
	end

	tool.Activated:Connect(fireGrapple)
	tool:GetAttributeChangedSignal("LTW_GrappleUses"):Connect(function()
		currentState.uses = tool:GetAttribute("LTW_GrappleUses") or 0
		updateHud()
	end)

	currentState.hasTool = true
	currentState.uses = tool:GetAttribute("LTW_GrappleUses") or 0
	currentState.isInfinite = tool:GetAttribute("LTW_GrappleInfinite") == true
	updateHud()
end

local function watchContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") then
			hookTool(child)
		end
	end

	container.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(hookTool, child)
		end
	end)
end

function GrappleController.Start(options)
	config = options.config
	requestGrappleRemote = options.requestGrappleRemote
	currentState = options.getStateRemote:InvokeServer()

	createHud()
	updateHud()

	options.stateChangedRemote.OnClientEvent:Connect(function(nextState)
		currentState = nextState
		updateHud()
	end)

	options.grappleFiredRemote.OnClientEvent:Connect(function(grapplePlayer, targetPosition)
		if grapplePlayer == localPlayer then
			lastLocalFireAt = os.clock()
		end
		flashTether(grapplePlayer, targetPosition)
	end)

	ContextActionService:BindAction(ACTION_GRAPPLE, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			fireGrapple()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonR2)

	watchContainer(localPlayer:WaitForChild("Backpack"))
	if localPlayer.Character then
		watchContainer(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(watchContainer)
end

return GrappleController
