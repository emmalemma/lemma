import {Api} from './api.js'
import {serveWorkers} from './workers.js'
import {serveBundles} from './bundler.js'

serveWorkers path: '.', matches: /_worker\.js$/
serveBundles path: './public'

Api.serve './public'

do ->
	console.log 'Listening on', 9010
	await Api.host 9010
