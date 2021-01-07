log = (args...)->
	console.log '[Server Runner]', args...

do ->
	[path..., file] = `import.meta.url`.split '/'
	log 'running at', uri = path.join '/'
	pid = Deno.run cmd: cmd = """deno run
	 --allow-env
	 --allow-run
	 --allow-net
	 --allow-read
	 --allow-write=./data
	 --unstable

	 #{uri}/host.js
	""".split /\s+/
	log 'running', cmd.join ' '
	log 'status', await pid.status()
