`#!/usr/bin/env node
`
import {bundle, watch} from './index.js'
import {spawn} from 'child_process'
import {log} from './log.js'
import {mkdirSync} from 'fs'

serve = (path, options = {})->
	log 'Spawning server process...'
	mkdirSync './generated', recursive: true
	spawn 'deno',
		"""run --allow-run ../node_modules/\\@lemmata/server/generated/server.js #{if options.debug then 'debug' else ''}""".split(/\s+/)
		stdio: 'inherit inherit inherit'.split(' ')
		cwd: './generated'
		killSignal: 'SIGINT'
	# process.on 'SIGINT', ->
	# 	log '[SIGINT] Stopping dev server...'

if process.argv[2] is 'watch'
	watch('.')
if process.argv[2] is 'debug'
	serve('./generated', debug: true)
else if process.argv[2] is 'serve'
	watch('.')
	serve('./generated')
else
	bundle('.')
