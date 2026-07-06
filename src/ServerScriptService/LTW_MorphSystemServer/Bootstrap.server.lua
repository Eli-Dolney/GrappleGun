local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packageRoot = ReplicatedStorage:WaitForChild("LTW_MorphSystem")
local shared = require(packageRoot.Shared)
local MorphService = require(script.Parent.MorphService)

local morphService = MorphService.new(shared.MorphDefinitions, shared.Remotes)
morphService:Start()

Players.PlayerRemoving:Connect(function(player)
	morphService:HandlePlayerRemoving(player)
end)
