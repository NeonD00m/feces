---
sidebar_position: 1
---

# Introduction

Feces is a library for replicating jecs entities and components. Here are some examples:
```lua
local entity = world:entity()
local Transform = world:component()
world:add(entity, Transform)

-- replicate all the components to all players
world:add(entity, feces.replicated)

-- replicate only the Transform component to all players
world:add(entity, pair(feces.replicated, Transform)) 

-- replicate all components to a specific player
world:set(entity, feces.replicated, Player1)

-- replicate only the Transform component to a table of players
world:set(entity, pair(feces.replicated, Transform), {
    Player1, Player2
})

-- replicate all components to any player except Player1
world:add(entity, feces.replicated, function(player)
    return player ~= Player1
end)
```

## Installation
Currently only available on [pesde](https://pesde.dev/packages/killergg/feces_core).


## Details

The goal of feces is not to directly handle your replication with remotes, but to provide the simplest, most efficient, and flexible way to replicate data between jecs worlds.

Feces requires a couple specific conditions to work correctly:
1. The components should all be created before a feces object is created.
2. The components should all be the same entity ids, basically just create the replicated components in the same order on all worlds.