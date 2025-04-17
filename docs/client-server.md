---
title: Client To Server
sidebar_position: 5
---
# Client To Server

:::warning
This is not a recommended use of feces, but since one might want to minimize libraries used for replication or reduce manual replication logic in their own code, here is a fairly secure way to do it.
:::

Theoretically, you can follow two approaches:

1. Each player will have their own entity for every component they can replicate to the server
- On the server, you would verify packets by making sure checking that the replicated entities contains the `pair(replicated, replicated)` component:
```lua
--setting up an entity for a player to replicate to the server (on the server)
world:set(entity, jecs.pair(replicated, replicated), sendingPlayer)

--check packets
local permission = world:get(entity, jecs.pair(replicated, replicated)) == sendingPlayer
```

2. Or, on the client you will have to create `replicated` components under entities that the client knows it can replicate to the server
- On the server, you would have to `filter()` packets received from clients, and then check if the player who sent the packet has permission with:
```lua
--setting up an entity for a player to replicate a specific component to the server (on the server)
world:set(entity, pair(replicated, someComponent), sendingPlayer)

--check packets
local permission = world:get(entity, pair(replicated, someComponent)) == sendingPlayer
```

Assuming you are using the simple setup, you can use the following code to replicate to the server:
```lua
WIP
```
