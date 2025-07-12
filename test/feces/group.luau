local types = require("./types")

-- local group helper functions
local function addToGroup(group: types.group, entity: types.LocalEntity): types.LookupEntity
	table.insert(group.refs, entity)
	local index = table.find(group.refs, entity) :: LookupEntity
	group.lookups[entity] = index
	self.world:set(entity, self.grouped, group)
	if #group.refs >= group.size then
		warn("[feces] Group is full, consider reserving a larger group size.\n\tA group created at {group.origin} exceeded {group.size}")
	end
	return index
end

local function removeFromGroup(group: types.group, entity: types.LocalEntity)
	if #group.lookups == 0 then
		warn("[feces] Group is empty, cannot remove the entity {entity} from the group.\n\tA group created at {group.origin} was empty when trying to remove entity {entity}")
	end
	self.world:remove(entity, self.grouped)
	table.remove(group.refs, entity)
	group.lookups[entity] = nil
end

-- group functionality
local function ref(self: types.feces, key: types.LookupEntity?, group: types.group?): types.LocalEntity
	local world = self.world
	local entity: LocalEntity = nil
	group = group or self
	if not key then
		entity = world:entity()
		addToGroup(group, entity)
	else
		local entity = group.refs[key]
		if not entity then
			entity = world:entity()
			addToGroup(group, entity)
		end
	end

	return entity
end

local function lookup(self: types.feces, entity: types.LocalEntity?, group: types.group?): types.LookupEntity
	local world = self.world
	local key: LookupEntity = nil
	group = group or self
	if not entity then
		entity = world:entity()
		key = addToGroup(group, entity)
	else
		key = group.lookups[entity]
		if not key then
			key = addToGroup(group, entity)
		end
	end

	addToGroup(group or self.lookups, entity)

	return key
end

--[=[
	@within feces
	Allows more efficient replication of entity changes by grouping entities' lookup ids.
	```lua
	local playerGroup = feces:reserve(16)
	-- ...
	world:set(playerEntity, feces.grouped, playerGroup)
	-- ...
	feces:delta(playerGroup) -- get packets for only the player entities
	```
]=]
local function reserve(size: number): types.group
	local scrpt, line, name = debug.info(3, "sln") -- TODO: Remove or hide behind DEBUG variable (bad performance)
	local origin = `{scrpt}:{line} {name}()`
	print("[feces] reserving group", origin, size)
    
	return {
		origin = origin,
		size = size,
		lookups = {},
	}
end

return {
    -- addToGroup = addToGroup,
    -- removeFromGroup = removeFromGroup,
    ref = ref,
    lookup = lookup,
    reserve = reserve,
}