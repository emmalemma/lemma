import {reactive, ref, effect} from '@vue/reactivity'

import {markdown} from './markdown'

EditOptions = reactive {}

export $cms = ({key, inline}, initial)->
	->
		initial ?= "&lsqb; cms: #{key} &rsqb;"
		options = {}
		entry = $cms.ref.value.strings[key] ?= {md: initial, html: markdown(initial)}
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
			console.log 'cms settings'
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

		if $cms.settings.highlight and editOptions.editable
			if editOptions.takeFocus
				# options.ref = divᴿ = ref null
				# nextTick -> divᴿ.value.focus()
				editOptions.takeFocus = false
			options.contentEditable = true

			options.textContent = if options.template
				"<!-- TEMPLATE VARIABLES AVAILABLE: #{JSON.stringify options.template} -->\n\n" + entry.md
			else entry.md
			delete options.innerHTML
			options.onFocusout = ({target: {textContent: text}})->
				entry.md = if options.template
					text.replace /^<!-- TEMPLATE VARIABLES AVAILABLE: .+? -->\n\n/, ''
				else text
				entry.html = markdown entry.md
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

$cms.display =->
	controller = component ({el, input, label, il})->
		el.cmsCenter ->
			el.actions.cms ->
				label ->
					input type: 'checkbox', checked: cms().settings.highlight, onChange: ({target:{checked}})->
						cms().settings.highlight = checked
					il 'Edit CMS'

	root = document.createElement 'root'
	document.body.appendChild root
	controller.attach root

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
