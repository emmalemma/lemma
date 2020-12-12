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
			context.response.html = """<script src='#{jspath}' type='module'></script>"""
		else next()


export watchBundle = ->
	console.log 'Running rollup watcher...'
	# process = await Deno.run cmd: "rollup.cmd -w -c .config/rollup.config.mjs".split(' ')
	console.log 'Revoking run permission.'
	await Deno.permissions.revoke name: 'run'
	window.addEventListener 'unload', =>
		console.log 'EVENT unload event'
		# await process.close()
