local types = require("./types")

local function full(self: types.Feces, group: types.Group?): types.Applyable
	local data = {} :: types.Applyable
	group = group or self

	local function addEntity(component, player, entity: types.LocalEntity, value: any, action: types.ChangeType?)
		if player then
			return -- we only want publicly replicated data
		end
		local lookup: types.LookupEntity = (group :: types.Group).lookups[entity]
		if lookup == nil then
			return -- we only want the entities that are in this group
		end

		data[component] = data[component] or { [lookup] = {} }
		if not data[component][lookup] then
			data[component][lookup] = { }
		end

		data[component][lookup].action = action
		data[component][lookup].value = value
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
			if id == self.replicated then
				continue
			end
			local column = columns[key]
			if not column then
				continue
			end

			for row, entity in entities do
				local player = playerColumn[row]
				addEntity(id :: any, player, entity :: any, column[row])
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
			if not self.jecs.IS_PAIR(id :: any) then
				continue
			end

			if self.jecs.pair_first(self.world, id :: any) ~= self.replicated then
				continue -- it's a pair but the first component isn't replicated e.g pair(someComponent, someOtherComponent) instead of pair(replicated, someOtherComponent)
			end

			local record = records[id]
			if not record then
				continue
			end

			local playerColumn = archetype.columns[record]
			local component: types.Component = self.jecs.pair_second(self.world, id :: any) :: any
			for row, entity in entities do
				if not (self.world.has :: any)(self.world, entity, component) then
					continue -- what has my life become
				end

				addEntity(
					component,
					playerColumn[row],
					entity :: any,
					(self.world.get :: any)(self.world, entity, component)
				)
			end
		end
	end

	return data
end

return full