import {reactive, watch, toRaw} from 'vue'
import {LocalDatabase} from './database'

import {fetcher} from './remoting'
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

export remote = (state = {})->
	shell = reactive
		value: state.value
		id: state.id
		rev: state.rev or -1

		store: state.store or 'uncategorized'
		state: 'pending'
		owner: 'remote'
	remote.sync shell
	watch (->shell.value), (->
		if shell.state is 'synced'
			shell.rev += 1
			remote.sync shell), deep: true
	shell

remote.connect = (url)->
	remote.url = url

remote.sync = (remoteObject)->
	remoteObject.state = 'loading'
	try
		result = await fetcher.get "#{remote.url}/#{remoteObject.store}/#{remoteObject.id or ''}"
	catch e
		unless e.status is 404
			throw e
			e = null

	if result and result.rev > remoteObject.rev
		remoteObject.value = result.value
		remoteObject.id = result.id
		remoteObject.rev = result.rev
		remoteObject.state = 'synced'

	else if not result or remoteObject.rev > result.rev
		if not result
			remoteObject.rev = 0

		remoteObject.state = 'saving'
		result = await fetcher.post "#{remote.url}/#{remoteObject.store}/#{remoteObject.id}", body: toRaw remoteObject

		remoteObject.id = result.id
		remoteObject.rev = result.rev
		if result.state is 'raced'
			remoteObject.stale = remoteObject.value
			remoteObject.value = result.value
		remoteObject.state = 'synced'

	remoteObject

export persist = (state = {})->
	shell = reactive
		value: state.value
		id: state.id
		rev: state.rev or -1

		store: state.store or 'global'
		state: 'pending'
		owner: 'local'
	persist.sync shell
	watch (->shell.value), (->
		if shell.state is 'synced'
			shell.rev += 1
			persist.sync shell), deep: true
	shell

persist.connect = (database, version, stores = [])->
	persist.database = LocalDatabase.open database, version, stores

persist.sync = (persistent)->
	persistent.state = 'loading'
	result = await (await persist.database).getObject persistent.store, persistent.id

	if result and result.rev > persistent.rev
		persistent.value = result.value
		persistent.id = result.id
		persistent.rev = result.rev
		persistent.state = 'synced'

	else if not result or persistent.rev > result.rev
		persistent.state = 'saving'
		if not result and persistent.rev < 0
			persistent.rev = 0
		await (await persist.database).setObject persistent.store, persistent.id, toRaw persistent
		persistent.state = 'synced'

	persistent
