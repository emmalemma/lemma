harnesses = {}
requests = {}

import {reactive} from 'https://esm.sh/@vue/reactivity@3.0.4'
import {Api} from './api.js'
import {log} from './log.js'
import {
  isWebSocketCloseEvent,
  isWebSocketPingEvent,
} from "https://deno.land/std@0.82.0/ws/mod.ts";

delay = (ms)->new Promise (res)-> setTimeout res, ms

hostWorker = (target)->
	Api.router.post "/#{target}/:exportName", (context)->
		{request, response} = context
		rid = request.serverRequest.conn.rid

		# log context.params, harnesses
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
			try
				for await message from socket
					if typeof message is 'string'
						data = JSON.parse message
						handlers[data.target]?.apply null, data.args
					else if isWebSocketCloseEvent(message)
						handlers.onclose?()
					else
						log.error {error: message}
			catch e
				log.error 'Socket recv error'
				log.error e
				handlers.onclose?()
		@setup new Proxy {},
			get: (_, target)->
				(args...)->
					# log {sending: {target, args}, socket}
					try
						socket.send JSON.stringify {target, args}
					catch e
						log.error 'socket send error'
						log.error e
						handlers.onclose?()
			set: (target, prop, value)->
				handlers[prop] = value

export realtime = (setup)->
	new SocketProxy setup

sockets = {}
hostSocket = (target, exportName)->
	targetUri = target.replace /__slash__/g, '/'
	sockets["#{target}:#{exportName}"] ?= Api.router.get "/#{targetUri}/#{exportName}" , (context)->
		if context.isUpgradable
			proxy = await modules[target][exportName].apply(context, await context.request.body().value)
			proxy.connect await context.upgrade()

modules = {}
hostApi = (target)->
	targetUri = target.replace /__slash__/g, '/'
	Api.router.post "/#{targetUri}/:exportName", (context)->
		{request, response} = context
		rid = request.serverRequest.conn.rid

		try
			if context.params.exportName.match /^_/
				throw new Error 'invalid export'
			unless fn = modules[target][context.params.exportName]
				throw new Error "no definition for #{target}.#{context.params.exportName}"
			result = await fn.apply(context, await request.body().value)
			if result instanceof SocketProxy
				hostSocket target, context.params.exportName

				response.json = socket: request.url.href.replace(/^https?/, 'wss')
			else
				response.json = raw: result

		catch e
			response.status = 500
			log.error 'API error', target
			log.error e.stack
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

	# log context.params, harnesses
	harnesses[context.params.target].postMessage ['reactive', rid, context.params.id, await request.body().value, context.identity]

	try
		result = await new Promise (resolve, reject)->
			requests[rid] = {resolve, reject}
	catch e
		response.status = 500
		result = e
	response.json = result

onWorkerMessage = ({data: [event, callId, result]})->
	# log [event, callId, result]
	switch event
		when 'resolve'
			requests[callId].resolve result
		when 'reject'
			requests[callId].reject result

	delete requests[callId]

onWorkerError = (error)->
	log.error 'worker error'
	log.error error
	error.preventDefault()

loadWorker = (target, uri)->
	previous = harnesses[target]
	harness = harnesses[target] = new Worker new URL('harness.js', `import.meta.url`).href, type: 'module', deno: true
	callId = "worker-#{target}"
	harness.postMessage ['loadModule', callId, uri]
	harness.onmessage = onWorkerMessage
	harness.onerror = onWorkerError

	loaded = new Promise (resolve, reject)->
		requests[callId] = {resolve, reject}

	if previous
		previous.postMessage ['teardown', callId]
		state = await new Promise (resolve, reject)->
			requests[callId] = {resolve, reject}

		await loaded
		harness.postMessage ['upgrade', state]
	else loaded

loadModule = (target, uri)->
	previous = modules[target]
	try
		module = await import(path = "#{uri}?#{Date.now()}")
		modules[target] = module
		module._upgrade? previous if previous
	catch e
		log.error 'hot reload failed on', target
		log.error e

watchTarget = (target, path, reload)->
	uri = "file:///#{Deno.cwd()}/#{path}"
	reload target, uri
	debounce = null

	for await event from Deno.watchFs path
		if event.kind is 'modify'
			debounce ?= do ->
				await delay 100
				await reload target, uri
				await delay 100
				debounce = null

export serveWorkers = ({path, matches})->
	worker_files = []
	try
		for await entry from Deno.readDir(path)
			if entry.name.match matches
				worker_files.push "#{path}/#{entry.name}"
	catch e
		log.error "Can't read apis: #{path}"

	for worker_file in worker_files
		log 'loading worker', worker_file
		target = worker_file.match(/([^\/\\]+)\.[a-z]+$/)[1]
		hostWorker target
		watchTarget target, worker_file, loadWorker

export serveApis = ({path, matches})->
	worker_files = []
	try
		for await entry from Deno.readDir(path)
			if entry.name.match /\.js$/
				worker_files.push "#{path}/#{entry.name}"
	catch e
		log.error "Can't read apis: #{path}"

	for worker_file in worker_files
		target = worker_file.match(/([^\/\\]+)\.[a-z]+$/)[1]
		hostApi target
		watchTarget target, worker_file, loadModule
