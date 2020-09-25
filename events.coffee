import {onUnmounted} from 'vue'

export  stopEvent =(e)->
	e.stopPropagation()

export swallowEvent =(e)->
	e.stopPropagation()
	e.preventDefault()

export mountListener =(target, event, cb, capture=false)->
	target.addEventListener event, cb, capture
	onUnmounted -> target.removeEventListener event, cb, capture
