import {jwt, uuid} from './deps.js'
import {DataStore} from './datastore.js'
import * as bcrypt from "https://deno.land/x/bcrypt@v0.2.4/mod.ts";

import Config from './config.js'

identities = {}
idStore = new DataStore './data/identities',
	indexes:
		username: (record)->record.username

readToken = (token)->
	await jwt.verify token, Config.jwt.keys[0], Config.jwt.algorithm

makeToken = (payload)->
	await jwt.create alg:Config.jwt.algorithm, typ:'jwt', payload, Config.jwt.keys[0]

export assignId = (context, id)->
	token = await makeToken payload = guid: id
	context.cookies.set 'Identity', token,
		domain: context.request.url.hostname,
		# expires: new Date payload.exp * 1000
		httpOnly: true
		overwrite: true
		secure: true
		sameSite: 'strict'

export destroyId = (context)->
	context.cookies.delete 'Identity',
		domain: context.request.url.hostname

export saveId = (identity)->
	idStore.write identity.guid, identity

export authenticateUser = (username, password)->
	id = idStore.index.username[username]
	unless id
		throw new Error 'no such user'

	identity = await idStore.read id
	unless await bcrypt.compare password, identity.password
		throw new Error 'invalid password'
	identity

export AuthIdentity = (context, next)->
	token = context.cookies.get 'Identity'

	if token
		payload = await readToken token

	unless payload
		payload = guid: uuid.v4.generate()
		assignId context, payload.guid

	context.identity = identities[payload.guid] ?= (await idStore.read(payload.guid)) or guid: payload.guid

	context.requireAdmin = ->
		unless context.identity.admin
			throw new Error 'requires admin'

	next()
