module = {}

loadWorker = (filename)->
	try
		module = await import(filename)
	catch e
		console.error 'module load error', filename
		console.error e
		throw e

self.onmessage = ({data: [event, args...]})->
	try
		if event is 'loadWorker'
			loadWorker args[0]
		else if event is 'callExport'
			[callId, exp, args] = args
			try
				console.log 'calling', module, exp, args
				result = await module[exp].apply module[exp], args
				postMessage ['resolve', callId, result]
			catch e
				postMessage ['reject', callId, e]
	catch e
		console.error e
		throw e
