local frktest = require("@pkg/frktest")
local test = frktest.test
local check = frktest.assert.check

return function()
    local jecs = require("@rbx/jecs")
    local lib = require("@feces/init.luau")

    local function create()
        return lib.new(jecs, jecs.world(), nil, false) 
    end

    test.suite("advanced", function()
        test.case("pair valid - specific", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A COMPONENT:")
            local A = feces.world:component()
            feces:debug("ADDING A COMPONENT:")
            feces.world:add(E, A)
            feces:debug("SETTING PAIR:")
            feces.world:set(E, jecs.pair(feces.replicated, A), "-1")
            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = { },
                        remove = { },
                        none = { lookup },
                    }
                },
                -- [jecs.pair(A, feces.replicated)] = {
                --     ["-1"] = {
                --         value = { [lookup] = "-1" },
                --         remove = { },
                --         none = { },
                --     }
                -- },
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("pair valid - nil", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A COMPONENT:")
            local A = feces.world:component()
            feces:debug("ADDING A COMPONENT:")
            feces.world:add(E, A)
            feces:debug("ADDING PAIR:")
            feces.world:add(E, jecs.pair(feces.replicated, A))
            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = { },
                        remove = { },
                        none = { lookup },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("pair valid - nil", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A COMPONENT:")
            local A = feces.world:component()
            feces:debug("ADDING A COMPONENT:")
            feces.world:add(E, A)
            feces:debug("ADDING PAIR:")
            feces.world:add(E, jecs.pair(feces.replicated, A))
            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = { },
                        remove = { },
                        none = { lookup },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("pair invalid - specific", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A COMPONENT:")
            local A = feces.world:component()
            feces:debug("ADDING A COMPONENT:")
            feces.world:add(E, A)
            feces:debug("SETTING PAIR:")
            feces.world:set(E, jecs.pair(feces.replicated, A), "-2")
            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-2"] = {
                        value = { },
                        remove = { },
                        none = { lookup },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("pair invalid - wrong order", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            feces:debug("A COMPONENT:")
            local A = feces.world:component()
            feces:debug("ADDING A COMPONENT:")
            feces.world:add(E, A)
            feces:debug("SETTING PAIR:")
            feces.world:set(E, jecs.pair(A, feces.replicated), {})
            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("pair invalid - wrong target", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            feces:debug("A COMPONENT:")
            local A = feces.world:component()
            local B = feces.world:component()
            feces:debug("ADDING A COMPONENT:")
            feces.world:add(E, A)
            feces:debug("SETTING PAIR:")
            feces.world:set(E, jecs.pair(feces.replicated, B), {})
            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("valid filter - table", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            local A = feces.world:component()
            feces:debug("ADDING A COMPONENT:")
            feces.world:add(E, A)
            feces:debug("SETTING REPLICATED:")
            feces.world:set(E, feces.replicated, {"-4", "-1"})
            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {},
                        remove = { },
                        none = { lookup },
                    },
                    ["-4"] = {
                        value = {},
                        remove = { },
                        none = { lookup },
                    },
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("valid filter - function", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A COMPONENT:")
            local A = feces.world:component()
            feces:debug("ADDING A COMPONENT:")
            feces.world:add(E, A)
            feces:debug("SETTING REPLICATED:")
            feces.world:set(E, feces.replicated, function() return true end)
            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {},
                        remove = { },
                        none = { lookup },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("valid filter - table", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A COMPONENT:")
            local A = feces.world:component()
            feces:debug("ADDING A COMPONENT:")
            feces.world:add(E, A)
            feces:debug("SETTING REPLICATED:")
            feces.world:set(E, feces.replicated, {"-2", "-3"})
            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-2"] = {
                        value = { },
                        remove = { },
                        none = { lookup },
                    },
                    ["-3"] = {
                        value = { },
                        remove = { },
                        none = { lookup },
                    },
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("invalid filter - function", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A COMPONENT:")
            local A = feces.world:component()
            feces:debug("ADDING A COMPONENT:")
            feces.world:add(E, A)
            feces:debug("SETTING REPLICATED:")
            feces.world:set(E, feces.replicated, function() return false end)
            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {})
            return nil
        end)
    
        -- PAIRS WITH FILTERS?
        return nil
    end)
end