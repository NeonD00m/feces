--[[

RUN WITH:

lune run test/_run.luau

]]

function load_tests()
    -- tests execute in the order they are loaded
    require("./basic")()
    require("./advanced")()
    require("./groups")()
end

function run_tests()
    local frktest = require("@pkg/frktest")
    local lune_console_reporter = frktest._reporters.lune_console_reporter

    lune_console_reporter.init()
    local success = frktest.run()
    if not success then
        require("@lune/process").exit(1)
    end
end

load_tests()
run_tests()