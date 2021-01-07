import {Api} from './api.js'
import {serveWorkers, serveApis} from './workers.js'
import {serveBundles, runRollup} from './bundler.js'
import {loadConfig} from './config.js'
import {log} from './log.js'
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

	log 'Listening on', Config.port
	await Api.host()

	log 'Listen server exited.'
	# log 'Closing rollup.'
	# rollup.close()
	log 'Closing Deno.'
	Deno.exit(1)
