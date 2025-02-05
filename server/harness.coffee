module = {}

import {isReactive, toRaw} from 'https://esm.sh/@vue/reactivity@3.0.4'

loadModule = (filename)->
	try
		module = await import(filename)
		# console.log 'loaded module', module
	catch e
		console.error 'module load error', filename
		console.error e
		throw e

wrapValue = (result)->
	raw: result

idx = 0
continuations = {}
registerContinuation = (fn)->
	id = idx += 1
	continuations[id] = fn
	{continue: id}

reactiveIds = new WeakMap
reactives = {}
registerReactive = (rx)->
	id = reactiveIds.get(rx) or (
		id = idx += 1
		reactiveIds.set rx, id
		id
	)
	reactives[id] = rx
	{reactive: id, raw: toRaw rx}

processRpc = (callId, result)->
	result = switch typeof result
		when 'function'
			registerContinuation result
		when 'object'
			if isReactive result
				registerReactive result
			else
				wrapValue result
		else wrapValue result
	postMessage ['resolve', callId, result]

self.onmessage = ({data: [event, args...]})->
	try
		if event is 'loadModule'
			[callId, uri] = args
			try
				await loadModule uri
				postMessage ['resolve', callId]
			catch e
				postMessage ['reject', callId, e.message]

		else if event is 'callExport'
			[callId, exp, args, context] = args
			try
				if typeof module[exp] is 'function'
					unless Array.isArray args
						args = [args]
					context.requireAdmin =->
						throw new Error 'unauthorized' unless @identity.admin
					processRpc callId, await module[exp].apply context, args
				else
					# if typeof args is 'object'
					# 	module[exp][k] = v for k, v of args
					postMessage ['resolve', callId, toRaw module[exp]]
			catch e
				console.error e
				postMessage ['reject', callId, {message: e.message}]
		else if event is 'continuation'
			[callId, continuationId, args, context] = args
			processRpc callId, await continuations[continuationId].apply context, args
		else if event is 'reactive'
			[callId, rxId, raw] = args
			reactives[rxId][k] = v for k, v of raw
			postMessage ['resolve', callId, {done: true}]
	catch e
		console.error e
		throw e
