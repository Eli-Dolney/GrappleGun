local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packageRoot = ReplicatedStorage:WaitForChild("LTW_GrappleSystem")
local shared = require(packageRoot.Shared)
local remotesFolder = ReplicatedStorage:WaitForChild(shared.GrappleConfig.RemoteFolderName)

local GrappleController = require(script.GrappleController)

GrappleController.Start({
	config = shared.GrappleConfig,
	requestGrappleRemote = remotesFolder:WaitForChild(shared.GrappleConfig.RequestGrappleRemote),
	grappleFiredRemote = remotesFolder:WaitForChild(shared.GrappleConfig.GrappleFiredRemote),
	getStateRemote = remotesFolder:WaitForChild(shared.GrappleConfig.GetGrappleStateRemote),
	stateChangedRemote = remotesFolder:WaitForChild(shared.GrappleConfig.StateChangedRemote),
})
