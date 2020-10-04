import {onUnmounted, createApp} from 'vue'

export mount =(app, selector)->
	app = createApp app
	app.mount selector
	app.config.errorHandler = (error)->
		console.error 'Internal:', error
		throw error unless process.env.NODE_ENV is 'production'
	app

export mountOn =(target, event, cb)->
	handle = target.on event, cb
	onUnmounted -> target.off handle

export merge =(a, bs...)->
	for b in bs
		for k, v of b
			a[k] = v
	a


export mergeClass =(a, bs...)->
	for b in bs
		for k, v of b
			if k is 'class'
				a.class ?= {}
				a.class[k] = b.class[k] for k of b.class
			else
				a[k] = v
	a



export premerge =(a, bs...)->
	for b in bs
		for k, v of b
			a[k] = v if a[k] is undefined
	a

export literal = do ->
	Thing = (type)-> (fn)->
		if typeof fn is 'object'
			obj = fn
			fn =->obj
		type: type
		default: fn
	Object: Thing Object
	Array: Thing Array
	String: Thing String

export touch =(type='tap', fn=->)->
	if typeof type is 'function'
		fn = type
		type = 'tap'
	name: 'touch'
	rawName: "touch:#{type}"
	arg: type
	value: fn

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
