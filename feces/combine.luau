local types = require("@feces/types")

local function combine(changes: types.Changes, deleted: types.Deletes?): { [types.TestPlayer]: types.Applyable }
	local packets: { [types.TestPlayer]: types.Applyable } = {}

	for component, players in changes do
		for player, entities in players do
			packets[player] = packets[player] or { __d = {} }
			packets[player][component] = packets[player][component] or { }
			for entity, value in entities.value do
				packets[player][component][entity] = { value = value }
			end
			for _, entity in entities.remove do
				packets[player][component][entity] = { action = types.Remove }
			end
			for _, entity in entities.none do
				packets[player][component][entity] = { action = types.None }
			end
		end
	end

	if deleted then
		for player, entities in deleted do
			packets[player] = packets[player] or { __d = {} }
			packets[player].__d = entities
		end
	end

	return packets
end

return combine