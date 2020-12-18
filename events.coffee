export preventDefault = (fn)->
	(e)->
		e.preventDefault()
		fn e
