local Players = game and game:GetService("Players")

local types = require("./feces/types")
local groups = require("./feces/groups")

local apply = require("./feces/apply")
local full = require("./feces/full")
local delta = require("./feces/delta")
local combine = require("./feces/combine")
local resolvePlayers = require("./feces/resolvePlayers")
local hooks = require("./feces/hooks")

local added, changed, removed, deleted = hooks.added, hooks.changed, hooks.removed, hooks.deleted
local ref, lookup = groups.ref, groups.lookup

local lib = {
    reserve = groups.reserve,
    combine = combine,
    new = function(jecs: types.Jecs, world: types.World, group: types.Group?): types.Feces
        --assume the user has already added observers to the world
        local replicated = world:component() :: types.Component<types.PlayerObject>
        local grouped = world:component() :: types.Component<types.Group>
        world:set(replicated, jecs.Name, "replicated")
        world:set(grouped, jecs.Name, "grouped")

        local storages = {}

        local feces = {
            jecs = jecs,
            world = world,
            replicated = replicated,
            grouped = grouped,

            queries = {
                single = world:query(replicated):cached(),
                pair = world:query(jecs.pair(replicated, jecs.Wildcard)):cached(),
            },
            pendingChanges = {},
            pendingDeletes = {},
            storages = storages,

            origin = if group then group.origin else "feces.new()",
            size = if group then group.size else math.huge,
            refs = if group then group.refs else {},
            lookups = if group then group.lookups else {},

            ref = ref,
            lookup = lookup,
            apply = apply,
            delta = delta,
            full = full,

            added = added,
            changed = changed,
            removed = removed,
            deleted = deleted,
            hooks = {},
        } :: types.Feces

        local function listen(component: types.Component)
            if storages[component] then
				return
			end

            storages[component] = {}
            local isTag = jecs.is_tag(world, component)

            world:added(component, function(ent, _, val)
                storages[component][ent] = { value = val, players = if game then Players:GetPlayers() else { "-1" } }
            end)

            if not isTag then
                world:changed(component, function(ent, _, val)
                    storages[component][ent] = { value = val, players = if game then Players:GetPlayers() else { "-1" } }
                end)
            end

			world:removed(component, function(ent)
                storages[component][ent] = { value = DELETE_VALUE, players = if game then Players:GetPlayers() else { "-1" } }
            end)
        end

        for component in world.component_index do
            if component ~= replicated and not (jecs.IS_PAIR(component) and jecs.pair_first(world, component) == replicated) then
                listen(component)
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

		world:removed(replicated, function(ent)
            local filter = world:get(ent, replicated)
            for _, player in resolvePlayers(filter) do
                feces.pendingDeletes[player] = feces.pendingDeletes[player] or {}
                feces.pendingDeletes[player][ent] = true
                -- table.insert(self.pendingDeletes[player], ent)
            end
        end)
        
        return feces :: types.Feces
    end
}

return lib :: types.Lib