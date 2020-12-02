import {elements, state, toRaw} from 'ur'

import music from './music.json'
# cms().load state {}

# import {elements, persistent, state} from 'ur-'
import {persistence} from 'ur'
persistent = persistence indexeddb:
	db: 'testdb'
	version: 1
	store: 'persistence'

{div, span, button, input} = elements
do ->
	todos = persistent.todos state []
	document.body.appendChild div.todoApp ->
		input onkeypress: ({target, keyCode})-> (todos.push {task: target.value}; target.value = '') if keyCode is 13
		button 'clear completed' or cms.todoApp.actions.clearCompleted(), onclick: -> todos.splice todos.indexOf(todo), 1 for todo in (todo for todo in todos when todo.done)
		for todo in todos
			div.$for(todo)["todo-#{todo.task}"] (todo)->
				div.inner ->
					input type: 'checkbox', checked: todo.done, onclick: -> todo.done = not todo.done
					span.task todo.task

todoActions = (todos)->
	input onkeypress: ({target, keyCode})-> (todos.push {task: target.value}; target.value = '') if keyCode is 13
	button 'Clear completed', onclick: -> todos.splice todos.indexOf(todo), 1 for todo in (todo for todo in todos when todo.done)

todoItem = (todos)-> (todo)->

do ->
	todos = persistent.editableTodos state []
	document.body.appendChild div.todoAppEditable ->
		todoActions todos
		div.todos ->
			for todo in todos
				div.todo.$for(todo)  (todo) ->
					editable = state task: no
					div ->
						if editable.task
							button 'x', onclick: -> todos.splice todos.indexOf(todo), 1
							input.task value: todo.task, oninput: ({target: {value}})-> todo.task = value
							button 'done', onclick: -> editable.task = no
						else
							input.done type: 'checkbox', checked: todo.done, onclick: -> todo.done = not todo.done
							span.task todo.task
							button 'edit', onclick: -> editable.task = yes


coords = [
	[3, 0]
	[2, 0]
	[3, 1]
	[2, 1]
	[3, 2]
	[4, 3]
	[3, 3]
	[4, 4]
	[3, 4]
	[4, 5]
	[3, 5]
	[4, 6]
	[5, 7]
]

import midiParser from 'midi-parser-js'
lanes = state music
transpose = state steps: 0

document.body.appendChild div.music ->
	div.transpose ->
		button.down '-', onclick: -> transpose.steps -= 1
		span.steps transpose.steps.toString()
		button.down '+', onclick: -> transpose.steps += 1
	div.import ->
		input type: 'file', onchange: ({target: files: [file]})->
			parsed = midiParser.parse new Uint8Array await file.arrayBuffer()
			notes = []
			activeNotes = {}
			time = 0
			NOTE_ON = 9
			NOTE_OFF = 8
			for track in parsed.track
				for event in track.event
					time += event.deltaTime
					if event.type in [NOTE_ON, NOTE_OFF]
						[n, v] = event.data
						if event.type is NOTE_ON
							notes.push activeNotes[n] = {t: time, n}
						else if event.type is NOTE_OFF
							continue unless n of activeNotes
							activeNotes[n].d = time - activeNotes[n].t
							delete activeNotes[n]
			laneIdx = 0
			time = 0
			lanes.push (false for x in [0..48])
			lane = lanes[lanes.length - 1]
			for note in notes
				if note.t > time
					time = note.t
					lanes.push (false for x in [0..48])
					lane = lanes[lanes.length - 1]
				lane[note.n - 40] = true
			console.log JSON.stringify toRaw lanes
	div.staff style: 'position: relative; top: 20px;', ->
		for lane, lidx in lanes
			div.lane.$for(lane, lidx) style: "position: absolute; top: #{(lidx+1) * 100}px; transform: rotate(15deg); text-shadow: 0 0 20px black;", (lane, lidx)->
				for note, idx in lane then do (idx)->
					idx += transpose.steps
					coord = coords[idx % 12]
					octave = Math.floor idx / 12
					[q, r] = coord
					q += octave * 2
					r += octave * 7
					width = 25
					y = -1 * (Math.sqrt(3) * q  +  Math.sqrt(3)/2 * -r) * width
					x = 800 + -1 * 3/2 * r * width
					div.hexagon.$for(idx) '⬢', style: "display: inline-block; position: absolute; top: #{y}px; left: #{x}px; font-size: #{width * 2.3}px; color: #{if note then 'black' else 'white'}; line-height: #{width}px; width: #{width}px; vertical-align: middle; transform: rotate(30deg);", onclick: -> lanes[lidx][idx] = not lanes[lidx][idx]
#
# const {div, button} = elements;
# const todos = persistent(state([]));
# document.body.appendChild(div.todoApp(_=>{
# 	input({onkeypress: ({target: {value}}) => todos.push {task: value}});
# 	button('clear completed', onclick: _=> todos.filter(t=>t.done).forEach((todo)=>todos.splice(todos.indexOf(todo), 1)));
# 	for (idx in todos) {
# 		const todo = todos[idx];
# 		div.$for(todo)(todo => {
# 			input({type: 'checkbox', checked: todo.task, onclick: ({})=>todo.checked = !todo.checked});
# 			div.task(todo.task)
# 		})
# 	}
# }));
{textarea} = elements
posts = state []
document.body.appendChild div.blog ->
	div.header ->
		div.brand 'My New Blog'
		div.logo innerHTML: """<svg id="Capa_1" enable-background="new 0 0 512 512" height="100%" viewBox="0 0 512 512" width="100px" xmlns="http://www.w3.org/2000/svg"><g><path d="m336 431h-160c-5.523 0-10-4.477-10-10v-154.795l-16.907 23.67c-11.263 15.767-29.447 25.125-48.824 25.125h-65.269c-19.33 0-35-15.67-35-35 0-19.33 15.67-35 35-35h45.908l50.049-68.817c18.754-25.787 48.987-41.183 80.873-41.183h88.34c31.886 0 62.119 15.396 80.874 41.183l50.048 68.817h45.908c19.33 0 35 15.67 35 35 0 19.33-15.67 35-35 35h-65.269c-19.377 0-37.561-9.358-48.824-25.126l-16.907-23.669v154.795c0 5.523-4.477 10-10 10z" fill="#ffcdbe"/><path d="m477 245h-45.908l-50.049-68.817c-18.754-25.787-48.987-41.183-80.873-41.183h-44.17v296h80c5.523 0 10-4.477 10-10v-154.795l16.907 23.669c11.263 15.768 29.447 25.126 48.824 25.126h65.269c19.33 0 35-15.67 35-35 0-19.33-15.67-35-35-35z" fill="#ffbeaa"/><path d="m151 468.922c0-19.803 13.417-36.988 32.629-41.791l172.054-43.013c18.892-4.723 38.345-7.118 57.817-7.118 37.22 0 67.5 30.28 67.5 67.5s-30.28 67.5-67.5 67.5h-219.422c-23.753 0-43.078-19.325-43.078-43.078z" fill="#989dec"/><path d="m317.922 512h-219.422c-37.22 0-67.5-30.28-67.5-67.5s30.28-67.5 67.5-67.5c19.472 0 38.925 2.395 57.817 7.118l172.054 43.013c19.212 4.803 32.629 21.988 32.629 41.791 0 23.753-19.325 43.078-43.078 43.078z" fill="#bceaf9"/><path d="m328.371 427.131-72.371-18.092v102.961h61.922c23.753 0 43.078-19.325 43.078-43.078 0-19.803-13.417-36.988-32.629-41.791z" fill="#acceff"/><path d="m256 160c-44.112 0-80-35.888-80-80s35.888-80 80-80 80 35.888 80 80-35.888 80-80 80z" fill="#ffdecf"/><path d="m336 80c0-44.112-35.888-80-80-80v160c44.112 0 80-35.888 80-80z" fill="#ffcdbe"/></g></svg>"""
	div.body ->
		div.subhead "Posts on my blog"
		div.posts ->
			for post in posts
				div.post.$for(post) (post)->
					div.title post.title
					div.body post.body
		div.newPost ->
			inputs =
				title: input.title placeholder: 'post title'
				body: textarea.body placeholder: 'post body'

			button.makePost 'Post', onclick: ->
				posts.push title: inputs.title.value, body: inputs.body.value
				field.value = '' for _, field of inputs
#
# {div, button} = elements
# todos = persistent state []
# document.body.appendChild div.todoApp ->
# 	input onkeypress: ({target: {value}})-> todos.push {task: value}
# 	button 'Clear completed', onclick: -> todos.splice(idx, 1) for todo, idx in todos when todo.done
# 	for todo in todos
# 		div.todo.$for(todo) (todo)->
# 			editable = persistent state task: no
# 			if editable.task
# 				button 'x', onclick: -> todos.splice todos.indexOf todo
# 				input value: todo.task, oninput: ({target: {value}})-> todo.task = value
# 				button 'done', onclick: -> editable.task = no
# 			else
# 				input type: 'checkbox', selected: todo.done, onclick: -> todo.done = not todo.done
# 				div.task todo.task
# 				button 'edit', onclick: -> editable.task = yes
#
# makeTag todoApp
