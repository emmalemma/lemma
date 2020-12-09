### @__PUBLISH__ ###

import {Extend} from 'lemma'
do Extend

import {elements, state, toRaw, enableTouch} from 'lemma'
enableTouch document

# cms().load state {}
music = []
# import {elements, persistent, state} from 'ur-'
import {persistence} from 'lemma'
import {delay} from 'lemma'
persistent = persistence indexeddb:
	db: 'testdb'
	version: 1
	store: 'persistence'


{div, span, button, input} = elements

import {grid, gridArea, size} from './theme'

dofer =(fn)->fn()

import {watch} from 'lemma'
import {getTheme, saveTheme} from './theme_worker'

StyleEditor =->
	styles = persistent.styles state {styleText: ""}

	dofer ->
		result = await getTheme()
		styles.styleText = result if result
		watch (->styles.styleText), ->
			await saveTheme styles.styleText

	watchHandle = null
	stopWatch =->
		clearInterval watchHandle if watchHandle

	watchStyles = (sheet)->
		doWatch =->
			console.debug styles.liveStyleText = document.styleSheets.asArray.flatMap((sheet)->sheet.cssRules.asArray.map (rule)->rule.cssText).sorted().join '\n'
		watchHandle = setInterval doWatch, 1001 # 251

	dofer ->
		await persistence.record(styles).loadedᴾ
		document.head.appendChild styleElement = elements.style ->
			if @sheet
				stopWatch @sheet
				(sheet.deleteRule(0) while sheet.cssRules.length) for sheet in document.styleSheets
			console.log 'setting styled text', @textContent = styles.styleText
			await delay 0
			watchStyles @sheet

	styleSettings = state edit: false
	div.styleEditor ->
		div.monitor ->
			span 'Watching CSS changes.'
		if styleSettings.edit
			elements.textarea value: styles.editableStyleText, oninput: ({target: {value}})->
				styles.editableStyleText = value
			if styles.editableStyleText isnt styles.styleText
				div.editableActions ->
					div.hint 'CSS edits detected.'
					button.commit 'Commit', onclick: -> styles.styleText = styles.editableStyleText
					button.revert 'Revert', onclick: -> styles.editableStyleText = styles.styleText
			else
				button.done 'Done', onclick: -> styleSettings.edit = false
		else
			button.edit 'Edit', onclick: -> styleSettings.edit = true

		if styles.liveStyleText isnt styles.styleText
			div.liveActions ->
				div.hint 'Live edits detected.'
				div.css.pre styles.liveStyleText
				button.commit 'Commit', onclick: -> styles.editabelStyleText = styles.styleText = styles.liveStyleText
				button.revert 'Revert', onclick: -> styles.liveStyleText = styles.styleText; styles.styleText = ''; styles.styleText = styles.liveStyleText

Todos =->
	todos = persistent.todos state []
	div.todoApp ->
		input onkeypress: ({target, keyCode})-> (todos.push {task: target.value}; target.value = '') if keyCode is 13
		button 'clear completed' or cms.todoApp.actions.clearCompleted(), onclick: -> todos.splice todos.indexOf(todo), 1 for todo in (todo for todo in todos when todo.done)
		for todo in todos
			div.$for(todo)["todo-#{todo.task}"] (todo)->
				div.inner ->
					input type: 'checkbox', checked: todo.done, onclick: -> todo.done = not todo.done
					span.task todo.task


import {random, err} from './random_worker'

RandGetter =->
	rand = state {value: -1}
	div.randGetter ->
		div.value rand.value.toString()
		button.getRand 'get rand', onclick: ->
			rand.value = await random()
		button.getRand 'get double rand', onclick: ->
			random()
			random()
			rand.value = await random()
		button.err 'err', onclick: ->
			try
				await err()
			catch e
				console.error 'err', e


Calculator =-> div.calculator grid("repeat(3, min-content) / auto"), ->
	operation = state number: '', op: null, store: 0
	execute =->
		return unless operation.op
		opand = parseInt operation.number, 10
		operation.number = (operation.op operation.store, opand).toString()
		operation.op = null

	doOp = (op)->->
		execute() if operation.op
		operation.store = parseInt(operation.number, 10)
		operation.number = ''
		operation.op = op

	div.display ->
		input value: operation.number
	div.numbers grid("repeat(4, min-content) / repeat(3, min-content)"), ->
		for n in [0..9] then div.number.$for(n) (if n is 0 then gridArea('4 / 2') else {}), (n)->
			button.digit n.toString(), onclick: ->
				operation.number += n.toString()
	div.ops ->
		button.plus '+', onclick: doOp (x,y)->x + y
		button.times '*', onclick: doOp (x,y)->x * y
		button.div '/', onclick: doOp (x,y)->x / y
		button.eq '=', onclick: ->execute()
# parallel state contexts
#
# context todos =->
# 	state = {todos}
# 	context todoActions =->
#
# 	consumer ConsumedTodoActions # ? = consume todoActions, todoActionComponent
#
#
# consume todos, ({todos}, {todoActions})->
# 	div.todos ->
# 		consume todoActions, ({todos})->
# 			div.todoActions ->
#
# 		for todo in todos
# 			consume todoTask, for:todo, ({todos}, todo)->
# 				div.todo.$for(todo) ->
#
#
# import {fish} from '../server/api'
#
# import {auth, doLogin} from '../server/auth'
#
# account = doLogin𝑓 username, password
#
# await fish𝑓() # rpc, embedded auth...
#
# todoActionComponent = ({todos})->
# 	div.todoActions ->
#
# consume todos, ({todos}, {todoActions})->
# 	div.todos ->
# 		consume todoActions, todoActionComponent
#
# consume todos ({todos}, {ConsumedTodoActions})->
# 	div.todos ->
# 		ConsumedTodoActions()
#
# define todos = ->
# 	define todoActions = ->
#
import {todos as remoteTodos, clearCompleted} from './main_worker'

clearCompleted()

EditableTodos =->
	todoActions = (todos)->
		input onkeypress: ({target, keyCode})-> (todos.push {task: target.value}; target.value = '') if keyCode is 13
		button 'Clear completed', onclick: -> todos.splice todos.indexOf(todo), 1 for todo in (todo for todo in todos when todo.done)

	todos = persistent.editableTodos state []
	div.todoAppEditable ->
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


import midiParser from 'midi-parser-js'
Music =->
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

	lanes = state music
	transpose = state steps: 0

	div.music ->
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

# ES6 version:
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
TicTac =->
	rules = state
		turn: 'x'
		board: {}
		turns: 0
		max_turns: 9

	win = (n)->
		rules.turn = null
		rules.winner = rules.board[n]
	test =(board)->
		for i in [0..2]
			if board[i] and (board[i] is board[i+3] and board[i] is board[i+6])
				return win i
		for i in [0,3,6]
			if board[i] and (board[i] is board[i+1] and board[i] is board[i+2])
				return win i
		for x in [-1, +1]
			i = 4
			if board[i] and (board[i] is board[i - 3 + x] and board[i] is board[i + 3 - x])
				return win i

		if rules.turns is rules.max_turns
			rules.winner = 'no one'
			rules.turn = null

	play =(n)->
		return if rules.board[n]
		rules.board[n] = rules.turn
		rules.turn = if rules.turn is 'x' then 'o' else 'x'
		rules.turns += 1
		test rules.board

	div.ticTac ->
		div.actions ->
			if rules.turn
				div.turn "#{rules.turn}'s turn"
			else if rules.winner
				div.win "#{rules.winner} won!"
				button.reset 'Replay', onclick: ->
					rules.board = {}
					rules.winner = null
					rules.turn = 'x'
					rules.turns = 0
		div.squares grid("repeat(3, min-content) / repeat(3, min-content)"), ->
			for n in [0..8] then div.square.$for(n) (n)->
				button size('1em', '1em'), "#{if rules.board[n] then rules.board[n] else ' '}", onclick: -> play n

Blog =->
	{textarea} = elements
	posts = persistent.blogPosts state []
	div.blog ->
		div.header ->
			div.brand 'My New Blog'
			div.logo size('2em', '2em'), innerHTML: """<svg id="Capa_1" enable-background="new 0 0 512 512" height="100%" viewBox="0 0 512 512" width="100px" xmlns="http://www.w3.org/2000/svg"><g><path d="m336 431h-160c-5.523 0-10-4.477-10-10v-154.795l-16.907 23.67c-11.263 15.767-29.447 25.125-48.824 25.125h-65.269c-19.33 0-35-15.67-35-35 0-19.33 15.67-35 35-35h45.908l50.049-68.817c18.754-25.787 48.987-41.183 80.873-41.183h88.34c31.886 0 62.119 15.396 80.874 41.183l50.048 68.817h45.908c19.33 0 35 15.67 35 35 0 19.33-15.67 35-35 35h-65.269c-19.377 0-37.561-9.358-48.824-25.126l-16.907-23.669v154.795c0 5.523-4.477 10-10 10z" fill="#ffcdbe"/><path d="m477 245h-45.908l-50.049-68.817c-18.754-25.787-48.987-41.183-80.873-41.183h-44.17v296h80c5.523 0 10-4.477 10-10v-154.795l16.907 23.669c11.263 15.768 29.447 25.126 48.824 25.126h65.269c19.33 0 35-15.67 35-35 0-19.33-15.67-35-35-35z" fill="#ffbeaa"/><path d="m151 468.922c0-19.803 13.417-36.988 32.629-41.791l172.054-43.013c18.892-4.723 38.345-7.118 57.817-7.118 37.22 0 67.5 30.28 67.5 67.5s-30.28 67.5-67.5 67.5h-219.422c-23.753 0-43.078-19.325-43.078-43.078z" fill="#989dec"/><path d="m317.922 512h-219.422c-37.22 0-67.5-30.28-67.5-67.5s30.28-67.5 67.5-67.5c19.472 0 38.925 2.395 57.817 7.118l172.054 43.013c19.212 4.803 32.629 21.988 32.629 41.791 0 23.753-19.325 43.078-43.078 43.078z" fill="#bceaf9"/><path d="m328.371 427.131-72.371-18.092v102.961h61.922c23.753 0 43.078-19.325 43.078-43.078 0-19.803-13.417-36.988-32.629-41.791z" fill="#acceff"/><path d="m256 160c-44.112 0-80-35.888-80-80s35.888-80 80-80 80 35.888 80 80-35.888 80-80 80z" fill="#ffdecf"/><path d="m336 80c0-44.112-35.888-80-80-80v160c44.112 0 80-35.888 80-80z" fill="#ffcdbe"/></g></svg>"""
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

# document.body.appendChild StyleEditor()
import {layout} from './layout'

layout -> div.tabs ->
	div.header ->
		div.logo size('2em', '2em'), innerHTML: """<svg version="1.1" id="Capa_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 168.1 168.1" style="enable-background:new 0 0 168.1 168.1;" xml:space="preserve">
<g>
	<path d="M142.119,19.245C123.68,9.39,99.36,12.383,84.077,26.134C68.72,12.394,44.361,9.433,25.984,19.245
		C9.968,27.737,0,44,0,61.658c0,5.056,0.84,10.08,2.326,14.408c7.839,33.931,58.163,78.583,81.751,78.583
		c23.537,0,73.823-44.656,81.527-78.008c1.652-4.908,2.495-9.92,2.495-14.988C168.1,44,158.141,27.731,142.119,19.245z
		 M154.157,73.396c-7.294,31.578-54.816,69.347-70.08,69.347c-16.987,0-63.271-39.567-70.303-69.921
		c-1.256-3.661-1.86-7.409-1.86-11.157c0-13.241,7.526-25.478,19.638-31.902c5.64-3.021,12.056-4.58,18.542-4.58
		c11.416,0,22.162,4.843,29.492,13.308l4.543,5.199l4.475-5.199c11.415-13.247,32.384-17.056,47.97-8.728
		c12.112,6.424,19.639,18.661,19.639,31.902C156.188,65.406,155.58,69.155,154.157,73.396z M149.506,61.658
		c0,3.114-0.523,6.244-1.564,9.324c-0.425,1.253-1.56,1.993-2.824,1.993c-0.317,0-0.63-0.022-0.952-0.131
		c-1.564-0.526-2.386-2.222-1.86-3.776c0.837-2.473,1.286-4.98,1.286-7.41c0-8.891-5.049-17.083-13.172-21.362
		c-3.852-2.057-8.021-3.114-12.397-3.114c-1.665,0-2.96-1.308-2.96-2.96c0-1.653,1.295-2.955,2.96-2.955
		c5.341,0,10.45,1.253,15.188,3.776C143.257,40.366,149.506,50.556,149.506,61.658z"/></g></svg>"""
		div.brand 'Little Theorem'

	apps = {Todos, EditableTodos, Music, Blog, Calculator, RandGetter, TicTac}
	tabs = state app: null
	for name, app of apps then div.tab.$for(app) (app)->
		button name or '[Unnamed App]', onclick: -> tabs.app = app
	div.app ->
		tabs.app?() or div.blank ->
			span 'Choose an app'
