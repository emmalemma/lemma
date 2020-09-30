import {mount, registration, local, remote, persist, themes, cms} from 'ur'

import {App} from './app'
import {Music} from './music'

local.connect 'persistence', 1, ['global']
remote.connect '/api/v1'

# EMBEDDED
themes.enable ref: remote store: 'themes', id: 'global'
cms().enable ref: remote store: 'cms', id: 'global'

Root = registration (register, state)->
	register App, ->
		register Music
		state {}
do ->
	document.body.innerHTML = "Loading..."
	await persist.promise themes.ref
	await persist.promise cms().ref
	mount Root, 'body'
