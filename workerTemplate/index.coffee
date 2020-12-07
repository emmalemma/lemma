import {watch, elements, state, toRaw} from 'ur'

{main, section, a, header} = elements
document.body.append main.site ->
	header "Little Theorem"
	section.links ->
		a href: '/demo', 'Demo'
		a href: '/playground', 'Playground'
