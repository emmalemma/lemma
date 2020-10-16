import {reactive} from '@vue/reactivity'
import {NamedError} from './errors'

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
			shell.promise = doAsync -> try
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


class FetcherError extends NamedError
	constructor: (message, {status})->
		super message
		@status = status

export fetcher =
	get: (url)->
		@handledFetch url
	post: (url, {body})->
		@handledFetch url, method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify body

	handledFetch: (url, options)->
		res = await fetch url, options
		unless res.status is 200
			throw new FetcherError "#{url}: Status #{res.status}", status: res.status
		unless res.headers.get('content-type') is 'application/json'
			throw new FetcherError "#{url}: Content-Type=#{res.headers.get('content-type')}"
		await res.json()
