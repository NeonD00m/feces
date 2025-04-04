local core = require("./roblox_packages/feces")
local world = require("./roblox_packages/world")
local refs = require("./roblox_packages/refs")

local feces = core.new(world)
feces.refs = refs

return feces