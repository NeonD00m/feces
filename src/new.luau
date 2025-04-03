--!strict
--!optimize 2
--[=[
	@class feces
	The feces library for replicating jecs entities and components.
]=]
local Players = game:GetService("Players")
local jecs = require("./roblox_packages/jecs")
local ref = require("./roblox_packages/ref")
local refs = require("./roblox_packages/refs")
local world = require("./roblox_packages/world")
local observer = require("./observers")

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
			special: { [Entity]: deleteValue | nilValue }
		}
	}
}
--[=[
	@type deletes { [Player]: { Entity } }
	@within feces
	How deleted entities are represented.
]=]
type deletes = {
	[Player]: { Entity }
}
--[=[
	@type applyable { [Component]: { value: { [Entity]: any }, special: { [Entity]: deleteValue | nilValue } } } & { __d: { Entity } }
	@within feces
	Funkier type for how applyable changes should be formated.
]=]
type applyable = {
	[Component]: {
		value: { [Entity]: any },
		special: { [Entity]: deleteValue | nilValue }
	}
} & { __d: { Entity }}

export type feces = {
	apply: (applyable) -> nil, -- applies component changes to world
	delta: (self) -> (changes, deletes), -- gets the component changes to replicate

	-- gets the entity deletions to replicate
	full: (self) -> applyable, -- gets all currently replicating components
	group: (self, changes, deletes?) -> { [Player]: applyable },
	
	-- hooks into applying replication
	added: ((Entity) -> nil) -> nil,
	changed: ((Entity, Component, any) -> nil) -> nil,
	removed: ((Entity, Component) -> nil) -> nil,
	deleted: ((Entity) -> nil) -> nil,
    -- hooks: {
    --     added: ((Entity) -> nil)?,
	--     changed: ((Entity, Component, any) -> nil)?,
	--     removed: ((Entity, Component) -> nil)?,
	--     deleted: ((Entity) -> nil)?
    -- },

    -- pendingChanges: changes,
    -- pendingDeletes: deletes,
}

local feces = {}
feces.__index = feces

-- PRIVATE FUNCTIONS

local function getPlayers(info: PlayerObject): { Player? }
	if typeof(info) == "table" then
		return info
	elseif typeof(info) == "function" then
		local result = {}
		for key, player in Players:GetPlayers() do
			if not info(player) then
				continue
			end
			
			result[key] = player
		end
		return result
	end
	
	return { info }
end

local function fill(changes: changes, comp: Component, ent: Entity, value: any, players: PlayerObject)
	changes[comp] = changes[comp] or {}
	
	for _, player in getPlayers(players) do
		if not player then
			continue
		end

		changes[comp][player] = changes[comp][player] or { value = {}, special = {} }
		if value == DELETE_VALUE or value == NIL_VALUE then
			changes[comp][player].special[ent] = value
		else
			changes[comp][player].value[ent] = value
		end
	end
end

function feces:_replicating(callback: (Component, PlayerObject, Entity, any, Component) -> nil)
	for _, archetype in self.queries.single:archetypes() do
		local entities = archetype.entities
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
				callback(
					id :: Component,
					player,
					entity :: Entity,
					column[row],
					self.replicated
				)
			end
		end
	end

	for _, archetype in self.queries.pair:archetypes() do
		local entities: { number } = archetype.entities
		local types = archetype.types
		local records = archetype.records

		for _, id in types do
			if not jecs.IS_PAIR(id) then
				continue
			end

			if jecs.pair_first(world, id) ~= self.replicated :: number then
				continue -- it's a pair but the first component isn't replicated e.g pair(someComponent, someOtherComponent) instead of pair(replicated, someOtherComponent)
			end

			local record = records[id]
			if not record then
				continue
			end

			local playerColumn = archetype.columns[record]
			local component = jecs.pair_second(world, id)
			for row, entity in entities do
				if not world:has(entity :: Entity, component :: Component) then
					continue
				end

				callback(
					component :: Component,
					playerColumn[row],
					entity :: Entity,
					world:get(
						entity :: Entity,
						component :: Component
					),
					id :: Component
				)
			end
		end
	end
end

-- PUBLIC FUNCTIONS

--[=[
	@within feces
    Creates a new replicatable component for feces.
	```lua
	local transform = feces:component()
	```
]=]
function feces:component(): jecs.Component
    local component = self.world:component()
    local paired = pair(self.replicated, component)

    self.world:changed(component, function(entity, value)
        fill(self.pendingChanges, component, entity, value, getPlayers(value) :: {Player})
    end)

    self.world:added(paired, function(entity, value)
        fill(self.pendingChanges, component, entity, world:get(entity, component), getPlayers(value) :: {Player})
    end)

    self.world:removed(paired, function(entity, value)
        fill(self.pendingChanges, component, entity, DELETE_VALUE, getPlayers(value) :: {Player})
    end)

    return component
end

--[=[
	@within feces
	Applies changes to the world by taking in the [`applyable`](/api/feces#applyable) type and editing the world. 
	```lua
	feces.apply({
		[someComponent] = {
			[someForeignEntity] = someValue,
		}
	})
	```
]=]
function feces:apply(
	delta: applyable
)
	if not delta then
		warn("NO APPLYABLE DATA RECEIVED")
		return
	end

	for component, entities in delta :: {[any]: any } do
		if not entities then
			continue
		end
		
		if component == DELETE_VALUE then
			for _, entity in entities do
				local id = ref(`repl{entity}`)
				if self.hooks.deleted then
					self.hooks.deleted(id)
				end
				world:delete(id)
			end
			continue
		end
		
		local newEntities = {}

		for entity: Entity, value in entities.value do
			if not refs[`repl{entity}`] then
				local id = ref(`repl{entity}`)
				if self.hooks.changed then
					self.hooks.changed(id, component, value)
				end
				world:set(id, component, value)
				if self.hooks.added then
					newEntities[id] = true
				end
			else
				local id = ref(`repl{entity}`)
				if self.hooks.changed then
					self.hooks.changed(id, component, value)
				end
				world:set(id, component, value)
			end
		end

		for entity: Entity, value in entities.special do
			local id = ref(`repl{entity}`)

			if value == DELETE_VALUE then
				if self.hooks.removed then
					self.hooks.removed(id, component)
				end
				world:remove(id, component)
				continue
			end
			
			local newValue = if value == NIL_VALUE then nil else value
			if self.hooks.changed then
				self.hooks.changed(id, component, newValue)
			end

			world:set(id, component, newValue)
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
	local changedComponents, deletedEntities = feces.delta()
	-- ... replicate however you'd like or see the examples [here](/docs/setup)
	```
]=]
function feces:delta(): (changes, deletes)
	local changes: changes, deleted: deletes = self.pendingChanges, self.pendingDeletes
	
	self.pendingChanges, self.pendingDeletes = {}, {}
	
	return changes, deleted
end
--[=[
	@within feces
	Reformats the results of [`delta()`](/api/feces#delta) into an easier format to replicate.
	Not optimal, but recommended if performance of feces-replicated entities is not a concern.
	```lua
	local dataByPlayer = feces.group(feces.delta())
	for player, packet in dataByPlayer do
		someRemote:FireClient(player, packet)
	end
	-- see more of this example [here](/docs/setup#simple)
	```
]=]
function feces.group(changes: changes, deleted: deletes?): { [Player]: applyable }
	local packets: { [Player]: applyable } = {}

	for component, players in changes do
		for player, entities in players do
			packets[player] = packets[player] or {__d = {}}
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
			packets[player] = packets[player] or {__d = {}}
			packets[player].__d = entities
		end
	end
	
	return packets
end
--[=[
	@within feces
	Gets all the currently replicating component and entity values.
	:::tip
	This is useful for providing payloads to new players when they first join a server.
	:::
	```lua
	local changedComponents = feces.full()
	-- ... replicate however you'd like or see the examples [here](/docs/setup)
	```
]=]
function feces:full(): applyable
	local data = {} :: applyable

	self:_replicating(function(component, player, entity, value)
		if player then
			return -- we only want publicly replicated data
		end
		data[component] = data[component] or { value = {}, special = {} }
		if value == DELETE_VALUE or value == NIL_VALUE then
			(data[component].special :: any)[entity] = value
		else
			(data[component].value :: any)[entity] = value
		end
	end)

	return data
end
--[=[
	@within feces
	Adds a callback for when an entity is added to the world through [`apply()`](/api/feces#apply).
	Called *after* **a** (not all) component value is set to a newly replicated entity.
	See how you might use this [here](/docs/hooks#added).
]=]
function feces:added(callback: (Entity) -> nil)
	self.hooks.added = callback
end
--[=[
	@within feces
	Adds a callback for when a component value is changed in the world through [`apply()`](/api/feces#apply).  
	Called *before* the component in question is changed, deleted, or set to `nil`.
	See how you might use this [here](/docs/hooks#changed).
]=]
function feces:changed(callback: (Entity, Component, any) -> nil)
	self.hooks.changed = callback
end
--[=[
	@within feces
	Adds a callback for when a component is removed in the world through [`apply()`](/api/feces#apply).   
	Called *before* the component in question is removed.
	See how you might use this [here](/docs/hooks#removed).
]=]
function feces:removed(callback: (Entity, Component) -> nil)
	self.hooks.removed = callback
end
--[=[
	@within feces
	Adds a callback for when an entity is deleted in the world through [`apply()`](/api/feces#apply).   
	Called *before* the entity in question is deleted, allowing hooks to get component values and clean up.
	See how you might use this [here](/docs/hooks#deleted).
]=]
function feces:deleted(callback: (Entity) -> nil)
	self.hooks.deleted = callback
end	

function feces.new(world: jecs.World)
    local replicated = observer(world):component() 
    local self = setmetatable({
        world = world,
        queries = {
            single = world:query(replicated):cached(),
            pair = world:query(pair(replicated, __)):cached(),
        },
        pendingChanges = {} :: changes,
        pendingDeletes = {} :: deletes,
        hooks = {},
    }, feces)

    world:added(replicated, function(entity, value)
        -- gotta replicate all the components
    end)

    world:removed(replicated, function(entity, value)
        for _, player in getPlayers(value) do
            if not player then continue end
            table.insert(self.pendingDeletes[player], entity)
        end
    end)

    return self
end

return feces