import {Api} from './api.js'

export runRollup = ()->
	if '--watch' in Deno.args
		Deno.run cmd: "bash rollup -w -c .config/rollup.config.mjs".split ' '
	Deno.permissions.revoke name: 'run'
	Deno.permissions.revoke name: 'env'

export serveBundles = ({path})->
	Api.staticStack.push (context, next) ->
		jsfile = if context.request.url.pathname is '/'
			'index.js'
		else
			[_, parts...] = context.request.url.pathname.split '/'
			parts.join('__slash__') + '.js'
		console.log 'serving jsfile', jsfile, "#{path}/#{jsfile}"
		if await Deno.stat("#{path}/#{jsfile}").then((x)->true).catch(->false)
			context.response.html = """<script src='/#{jsfile}' type='module'></script>"""
		else next()
