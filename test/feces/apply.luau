local types = require("./types")

local function apply(self: types.Feces, delta: types.Applyable, group: types.Group?)
	if not delta then
		return
	end

	group = group or self
	for component, entities in delta :: { [any]: any } do
		if not entities then
			continue
		end

		if component == DELETE_VALUE then
			for _, lookupEntity: types.LookupEntity in entities do
				local entity = self:ref(lookupEntity, group)
				if self.hooks.deleted then
					self.hooks.deleted(entity)
				end
				self.world:delete(entity)
			end
			continue
		end

		local newEntities: { LocalEntity } = {}

		for lookupEntity: types.LookupEntity, value in entities.value do
			if not group.refs[lookupEntity] then
				local entity: LocalEntity = self:ref(lookupEntity, group)
				if self._hooks.changed then
					self._hooks.changed(entity, component, value)
				end
				self.world:set(entity, component, value)
				if self._hooks.added then
					newEntities[entity] = true
				end
			else
				local entity: types.LocalEntity = self:ref(lookupEntity, group)
				if self._hooks.changed then
					self._hooks.changed(entity, component, value)
				end
				self.world:set(entity, component, value)
			end
		end

		for lookupEntity, value in entities.special do
			local entity: types.LocalEntity = self:ref(lookupEntity, group)

			if value == types.Remove then
				if self.hooks.removed then
					self.hooks.removed(entity, component)
				end
				self.world:remove(entity, component)
				continue
			end

			local newValue = if value == NIL_VALUE then nil else value
			if self.hooks.changed then
				self.hooks.changed(entity, component, newValue)
			end

			self.world:set(entity, component, newValue)
		end

		if self.hooks.added then
			for entity, _ in newEntities do
				self.hooks.added(entity)
			end
		end
	end
end

return apply