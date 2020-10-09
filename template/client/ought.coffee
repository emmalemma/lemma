import {local, remote, persist, themes, cms, component, ref, reactive, symbolize, toRaw, elements, mount} from 'ur'

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
	document.body.innerHTML = ''
	cms().display()
	# mount Root, 'body'

	todos = reactive []
	newTodo = ref ''

	#
	# rootComponent = component ({el, il, input, label, h1, button})->
	# 	el.root ->
	# 		el.actions.cms ->
	# 			label ->
	# 				input type: 'checkbox', checked: cms().settings.highlight, onChange: ({target:{checked}})->
	# 					cms().settings.highlight = checked
	# 				il 'Edit CMS'
	# 		el.ought ->
	# 			el.header cms.ought.header()
	# 			el.body cms.ought.body()
	#
	# rootComponent.attach document.body
	# # mount rootComponent, document.body

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

	rootComponent = component ({el, label, il, input, button})->
		el.ought ->
			el.header cms.ought.header()
			el.tagline cms.ought.tagline()
			el.body cms.ought.body()

			el.todo ->
				button.addMany cms.todo.actions.addMany(), onClick: addMany𝑓
				el.newtodo ->
					input.task value: newTodo.value, onInput: ({target: {value}})-> newTodo.value = value
					button.add cms.todo.actions.add(), onClick: add𝑓
					el.preview ->
						il newTodo.value
				el.todos ->
					for todo,idx in todos
						el.todo.$for(todo) (todo)->
							il.task todo.task
							il.actions ->
								button.remove cms.todo.actions.remove(), onClick: ->remove𝑓(todo)
								button.moveUp cms.todo.actions.moveup(), onClick: ->moveUp𝑓(todo)

		el.backdrop ->
			el.imageLayer()
			el.imageLayer.shadow()
			el.shadowLayer ->
				el.header cms.ought.header()
				el.tagline cms.ought.tagline()
				el.body cms.ought.body()

	root = document.createElement 'root'
	document.body.appendChild root
	rootComponent.attach root
