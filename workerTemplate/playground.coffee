import {elements, state, persistence} from 'ur'
import {compile} from 'coffeescript'

{div, textarea} = elements
code = state js: 'console.log("initial code")'

persistent = persistence indexeddb:
	db: 'lemma-playground'
	version: 1
	store: 'persistence'

error = state {}



document.body.appendChild div.playground ->
	textarea.code value: code.js, oninput: ({target: {value}})-> code.js = value
	div.rendered ->
		error.message = ''
		error.stack = ''
		# @removeChild @firstElementChild while @firstElementChild
		try
			(new Function 'elements', 'state', 'persistent', compile code.js) elements, state, persistent
		catch e
			# error.message = e.message
			# error.stack = e.stack

	div.error ->
		div.message error.message
		div.stack error.stack
