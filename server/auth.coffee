# import "@lemmata/expose/middleware"

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
	token = await makeToken payload =
		sub: id
		iat: iat = Math.floor(Date.now() / 1000)
		exp: iat + 30 * 24 * 60 * 60

	context.cookies.set 'Identity', token,
		domain: context.request.url.hostname,
		expires: new Date payload.exp * 1000
		httpOnly: true
		overwrite: true
		# secure: true
		sameSite: 'strict'

export destroyId = (context)->
	context.cookies.delete 'Identity',
		domain: context.request.url.hostname

export saveId = (identity)->
	idStore.write identity.guid, identity

export authenticateUser = (username, password)->
	id = idStore.index.username?[username]
	unless id
		throw new Error 'no such user'

	identity = await idStore.read id
	unless await bcrypt.compare password, identity.password
		throw new Error 'invalid password'
	identity

export registerUser = (username, password)->
	unless username and password
		throw new Error 'username and password must exist'

	if idStore.index.username[username]
		throw new Error 'username is already registered'

	if @identity.username and @identity.password
		throw new Error 'user record has a username already'

	@identity.username = username
	@identity.password = await bcrypt.hash(password)
	await saveId @identity

export AuthIdentity = (context, next)->
	token = context.cookies.get 'Identity'

	if token
		payload = await readToken token

	unless payload
		payload = sub: uuid.v4.generate()
		assignId context, payload.sub
	else
		if payload.guid
			payload.sub = payload.guid

		if not payload.iat or payload.iat < (Date.now() / 1000) - 30 * 60 * 60
			assignId context, payload.sub

	context.identity = identities[payload.sub] ?= (await idStore.read(payload.sub)) or guid: payload.sub

	context.requireAdmin = ->
		unless context.identity.admin
			throw new Error 'requires admin'

	next()
