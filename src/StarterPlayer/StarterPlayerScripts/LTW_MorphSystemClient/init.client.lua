local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local packageRoot = ReplicatedStorage:WaitForChild("LTW_MorphSystem")
local shared = require(packageRoot.Shared)
local remotesFolder = ReplicatedStorage:WaitForChild(shared.Remotes.FolderName)

local MorphUI = require(script.MorphUI)
local FlightController = require(script.FlightController)

local requestMorph = remotesFolder:WaitForChild(shared.Remotes.RequestMorph)
local getMorphState = remotesFolder:WaitForChild(shared.Remotes.GetMorphState)

local initialState = getMorphState:InvokeServer()

FlightController.Start(localPlayer)
MorphUI.Start({
	player = localPlayer,
	requestMorphRemote = requestMorph,
	initialState = initialState,
})
