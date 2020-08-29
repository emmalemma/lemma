
export class NamedError extends Error
    nameOf: ({constructor: {name}})-> name
    constructor: ->
        super arguments...
        @name = @nameOf this

export class ElementalError extends NamedError

export class CanaryUnused extends NamedError
export class CanaryMissing extends NamedError
export canaryProxy = (stuff, name)->
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
export prohibitThis = (name)-> new Proxy {},
    get: (_, prop)->
        throw new Prohibited "access to `this.#{prop}` in #{name}"

export class RegistrationError extends NamedError
