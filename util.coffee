import {onUnmounted, createApp} from 'vue'

export mount =(app, selector)->
	createApp app
	.mount selector

export mountListener =(target, event, cb, capture=false)->
    target.addEventListener event, cb, capture
    onUnmounted -> target.removeEventListener event, cb, capture

export mountOn =(target, event, cb)->
    handle = target.on event, cb
    onUnmounted -> target.off handle

export literal = do ->
    Thing = (type)-> (fn)->
        if typeof fn is 'object'
            obj = fn
            fn =->obj
        type: type
        default: fn
    Object: Thing Object
    Array: Thing Array
    String: Thing String

export touch =(type='tap', fn=->)->
    if typeof type is 'function'
        fn = type
        type = 'tap'
    name: 'touch'
    rawName: "touch:#{type}"
    arg: type
    value: fn

export mutate =(obj, fn)->
    fn.call this, obj
    obj

export delay =(delay, fn)->setTimeout fn, delay

export quoted =(s)->"\"#{s}\""

export pluralize =(string, count)->
    "#{string}#{if count is 1 then '' else 's'}"

export randInt =(min, max)->
    Math.floor(Math.random() * (max - min)) + min

export canonical =(object)->
    replacer = (key, value)->
        if typeof value is 'function'
            value.toString()
        else
            value
    JSON.stringify object, replacer, 2

export clamp =(x, min, max)->
    Math.max min, Math.min x, max

export tokenize =(s)->s.trim().replace(/[^A-Za-z0-9]+/g, '-')
