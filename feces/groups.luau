local types = require("@feces/types")

local function addToGroup(self: types.Feces, group: types.Group, entity: types.LocalEntity): types.LookupEntity
	table.insert(group.refs :: { types.LocalEntity }, entity)

	local index: types.LookupEntity = table.find(group.refs :: { types.LocalEntity }, entity) :: any
	group.lookups[entity] = index
	if group ~= self then
		self.world:set(entity, self.grouped, group)
	end
	if #group.refs >= group.size then
		warn("[feces] Group is full, consider reserving a larger group size.\n\tA group created at {group.origin} exceeded {group.size}")
	end

	return index
end

local function removeFromGroup(self: types.Feces, group: types.Group, entity: types.LocalEntity)
	if #group.lookups == 0 then
		warn("[feces] Group is empty, cannot remove the entity {entity} from the group.\n\tA group created at {group.origin} was empty when trying to remove entity {entity}")
	end

	self.world:remove(entity, self.grouped)

	table.remove(group.refs :: { types.LocalEntity }, entity)
	group.lookups[entity] = nil
end

-- group functionality
local function ref(self: types.Feces, key: types.LookupEntity?, group: types.Group?): types.LocalEntity
	local world = self.world
	group = group or self
	local entity: types.LocalEntity = if not key then (world:entity() :: any) else group.refs[key]
	
	if not group.lookups[entity] then
		addToGroup(self, group, entity)
	end

	return entity
end

local function lookup(self: types.Feces, entity: types.LocalEntity?, group: types.Group?): types.LookupEntity
	local world = self.world
	local key: types.LookupEntity = nil :: any
	group = group or self
	if not entity then
		entity = world:entity() :: any
		key = addToGroup(self, group, entity)
	else
		key = group.lookups[entity]
		if not key then
			key = addToGroup(self, group, entity)
		end
	end

	return key
end

local function reserve(size: number): types.Group
	local scrpt, line, name = debug.info(2, "sln")
	local origin = `{scrpt}:{line} {name}()`
	print("[feces] reserving group", origin, size)
    
	return {
		origin = origin,
		size = size,
		lookups = {},
		refs = {},
	}
end

return {
    addToGroup = addToGroup,
    removeFromGroup = removeFromGroup,
    ref = ref,
    lookup = lookup,
    reserve = reserve,
} 