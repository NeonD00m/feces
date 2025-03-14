"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[450],{5342:e=>{e.exports=JSON.parse('{"functions":[{"name":"apply","desc":"Applies changes to the world by taking in the [`applyable`](/api/feces#applyable) type and editing the world. \\n```lua\\nfeces.apply({\\n\\t[someComponent] = {\\n\\t\\t[someForeignEntity] = someValue,\\n\\t}\\n})\\n```","params":[{"name":"delta","desc":"","lua_type":"applyable\\r\\n"}],"returns":[],"function_type":"static","source":{"line":267,"path":"src/init.luau"}},{"name":"delta","desc":"Gets the world changes from the last time it was called.\\n```lua\\nlocal changedComponents, deletedEntities = feces.delta()\\n-- ... replicate however you\'d like or see the examples [here](/docs/setup)\\n```","params":[],"returns":[{"desc":"","lua_type":"changes"},{"desc":"","lua_type":"deletes"}],"function_type":"static","source":{"line":346,"path":"src/init.luau"}},{"name":"group","desc":"Reformats the results of [`delta()`](/api/feces#delta) into an easier format to replicate.\\nNot optimal, but recommended if performance of feces-replicated entities is not a concern.\\n```lua\\nlocal dataByPlayer = feces.group(feces.delta())\\nfor player, packet in dataByPlayer do\\n\\tsomeRemote:FireClient(player, packet)\\nend\\n-- see more of this example [here](/docs/setup#simple)\\n```","params":[{"name":"changes","desc":"","lua_type":"changes"},{"name":"deleted","desc":"","lua_type":"deletes?"}],"returns":[{"desc":"","lua_type":"{ [Player]: applyable }\\r\\n"}],"function_type":"static","source":{"line":402,"path":"src/init.luau"}},{"name":"full","desc":"Gets all the currently replicating component and entity values.\\n:::tip\\nThis is useful for providing payloads to new players when they first join a server.\\n:::\\n```lua\\nlocal changedComponents = feces.full()\\n-- ... replicate however you\'d like or see the examples [here](/docs/setup)\\n```","params":[],"returns":[{"desc":"","lua_type":"applyable\\r\\n"}],"function_type":"static","source":{"line":438,"path":"src/init.luau"}},{"name":"added","desc":"Adds a callback for when an entity is added to the world through [`apply()`](/api/feces#apply).\\nCalled *after* **a** (not all) component value is set to a newly replicated entity.\\nSee how you might use this [here](/docs/hooks#added).","params":[{"name":"callback","desc":"","lua_type":"(Entity) -> nil"}],"returns":[],"function_type":"static","source":{"line":461,"path":"src/init.luau"}},{"name":"changed","desc":"Adds a callback for when a component value is changed in the world through [`apply()`](/api/feces#apply).  \\nCalled *before* the component in question is changed, deleted, or set to `nil`.\\nSee how you might use this [here](/docs/hooks#changed).","params":[{"name":"callback","desc":"","lua_type":"(Entity, Component, any) -> nil"}],"returns":[],"function_type":"static","source":{"line":470,"path":"src/init.luau"}},{"name":"removed","desc":"Adds a callback for when a component is removed in the world through [`apply()`](/api/feces#apply).   \\nCalled *before* the component in question is removed.\\nSee how you might use this [here](/docs/hooks#removed).","params":[{"name":"callback","desc":"","lua_type":"(Entity, Component) -> nil"}],"returns":[],"function_type":"static","source":{"line":479,"path":"src/init.luau"}},{"name":"deleted","desc":"Adds a callback for when an entity is deleted in the world through [`apply()`](/api/feces#apply).   \\nCalled *before* the entity in question is deleted, allowing hooks to get component values and clean up.\\nSee how you might use this [here](/docs/hooks#deleted).","params":[{"name":"callback","desc":"","lua_type":"(Entity) -> nil"}],"returns":[],"function_type":"static","source":{"line":488,"path":"src/init.luau"}}],"properties":[{"name":"replicated","desc":"The feces library for replicating jecs entities and components.","lua_type":"Component","source":{"line":87,"path":"src/init.luau"}}],"types":[{"name":"changes","desc":" \\nHow changes are represented and returned from [`delta()`](/api/feces#delta).","lua_type":"{ [Component]: { [Player]: { value: { [Entity]: any }, special: { [Entity]: deleteValue | nilValue } } } }","source":{"line":33,"path":"src/init.luau"}},{"name":"deletes","desc":"How deleted entities are represented.","lua_type":"{ [Player]: { Entity } }","source":{"line":46,"path":"src/init.luau"}},{"name":"applyable","desc":"Funkier type for how applyable changes should be formated.","lua_type":"{ [Component]: { value: { [Entity]: any }, special: { [Entity]: deleteValue | nilValue } } } & { __d: { Entity } }","source":{"line":54,"path":"src/init.luau"}}],"name":"feces","desc":"The feces library for replicating jecs entities and components.","source":{"line":7,"path":"src/init.luau"}}')}}]);