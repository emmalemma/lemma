import {Api} from './api.js'
import {serveWorkers} from './workers.js'
import {serveBundles} from './bundler.js'
import {loadConfig} from './config.js'
import Config from './config.js'

serveWorkers path: '.', matches: /_worker\.js$/
serveBundles path: './public'

Api.serve './public'

do ->
	await loadConfig "file:///#{Deno.cwd()}/.config/server.js"

	console.log 'Listening on', Config.port
	Api.host()
