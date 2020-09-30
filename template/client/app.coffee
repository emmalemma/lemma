import {ref, local, remote, delay, cms, reactive, persist, toRaw, watch, onMounted, component} from 'ur'

export App = ({})->
	allThemes = persist.all store: 'themes', owner: 'remote'
	activeThemeᴿ = ref null

	watch (->allThemes), (->
		console.log 'all themes:', allThemes
		activeThemeᴿ.value = allThemes[0]
		), deep: true

	testᴿ = ref null
	testValueᴿ = ref 3
	multᴿ = ref 1
	# onMounted ->
		# testᴿ.value.appendChild component

	comp = ({el, il, button})->
			el.parent ->
				il 'this is a test of live components'
				console.log 'rendering parent contents'
				button.test 'Click', onClick: -> testValueᴿ.value *= 2
				button.mult 'Click', onClick: -> multᴿ.value += 1
				il "parent: #{JSON.stringify testValueᴿ.value}"
				el.indicator ->
					console.log 'rendering indicator contents'
					il "indicator: #{JSON.stringify testValueᴿ.value}"
				if testValueᴿ.value % 2
					el.isEven 'test value is odd'

				for idx in [0..testValueᴿ.value] then do (idx)->
					el.test key: idx, ->
						il "test #{idx * multᴿ.value}"
				el.child 'this is a child'
				el.sibling 'this is a sibling'


	onMounted ->
		testᴿ.value.appendChild component comp

	(el$, child, {$, el, il, input, label, h1, button, svg, textarea})->
		# comp {el, il, button}
		el.actions.cms ->
			label ->
				input type: 'checkbox', checked: cms().settings.highlight, onChange: ({target:{checked}})->
					cms().settings.highlight = checked
				il 'Edit CMS'
			label ->
				for themeᴿ in allThemes
					$.select ->
						$.option persist.record(themeᴿ).id, selected: themeᴿ is activeThemeᴿ.value
					el.theme ->
						il JSON.stringify themeᴿ.value
				il 'Themes'
			if activeThemeᴿ.value
				el 'Active Theme'
				el JSON.stringify activeThemeᴿ.value.value

		h1 cms.app.global.header()

		el.indicator "#{JSON.stringify testValueᴿ.value}"
		$.testarea ref: testᴿ

		#el$ child.Music
