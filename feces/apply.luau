local types = require("./types")

local function apply(self: types.Feces, delta: types.Applyable, group: types.Group?)
	if not delta then
		return
	end

	group = group or self
	for component, entities in delta do
		if component == types.Delete then
			for _, lookupEntity: types.LookupEntity in entities do
				local entity = group.refs[lookupEntity] :: types.LocalEntity?
				if entity == nil then
					continue
				end
				if self._hooks.deleted then
					self._hooks.deleted(entity)
				end
				self.world:delete(entity)
			end
			continue
		end

		local newEntities: { [types.LocalEntity]: true } = {}

		for lookupEntity, info in entities do
			local action, value = info.action, info.value
			local existed = group.refs[lookupEntity]
			local entity: types.LocalEntity = self:ref(lookupEntity, group)

			if not existed and self._hooks.added then
				newEntities[entity] = true
			end

			if action == types.Remove then
				if self._hooks.removed then
					self._hooks.removed(entity, component)
				end
				self.world:remove(entity, component)
			end
			
			local newValue = if action == types.None then nil else value
			if self._hooks.changed then
				self._hooks.changed(entity, component, newValue)
			end
		end

		if self._hooks.added then
			for entity, _ in newEntities do
				self._hooks.added(entity)
			end
		end
	end
end

return apply