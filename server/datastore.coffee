import * as fs from "https://deno.land/std@0.80.0/fs/mod.ts"

readJson = (path)->
	JSON.parse await Deno.readTextFile path

writeJson = (path, object)->
	await Deno.writeTextFile path, JSON.stringify object, null, 2

export class DataStore
	constructor: (@path, {@indexes} = {})->
		fs.ensureDir @path
		fs.ensureDir "#{@path}/.backup"
		@index = {}
		@readIndex()

	readIndex: ->
		try
			@index = (await readJson "#{@path}/.index") or {}
		catch e
			console.log 'Index read error', @path
		@index[k] ?= {} for k of @indexes

	persistIndex: ->
		await writeJson "#{@path}/.index", @index

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

		indexed = false
		for key, fn of @indexes
			indexed = true
			value = fn object
			if value?
				(index = @index[key] ?= {})[fn object] = id

		@persistIndex() if indexed
		# console.log 'wrote', object, 'to', jsonPath
