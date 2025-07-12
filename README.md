<div align="center">
    <img src="https://raw.githubusercontent.com/NeonD00m/feces/refs/heads/main/images/thelogo.png" width="600" />
</div>

#### _"Fast Entity Component Export System" - By Killer Games_

A generalized replication system for [jecs](https://github.com/ukendio/jecs) that allows for easy and fast replication of components.

#### [docs](https://neond00m.github.io/feces/) | [pesde](https://pesde.dev/packages/killergg/feces)

<br>

### Examples

```luau
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

<br>

### Installation
Either copy the code manually or use pesde:
```sh
pesde add killergg/feces
```
