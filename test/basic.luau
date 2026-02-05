local frktest = require("@pkg/frktest")
local test = frktest.test
local check = frktest.assert.check

return function()
    local jecs = require("@rbx/jecs")
    local lib = require("@feces/init.luau")

    local function create()
        return lib.new(jecs, jecs.world(), nil, false) 
    end

    test.suite("basic", function()
        test.case("setup", function()
            return check.truthy(create())
        end)

        test.case("multiple components added", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A & B COMPONENTS:")
            local A = feces.world:component()
            local B = feces.world:component()
            feces:debug("EMPTY DELTA:")
            feces:delta()
            -- check.table.equal(initial, {})
            -- check.table.equal(empty, {})
            feces:debug("CHANGES:")
            feces.world:set(E, A, 1)
            feces.world:set(E, B, 2)
            feces:debug("ADDED REPLICATED")
            feces.world:add(E, feces.replicated)

            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            -- feces:debug("changes", changes)
            -- feces:debug("deleted", deleted)
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [lookup] = 1
                        },
                        remove = { },
                        none = {},
                    }
                },
                [B] = {
                    ["-1"] = {
                        value = {
                            [lookup] = 2
                        },
                        remove = { },
                        none = {},
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("multiple components changed", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A & B COMPONENTS:")
            local A = feces.world:component()
            local B = feces.world:component()

            feces:debug("CHANGES:")
            feces.world:set(E, A, 1)
            feces.world:set(E, B, 2)
            feces:debug("ADDED REPLICATED")
            feces.world:add(E, feces.replicated)

            -- call delta the first time to remove the initial state
            feces:debug("EMPTY DELTA:")
            feces:delta()
            -- feces:debug("initial", initial)
            -- feces:debug("removed", removed)

            feces:debug("CHANGES:")
            feces.world:set(E, A, 3)
            feces.world:set(E, B, 4)

            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [lookup] = 3
                        },
                        remove = { },
                        none = {},
                    }
                },
                [B] = {
                    ["-1"] = {
                        value = {
                            [lookup] = 4
                        },
                        remove = { },
                        none = {},
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("multiple components removed", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A & B COMPONENTS:")
            local A = feces.world:component()
            local B = feces.world:component()

            feces:debug("CHANGES:")
            feces.world:set(E, A, 1)
            feces.world:set(E, B, 2)
            feces:debug("ADDED REPLICATED")
            feces.world:add(E, feces.replicated)
            feces:debug("EMPTY DELTA:")
            feces:delta()

            feces:debug("REMOVED COMPONENTS:")
            feces.world:remove(E, A)
            feces.world:remove(E, B)

            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {},
                        remove = { lookup },
                        none = {},
                    }
                },
                [B] = {
                    ["-1"] = {
                        value = {},
                        remove = { lookup },
                        none = {},
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("entity deleted", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A & B COMPONENTS:")
            local A = feces.world:component()
            local B = feces.world:component()

            feces:debug("CHANGES:")
            feces.world:set(E, A, 1)
            feces.world:set(E, B, 2)
            feces:debug("ADDED REPLICATED")
            feces.world:add(E, feces.replicated)
            feces:debug("EMPTY DELTA:")
            feces:delta()

            feces:debug("DELETE ENTITY:")
            feces.world:delete(E)

            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {
                ["-1"] = { lookup }
            })
            return nil
        end)

        test.case("replicated deleted", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A & B COMPONENTS:")
            local A = feces.world:component()
            local B = feces.world:component()

            feces:debug("CHANGES:")
            feces.world:set(E, A, 1)
            feces.world:set(E, B, 2)
            feces:debug("ADDED REPLICATED")
            feces.world:add(E, feces.replicated)
            feces:debug("EMPTY DELTA:")
            feces:delta()

            feces:debug("REMOVED REPLICATED")
            feces.world:remove(E, feces.replicated)

            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {
                ["-1"] = { lookup }
            })
            return nil
        end)

        test.case("singleton", function()
            local feces = create()
            feces:debug("TIMER COMPONENT:")
            local timer = feces.world:component()
            local lookup = feces:lookup(timer)
            check.truthy(lookup == 1)
            feces:debug("SETTING TIMER COMPONENT:")
            feces.world:set(timer, timer, 10)
            feces:debug("ADDING REPLICATED")
            feces.world:add(timer, feces.replicated)

            feces:debug("DELTA:")
            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [timer] = {
                    ["-1"] = {
                        value = {
                            [lookup] = 10
                        },
                        remove = { },
                        none = { },
                    }
                }
            })
            check.table.equal(deleted, {})
            return nil
        end)

        test.case("full payload", function()
            local feces = create()
            feces:debug("ENTITY:")
            local E = feces.world:entity()
            local lookup = feces:lookup(E)
            check.truthy(lookup == 1)
            feces:debug("A & B COMPONENTS:")
            local A = feces.world:component()
            local B = feces.world:component()
            feces:debug("CHANGES:")
            feces.world:set(E, A, 1)
            feces.world:set(E, B, 2)
            feces:debug("ADDED REPLICATED")
            feces.world:add(E, feces.replicated)
            
            feces:debug("FULL:")
            local k = feces:full()
            check.table.equal(k, {
                [A] = {
                    [lookup] = {
                        value = 1,
                    },
                },
                [B] = {
                    [lookup] = {
                        value = 2,
                    },
                }
            })
            return nil
        end)

    --     test.case("contains", function()
    --         local a = { "one", "two", "three", "four", "five" }
    --         check.array.contains(a, "eleven") -- check for one value
    --         check.array.contains(a, { "four", "five", "six", "seven" }) -- check for multiple values
    --     end)

    --     test.case("equal changed", function()
    --         local a = { 1, 2, 3, 4, 5 }
    --         local b = { 1, 2, 10, 4, 5 }
    --         check.array.equal(a, b)
    --     end)

    --     test.case("equal extra", function()
    --         local a = { 1, 2, 3, 4, 5 }
    --         local b = { 1, 2, 3, 4, 5, 6, 7 }
    --         check.array.equal(a, b)
    --     end)

    --     test.case("equal fewer", function()
    --         local a = { 1, 2, 3, 4, 5 }
    --         local b = { 1, 2, 3 }
    --         check.array.equal(a, b)
    --     end)

    --     test.case("equal changed and more", function()
    --         local a = { 1, 2, 3, 4, 5 }
    --         local b = { 1, 20, 3, 4, 5, 6, 7 }
    --         check.array.equal(a, b)
    --     end)

    --     test.case("for arrays with tables, you should use check.table.equal", function()
    --         local a = { { a = 1 }, { a = 2 } }
    --         local b = { { a = 1 }, { a = 2 } }
    --         check.array.equal(a, b)
    --     end)

        return nil
    end)
end