import coffeescript from 'rollup-plugin-coffee-script'
import injectProcessEnv from 'rollup-plugin-inject-process-env'
import commonJs from '@rollup/plugin-commonjs'
import resolve from '@rollup/plugin-node-resolve'
import {babel} from '@rollup/plugin-babel'
import json from '@rollup/plugin-json'
import polyfills from 'rollup-plugin-node-polyfills'
import analyzer from 'rollup-plugin-analyzer'
# // import html from '@rollup/plugin-html'
import brotli from 'rollup-plugin-brotli'
import {terser} from 'rollup-plugin-terser'
import {workerInterface, autoInput, serverImportMaps, stripDecorators} from './plugins.js'

export server =
	input: []
	plugins: [
			autoInput({dir: '.', matches: /\.coffee$/, exclude: /theme/, tagged: /^@expose.(API|WORKER)|@lemmata\/expose\/api/}),
			coffeescript(),
			serverImportMaps(),
			stripDecorators(),
	],
	output:
			dir: if process.env.ROLLUP_DEPLOY then './deploy/server' else './generated/server',
			format: 'es',
			sourcemap: true,
			chunkFileNames: "[name].js"

__dirname = `import.meta.url`.split('/')[2..-2].join('/').replace /^\/?C:/, ''

export client =
	input: ['.'],
	plugins: [
			autoInput({dir: '.', matches: /\.coffee$/, exclude: /theme/, tagged: /^@expose.CLIENT|@lemmata\/expose\/client/}),
			brotli(),

			coffeescript(),
			resolve({preferBuiltins: false, extensions: ['.js', '.coffee']}),
			commonJs(),
			workerInterface({matches: /_worker.[a-z]+$/}),
			stripDecorators(),
			babel({
			cwd: __dirname + '/..'
			babelHelpers: 'bundled',
			exclude: [/core-js/],
			presets: [["@babel/env", {
					"useBuiltIns": "entry",
					"corejs": 3,
					"modules": false,
					targets: {esmodules: true},

				}]]
			}),
			json(),
			polyfills(),
			injectProcessEnv({env: {}}),
			if process.env.ROLLUP_DEPLOY then terser({
					ecma: 6,
					module: true,
					compress: {
							ecma: 6
					},
					toplevel: true,
			}) else {}
	]
	output:
		dir: if process.env.ROLLUP_DEPLOY then './deploy/public' else './generated/public',
		format: 'es',
		sourcemap: process.env.ROLLUP_DEPLOY ? false : true
