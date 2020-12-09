// rollup.config.js
import coffeescript from 'rollup-plugin-coffee-script';
import injectProcessEnv from 'rollup-plugin-inject-process-env';
import commonJs from '@rollup/plugin-commonjs';
import resolve from '@rollup/plugin-node-resolve';
import babel from '@rollup/plugin-babel';
import json from '@rollup/plugin-json';
import polyfills from 'rollup-plugin-node-polyfills';
import analyzer from 'rollup-plugin-analyzer';
// import html from '@rollup/plugin-html';
import brotli from 'rollup-plugin-brotli'
import {terser} from 'rollup-plugin-terser';

import 'coffeescript/register';
import {workerInterface, autoInput} from 'ur/plugins';

export default {
  input: ['.'],// ['index.coffee', 'demo.coffee'],
  plugins: [
      autoInput({dir: '.', matches: /\.coffee$/, exclude: /theme/}),
      brotli(),

      coffeescript(),
      resolve({preferBuiltins: false, extensions: ['.js', '.coffee']}),
      commonJs(),
      workerInterface({matches: /_worker.[a-z]+$/}),
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
	injectProcessEnv({env: {}}),

    {} || terser({
        ecma: 6,
        module: true,
        compress: {
            ecma: 6
        },
        toplevel: true,
    }),

    // html({title: 'Template App'}),
    analyzer({hideDeps: false, summaryOnly: true}),
],
	output: {
        dir: './public',
		// file: 'public/bundle.js',
		format: 'es',
		sourcemap: true
	},
}
