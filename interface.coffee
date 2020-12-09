import {reactive, toRaw} from '@vue/reactivity'
import {watch} from './util'
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

rpcResult =	(worker, result)->
	if result.continue
		return continuation worker, result.continue
	else if result.reactive
		return getReactive worker, {id: result.reactive, raw: result.raw}
	else result.raw

export workerInterface =
	rpc: (worker, endpoint)-> (args...)->
		console.log 'calling RPC with', worker, endpoint, args
		rpcResult worker, await fetcher.post "/workers/#{worker}/endpoints/#{endpoint}", body: args

	reactive: (worker, target)->
		shell = reactive {}
		watch (->shell), ->
			console.log 'updating remote reactive with', worker, target, shell
		console.log 'loading remote reactive with', worker, target
