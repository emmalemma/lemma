import {fs} from './deps.js'

readJson = (path)->
	JSON.parse await Deno.readTextFile path

writeJson = (path, object)->
	await Deno.writeTextFile path, JSON.stringify object, null, 2

export class DataStore
	constructor: (@path)->
		fs.ensureDir @path
		fs.ensureDir "#{@path}/.backup"

	readAll: (path)->
		path ?= @path
		base = {}
		for await entry from Deno.readDir("#{path}")
			if entry.isFile and m = entry.name.match /^(.*)\.json$/
				if m[1] is ''
					base[k] = v for k, v of await readJson "#{path}/#{entry.name}"
				else if m[1][0] is '.'
					continue
				else base[m[1]] = await readJson "#{path}/#{entry.name}"
			else if entry.isDirectory and not entry.name.match /^./
				base[entry.name] = await @readAll "#{path}/#{entry.name}"
		base

	read: (id)->
		try
			stat = await Deno.stat jsonPath = "#{@path}/#{id}.json"
			if stat.isFile
				return await readJson jsonPath
		catch e
			#

		try
			stat = await Deno.stat dirPath = "#{@path}/#{id}"
			if stat.isDirectory
				return await @readAll dirPath
		catch e
			#

		return null

	write: (id, object)->
		try
			stat = await Deno.stat jsonPath = "#{@path}/#{id}.json"
			if stat.isFile
				await Deno.rename jsonPath, "#{@path}/.backup/#{id}.json"
		catch e
			console.log 'existing json not found'

		await writeJson jsonPath, object
		console.log 'wrote', object, 'to', jsonPath
