### @__WORKER__ ###

export random =->
	console.log 'Server generated a random number: ', result = Math.random()
	result

export err =->
	throw new Error 'oops'
#
# restrict err, (request)->
# 	request.auth.userId is 10
