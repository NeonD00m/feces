---
sidebar_position: 2
---

# Setup

## Simple

This option reduces code written and tools needed. In most cases, developers don't need to implement anything more complex than this unless they will be using feces to replicate large amounts of data often.

```lua
if RunService:IsServer() then
	requestFullPacket.OnServerEvent:Connect(function(player)
		remote:FireClient(player, feces.full())
	end)
else
	requestFullpacket:FireServer()
	remote.OnClientEvent:Connect(function(data)
		feces.apply(data)
	end)
end

local function replicate()
	local changes, deleted = delta()
	if not next(changes) and not next(deleted) then
		return
	end

	for player, packet in feces.combine(changes, deleted) do
		remote:FireClient(player, packet)
	end
end
```