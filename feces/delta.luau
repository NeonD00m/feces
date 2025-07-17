local types = require("@feces/types")
local resolvePlayers = require("@feces/resolvePlayers")
local Players = game and game:GetService("Players")

local function fill(changes: types.Changes, comp: types.Component, ent: types.LookupEntity, value: any, action: types.ChangeType?, players: { types.TestPlayer })
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
            table.insert(entry.remove, ent)
        elseif action == types.None then
            table.insert(entry.none, ent)
        else
            entry.value[ent] = value
        end
        changes[comp][player] = entry
	end
end

local function delta(self: types.Feces, group: types.Group?): (types.Changes, types.Deletes)
    self:debug("delta changed")
    local changes = {}
    local hasGroup = group ~= nil
	group = group or self
    for comp, storage in self._storages do
		if comp == self.replicated or comp == self.grouped then
			continue
		end

        for entity: types.LocalEntity, data in storage do
			if entity == self.replicated or entity == self.grouped then
				continue
			end

			local lookup: types.LookupEntity? = if hasGroup then group.lookups[entity] else self:lookup(entity)
			if lookup == nil then
                self:debug(`X\t{entity} is not in this group: {group.origin}`)
				continue -- we only want the entities that are in this group
			end
            
            local hasRepl = self.world:has(entity, self.replicated)
            local hasPair = self.world:has(entity, self.jecs.pair(self.replicated, comp))
            if not hasRepl and not hasPair then
                continue
            end
            local players: { types.TestPlayer } = resolvePlayers(
                (
                    if hasRepl then self.world:get(entity, self.replicated)
                    else self.world:get(entity, self.jecs.pair(self.replicated, comp))
                ) :: types.PlayerObject
            )
            self:debug(`!\tresolved players: {players[1]} {players[2]} {players[3]}`)
            for i, player in players do
                if self._deleted[player] and self._deleted[player][entity] then
                    self:debug(`=\tSkipping changes because entity deleted for player {player} at entity {entity}`)
                    players[i] = nil
                end
            end

            -- self:debug("filling change:", ent, comp, data.value, data.action)
            fill(changes, comp, lookup, data.value, data.action, players)
        end
        table.clear(storage)
    end

    self:debug("delta deleted")
    local deleted: types.Deletes = {}
    for player, entities in self._deleted do
        for entity, _ in entities do
			local lookup: types.LookupEntity? = if hasGroup then group.lookups[entity] else self:lookup(entity)
			if not lookup then
                self:debug(`X\t{entity} is not in this group: {group.origin}`)
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