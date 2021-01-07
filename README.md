### **lemma**

 | A lemma is a smaller, proven result which is used in the proof of a more consequential theorem.

Lemma is a full-stack JS library built on top of Deno, CoffeeScript and Rollup.js. The philosophy of Lemma is to do as much as possible in terms of apparent semantics, while doing as little as possible in terms of library code.


A simple to-do app in its entirety:

```coffeescript
import {elements, state} from 'lemma'
{div, span, button, input} = elements

document.body.appendChild div.todoApp ->
  tasks = state []
  addTask = ({target, keyCode})->
    if keyCode is 13
      tasks.push {body: target.value}
      target.value = ''

  clearCompleted = ->
    for task in tasks.filter (task)->task.done
      tasks.splice tasks.indexOf(task), 1

	input onkeypress: addTask
	button 'clear completed', onclick: clearCompleted
  div.tasks ->
  	for task in tasks
  		div.$for(task) (task)->
  			input type: 'checkbox', selected: task.done, onclick: -> task.done = not task.done
  			span.task task.body
```

The same thing in raw ES6:

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

# Incentives

- Very low boilerplate (sensible defaults for small apps)
- Full-stack simplicity (seamless client-server interaction)
- Flexibility in iterative development (state lifting, refactoring components)
- Single technology (it's all just JavaScript)

# Features

- Declarative, compositional syntax
- Native JavaScript closure scopes for both state and view code
- Automatic RPC generation between client and server code

# What makes Lemma different?

Lemma selectively combines many features that are common among front-end frameworks, with a specific focus on balancing build-time and run-time simplicity.

Unlike Angular and Ember.js, Lemma uses pure-JS render functions rather than HTML templates or inline attributes.

Unlike React and Vue.js, Lemma creates raw DOMElement nodes which are returned directly to the caller, and updates them in-place with a minimal runtime rather than via a virtual DOM. Event handlers are assigned in-place with the closure scope where they are defined.

Unlike Svelte and Imba, Lemma does not use a build-time compilation step apart from the CoffeeScript compiler to produce front-end code-- however, automatic RPC generation does require bundling.

Unlike raw JavaScript, Lemma provides a simple declarative syntax, reactive updating of components, and a principled approach to state flow through the app.

Uniquely, Lemma uses CoffeeScript by default as an expressive syntax for view code. There is no special "component" abstraction; every element has its own closure scope which is used for state management and runtime behavior.

Lemma ships as a full-stack system, which partitions client- and server-side code across a transparent RPC interface to a Deno-based API server.

# Why should you use Lemma?

I really don't think you should! You should continue to use whatever technology your working production system is already built on, and focus on approaches with which your team is already familiar.

If you're building a web app from scratch in 2021, I recommend React.js as a default. If a minimal, compositional style is attractive, consider testing Vue 3 with the Composition API. Where bundle size and raw performance are priorities, try Svelte, or if you are up for something more dramatic, take a look at Imba.

Lemma is an experiment. It's not at all ready for production applications, and it may never be. There is little test coverage, the APIs are not stable, and many of the core abstractions can be at best called "esoteric".

With that said, if you're interested in the kind of web development which is possible when abstractions built on pure JS are pushed to the breaking point, poke around. You might just find something here that entertains.
