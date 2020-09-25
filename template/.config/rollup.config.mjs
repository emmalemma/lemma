// rollup.config.js
import coffeescript from 'rollup-plugin-coffee-script';
import nodeResolve from 'rollup-plugin-node-resolve';
import injectProcessEnv from 'rollup-plugin-inject-process-env';
import babel from '@rollup/plugin-babel';
import path from 'path';

export default {
  input: 'client/main.coffee',
  plugins: [
	coffeescript(),
	nodeResolve({ extensions: ['.js', '.coffee'] }),
	// commonjs({
	//   extensions: ['.js', '.coffee']
  // }),
	babel({ babelHelpers: 'bundled', configFile: path.resolve(__dirname, 'babel.config.mjs') }),
	injectProcessEnv({
        env: {}}
    ),
],
	output: {
		file: 'public/bundle.js',
		format: 'iife', // immediately-invoked function expression — suitable for <script> tags
		sourcemap: true
	},
}
