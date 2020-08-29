import {h, onUnmounted, createApp} from 'vue'

import {ElementalError} from './errors'


formatPath =(el_path, max_length = 5)->
    if el_path.length > max_length
        el_path = [el_path[0], "...#{el_path.length - max_length} hidden...", ...el_path[-max_length+1..]]
    el_path.map((p)=>"el(#{p})").join ' -> '


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
