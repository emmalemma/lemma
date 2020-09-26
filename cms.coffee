import {reactive, ref, nextTick, watch} from 'vue'

import MarkdownIt from 'markdown-it'
# console.log 'imported markdown:', MarkdownIt
markdown = new MarkdownIt html: true

EditOptions = reactive {}


export cms = ({key, inline}, initial = '[ missing initial text ]')->
	renderer =(x)->
		if inline
			markdown.renderInline x
		else
			markdown.render x
	entry = cms.ref.value.strings[key] ?= {md: initial, html: renderer(initial)}
	editOptions = EditOptions[key] ?= {}
	options =
		innerHTML: entry.html
		'data-cms-key': key
		key: "cms-#{key}"
		class: {'cms-content': true}
	if cms.settings.highlight
		options.href = ''
	if cms.settings.highlight and not editOptions.editable
		options.onClickCapture = (e)->
			console.log 'clicked on highlighted piece'
			e.preventDefault()
			e.stopPropagation()
			editOptions.editable = true
			editOptions.takeFocus = true
	else if cms.settings.highlight
		options.onClickCapture = (e)->
			e.stopPropagation()

	if editOptions.editable
		if editOptions.takeFocus
			options.ref = divᴿ = ref null
			nextTick -> divᴿ.value.focus()
			editOptions.takeFocus = false
		options.contenteditable = true
		options.textContent = entry.md
		delete options.innerHTML
		options.onFocusout = ({target: {textContent: text}})->
			entry.md = text
			entry.html = renderer entry.md
			editOptions.editable = false
		options.onKeydown = (event)->
			return unless event.keyCode is 13
			event.preventDefault()
			document.execCommand 'insertHTML', false, '\r\n'

	options

cms.enable = ({ref})->
	cms.ref = ref
	ref.value ?= {strings: {}}

	watch (->cms.settings.highlight), (highlight)->
		document.body.setAttribute 'data-cms-highlight', highlight

cms.inline = (options, initial)->
	options.inline = true
	cms options, initial


cms.settings = reactive
	highlight: false
