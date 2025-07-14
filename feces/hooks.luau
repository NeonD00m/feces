local types = require("./types")

local function added(self: types.Feces, callback: (types.LocalEntity) -> nil)
	self._hooks.added = callback
end

local function changed(self: types.Feces, callback: (types.LocalEntity, types.Component, any) -> nil)
	self._hooks.changed = callback
end

local function removed(self: types.Feces, callback: (types.LocalEntity, types.Component) -> nil)
	self._hooks.removed = callback
end

local function deleted(self: types.Feces, callback: (types.LocalEntity) -> nil)
	self._hooks.deleted = callback
end

return {
    added = added,
    changed = changed,
    removed = removed,
    deleted = deleted,
}