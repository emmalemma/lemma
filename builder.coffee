# Proxy-based builder syntax
# converts
#  `tag.class.[Symbol(key)].$for(iterArg) args...`
# into
#  `el𝑓 {tagName: 'tag', class: 'class', _key: Symbol(key), _args: [iterArg]}, args...`

ProxyStyles = new WeakMap

export elementBuilder = (el𝑓, {svg} = {svg: false})->
	chainer = (tagName)->
		props = {tagName, svg}
		styles = []
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
				args.unshift styles
				args.unshift props
				props = {tagName, svg}
				el𝑓.apply it, args
		ProxyStyles.set proxy, styles
		proxy

	generator = new Proxy {},
		get: (target, prop)->
			if prop is '$'
				generator
			else chainer(prop)

_extend = (el, exts...)->
	unless styles = ProxyStyles.get(el)
		throw new Error "Tried to extend something that wasn't a lemma element builder"
	# console.log 'equal?', ProxyStyles.get(el) is styles
	styles.push ext for ext in exts
	el

`export const extend = (...args)=> /* @__PURE__ */ _extend.apply(null, args)`
