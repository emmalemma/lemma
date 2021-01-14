import fs from 'fs'

promisify = (caller)->
	new Promise (res, rej)->
		caller (err, out)->
			if err then rej err
			else res out

exportName = (node)->
	if node.type is 'ExportDefaultDeclaration'
		return 'default'
	if node.declaration
		for decl in node.declaration.declarations
			return decl.id.name
	if node.specifiers?.length
		return node.specifiers[0].exported.name

exportType = (node)->
	# if node.declaration
	# 	for decl in node.declaration.declarations
	# 		# console.log 'node decl', decl
	# 		if decl.init.type is 'CallExpression'
	# 			console.log 'callee', decl.init.callee.name
	# 			if decl.init.callee.name is 'reactive'
	# 				return 'reactive'
	'rpc'

export workerInterface = ->
	name: 'worker-interface-plugin'
	transform: (code, id)->
		unless (code.match /expose\/(api|worker)/)
			return
		ast = this.parse code, sourceType: 'module'
		exports = []
		for node in ast.body
			if node.type in ['ExportDefaultDeclaration', 'ExportNamedDeclaration']
				exports.push exp =
					name: exportName node
					type: exportType node
		[_, parts...] = id.replace(process.cwd(), '').replace(/\.\w+$/, '').split /[\\\/]/
		target = parts.join '/'
		exportInterfaces = for exp in exports
			"""export #{if exp.name is 'default' then 'default ' else "const #{exp.name} = "} workerInterface.#{exp.type}("#{target}", '#{exp.name}');"""

		return map: {mappings: ''}, code: """
			import {workerInterface} from '@lemmata/client';

			#{exportInterfaces.join '\n\n'}
			"""

export serverImportMaps = ->
	options = null
	map =
		'@vue/reactivity': 'https://esm.sh/@vue/reactivity@3.0.4'

	name: 'server-import-maps'
	options: (opts)->
		options = opts
	resolveId: (source, importer)->
		if source in options.input and not importer
			return null
		result = if m = source.match /^@lemmata\/server\/(.+)/
			id: "../../node_modules/@lemmata/server/generated/#{m[1]}.js"
			external: true
		else if m = source.match /^\.\/(.+)/
			[path..., file] = importer.split /[\\\/]/
			id: "#{path.join '/'}/#{m[1]}.coffee"
			external: false
		else if source.match /^https:/
			id: source
			external: true
		else if source of map
			id: map[source]
			external: true
		else null
		result

export stripDecorators = ->
	name: 'strip-decorators-plugin'
	transform: (code, id)->
		return unless code.match /@lemmata\/expose/
		ast = this.parse code, sourceType: 'module'
		next = false
		for node in ast.body
			if node.type is 'ExpressionStatement' and node.expression.property?.name in ['CLIENT', 'API', 'WORKER']
				next = true
			else if next
				next = false

		map: {mappings: ''}, code: code.replace /import '@lemmata\/expose\/\w+'/g, ''

export autoInput = ({dir, matches, exclude, tagged})->
	name: 'auto-input-plugin'
	options: (options)->
		options.input = []
		scanDir = (dir)->
			entries = await promisify (cb)-> fs.readdir dir, withFileTypes: true, cb
			for entry in entries
				if entry.isDirectory()
					unless entry.name.match /node_modules|generated/
						await scanDir "#{dir}/#{entry.name}"
				else if entry.name.match(matches) and not entry.name.match exclude
					filePath = "#{dir}/#{entry.name}"
					file = await promisify (cb)-> fs.readFile filePath, 'utf8', cb
					if file.match tagged
						options.input.push filePath
		await scanDir dir
		options

export outputTree =->
	name: 'output-tree-plugin'
	renderChunk: (code, chunk, options)->
		return unless chunk.isEntry
		relativePath = chunk.facadeModuleId.replace process.cwd(), ''
		[_, dirs..., path] = relativePath.split /[\/\\]/
		chunk.fileName = [dirs..., chunk.fileName.replace(/[\d+]\.js/, '.js')].join '__slash__'
		null
