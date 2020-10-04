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

		if not element or element.tagName isnt props.tagName.toUpperCase() or element.className isnt props.class or (element._key and element._key isnt props._key) or (element._args and not element._args.every((arg)->props._args.includes(arg)))
			console.log 'not reusing a', element
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
				activeEffect = _activeEffect
			catch e
				console.error 'Error in apply:', e
		applyContent =(content, idx)->
			if content is _el_sentinel
				return
			else if typeof content is 'function'
				if activeEffect.invalidators
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
				applyContent result

				remove = []
				for child in element.children
					if child._mark
						remove.push child
				for child in remove
					element.removeChild child

				cacheIdx = _cacheIdx
				parent = _parent

			else if typeof content is 'string'
				element.textContent = content

			else if typeof content is 'object'
				for k, v of content
					if m = k.match /^on(.+)/
						event = m[1].toLowerCase()
						element.addEventListener event, v
						activeEffect.invalidators ?= []
						activeEffect.invalidators.push do (event, v)->-> element.removeEventListener event, v
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
