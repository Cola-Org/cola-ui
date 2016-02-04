sources = require "./sources"

module.exports = (grunt) ->
	pkg = grunt.file.readJSON "package.json"
	grunt.initConfig
		pkg: pkg
		clean:
			build: ["dist"]
			workTemp: ["dist/work"]
		coffee:
			dist:
				options:
					sourceMap: false
					join: true
				files:
					"dist/cola-dorado7.js": sources.coffee.core
		copy:
			libs:
				expand: true
				cwd: "src"
				src: ["lib/**"]
				dest: "dist"
		watch:
			coffee:
				files: ["src/**/*.coffee"]
				tasks: "coffee:dist"

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
					"dist/cola-dorado7.js": "dist/cola-dorado7.js"

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

	grunt.registerTask "compile", ["clean:dev", "coffee:dist", "copy:libs"]
	grunt.registerTask "all", ["clean", "coffee", "copy"]
	grunt.registerTask "w", ["watch"]
	grunt.registerTask "build", ["clean:build","coffee:dist",
								 "cola-ui-license", "concat", "copy:libs", "clean:workTemp"]