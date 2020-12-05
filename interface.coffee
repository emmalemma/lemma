import {reactive} from '@vue/reactivity'
import {watch} from './util'
import {fetcher} from './remoting'


export workerInterface =
	rpc: (worker, endpoint)-> ->
		console.log 'calling RPC with', worker, endpoint, arguments
		result = await fetcher.post "/workers/#{worker}/endpoints/#{endpoint}", body: (x for x in arguments)
		console.log 'rpc returned', [result]
		result

	reactive: (worker, target)->
		shell = reactive {}
		watch (->shell), ->
			console.log 'updating remote reactive with', worker, target, shell
		console.log 'loading remote reactive with', worker, target
