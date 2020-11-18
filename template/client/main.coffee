import {ref, reactive, context} from 'ur'

root = document.createElement 'root'
document.body.appendChild root

todo = context ({})->
	nameInput = ref null
	todos = reactive []
	editState = ref false

	({div, span, button, input})->
		div.newItem ->
			nameInput.value = input.name placeholder: 'name'
			button.addItem 'Add Item', onclick: -> todos.push name: nameInput.value.value
			button.addItems 'Add Items', onclick: ->
				for i in [0..100]
					todos.push name: "#{i}"
			button.complete 'Complete All Tasks', onclick: ->
				todo.done = true for todo in todos
			unless editState.value
				button.edit 'Edit', onclick: -> editState.value = true
			else
				button.edit 'Done', onclick: -> editState.value = false

		div.list ->
			for item, idx in todos
				div.item.$for(item, idx) (item, idx)->
					unless editState.value
						input.done type: 'checkbox', checked: item.done, onclick: -> item.done = not item.done
						span.name item.name
					else
						div.actions ->
							input.name value: item.name, oninput: ({target: {value}})-> item.name = value
							button.delete 'Delete', onclick: -> todos.splice idx, 1
							button.moveUp 'MoveUp', onclick: -> todos.splice(idx, 1); todos.splice(idx - 1, 0, item)

todo root
