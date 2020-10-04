import {reactive, effect, toRaw} from '@vue/reactivity'
import {watch} from 'vue'
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
	shell = reactive
		value: state.value

	record = reactive
		id: state.id
		rev: state.rev or -1

		store: state.store or 'uncategorized'
		state: 'pending'
		owner: state.owner
		watch: ->
			record._watchStop ?= watch (->shell.value), (->
				if record.state is 'synced'
					record.rev += 1
					persist.sync shell), deep: true
		unwatch: ->
			record._watchStop()
			record._watchStop = null

	if record.owner is 'remote'
		record.retrieve =-> fetcher.get "#{remote.url}/#{record.store}/#{record.id or ''}"
		record.push =-> fetcher.post "#{remote.url}/#{record.store}/#{record.id}", body: {id: record.id, rev: record.rev, value: toRaw shell.value}
	else if record.owner is 'local'
		record.retrieve =->
			out = await (await local.database).getObject record.store, record.id
			out
		record.push =->
			await (await local.database).setObject record.store, record.id, id: record.id, rev: record.rev, value: toRaw shell.value
			{value: shell.value, id: record.id, rev: record.rev}

	record.watch()
	PersistentRecords.set shell, record

	unless state.sync is no
		persist.sync shell

	shell

persist.record =(shell)->
	PersistentRecords.get shell

persist.promise =(shell)->
	persist.record(shell).promise

persist.all = ({store, owner})->
	shell = reactive []
	PersistentRecords[shell] = record =
		store: store
		owner: owner
	record.promise = doAsync ->
		allResults = await if record.owner is 'remote'
			Object.values await fetcher.get "#{remote.url}/#{record.store}"
		else if record.owner is 'local'
			(await local.database).getAll record.store

		for result in allResults
			result.sync = no
			result.owner = record.owner
			shell.push persist result

	shell

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
			shell.value = result.value
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
			if result.state is 'raced'
				record.stale = shell.value
				record.unwatch()
				shell.value = result.value
				record.watch()
			record.state = 'synced'

		shell


export remote = (record)->
	record.owner = 'remote'
	persist record

remote.connect = (url)->
	remote.url = url

export local = (record)->
	record.owner = 'local'
	persist record

local.connect = (database, version, stores = [])->
	local.database = LocalDatabase.open database, version, stores
