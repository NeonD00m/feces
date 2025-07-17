local frktest = require("@pkg/frktest")
local test = frktest.test
local check = frktest.assert.check

return function()
    local jecs = require("@test/jecs_0_8_3")
    local o = require("@test/observers")
    local lib = require("@feces/init.luau")

    local function create()
        return lib.new(jecs, o(jecs.world()), nil, true) 
    end

    test.suite("basic", function()
        test.case("creating a group", function()
            local feces = create()
            local group = feces.reserve(16)
            check.table.equal(group, {
                origin = `[string "test\\\groups.luau"]:17 ()`,
                size = 16,
                lookups = {},
                refs = {},
            })
            return nil
        end)

        test.case("adding entities to a group", function()
            local feces = create()
            local group = feces.reserve(16)
            local E1 = feces.world:entity()
            local E2 = feces.world:entity()
            local A = feces.world:component()
            -- give components to both but only group one
            feces.world:set(E1, A, 1)
            feces.world:set(E2, A, 2)
            feces.world:add(E1, feces.replicated)
            feces.world:set(E1, feces.grouped, group)
            feces.world:add(E2, feces.replicated)
            -- make sure group and feces have different lookups
            check.table.equal(group.refs, {
                E1
            })
            check.table.equal(group.lookups, {
                [E1] = 1,
            })
            check.table.equal(feces.refs, { }) -- should be empty because feces won't make these until needed
            check.table.equal(feces.lookups, { })
            local changes, deleted = feces:delta(group)
            check.table.equal(feces.refs, {
                E2
            })
            check.table.equal(feces.lookups, {
                [E2] = 1,
            })
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [E1] = 1,
                        },
                        remove = { },
                        none = { },
                    }
                }
            })
            check.table.equal(deleted, {})
            changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [E2] = 2,
                        },
                        remove = { },
                        none = { },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)
        return nil
    end)
end