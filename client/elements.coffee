import {effect, stop, reactive, computed} from '@vue/reactivity'
import {elementBuilder} from './builder'
import {delay} from './util'

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
		target.needsRerender = target.childNeedsRerender = false
		# delete target.dataset.needsRerender
		# delete target.dataset.childNeedsRerender

	else if target.childNeedsRerender
		checkRenders child for child in target.children
		target.childNeedsRerender = false
		# delete target.dataset.childNeedsRerender



schedulef = (effect)->
	effect.element.needsRerender = true
	# effect.element.dataset.needsRerender = true
	# effect.element.dataset.rootElement = effect.rootElement.tagName
	parentEffect = effect
	while (parentEffect = parentEffect.parent) and not (parentEffect.element.childNeedsRerender or parentEffect.element.needsRerender)
		parentEffect.element.childNeedsRerender = true
		# parentEffect.element.dataset.childNeedsRerender = true


	unless effect.rootElement.renderScheduled
		effect.rootElement.renderScheduled = true
		# effect.rootElement.dataset.renderScheduled = true
		await delay 0
		effect.rootElement.renderScheduled = false
		# effect.rootElement.dataset.renderScheduled = false
		checkRenders effect.rootElement

effectCatcher = (element, effectFn)->
	_activeEffect = activeEffect
	element.effect = activeEffect = effect effectFn,
		scheduler: schedulef
		lazy: true
		# onTrack: (args...)->console.log element, 'track', args
		# onTrigger: (args...)->console.log element, 'trigger', args
	activeEffect.parent = _activeEffect
	activeEffect.element = element
	activeEffect.rootElement = _activeEffect?.rootElement or rootElement
	do activeEffect
	activeEffect = _activeEffect


clearEffects = (element)->
	stop element.effect if element.effect
	cleaner() for cleaner in element.cleanups or []
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
			if element instanceof SVGElement
				switch prop
					when 'className' then element.setAttribute 'class', value
					else element.setAttribute prop, value
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
		if keyProps.svg
			element = document.createElementNS "http://www.w3.org/2000/svg", keyProps.tagName
		else
			element = document.createElement keyProps.tagName
		element.dataset.class = keyProps.class if keyProps.class
		element._args = keyProps._args
		element.rerender
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
				if Array.isArray arg
					combineProps props, opts for opts in arg
				else
					combineProps props, arg
			when 'string' then textContent = arg

	if textContent?
		props.textContent = textContent

	if (_args = keyProps._args) and (_bodyFn = bodyFn)
		bodyFn = -> _bodyFn _args...

	element = makeOrRetrieve keyProps

	if parentElement
		if insertElement
			if insertElement is element
				insertElement = element.nextElementSibling
			else unless insertElement.previousElementSibling is element
				parentElement.insertBefore element, insertElement
		else unless parentElement.lastElementChild is element
			parentElement.appendChild element
	else
		rootElement = element

	cursor = element.nextElementSibling

	if 'body' of props
		bodyFn = props.body
		delete props.body

	applyProps element, props

	if bodyFn
		if element.effect
			checkRenders element
		else
			makeEffect element, bodyFn

	return lastProperElement = element

export elements = elementBuilder _elements
export svgElements = elementBuilder _elements, svg: true

export state = reactive
state.computed = computed

export cleanup =(cb)->
	console.log
	parentElement.cleanups ?= []
	parentElement.cleanups.push cb

export rerender =(element)->
	schedulef element.effect if element.effect

export layout = (element)->
	document.body.appendChild element

export assumeRoot = (element, bodyFn)->
	rootElement = element
	makeEffect element, bodyFn

export registerComponent = (name, fn)->
	className = name.replace(/(:?^|-)(\w)/g, (m,c,s)->s.toUpperCase())+'Component'
	box = [className]: class extends HTMLElement
		constructor: ->
			super()
			do =>
				await delay 0
				assumeRoot this, fn
	customElements.define name, box[className]
