import {effect, track, trigger, ref, reactive} from '@vue/reactivity'
import {watchEffect} from 'vue'

console.log 'vue track: ', effect

export creactive = (input = {})->
	new Proxy input,
		get: (target, prop)->
			if typeof target[prop] is 'object'
				creactive target[prop]
			else
				target[prop]
		set: (target, prop, value)->
			target[prop] = value



export component = (_inner_render)->

	parent = null
	domCache = {}

	el = (contents...)->
		props = contents[0]
		key = "#{props.tagName} class=#{props.class} key=#{props.key}"
		cacheRecord = domCache[key] ?= {childCache: {}, invalidators: []}

		present = cacheRecord.element ?= document.createElement props.tagName
		cacheRecord.markToClear = false

		for invalidate in cacheRecord.invalidators
			invalidate()
		cacheRecord.invalidators = []


		_parent = parent



		for content in contents
			if typeof content is 'function'
				cacheRecord.invalidators.push watchEffect ->
					for ck, cr of cacheRecord.childCache
						cr.markToClear = true
					parent = present
					_cache = domCache
					domCache = cacheRecord.childCache
					do content
					domCache = _cache

					for ck, cr of cacheRecord.childCache
						if cr.markToClear and cr.attached
							present.removeChild cr.element
							cr.attached = false
			else if typeof content is 'string'
				present.textContent = content
			else if typeof content is 'object'
				for k, v of content
					if m = k.match /^on(.+)/
						event = m[1].toLowerCase()
						present.addEventListener event, v
						cacheRecord.invalidators.push do (event, v)->-> present.removeEventListener event, v
					else
						present.setAttribute k, v


		unless cacheRecord.attached
			_parent?.appendChild present
			cacheRecord.attached = true

		parent = _parent or present
		present

	el_chainer = ->
		props = {}
		proxy = new Proxy (->),
			get: (target, prop)->
				unless props.tagName
					props.tagName = prop
				else
					props.class ?= ""
					props.class += "#{prop} "
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

	watchEffect ->
		console.log 'running _inner_render'
		_inner_render el_generator
	console.log 'returning root'
	return parent
