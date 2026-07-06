local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local FlightController = {}

local ACTION_TOGGLE = "LTW_ToggleFlight"
local ACTION_ASCEND = "LTW_AscendFlight"
local ACTION_DESCEND = "LTW_DescendFlight"

local currentPlayer
local currentCharacter
local currentRootPart
local currentHumanoid
local flightVelocity
local flightGyro
local renderConnection
local characterConnection

local canFly = false
local isFlying = false
local ascendHeld = false
local descendHeld = false
local flightSpeed = 52

local flyGui
local flyButton
local upButton
local downButton

local function stabilizeCharacter()
	if currentRootPart then
		currentRootPart.AssemblyLinearVelocity = Vector3.zero
		currentRootPart.AssemblyAngularVelocity = Vector3.zero
	end

	if currentHumanoid then
		currentHumanoid.PlatformStand = false
		currentHumanoid.Sit = false
		currentHumanoid.AutoRotate = true
		currentHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function cleanupForces()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if flightVelocity then
		flightVelocity:Destroy()
		flightVelocity = nil
	end

	if flightGyro then
		flightGyro:Destroy()
		flightGyro = nil
	end

	if currentHumanoid then
		currentHumanoid.AutoRotate = true
	end
end

local function updateFlightHud()
	if not flyGui then
		return
	end

	flyGui.Enabled = canFly

	if flyButton then
		flyButton.Text = isFlying and "LAND" or "FLY"
		flyButton.BackgroundColor3 = isFlying and Color3.fromRGB(227, 101, 74) or Color3.fromRGB(52, 151, 186)
	end

	local touchMode = UserInputService.TouchEnabled
	if upButton then
		upButton.Visible = canFly and isFlying and touchMode
	end
	if downButton then
		downButton.Visible = canFly and isFlying and touchMode
	end
end

local function stopFlight()
	isFlying = false
	ascendHeld = false
	descendHeld = false
	cleanupForces()
	updateFlightHud()
end

local function stopFlightAndStabilize()
	stopFlight()
	stabilizeCharacter()
end

local function startFlight()
	if not canFly or not currentRootPart or not currentHumanoid then
		return
	end

	stopFlight()
	isFlying = true
	currentHumanoid.AutoRotate = false
	currentHumanoid:ChangeState(Enum.HumanoidStateType.Freefall)

	flightVelocity = Instance.new("BodyVelocity")
	flightVelocity.Name = "LTW_FlightVelocity"
	flightVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
	flightVelocity.P = 2500
	flightVelocity.Velocity = Vector3.zero
	flightVelocity.Parent = currentRootPart

	flightGyro = Instance.new("BodyGyro")
	flightGyro.Name = "LTW_FlightGyro"
	flightGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
	flightGyro.P = 7500
	flightGyro.CFrame = currentRootPart.CFrame
	flightGyro.Parent = currentRootPart

	renderConnection = RunService.RenderStepped:Connect(function()
		if not currentRootPart or not currentHumanoid or not flightVelocity or not flightGyro then
			stopFlight()
			return
		end

		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		local moveVector = currentHumanoid.MoveDirection
		local vertical = 0
		if ascendHeld then
			vertical += 1
		end
		if descendHeld then
			vertical -= 1
		end

		local velocity = Vector3.new(moveVector.X, vertical, moveVector.Z)
		if velocity.Magnitude > 0 then
			velocity = velocity.Unit * flightSpeed
		end

		local lookVector = camera.CFrame.LookVector
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
		if flatLook.Magnitude < 0.001 then
			flatLook = currentRootPart.CFrame.LookVector
		end
		flatLook = flatLook.Unit

		flightVelocity.Velocity = velocity
		flightGyro.CFrame = CFrame.lookAt(currentRootPart.Position, currentRootPart.Position + flatLook)
	end)

	updateFlightHud()
end

local function toggleFlight()
	if not canFly then
		return
	end

	if isFlying then
		stopFlight()
	else
		startFlight()
	end
end

local function bindAction(name, callback, ...)
	ContextActionService:BindAction(name, callback, true, ...)
	local button = ContextActionService:GetButton(name)
	if button then
		button.Visible = false
	end
end

local function updateAttributes()
	if not currentPlayer then
		return
	end

	local wasAbleToFly = canFly
	canFly = currentPlayer:GetAttribute("LTW_CanFly") == true
	flightSpeed = currentPlayer:GetAttribute("LTW_FlightSpeed") or 52

	if not canFly and isFlying then
		stopFlightAndStabilize()
	elseif canFly and not wasAbleToFly and not isFlying then
		task.defer(startFlight)
	end

	updateFlightHud()
end

local function hookCharacter(character)
	currentCharacter = character
	currentHumanoid = character:WaitForChild("Humanoid")
	currentRootPart = character:WaitForChild("HumanoidRootPart")

	stopFlight()
	updateAttributes()
end

local function createRoundButton(parent, text, size, position)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.fromRGB(32, 38, 59)
	button.Position = position
	button.Size = size
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(248, 251, 255)
	button.TextSize = 18
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.82
	stroke.Thickness = 1
	stroke.Parent = button

	return button
end

local function createHud(playerGui)
	flyGui = Instance.new("ScreenGui")
	flyGui.Name = "LTW_FlightHUD"
	flyGui.ResetOnSpawn = false
	flyGui.Enabled = false
	flyGui.Parent = playerGui

	flyButton = createRoundButton(flyGui, "FLY", UDim2.new(0, 88, 0, 88), UDim2.new(1, -110, 1, -120))
	upButton = createRoundButton(flyGui, "+", UDim2.new(0, 62, 0, 62), UDim2.new(1, -188, 1, -152))
	downButton = createRoundButton(flyGui, "-", UDim2.new(0, 62, 0, 62), UDim2.new(1, -188, 1, -80))

	upButton.Visible = false
	downButton.Visible = false

	flyButton.Activated:Connect(toggleFlight)

	upButton.MouseButton1Down:Connect(function()
		ascendHeld = true
	end)
	upButton.MouseButton1Up:Connect(function()
		ascendHeld = false
	end)
	upButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			ascendHeld = true
		end
	end)
	upButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			ascendHeld = false
		end
	end)

	downButton.MouseButton1Down:Connect(function()
		descendHeld = true
	end)
	downButton.MouseButton1Up:Connect(function()
		descendHeld = false
	end)
	downButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			descendHeld = true
		end
	end)
	downButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			descendHeld = false
		end
	end)
end

function FlightController.Start(player)
	currentPlayer = player

	local playerGui = player:WaitForChild("PlayerGui")
	createHud(playerGui)

	bindAction(ACTION_TOGGLE, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			toggleFlight()
		end
	end, Enum.KeyCode.F)

	bindAction(ACTION_ASCEND, function(_, inputState)
		if not canFly then
			return Enum.ContextActionResult.Pass
		end

		if inputState == Enum.UserInputState.Begin and not isFlying then
			startFlight()
		end

		if isFlying then
			ascendHeld = inputState == Enum.UserInputState.Begin
			return Enum.ContextActionResult.Sink
		end

		return Enum.ContextActionResult.Pass
	end, Enum.KeyCode.Space, Enum.KeyCode.E)

	bindAction(ACTION_DESCEND, function(_, inputState)
		if not isFlying then
			return Enum.ContextActionResult.Pass
		end

		descendHeld = inputState == Enum.UserInputState.Begin
		return Enum.ContextActionResult.Sink
	end, Enum.KeyCode.Q)

	player:GetAttributeChangedSignal("LTW_CanFly"):Connect(updateAttributes)
	player:GetAttributeChangedSignal("LTW_FlightSpeed"):Connect(updateAttributes)

	if player.Character then
		hookCharacter(player.Character)
	end

	characterConnection = player.CharacterAdded:Connect(hookCharacter)
	updateAttributes()
end

return FlightController
