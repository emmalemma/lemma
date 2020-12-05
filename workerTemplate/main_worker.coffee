import {reactive} from 'https://esm.sh/@vue/reactivity@3.0.4'

export todos = reactive []
#
# do ->
# 	load 'todos', todos
#
# watch (->todos), ->
# 	save todos
#
# export users = {}
#
# export todosForUser = (user)->
# 	users[user]

# returned a reactive object
# can deserialize on client
# send guid (from weakmap)
# retrieve from map on return
#
# export lazyUsers = lazyReactive {}
# = new Proxy {},
# 	get: ->
# 		reactive object
# returns an empty proxy
# deserializes to... complicated object
# virtual object full of promises
#
# could just be proxy forwarding
#
# think through first

export clearCompleted =->
	console.log 'clearing completed todos'
	return 'done'
