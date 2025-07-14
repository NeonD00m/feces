local core = require("./roblox_packages/core")
local observers = require("./roblox_packages/observers")
local jecs = require("./roblox_packages/jecs")

local feces = core.new(jecs, observers(jecs.World.new()))

return feces