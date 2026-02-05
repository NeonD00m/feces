local types = require("@feces/types")

local function added(self: types.Feces, callback: (types.LocalEntity) -> ())
	self._hooks.added = callback
end

local function changed(self: types.Feces, callback: (types.LocalEntity, types.Component, any) -> ())
	self._hooks.changed = callback
end

local function removed(self: types.Feces, callback: (types.LocalEntity, types.Component) -> ())
	self._hooks.removed = callback
end

local function deleted(self: types.Feces, callback: (types.LocalEntity) -> ())
	self._hooks.deleted = callback
end

return {
    added = added,
    changed = changed,
    removed = removed,
    deleted = deleted,
}