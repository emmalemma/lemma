import {ref, persist, remote, delay, cms} from 'ur'


# target api:
# (el)->
# 	el "#{dynamic}" -> # outer dynamic, whole call will be reeval
#   el (->"#{dynamic}") # inner dynamic, tagname will be updated
#   el (->"static"), (-> class: dynamic), (-> el 'child'), (-> el '', 'text')
#   el "static", ->
#		el 'static', -> dynamic # inner dynamic

export App = ({})->
	counterᴿ = ref 0

	persistentCounterᴿ = persist store: 'global', id: 'clicks', value: 0
	globalCounterᴿ = remote store: 'global', id: 'clicks', value: 0

	(el)->
		el '.actions.cms', ->
			el 'label', ->
				el 'input', type: 'checkbox', checked: cms.settings.highlight, onChange: ({target:{checked}})->
					cms.settings.highlight = checked
				el 'span', 'Edit CMS'

		el 'h1', cms.inline key: 'app.global.header', 'Default *App*'

		el '.clicks',"#{counterᴿ.value} clicks this time"
		el '.clicks', "#{persistentCounterᴿ.value} clicks in this browser"
		el '.clicks', "#{globalCounterᴿ.value} clicks ever"
		el 'button', 'Increment', onClick: ->
			counterᴿ.value += 1
			persistentCounterᴿ.value += 1
			globalCounterᴿ.value += 1
		el 'button', 'Reset', onClick: ->
			counterᴿ.value = 0
			persistentCounterᴿ.value = 0
			globalCounterᴿ.value = 0
		el 'button', 'Race', onClick: ->
			counterᴿ.value += 1
			persistentCounterᴿ.value += 1
			globalCounterᴿ.value += 1

			await delay 100

			counterᴿ.value += 1
			persistentCounterᴿ.value += 1
			globalCounterᴿ.value += 1
