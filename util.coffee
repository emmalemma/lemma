import {effect} from '@vue/reactivity'

export mutate =(obj, fn)->
	fn.call this, obj
	obj

export delay =(delay, fn)->
	throw new Error 'Wrong delay api' if fn
	new Promise (res) ->
		setTimeout res, delay

export quoted =(s)->"\"#{s}\""

export pluralize =(string, count)->
	"#{string}#{if count is 1 then '' else 's'}"

export randInt =(min, max)->
	Math.floor(Math.random() * (max - min)) + min

export canonical =(object)->
	replacer = (key, value)->
		if typeof value is 'function'
			value.toString()
		else
			value
	JSON.stringify object, replacer, 2

export clamp =(x, min, max)->
	Math.max min, Math.min x, max

export tokenize =(s)->s.trim().replace(/[^A-Za-z0-9]+/g, '-')

SymbolRegistry = new WeakMap
export symbolize =(object)->
	SymbolRegistry.get(object) or SymbolRegistry.set(object, Symbol('symbolized')).get(object)


traverse =(value)->
	if typeof value is 'object'
		if Array.isArray value
			traverse v for v in value
		else
			for own k, v of value
				traverse v

export watch = (watcher, cb)->
	doEffect = effect (->traverse watcher()), scheduler: (->cb(); doEffect())

watch.shallow = (watcher, cb)->
	doEffect = effect (->watcher()), scheduler: (->cb(); doEffect())

export guid = ->
	encoder = new TextEncoder()
	input = Date.now().toString() + Math.random().toString()
	buffer = await crypto.subtle.digest('SHA-1', encoder.encode input)
	array = Array.from new Uint8Array buffer
	array.map((c)->c.toString(36)).join ''
