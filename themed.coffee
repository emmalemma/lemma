import {h, onUnmounted, createApp} from 'vue'

import * as Vue from 'vue'

export * from 'vue'

export * from './remoting'
export * from './database'
export * from './registration'
export * from './elements'
export * from './themed'

export {Vue}

export mount =(app, selector)->
	createApp app
	.mount selector


formatPath =(el_path, max_length = 5)->
    if el_path.length > max_length
        el_path = [el_path[0], "...#{el_path.length - max_length} hidden...", ...el_path[-max_length+1..]]
    el_path.map((p)=>"el(#{p})").join ' -> '

class NamedError extends Error
    nameOf: ({constructor: {name}})-> name
    constructor: ->
        super arguments...
        @name = @nameOf this

class ElementalError extends NamedError

export elements = (_el_render, child)->
    _el_path = null
    _el_stack = null
    _el_context = null
    createElement = null
    _el_return_sentinel = {}

    processError =(e)->
        _el_path = _el_path.map (key)->"el('#{key}') ->"
        _el_path.unshift 'elements (el)->'
        console.error _el_path
        console.error e.stack
        if e.stack
            e.stack = e.stack.replace /.*_default[^\w]+render.+@/g, ->
                name = _el_path.pop()
                "#{name}@"
            .replace /_el_([\w]+)/g, "_____^($1)"

    _el_outer = (key, props={}, content=->)->
        if key is undefined
            _el_path.push key
            throw new ElementalError "#{formatPath(_el_path)} is undefined input! Did you forget to register a child?"

        if content is _el_return_sentinel or props is _el_return_sentinel
            throw new ElementalError "#{formatPath(_el_path)} received _el_return_sentinel as argument. el returns should never be passed anywhere-- did you forget a `->`?"

        text = null
        if typeof props == 'function'
            content = props
            props = {}
        if typeof props == 'string'
            _content = props
            if typeof content is 'object'
                props = content
            else
                props = {}
            content = _content
        if typeof content == 'string'
            text = content
            content = ->

        if typeof key is 'string'
            _el_path.push key
        _el_stack.push _el_context = []

        try
            content.call this
        catch e
            processError e
            throw e

        local_context = _el_stack.pop()
        _el_context = _el_stack[_el_stack.length - 1]
        if typeof key is 'string'
            _el_path.pop()
        if text
            local_context.push text

        if typeof key is 'string'
            props ?= {}
            match = key.match /^([\w\-]+)?(#[\w\-]+)?((?:\.[\w\-]+)*)$/
            if not match
                throw new ElementalError "el('#{key}') can't be parsed into element attributes."
            tagName = match[1] or 'div'
            if match[2]?
                props.id = match[2].replace /#/g, ''
            for cn in match[3].split('.')
                continue unless cn
                props.class ?= {}
                props.class[cn] = true

            _el_context.push createElement tagName, props, local_context

        else if (typeof key is 'object' and (typeof key.render is 'function' or typeof key.setup is 'function')) or (typeof key is 'function' and key.name is 'VueComponent')
            _el_context.push createElement key, props

        _el_return_sentinel


    _el_wrapper = ->
        el = _el_outer.bind this
        createElement = h
        _el_stack = []
        _el_path = []
        _el_stack.push _el_context = []


        try
            _el_render.call(this, el, child)
        catch e
            processError e
            throw e

        result = if _el_context.length > 1
            createElement 'div', {class: 'root'}, _el_context
        else
            _el_context[0]

        _el_stack = null
        _el_context = null
        createElement = null
        result

    if module?.hot
        _el_wrapper._inner_render = _el_render
    _el_wrapper


export mountListener =(target, event, cb, capture=false)->
    target.addEventListener event, cb, capture
    onUnmounted -> target.removeEventListener event, cb, capture

export mountOn =(target, event, cb)->
    handle = target.on event, cb
    onUnmounted -> target.off handle


class CanaryUnused extends NamedError
class CanaryMissing extends NamedError
canaryProxy = (stuff, name)->
    flags = {}
    flags[k] = no for k of stuff
    new Proxy stuff,
        apply: ->
            for k, v of flags
                unless v
                    throw new CanaryUnused "#{name} setup never destructured #{k}"
            return true
        get: (target, prop)->
            if prop is canaryProxy.assert
                return CanaryAssert = ->
                    for k, v of flags
                        unless v
                            throw new CanaryUnused "#{name} setup never destructured #{k}"
                    return true

            unless prop of flags
                throw new CanaryMissing "#{prop.toString()} undefined in #{name} registration"
            flags[prop] = yes
            target[prop]
canaryProxy.assert = Symbol('CanaryAssert')

class Prohibited extends NamedError
prohibitThis = (name)-> new Proxy {},
    get: (_, prop)->
        throw new Prohibited "access to `this.#{prop}` in #{name}"

class RegistrationError extends NamedError

export registration = (regFn)->
    Registry = {}
    _currentStuff = {}
    _parent = null
    state = (stuff)-> _currentStuff = stuff
    register = (innerSetup, stuffOrChildren)->
        unless innerSetup
            throw new RegistrationError "innerSetup (under #{_parent?.name or 'root'}) is undefined"

        if typeof innerSetup isnt 'function'
            console.error componentFn
            throw new RegistrationError "I don't think #{innerSetup.name}:#{innerSetup.toString()} is a proper elemental!"

        name = unless innerSetup.name in ['', '_default']
            innerSetup.name
        else throw new RegistrationError "Trying to register an unnamed setup function! #{innerSetup}"


        componentObject = name: name, setup: ->
            stuff = if typeof stuffOrChildren is 'object'
                stuffOrChildren
            else if typeof stuffOrChildren is 'function'
                _currentStuff = null
                _gp = _parent
                _parent = componentObject
                stuffOrChildren()
                _parent = _gp
                _gp = null
                _currentStuff

            stuff ?= {}

            stuffCanary = canaryProxy stuff, name

            renderFn = innerSetup.call prohibitThis("#{name} setup"), stuffCanary

            do stuffCanary[canaryProxy.assert]

            renderFn = elements renderFn, Registry
            .bind prohibitThis("#{name} render")

        return Registry[componentObject.name] = componentObject

    regFn register, state

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

export nextTick =(delay, fn)->
    if typeof delay is 'function'
        fn = delay
        delay = 0
    setTimeout fn, delay

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


export themed =(themeId, definitions)->
	classNames = {}
	sheetEl = document.querySelector("style\#id-#{themeId}")
	if sheetEl
		document.removeChild sheetEl

	sheetEl = document.createElement 'style'
	document.head.appendChild sheetEl
	sheetEl.type = 'text/css'
	sheet = sheetEl.sheet
	console.log 'created', sheet

	n = 0
	for key, def of definitions
		n += 1
		localClass = ".#{key}-#{n}"
		classNames[key] = localClass
		styles = ""
		mods = {}
		def.call methods =
			class: (name)-> classNames[key] += ".#{name}"
			tag: (name)-> classNames[key] = name + classNames[key]
			css: (text)->
				styles += text
			color: (s)->
			layout: (n)->
			padding:
				text: ->
					methods.css "padding: 1em;"
			background:
				focus: ->
					methods.css "background-color: darkGray;"
			mod: (mod, css)->
				m = mods[mod] ?= {css: ""}
				m.css += css
		decl = "#{localClass} {
			 #{styles}
			}"
		ruleIdx = sheet.insertRule decl
		for mod, {css} of mods
			sheet.insertRule rules = "#{localClass}#{mod} { #{css} }"
			console.log 'mod rules', rules
	classNames
