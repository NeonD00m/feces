---
sidebar_position: 3
---
# Advanced Setup
This example will use [Blink](https://1axen.github.io/blink) to show how you could optimize packet size.
The same concepts can likely be applied to any other serialized networking library.


In our blink file events like requestFullPacket and entityDeleted are 
```lua
-- network.blink
event requestFullPacket {
	from: Client,
	type: Reliable,
	call: SingleAsync
}

type Entity = u16
event entityDeleted {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: u16[]
}

map EntityMap<T> = { [Entity]: T }
enum SpecialChange = { __n, __d }
struct ComponentPacket<T> {
	value: EntityMap<T>,
	special: EntityMap<SpecialChange>
}

event component {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: (Entity, ComponentPacket<unknown>)
}

event componentTransform {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: ComponentPacket<CFrame>
}

-- ... You'd have to make a new event to properly optimize replicating each component
```

This is very close to actual code we use at killergg for optimally replicating commonly used components. It might be verbose, but it gets the job done.

```lua
local function fire(network, player, component, entities)
	local remote = network[`component{getNameFromComponent(component)}`]
	if remote == nil then
		network.component.fire(player, component, entities)
		return
	end

	remote.fire(player, entities)
end

local function replicate()
	local network = require(ReplicatedStorage.Blink.Server)
	local fullPacket = nil
	for _, player in network.requestFullPacket.iter() do
		fullPacket = fullPacket or full()
		for component, data in fullPacket do
			fire(network, player, component, data)
		end
	end
	
	local changes, deleted = delta()
	for component, players in changes do
		for player, entities in players do
			fire(network, player, component, entities)
 		end
	end
	
	for player, entities: { number } in deleted do
		network.entityDeleted.fire(player, entities)
	end
end

local function receive()
	local network = require(ReplicatedStorage.Blink.Client)
	for _, component, entities in network.component.iter() do
		apply({ [component] = entities })
	end

	for name, id in Components do
		local remote = network[`component{getNameFromComponent(name)}`]
		if not remote then
			continue
		end
		
		for _, entities in remote.iter() do
			apply({ [id] = entities })
		end
	end

	for _, entities in network.entityDeleted.iter() do
		apply({ __d = entities })
	end
end
```