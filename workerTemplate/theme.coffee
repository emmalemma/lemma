import {makeRuleClass, styleKey, styleValue, styleProxy} from 'ur'

export backgroundBrand = makeRuleClass 'backgroundBrand', "background-color: lightgray;"


export backgroundAttend = makeRuleClass 'backgroundAttend', "background-color: rgb(203, 238, 255);"

export backgroundUnused =  makeRuleClass 'UNUSED', "background-color: red);"

export backgroundFade = makeRuleClass 'backgroundFade',  "background-color: hsl(210, 10%, 67%);"

export largeText = makeRuleClass 'largeText', "font-size: 3em;"

export mainText = makeRuleClass 'mainText', "font-size: 1.3em; font-family: sans-serif;"

export lightBlue = makeRuleClass 'lightBlue', "color: hsl(194, 62%, 73%);"

export color = styleProxy 'color'
export mainBlue = styleValue 'hsl(198, 100%, 50%);'

export cursor = styleProxy 'cursor'

export fontSize = styleProxy 'font-size', (n)->"#{n}em"

export background = styleProxy 'background'
export brandColor = styleValue 'hsl(212, 93%, 75%)'
