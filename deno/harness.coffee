module = {}

loadWorker = (filename)->
	module = await import(filename)

self.onmessage = ({data: [event, args...]})->
	try
		if event is 'loadWorker'
			loadWorker args[0]
		else if event is 'callExport'
			[callId, exp, args] = args
			try
				result = await module[exp].apply module[exp], args
				postMessage ['resolve', callId, result]
			catch e
				postMessage ['reject', callId, e]
	catch e
		console.error e
		throw e
