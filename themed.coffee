export themed =(themeId, definitions)->
	classNames = {}
	sheetEl = document.querySelector("style\#id-#{themeId}")
	if sheetEl
		document.removeChild sheetEl

	sheetEl = document.createElement 'style'
	document.head.appendChild sheetEl
	sheetEl.type = 'text/css'
	sheet = sheetEl.sheet
	console.log 'created', sheet

	n = 0
	for key, def of definitions
		n += 1
		localClass = ".#{key}-#{n}"
		builder = new StyleBuilder localClass
		def.call builder
		classNames[key] = builder.rootName
		for selector, style of builder.getRules()
			sheet.insertRule "#{selector} { #{style} }"
	classNames

class StyleBuilder
	constructor: (@rootName)->
		@rules = {}
		@root = ""

	getRules: ->
		rules = {}
		rules[@rootName] = @root
		for selector, rule of @rules
			rules[@rootname + selector] = rule
		rules

	class: (name)-> @rootName += ".#{name}"
	tag: (name)-> @rootName = name + @rootName
	css: (text)->@root += text
	mod: (mod, css)->
		@rules[mod] = css

export DynamicTheme =->

	new Proxy {},
		get: (target, classKey)->
			selector = ".#{classKey.replace /_/g, '-'}"
