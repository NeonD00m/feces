local types = require("@feces/types")

local function apply(self: types.Feces, delta: types.Applyable, group: types.Group?)
	if not delta then
		return
	end
	local hasGroup = group ~= nil
	group = group or self
	for component, entities in delta :: any do
		if component == types.Delete then
			for _, lookupEntity: types.LookupEntity in entities do
				local entity: types.LocalEntity? = if hasGroup then (group :: types.Group).refs[lookupEntity] else self:ref(lookupEntity)
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

		for lookupEntity, info in entities do
			local action, value = info.action, info.value
			local existed = (group :: types.Group).refs[lookupEntity]
			local entity: types.LocalEntity = self:ref(lookupEntity, group)

			if not existed and self._hooks.added then
			    self._hooks.added(entity)
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
	end
end

return apply
