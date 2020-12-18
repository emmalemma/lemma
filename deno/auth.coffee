import {jwt, uuid} from './deps.js'
import Config from './config.js'

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

export AuthIdentity = (context, next)->
	token = context.cookies.get 'Identity'

	if token
		payload = await readToken token

	unless payload
		payload = guid: uuid.v4.generate()
		assignId context, payload.guid

	context.identity =
		guid: payload.guid

	next()
