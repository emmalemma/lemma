fs = require 'fs'

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

exports.workerInterface = ({matches})->
	name: 'worker-interface-plugin'
	transform: (code, id)->
		unless code.match /^(\/\/ ([^\n])+[\r\n]+\s*)?\/\* @__(API|WORKER)__ \*\//
			return
		ast = this.parse code, sourceType: 'module'
		exports = []
		for node in ast.body
			if node.type in ['ExportDefaultDeclaration', 'ExportNamedDeclaration']
				exports.push exp =
					name: exportName node
					type: exportType node
		target = id.match(/([^\/\\]+)\.[a-z]+$/)[1]
		exportInterfaces = for exp in exports
			"""export #{if exp.name is 'default' then 'default ' else "const #{exp.name} = "} workerInterface.#{exp.type}("#{target}", '#{exp.name}');"""

		return map: {mappings: ''}, code: """
			import {workerInterface} from 'lemma';

			#{exportInterfaces.join '\n\n'}
			"""

exports.serverImportMaps = ->
	options = null
	name: 'server-import-maps'
	options: (opts)->
		options = opts
	resolveId: (source, importer)->
		if source in options.input
			return null

		if source.match /^lemma/
			id: "../node_modules/#{source}.js"
			external: true
		else if source.match /^\.\//
			id: "#{source}.coffee"
			external: false
		else null


exports.autoInput = ({dir, matches, exclude, tagged})->
	name: 'auto-input-plugin'
	options: (options)->
		options.input = []
		files = await promisify (cb)-> fs.readdir dir, cb
		for file in files
			if file.match(matches) and not file.match exclude
				filePath = "#{dir}/#{file}"
				file = await promisify (cb)-> fs.readFile filePath, 'utf8', cb
				# console.log 'testing tag', tagged
				if file.match tagged
					options.input.push filePath
		console.log 'bundling', options.input
		options
