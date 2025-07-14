local frktest = require("@pkg/frktest")
local test = frktest.test
local check = frktest.assert.check

return function()
    local jecs = require("../luau_packages/jecs")
    local o = require("./observers")
    local lib = require("../pkgs/core/feces")

    local function create()
        return lib.new(jecs, o(jecs.World.new())) 
    end

    test.suite("advanced", function()
        test.case("pair valid - specific", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            feces.world:add(E, A)
            feces.world:set(E, jecs.pair(A, feces.replicated), "-1")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {},
                        remove = { },
                        none = { E },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("pair valid - nil", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            feces.world:add(E, A)
            feces.world:add(E, jecs.pair(A, feces.replicated))
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {},
                        remove = { },
                        none = { E },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("pair invalid - specific", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            feces.world:add(E, A)
            feces.world:set(E, jecs.pair(A, feces.replicated), "-2")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("pair invalid - empty", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            feces.world:add(E, A)
            feces.world:set(E, jecs.pair(A, feces.replicated), {})
            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("valid filter - table", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            feces.world:add(E, A)
            feces.world:set(E, feces.replicated, {"-4", "-1"})
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {},
                        remove = { },
                        none = { E },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("valid filter - function", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            feces.world:add(E, A)
            feces.world:set(E, feces.replicated, function() return true end)
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {},
                        remove = { },
                        none = { E },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("valid filter - table", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            feces.world:add(E, A)
            feces.world:set(E, feces.replicated, {"-2", "-3"})
            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("valid filter - function", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            feces.world:add(E, A)
            feces.world:set(E, feces.replicated, function() return false end)
            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {})
            return nil
        end)
    
        -- PAIRS WITH FILTERS?
        return nil
    end)
end