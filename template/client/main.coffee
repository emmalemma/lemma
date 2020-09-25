import {mount, registration, persist, remote} from 'ur'

import {App} from './app'

persist.connect 'persistence', 1, ['global']
remote.connect '/api/v1'

Root = registration (register, state)->
	register App, ->
		state {}

mount Root, '.root'

console.log 'mounted'
