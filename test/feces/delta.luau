local types = require("./types")
local resolvePlayers = require("./resolvePlayers")
local Players = game and game:GetService("Players")

local function fill(changes: types.Changes, comp: types.Component, ent: types.LookupEntity, value: any, action: types.ChangeType, players: { types.TestPlayer })
	if not comp or not ent then
		warn("[feces] Cannot fill changes with nil component or entity.")
        return
	end

	for _, player in players do
        changes[comp] = changes[comp] or {}
		if game and (typeof(player) ~= "Instance" or not player:IsDescendantOf(Players)) then
            continue
        end

        local entry = changes[comp][player] or { value = {}, remove = {}, none = {} }
        if action == types.Remove then
            entry.remove[ent] = value
        elseif action == types.None then
            entry.none[ent] = value
        else
            entry.value[ent] = value
        end
        changes[comp][player] = entry
	end
end

local function delta(self: types.Feces, group: types.Group?): (types.Changes, types.Deletes)
    local changes = {}
	group = group or self
    for comp, storage in self._storages do
		if comp == self.replicated or comp == self.grouped then
			continue
		end

        for ent: types.LocalEntity, data in storage do
			if ent == self.replicated or ent == self.grouped then
				continue
			end

			local lookup: types.LookupEntity = group.lookups[ent]
			if not lookup then
				continue -- we only want the entities that are in this group
			end

            local players = resolvePlayers(data.players)
            for i, player in players do
                if self._deleted[player] and self._deleted[player][ent] then
                    print("SKIPPING COMPONENT CHANGE FOR PLAYER BECAUSE OF DELETION", player, ent)
                    players[i] = nil
                end
            end

            -- print("filling change:", ent, comp, data.value, data.action)
            fill(changes, comp, lookup, data.value, data.action, players)
        end
        table.clear(storage)
    end

    local deleted: types.Deletes = {}
    for player, entities in self._deleted do
        for entity, _ in entities do
			local lookup: types.LookupEntity = group.lookups[entity]
			if not lookup then
				continue -- we only want the entities that are in this group
			end
            deleted[player] = deleted[player] or {}
            table.insert(deleted[player], lookup)
            self._deleted[player][entity] = nil
        end
    end

    return changes, deleted
end

return delta