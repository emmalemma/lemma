# Proxy-based builder syntax
# converts
#  `tag.class.[Symbol(key)].$for(iterArg) args...`
# into
#  `el𝑓 {tagName: 'tag', class: 'class', _key: Symbol(key), _args: [iterArg]}, args...`

export elementBuilder = (el𝑓)->
	chainer = (tagName)->
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
				el𝑓.apply it, args

	generator = new Proxy {},
		get: (target, prop)->
			if prop is '$'
				generator
			else chainer(prop)
