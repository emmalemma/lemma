import {ref, local, remote, delay, cms, reactive, persist, toRaw} from 'ur'


# target api:
# (el)->
# 	el$ "#{dynamic}" -> # outer dynamic, whole call will be reeval
#   el$ (->"#{dynamic}") # inner dynamic, tagname will be updated
#   el (->"static"), (-> class: dynamic), (-> el 'child'), (-> el '', 'text')
#   el "static", ->
#		el 'static', -> dynamic # inner dynamic

bigNumbers = {
6: "Million",
9: "Billion",
12: "Trillion",
15: "Quadrillion",
18: "Quintillion",
21: "Sextillion",
24: "Septillion",
27: "Octillion",
30: "Nonillion",
33: "Decillion",
36: "Undecillion",
39: "Duodecillion",
42: "Tredecillion",
45: "Quattuordecillion",
48: "Quindecillion",
51: "Sexdecillion",
54: "Septendecillion",
57: "Octodecillion",
60: "Novemdecillion",
63: "Vigintillion",
66: "Unvigintillion",
69: "Duovigintillion",
72: "Trevigintillion",
75: "Quattuorvigintillion",
78: "Quinvigintillion",
81: "Sexvigintillion",
84: "Septenvigintillion",
87: "Octovigintillion",
90: "Novemvigintillion",
93: "Trigintillion",
96: "Untrigintillion",
99: "Duotrigintillion"
}

export App = ({})->
	counterᴿ = ref 0

	localCounterᴿ = local store: 'global', id: 'clicks', value: 0
	remoteCounterᴿ = remote store: 'global', id: 'clicks', value: 0


	makeClicker𝑓 =->
		if remoteCounterᴿ.value > 10
			remoteCounterᴿ.value -= 10
		setInterval increment𝑓, 1000

	availableStuff = reactive
		clicks:
			name: 'Clicks'
			cost:
				clicks: 0n
		clicker:
			name: 'Clicker'
			makes: 'clicks'
			cost:
				clicks: 10n
		clickerMaker:
			name: 'Clicker Maker'
			makes: 'clicker'
			cost:
				clicks: 100n
		clickerMakerMaker:
			name: 'Clicker Maker Maker'
			makes: 'clickerMaker'
			cost:
				clicks: 10000n
		clickerMakerMakerMaker:
			name: 'Clicker Maker Maker Maker'
			makes: 'clickerMakerMaker'
			cost:
				clicks: 10000000000n

	persistedStuffᴿ = remote store: 'global', id: 'ownedStuff', value: {}
	ownedStuffᴿ = ref {}
	persist.promise(persistedStuffᴿ).then (stuff)->
		for k, v of stuff.value
			console.log 'setting', k, v
			ownedStuffᴿ.value[k] = {initial: BigInt v.initial}

	increment𝑓 =->
		stuff = ownedStuffᴿ.value.clicks ?= {initial: 0}
		stuff.initial += 1

	bigMin =(a,b)->
		if a < b then a else b


	bigFormat =(n)->
		if n < 1000000n
			return n.toString()
		x = 1000000n
		for exp, name of bigNumbers
			y = x * 1000n
			if n < y
				return "#{Number(n * 100n / x)/100} #{name}"
			x = y
		x /= 1000n
		return "#{n / x} #{name}"

	testFormat =(n)->
		console.log "#{n} is #{bigFormat(n)}"

	testFormat 5000000n
	testFormat 5500000n
	testFormat 100000000n
	testFormat 1000000000n
	testFormat 1000000000000n
	testFormat 100000000000000n
	testFormat 1000000000000000n

	max = (available)->
		_max = Infinity

		for k, cost of available.cost
			if cost is 0n
				return 0n
			_max = bigMin _max, ((ownedStuffᴿ.value?[k]?.initial or 0n) / cost)

		_max


	purchase𝑓 = (k, v, n = 1n)->
		stuffRecord = ownedStuffᴿ.value[k] = if typeof ownedStuffᴿ.value[k] is 'object' then ownedStuffᴿ.value[k] else {initial: 0n}
		available = availableStuff[k]
		for k, cost of available.cost
			unless ownedStuffᴿ.value[k]?.initial >= cost * n
				return

		for k, cost of available.cost
			ownedStuffᴿ.value[k].initial -= cost * n

		stuffRecord.initial += n

	purchaseMax𝑓 = (k,v)->
		purchase𝑓 k,v,max v

	updateCounts𝑓 =->
		tree = null
		stuffLinks = {}
		for k, owned of ownedStuffᴿ.value
			stuff = availableStuff[k]
			link = stuffLinks[k] ?= {}
			link.key = k
			link.owned = stuff

			madeStuff = stuffLinks[stuff.makes] ?= {}

			link.child = madeStuff
			madeStuff.parent = link

			tree ?= link
			if tree is link.child
				tree = link

		while tree?.child?.key
			ownedStuffᴿ.value[tree.child.key].initial += ownedStuffᴿ.value[tree.key].initial
			tree = tree.child

	setInterval updateCounts𝑓, 100

	(el$, child, {el, il, input, label, h1, button})->
		el.actions.cms ->
			label ->
				input type: 'checkbox', checked: cms().settings.highlight, onChange: ({target:{checked}})->
					cms().settings.highlight = checked
				il 'Edit CMS'

		h1 cms.app.global.header 'Default *App*', template: n: remoteCounterᴿ.value

		el.clicker ->
			button cms.clicker.clickButton 'CLICK', onClick: increment𝑓
			el cms.clicker.instructions()

		el.clicks "#{counterᴿ.value} clicks this time"
		el.clicks "#{localCounterᴿ.value} clicks in this browser"
		el.clicks "#{remoteCounterᴿ.value} clicks ever"

		el.owned ->
			for k, v of ownedStuffᴿ.value
				continue unless typeof v is 'object'
				el.stuff ->
					il.stuffName availableStuff[k].name
					il.stuffCount bigFormat v.initial

		el.purchase ->
			for k, v of availableStuff then do (k, v)->
				el.stuff ->
					il.stuffName v.name
					il.stuffPrice "#{tag}: #{price}" for tag, price of v.cost
					button 'Purchase', onClick: ->purchase𝑓 k, v
					button "Purchase #{bigFormat max(v)}", onClick: ->purchaseMax𝑓 k, v
