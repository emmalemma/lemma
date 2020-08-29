import {reactive} from 'vue'

export doAsync =(fn)->fn()

export pRef =(promise)->
	shell = reactive
		status: 'pending'
		value: undefined
		error: undefined
		handle: (promise)->
			promise.then (value)->
				shell.state = 'success'
				shell.value = value
			.catch (error)->
				shell.state = 'error'
				shell.error = error
			shell
	shell.handle promise

export fetchRef =(fetchArgs...)->
	shell = reactive
		state: 'requested'
		value: undefined
		error: undefined
		fetch: (fetchArgs...)->
			doAsync -> try
					res = await fetch fetchArgs...
					if res.status < 200 or res.status > 299
						throw new Error "Failure response: #{await res.json()}"
					shell.value = await res.json()
					shell.state = 'success'
				catch error
					shell.error = error
					shell.state = 'error'
			shell
	shell.fetch fetchArgs...
