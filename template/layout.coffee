import {elements} from 'lemma'

import {fullPage, fullWidth, flexRow, block, pad, margin, hover, children, specify, select, pads, backgroundBrand, backgroundAttend, backgroundFade, largeText, mainText, lightBlue, color, mainBlue, cursor, fontSize, background, brandColor} from './theme'

{main,header,footer} = elements

export layout =(content𝑓)->
	document.body.appendChild main.site fullPage, ->
		header fullWidth, background[brandColor], fontSize[3.4], color[mainBlue], hover(color.red), cursor.pointer, "Example"
		do content𝑓
		footer fullWidth, background[brandColor], fontSize[1], color.black, "Made for you with Lemma"
