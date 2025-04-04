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

local pair = jecs.pair
local __ = jecs.Wildcard
local onRemove = jecs.OnRemove

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
	delta: () -> (changes, deletes), -- gets the component changes to replicate

	-- gets the entity deletions to replicate
	full: () -> applyable, -- gets all currently replicating components
	group: (changes, deletes?) -> { [Player]: applyable },
	
	-- hooks into applying replication
	added: ((Entity) -> nil),
	changed: ((Entity, Component, any) -> nil),
	removed: ((Entity, Component) -> nil),
	deleted: ((Entity) -> nil)
}

local replicated = world:component() :: Component<PlayerObject>
local queries = {
	single = world:query(replicated):cached(),
	pair = world:query(pair(replicated, __)):cached(),
}

--[=[
	@prop replicated Component
	@within feces
	The feces library for replicating jecs entities and components.
]=]
local added, changed, removed, deleted = nil, nil, nil, nil
local previous: { [Component]: { [Entity]: any | "__n" }} = {}
local feces = {
	replicated = replicated,
	queries = queries
}

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

local function deepEquals(a: any, b: any): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end

	for key, value in a do
		if not deepEquals(value, b[key]) then
			return false
		end
	end
	for key, value in b do
		if not deepEquals(value, a[key]) then
			return false
		end
	end
	return true
end

local function diffComponent(prevValue: any, current: any): nilValue | any | {}?
	if current == nil then
		return if prevValue == NIL_VALUE then nil else NIL_VALUE
	end
	if prevValue == nil then
		return current
	end

	if typeof(prevValue) ~= typeof(current) then
		return if prevValue == current then nil else current
	end
	return if deepEquals(prevValue, current) then nil else current
end

local function fill(changes: changes, comp: Component, ent: Entity, value: any,  players: PlayerObject)
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

local function reconcile(changes: changes, player: PlayerObject, entity: Entity, component: Component, value: any)
	previous[component] = previous[component] or {}
	local diff = diffComponent(previous[component][entity], value)
	if not diff then
		return
	end

	previous[component][entity] = if diff == DELETE_VALUE then nil else diff
	if player == nil then
		fill(changes, component, entity, diff, Players:GetPlayers())
		return
	end
	
	fill(changes, component, entity, diff, player)
end

local function replicating(callback: (Component, PlayerObject, Entity, any, Component) -> nil)
	for _, archetype in queries.single:archetypes() do
		local entities = archetype.entities
		local columns = archetype.columns
		local types = archetype.types
		local record = archetype.records[replicated]
		if not record then
			continue
		end
		
		local playerColumn = columns[record]
		for key, id in types do
			if id == replicated :: number then
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
					replicated
				)
			end
		end
	end

	for _, archetype in queries.pair:archetypes() do
		local entities: { number } = archetype.entities
		local types = archetype.types
		local records = archetype.records

		for _, id in types do
			if not jecs.IS_PAIR(id) then
				continue
			end

			if jecs.pair_first(world, id) ~= replicated :: number then
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
	Applies changes to the world by taking in the [`applyable`](/api/feces#applyable) type and editing the world. 
	```lua
	feces.apply({
		[someComponent] = {
			[someForeignEntity] = someValue,
		}
	})
	```
]=]
function feces.apply(
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
				if deleted then
					deleted(id)
				end
				world:delete(id)
			end
			continue
		end
		
		local newEntities = {}

		for entity: Entity, value in entities.value do
			if not refs[`repl{entity}`] then
				local id = ref(`repl{entity}`)
				if changed then
					changed(id, component, value)
				end
				world:set(id, component, value)
				if added then
					newEntities[id] = true
				end
			else
				local id = ref(`repl{entity}`)
				if changed then
					changed(id, component, value)
				end
				world:set(id, component, value)
			end
		end

		for entity: Entity, value in entities.special do
			local id = ref(`repl{entity}`)

			if value == DELETE_VALUE then
				if removed then
					removed(id, component)
				end
				world:remove(id, component)
				continue
			end
			
			local newValue = if value == NIL_VALUE then nil else value
			if changed then
				changed(id, component, newValue)
			end

			world:set(id, component, newValue)
		end

		if added then
			for id, _ in newEntities do
				added(id)
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
function feces.delta(): (changes, deletes)
	local changes: changes = {}
	local deleted: deletes = {}
	
	replicating(function(component, playerObject, entity: Entity, value, replicatedId)
		reconcile(changes, playerObject, entity, component, value)
		
		world:set(replicatedId, onRemove, function(id: jecs.Entity)
			if id == entity :: jecs.Entity then
				for _, player in getPlayers(playerObject) do
					if not player then
						continue
					end
					
					deleted[player] = id
				end
			end
		end)
		
		if next(deleted) then
			for _, player in getPlayers(playerObject) do
				if not player then
					continue
				end
				
				local id = deleted[player]
				if not id or id ~= entity :: jecs.Entity then
					continue
				end

				previous[component] = previous[component] or {}
				previous[component][entity] = nil
			end
		end
		
		world:set(component, onRemove, function(id)
			if id == entity :: jecs.Entity and not deleted[id :: Entity] then
				reconcile(changes, playerObject, id :: Entity, component, DELETE_VALUE)
			end
		end)
	end)
	
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
function feces.full(): applyable
	local data = {} :: applyable

	replicating(function(component, player, entity, value)
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
function feces.added(callback: (Entity) -> nil)
	added = callback
end
--[=[
	@within feces
	Adds a callback for when a component value is changed in the world through [`apply()`](/api/feces#apply).  
	Called *before* the component in question is changed, deleted, or set to `nil`.
	See how you might use this [here](/docs/hooks#changed).
]=]
function feces.changed(callback: (Entity, Component, any) -> nil)
	changed = callback
end
--[=[
	@within feces
	Adds a callback for when a component is removed in the world through [`apply()`](/api/feces#apply).   
	Called *before* the component in question is removed.
	See how you might use this [here](/docs/hooks#removed).
]=]
function feces.removed(callback: (Entity, Component) -> nil)
	removed = callback
end
--[=[
	@within feces
	Adds a callback for when an entity is deleted in the world through [`apply()`](/api/feces#apply).   
	Called *before* the entity in question is deleted, allowing hooks to get component values and clean up.
	See how you might use this [here](/docs/hooks#deleted).
]=]
function feces.deleted(callback: (Entity) -> nil)
	deleted = callback
end
--[=[
	@within feces
	Initiates feces with a new world and resets previous data.
	Internally creates new feces.replicated component and new
	queries for single and paired components.
]=]
function feces.init(world: jecs.World)
	world = world
	replicated = world:component() :: Component<PlayerObject>
	feces.replicated = replicated
	queries = {
		single = world:query(replicated):cached(),
		pair = world:query(pair(replicated, __)):cached(),
	}
	feces.queries = queries
	previous = {}
end	

return feces :: typeof(feces)
