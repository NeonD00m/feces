---
sidebar_position: 4
---

# Hooks

Hooks allow you to add features tied to the replication process.

:::warning
With any of the hook methods:
Only one callback can be set at a time and calling again will overwrite the previous callback.

If you'd like a signal or some sort of scheduler please set that up on your own.
:::

## [`added()`](/api/feces#added)

Hooks onto when a new **entity** is replicated to the world, not for new components.
The added callback is called *after* all the components received are set to 
a newly replicated entity. This is because there has to be at least one replicating
component under an entity for it to be added through feces.

```lua
feces.added(function(entity)
    if world:has(entity, PlayerTag) then
        print("new player added", entity)
        return
    end
    print("entity added", entity)
end)
```

## [`changed()`](/api/feces#changed)

Hooks onto when a **component** value is changed in the world. Called *before* the component's new value is set in the world. This means that you can get whether the entity has the component or not, and the previous value of the component.

This also allows you to check for values being set to `nil` and compare previous and current values.

```lua
feces.changed(function(entity, component, value)
    local had = world:has(entity, component)
    if not had then
        print("component added", component)
        return
    end
    local previous = world:get(entity, component)
    print("component changed", component, previous, "->", value)
end)
```

## [`removed()`](/api/feces#removed)

Hooks onto when a **component** is removed from the world. Called *before* removing the component from the world. This means that you can get the previous value of the component.

```lua
feces.removed(function(entity, component)
    local previous = world:get(entity, component)
    print("component removed", component, "had the value of", previous)
end)
```

## [`deleted()`](/api/feces#deleted)

Hooks onto when an **entity** is deleted in the world. This is called *before* the entity is deleted, allowing you to get the component values and clean up, fairly straightforward.

```lua
feces.deleted(function(entity)
    if world:has(entity, PlayerTag) then
        print("player has left the game", entity)
        return
    end
    print("entity deleted", entity)
end)
```
