import {effect, stop} from '@vue/reactivity'
import {watch} from './util'

export DynamicTheme =->

	new Proxy {},
		get: (target, classKey)->
			selector = ".#{classKey.replace /_/g, '-'}"

export themes = ->

styleElement = null
createStyleElement =->
	el = document.createElement 'style'
	el.id = 'style-theme'
	el.textContent = '/* initialized */'
	document.head.appendChild el
	el

watchDocumentStyles =(cb)->
	storedText = null
	doWatch =->
		sheets = document.styleSheets
		ruleTexts = []
		for sheet in sheets
			ruleTexts.push rule.cssText for rule in sheet.cssRules
		ruleTexts.sort()
		canonicalRuleString = ruleTexts.join '\n'
		if storedText and storedText isnt canonicalRuleString
			cb canonicalRuleString
		storedText = canonicalRuleString
	setInterval doWatch, 250

themes.enable =({ref})->
	themes.ref = ref
	ref.value ?= {}
	styleElement ?= createStyleElement()

	watchEffect = watch (->themes.ref.value), ->
		styleElement.textContent = themes.ref.value?.storedText or '/* empty */'
		stop watchEffect

	watchDocumentStyles (ruleString)->
		ref.value.storedText = ruleString
