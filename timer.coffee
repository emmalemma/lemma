export class Timer
	constructor:(@label = 'Timer')->
		@start = Date.now()

	start: -> @start = Date.now()
	stop: -> @stop = Date.now()
	log: (detail='')-> console.log "#{@label}:#{detail} #{Date.now() - @start}ms"
