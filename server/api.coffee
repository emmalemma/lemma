import {Oak} from './deps.js'

import {DataStore} from './datastore.js'

import {AuthIdentity} from './auth.js'
import Config from './config.js'
import {log} from './log.js'

AllowedHostnames = (context, next)->
	unless context.request.url.hostname in Config.allowedHosts
		context.respond = false
		log 'Ignoring request to ', context.request.url.hostname
		context.request.serverRequest.conn.close()
	else
		await next()

JsonResponse = (context, next)->
	await next()
	if 'json' of context.response
		if context.response.body
			log.error json: context.response.json
			throw new Error "Set JSON as well as raw body!"
		context.response.headers.set 'Content-Type', 'application/json'
		context.response.body = JSON.stringify context.response.json, null, 2

HtmlResponse = (context, next)->
	await next()
	if 'html' of context.response
		if context.response.body
			log.error html: context.response.html
			throw new Error "Set HTML as well as raw body!"
		context.response.headers.set 'Content-Type', 'text/html; charset=utf-8'
		context.response.body = context.response.html

RequestLogging = ({request, response}, next)->
		log request.method, request.url.href
		try
			await next()
		catch e
			log.error "LOG", e.stack
			response.status = e.status or 500
		finally
			log request.method, request.url.href, response.status

NotFound =(context, next)->
	try
		await next()
	catch e
		log 'notfound error', e
		if context.response.status is 404
			context.response.headers.set 'Content-Type', 'text/html; charset=utf-8'
			context.response.body = "<script src='/not_found.js' type='module'></script>"

abortController = null
export Abort =-> abortController.abort()

export Api =
	app: new Oak.Application
	router: new Oak.Router
	staticStack: []
	serve: (path)->
		@staticStack.push (context) ->
			await Oak.send context, context.request.url.pathname,
				root: path

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
			log.error event.error
		if Config.allowedHosts
			@app.use AllowedHostnames
		@app.use RequestLogging
		@app.use NotFound
		@app.use JsonResponse
		@app.use HtmlResponse
		@app.use AuthIdentity
		@app.use @router.routes()
		@app.use @router.allowedMethods()
		@app.use hook for hook in @staticStack

		abortController = new AbortController

		@app.addEventListener 'error', (event)->
			log.error "#{new Date()} Oak uncaught #{event.error.name}"
			log.error event.error.stack
			abortController.abort()

		certs =
			if Config.tls
				certFile: Config.tls.certPath
				keyFile: Config.tls.keyPath
				secure: true
			else secure: false


		options = Object.assign
			signal: abortController.signal
			port: Config.port or 9010
			secure: true
			certs
		await @app.listen options
