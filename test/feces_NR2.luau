--!optimize 2
--[=[
	@class feces
	The feces library for replicating jecs entities and components.
]=]
local Players = game and game:GetService("Players")
local isServer = game and game:GetService("RunService"):IsServer()
local jecs = require(if game then "./roblox_packages/jecs" else "../luau_packages/jecs")
local observers = game and require("../../../killergg+jecs_observers/0.1.0/jecs_observers/src")
type World = observers.PatchedWorld

local pair = jecs.pair
local __ = jecs.Wildcard

type Entity = jecs.Entity & number
type Component<T = any> = jecs.Entity<T> & number

type nilValue = "__n"
local NIL_VALUE: nilValue = "__n"

type deleteValue = "__d"
local DELETE_VALUE: deleteValue = "__d"

type PlayerObject = Player? | { Player } | (Player) -> boolean

--[=[ 
	@within feces
	@type changes { [Component]: { [Player]: { value: { [Entity]: any }, special: { [Entity]: deleteValue | nilValue } } } }
	How changes are represented and returned from [`delta()`](/api/feces#delta).
]=]
type changes = {
	[Component]: {
		[Player]: {
			value: { [Entity]: any },
			special: { [Entity]: deleteValue | nilValue },
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
		value: { [Entity]: any },
		special: { [Entity]: deleteValue | nilValue },
	},
} & { __d: { Entity } }

export type lib = {
	new: (jecs.World) -> feces,
	group: (changes, deletes?) -> { [Player]: applyable },
}

export type feces = lib & {
	replicated: jecs.Component,
	queries: {
		single: jecs.Query,
		pair: jecs.Query,
	},
	world: jecs.World,
	pendingChanges: changes,
	pendingDeletes: deletes,
	refs: { [string]: Entity },

	ref: (self: feces, key: string?) -> Entity,
	replicating: (self: feces, (Component, PlayerObject, Entity, any, Component) -> nil) -> nil,

	apply: (self: feces, applyable) -> nil, -- applies component changes to world
	delta: (self: feces) -> (changes, deletes), -- gets the component changes to replicate

	-- gets the entity deletions to replicate
	full: (self: feces) -> applyable, -- gets all currently replicating components
	group: (changes, deletes?) -> { [Player]: applyable },

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

local storages = {}

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

local previous = {}

local function fill(changes: changes, comp: Component, ent: Entity, value: any, players: { Player }, replicated)
	if not comp or not ent then
		return
	end
	
	if comp == replicated or ent == replicated then
		return
	end

	changes[comp] = changes[comp] or {}
	previous[comp] = previous[comp] or {}

	players = resolvePlayers(players)

	for _, player in players do
		 if typeof(player) ~= "Instance" or not player:IsDescendantOf(Players) then
            continue
        end

        local entry = changes[comp][player] or { value = {}, special = {} }
        if value == DELETE_VALUE or value == NIL_VALUE then
            entry.special[ent] = value
        else
            previous[comp][ent] = value
            entry.value   [ent] = value
        end
        changes[comp][player] = entry
	end
end

local function ref(self: feces, key: string?): Entity
	local world = self.world
	if not key then
		return world:entity()
	end

	local refs = self.refs
	local entity = refs[key]
	if not entity then
		entity = world:entity()
		refs[key] = entity
	end

	return entity
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
local function apply(self: feces, delta: applyable)
	if not delta then
		warn("NO APPLYABLE DATA RECEIVED")
		return
	end

	print("APPLY HAS BEEN CALLED", delta)

	for component, entities in delta :: { [any]: any } do
		if not entities then
			continue
		end

		if component == DELETE_VALUE then
			for _, entity in entities do
				local id = self:ref(`repl{entity}`)
				if self.hooks.deleted then
					self.hooks.deleted(id)
				end
				self.world:delete(id)
			end
			continue
		end

		local newEntities = {}

		for entity: Entity, value in entities.value do
			if not self.refs[`repl{entity}`] then
				local id = self:ref(`repl{entity}`)
				if self.hooks.changed then
					self.hooks.changed(id, component, value)
				end
				self.world:set(id, component, value)
				if self.hooks.added then
					newEntities[id] = true
				end
			else
				local id = self:ref(`repl{entity}`)
				if self.hooks.changed then
					self.hooks.changed(id, component, value)
				end
				self.world:set(id, component, value)
			end
		end

		for entity: Entity, value in entities.special do
			local id = self:ref(`repl{entity}`)

			if value == DELETE_VALUE then
				if self.hooks.removed then
					self.hooks.removed(id, component)
				end
				self.world:remove(id, component)
				continue
			end

			local newValue = if value == NIL_VALUE then nil else value
			if self.hooks.changed then
				self.hooks.changed(id, component, newValue)
			end

			self.world:set(id, component, newValue)
		end

		if self.hooks.added then
			for id, _ in newEntities do
				self.hooks.added(id)
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
local function delta(self: feces): (changes, deletes)
	print("FULL STORAGES", storages)
    for comp, storage in storages do
        for ent, data in storage do
            fill(self.pendingChanges, comp, ent, data.value, data.players, self.replicated)
        end
        table.clear(storage)
    end

    local changes, deleted = self.pendingChanges, self.pendingDeletes
    self.pendingChanges, self.pendingDeletes = {}, {}
    return changes, deleted
end
--[=[
	@within feces
	Reformats the results of [`delta()`](/api/feces#delta) into an easier format to replicate.
	Not optimal, but recommended if performance of feces-replicated entities is not a concern.
	```lua
	local dataByPlayer = feces.group(feces:delta())
	for player, packet in dataByPlayer do
		someRemote:FireClient(player, packet)
	end
	-- see more of this example [here](/docs/setup#simple)
	```
]=]
local function group(changes: changes, deleted: deletes?): { [Player]: applyable }
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
lib.group = group
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

local function full(self: feces): applyable
	local data = {} :: applyable

	local function addEntity(component, player, entity, value)
		if player then
			return -- we only want publicly replicated data
		end

		value = value or NIL_VALUE
		data[component] = data[component] or { value = {}, special = {} }
		if value == DELETE_VALUE or value == NIL_VALUE then
			(data[component].special :: any)[entity] = value
		else
			(data[component].value :: any)[entity] = value
		end
	end


	for _, archetype in self.queries.single:archetypes() do
		local entities = archetype.entities
		if #entities == 0 then
			continue
		end

		local columns = archetype.columns
		local types = archetype.types
		local record = archetype.records[self.replicated]
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
				addEntity(id :: Component, player, entity :: Entity, column[row])
			end
		end
	end

	for _, archetype in self.queries.pair:archetypes() do
		local entities: { number } = archetype.entities
		if #entities == 0 then
			continue
		end

		local types = archetype.types
		local records = archetype.records

		for _, id in types do
			if not jecs.IS_PAIR(id) then
				continue
			end

			if jecs.pair_first(self.world, id) ~= self.replicated then
				continue -- it's a pair but the first component isn't replicated e.g pair(someComponent, someOtherComponent) instead of pair(replicated, someOtherComponent)
			end

			local record = records[id]
			if not record then
				continue
			end

			local playerColumn = archetype.columns[record]
			local component = jecs.pair_second(self.world, id)
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

function lib.new(world: World): feces
	--assume the user has already added observers to the world
	local replicated = world:component()
	world:set(replicated, jecs.Name, "replicated")
	local self = {
		replicated = replicated,
		queries = {
			single = world:query(replicated):cached(),
			pair = world:query(pair(replicated, __)):cached(),
		},
		world = world,
		pendingChanges = {} :: changes,
		pendingDeletes = {} :: deletes,
		hooks = {},
		refs = {},
		ref = ref,
		apply = apply,
		delta = delta,
		full = full,
		group = group,
		added = added,
		changed = changed,
		removed = removed,
		deleted = deleted,
	} :: any
	
	if isServer then
        local function listen(comp)
            print("LISTENING TO COMPONENT", comp)
            if storages[comp] then 
                print("ALREADY LISTENING TO COMPONENT", comp)
				return
			end

            storages[comp] = {}
            local isTag = jecs.is_tag(world, comp)
            -- value hook
            world:added(comp, function(ent, _, val)
                print("world added", ent, comp, val)
                storages[comp][ent] = { value = val or true, players = if game then Players:GetPlayers() else { "-1" } }
            end)

            if not isTag then
                print("LISTENING TO CHANGES FOR COMPONENT", comp)
                world:changed(comp, function(ent, _, val)
                    print("world changed", ent, comp, val)
                    storages[comp][ent] = { value = val, players = if game then Players:GetPlayers() else { "-1" } }
                end)
            end

			world:removed(comp, function(ent)
                print("world removed", ent, comp)
                storages[comp][ent] = { value = DELETE_VALUE, players = if game then Players:GetPlayers() else { "-1" } }
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
                table.insert(self.pendingDeletes[player], ent)
            end
        end)
    end

	return self :: feces
end

return lib :: lib