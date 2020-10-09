import {reactive, effect, toRaw, stop} from '@vue/reactivity'
import {watch} from './util'
import {LocalDatabase} from './database'

import {fetcher, doAsync} from './remoting'
#
#	target api:
# 	object = remote id: x
#	await remote.resolve object
#	await remote.load object
#	await remote.sync object
#

# 1. load on read
# 2. save on write
# 3. populate cursors

PersistentRecords = new WeakMap

remote = local = persist = null

export persist = (state = {})->
	shell = reactive state.value

	record = reactive
		id: state.id
		rev: state.rev ? -1

		store: state.store or 'uncategorized'
		state: 'pending'
		owner: state.owner
		value: shell
		watch: ->
			console.log 'watching', shell
			record._effect ?= watch (->shell), (->
				console.log 'saving record', record
				if record.state is 'synced'
					record.rev += 1
					persist.sync shell), deep: true
		unwatch: ->
			stop record._effect
			record._effect = null

	if record.owner is 'remote'
		record.retrieve =-> fetcher.get "#{remote.url}/#{record.store}/#{record.id or ''}"
		record.push =-> fetcher.post "#{remote.url}/#{record.store}/#{record.id}", body: {id: record.id, rev: record.rev, value: toRaw shell}
	else if record.owner is 'local'
		record.retrieve =->
			out = await (await local.database).getObject record.store, record.id
			out
		record.push =->
			await (await local.database).setObject record.store, record.id, id: record.id, rev: record.rev, value: toRaw shell
			{value: shell, id: record.id, rev: record.rev}

	record.watch()
	PersistentRecords.set shell, record

	unless state.sync is no
		persist.sync shell
	else
		record.state = 'synced'

	shell

persist.record =(shell)->
	PersistentRecords.get shell

persist.promise =(shell)->
	persist.record(shell).promise

persist.collection = ({store, owner})->
	shell = reactive {}

	PersistentRecords[shell] = record =
		store: store
		owner: owner

	proxy = new Proxy (shell),
		get: (target, prop)-> target[prop]
		has: (target, key)->key in target
		getOwnPropertyDescriptor: (target, key) -> Object.getOwnPropertyDescriptor target, key
		set: (target, prop, value)->
			persisted =
				store: record.store
				id: prop
				rev: 0
				value: value
			if record.owner is 'local'
				await (await local.database).setObject record.store, prop, {id: prop, rev: 0, value}
				return target[prop] = local persisted
		deleteProperty: (target, prop)->
			await if record.owner is 'local'
				(await local.database).deleteObject record.store, prop
			delete target[prop]
			prop

	record.promise = doAsync ->
		allResults = await if record.owner is 'remote'
			Object.values await fetcher.get "#{remote.url}/#{record.store}"
		else if record.owner is 'local'
			(await local.database).getAll record.store

		for result in allResults
			result.sync = no
			result.owner = record.owner
			result.store = record.store
			console.log 'collection persisting', result
			shell[result.id] = persist result
	# watch.shallow (->shell), ->
	# 	for
	#
	proxy

persist.destroy =(shell)->
	record = persist.record shell
	if record.owner is 'local'
		(await local.database).deleteObject record.store, record.id

persist.sync = (shell)->
	record = persist.record(shell)
	record.promise = doAsync ->
		record.state = 'loading'
		try
			result = await record.retrieve()
		catch e
			unless e.status is 404
				throw e
				e = null

		if result and result.rev > record.rev
			record.unwatch()
			shell[k] = v for k, v of result.value
			record.watch()

			record.id = result.id
			record.rev = result.rev
			record.state = 'synced'

		else if not result or record.rev > result.rev
			if not result
				record.rev = 0

			record.state = 'saving'
			result = await record.push()

			record.id = result.id
			record.rev = result.rev
			record.state = 'synced'

		shell


export remote = (record)->
	record.owner = 'remote'
	persist record

remote.connect = (url)->
	remote.url = url

remote.cursor = (record)->
	record.owner = 'remote'
	persist.cursor record

export local = (record)->
	record.owner = 'local'
	persist record

local.collection = (record)->
	record.owner = 'local'
	persist.collection record

local.connect = (database, version, stores = [])->
	local.database = LocalDatabase.open database, version, stores
