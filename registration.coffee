import {canaryProxy, prohibitThis, RegistrationError} from './errors'
# import {elements} from './elements'

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
