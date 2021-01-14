import {elements, extend} from '@lemmata/client'

import {filter, background, backgroundAttend, backgroundBrand, backgroundColor, backgroundFade, backgroundImage, backgroundPosition, block, bold, border, borderBottom, brandColor, children, color, colors, corners, cursor, flexAlign, flexRow, font, fontSize, fullPage, fullWidth, hover, inlineBlock, justify, largeText, lightBlue, mainBlue, mainText, margin, minHeight, noTextDecoration, opacity, pad, select, shadow, specify, textCenter, transition, size, smallScreen, textAlign, float, clear, maxWidth, rewrite, active, anywhere, fitX, pointerEvents, userSelect} from './index'

export button = extend elements.button, border.none, pad['0.5em 1em'], bold, background.gray, cursor.pointer, color.white, corners[1], margin['0 0.5em 0 0'], shadow['0 3px 5px lightgray'], hover(background.lightgray, color.black), anywhere(active(background.darkgray, color.white))

export smallButton = extend elements.button, color.white, bold, border.none, pad['0 0.5em'], margin['0 0 0 1em'], corners[0.5], background.darkgray

export label = extend elements.label, block, bold, color[colors.mediumgray]

export input = extend elements.input, border.none, pad['0.5em 1em'], fitX, corners[0.5], background[colors.lightgray], shadow['inset white -3px -3px 10px']

export textarea = extend elements.textarea, border.none, pad['0.5em 1em'], fitX, corners[0.5], background[colors.lightgray], shadow['inset white -3px -3px 10px']

export card = extend elements.div, border["3px solid transparent"], pad[1], corners[0.5], background.white, shadow['#e1e1e1 2px 7px 15px 0px, inset #EEE 0 0 0 1px']

export blurout = extend elements.div, filter['blur(3px)'], pointerEvents.none, userSelect.none

export styleBody =->
	rewrite('body') margin[0], font['sans-serif'], backgroundColor.white, backgroundImage["""url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='10'%3E %3Cg%3E%3Cellipse id='svg_1' stroke-width='1.5' fill='%23fff' cy='5' cx='5' stroke='%23FAFAFA' ry='1' rx='1'/%3E%3C/g%3E%3C/svg%3E");"""], backgroundPosition.center
