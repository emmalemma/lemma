import {DataStore} from './node_modules/ur/deno/datastore.js'
themeStore = new DataStore './data/themes'
theme = ''

dofer =(fn)->fn()
dofer ->
	try
		theme = (await themeStore.read 'global') or ''
	catch e
		console.error e

export getTheme =->
	console.log 'getting theme', theme
	theme

export saveTheme =(t)->
	console.log 'saving theme', t
	theme = t
	await themeStore.write 'global', theme
