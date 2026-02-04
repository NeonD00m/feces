--[=[
@class lib
The feces library only provides 3 functions
- [`new`](#new) -- creates new feces class
- [`combine`](#combine) -- combines `Changes` and `Deletes` objects into one [`Applyable`](api/feces#Applyable) per player
- [`reserve`](#reserve) -- creates a `Group` structure that can be used by any feces object

Also, [`combine`](#combine) and [`reserve`](#reserve) can both be used from an instance of [`feces`](/api/feces)
via `feces.combine` and `feces.reserve` respectively (using . operator instead of :)
]=]


--[=[
@within lib
@function new
@param jecs Jecs -- The `jecs` module instance (require("@rbx/jecs")).
@param world World -- The `jecs.World` instance to observe and mutate.
@param group? Group -- Optional initial group to use for the returned instance (creates default group).
@param debugPrints? boolean -- Enable debug printing.
@return feces -- Returns a new `feces` instance.
Creates a `feces` library instance that watches the supplied `world` for component changes
and exposes `apply`, `delta`, `full`, `reserve`, and other helpers.
```lua
-- may be used like this in a module of its own
local world = jecs.world()
local feces = lib.new(jecs, world)
```
]=]

--[=[
@within lib
@function combine
@param changes Changes -- The changes object returned from `delta`.
@param deleted Deletes? -- Optional deletes object returned from `delta`.
@return { [Player]: Applyable } -- Per-player packets prepared from the changes+deletes.
`combine` translates [`Changes`](#Changes) objects into per-player [`Applyable`](api/feces#Applyable) packets,
ready to be serialized or sent to each client as one object with all the necessary updates.
See the [simple setup here](/docs/setup#simple).
]=]

--[=[
@within lib
@function reserve
@param size number -- number of lookup slots to reserve
@param debugLocation boolean? -- whether to use debug.info for debugging
@return Group -- A `Group` object with its own lookup space.
Reserves a lookup namespace of `size` entries and returns a `Group`. The returned `Group` can be
passed to `lookup`, `ref`, `delta`, `apply`, etc., to isolate replication to that namespace.
Use [`feces:setGroup`](/api/feces#setGroup) to add a particular entity to a replication group.

The primary goal of these is to allow serializing entites of specific types with a set amount of bits.
So for example, you could have a maximum of 8 racecars at a time in your racing game, and you could create
a replication group with a size of 8, and then serialize those entities' lookup ids as 3 *whole* ___bits___.

**Or** if you're feeling fancy you can reserve a group then create an instance of feces from it:
```lua
local group = lib.reserve(24)
lib.new(jecs, myWorld, group)
```
]=]

--[=[
@within lib
@interface Group
.origin string -- Human-readable origin for warnings and debugging (e.g. "script:23 reserve()")
.size number -- Maximum count of entities for this group
.lookups { [LocalEntity]: LookupEntity } -- Mapping local entity -> lookup id
.refs { [LookupEntity]: LocalEntity } -- Mapping lookup id -> local entity
An object representing a reserved or default lookup namespace. The `feces` instance itself behaves as a `Group`
when used as the default/global group.
]=]

--[=[
@within lib
@type Applyable { [Component]: { [LookupEntity]: { value: any, action?: number,}}, __d = { LookupEntity }}
Represents a per-player packet that can be applied locally.
Use [`feces:apply`](#apply) to enact the changes in `Applyable` into the [`feces.world`](#world).
]=]

--[=[
@within lib
@type Changes { [Component]: { [Player]: { value: { [LookupEntity]: any }, remove: { LookupEntity }, none: { LookupEntity }, } } }
Produced by [`feces:delta`](#delta) and accepted by [`feces.combine`](#combine).
]=]

--[=[
@within lib
@type Deletes { [Player]: { LookupEntity } }
Produced by [`feces:delta`](#delta)
]=]

--[=[
@within lib
@type LocalEntity number
An entity in the world at [`feces.world`](#world)
]=]

--[=[
@within lib
@type LookupEntity number
An lookup id for an entity that *may* exist in [`feces.world`](#world).
]=]

--[=[
@class feces
The feces class for replicating jecs entities and components.
]=]

--[=[
@within feces
@prop _debug boolean?
When true, the library prints debug traces using `feces:debug`.
This is intended to be set by [`new`](api/lib#new) but I guess
you can enable/disable whenever you want to debug specific code.
]=]

--[=[
@within feces
@prop jecs jecs
The [`jecs`](github.com/ukendio/jecs) module instance used by this library.
]=]

--[=[
@within feces
@prop world World
The [`jecs.World`](github.com/ukendio/jecs) instance this `feces` object observes and mutates.
]=]

--[=[
@within feces
@prop replicated Entity
The replicated component id used to indicate per-entity player routing.
]=]

--[=[
@within feces
@prop refs { [number]: number }
Lookup table: lookupId -> localEntity for this group.
]=]

--[=[
@within feces
@prop lookups { [number]: number }
Reverse lookup: localEntity -> lookupId for this group.
]=]

--[=[
@within feces
@method ref
@param key LookupEntity?
@param group Group?
@return LocalEntity
Find a local entity from a lookup id in `group`.
Allocates a local entity if needed.
Use [`feces.refs`](#refs) or `group.refs` if you simply want to check for a local entity.
]=]

--[=[
@within feces
@method lookup
@param entity LocalEntity?
@param group Group?
@return LookupEntity
Resolve/allocate a lookup id and `entity` (if needed) in `group`.
Find a lookup id for a local entity in `group`.
Allocates a local entity if needed.
Use [`feces.lookups`](#lookups) or `group.lookups` if you simply want to check for a lookup id.
]=]

--[=[
@within feces
@method added
@param callback (LocalEntity) -> ()
Register an "added" hook called when new local entities are created by incoming packets.
]=]

--[=[
@within feces
@method changed<T>
@param callback (LocalEntity, Component, T) -> ()
Register a "changed" hook called when a component value is set.
]=]

--[=[
@within feces
@method removed
@param callback (LocalEntity, Component) -> ()
Register a "removed" hook for removals.
]=]

--[=[
@within feces
@method deleted
@param callback (LocalEntity) -> ()
Register a "deleted" hook for entity deletions.
]=]

--[=[
@within feces
@method setGroup
@param group Group? -- The group to assign (nil means default group)
@param entity LocalEntity -- The local entity to move
Assigns `entity` to `group` (or to the instance default group). Useful when you need to move an
entity between replication namespaces. The implementation will update `refs`/`lookups`.
]=]

--[=[
@within feces
@method getGroup
@param entity LocalEntity
@return Group
Return the `Group` currently owning `entity`. If the entity is not assigned to a non-default
group the result is the feces instance (default group).
]=]

--[=[
@within feces
@method delta
@param group Group?
@return (Changes, Deletes)
Compute the pending changes and deletes for the provided `group` (or default). `delta` consumes
internal buffers used to collect component changes; repeated calls without new changes return empty results.
The result can be passed to [`combine`](#combine) for simple unified replication data.
]=]

--[=[
@within feces
@method full
@param group Group?
@return Applyable
Produce a full replication packet for `group` (or default). This enumerates all currently replicated
components and packages them into an [`Applyable`](#Applyable) suitable for sending to a player that needs the
full current state for the `group`.
]=]

--[=[
@within feces
@method apply
@param delta Applyable -- Packet to apply to the `world`.
@param group Group? -- Apply using the `group`'s lookup mapping; defaults to the instance group.
Apply a replication packet to the local `world`. `apply` will create entities for lookup ids,
call hooks (`added`, `changed`, `removed`, `deleted`) as appropriate, and perform jecs mutations.
]=]

--[=[
@within feces
@method debug
@param ... any
Internal debug function that prints only when `feces._debug` is truthy.
]=]

-- Notes & Implementation details
-- - Groups: A `Group` is a separate lookup namespace. Lookups are per-group. Use `reserve(size)` to
--   create a group with `size` slots. Passing a `group` to `lookup`, `ref`, `delta`, `apply`, `full`
--   causes the operation to be scoped to that group's lookup mappings.
-- - Player resolution: The library resolves players from the `replicated` component which may be:
--     - a Player instance
--     - a string (for Non-Roblox)
--     - a table of players
--     - a function filter (returns players matching the function)
-- - Hooks: `added`, `changed`, `removed`, and `deleted` callbacks are invoked during `apply` to allow
--   consumers to observe materialized changes.
-- - TODO: If you want longer descriptions for `delta`/`combine` internals (packet layout, byte-size
--   expectations, serializing tables to/from network) tell me which serialization format you use and
--   I will expand those sections.
