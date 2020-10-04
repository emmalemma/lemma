import {local, remote, persist, themes, cms, component, ref, reactive, symbolize, toRaw} from 'ur'

# import {App} from './app'
# import {Music} from './music'

local.connect 'persistence', 1, ['global']
remote.connect '/api/v1'

# EMBEDDED
themes.enable ref: remote store: 'themes', id: 'global'
cms().enable ref: remote store: 'cms', id: 'global'

# Root = registration (register, state)->
# 	register App, ->
# 		register Music
# 		state {}
do ->
	document.body.innerHTML = "Loading..."
	await persist.promise themes.ref
	await persist.promise cms().ref
	# mount Root, 'body'

	todos = reactive []
	newTodo = ref ''

	add𝑓 =->
		console.log 'adding', newTodo.value
		todos.push task: newTodo.value
		newTodo.value = ''

	remove𝑓 = (todo)->
		idx = todos.indexOf todo
		todos.splice idx, 1

	moveUp𝑓 = (todo)->
		idx = todos.indexOf todo
		todos.splice idx, 1
		todos.splice idx-1, 0, todo

	addMany𝑓 =->
		for i in [0..100]
			newTodo.value = i.toString()
			add𝑓()

	rootComponent = component ({el, il, input, button})->
		el.todo ->
			button.addMany cms.todo.actions.addMany(), onClick: addMany𝑓
			el.newtodo ->
				input.task ->value: newTodo.value, onInput: ({target: {value}})-> newTodo.value = value
				button.add cms.todo.actions.add(), onClick: add𝑓
				el.preview ->
					il -> newTodo.value
			el.todos ->
				for todo,idx in todos
					el.todo.$for(todo) (todo)->
						il.task -> todo.task
						il.actions ->
							button.remove cms.todo.actions.remove(), onClick: ->remove𝑓(todo)
							button.moveUp cms.todo.actions.moveup(), onClick: ->moveUp𝑓(todo)

	rootComponent.attach document.body
	#
	# populate =->
	# 	for i in [0..24000]
	# 		el = document.createElement 'el'
	# 		el.textContent = "test #{i}"
	# 		document.body.appendChild el
	#
	# notify =->
	# 	el = document.createElement 'el'
	# 	el.textContent = 'testing now'
	# 	document.body.appendChild el
	# 	setTimeout populate, 100
	#
	# el = document.createElement 'el'
	# el.textContent = "testing in 3..."
	# document.body.appendChild el
	#
	# setTimeout notify, 3000
