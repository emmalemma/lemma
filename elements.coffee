import {effect, stop, reactive} from '@vue/reactivity'
import {elementBuilder} from './builder.coffee'

# Stack variables
parentElement = null
rootElement = null
activeEffect = null
cursor = null
insertElement = null
lastProperElement = null

checkRenders = (target)->
	if target.needsRerender
		do target.effect
		target.needsRerender = false
	else if target.childNeedsRerender
		checkRenders child for child in target.children
		target.childNeedsRerender = false

schedule𝑓 = (effect)->
	effect.element.needsRerender = true
	parentEffect = effect
	console.log 'marking render on', effect.element
	while (parentEffect = parentEffect.parent) and not (parentEffect.element.childNeedsRerender or parentEffect.element.needsRerender)
		console.log 'tracing render to', parentEffect.element
		parentEffect.element.childNeedsRerender = true

	unless effect.rootElement.renderScheduled
		effect.rootElement.renderScheduled = true
		# queueMicrotask preempts some DOM behaviors (e.g. checkboxes)
		setTimeout (->
			effect.rootElement.renderScheduled = false
			# perf: should flag actual root of mutation
			checkRenders effect.rootElement), 0

effectCatcher = (element, effectFn)->
	_activeEffect = activeEffect
	element.effect = activeEffect = effect effectFn,
		scheduler: schedule𝑓
		lazy: true
	activeEffect.parent = _activeEffect
	activeEffect.element = element
	activeEffect.rootElement = _activeEffect?.rootElement or rootElement
	do activeEffect
	activeEffect = _activeEffect


clearEffects = (element)->
	stop element.effect if element.effect
	for child in element.children
		clearEffects child

makeEffect = (element, bodyFn)->
	element.bodyFn = bodyFn
	effectCatcher element, ->
		_parent = parentElement
		parentElement = element
		_cursor = cursor
		cursor = element.firstElementChild
		_insert = insertElement
		insertElement = element.firstElementChild

		_activeEffect = activeEffect
		activeEffect = element.effect

		_last = lastProperElement
		lastProperElement = null
		bodyFn.call element

		lastElement = if lastProperElement
			lastProperElement.nextElementSibling
		else
			element.firstElementChild

		while lastElement
			_last = lastElement.nextElementSibling
			lastElement.parentElement.removeChild lastElement
			clearEffects lastElement
			lastElement = _last

		activeEffect = _activeEffect
		lastProperElement = _last
		cursor = _cursor
		insertElement = _insert
		parentElement = _parent

applyProps = (element, props)->
	for prop, value of props
		if false and eventMatch = prop.match /^on(.+)$/
			event = eventMatch[1]
			element.addEventListener event, value
		else
			switch prop
				when 'x' then null
				when 'checked'
					element[prop] = if value then true else false
				else element[prop] = value
	for prop, value of element.cachedProps
		unless prop of props
			delete element[prop]
	element.cachedProps = props

matchKeyProps = (element, keyProps)->
	return false unless element.tagName.toLowerCase() is keyProps.tagName.toLowerCase() and element.dataset.class is keyProps.class
	if keyProps._args
		for arg, idx in keyProps._args
			return false unless arg is element._args[idx]
	true

makeOrRetrieve = (keyProps)->
	while cursor and not matchKeyProps cursor, keyProps
		cursor = cursor.nextElementSibling

	if cursor
		return cursor

	else
		element = document.createElement keyProps.tagName
		element.dataset.class = keyProps.class if keyProps.class
		element._args = keyProps._args
		return element

combineProps =(target, ext)->
	for k, v of ext
		switch k
			when 'style', 'className'
				target[k] ?= ''
				target[k] += ' ' + v
			else target[k] = v

_elements =  (keyProps, args...)->
	props = {}
	for arg in args
		switch typeof arg
			when 'function' then bodyFn = arg
			when 'object'
				combineProps props, arg
			when 'string' then textContent = arg

	if textContent
		props.textContent = textContent

	if (_args = keyProps._args) and (_bodyFn = bodyFn)
		bodyFn = -> _bodyFn _args...

	element = makeOrRetrieve keyProps

	if parentElement
		if insertElement
			if insertElement is element
				insertElement = element.nextElementSibling
			else
				parentElement.insertBefore element, insertElement
		else
			parentElement.appendChild element
	else
		rootElement = element

	cursor = element.nextElementSibling

	applyProps element, props

	if bodyFn
		if element.effect
			checkRenders element
		else
			makeEffect element, bodyFn

	return lastProperElement = element

export elements = elementBuilder _elements

export state = reactive
