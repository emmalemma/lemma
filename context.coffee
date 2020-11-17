
parentElement = null

elementBuilder = (el)->
	el_chainer = (tagName)->
		props = {tagName}
		proxy = new Proxy (->),
			get: (target, prop)->
				if typeof prop is 'string'
					if prop is '$for'
						return (args...)->
							props._args = args
							proxy
					else
						if props.class
							props.class += " #{prop}"
						else
							props.class = "#{prop}"
				else if typeof prop is 'symbol'
					props._key = prop
				proxy
			apply: (target, it, args)->
				args.unshift props
				props = {tagName}
				el.apply it, args

	el_generator = new Proxy {},
		get: (target, prop)->
			if prop is '$'
				el_generator
			else el_chainer(prop)

rerender = (target)->
	applyBody target, target.bodyFn

checkRenders = (target)->
	if target.needsRerender
		rerender target
	else if target.childNeedsRerender
		checkRenders child for child in target

Context.doRerenders =->
	checkRenders root

schedule𝑓 = (effect)->
	effect.element.needsRerender = true
	for parent of effect
		parent.element.childNeedsRerender = true

	queueMicrotask ->
		Context.doRerenders

effectCatcher = (effectFn)->
	effect effectFn,
		scheduler: schedule𝑓

cursor = null
insertElement = null

applyBody = (element, bodyFn)->
	effectCatcher ->
		_parent = parentElement
		parentElement = element
		cursor = element.firstElementChild
		insertElement = element.firstElementChild
		do bodyFn
		parentElement = _parent

applyProps = (element, props)->
	props = effectCatcher props

makeOrRetrieve = (keyProps)->
	while cursor and not matchKeyProps cursor, keyProps
		cursor = cursor.nextElementSibling

	if cursor


elements =  (keyProps, props, bodyfn)->
	element = makeOrRetrieve keyProps

	if insertElement
		if insertElement is element
			insertElement = element.nextElementSibling
		else
			parentElement.insertBefore element, insertElement
	else
		parentElement.appendChild element

	applyProps element, props
	applyBody element, bodyfn

watchStack = (target, renderFn)->

	effectCatcher ->
		parentElement = target
		renderFn elementBuilder(elements)

export Context = (contextFn)->
	return ({inputs}, target)->
		renderFn = contextFn inputs

		watchStack target, renderFn


subComponent = Context ({x})->
	({li})->
		li x

component = Context ({inputs})->
	x = ref 1
	y = ref 2
	z = ref 3
	# global.addEventListener()
	# teardown -> global.removeEventListener()

	({el, il})->
		el.x x.value
		el.y y.value
		el.k wrap(->klass: 'ab'), ->
		el.z z.value, ->
		el.numbers ->
			el.one '1'
			el.two '2'
		subComponent {x: x.value}

component document.body, {inputs}
