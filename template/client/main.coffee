import {mount, registration, persist, remote, themes, cms} from 'ur'

import {App} from './app'

persist.connect 'persistence', 1, ['global']
remote.connect '/api/v1'

# EMBEDDED
themes.enable ref: remote store: 'themes', id: 'global'
cms.enable ref: remote store: 'cms', id: 'global'

Root = registration (register, state)->
	register App, ->
		state {}
do ->
	document.body.innerHTML = "Loading..."
	await remote.promise themes.ref
	await remote.promise cms.ref
	mount Root, 'body'

console.log 'mounted'
