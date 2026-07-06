local MorphRegistry = {}
MorphRegistry.__index = MorphRegistry

function MorphRegistry.new()
	return setmetatable({
		_byId = {},
		_ordered = {},
	}, MorphRegistry)
end

function MorphRegistry:Register(morphDefinition)
	assert(type(morphDefinition) == "table", "Morph definition must be a table")
	assert(type(morphDefinition.id) == "string", "Morph definition requires an id")

	self._byId[morphDefinition.id] = morphDefinition
	table.insert(self._ordered, morphDefinition)
end

function MorphRegistry:RegisterMany(definitions)
	for _, definition in ipairs(definitions) do
		self:Register(definition)
	end
end

function MorphRegistry:Get(id)
	return self._byId[id]
end

function MorphRegistry:List()
	return self._ordered
end

return MorphRegistry
