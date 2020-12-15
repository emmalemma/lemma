import {jwt, uuid} from './deps.js'
import Config from './config.js'

readToken = (token)->
	await jwt.verify token, Config.jwt.keys[0], Config.jwt.algorithm

makeToken = (payload)->
	await jwt.create alg:Config.jwt.algorithm, typ:'jwt', payload, Config.jwt.keys[0]

export AuthIdentity = (context, next)->
	token = context.cookies.get 'Identity'
	
	if token
		payload = await readToken token

	unless payload
		token = await makeToken payload = guid: uuid.v4.generate()
		context.cookies.set 'Identity', token,
			domain: context.request.url.hostname,
			expires: new Date payload.exp * 1000
			httpOnly: true
			overwrite: true
			secure: true
			sameSite: 'strict'

	context.identity =
		guid: payload.guid

	next()
