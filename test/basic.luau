local frktest = require("@pkg/frktest")
local test = frktest.test
local check = frktest.assert.check

return function()
    local jecs = require("../luau_packages/jecs")
    local o = require("./observers")
    local lib = require("./feces_current")

    local function create()
        return lib.new(jecs, o(jecs.World.new())) 
    end

    test.suite("basic", function()
        test.case("setup", function()
            check.truthy(create())
        end)

        test.case("multiple components added", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()
            local initial, empty = feces:delta()
            -- check.table.equal(initial, {})
            -- check.table.equal(empty, {})
            -- print("entity:", E)
            -- print("component A:", A)
            -- print("component B:", B)
            feces.world:set(E, A, 1)
            -- print("set A to 1")
            feces.world:set(E, B, 2)
            -- print("set B to 2")
            feces.world:add(E, feces.replicated)
            -- print("added replicated")

            local changes, deleted = feces:delta()
            -- print("changes", changes)
            -- print("deleted", deleted)
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [E] = 1
                        },
                        special = {}
                    }
                },
                [B] = {
                    ["-1"] = {
                        value = {
                            [E] = 2
                        },
                        special = {}
                    }
                }
            })
            check.table.equal(deleted, {})
        end)

        test.case("multiple components changed", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()

            feces.world:set(E, A, 1)
            feces.world:set(E, B, 2)
            feces.world:add(E, feces.replicated)

            -- call delta the first time to remove the initial state
            local initial, removed = feces:delta()
            -- print("initial", initial)
            -- print("removed", removed)

            feces.world:set(E, A, 3)
            feces.world:set(E, B, 4)

            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {
                            [E] = 3
                        },
                        special = {},
                    }
                },
                [B] = {
                    ["-1"] = {
                        value = {
                            [E] = 4
                        },
                        special = {},
                    }
                }
            })
            check.table.equal(deleted, {})
        end)

        test.case("multiple components removed", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()

            feces.world:set(E, A, 1)
            feces.world:set(E, B, 2)
            feces.world:add(E, feces.replicated)
            feces:delta()

            feces.world:remove(E, A)
            feces.world:remove(E, B)

            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        value = {},
                        special = {
                            [E] = "__d"
                        },
                    }
                },
                [B] = {
                    ["-1"] = {
                        value = {},
                        special = {
                            [E] = "__d"
                        },
                    }
                }
            })
            check.table.equal(deleted, {})
        end)

        test.case("entity deleted", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()

            feces.world:set(E, A, 1)
            feces.world:set(E, B, 2)
            feces.world:add(E, feces.replicated)
            feces:delta()

            feces.world:delete(E)

            local changes, deleted = feces:delta()
            print("changes", changes)
            print("deleted", deleted)
            check.table.equal(changes, {})
            check.table.equal(deleted, {
                ["-1"] = { E }
            })
        end)

        test.case("replicated deleted", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()

            feces.world:set(E, A, 1)
            feces.world:set(E, B, 2)
            feces.world:add(E, feces.replicated)
            feces:delta()

            feces.world:remove(E, feces.replicated)

            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {
                ["-1"] = { E }
            })
        end)

        test.case("singleton", function()
            local feces = create()
            local timer = feces.world:component()
            feces.world:set(timer, timer, 10)
            feces.world:add(timer, feces.replicated)

            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [timer] = {
                    ["-1"] = {
                        value = {
                            [timer] = 10
                        },
                        special = {
                            -- [timer] = "__n"
                        }
                    }
                }
            })
            check.table.equal(deleted, {})
        end)

        test.case("full payload", function()
            local feces = create()
            local E = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()
            -- print("entity:", E)
            -- print("component A:", A)
            -- print("component B:", B)
            feces.world:set(E, A, 1)
            -- print("set A to 1")
            feces.world:set(E, B, 2)
            -- print("set B to 2")
            feces.world:add(E, feces.replicated)
            -- print("added replicated")

            local k = feces:full()
            check.table.equal(k, {
                [A] = {
                    value = {
                        [E] = 1
                    },
                    special = {}
                },
                [B] = {
                    value = {
                        [E] = 2
                    },
                    special = {}
                }
            })
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
    end)
end