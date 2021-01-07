import {rollup, watch as rollupWatch} from 'rollup'
import {performance} from 'perf_hooks'
import * as bundles from './bundles.js'
import {log} from './log.js'

export bundle = ->
	for name, options of bundles
		log 'bundling', name
		bundle = await rollup options
		await bundle.write options.output
		await bundle.close()

export watch = ->
	for name, options of bundles then do (name, options)->
		log 'Watching', name
		watcher = rollupWatch options
		startTime = 0
		watcher.on 'event', ({code, result, error})->
			switch code
				when 'BUNDLE_START' then startTime = performance.now()
				when 'BUNDLE_END'
					log "Built #{name} in #{performance.now() - startTime}ms."
					result.close()
				when 'ERROR'
					log.error "Error building #{name}:"
					log.error error
		process.on 'SIGINT', ->
			log '[SIGINT] closing watcher for', name
			watcher.close()
