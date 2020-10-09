import {local, remote, persist, themes, cms, component, ref, reactive, symbolize, toRaw, elements, mount, markdown} from 'ur'

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
	document.body.innerHTML = "Loading..."
	await persist.promise themes.ref
	await persist.promise cms().ref
	document.body.innerHTML = ''
	cms().display()
	# mount Root, 'body'

	pages = remote store: 'global', id: 'pages', value: {pages: []}

	allPages = remote.cursor store: 'pages'

	newPage = ref ''

	randomPage = ref null

	chooseRandom𝑓 =->
		randomPage.value = pages.value.pages[Math.floor Math.random() * pages.value.pages.length]
	persist.promise(pages).then chooseRandom𝑓

	persist.promise(allPages).then ->
		await persist.promise(pages)
		if allPages.length is 0
			for page in pages.value.pages
				allPages.push page
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
					console.log 'saving the page', page
					pages.value.pages.push page
					console.log pages.value

			el.allPages ->
				JSON.stringify allPages

	root = document.createElement 'root'
	document.body.appendChild root
	rootComponent.attach root
