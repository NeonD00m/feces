local types = require("@feces/types")

local function _addToGroup(self: types.Feces, group: types.Group, entity: types.LocalEntity): types.LookupEntity
	table.insert(group.refs :: { types.LocalEntity }, entity)

	local index: types.LookupEntity = table.find(group.refs :: { types.LocalEntity }, entity) :: any
	group.lookups[entity] = index
	if group ~= self then
		-- self.world:add(entity, self.grouped, group)
		self._grouped[entity] = group
	end
	if #group.refs >= group.size then
		warn(`[feces] Group is full, consider reserving a larger group size.\n\tA group created at {group.origin} exceeded {group.size}`)
	end

	return index
end

local function getGroup(self: types.Feces, entity: types.LocalEntity): types.Group
	-- self.world:get(entity, self.grouped)
	return self._grouped[entity] or self
end

local function _removeFromGroup(self: types.Feces, entity: types.LocalEntity): types.Group
	local group = getGroup(self, entity)
	if not group.lookups[entity] then
		print(`\t\ttried to remove entity from group but it wasn't in the group: {entity}`)
		return self
	end
	if #group.lookups == 0 then
		warn(`[feces] Group is empty, cannot remove the entity {entity} from the group.\n\tA group created at {group.origin} was empty when trying to remove entity {entity}`)
	end
	self._grouped[entity] = nil

	if group.lookups[entity] then
		group.refs[group.lookups[entity]] = nil
		group.lookups[entity] = nil
	end

	return group
end

local function setGroup(self: types.Feces, group: types.Group?, entity: types.LocalEntity)
	local prev = _removeFromGroup(self, entity)
	local val: types.Group = group or self
	if group and not group.lookups[entity] then
		self:debug(`->\tgroup changed: {entity}[grouped] = ({prev and prev.origin}) -> ({val.origin})`)
		_addToGroup(self, group or self, entity)
	end
end

-- group functionality
local function ref(self: types.Feces, key: types.LookupEntity?, group: types.Group?): types.LocalEntity
	local world = self.world
	group = group or self
	local entity: types.LocalEntity = if not key then (world:entity() :: any) else group.refs[key]
	
	if not group.lookups[entity] then
		setGroup(self, group, entity)
	end

	return entity
end

local function lookup(self: types.Feces, entity: types.LocalEntity?, group: types.Group?): types.LookupEntity
	local world = self.world
	local key: types.LookupEntity = nil :: any
	group = group or self
	if not entity then
		entity = world:entity() :: any
		key = _addToGroup(self, group, entity)
	else
		key = group.lookups[entity]
		if not key then
			key = _addToGroup(self, group, entity)
		end
	end

	return key
end

local function reserve(size: number): types.Group
	local scrpt, line, name = debug.info(2, "sln")
	local origin = `{scrpt}:{line} {name}()`
    
	return {
		origin = origin,
		size = size,
		lookups = {},
		refs = {},
	}
end

return {
	setGroup = setGroup,
	getGroup = getGroup,
    ref = ref,
    lookup = lookup,
    reserve = reserve,
} 