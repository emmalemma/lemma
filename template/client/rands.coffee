import {ref, local, remote, delay, cms, reactive, persist, toRaw} from 'ur'

export App = ({})->
	seedᴿ = ref null
	bitsᴿ = ref ''
	pointsᴿ = ref []
	generate𝑓 =()->
		enc = new TextEncoder
		console.log 'encoded', encoded = enc.encode(seedᴿ.value.value)
		seed = await crypto.subtle.importKey "raw",
			encoded,
			{name: "PBKDF2"},
			false,
			["deriveBits", "deriveKey"]
		console.log 'created key', seed
		buffer = await crypto.subtle.deriveBits
				name: 'PBKDF2'
				iterations: 1
				hash: "SHA-1"
				salt: enc.encode 'World'
			, seed, 1024
		bitsᴿ.value = (c.toString(16) for c in new Uint8Array buffer)
		pointsᴿ.value = []
		floats = new Float32Array buffer
		for i in [0..floats.length/2]
			pointsᴿ.value.push {x: floats[i], y: floats[i+1]}


	(el$, child, {el, il, input, label, h1, button, svg, textarea})->
		el.actions.cms ->
			label ->
				input type: 'checkbox', checked: cms().settings.highlight, onChange: ({target:{checked}})->
					cms().settings.highlight = checked
				il 'Edit CMS'

		h1 cms.app.global.header()

		button cms.generator.button onClick: generate𝑓
		input ref: seedᴿ, placeholder: 'Seed', value:'example seed phrase'
		textarea JSON.stringify pointsᴿ.value
		svg ->
