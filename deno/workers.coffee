harnesses = {}
requests = {}
import {reactive} from 'https://esm.sh/@vue/reactivity@3.0.4'

import {Api} from './api.js'

hostWorker = (target)->
	Api.router.post "/#{target}/:exportName", (context)->
		{request, response} = context
		rid = request.serverRequest.conn.rid

		# console.log context.params, harnesses
		harnesses[target].postMessage ['callExport', rid, context.params.exportName, await request.body().value, {identity: context.identity, headers: context.request.headers}]

		try
			result = await new Promise (resolve, reject)->
				requests[rid] = {resolve, reject, context}
		catch e
			response.status = 500
			result = e
		response.json = result

class SocketProxy
	constructor: (@setup)->
	connect: (socket)->
		handlers = {}
		do ->
			for await message from socket
				unless typeof message is 'string'
					console.error {error: message}
					continue
				data = JSON.parse message
				handlers[data.target]?.apply null, data.args
		@setup new Proxy {},
			get: (_, target)->
				(args...)->
					socket.send JSON.stringify {target, args}
			set: (target, prop, value)->
				handlers[prop] = value

export realtime = (setup)->
	new SocketProxy setup

sockets = {}
hostSocket = (target, exportName)->
	sockets["#{target}:#{exportName}"] ?= Api.router.get "/#{target}/#{exportName}" , (context)->
		if context.isUpgradable
			proxy = modules[target][exportName].apply(context, await context.request.body().value)
			proxy.connect await context.upgrade()

modules = {}
hostApi = (target)->
	Api.router.post "/#{target}/:exportName", (context)->
		{request, response} = context
		rid = request.serverRequest.conn.rid

		try
			if context.params.exportName.match /^_/
				throw new Error 'invalid export'

			result = await modules[target][context.params.exportName].apply(context, await request.body().value)
			if result instanceof SocketProxy
				hostSocket target, context.params.exportName
				response.json = socket: request.url.href.replace /https/, 'wss'
			else
				response.json = raw: result

		catch e
			response.status = 500
			console.error 'API error', target
			console.error e.stack
			response.json = error: stack: e.stack, message: e.message

Api.router.post "/workers/:target/continuation/:id", (context)->
	{request, response} = context
	rid = request.serverRequest.conn.rid

	harnesses[context.params.target].postMessage ['continuation', rid, context.params.id, await request.body().value, context.identity]

	try
		result = await new Promise (resolve, reject)->
			requests[rid] = {resolve, reject}
	catch e
		response.status = 500
		result = e
	response.json = result

Api.router.post "/workers/:target/reactive/:id", (context)->
	{request, response} = context
	rid = request.serverRequest.conn.rid

	# console.log context.params, harnesses
	harnesses[context.params.target].postMessage ['reactive', rid, context.params.id, await request.body().value, context.identity]

	try
		result = await new Promise (resolve, reject)->
			requests[rid] = {resolve, reject}
	catch e
		response.status = 500
		result = e
	response.json = result


onWorkerMessage = ({data: [event, callId, result]})->
	# console.log [event, callId, result]
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
		console.log 'loading worker', worker_file
		target = worker_file.match(/([^\/\\]+)\.[a-z]+$/)[1]
		hostWorker target
		harness = harnesses[target] = new Worker new URL('harness.js', `import.meta.url`).href, type: 'module', deno: true
		harness.postMessage ['loadWorker', "file:///#{Deno.cwd()}/#{worker_file}"]
		harness.onmessage = onWorkerMessage
		harness.onerror = onWorkerError


watchModule = (target, path, uri)->
	console.log watch: {target, path, uri}
	debounce = null
	for await event from Deno.watchFs path
		console.log {event}
		if event.kind is 'modify'
			debounce ?= setTimeout (->
				debounce = null
				previous = modules[target]
				try
					module = modules[target] = await import("#{uri}?#{Date.now()}")
					console.log 'new module loaded'
					module._upgrade? previous
				catch e
					console.error 'hot reload failed'
					console.error e
				), 100

export serveApis = ({path, matches})->
	worker_files = []
	for await entry from Deno.readDir(path)
		if entry.name.match matches
			worker_files.push "#{path}/#{entry.name}"

	for worker_file in worker_files
		target = worker_file.match(/([^\/\\]+)\.[a-z]+$/)[1]
		worker_path = "#{worker_file}"
		hostApi target
		uri = "file:///#{Deno.cwd()}/#{worker_path}"
		# console.log {target, worker_file, worker_path, uri}
		try
			module = modules[target] = await import("#{uri}?#{Date.now()}")
		catch e
			console.error 'api load failed'
			console.error e
			modules[target] = {error: e}
		watchModule target, "#{worker_path}", uri
