--!optimize 2
--[=[
	@class feces
	The feces library for replicating jecs entities and components.
]=]
local Players = game and game:GetService("Players")
local isServer = not game or game:GetService("RunService"):IsServer()

type Entity<T = any> = number & { __t: T }

type LocalEntity = Entity
type LookupEntity = Entity
type Component<T = any> = jecs.Entity<T> & number

type nilValue = "__n"
local NIL_VALUE: nilValue = "__n"

type deleteValue = "__d"
local DELETE_VALUE: deleteValue = "__d"

type PlayerObject = Player? | { Player } | (Player) -> boolean
type refs = { [string]: Entity }
type group = {
	origin: string,
	size: number,
	lookups: { [LocalEntity]: LookupEntity }, -- get the replicatable lookup id from an entity in this world
	refs: { [LookupEntity]: LocalEntity }, -- get the entity from this world from its replication lookup id
}
--[=[ 
	@within feces
	@type changes { [Component]: { [Player]: { value: { [Entity]: any }, special: { [Entity]: deleteValue | nilValue } } } }
	How changes are represented and returned from [`delta()`](/api/feces#delta).
]=]
type changes = {
	[Component]: {
		[Player]: {
			value: { [Entity]: any },
			remove: { [Entity]: deleteValue },
			none: { [Entity]: nilValue },
		},
	},
}
--[=[
	@type deletes { [Player]: { Entity } }
	@within feces
	How deleted entities are represented.
]=]
type deletes = {
	[Player]: { Entity },
}
--[=[
	@type applyable { [Component]: { value: { [Entity]: any }, special: { [Entity]: deleteValue | nilValue } } } & { __d: { Entity } }
	@within feces
	Funkier type for how applyable changes should be formated.
]=]
type applyable = {
	[Component]: {
		value: { [LookupEntity]: any },
		remove: { [LookupEntity]: deleteValue },
		none: { [LookupEntity]: deleteValue },
	},
} & { __d: { LookupEntity } }

export type lib = {
	new: (any) -> feces,
	combine: (changes, deletes?) -> { [Player]: applyable },
	reserve: (size: number) -> group, -- creates a group of entities with a separate lookup 
}

export type feces = lib & group & {
	replicated: jecs.Component<PlayerObject>,
	grouped: jecs.Component<group>,
	queries: {
		single: jecs.Query,
		pair: jecs.Query,
	},
	world: jecs.World,
	pendingChanges: changes,
	pendingDeletes: deletes,
    storages: { [Component]: { [Entity]: { value: any, players: { Player } } } },

	lookup: (self: feces, key: LocalEntity?, group: group?) -> LookupEntity,
	ref: (self: feces, key: LookupEntity?, group: group?) -> LocalEntity,
	-- replicating: (self: feces, (Component, PlayerObject, Entity, any, Component) -> nil) -> nil,

	apply: (self: feces, delta: applyable, group: group?) -> nil, -- applies component changes to world
	delta: (self: feces, group: group?) -> (changes, deletes), -- gets the component changes and entity deletions to replicate
	full: (self: feces, group: group?) -> applyable, -- gets all currently replicating components

	-- hooks into applying replication
	added: (self: feces, (Entity) -> nil) -> nil,
	changed: (self: feces, (Entity, Component, any) -> nil) -> nil,
	removed: (self: feces, (Entity, Component) -> nil) -> nil,
	deleted: (self: feces, (Entity) -> nil) -> nil,
	hooks: {
		added: ((Entity) -> nil)?,
		changed: ((Entity, Component, any) -> nil)?,
		removed: ((Entity, Component) -> nil)?,
		deleted: ((Entity) -> nil)?,
	},
}

local lib = {}

local function resolvePlayers(filter: PlayerObject): { Player? }
    if type(filter) == "function" then
        local out = {}
        for _, player in (if game then Players:GetPlayers() else { "-1" }) do
            if filter(player) then
                table.insert(out, player)
            end
        end
        return out
    elseif type(filter) == "table" then
        return filter
    elseif typeof(filter) == "Instance" then
        return { filter }
    else
		return if game then Players:GetPlayers() else { "-1" }
    end
end

local function fill(changes: changes, comp: Component, ent: LookupEntity, value: any, players: { Player })
	if not comp or not ent then
		warn("[feces] Cannot fill changes with nil component or entity.")
        return
	end

	for _, player in players do
        changes[comp] = changes[comp] or {}
		if game and (typeof(player) ~= "Instance" or not player:IsDescendantOf(Players)) then
            continue
        end

        local entry = changes[comp][player] or { value = {}, special = {} }
        if value == DELETE_VALUE or value == NIL_VALUE then
            entry.special[ent] = value
        else
            entry.value[ent] = value
        end
        changes[comp][player] = entry
	end
end


-- local group helper functions
local function addToGroup(group: group, entity: LocalEntity): LookupEntity
	table.insert(group.refs, entity)
	local index = table.find(group.refs, entity) :: LookupEntity
	group.lookups[entity] = index
	self.world:set(entity, self.grouped, group)
	if #group.refs >= group.size then
		warn("[feces] Group is full, consider reserving a larger group size.\n\tA group created at {group.origin} exceeded {group.size}")
	end
	return index
end

local function removeFromGroup(group: group, entity: LocalEntity)
	if #group.lookups == 0 then
		warn("[feces] Group is empty, cannot remove the entity {entity} from the group.\n\tA group created at {group.origin} was empty when trying to remove entity {entity}")
	end
	self.world:remove(entity, self.grouped)
	table.remove(group.refs, entity)
	group.lookups[entity] = nil
end


-- group functionality
local function ref(self: feces, key: LookupEntity?, group: group?): LocalEntity
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

local function lookup(self: feces, entity: LocalEntity?, group: group?): LookupEntity
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
local function reserve(size: number): group
	local scrpt, line, name = debug.info(3, "sln")
	local origin = `{scrpt}:{line} {name}()`
	print("[feces] reserving group", origin, size)
	return {
		origin = origin,
		size = size,
		lookups = {},
	}
end

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
local function apply(self: feces, delta: applyable, group: group?)
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
local function delta(self: feces, group: group?): (changes, deletes)
    local changes, deletedMap = self.pendingChanges, self.pendingDeletes
	group = group or self
	-- print("FULL STORAGES", self.storages)
    for comp, storage in self.storages do
		if comp == self.replicated or comp == self.grouped then
			continue
		end

        for ent: LocalEntity, data in storage do
			if ent == self.replicated or ent == self.grouped then
				continue
			end

			local lookup: LookupEntity = group.lookups[ent]
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

    local deleted: deletes = {}
    for player, entities in deletedMap do
        deleted[player] = {}
        for entity, _ in entities do
			local lookup: LookupEntity = group.lookups[entity]
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
local function combine(changes: changes, deleted: deletes?): { [Player]: applyable }
	local packets: { [Player]: applyable } = {}

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

local function full(self: Feces, group: group?): applyable
	local data = {} :: applyable
	group = group or self

	local function addEntity(component, player, entity: LocalEntity, value: any)
		if player then
			return -- we only want publicly replicated data
		end
		local lookup: LookupEntity = group.lookups[entity]
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
				addEntity(id :: Component, player, entity :: LocalEntity, column[row])
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
				if not self.world:has(entity :: Entity, component :: Component) then
					continue
				end

				addEntity(
					component :: Component,
					playerColumn[row],
					entity :: Entity,
					self.world:get(entity :: Entity, component :: Component)
				)
			end
		end
	end

	return data
end
--[=[
	@within feces
	Adds a callback for when an entity is added to the world through [`apply()`](/api/feces#apply).
	Called *after* **a** (not all) component value is set to a newly replicated entity.
	See how you might use this [here](/docs/hooks#added).
]=]
local function added(self: feces, callback: (Entity) -> nil)
	self.hooks.added = callback
end
--[=[
	@within feces
	Adds a callback for when a component value is changed in the world through [`apply()`](/api/feces#apply).  
	Called *before* the component in question is changed, deleted, or set to `nil`.
	See how you might use this [here](/docs/hooks#changed).
]=]
local function changed(self: feces, callback: (Entity, Component, any) -> nil)
	self.hooks.changed = callback
end
--[=[
	@within feces
	Adds a callback for when a component is removed in the world through [`apply()`](/api/feces#apply).   
	Called *before* the component in question is removed.
	See how you might use this [here](/docs/hooks#removed).
]=]
local function removed(self: feces, callback: (Entity, Component) -> nil)
	self.hooks.removed = callback
end
--[=[
	@within feces
	Adds a callback for when an entity is deleted in the world through [`apply()`](/api/feces#apply).   
	Called *before* the entity in question is deleted, allowing hooks to get component values and clean up.
	See how you might use this [here](/docs/hooks#deleted).
]=]
local function deleted(self: feces, callback: (Entity) -> nil)
	self.hooks.deleted = callback
end

function lib.new(jecs: jecs, world: World, group: group?): feces
	--assume the user has already added observers to the world
	local replicated = world:component()
	local grouped = world:component()
	jecs = testing_jecs or jecs
	world:set(replicated, jecs.Name, "replicated")
	world:set(replicated, jecs.Name, "grouped")
	local self = {
		size = math.huge,
		jecs = jecs,
		replicated = replicated,
		queries = {
			single = world:query(replicated):cached(),
			pair = world:query(pair(replicated, __)):cached(),
		},
		world = world,
		pendingChanges = {} :: changes,
		pendingDeletes = {} :: { [Player]: { [Entity]: true } },
		hooks = {},
		refs = refs or {},
        storages = {},
		ref = ref,
		apply = apply,
		delta = delta,
		full = full,
		combine = combine,
		added = added,
		changed = changed,
		removed = removed,
		deleted = deleted,
	} :: feces
	
	if isServer then
        local function listen(comp)
            if self.storages[comp] then
				return
			end

            self.storages[comp] = {}
            local isTag = jecs.is_tag(world, comp)
            -- value hook
            world:added(comp, function(ent, _, val)
                self.storages[comp][ent] = { value = val, players = if game then Players:GetPlayers() else { "-1" } }
            end)

            if not isTag then
                world:changed(comp, function(ent, _, val)
                    self.storages[comp][ent] = { value = val, players = if game then Players:GetPlayers() else { "-1" } }
                end)
            end

			world:removed(comp, function(ent)
                self.storages[comp][ent] = { value = DELETE_VALUE, players = if game then Players:GetPlayers() else { "-1" } }
            end)
        end

        for comp in world.component_index do
            if comp ~= replicated and not (jecs.IS_PAIR(comp) and jecs.pair_first(world, comp) == replicated) then
                listen(comp)
            end
        end

        setmetatable(world.component_index, {
            __newindex = function(tbl, comp, val)
                rawset(tbl, comp, val)
                if val and comp ~= replicated
                   and not (jecs.IS_PAIR(comp) and jecs.pair_first(world, comp) == replicated)
                then
                    listen(comp)
                end
            end,
        })

		world:removed(replicated, function(ent, filter)
            for _, player in resolvePlayers(filter) do
                self.pendingDeletes[player] = self.pendingDeletes[player] or {}
                self.pendingDeletes[player][ent] = true
                -- table.insert(self.pendingDeletes[player], ent)
            end
        end)
    end

	return self :: feces
end

return lib :: lib