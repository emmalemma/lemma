### @__PUBLISH__ ###
LEMMA = publish: true

import {watch, elements, state, toRaw, enableTouch, markdown} from 'ur'

import {fullPage, fullWidth, flexRow, block, pad, margin, hover, children, specify, select, backgroundBrand, backgroundAttend, backgroundFade, largeText, mainText, lightBlue, color, mainBlue, cursor, fontSize, background, brandColor} from './theme'

import {layout} from './layout'
# import * as __LOCALS__ from './theme'

# index_theme document
{main, section, a, header, div} = elements

layout ->
	section.description backgroundAttend, margin, pad, mainText, select('a')(lightBlue, hover(backgroundFade)), markdown.html """
		Welcome to Little Theorem!

		This is a personal showcase of interactive experiments.

		Everything you'll find on this site is built using [Lemma](/lemma) ([GitHub](/github)), a full-stack library I designed from scratch to push the boundaries of my personal developer experience using pure, modern JavaScript.

		"Modern" browsers are almost everywhere now, so I hope you'll be able to experience everything here the way I've intended it. If you're running an older platform, I beg your forgiveness, and hope you'll return later.
	"""
	section.links flexRow, children(block, pad, hover(backgroundFade, children(largeText))), ->
		a href: '/', ->
			a 'Child'
		div hover(backgroundAttend), 'text'
		a href: '/demo', 'Demo'
		a href: '/playground', 'Playground'
		a href: '/writing', 'Writing'
		a specify(hover(backgroundAttend)), href: '/fun', 'Just for Fun'
