
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
		return unless id.match matches
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

fs = require 'fs'

exports.autoInput = ({dir, matches, exclude})->
	name: 'auto-input-plugin'
	options: (options)->
		options.input = []
		new Promise (res, rej)->
			fs.readdir dir, (err, files)->
				rej err if err
				for file in files
					if file.match(matches) and not file.match exclude
						options.input.push "#{dir}/#{file}"
				console.log 'bundling', options.input
				res options
