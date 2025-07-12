local jecs = require("../../luau_packages/jecs")

export type Jecs = typeof(jecs)

type Observer = {
	callback: (jecs.Entity) -> (),
	query: jecs.Query<...jecs.Id>,
}

export type World = jecs.World & {
	added: <T>(World, jecs.Id<T>, (jecs.Entity, jecs.Id, T) -> ()) -> () -> (),
	removed: <T>(World, jecs.Id<T>, (jecs.Entity, jecs.Id) -> ()) -> () -> (),
	changed: <T>(World, jecs.Id<T>, (jecs.Entity, jecs.Id, T) -> ()) -> () -> (),
	observer: (World, Observer) -> (),
	deleted: <T>(World, jecs.Entity, (jecs.Entity) -> ()) -> (),
	monitor: (World, Observer) -> (),
}

export type LocalEntity = jecs.Entity
export type LookupEntity = jecs.Entity
export type Component<T = any> = jecs.Entity<T>

export type None = number
export type Remove = number
export type ChangeType = number

export type TestPlayer = Player | string

export type PlayerObject = TestPlayer? | { TestPlayer } | (TestPlayer) -> boolean
export type Refs = { [string]: jecs.Entity }
export type Group = {
	origin: string,
	size: number,
	lookups: { [LocalEntity]: LookupEntity }, -- get the replicatable lookup id from an entity in this world
	refs: { [LookupEntity]: LocalEntity }, -- get the entity from this world from its replication lookup id
}

export type Changes = {
	[Component]: {
		[TestPlayer]: {
			value: { [LookupEntity]: any },
			remove: { LookupEntity },
			none: { LookupEntity }
		}
	}
}

export type NoneComponents = {
	[Component]: { LookupEntity }
}

export type PendingDeletes = {
	[TestPlayer]: { [LookupEntity]: true },
}

export type Storages = {
	[Component]: {
		[LocalEntity]: {
			action: ChangeType,
			value: any?,
			players: { TestPlayer }
		}
	}
}

export type Deletes = {
	[TestPlayer]: { LookupEntity },
}

export type Applyable = {
	[Component]: {
		[LookupEntity]: {
			value: any,
			action: ChangeType
		}
	}
} & { __d: { LookupEntity } }

export type Lib = {
	new: (World) -> Feces,
	combine: (Changes, Deletes?) -> { [TestPlayer]: Applyable },
	reserve: (number) -> Group, -- creates a group of entities with a separate lookup 
}

export type Feces = Lib & Group & {
	jecs: Jecs,
	world: World,
	replicated: Component<PlayerObject>,
	grouped: Component<Group>,

	queries: {
		single: jecs.Query<Component<PlayerObject>>,
		pair: jecs.Query<jecs.Pair<Component<PlayerObject>, jecs.Entity>>,
	},

	_deleted: PendingDeletes,
	_storages: Storages,
	
	lookup: (self: Feces, key: LocalEntity?, group: Group?) -> LookupEntity,
	ref: (self: Feces, key: LookupEntity?, group: Group?) -> LocalEntity,

	apply: (self: Feces, delta: Applyable, group: Group?) -> nil,
	delta: (self: Feces, group: Group?) -> (Changes, Deletes),
	full: (self: Feces, group: Group?) -> Applyable,

	added: (self: Feces, (LocalEntity) -> nil) -> nil,
	changed: (self: Feces, (LocalEntity, Component, any) -> nil) -> nil,
	removed: (self: Feces, (LocalEntity, Component) -> nil) -> nil,
	deleted: (self: Feces, (LocalEntity) -> nil) -> nil,
	_hooks: {
		added: ((LocalEntity) -> nil)?,
		changed: ((LocalEntity, Component, any) -> nil)?,
		removed: ((LocalEntity, Component) -> nil)?,
		deleted: ((LocalEntity) -> nil)?,
	},
}

return {
	None = 0x1,
	Remove = 0x2,
}