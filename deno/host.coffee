import {Api} from './api.js'
import {serveWorkers} from './workers.js'

Api.serve './public'

serveWorkers path: '.', matches: /_worker\.js$/

do ->
	console.log 'Listening on', 9010
	await Api.host 9010
