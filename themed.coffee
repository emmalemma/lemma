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
		classNames[key] = localClass
		styles = ""
		mods = {}
		def.call methods =
			class: (name)-> classNames[key] += ".#{name}"
			tag: (name)-> classNames[key] = name + classNames[key]
			css: (text)->
				styles += text
			color: (s)->
			layout: (n)->
			padding:
				text: ->
					methods.css "padding: 1em;"
			background:
				focus: ->
					methods.css "background-color: darkGray;"
			mod: (mod, css)->
				m = mods[mod] ?= {css: ""}
				m.css += css
		decl = "#{localClass} {
			 #{styles}
			}"
		ruleIdx = sheet.insertRule decl
		for mod, {css} of mods
			sheet.insertRule rules = "#{localClass}#{mod} { #{css} }"
			console.log 'mod rules', rules
	classNames
