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
import {terser} from 'rollup-plugin-terser';

import 'coffeescript/register';
import {workerInterface} from 'ur/plugins';

export default {
  input: 'index.coffee',
  plugins: [
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
    terser({
        ecma: 6,
        module: true,
        mangle: {keep_fnames: true},
        compress: {
            keep_fnames: true,
            ecma: 6
        },
        // keep_classnames: true,
        keep_fnames: true,
        toplevel: true,
    }),

    html({title: 'Template App'}),
    analyzer({hideDeps: false, summaryOnly: false}),
],
	output: {
		file: 'public/bundle.js',
		format: 'iife', // immediately-invoked function expression — suitable for <script> tags
		sourcemap: true
	},
}
