

el 'tag.class', props: static, [memoized] ->
	el 'child'
	el 'child'

component =(render𝑓)->
	_trackStack = []
	_el =(content𝑓)->
		trackThisEl tracks = []
		_trackStack.push tracks

		_delta = []
		_constants = content𝑓.constants
		unless _constants
			_constants = []
			content𝑓()

		if tracks.length is 0
			content𝑓.constancy = _constants

		element = document.createElement tagName
		watch tracks ->
			_delta = []
			content𝑓()
			for delta in _delta
				_constants.mutate delta

		_trackStack.pop()

		watchThisTrack ->


	render𝑓 _el
