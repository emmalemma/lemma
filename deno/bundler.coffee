import {Api} from './api.js'

export serveBundles = ({path})->
	Api.staticStack.push (context, next) ->
		console.log 'static stack testing', context.request.url.pathname
		jspath = if context.request.url.pathname is '/'
			'/index.js'
		else
			context.request.url.pathname + '.js'
		console.log 'checking', path + jspath
		if await Deno.stat(path + jspath).then((x)->true).catch(->false)
			context.response.html = "<script src='#{jspath}' type='module'></script>"
		else next()
