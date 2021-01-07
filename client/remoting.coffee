import {reactive} from '@vue/reactivity'
import {NamedError} from './errors'

export doAsync =(fn)->fn()

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
			e = new FetcherError "#{url}: Status #{res.status}", status: res.status
			e.body = await res.json()
			throw e
		unless res.headers.get('content-type').match /^application\/json/
			throw new FetcherError "#{url}: Content-Type=#{res.headers.get('content-type')}"
		await res.json()
