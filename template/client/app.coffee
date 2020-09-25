import {ref, persist, remote, delay} from 'ur'

export App = ({})->
	counterᴿ = ref 0

	persistentCounterᴿ = persist store: 'global', id: 'clicks', value: 0
	globalCounterᴿ = remote store: 'global', id: 'clicks', value: 0

	(el)->
		el 'h1', 'Default App'

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
