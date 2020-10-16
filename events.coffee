export  stopEvent =(e)->
	e.stopPropagation()

export swallowEvent =(e)->
	e.stopPropagation()
	e.preventDefault()
