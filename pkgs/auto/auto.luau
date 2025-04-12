local core = require("./roblox_packages/feces")
local world = require("./roblox_packages/world")
local refs = require("./roblox_packages/refs")
local observers = require("./roblox_packages/observers")


local feces = core.new(observers(world))
feces.refs = refs

return feces