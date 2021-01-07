import {Api} from './api.js'
import {serveWorkers, serveApis} from './workers.js'
import {serveBundles, runRollup} from './bundler.js'
import {loadConfig} from './config.js'
import Config from './config.js'

serveWorkers path: './server', matches: /_worker\.js$/
serveApis path: './server', matches: /_api\.js$/
serveBundles path: './public'
rollup = runRollup()

Api.serve './public'

do ->
	for arg in Deno.args
		if m = arg.match /--config=(.+)/
			await loadConfig "file:///#{Deno.cwd()}/#{m[1]}"

	console.log 'Listening on', Config.port
	await Api.host()

	console.log 'Listen server exited.'
	# console.log 'Closing rollup.'
	# rollup.close()
	console.log 'Closing Deno.'
	Deno.exit(1)
