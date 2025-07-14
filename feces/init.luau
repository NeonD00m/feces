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
        local replicated: types.Component<types.PlayerObject> = world:component() :: any
        local grouped: types.Component<types.Group> = world:component() :: any
        world:set(replicated, jecs.Name, "replicated")
        world:set(grouped, jecs.Name, "grouped")

        local storages: types.Storages = {}

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
                storages[component][ent] = { value = val, action = if val == nil then types.None else nil, players = (if game then Players:GetPlayers() else { "-1" }) :: { types.TestPlayer } }
            end)

            if not isTag then
                world:changed(component, function(ent, _, val)
                    storages[component][ent] = { value = val, players = (if game then Players:GetPlayers() else { "-1" }) :: { types.TestPlayer } }
                end)
            end

			world:removed(component, function(ent)
                storages[component][ent] = { action = types.Remove, players = (if game then Players:GetPlayers() else { "-1" }) :: { types.TestPlayer } }
            end)
        end

        for component in world.component_index do
            if (component :: any) ~= replicated and not (jecs.IS_PAIR(component) and jecs.pair_first(world, component) == replicated) then
                listen(component :: any)
            end
        end

        setmetatable(world.component_index, {
            __newindex = function(tbl, comp: any, val)
                rawset(tbl, comp, val)
                if val and comp ~= replicated
                   and not (jecs.IS_PAIR(comp :: any) and jecs.pair_first(world, comp :: any) == replicated)
                then
                    listen(comp :: any)
                end
            end,
        })

		world:removed(replicated, function(ent)
            local filter = world:get(ent, replicated)
            for _, player in resolvePlayers(filter) do
                feces.pendingDeletes[player] = feces.pendingDeletes[player] or {}
                feces.pendingDeletes[player][ent] = true
            end
        end)
        
        return feces :: types.Feces
    end
}

return lib :: types.Lib