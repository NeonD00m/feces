local frktest = require("@pkg/frktest")
local test = frktest.test
local check = frktest.assert.check

return function()
    local jecs = require("@test/jecs_0_8_3")
    -- local o = require("@test/observers")
    local lib = require("@feces/init.luau")

    local function create()
        return lib.new(jecs, jecs.world(), nil, false) 
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
            feces:debug("CREATING GROUP")
            local group = feces.reserve(16)
            feces:debug("CREATING ENTITIES")
            local E1 = feces.world:entity()
            local E2 = feces.world:entity()
            local A = feces.world:component()
            -- give components to both but only group one
            feces:debug("SETTING COMPONENTS")
            feces.world:set(E1, A, 1)
            feces.world:set(E2, A, 2)
            feces:debug("ADDING REPLICATED 1", E1)
            feces.world:add(E1, feces.replicated)
            feces:debug("ADDING GROUPED 1", E1)
            feces:setGroup(group, E1)
            feces:debug("ADDING REPLICATED 2", E2)
            feces.world:add(E2, feces.replicated)
            -- make sure group and feces have different lookups
            feces:debug("CHECKING GROUP LOOKUPS")
            check.table.equal(group.refs, {
                E1
            })
            check.table.equal(group.lookups, {
                [E1] = 1,
            })
            feces:debug("CHECKING FECES LOOKUPS")
            check.table.equal(feces.refs, { }) -- should be empty because feces won't make these until needed
            check.table.equal(feces.lookups, { })
            feces:debug("GROUP DELTA")
            local changes, deleted = feces:delta(group)
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [1] = 1,
                        },
                        remove = { },
                        none = { },
                    }
                }
            })
            check.table.equal(deleted, {})
            feces:debug("FECES DELTA")
            changes, deleted = feces:delta()
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
                            [1] = 2,
                        },
                        remove = { },
                        none = { },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("feces -> group", function()
            local feces = create()
            feces:debug("CREATING GROUP")
            local group = feces.reserve(16)
            feces:debug("CREATING ENTITIES")
            local E = feces.world:entity()
            local A = feces.world:component()
            feces:debug("SETTING COMPONENTS")
            feces.world:set(E, A, 5)
            feces:debug("ADDING REPLICATED")
            feces.world:add(E, feces.replicated)
            feces:debug("FECES DELTA")
            local changes, deleted = feces:delta()
            check.table.equal(feces.refs, {
                E
            })
            check.table.equal(feces.lookups, {
                [E] = 1,
            })
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [1] = 5,
                        },
                        remove = { },
                        none = { },
                    }
                }
            })
            check.table.equal(deleted, {})
            feces:debug("CHECKING GROUP LOOKUPS")
            check.table.equal(group.refs, { })
            check.table.equal(group.lookups, { })
            feces:debug("CHANGING COMPONENTS")
            feces.world:set(E, A, 6)
            feces:debug("ADDING GROUPED")
            feces:setGroup(group, E)
            feces:debug("CHECKING FECES LOOKUPS")
            check.table.equal(feces.refs, { }) -- should be empty because feces won't make these until needed
            check.table.equal(feces.lookups, { })
            feces:debug("GROUP DELTA")
            changes, deleted = feces:delta(group)
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [1] = 6,
                        },
                        remove = { },
                        none = { },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("group -> group", function()
            local feces = create()
            feces:debug("CREATING GROUP")
            local group1 = feces.reserve(16)
            local group2 = feces.reserve(16)
            feces:debug("CREATING ENTITIES")
            local E = feces.world:entity()
            local A = feces.world:component()
            feces:debug("SETTING COMPONENTS")
            feces.world:set(E, A, 5)
            feces:debug("ADDING REPLICATED AND GROUPED")
            feces.world:add(E, feces.replicated)
            feces:setGroup(group1, E)
            feces:debug("FECES DELTA")
            local changes, deleted = feces:delta(group1)
            check.table.equal(group1.refs, {
                E
            })
            check.table.equal(group1.lookups, {
                [E] = 1,
            })
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [1] = 5,
                        },
                        remove = { },
                        none = { },
                    }
                }
            })
            check.table.equal(deleted, {})
            feces:debug("CHECKING GROUP LOOKUPS")
            check.table.equal(group2.refs, { })
            check.table.equal(group2.lookups, { })
            feces:debug("CHANGING COMPONENTS")
            feces.world:set(E, A, 6)
            feces:debug("ADDING GROUPED")
            feces:setGroup(group2, E)
            feces:debug("CHECKING FECES LOOKUPS")
            check.table.equal(group1.refs, { }) -- should be empty because feces won't make these until needed
            check.table.equal(group1.lookups, { })
            feces:debug("GROUP DELTA")
            changes, deleted = feces:delta(group2)
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [1] = 6,
                        },
                        remove = { },
                        none = { },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("group -> feces", function()
            return nil
        end)


        return nil
    end)
end