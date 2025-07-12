local types = require("./types")

local function added(self: types.feces, callback: (types.LocalEntity) -> nil)
	self.hooks.added = callback
end

local function changed(self: types.feces, callback: (types.LocalEntity, types.Component, any) -> nil)
	self.hooks.changed = callback
end

local function removed(self: types.feces, callback: (types.LocalEntity, types.Component) -> nil)
	self.hooks.removed = callback
end

local function deleted(self: types.feces, callback: (types.LocalEntity) -> nil)
	self.hooks.deleted = callback
end

return {
    added = added,
    changed = changed,
    removed = removed,
    deleted = deleted,
}