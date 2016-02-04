sources = require "./sources"

module.exports = (grunt) ->
	pkg = grunt.file.readJSON "package.json"
	grunt.initConfig
		pkg: pkg
		clean:
			build: ["dest/work", "dist"]
			workTemp: ["dest/work/cola"]
			dev: ["dest/dev"]
		coffee:
			dev:
				options:
					sourceMap: false
					join: true
				files:
					"dest/dev/cola.js": sources.coffee.core

			"cola-core":
				options:
					sourceMap: false
					join: true
				files:
					"dist/cola-core.js": [
						"dest/work/cola/coffee/cola.coffee"
					]
		copy:
			libs:
				expand: true
				cwd: "src"
				src: ["lib/**"]
				dest: "dest/dev"
		watch:
			coffee:
				files: ["src/**/*.coffee"]
				tasks: "coffee:dev"
			libs:
				files: ["src/lib/**"]
				tasks: "copy:libs"
		connect:
			testServer:
				options:
					port: 9001
					base: "."

		"cola-ui-clean":
			core:
				files:
					"dest/work/cola/coffee/cola.coffee": sources.coffee.core
		"cola-ui-license":
			options:
				license: """
/*! Cola UI - #{pkg.version}
 * Copyright (c) 2002-2016 BSTEK Corp. All rights reserved.
 *
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html)
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 *
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

"""
			build:
				files:
					"dist/cola-core.js": "dist/cola-core.js"
		concat:
			"3rd":
				files:
					"dist/3rd.js": sources.lib.js

	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-contrib-copy"
	grunt.loadNpmTasks "grunt-contrib-clean"
	grunt.loadNpmTasks "grunt-contrib-connect"
	grunt.loadNpmTasks "grunt-cola-ui-build"
	grunt.loadNpmTasks "grunt-contrib-concat"
	grunt.loadNpmTasks 'grunt-contrib-rename'

	grunt.registerTask "compile", ["clean:dev", "coffee:dev", "copy:libs"]
	grunt.registerTask "all", ["clean", "coffee", "copy"]
	grunt.registerTask "w", ["watch"]
	grunt.registerTask "build", ["clean:build", "cola-ui-clean", "coffee:cola-core",
								 "cola-ui-license", "concat", "clean:workTemp"]