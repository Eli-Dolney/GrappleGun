local AppearanceService = {}

local COSMETIC_FOLDER_NAME = "LTW_MorphCosmetics"
local ORIGINAL_APPEARANCE_FOLDER_NAME = "LTW_OriginalAppearance"

local function getBodyPart(character, partNameOptions)
	for _, partName in ipairs(partNameOptions) do
		local part = character:FindFirstChild(partName)
		if part then
			return part
		end
	end

	return nil
end

local function weldPart(part, target, offset)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = target
	weld.Parent = part

	part.CFrame = target.CFrame * offset
	part.Parent = target.Parent:FindFirstChild(COSMETIC_FOLDER_NAME)
end

local function ensureCosmeticFolder(character)
	local folder = character:FindFirstChild(COSMETIC_FOLDER_NAME)
	if folder then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = COSMETIC_FOLDER_NAME
	folder.Parent = character
	return folder
end

local function ensureOriginalAppearanceFolder(character)
	local folder = character:FindFirstChild(ORIGINAL_APPEARANCE_FOLDER_NAME)
	if folder then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = ORIGINAL_APPEARANCE_FOLDER_NAME
	folder.Parent = character
	return folder
end

local function saveOriginalBodyColors(character)
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		return
	end

	local originalFolder = ensureOriginalAppearanceFolder(character)
	if originalFolder:FindFirstChild("BodyColors") then
		return
	end

	local clone = bodyColors:Clone()
	clone.Name = "BodyColors"
	clone.Parent = originalFolder
end

local function replaceBodyColors(character, bodyColors)
	local existingBodyColors = character:FindFirstChildOfClass("BodyColors")
	if existingBodyColors then
		existingBodyColors:Destroy()
	end

	if bodyColors then
		bodyColors:Clone().Parent = character
	end
end

local function applyBodyColors(character, appearance)
	saveOriginalBodyColors(character)

	local bodyColors = Instance.new("BodyColors")
	for key, brickColorName in pairs(appearance.bodyColors or {}) do
		bodyColors[key] = BrickColor.new(brickColorName)
	end
	replaceBodyColors(character, bodyColors)
end

local function createCosmeticPart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Anchored = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function applyDragonCosmetics(character, themeColor)
	local folder = ensureCosmeticFolder(character)
	local torso = getBodyPart(character, { "UpperTorso", "Torso" })
	local head = getBodyPart(character, { "Head" })

	if not torso or not head then
		return
	end

	local leftWing = Instance.new("WedgePart")
	leftWing.Name = "DragonWingLeft"
	leftWing.Size = Vector3.new(0.6, 3.6, 5.5)
	leftWing.Color = themeColor
	leftWing.Material = Enum.Material.Neon
	leftWing.CanCollide = false
	leftWing.CanTouch = false
	leftWing.CanQuery = false
	leftWing.Anchored = false
	leftWing.Massless = true
	leftWing.TopSurface = Enum.SurfaceType.Smooth
	leftWing.BottomSurface = Enum.SurfaceType.Smooth
	leftWing.Parent = folder
	weldPart(leftWing, torso, CFrame.new(-1.7, 0.8, 0.8) * CFrame.Angles(0, math.rad(180), math.rad(18)))

	local rightWing = Instance.new("WedgePart")
	rightWing.Name = "DragonWingRight"
	rightWing.Size = Vector3.new(0.6, 3.6, 5.5)
	rightWing.Color = themeColor
	rightWing.Material = Enum.Material.Neon
	rightWing.CanCollide = false
	rightWing.CanTouch = false
	rightWing.CanQuery = false
	rightWing.Anchored = false
	rightWing.Massless = true
	rightWing.TopSurface = Enum.SurfaceType.Smooth
	rightWing.BottomSurface = Enum.SurfaceType.Smooth
	rightWing.Parent = folder
	weldPart(rightWing, torso, CFrame.new(1.7, 0.8, 0.8) * CFrame.Angles(0, 0, math.rad(-18)))

	local hornLeft = createCosmeticPart("DragonHornLeft", Vector3.new(0.2, 0.8, 0.2), Color3.fromRGB(255, 224, 163), Enum.Material.SmoothPlastic)
	hornLeft.Parent = folder
	weldPart(hornLeft, head, CFrame.new(-0.3, 0.55, -0.15) * CFrame.Angles(math.rad(-30), 0, math.rad(20)))

	local hornRight = createCosmeticPart("DragonHornRight", Vector3.new(0.2, 0.8, 0.2), Color3.fromRGB(255, 224, 163), Enum.Material.SmoothPlastic)
	hornRight.Parent = folder
	weldPart(hornRight, head, CFrame.new(0.3, 0.55, -0.15) * CFrame.Angles(math.rad(-30), 0, math.rad(-20)))

	local highlight = Instance.new("Highlight")
	highlight.Name = "DragonHighlight"
	highlight.FillColor = themeColor
	highlight.FillTransparency = 0.82
	highlight.OutlineColor = Color3.fromRGB(255, 214, 168)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = folder
	highlight.Adornee = character
end

local function applyGoblinCosmetics(character, themeColor)
	local folder = ensureCosmeticFolder(character)
	local head = getBodyPart(character, { "Head" })
	local torso = getBodyPart(character, { "UpperTorso", "Torso" })

	if not head or not torso then
		return
	end

	local earLeft = Instance.new("WedgePart")
	earLeft.Name = "GoblinEarLeft"
	earLeft.Size = Vector3.new(0.45, 1.2, 0.5)
	earLeft.Color = themeColor
	earLeft.Material = Enum.Material.SmoothPlastic
	earLeft.CanCollide = false
	earLeft.CanTouch = false
	earLeft.CanQuery = false
	earLeft.Anchored = false
	earLeft.Massless = true
	earLeft.TopSurface = Enum.SurfaceType.Smooth
	earLeft.BottomSurface = Enum.SurfaceType.Smooth
	earLeft.Parent = folder
	weldPart(earLeft, head, CFrame.new(-0.7, 0.35, 0) * CFrame.Angles(0, math.rad(90), math.rad(18)))

	local earRight = Instance.new("WedgePart")
	earRight.Name = "GoblinEarRight"
	earRight.Size = Vector3.new(0.45, 1.2, 0.5)
	earRight.Color = themeColor
	earRight.Material = Enum.Material.SmoothPlastic
	earRight.CanCollide = false
	earRight.CanTouch = false
	earRight.CanQuery = false
	earRight.Anchored = false
	earRight.Massless = true
	earRight.TopSurface = Enum.SurfaceType.Smooth
	earRight.BottomSurface = Enum.SurfaceType.Smooth
	earRight.Parent = folder
	weldPart(earRight, head, CFrame.new(0.7, 0.35, 0) * CFrame.Angles(0, math.rad(-90), math.rad(-18)))

	local satchel = createCosmeticPart("GoblinSatchel", Vector3.new(1.1, 1.2, 0.35), Color3.fromRGB(103, 74, 42), Enum.Material.Fabric)
	satchel.Parent = folder
	weldPart(satchel, torso, CFrame.new(-0.75, -0.1, 0.55) * CFrame.Angles(math.rad(10), 0, math.rad(18)))

	local highlight = Instance.new("Highlight")
	highlight.Name = "GoblinHighlight"
	highlight.FillColor = themeColor
	highlight.FillTransparency = 0.88
	highlight.OutlineColor = Color3.fromRGB(199, 255, 173)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = folder
	highlight.Adornee = character
end

function AppearanceService.Clear(character)
	local cosmeticFolder = character:FindFirstChild(COSMETIC_FOLDER_NAME)
	if cosmeticFolder then
		cosmeticFolder:Destroy()
	end

	local originalFolder = character:FindFirstChild(ORIGINAL_APPEARANCE_FOLDER_NAME)
	local originalBodyColors = originalFolder and originalFolder:FindFirstChild("BodyColors")
	if originalBodyColors then
		replaceBodyColors(character, originalBodyColors)
	end
end

function AppearanceService.Apply(character, morphDefinition)
	local appearance = morphDefinition.appearance or {}

	applyBodyColors(character, appearance)

	if appearance.cosmetic == "Dragon" then
		applyDragonCosmetics(character, appearance.themeColor or Color3.fromRGB(203, 64, 47))
	elseif appearance.cosmetic == "Goblin" then
		applyGoblinCosmetics(character, appearance.themeColor or Color3.fromRGB(88, 153, 73))
	end
end

return AppearanceService
