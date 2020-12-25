import {Api} from './api.js'
import {serveWorkers, serveApis} from './workers.js'
import {serveBundles} from './bundler.js'
import {loadConfig} from './config.js'
import Config from './config.js'

serveWorkers path: './server', matches: /_worker\.js$/
serveApis path: './server', matches: /_api\.js$/
serveBundles path: './public'

Api.serve './public'

do ->
	await loadConfig "file:///#{Deno.cwd()}/.config/server.js"

	console.log 'Listening on', Config.port
	await Api.host()

	console.log 'Listen server exited.'
	Deno.exit(1)
