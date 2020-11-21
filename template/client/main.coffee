import {elements, state} from 'ur'

# todoApp = makeTag 'todo-app', ({})->
# 	nameInput = ref null
# 	todos = reactive []
# 	# persistent(rest: ).
# 	# lists = persistent.remote(rest: '/api/lists').collection()
# 	editState = ref false
#
# 	({div, span, button, input})->
# 		div.newItem ->
# 			nameInput.value = input.name placeholder: 'name'
# 			button.addItem 'Add Item', onclick: -> todos.push name: nameInput.value.value; nameInput.value.value = ''
# 			button.addItems 'Add Items', onclick: ->
# 				for i in [0..100]
# 					todos.push name: "#{i}"
# 			button.complete 'Complete All Tasks', onclick: ->
# 				todo.done = true for todo in todos
# 			button.scramble 'Scramble', onclick: ->
# 				todos.sort ->Math.random() - 0.5
# 			button.scramble 'Sort', onclick: ->
# 				todos.sort (a, b)->if a.name < b.name then -1 else 1
# 			unless editState.value
# 				button.edit 'Edit', onclick: -> editState.value = true
# 			else
# 				button.edit 'Done', onclick: -> editState.value = false
#
# 		div.list ->
# 			for item, idx in todos
# 				listItem.$for(item) {item, onDelete:delete𝑓(item), onMoveUp:moveUp𝑓(item)}
#
#
#
# 				div.item.$for(item) (item, idx)->
# 					unless editState.value
# 						input.done type: 'checkbox', checked: item.done, onclick: -> item.done = not item.done
# 						span.name item.name, style: if item.done then 'text-decoration: line-through;' else ''
# 					else
# 						div.actions ->
# 							input.name value: item.name, oninput: ({target: {value}})-> item.name = value
# 							button.delete 'Delete', onclick: -> todos.splice todos.indexOf(item), 1
# 							button.moveUp 'MoveUp', onclick: ->idx = todos.indexOf(item); todos.splice(idx, 1); todos.splice(idx - 1, 0, item)

# import {elements, persistent, state} from 'ur-'
{div, span, button, input} = elements
do ->
	todos = state []
	document.body.appendChild div.todoApp ->
		input onkeypress: ({target, keyCode})-> (todos.push {task: target.value}; target.value = '') if keyCode is 13
		button 'Clear completed', onclick: -> todos.splice todos.indexOf(todo), 1 for todo in (todo for todo in todos when todo.done)
		for todo in todos
			div.$for(todo) (todo)->
				input type: 'checkbox', selected: todo.done, onclick: -> todo.done = not todo.done
				span.task todo.task

do ->
	todos = state []
	document.body.appendChild div.todoAppEditable ->
		input onkeypress: ({target, keyCode})-> (todos.push {task: target.value}; target.value = '') if keyCode is 13
		button 'Clear completed', onclick: -> todos.splice todos.indexOf(todo), 1 for todo in (todo for todo in todos when todo.done)
		for todo in todos
			div.$for(todo) (todo)->
				editable = state task: no
				div ->
					if editable.task
						button 'x', onclick: -> todos.splice todos.indexOf(todo), 1
						input.task value: todo.task, oninput: ({target: {value}})-> todo.task = value
						button 'done', onclick: -> editable.task = no
					else
						span.done JSON.stringify todo.done
						input.done type: 'checkbox', checked: todo.done, onclick: -> todo.done = not todo.done
						span.task todo.task
						button 'edit', onclick: -> editable.task = yes

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
