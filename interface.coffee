import {reactive, toRaw} from '@vue/reactivity'
import {watch, timeout} from './util'
import {fetcher} from './remoting'

continuation = rpcResult = getReactive = null

reactives = {}
getReactive = (worker, {id, raw})->
	rx = reactives[id] ?= reactive raw
	watch (->rx), ->
		await fetcher.post "/workers/#{worker}/reactive/#{id}", body: toRaw rx
	rx

continuation = (worker, id)->(args...)->
	rpcResult worker, await fetcher.post "/workers/#{worker}/continuation/#{id}", body: args

socketProxy = (href)->
	socket = new WebSocket href
	handlers = {}
	socket.onmessage = ({data})->
		data = JSON.parse data
		handlers[data.target]?.apply null, data.args
	socket.onopen = (data)->
		handlers.onopen? data
	new Proxy {},
		get: (_, target)->
			return undefined if target is 'then'
			(args...)->
				socket.send JSON.stringify {target, args}
		set: (target, prop, value)->
			handlers[prop] = value

rpcResult =	(worker, result)->
	if result.continue
		return continuation worker, result.continue
	else if result.reactive
		return getReactive worker, {id: result.reactive, raw: result.raw}
	else if result.socket
		return socketProxy result.socket
	else result.raw

export workerInterface =
	rpc: (worker, exportName)-> (args...)->
		try
			rpcResult worker, await fetcher.post "/#{worker}/#{exportName}", body: args
		catch e
			if rpcError = e.body?.error?.message
				throw new Error rpcError
			else throw e
