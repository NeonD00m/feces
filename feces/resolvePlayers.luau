local Players = game and game:GetService("Players")

local types = require("@feces/types")

local function resolvePlayers(filter: types.PlayerObject): { types.TestPlayer }
    if type(filter) == "function" then
        local out = {}
        for _, player in (if game then Players:GetPlayers() else { "-1" }) do
            local result = filter(player)
            if result then
                table.insert(out, player)
            end
        end
        return out
    elseif type(filter) == "table" then
        return filter
    elseif typeof(filter) == "Instance" or typeof(filter) == "string" then
        return { filter }
    else
		return if game then Players:GetPlayers() else { "-1" }
    end
end

return resolvePlayers