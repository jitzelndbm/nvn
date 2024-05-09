import nodeResolve from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import nodePolyfills from 'rollup-plugin-polyfill-node';
import terser from '@rollup/plugin-terser';
import babel from '@rollup/plugin-babel';

export default {
	input: './src/main.js',
	plugins: [
		nodeResolve(),
		commonjs(),
		nodePolyfills(),
		babel({ babelHelpers: "bundled" }),
		terser()
	],
	output: {
		file: './build/bundle.min.js',
		format: 'iife',
		name: 'myGraph',
		esModule: false,
		exports: "named",
		sourcemap: true
	}
}

