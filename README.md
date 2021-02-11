## **lemma**

> A lemma is a small, formally proven result which is used in the proof of a more consequential theorem.

Lemma is an experimental full-stack JS library built on top of Deno, CoffeeScript and Rollup.js. The goal: do as much as possible, while doing as little as possible.

### Components

#### client
A simple declarative syntax for building a tree of native DOMElements, each with a native closure context. A minimal runtime updates elements in-place using Vue's proxy-based reactive objects.

#### server
A Deno development server based on Oak which serves client code as pages according to the codebase directory structure, similar to Next.js. It supports the RPC interface that lets client and server code communicate transparently.

#### bundler
A build-time wrapper around rollup.js and a set of plugins which partition the codebase into client and server-side on a per-file basis. Server-side exports are converted into RPC methods on the client side.

## Philosophy

Unlike many frameworks which are intended to encourage separation of concerns among large teams, Lemma is explicitly intended to encourage the commingling of concerns. This approach empowers a sole developer to rapidly iterate on a UI concept. Paradoxically, the absence of a large-scale organizing abstraction enables one to easily refactor code as the app grows, leveraging mostly conventional JavaScript semantics.

## Demo

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

	input onkeypress: keyCode(13) clearTarget() ({target: {value}})-> tasks.push {body: value}
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

#### Incentives

- Very low boilerplate (sensible defaults for small apps)
- Full-stack simplicity (seamless client-server interaction)
- Flexibility in iterative development (state lifting, refactoring components)
- Single technology (it's all just JavaScript)

#### Features

- Declarative, compositional syntax
- Native JavaScript closure scopes for both state and view code
- Automatic RPC generation between client and server code

#### What makes Lemma different?

Lemma selectively combines many features that are common among front-end frameworks, with a specific focus on balancing build-time and run-time simplicity.

Unlike Angular and Ember.js, Lemma uses pure-JS render functions rather than HTML templates or inline attributes.

Unlike React and Vue.js, Lemma creates raw DOMElement nodes which are returned directly to the caller, and updates them in-place with a minimal runtime rather than via a virtual DOM. Event handlers are assigned in-place with the closure scope where they are defined.

Unlike Svelte and Imba, Lemma does not use a build-time compilation step (apart from the recommended CoffeeScript compiler) to produce front-end code-- however, automatic RPC generation does require bundling.

Unlike raw JavaScript, Lemma provides a simple declarative syntax, reactive updating of components, and a principled approach to state flow through the app.

Uniquely, Lemma uses CoffeeScript by default as an expressive syntax for view code. There is no special "component" abstraction; every element has its own closure scope which is used for state management and runtime behavior.

Lemma works as a full-stack system, which partitions client- and server-side code across a transparent RPC interface to a Deno-based API server.

#### Why should you use Lemma?

I really don't think you should! You should continue to use whatever technology your working production system is already built on, and focus on approaches with which your team is already familiar.

If you're building a web app from scratch in 2021, I recommend React.js as a default. If a minimal, compositional style is attractive, consider testing Vue 3 with the Composition API. Where bundle size and raw performance are priorities, try Svelte, or if you are up for something more dramatic, take a look at Imba.

Lemma is an experiment. It's not at all ready for production applications, and it may never be. There is little test coverage, the APIs are not stable, and many of the core abstractions can be at best called "esoteric".

With that said, if you're interested in the kind of web development which is possible when abstractions built on pure JS are pushed to the breaking point, poke around. You might just find something here that entertains.

## Client overview

As can be inferred from the code above, a basic element function like `div` returns a raw DOMElement, as in e.g. hyperscript. Fields of the property object passed in are assigned directly to that element, and its body function is evaluated recursively in the context of that element as a parent. `e.lements` is a proxy which produces functions with an arbitrary `tagName`, and `div` is a proxy which implicitly applies a `className` to the resulting props.

In other words, simplified definition for `div`:

```coffeescript
div.parent property: value, ->
  div.child 'Text Content'

# Behaves as if div is something like:

parentElement = null
div = new Proxy {},
  get: (_, className)->
    (props, bodyFn) ->
      element = document.createElement 'DIV'
      element.className = className
      element[prop] = value for prop, value of props
      parentElement?.appendChild element
      parentElement = element
      bodyFn.call element
```

Reactivity happens on a per-element basis: element bodies that access a reactive object are automatically reevaluated in-place when the reactive value changes. Elements which already exist (on the basis of the proxy-defined properties `tagName.className(...)`) are reused in order,

In other words, a more accurate simplified definition:

```coffeescript
text = ref ''
div.context ->
  div.output text.value
  input oninput: ({target: {value}})-> text.value = value


# Within the proxy, the body of the element generator looks more like:

... = (props, bodyFn)->
  element = findOrCreate(parentElement, tagName, className)
  element[prop] = value for prop, value of props
  parentElement?.appendChild element
  watchEffect ->
    parentElement = element
    bodyFn.call element
    removeOldElements(parentElement)

# where `watchEffect`, as in Vue 3, simply reevaluates the provided function when a reactive object it references is mutated
```

Since by default, reactive mutations are consumed by their closest containing `effect`, only the necessary body functions are reevaluated. This simple(ish) logic replaces the diff/patch mechanism of a virtual DOM:

```coffeescript
div.deeply ->
  div.nested ->
    div.scope ->
      text = ref ''
      div.getting ->
        # only this closure will be reevaluated on an input event
        div text.value # this is the only element that will be mutated
      div.setting ->
        # since the parent closure where text is defined won't be reevaluated, this event handler remains valid
        input oninput: ({target: {value}})-> text.value = value
```

There is clearly a decent amount of runtime magic happening to enforce these rules. But the benefit of doing things this way is that's where the magic ends-- the remaining semantics are purely those of JavaScript closure scope and function composition.

Consider what happens when we add a feature to the above:

```coffeescript
div.deeply ->
  div.nested ->
    # this _self-evidently_ won't work: `text` is not defined in this closure scope
    div.preview text.value
    div.scope ->
      text = ref ''
      div.getting ->
        div text.value
      div.setting ->
        input oninput: ({target: {value}})-> text.value = value
```

Knowing only the rules of JavaScript, it's obvious that the `text` ref must be lifted:


```coffeescript
div.deeply ->
  # we need to lift text to here
  text = ref ''
  div.nested ->
    # we access `text` here, so it obviously needs to be in a containing closure scope
    div.preview text.value
    div.scope ->
      # but since this closure doesn't immediately reference `text`, its body can be reused
      div.getting ->
        # only this closure is reevaluated
        div text.value
      div.setting ->
        # so this event handler still doesn't need to be redefined on input!
        input oninput: ({target: {value}})-> text.value = value
```

So following only conventional coding practices, it's completely natural to localize state to the nearest scope where it will be needed, and to lift state up as necessary when refactoring.

## Server overview

...

## Bundler

...
