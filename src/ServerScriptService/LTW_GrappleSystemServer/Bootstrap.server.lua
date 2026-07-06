local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packageRoot = ReplicatedStorage:WaitForChild("LTW_GrappleSystem")
local shared = require(packageRoot.Shared)
local GrappleService = require(script.Parent.GrappleService)

local grappleService = GrappleService.new(shared.GrappleConfig)
grappleService:Start()
