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

exportType = -> 'rpc'

exports.workerInterface = ({matches})->
	name: 'worker-interface-plugin'
	transform: (code, id)->
		unless code.match /^(\/\/ ([^\n])+[\r\n]+\s*)?\/\* @__API__ \*\//
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
			import {workerInterface} from 'ur';

			#{exportInterfaces.join '\n\n'}
			"""


exports.autoInput = ({dir, matches, exclude})->
	name: 'auto-input-plugin'
	options: (options)->
		options.input = []
		files = await promisify (cb)-> fs.readdir dir, cb
		for file in files
			if file.match(matches) and not file.match exclude
				filePath = "#{dir}/#{file}"
				file = await promisify (cb)-> fs.readFile filePath, 'utf8', cb
				if file.match /^### @__PUBLISH__ ###/
					options.input.push filePath
		console.log 'bundling', options.input
		options
