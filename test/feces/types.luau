type Entity<T = any> = number & { __t: T }

export type LocalEntity = Entity
export type LookupEntity = Entity
export type Component<T = any> = Entity<T> & number

export type nilValue = "__n"
export type deleteValue = "__d"

export type PlayerObject = Player? | { Player } | (Player) -> boolean
export type refs = { [string]: Entity }
export type group = {
	origin: string,
	size: number,
	lookups: { [LocalEntity]: LookupEntity }, -- get the replicatable lookup id from an entity in this world
	refs: { [LookupEntity]: LocalEntity }, -- get the entity from this world from its replication lookup id
}

export type changes = {
	[Component]: {
		[Player]: {
			value: { [Entity]: any },
			remove: { [Entity]: deleteValue },
			nil: { [Entity]: nilValue },
		},
	},
}

export type pendingDeletes = {
	[Player]: { [Entity]: true },
}

export type deletes = {
	[Player]: { Entity },
}

export type applyable = {
	[Component]: {
		value: { [LookupEntity]: any },
		remove: { [LookupEntity]: deleteValue },
		nil: { [LookupEntity]: deleteValue },
	},
} & { __d: { LookupEntity } }

export type lib<jecs> = {
	new: (typeof(jecs.World)) -> feces,
	combine: (changes, deletes?) -> { [Player]: applyable },
	reserve: (size: number) -> group, -- creates a group of entities with a separate lookup 
}

export type feces<jecs> = lib<jecs> & group & {
	replicated: jecs.Component<PlayerObject>,
	grouped: jecs.Component<group>,
	queries: {
		single: jecs.Query,
		pair: jecs.Query,
	},
	world: jecs.World,
	pendingChanges: changes,
	pendingDeletes: pendingDeletes,
    storages: { [Component]: { [Entity]: { value: any, players: { Player } } } },

	lookup: (self: feces, key: LocalEntity?, group: group?) -> LookupEntity,
	ref: (self: feces, key: LookupEntity?, group: group?) -> LocalEntity,

	apply: (self: feces, delta: applyable, group: group?) -> nil,
	delta: (self: feces, group: group?) -> (changes, deletes),
	full: (self: feces, group: group?) -> applyable,

	added: (self: feces, (Entity) -> nil) -> nil,
	changed: (self: feces, (Entity, Component, any) -> nil) -> nil,
	removed: (self: feces, (Entity, Component) -> nil) -> nil,
	deleted: (self: feces, (Entity) -> nil) -> nil,
	hooks: {
		added: ((Entity) -> nil)?,
		changed: ((Entity, Component, any) -> nil)?,
		removed: ((Entity, Component) -> nil)?,
		deleted: ((Entity) -> nil)?,
	},
}