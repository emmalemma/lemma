import {effect, stop, reactive} from '@vue/reactivity'

parentElement = null

elementBuilder = (el)->
	el_chainer = (tagName)->
		props = {tagName}
		proxy = new Proxy (->),
			get: (target, prop)->
				if typeof prop is 'string'
					if prop is '$for'
						return (args...)->
							props._args = args
							proxy
					else
						if props.class
							props.class += " #{prop}"
						else
							props.class = "#{prop}"
				else if typeof prop is 'symbol'
					props._key = prop
				proxy
			apply: (target, it, args)->
				args.unshift props
				props = {tagName}
				el.apply it, args

	el_generator = new Proxy {},
		get: (target, prop)->
			if prop is '$'
				el_generator
			else el_chainer(prop)

checkRenders = (target)->
	if target.needsRerender
		do target.effect
		target.needsRerender = false
	else if target.childNeedsRerender
		checkRenders child for child in target.children
		target.childNeedsRerender = false

rootElement = null
scheduled = false
schedule𝑓 = (effect)->
	effect.element.needsRerender = true
	parentEffect = effect
	while (parentEffect = parentEffect.parent) and not (parentEffect.element.childNeedsRerender or parentEffect.element.needsRerender)
		parentEffect.element.childNeedsRerender = true

	unless scheduled
		scheduled = true
		# queueMicrotask preempts some DOM behaviors (e.g. checkboxes)
		setTimeout (->
			scheduled = false
			# perf: should flag actual root of mutation
			checkRenders effect.rootElement), 0

activeEffect = null
effectCatcher = (element, effectFn)->
	_activeEffect = activeEffect
	element.effect = activeEffect = effect effectFn,
		scheduler: schedule𝑓
		lazy: true
	activeEffect.parent = _activeEffect
	activeEffect.element = element
	activeEffect.rootElement = rootElement
	do activeEffect
	activeEffect = _activeEffect

cursor = null
insertElement = null
lastProperElement = null

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
		do bodyFn

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
	return false unless element.tagName.toLowerCase() is keyProps.tagName.toLowerCase() and element.keyClass is keyProps.class
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
		element.className = keyProps.class
		element.keyClass = keyProps.class
		element._args = keyProps._args
		return element



_elements =  (keyProps, args...)->
	for arg in args
		switch typeof arg
			when 'function' then bodyFn = arg
			when 'object'
				if props
					props[k] = v for k, v of arg
				else
					props = arg
			when 'string' then textContent = arg

	unless props
		props = {}

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

	lastProperElement = element

	return element

export elements = elementBuilder _elements

export state = reactive

export makeTag = (tagName, contextFn)->
	return (inputs)->
		renderFn = contextFn inputs or {}
		# initialize state stack
		els = elementBuilder(elements)
		target = document.createElement tagName

		effectCatcher target, ->
			rootElement ?= parentElement = target
			renderFn els
		target
