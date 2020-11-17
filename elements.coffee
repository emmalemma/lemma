import {effect, track, trigger, ref, reactive} from '@vue/reactivity'

contextElement = null
contextEffect = null
contextIdx = 0
scheduler = null

markChildren = removeMarked =->


applyProps = (element, props)->
	for k, v of props
		if m = k.match /^on(.+?)(capture|)$/i
			event = m[1].toLowerCase()
			capturing = m[2].toLowerCase() is 'capture'
			element.addEventListener event, v, capturing
		else
			continue if k in ['tagName']
			k = 'className' if k is 'class'
			element[k] = v

applyOutcome = (outcome)->
	if typeof outcome is 'string'
		contextElement.textContent = outcome
	else if typeof outcome is 'object'
		applyProps contextElement, outcome

reactiveMutator = (mutator)->
	if typeof mutator isnt 'function'
		return -> applyOutcome mutator

	outerEffect = null
	_wrapper = ->
		console.log 'EFFECT', mutator
		outerEffect.scheduled = false
		markChildren(outerEffect.children)
		_ctx = contextEffect
		contextEffect = outerEffect
		_idx = contextIdx
		contextIdx = 0
		outcome = do mutator
		contextIdx = _idx
		contextEffect = _ctx
		applyOutcome outcome
		removeMarked(outerEffect.children)
		outerEffect.cached = true
	outerEffect = effect _wrapper, lazy: true, scheduler: ->
		console.log 'SCHEDULED', mutator
		outerEffect.cached = no
		while (parent = outerEffect.parentEffect) and parent.descentCached
			parent.descentCached = no
		unless scheduler.scheduled
			scheduler.scheduled = yes
			queueMicrotask -> do scheduler

	outerEffect.parentEffect = contextEffect
	outerEffect

matchesProps = (element, keyProps)->
	element.tagName is keyProps.tagName and element.className is keyProps.class

findOrMake = (keyProps, mutators)->
	if (element = contextEffect.elements?[contextIdx]) and matchesProps element, keyProps
		contextIdx += 1
		return {element, state: element._ur_state}

	element = document.createElement keyProps.tagName
	element.className = keyProps.class
	if contextElement
		contextElement.appendChild element

	if contextEffect
		contextEffect.elements ?= []
		contextEffect.elements.push element

	state = element._ur_state = {mutators: (reactiveMutator mutator for mutator in mutators)}
	{element, state}

make = (keyProps, mutators...)->
	console.log 'MAKING', keyProps
	{element, state} = findOrMake keyProps, mutators

	_ctx = contextElement
	contextElement = element

	for mutator in state.mutators
		unless mutator.cached
			do mutator
		else unless mutator.descentCached
			descend mutator

	contextElement = _ctx
	element

el_chainer = ->
	props = {}
	proxy = new Proxy (->),
		get: (target, prop)->
			if typeof prop is 'string'
				if prop is '$key'
					return (key)->
						props._key = key
						proxy
				if prop is '$for'
					return (args...)->
						props._args = args
						proxy
				unless props.tagName
					props.tagName = prop
				else
					if props.class
						props.class += " #{prop}"
					else
						props.class = "#{prop}"
			else if typeof prop is 'symbol'
				props._key = prop
			proxy
		apply: (target, it, args)->
			unless typeof args[0] is 'object'
				args.unshift props
			else
				args[0][k] = v for k, v of props
			props = {tagName: props.tagName}
			make.apply it, args

export elements = new Proxy {},
	get: (target, prop)->
		if prop is '$'
			el_generator
		else el_chainer()[prop]

export attach = (element, fn)->
	do render =->
		scheduler = render
		scheduler.scheduled = no
		_ctx = contextElement
		contextElement = element
		contextEffect = fn
		do fn
		contextElement = _ctx
