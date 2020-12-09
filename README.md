### **lemma**

 | A lemma is a smaller, proven result which is used in the proof of a more consequential theorem.

Lemma is a full-stack JS library that... well, you'll see.

```coffeescript
import {elements, state} from 'lemma'
{div, span, button, input} = elements

tasks = state []
document.body.appendChild div.todoApp ->
	input onkeypress: ({target, keyCode})-> (tasks.push {body: target.value}; target.value = '') if keyCode is 13
	button 'clear completed', onclick: -> tasks.splice tasks.indexOf(task), 1 for task in tasks.filter((task)->task.done)

	for task in tasks
		div.$for(task) (task)->
			input type: 'checkbox', selected: task.done, onclick: -> task.done = not task.done
			span.task task.body
```


```javascript
import {elements, state} from 'lemma';
const {div, span, button, input} = elements;

const tasks = state([]);
document.body.appendChild(div.todoApp(_=>{
	input({onkeypress: ({target, keyCode}) => if (keyCode === 13) { tasks.push({body: value}); target.value = '';}});
	button('clear completed', onclick: _=> tasks.filter(t=>t.done).forEach((task)=>tasks.splice(tasks.indexOf(task), 1)));

	tasks.forEach(task => {
		div.$for(task)(_ => {
			input({type: 'checkbox', checked: task.done, onclick: _=>task.checked = !task.checked});
			span.task(task.body)
		});
	});
}));
```
