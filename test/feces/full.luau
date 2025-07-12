local types = require("./types")

local function full(self: types.Feces, group: types.Group?): types.Applyable
	local data = {} :: types.Applyable
	group = group or self

	local function addEntity(component, player, entity: LocalEntity, value: any)
		if player then
			return -- we only want publicly replicated data
		end
		local lookup: types.LookupEntity = group.lookups[entity]
		if not lookup then
			return -- we only want the entities that are in this group
		end

		value = value or NIL_VALUE
		data[component] = data[component] or { value = {}, special = {} }
		if value == DELETE_VALUE or value == NIL_VALUE then
			(data[component].special :: any)[lookup] = value
		else
			(data[component].value :: any)[lookup] = value
		end
	end


	for _, archetype in self.queries.single:archetypes() do
		local entities = archetype.entities
		if #entities == 0 then
			continue
		end

		local columns = archetype.columns
		local types = archetype.types
		local record = archetype.types[self.replicated]
		if not record then
			continue
		end


		local playerColumn = columns[record]
		for key, id in types do
			if id == self.replicated :: number then
				continue
			end
			local column = columns[key]
			if not column then
				continue
			end

			for row, entity in entities do
				local player = playerColumn[row]
				addEntity(id :: types.Component, player, entity :: types.LocalEntity, column[row])
			end
		end
	end

	for _, archetype in self.queries.pair:archetypes() do
		local entities: { number } = archetype.entities
		if #entities == 0 then
			continue
		end

		local types = archetype.types
		local records = archetype.types

		for _, id in types do
			if not self.jecs.IS_PAIR(id) then
				continue
			end

			if self.jecs.pair_first(self.world, id) ~= self.replicated then
				continue -- it's a pair but the first component isn't replicated e.g pair(someComponent, someOtherComponent) instead of pair(replicated, someOtherComponent)
			end

			local record = records[id]
			if not record then
				continue
			end

			local playerColumn = archetype.columns[record]
			local component = self.jecs.pair_second(self.world, id)
			for row, entity in entities do
				if not self.world:has(entity :: types.Entity, component :: Component) then
					continue
				end

				addEntity(
					component :: Component,
					playerColumn[row],
					entity :: Entity,
					self.world:get(entity :: types.Entity, component :: Component)
				)
			end
		end
	end

	return data
end

return full