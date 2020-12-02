// rollup.config.js
import coffeescript from 'rollup-plugin-coffee-script';
import injectProcessEnv from 'rollup-plugin-inject-process-env';
import commonJs from '@rollup/plugin-commonjs';
import resolve from '@rollup/plugin-node-resolve';
import babel from '@rollup/plugin-babel';
import json from '@rollup/plugin-json';
import polyfills from 'rollup-plugin-node-polyfills';
import analyzer from 'rollup-plugin-analyzer';
import html from '@rollup/plugin-html';

export default {
  input: 'client/main.coffee',
  plugins: [
      coffeescript(),
      analyzer({hideDeps: false, summaryOnly: false}),
      resolve({preferBuiltins: false, extensions: ['.js', '.coffee']}),
      commonJs(),
      babel({
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
	// nodeResolve({ extensions: ['.js', '.coffee'] }),
	// commonjs({
	//   extensions: ['.js', '.coffee']
  // }),
	injectProcessEnv({
        env: {}}
    ),
    html({title: 'Template App'}),
],
	output: {
		file: 'public/bundle.js',
		format: 'iife', // immediately-invoked function expression — suitable for <script> tags
		sourcemap: true
	},
}
