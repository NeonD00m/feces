local types = require("./types")

--[=[
	@within feces
	Applies changes to the world by taking in the [`applyable`](/api/feces#applyable) type and editing the world. 
	```lua
	feces:apply({
		[someComponent] = {
			[someForeignEntity] = someValue,
		}
	})
	```
]=]
local function apply(self: types.feces, delta: types.applyable, group: types.group?)
	if not delta then
	-- 	warn("NO APPLYABLE DATA RECEIVED")
		return
	end

	-- print("APPLY HAS BEEN CALLED", delta)
	group = group or self
	for component, entities in delta :: { [any]: any } do
		if not entities then
			continue
		end

		if component == DELETE_VALUE then
			for _, lookupEntity in entities do
				local entity = self:ref(lookupEntity, group)
				if self.hooks.deleted then
					self.hooks.deleted(entity)
				end
				self.world:delete(entity)
			end
			continue
		end

		local newEntities: { LocalEntity } = {}

		for lookupEntity: Entity, value in entities.value do
			if not group.refs[lookupEntity] then
				local entity: LocalEntity = self:ref(lookupEntity, group)
				if self.hooks.changed then
					self.hooks.changed(entity, component, value)
				end
				self.world:set(entity, component, value)
				if self.hooks.added then
					newEntities[entity] = true
				end
			else
				local entity: LocalEntity = self:ref(lookupEntity, group)
				if self.hooks.changed then
					self.hooks.changed(entity, component, value)
				end
				self.world:set(entity, component, value)
			end
		end

		for lookupEntity, value in entities.special do
			local entity: LocalEntity = self:ref(lookupEntity, group)

			if value == DELETE_VALUE then
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
--[=[
	@within feces
	Gets the world changes from the last time it was called.
	```lua
	local changedComponents, deletedEntities = feces:delta()
	-- ... replicate however you'd like or see the examples [here](/docs/setup)
	```
]=]
local function delta(self: types.feces, group: types.group?): (types.changes, types.deletes)
    local changes, deletedMap = self.pendingChanges, self.pendingDeletes
	group = group or self
	-- print("FULL STORAGES", self.storages)
    for comp, storage in self.storages do
		if comp == self.replicated or comp == self.grouped then
			continue
		end

        for ent: types.LocalEntity, data in storage do
			if ent == self.replicated or ent == self.grouped then
				continue
			end

			local lookup: types.LookupEntity = group.lookups[ent]
			if not lookup then
				continue -- we only want the entities that are in this group
			end

            local players = resolvePlayers(data.players) :: { Player }
            for i, player in players do
                if deletedMap[player] and deletedMap[player][ent] then
                    print("SKIPPING PLAYER FOR DELETION", player, ent)
                    players[i] = nil
                end
            end

            -- print("filling change:", ent, comp, data.value)
            fill(changes, comp, lookup, data.value, players)
        end
        table.clear(storage)
    end

    local deleted: types.deletes = {}
    for player, entities in deletedMap do
        deleted[player] = {}
        for entity, _ in entities do
			local lookup: types.LookupEntity = group.lookups[entity]
			if not lookup then
				continue -- we only want the entities that are in this group
			end

            table.insert(deleted[player], lookup)
        end
    end

    self.pendingChanges, self.pendingDeletes = {}, {}
    return changes, deleted
end
--[=[
	@within feces
	Reformats the results of [`delta()`](/api/feces#delta) into an easier format to replicate.
	Not optimal, but recommended if performance of feces-replicated entities is not a concern.
	```lua
	local dataByPlayer = feces.combine(feces:delta())
	for player, packet in dataByPlayer do
		someRemote:FireClient(player, packet)
	end
	-- see more of this example [here](/docs/setup#simple)
	```
]=]
local function combine(changes: types.changes, deleted: types.deletes?): { [Player]: types.applyable }
	local packets: { [Player]: types.applyable } = {}

	for component, players in changes do
		for player, entities in players do
			packets[player] = packets[player] or { __d = {} }
			packets[player][component] = packets[player][component] or { value = {}, special = {} }
			for entity, value in entities.value do
				(packets[player][component] :: any).value[entity] = value
			end
			for entity, value in entities.special do
				(packets[player][component] :: any).special[entity] = value
			end
		end
	end

	if deleted then
		for player, entities in deleted do
			packets[player] = packets[player] or { __d = {} }
			packets[player].__d = entities
		end
	end

	return packets
end
lib.combine = combine
--[=[
	@within feces
	Gets all the currently replicating component and entity values.
	:::tip
	This is useful for providing payloads to new players when they first join a server.
	:::
	```lua
	local changedComponents = feces:full()
	-- ... replicate however you'd like or see the examples [here](/docs/setup)
	```
]=]

local function full(self: types.feces, group: types.group?): types.applyable
	local data = {} :: types.applyable
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

return {
    apply = apply,
    delta = delta,
    full = full,
    combine = combine,
}