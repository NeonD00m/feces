local types = require("./types")
local groups = require("./groups")
local changes = require("./changes")

local ref, lookup = groups.ref, groups.lookup
local apply, delta, full = changes.apply, changes.delta, changes.full

local lib = {
    reserve = groups.reserve,
    combine = changes.combine,
    new = function<jecs>(jecs: jecs, world: types.World, group: types.group?): types.feces<jecs>
        --assume the user has already added observers to the world
        local replicated = world:component()
        local grouped = world:component()
        world:set(replicated, jecs.Name, "replicated")
        world:set(replicated, jecs.Name, "grouped")

        local feces = {
            size = math.huge,
            jecs = jecs,
            replicated = replicated,
            grouped = grouped,
            queries = {
                single = world:query(replicated):cached(),
                pair = world:query(pair(replicated, __)):cached(),
            },
            world = world,
            pendingChanges = {} :: types.changes,
            pendingDeletes = {} :: types.pendingDeletes,
            hooks = {},
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
        } :: feces<jecs>


        return self :: feces<jecs>
    end
}

return lib :: types.lib