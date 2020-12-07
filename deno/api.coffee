import {Oak} from './deps.js'

import {DataStore} from './datastore.js'

JsonResponse = (context, next)->
	await next()
	if 'json' of context.response
		if context.response.body
			console.error json: context.response.json
			throw new Error "Set JSON as well as raw body!"
		context.response.headers.set 'Content-Type', 'application/json'
		context.response.body = JSON.stringify context.response.json, null, 2

HtmlResponse = (context, next)->
	await next()
	if 'html' of context.response
		if context.response.body
			console.error html: context.response.html
			throw new Error "Set HTML as well as raw body!"
		context.response.headers.set 'Content-Type', 'text/html; charset=utf-8'
		context.response.body = context.response.html

RequestLogging = ({request, response}, next)->
		console.log request.method, request.url.href
		try
			await next()
		catch e
			console.error e.stack
			response.status = e.status or 500
		finally
			console.log request.method, request.url.href, response.status

export Api =
	app: new Oak.Application
	router: new Oak.Router
	staticStack: []
	serve: (path)->
		@staticStack.push (context) ->
			await Oak.send context, context.request.url.pathname,
				root: path
				index: "index.html"

	serveDataObject: (key, path)->
		dataStore = new DataStore path

		@router.get "/#{key}", (context)->
			objects = await dataStore.readAll()
			context.response.json = objects

		@router.get "/#{key}/:id", (context)->
			object = await dataStore.read context.params.id
			context.response.json = object

		@router.post "/#{key}/:id", (context)->
			object = await context.request.body().value
			object.state = 'saved'
			await dataStore.write context.params.id, object
			context.response.json = object

	host: (port)->
		@app.addEventListener 'error', (event)->
			console.error event.error
		@app.use RequestLogging
		@app.use JsonResponse
		@app.use HtmlResponse
		@app.use @router.routes()
		@app.use @router.allowedMethods()
		@app.use hook for hook in @staticStack
		await @app.listen {port}
