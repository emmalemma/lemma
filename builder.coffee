# Proxy-based builder syntax
# converts
#  `tag.class.[Symbol(key)].$for(iterArg) args...`
# into
#  `el𝑓 {tagName: 'tag', class: 'class', _key: Symbol(key), _args: [iterArg]}, args...`

ProxyStyles = new WeakMap

export elementBuilder = (el𝑓)->
	chainer = (tagName)->
		props = {tagName}
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
				args.unshift style for style in styles
				args.unshift props
				props = {tagName}
				el𝑓.apply it, args
		ProxyStyles.set proxy, styles
		proxy

	generator = new Proxy {},
		get: (target, prop)->
			if prop is '$'
				generator
			else chainer(prop)

export style = (el, styles...)->
	ProxyStyles(el).push style for style in styles
