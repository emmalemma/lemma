import {Api} from './api.js'

export runRollup = ()->
	if '--watch' in Deno.args
		Deno.run cmd: "bash rollup -w -c .config/rollup.config.mjs".split ' '
	Deno.permissions.revoke name: 'run'
	Deno.permissions.revoke name: 'env'

export serveBundles = ({path})->
	Api.staticStack.push (context, next) ->
		jspath = if context.request.url.pathname is '/'
			'/index.js'
		else
			context.request.url.pathname + '.js'
		if await Deno.stat(path + jspath).then((x)->true).catch(->false)
			console.log 'serving module', path + jspath
			context.response.html = """<script src='#{jspath}' type='module'></script>"""
		else next()
