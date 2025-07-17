local jecs = require("@test/jecs_0_8_3")

export type Jecs = typeof(jecs)

type Entity<T = any> = jecs.Entity<T> & number

type Observer = {
	callback: (Entity) -> (),
	query: jecs.Query<...jecs.Id>,
}

export type World = jecs.World & {
	added: <T>(World, jecs.Id<T>, (Entity, jecs.Id, T) -> ()) -> () -> (),
	removed: <T>(World, jecs.Id<T>, (Entity, jecs.Id) -> ()) -> () -> (),
	changed: <T>(World, jecs.Id<T>, (Entity, jecs.Id, T) -> ()) -> () -> (),
	observer: (World, Observer) -> (),
	deleted: <T>(World, Entity, (Entity) -> ()) -> (),
	monitor: (World, Observer) -> (),
}

export type LocalEntity = Entity
export type LookupEntity = Entity
export type Component<T = any> = Entity<T>

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
			action: ChangeType?,
			value: any?,
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
			action: ChangeType?
		}
	}
} & { __d: { LookupEntity } }

export type Lib = {
	new: (Jecs, World, Group?, boolean?) -> Feces,
	combine: (Changes, Deletes?) -> { [TestPlayer]: Applyable },
	reserve: (number) -> Group, -- creates a group of entities with a separate lookup 
}

export type Feces = Lib & Group & {
	DEBUG: boolean?,
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
	
	debug: (self: Feces, ...any) -> (),
	lookup: (self: Feces, key: LocalEntity?, group: Group?) -> LookupEntity,
	ref: (self: Feces, key: LookupEntity?, group: Group?) -> LocalEntity,

	apply: (self: Feces, delta: Applyable, group: Group?) -> (),
	delta: (self: Feces, group: Group?) -> (Changes, Deletes),
	full: (self: Feces, group: Group?) -> Applyable,

	added: (self: Feces, (LocalEntity) -> nil) -> (),
	changed: (self: Feces, (LocalEntity, Component, any) -> ()) -> (),
	removed: (self: Feces, (LocalEntity, Component) -> ()) -> (),
	deleted: (self: Feces, (LocalEntity) -> nil) -> (),
	_hooks: {
		added: ((LocalEntity) -> ())?,
		changed: ((LocalEntity, Component, any) -> ())?,
		removed: ((LocalEntity, Component) -> ())?,
		deleted: ((LocalEntity) -> ())?,
	},
}

return {
	None = 0x1,
	Remove = 0x2,
	Delete = "__d",
}