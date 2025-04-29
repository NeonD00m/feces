local frktest = require("@pkg/frktest")
local test = frktest.test
local check = frktest.assert.check

return function()
    local jecs = require("../luau_packages/jecs")
    local o = require("../roblox_packages/observers")
    local lib = require("../pkgs/auto/auto.luau")

    local feces = nil

    test.suite("basic", function()
        test.case("setup", function()
            feces = lib.new(o(jecs.World.new())) 
            check.truthy(feces)
        end)

        test.case("multiple components added", function()
            local entity = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()

            feces.world:set(entity, A, 1)
            feces.world:set(entity, B, 2)
            feces.world:set(entity, feces.replicated)

            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        [entity] = 1
                    }
                },
                [B] = {
                    ["-1"] = {
                        [entity] = 2
                    }
                }
            })
            check.table.equal(deleted, {})
        end)

        test.case("multiple components changed", function()
            local entity = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()

            feces.world:set(entity, A, 1)
            feces.world:set(entity, B, 2)
            feces.world:set(entity, feces.replicated)
            feces:delta()

            feces.world:set(entity, A, 3)
            feces.world:set(entity, B, 4)

            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        [entity] = 3
                    }
                },
                [B] = {
                    ["-1"] = {
                        [entity] = 4
                    }
                }
            })
            check.table.equal(deleted, {})
        end)

        test.case("multiple components removed", function()
            local entity = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()

            feces.world:set(entity, A, 1)
            feces.world:set(entity, B, 2)
            feces.world:set(entity, feces.replicated)
            feces:delta()

            feces.world:remove(entity, A)
            feces.world:remove(entity, B)

            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [A] = {
                    ["-1"] = {
                        [entity] = 1
                    }
                },
                [B] = {
                    ["-1"] = {
                        [entity] = 2
                    }
                }
            })
            check.table.equal(deleted, {})
        end)

        test.case("entity deleted", function()
            local entity = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()

            feces.world:set(entity, A, 1)
            feces.world:set(entity, B, 2)
            feces.world:set(entity, feces.replicated)
            feces:delta()

            feces.world:delete(entity)

            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {
                ["-1"] = { entity }
            })
        end)

        test.case("replicated deleted", function()
            local entity = feces.world:entity()
            local A = feces.world:component()
            local B = feces.world:component()

            feces.world:set(entity, A, 1)
            feces.world:set(entity, B, 2)
            feces.world:set(entity, feces.replicated)
            feces:delta()

            feces.world:remove(entity, feces.replicated)

            local changes, deleted = feces:delta()
            check.table.equal(changes, {})
            check.table.equal(deleted, {
                ["-1"] = { entity }
            })
        end)

        test.case("singleton", function()
            local timer = feces.world:component()
            feces.world:set(timer, timer, 10)
            feces.world:set(timer, feces.replicated)

            local changes, deleted = feces:delta()
            check.table.equal(changes, {
                [timer] = {
                    ["-1"] = {
                        [timer] = 10
                    }
                }
            })
            check.table.equal(deleted, {})
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