import {watch, elements, state, toRaw, enableTouch, markdown} from 'ur'
{main, section, a, header, div} = elements

import {fullPage, fullWidth, flexRow, block, pad, margin, hover, children, specify, select} from './layout'
import {backgroundBrand, backgroundAttend, backgroundFade, largeText, mainText, lightBlue} from './theme'

# index_theme document
document.body.appendChild main.site fullPage, ->
	header fullWidth, backgroundBrand, largeText, "Little Theorem"
	section.description backgroundAttend, margin, pad, mainText, select('a')(lightBlue, hover(backgroundFade)), markdown.html """

	"""
	section.links flexRow, children(block, pad, hover(backgroundFade, children(largeText))), ->
		a href: '/', ->
			a 'Child'
		div hover(backgroundAttend) 'text'
		a href: '/demo', 'Demo'
		a href: '/playground', 'Playground'
		a href: '/writing', 'Writing'
		a specify(hover(backgroundAttend)), href: '/fun', 'Just for Fun'
