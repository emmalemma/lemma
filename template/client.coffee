import '@lemmata/expose/client'

import {elements, state} from '@lemmata/client'
{div, button, scope} = elements

import {serverRandom} from './api'

app = state color: 0
document.body.appendChild scope ->
	div style: "background-color: hsl(#{app.color * 255}, 100%, 50%);", ->
		div.title 'Hello'
		button 'random color', onclick: -> app.color = await serverRandom()
