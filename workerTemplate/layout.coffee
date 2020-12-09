import {makeRuleClass, ruleMutator} from 'ur'

export block = makeRuleClass 'block', 'display: block;'

export fullPage = makeRuleClass 'fullPage', 'width: 100%;'

export fullWidth = makeRuleClass 'fullWidth', 'width: 100%;'

export flexCol = makeRuleClass 'flexCol', """
	display: flex;
	flex-direction: column;
	"""

export flexRow = makeRuleClass 'flexRow', """
	display: flex;
	flex-direction: row;
	"""

export grid = (inner)-> makeRuleClass 'grid', """
	display: grid;
	grid: #{inner};
	"""

export size = (x, y)-> makeRuleClass 'size', """
	width: #{x};
	height: #{y};
	"""

export gridRow = (inner)-> makeRuleClass 'gridRow', "grid-row: #{inner};"
export gridArea = (inner)-> makeRuleClass 'gridArea', "grid-area: #{inner};"

export pad = makeRuleClass 'pad', "padding: 0.5em;"
export margin = makeRuleClass 'margin', "margin: 1em;"

export hover = ruleMutator 'hover', (selector)-> "#{selector}:hover"
export children = ruleMutator 'children', (selector)-> "#{selector} > *"
export specify = ruleMutator 'specify', (selector)-> "#{selector}#{selector}"
export select = (s)-> ruleMutator 'select', (selector)-> "#{selector} #{s}"

export pads = [1,2,3,4]
