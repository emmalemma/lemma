import {ExtensionError} from './errors'

export Extend = ->
	if Array.prototype.sorted
		throw new ExtensionError 'Sorted is defined!'

	Object.defineProperty Array.prototype, 'sorted',
		writable: false
		enumerable: false
		configurable: false
		value: ->
			@sort()
			this


	_debug = console.debug
	console.debug = ->
		_debug.apply console, arguments
		arguments[0]

	Object.defineProperty Object.prototype, 'asArray',
		configurable: true
		enumerable: false
		get: ->
			if Object.hasOwnProperty this, 'asArray'
				this.asArray
			else new Proxy this,
				get: (target, prop)->
					if typeof Array.prototype[prop] is 'function'
						Array.prototype[prop].bind target
					else target[prop]
