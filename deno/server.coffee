export Server =->
	console.log 'running'
	pid = Deno.run cmd: cmd = """deno run
	 --allow-env
	 --allow-run
	 --allow-net
	 --allow-read
	 --allow-write=./data
	 --unstable

	 ../lemma/deno/host.js
	 --watch
	""".split /\s+/
	console.log 'ran', cmd.join ' '
	console.log 'status', await pid.status()
