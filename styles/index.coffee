import {makeRuleClass, styleKey, styleValue, styleProxy, ruleMutator, ruleWrapper} from './themed'

export background = styleProxy 'background'
export backgroundColor = styleProxy 'background-color'
export backgroundPosition = styleProxy 'background-position'
export backgroundImage = styleProxy 'background-image'
export backgroundAttend = makeRuleClass 'backgroundAttend', "background-color: rgb(203, 238, 255);"
export backgroundBrand = makeRuleClass 'backgroundBrand', "background-color: lightgray;"
export backgroundFade = makeRuleClass 'backgroundFade',  "background-color: hsl(210, 10%, 67%);"
export backgroundUnused =  makeRuleClass 'UNUSED', "background-color: red);"
export block = makeRuleClass 'block', 'display: block;'
export border = styleProxy 'border'
export bold = makeRuleClass 'bold', 'font-weight: bold'
export borderBottom = styleProxy 'border-bottom'
export borderTop = styleProxy 'border-top'
export brandColor = styleValue 'hsl(212, 93%, 75%)'
export children = ruleMutator 'children', (selector)-> "#{selector} > *"
export clear = styleProxy 'clear'
export color = styleProxy 'color'
export corners = styleProxy 'border-radius', (n)->"#{n}em"
export cursor = styleProxy 'cursor'
export display = styleProxy 'display'
export font = styleProxy 'font-family'
export flexAlign = styleProxy ['align-items', '-webkit-align-items']
export float = styleProxy 'float'
export inlineBlock = makeRuleClass 'inline-block', 'display: inline-block'
export inline = makeRuleClass 'inline', 'display: inline'
export justify = styleProxy 'justify-self'
export justifyItems = styleProxy 'justify-items'
export align = styleProxy 'align-self'
export alignItems = styleProxy 'align-items'
export fontSize = styleProxy 'font-size', (n)->"#{n}em"
export fullPage = makeRuleClass 'fullPage', 'width: 100%;'
export fullWidth = makeRuleClass 'fullWidth', 'width: 100%;'
export gridRow = (inner)-> makeRuleClass 'gridRow', "grid-row: #{inner};"
export hover = ruleMutator 'hover', (selector)-> "#{selector}:hover"
export active = ruleMutator 'hover', (selector)-> "#{selector}:active"
export largeText = makeRuleClass 'largeText', "font-size: 3em;"
export lightBlue = makeRuleClass 'lightBlue', "color: hsl(194, 62%, 73%);"
export mainBlue = styleValue 'hsl(198, 100%, 50%);'
export mainText = makeRuleClass 'mainText', "font-size: 1.3em; font-family: sans-serif;"
export margin = styleProxy 'margin', (n)->"#{n}em"
export marginTop = styleProxy 'margin-top', (n)->"#{n}em"
# export margin = styleProxy 'margin', (n)->"#{n}em"
export maxWidth = styleProxy 'max-width'
export minWidth = styleProxy 'min-width'
export maxHeight = styleProxy 'max-height'
export minHeight = styleProxy 'min-height'
export noTextDecoration = makeRuleClass 'noTextDecoration', "text-decoration: none;"
export opacity = styleProxy 'opacity'
export pad = styleProxy 'padding', (n)->"#{n}em"
export select = (s)-> ruleMutator 'select', (selector)-> "#{selector} #{s}"
export shadow = styleProxy 'box-shadow'
export stretch = makeRuleClass 'stretch', 'justify-self: stretch'
export specify = ruleMutator 'specify', (selector)-> "#{selector}#{selector}"
export anywhere = ruleMutator 'anywhere', (selector)-> ":root #{selector}"
export textCenter = makeRuleClass 'text-center', 'text-align: center;'
export textAlign = styleProxy 'text-align'
export transition = styleProxy 'transition'
export width = styleProxy 'width'
export height = styleProxy 'height'
export position = styleProxy 'position'
export pointerEvents = styleProxy 'pointer-events'
export userSelect = styleProxy 'user-select'
export inset = styleProxy 'inset'
export zIndex = styleProxy 'z-index'

export rewrite = (s)-> ruleMutator 'rewrite', -> s
export smallScreen = ruleWrapper 'smallScreen', (rule)->"@media (max-width: 650px) { #{rule} }"

export flexCol = makeRuleClass 'flexCol', """
	display: flex;
	flex-direction: column;
	"""

export flexRow = makeRuleClass 'flexRow', """
	display: flex;
	flex-direction: row;
	"""

export flex = makeRuleClass 'flex', "display: flex"
export flexWrap = makeRuleClass 'flexWrap', "flex-wrap: wrap"
export flexFlow = styleProxy 'flex-flow'

export grid = (inner)-> makeRuleClass 'grid', """
	display: grid;
	grid: #{inner};
	"""
export gridGap = styleProxy 'grid-gap'
export gridArea = styleProxy 'grid-area'

export size = (x, y)-> makeRuleClass 'size', """
	width: #{x};
	height: #{y};
	"""

export fit = makeRuleClass 'fit', """
	width: 100%;
	height: 100%;
	"""

export filter = styleProxy 'filter'

export combine = ruleMutator 'combine', (s)->s

export fitX = makeRuleClass 'fitX', 'width: 100%'

export colors =
	gray: "hsl(0, 0%, 75%)"
	lightgray: "hsl(0, 0%, 85%)"
	darkgray: "hsl(0, 0%, 55%)"
	darkergray: "hsl(0, 0%, 25%)"
	lightergray: "hsl(0, 0%, 95%)"
	mediumgray: "hsl(0, 0%, 65%)"
