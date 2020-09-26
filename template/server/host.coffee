import {Api} from '../node_modules/ur/deno/api.js'

Api.router.prefix '/api/v1'
Api.serveDataObject 'global', './data/global'
Api.serveDataObject 'themes', './data/themes'
Api.serveDataObject 'cms', './data/cms'
Api.serve './public'

do ->
	console.log 'Listening on', 9010
	await Api.host 9010
