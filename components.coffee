import {effect, track, trigger, ref, reactive} from '@vue/reactivity'

export component = (_inner_render)->
	el_generator = el_chainer = null

	parent = null
	domCache = []
	cacheIdx = null
	_el_sentinel = {}

	isScheduled = no
	activeEffect = null

	track𝑓 = ({target, key, type})->

	trigger𝑓 = ({target, key, type, effect})->

	rerender𝑓 =->
		isScheduled = no
		cacheIdx = 0
		_inner_render el_generator

	schedule𝑓 = (effect)->
		unless isScheduled
			isScheduled = yes
			queueMicrotask rerender𝑓

		effect.cached = no
		while (effect = effect.parentEffect)?.cached
			effect.cached = no

	el = (contents...)->
		props = contents[0]

		element = parent.children[cacheIdx]

		if not element or element.tagName isnt props.tagName.toUpperCase() or (element.className and element.className isnt props.class) or (element._key and element._key isnt props._key) or (element._args and not element._args.every((arg)->props._args.includes(arg)))
			newElement = document.createElement props.tagName
			unless element
				parent.appendChild newElement
				newElement._invalidators = []
			else
				parent.insertBefore newElement, element

			element = newElement
			element._effects = {}
		else
			element._mark = false

		cacheIdx += 1

		applyContent = null
		applyEffect =(content, idx)->
			try
				_activeEffect = activeEffect
				activeEffect = element._effects[idx] ?= effect (-> applyContent content),
					lazy: true
					onTrack: track𝑓
					onTrigger: trigger𝑓
					scheduler: schedule𝑓
				do activeEffect
				activeEffect.cached = true
				activeEffect.parentEffect = _activeEffect
				activeEffect.element = element
				activeEffect.content = content
				activeEffect = _activeEffect
			catch e
				console.error 'Error in apply:', e
		applyContent =(content, idx)->
			if content is _el_sentinel
				return
			else if typeof content is 'function'
				if activeEffect.invalidators
					console.log 'invalidating', activeEffect.invalidators
					for invalidate in activeEffect.invalidators
						invalidate()
				activeEffect.invalidators = []

				_parent = parent
				parent = element

				_cacheIdx = cacheIdx
				cacheIdx = 0

				for child in element.children
					child._mark = true

				result = content((props._args or [])...)
				if typeof result is 'string'
					console.log 'effect setting text value', result
				applyContent result

				remove = []
				for child in element.children
					console.log 'considering removing', child
					if child._mark
						remove.push child
				for child in remove
					element.removeChild child

				cacheIdx = _cacheIdx
				parent = _parent

			else if typeof content is 'string'
				# do ->
				# 	_content = element.textContent
				# 	activeEffect.invalidators.push ->
				# 		element.textContent = _content
				element.textContent = content

			else if typeof content is 'object'
				# console.log 'applying content object', content
				for k, v of content
					if m = k.match /^on(.+?)(capture|)$/i
						event = m[1].toLowerCase()
						capturing = m[2].toLowerCase() is 'capture'
						element.addEventListener event, v, capturing
						activeEffect.invalidators ?= []
						activeEffect.invalidators.push do (event, v)->-> element.removeEventListener event, v, capturing
					else
						continue if k in ['tagName']
						k = 'className' if k is 'class'
						element[k] = v

		for content,idx in contents
			unless typeof content is 'function'
				applyContent content
			else if element._effects[idx]?.cached
				continue
			else
				applyEffect content, idx

		_el_sentinel

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
				el.apply it, args

	el_generator = new Proxy {},
		get: (target, prop)->
			if prop is '$'
				el_generator
			else el_chainer()[prop]

	renderEffect = null
	isScheduled = no

	attach: (root)->
		parent = root
		rerender𝑓()


bind = (object)->
	new Proxy {},
		get: (target, prop)->
			value: (->target[prop]), onInput: ({target: {value}})->target[prop] = value


elementState = (element)->
	element._ur_state ?= {}

handleElement = null

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

export elementTree = (rootEffect)->
	contextElement = null
	contextEffect = null
	renderContext𝑓 = null
	cacheIdx = 0

	applyOutcome = (outcome)->
		if typeof outcome is 'string'
			contextElement.textContent = outcome
		else if typeof outcome is 'object'
			applyProps contextElement, outcome

	renderScheduled = no

	markChildren =->
	removeMarked =->

	findCache =(keyProps)->
		console.log 'RETRIEVE', keyProps, cacheIdx
		el = contextEffect.childElements?[cacheIdx]
		cacheIdx += 1
		el

	prepareEffect = (innerEffect)->
		if typeof innerEffect isnt 'function'
			return -> applyOutcome innerEffect

		outerEffect = null
		_wrapper = ->
			markChildren(outerEffect.children)
			console.log 'Performing inner effect', innerEffect
			outcome = do innerEffect
			applyOutcome outcome
			removeMarked(outerEffect.children)
			outerEffect.cached = true
		outerEffect = effect _wrapper, lazy: true, scheduler: ->
			console.log 'SCHEDULED', innerEffect
			unless renderScheduled
				renderScheduled = yes
				queueMicrotask renderContext𝑓
			outerEffect.cached = no
			while (parent = outerEffect.parentEffect) and parent.descentCached
				parent.descentCached = no

		outerEffect.parentEffect = contextEffect
		outerEffect

	renderContext𝑓 = ->
		console.log "RENDER CONTEXT", contextElement, contextEffect
		renderScheduled = no
		contextState = elementState(contextElement)
		for childEffect in contextState.effects
			_fx = contextEffect
			contextEffect = childEffect
			unless childEffect.cached
				do childEffect
			else unless childEffect.descentCached
				for child in childEffect.childElements or []
					_ctx = contextElement
					contextElement = child
					_idx = cacheIdx
					cacheIdx = 0
					renderContext𝑓()
					cacheIdx = _idx
					contextElement = _ctx
					# childEffect.descentCached = true
			contextEffect = _fx

	makeElement =(keyProps)->
		el = document.createElement keyProps.tagName
		el.className = keyProps.class
		el

	handleElement =(keyProps, effects...)->
		console.log 'HANDLE ELEMENT', keyProps, effects...
		cachedElement = findCache keyProps
		if cachedElement
			contextState = elementState(cachedElement)
		else
			cachedElement = makeElement keyProps
			contextState = elementState(cachedElement)
			contextElement.appendChild cachedElement
			contextEffect.childElements ?= []
			contextEffect.childElements.push cachedElement
			contextState.effects = (prepareEffect fx for fx in effects)
		contextState.marked = false

		_ctx = contextElement
		contextElement = cachedElement
		_idx = cacheIdx
		cacheIdx = 0

		renderContext𝑓()

		contextElement = _ctx
		cacheIdx = _idx

	(rootElement)->
		contextElement = rootElement
		elementState(contextElement).effects = [prepareEffect rootEffect]
		renderContext𝑓()

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
			handleElement.apply it, args

export elements = new Proxy {},
	get: (target, prop)->
		if prop is '$'
			el_generator
		else el_chainer()[prop]
