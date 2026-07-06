local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MorphUI = {}

local PANEL_WIDTH = 270
local PANEL_CLOSED_X = -PANEL_WIDTH - 24
local PANEL_OPEN_X = 102
local BUTTON_OPEN_X = 22
local BUTTON_CLOSED_X = 18

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function tween(instance, properties)
	local animation = TweenService:Create(instance, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	animation:Play()
	return animation
end

local function getThemeColor(morph)
	return morph.themeColor or Color3.fromRGB(110, 154, 255)
end

local function createAbilityBadge(parent, text, color)
	local badge = Instance.new("TextLabel")
	badge.BackgroundColor3 = color
	badge.Font = Enum.Font.GothamBold
	badge.Text = text
	badge.TextColor3 = Color3.fromRGB(255, 255, 255)
	badge.TextSize = 10
	badge.Position = UDim2.new(0, 72, 1, -23)
	badge.Size = UDim2.new(0, 58, 0, 16)
	badge.Parent = parent
	createCorner(badge, 8)

	return badge
end

local function buildCard(parent, morph, onSelected)
	local card = Instance.new("TextButton")
	card.Name = morph.id
	card.AutoButtonColor = false
	card.BackgroundColor3 = Color3.fromRGB(29, 34, 51)
	card.Size = UDim2.new(1, 0, 0, 76)
	card.Text = ""
	card.Parent = parent
	createCorner(card, 18)
	createStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.86)

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.BackgroundColor3 = getThemeColor(morph)
	accent.BorderSizePixel = 0
	accent.Position = UDim2.new(0, 10, 0.5, -24)
	accent.Size = UDim2.new(0, 48, 0, 48)
	accent.Parent = card
	createCorner(accent, 16)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Text = morph.icon
	iconLabel.TextColor3 = Color3.fromRGB(255, 248, 242)
	iconLabel.TextScaled = true
	iconLabel.Position = UDim2.new(0, 8, 0, 8)
	iconLabel.Size = UDim2.new(1, -16, 1, -16)
	iconLabel.Parent = accent

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = morph.displayName
	nameLabel.TextColor3 = Color3.fromRGB(245, 246, 252)
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Position = UDim2.new(0, 72, 0, 12)
	nameLabel.Size = UDim2.new(1, -120, 0, 22)
	nameLabel.Parent = card

	local descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.Font = Enum.Font.Gotham
	descriptionLabel.Text = morph.description
	descriptionLabel.TextColor3 = Color3.fromRGB(186, 193, 216)
	descriptionLabel.TextSize = 13
	descriptionLabel.TextWrapped = true
	descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
	descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
	descriptionLabel.Position = UDim2.new(0, 72, 0, 34)
	descriptionLabel.Size = UDim2.new(1, -84, 0, 30)
	descriptionLabel.Parent = card

	if morph.id == "human" then
		createAbilityBadge(card, "RESET", Color3.fromRGB(79, 118, 255))
	elseif morph.canFly then
		createAbilityBadge(card, "FLIGHT", Color3.fromRGB(31, 171, 180))
	else
		createAbilityBadge(card, "SPEED", Color3.fromRGB(88, 153, 73))
	end

	local statusPill = Instance.new("TextLabel")
	statusPill.Name = "Status"
	statusPill.AnchorPoint = Vector2.new(1, 0.5)
	statusPill.BackgroundColor3 = Color3.fromRGB(61, 70, 104)
	statusPill.Position = UDim2.new(1, -12, 0.5, 0)
	statusPill.Size = UDim2.new(0, 34, 0, 24)
	statusPill.Font = Enum.Font.GothamBold
	statusPill.Text = "GO"
	statusPill.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusPill.TextSize = 11
	statusPill.Parent = card
	createCorner(statusPill, 12)

	card.MouseEnter:Connect(function()
		tween(card, { BackgroundColor3 = Color3.fromRGB(37, 44, 66) })
	end)

	card.MouseLeave:Connect(function()
		if not card:GetAttribute("Selected") then
			tween(card, { BackgroundColor3 = Color3.fromRGB(29, 34, 51) })
		end
	end)

	card.Activated:Connect(function()
		onSelected(morph.id)
	end)

	return card
end

function MorphUI.Start(config)
	local player = config.player or Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local requestMorphRemote = config.requestMorphRemote
	local initialState = config.initialState

	local activeMorphId = initialState.activeMorphId or "human"
	local morphs = {
		{
			id = "human",
			displayName = "Human",
			icon = "HU",
			description = "Reset your look and abilities back to normal.",
			themeColor = Color3.fromRGB(79, 118, 255),
		},
	}

	for _, morph in ipairs(initialState.morphs or {}) do
		table.insert(morphs, morph)
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LTW_MorphSystemUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "MorphToggle"
	toggleButton.AnchorPoint = Vector2.new(0, 0.5)
	toggleButton.AutoButtonColor = false
	toggleButton.BackgroundColor3 = Color3.fromRGB(18, 23, 37)
	toggleButton.Position = UDim2.new(0, 18, 0.5, 0)
	toggleButton.Size = UDim2.new(0, 72, 0, 72)
	toggleButton.Text = ""
	toggleButton.Parent = screenGui
	createCorner(toggleButton, 24)
	createStroke(toggleButton, Color3.fromRGB(255, 255, 255), 1.5, 0.78)

	local buttonConstraint = Instance.new("UISizeConstraint")
	buttonConstraint.MinSize = Vector2.new(64, 64)
	buttonConstraint.MaxSize = Vector2.new(88, 88)
	buttonConstraint.Parent = toggleButton

	local buttonGradient = Instance.new("UIGradient")
	buttonGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 74, 160)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(31, 171, 180)),
	})
	buttonGradient.Rotation = 125
	buttonGradient.Parent = toggleButton

	local buttonLabel = Instance.new("TextLabel")
	buttonLabel.BackgroundTransparency = 1
	buttonLabel.Font = Enum.Font.GothamBlack
	buttonLabel.Text = "M"
	buttonLabel.TextColor3 = Color3.fromRGB(255, 251, 245)
	buttonLabel.TextScaled = true
	buttonLabel.Position = UDim2.new(0, 16, 0, 10)
	buttonLabel.Size = UDim2.new(0, 40, 0, 34)
	buttonLabel.Parent = toggleButton

	local buttonSubLabel = Instance.new("TextLabel")
	buttonSubLabel.BackgroundTransparency = 1
	buttonSubLabel.Font = Enum.Font.GothamBold
	buttonSubLabel.Text = "Morph"
	buttonSubLabel.TextColor3 = Color3.fromRGB(244, 249, 255)
	buttonSubLabel.TextSize = 14
	buttonSubLabel.Position = UDim2.new(0, 12, 0, 42)
	buttonSubLabel.Size = UDim2.new(1, -24, 0, 18)
	buttonSubLabel.Parent = toggleButton

	local activeBadge = Instance.new("TextLabel")
	activeBadge.Name = "ActiveBadge"
	activeBadge.AnchorPoint = Vector2.new(0, 0.5)
	activeBadge.BackgroundColor3 = Color3.fromRGB(13, 17, 29)
	activeBadge.Position = UDim2.new(0, 78, 0.5, 0)
	activeBadge.Size = UDim2.new(0, 72, 0, 28)
	activeBadge.Font = Enum.Font.GothamBold
	activeBadge.Text = "Human"
	activeBadge.TextColor3 = Color3.fromRGB(248, 251, 255)
	activeBadge.TextSize = 12
	activeBadge.Parent = toggleButton
	createCorner(activeBadge, 14)
	createStroke(activeBadge, Color3.fromRGB(255, 255, 255), 1, 0.86)

	local panel = Instance.new("Frame")
	panel.Name = "MorphPanel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(13, 17, 29)
	panel.Position = UDim2.new(0, PANEL_CLOSED_X, 0.5, 0)
	panel.Size = UDim2.new(0, PANEL_WIDTH, 0, 320)
	panel.Parent = screenGui
	createCorner(panel, 26)
	createStroke(panel, Color3.fromRGB(255, 255, 255), 1, 0.85)

	local panelConstraint = Instance.new("UISizeConstraint")
	panelConstraint.MinSize = Vector2.new(250, 280)
	panelConstraint.MaxSize = Vector2.new(300, 360)
	panelConstraint.Parent = panel

	local panelGradient = Instance.new("UIGradient")
	panelGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 18, 34)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 33, 52)),
	})
	panelGradient.Rotation = 90
	panelGradient.Parent = panel

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.Text = "Choose Your Morph"
	header.TextColor3 = Color3.fromRGB(245, 246, 252)
	header.TextSize = 22
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Position = UDim2.new(0, 18, 0, 18)
	header.Size = UDim2.new(1, -72, 0, 28)
	header.Parent = panel

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.AutoButtonColor = false
	closeButton.BackgroundColor3 = Color3.fromRGB(35, 42, 63)
	closeButton.Position = UDim2.new(1, -18, 0, 18)
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(234, 238, 248)
	closeButton.TextSize = 14
	closeButton.Parent = panel
	createCorner(closeButton, 10)
	createStroke(closeButton, Color3.fromRGB(255, 255, 255), 1, 0.88)

	local subHeader = Instance.new("TextLabel")
	subHeader.BackgroundTransparency = 1
	subHeader.Font = Enum.Font.Gotham
	subHeader.Text = "Switch forms instantly. Space rises while flying."
	subHeader.TextColor3 = Color3.fromRGB(176, 185, 209)
	subHeader.TextSize = 13
	subHeader.TextWrapped = true
	subHeader.TextXAlignment = Enum.TextXAlignment.Left
	subHeader.TextYAlignment = Enum.TextYAlignment.Top
	subHeader.Position = UDim2.new(0, 18, 0, 50)
	subHeader.Size = UDim2.new(1, -36, 0, 34)
	subHeader.Parent = panel

	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.CanvasSize = UDim2.new()
	scrollingFrame.ScrollBarThickness = 4
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(104, 121, 171)
	scrollingFrame.Position = UDim2.new(0, 18, 0, 98)
	scrollingFrame.Size = UDim2.new(1, -36, 1, -116)
	scrollingFrame.Parent = panel

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = scrollingFrame

	local cardsById = {}
	local morphsById = {}
	local isOpen = false

	for _, morph in ipairs(morphs) do
		morphsById[morph.id] = morph
	end

	local function refreshSelection(nextMorphId)
		activeMorphId = nextMorphId
		local activeMorph = morphsById[activeMorphId] or morphsById.human
		if activeMorph then
			activeBadge.Text = activeMorph.displayName
			activeBadge.BackgroundColor3 = getThemeColor(activeMorph)
		end

		for morphId, card in pairs(cardsById) do
			local selected = morphId == activeMorphId
			card:SetAttribute("Selected", selected)
			local status = card:FindFirstChild("Status")
			local accent = card:FindFirstChild("Accent")

			if selected then
				tween(card, { BackgroundColor3 = Color3.fromRGB(42, 53, 84) })
				if status then
					status.BackgroundColor3 = getThemeColor({
						themeColor = accent and accent.BackgroundColor3 or Color3.fromRGB(79, 118, 255),
					})
					status.Text = "ON"
				end
			else
				tween(card, { BackgroundColor3 = Color3.fromRGB(29, 34, 51) })
				if status then
					status.BackgroundColor3 = Color3.fromRGB(61, 70, 104)
					status.Text = "GO"
				end
			end
		end
	end

	local function togglePanel(forceOpen)
		if forceOpen ~= nil then
			isOpen = forceOpen
		else
			isOpen = not isOpen
		end

		local targetX = isOpen and PANEL_OPEN_X or PANEL_CLOSED_X
		tween(panel, { Position = UDim2.new(0, targetX, 0.5, 0) })
		tween(toggleButton, { Position = UDim2.new(0, isOpen and BUTTON_OPEN_X or BUTTON_CLOSED_X, 0.5, 0) })
		tween(toggleButton, { Rotation = isOpen and 8 or 0 })
	end

	for _, morph in ipairs(morphs) do
		local card = buildCard(scrollingFrame, morph, function(selectedId)
			requestMorphRemote:FireServer(selectedId)
			refreshSelection(selectedId)
		end)
		cardsById[morph.id] = card
	end

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	end)
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)

	toggleButton.Activated:Connect(function()
		togglePanel()
	end)

	closeButton.Activated:Connect(function()
		togglePanel(false)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.M then
			togglePanel()
		elseif input.KeyCode == Enum.KeyCode.Escape and isOpen then
			togglePanel(false)
		end
	end)

	player:GetAttributeChangedSignal("LTW_ActiveMorphId"):Connect(function()
		local updatedMorphId = player:GetAttribute("LTW_ActiveMorphId")
		if updatedMorphId then
			refreshSelection(updatedMorphId)
		end
	end)

	refreshSelection(activeMorphId)
end

return MorphUI
