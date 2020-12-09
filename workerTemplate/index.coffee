import {watch, elements, state, toRaw, enableTouch, markdown} from 'ur'
{main, section, a, header, div} = elements

import {fullPage, fullWidth, flexRow, block, pad, margin, hover, children, specify, select, pads} from './layout'
import {backgroundBrand, backgroundAttend, backgroundFade, largeText, mainText, lightBlue, color, mainBlue, cursor, fontSize, background, brandColor} from './theme'

# import * as __LOCALS__ from './theme'

# index_theme document
document.body.appendChild main.site fullPage, ->
	header fullWidth, background[brandColor], fontSize[3.4], color[mainBlue], hover(color.red), cursor.pointer, "Little Theorem"
	section.description backgroundAttend, margin, pad, mainText, select('a')(lightBlue, hover(backgroundFade)), markdown.html """

	"""
	section pads[2].toString()
	section.links flexRow, children(block, pad, hover(backgroundFade, children(largeText))), ->
		a href: '/', ->
			a 'Child'
		div hover(backgroundAttend), 'text'
		a href: '/demo', 'Demo'
		a href: '/playground', 'Playground'
		a href: '/writing', 'Writing'
		a specify(hover(backgroundAttend)), href: '/fun', 'Just for Fun'
