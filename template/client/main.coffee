import {local, remote, persist, themes, cms, component, ref, reactive, symbolize, toRaw, guid, markdown, elementTree, elements, attach, context} from 'ur'

# import {App} from './app'
# import {Music} from './music'

local.connect 'persistence', 1, ['global']
remote.connect '/api/v1'

# EMBEDDED
themes.enable ref: remote store: 'themes', id: 'global'
cms().enable ref: remote store: 'cms', id: 'global'

# Root = registration (register, state)->
# 	register App, ->
# 		register Music
# 		state {}


do ->
	attach document.body, ->
		{div, button} = elements

		nᴿ = ref 0
		div.root ->
			button 'increment', onclick: ->
				nᴿ.value += 1
				console.log 'nᴿ', nᴿ.value
			div.n -> "value is #{nᴿ.value}"
			for i in [0..nᴿ.value]
				console.log 'would nx', i
				div.nx -> "#{i}"

if false then do ->
	document.body.innerHTML = "Loading..."
	await persist.promise themes.ref
	await persist.promise cms().ref
	document.body.innerHTML = ''

	cms().display()
	# mount Root, 'body'

	allPages = remote.collection store: 'pages'

	newPage = ref ''

	randomPage = ref null

	chooseRandom𝑓 =->
		values = Object.values allPages
		randomPage.value = values[Math.floor Math.random() * values.length]
	persist.promise(allPages).then chooseRandom𝑓

	rootComponent = component ({el, label, il, input, button, textarea})->
		el.papercut ->
			el.header cms.papercut.header()
			el.pages ->
				el.page.random -> innerHTML: markdown randomPage.value?.text or ''
				button 'Randomize', onclick: chooseRandom𝑓
				el.page.next ->
					il cms.papercut.nextPage()

			el.newPage ->
				textarea oninput: (({target: {value}})->newPage.value = value), ->value: newPage.value
				button 'Save Page', onclick: ->
					page =
						text: newPage.value
					newPage.value = ''
					allPages[await guid()] = page

	root = document.createElement 'root'
	document.body.appendChild root
	rootComponent.attach root
