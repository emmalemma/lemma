import {LocalDatabase} from './database'
import {watch} from './util'
import {stop, toRaw} from '@vue/reactivity'

Records = new WeakMap

dofer =(fn)->fn()

idBuilder = (innerFn)->
	id = null
	proxy = new Proxy (->),
		get: (target, prop)->
			id = prop
			proxy
		apply: (target, it, args)->
			args.unshift id
			innerFn.apply it, args

ObjectStore = ({db, version, store})->
	db = LocalDatabase.open db, version, [store]
	set: (id, value)->
		(await db).setObject store, id, value
	get: (id)->
		(await db).getObject store, id

persistenceStrategies =
	indexeddb: (options)->
		db = ObjectStore options

		store: (id, state)->
			await db.set id, state
		load: (id)->
			await db.get id

	rest: ({endpoint, id})->
		fetcher = RestFetcher endpoint

		store: (id, state)->
			await fetcher.post id, state
		load: (id)->
			await fetcher.get id

export persistence = (options)->
	for type, typeOptions of options
		strategy = persistenceStrategies[type] typeOptions

	watchRecord = (record)->
		record.watch = watch (->record.state), ->
			strategy.store record.id, toRaw record.state

	stopWatch = (record)->
		stop record.watch

	merge = (record, state)->
		stopWatch record
		if Array.isArray record.state
			record.state.splice 0, record.state.length
			record.state.push x for x in state
		else
			for k of record.state
				delete record.state[k] unless k of state
			for k, v of state
				record.state[k] = v
		watchRecord record

	persistent = (id, state)->
		record = {id, state}

		Records.set state, record

		watchRecord record

		record.loadedᴾ = dofer ->
			try
				out = await strategy.load id
			catch e
				console.error "Strategy load error", strategy, record, id
				throw e
			return unless out
			merge record, out

		return state

	return idBuilder persistent

persistence.record = (state)->
	Records.get state
