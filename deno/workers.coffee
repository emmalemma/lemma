harnesses = {}
requests = {}
import {reactive} from 'https://esm.sh/@vue/reactivity@3.0.4'


import {Api} from './api.js'
Api.router.post "/workers/:target/endpoints/:endpoint", (context)->
	{request, response} = context
	rid = request.serverRequest.conn.rid

	console.log context.params, harnesses
	harnesses[context.params.target].postMessage ['callExport', rid, context.params.endpoint, await request.body().value, request]

	try
		result = await new Promise (resolve, reject)->
			requests[rid] = {resolve, reject}
	catch e
		response.status = 500
		result = e
	response.json = result

onWorkerMessage = ({data: [event, callId, result]})->
	console.log [event, callId, result]
	
	if event is 'resolve'
		requests[callId].resolve result
	else if event is 'reject'
		requests[callId].reject result
	delete requests[callId]

onWorkerError = (error)->
	console.error 'worker error'
	console.error error
	error.preventDefault()

export serveWorkers = ({path, matches})->
	worker_files = []
	for await entry from Deno.readDir(path)
		if entry.name.match matches
			worker_files.push "#{path}/#{entry.name}"

	for worker_file in worker_files
		target = worker_file.match(/([^\/\\]+)\.[a-z]+$/)[1]
		harness = harnesses[target] = new Worker new URL('harness.js', `import.meta.url`).href, type: 'module', deno: true
		harness.postMessage ['loadWorker', "file:///#{Deno.cwd()}/#{worker_file}"]
		harness.onmessage = onWorkerMessage
		harness.onerror = onWorkerError
