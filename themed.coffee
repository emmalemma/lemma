sheet = do ->
	document.head.appendChild el = document.createElement 'style'
	el.sheet
idx = 0

styleMap = {}
classMap = {}
mutatorMap = {}

_makeRuleClass = (name, style)->
	styleMap[style] ?= (
		className = "#{name}-#{idx += 1}"
		sheet.insertRule ".#{className} {#{style}}"
		classMap[className] = style
		{className}
	)

_ruleMutator = (name, mutate)->
	(inClasses...)->
		handle = inClasses.map((x)->x.className).join ', '
		(mutatorMap[name] ?= {})[handle] ?= (
			className = "#{name}-#{idx += 1}"
			baseRule = ''
			mutated = []
			for {className: subClass, mutate: subMutate, mutated: subMutated} in inClasses
				if subMutate
					sheet.insertRule rule = "#{subMutate mutate '.'+className} {#{classMap[subClass]}}"
					mutated.push {mutate: subMutate, className: subClass}

					for mutate2 in subMutated
						sheet.insertRule "#{mutate2.mutate subMutate mutate '.'+className} {#{classMap[mutate2.className]}}"

					# console.log name, className, subClass, subMutate, rule
				else
					# console.log name, className, subClass
					baseRule += classMap[subClass] + ';'
			classMap[className] = baseRule
			# console.log name, className, base: baseRule
			sheet.insertRule "#{mutate '.'+className} {#{baseRule}}"

			{className, mutate, mutated}
		)


_ruleWrapper = (name, wrap)->
	(inClasses...)->
		handle = inClasses.map((x)->x.className).join ', '
		(mutatorMap[name] ?= {})[handle] ?= (
			className = "#{name}-#{idx += 1}"
			baseRule = ''
			wrapped = []
			for {className: subClass, mutate: subMutate, mutated: subMutated} in inClasses
				if subMutate
					sheet.insertRule rule = wrap "#{subMutate '.'+className} {#{classMap[subClass]}}"
					wrapped.push {mutate: subMutate, className: subClass}

					for mutate2 in subMutated
						sheet.insertRule wrap "#{mutate2.mutate subMutate '.'+className} {#{classMap[mutate2.className]}}"

					# console.log name, className, subClass, subMutate, rule
				else
					# console.log name, className, subClass
					baseRule += classMap[subClass] + ';'
			classMap[className] = baseRule
			# console.log name, className, base: baseRule
			sheet.insertRule wrap "#{'.'+className} {#{baseRule}}"

			{className, wrap, wrapped}
		)

# These are obviously not "pure", i.e. they have global side effects. But we want them to be tree-shaken unless they are used
`export const makeRuleClass = (name, style)=> /* @__PURE__ */ _makeRuleClass(name, style)`
`export const ruleMutator = (name, mutate)=> /* @__PURE__ */ _ruleMutator(name, mutate)`
`export const ruleWrapper = (name, mutate)=> /* @__PURE__ */ _ruleWrapper(name, mutate)`

export makeRule = (rule)->sheet.insertRule rule

export styleKey = (key)->
	(value)->makeRuleClass "#{key}", "#{key}: #{value};"

export styleValue = (value)-> value

export styleProxy = (keys, convertNumber)->
	convert = if convertNumber
		(n)-> if n.match /^[0-9\.]+$/ then convertNumber n else n
	else (n)->n
	unless typeof keys is 'object' and Array.isArray keys
		keys = [keys]
	new Proxy {},
		get: (target, prop)->
			# console.log {prop}
			makeRuleClass "#{keys[0]}-#{prop.replace /[^a-zA-Z0-9]+/g, '-'}", ("#{key}: #{convert prop};" for key in keys).join ' '
