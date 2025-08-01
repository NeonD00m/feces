local types = require("@feces/types")
local groups = require("@feces/groups")
local hooks = require("@feces/hooks")

local apply = require("@feces/apply")
local full = require("@feces/full")
local delta = require("@feces/delta")
local combine = require("@feces/combine")
local resolvePlayers = require("@feces/resolvePlayers")

local added, changed, removed, deleted = hooks.added, hooks.changed, hooks.removed, hooks.deleted
local ref, lookup, reserve, setGroup, getGroup = groups.ref, groups.lookup, groups.reserve, groups.setGroup, groups.getGroup

local function debug(self: types.Feces, ...: any)
    if not self.DEBUG then
        return
    end
    print(...)
end


local lib = {
    reserve = reserve,
    combine = combine,
    new = function(jecs: types.Jecs, world: types.World, group: types.Group?, debugPrints: boolean?): types.Feces
        --assume the user has already added observers to the world
        local replicated = world:component() :: any
        local grouped = world:component() :: any
        world:set(replicated, jecs.Name, "replicated")
        world:set(grouped, jecs.Name, "grouped")

        local storages: types.Storages = {}

        local feces = {
            jecs = jecs,
            world = world,
            replicated = replicated,
            DEBUG = debugPrints,

            queries = {
                single = world:query(replicated):cached(),
                pair = world:query(jecs.pair(replicated, jecs.Wildcard)):cached(),
            },
            _deleted = {},
            _storages = storages,
            _grouped = {},

            origin = if group then group.origin else "feces.new()",
            size = if group then group.size else math.huge,
            refs = if group then group.refs else {},
            lookups = if group then group.lookups else {},

            debug = debug,
            ref = ref,
            lookup = lookup,
            apply = apply,
            delta = delta,
            full = full,
            reserve = reserve,
            combine = combine,
            setGroup = setGroup,
            getGroup = getGroup,

            added = added,
            changed = changed,
            removed = removed,
            deleted = deleted,
            _hooks = {},
        } :: types.Feces

        local function listen(component: types.Component)
            if component == replicated or component == grouped then
                return
            end

            if storages[component] then
                feces:debug(`[feces] Error, there is already a storage for component: {component}`)
				return
			end

            storages[component] = {}
            local isTag = jecs.is_tag(world, component)

            world:added(component, function(ent, _, val)
                if ent == replicated or ent == grouped then
                    return
                end
                feces:debug(`->\tcomponent added: {ent}[{component}] = {val}`)
                storages[component][ent] = { value = val, action = if val == nil then types.None else nil }
            end)

            if not isTag then
                world:changed(component, function(ent, _, val)
                    if ent == replicated or ent == grouped then
                        return
                    end
                    feces:debug(`->\tcomponent changed: {ent}[{component}] = {val}`)
                    storages[component][ent] = { value = val, action = if val == nil then types.None else nil }
                end)
            end

			world:removed(component, function(ent)
                if ent == replicated or ent == grouped then
                    return
                end
                feces:debug(`/->\tcomponent removed: {ent}[{component}]`)
                storages[component][ent] = { action = types.Remove }
            end)
        end

        for component in world.component_index :: {any} do
            if component > 256 and component <= 271 then
                continue
            end
            if component == replicated or component == grouped then
                continue
            end
            if (component :: any) ~= replicated and not (jecs.IS_PAIR(component :: any) and jecs.pair_first(world, component :: any) == replicated) then
                listen(component :: any)
            end
        end

        setmetatable(world.component_index, {
            __newindex = function(tbl, comp: any, val)
                rawset(tbl, comp, val)

                if (comp > 256 and comp <= 271) or comp == replicated or comp == grouped then
                    return
                end
                if val and not (jecs.IS_PAIR(comp :: any) and jecs.pair_first(world, comp :: any) == replicated) then
                    listen(comp :: any)
                end
            end,
        })

		world:removed(replicated, function(ent: any)
            local filter = world:get(ent, replicated)
            for _, player in resolvePlayers(filter) do
                feces._deleted[player] = feces._deleted[player] or {}
                feces._deleted[player][ent] = true
            end
        end)

        -- world:added(grouped, function(ent: any, _, val: types.Group)
        --     if feces.lookups[ent] then
        --         feces:debug(`->\tremoving from feces: {ent}`)
        --         removeFromGroup(feces, ent)
        --     end
        --     if val then
        --         feces:debug(`->\tgroup added: {ent}[grouped] = {val.origin}`)
        --         addToGroup(feces, val, ent)
        --     else
        --         feces:debug("->\tgroup was nil when added:", val)
        --     end
        -- end)

        -- world:changed(grouped, function(ent: any, _, val: types.Group)
        --     local prev = removeFromGroup(feces, ent)
        --     feces:debug("->\tgroup was nil when changed:", val)
        --     if val and not val.lookups[ent] then
        --         feces:debug(`->\tgroup changed: {ent}[grouped] = ({prev and prev.origin}) -> ({val.origin})`)
        --         addToGroup(feces, val, ent)
        --     end
        -- end)

        -- world:removed(grouped, function(ent: any, _)
        --     local prev = removeFromGroup(feces, ent)
        --     feces:debug(`->\tgroup removed: {ent}[grouped] = ({prev and prev.origin}) deleted`)
        -- end)
        
        return feces :: types.Feces
    end
}

return lib :: types.Lib