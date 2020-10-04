import {reactive, ref, effect} from '@vue/reactivity'

import {elements} from './elements'

import snarkdown from 'snarkdown'

EditOptions = reactive {}


renderer = (md) =>
	parts = md.split(/(?:\r?\n){2,}/)
	return snarkdown(parts[0]) if parts.length is 1
	parts.map (l)->
		if [' ', '\t', '#', '-', '*'].some((ch)-> l.startsWith(ch))
			snarkdown(l)
		else "<p>#{snarkdown(l)}</p>"
	.join('\n\n')

export $cms = ({key, inline}, initial, options)->
	->
		if typeof initial is 'object'
			options = initial
			initial = null
		initial ?= "&lsqb; cms: #{key} &rsqb;"
		options ?= {}
		entry = $cms.ref.value.strings[key] ?= {md: initial, html: renderer(initial)}
		editOptions = EditOptions[key] ?= {}
		template =(html)->
			for k, v of options.template or {}
				html = html.replace ///\#\{\s*#{k}\s*\}///g, v.toString()
			html
		options[k] = v for k, v of _=
			innerHTML: template entry.html
			'data-cms-key': key
			key: "cms-#{key}"
		if $cms.settings.highlight
			options.href = ''
			delete options.onClick
			unless editOptions.editable
				options.onClickCapture = (e)->
					e.preventDefault()
					e.stopPropagation()
					editOptions.editable = true
					editOptions.takeFocus = true
			else
				options.onClickCapture = (e)->
					e.stopPropagation()

		if editOptions.editable
			if editOptions.takeFocus
				options.ref = divᴿ = ref null
				nextTick -> divᴿ.value.focus()
				editOptions.takeFocus = false
			options.contenteditable = true

			options.textContent = if options.template
				"<!-- TEMPLATE VARIABLES AVAILABLE: #{JSON.stringify options.template} -->\n\n" + entry.md
			else entry.md
			delete options.innerHTML
			options.onFocusout = ({target: {textContent: text}})->
				entry.md = if options.template
					text.replace /^<!-- TEMPLATE VARIABLES AVAILABLE: .+? -->\n\n/, ''
				else text
				entry.html = renderer entry.md
				editOptions.editable = false
			options.onKeydown = (event)->
				return unless event.keyCode is 13
				event.preventDefault()
				document.execCommand 'insertHTML', false, '\r\n'

		options

$cms.enable = ({ref})->
	$cms.ref = ref
	ref.value ?= {strings: {}}

	effect ->
		document.body.setAttribute 'data-cms-highlight', $cms.settings.highlight

$cms.inline = (options, initial)->
	options.inline = true
	$cms options, initial


$cms.settings = reactive
	highlight: false

cms_chainer =->
	path = []
	proxy = new Proxy (->),
		get: (target, prop)->
			path.push prop
			proxy
		apply: (target, it, args)->
			args.unshift key: path.join('.')
			$cms.apply $cms, args

export cms = new Proxy (->),
	get: (target, prop)->
		cms_chainer()[prop]
	apply: -> $cms
