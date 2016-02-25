sources = require "./sources"

module.exports = (grunt) ->
	pkg = grunt.file.readJSON "package.json"
	grunt.initConfig
		pkg: pkg
		clean:
			build: ["dest/work", "dist"]
			workTemp: ["dest/work/cola"]
			dev: ["dest/dev"]
			"core-widget": [
				"dist/cola-core.js"
				"dist/cola-widget.js"
			]
		coffee:
			dev:
				options:
					sourceMap: false
					join: true
				files:
					"dest/dev/cola.js": sources.coffee.core
					"dest/dev/widget/widget.js": sources.coffee.widget
					"dest/dev/widget/base.js": sources.coffee.base
					"dest/dev/widget/layout.js": sources.coffee.layout
					"dest/dev/widget/edit.js": sources.coffee.edit
					"dest/dev/widget/collection.js": sources.coffee.collection
					"dest/dev/widget/list.js": sources.coffee.list

			"cola-core":
				options:
					sourceMap: false
					join: true
				files:
					"dist/cola-core.js": [
						"dest/work/cola/coffee/cola.coffee"
					]
			"cola-widget":
				options:
					sourceMap: false
					join: true
				files:
					"dist/cola-widget.js": [
						"dest/work/cola/coffee/widget.coffee"
					]
		less:
			dev:
				options:
					sourceMap: false
					join: true
				files:
					"dest/dev/skins/default/cola.css": sources.less.cola
			build:
				options:
					sourceMap: false
					join: true
				files:
					"dist/cola.css": sources.less.cola
		copy:
			libs:
				expand: true
				cwd: "src"
				src: ["lib/**"]
				dest: "dest/dev"

			semantic:
				expand: true
				cwd: "src/lib/semantic-ui"
				src: ["themes/**", "semantic.css", "semantic.js"]
				dest: "dist"

			apiResources:
				expand: true
				cwd: "node_modules/grunt-cola-ui-build"
				src: ["resources/**"]
				dest: "api"

		mochaTest:
			test:
				options:
					mocha:
						ui: "qunit"
					reporter: "spec"
				src: ["test/mocha/*.js"]
		qunit:
			all:
				options:
					urls: [
						'http://localhost:9001/test/qunit/all.html'
					]
		uglify:
			options:
				expand: true
				preserveComments: "some"
			build:
				files: [
					{
						expand: true
						cwd: 'dist'
						src: '**/*.js'
						dest: 'dist'
						ext: '.min.js'
					}
				]
		yaml:
			api:
				files: [
					expand: true
					cwd: "src"
					src: ["**/*.yaml"]
					dest: "api"
				]
		watch:
			coffee:
				files: ["src/**/*.coffee"]
				tasks: "coffee:dev"
			less:
				files: ["src/**/*.less"]
				tasks: "less:dev"
			libs:
				files: ["src/lib/**"]
				tasks: "copy:libs"
		connect:
			testServer:
				options:
					port: 9001
					base: "."
		yamlToDoc:
			api:
				options:
					output: "api"
				files: [
					{
						expand: true
						cwd: "src"
						src: ["**/*.yaml"]
						dest: "api"
					}
				]

		"cola-ui-clean":
			core:
				files:
					"dest/work/cola/coffee/cola.coffee": sources.coffee.core
			widget:
				files:
					"dest/work/cola/coffee/widget.coffee": sources.coffee.widgetAll
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
					"dist/cola-widget.js": "dist/cola-widget.js"
					"dist/cola.css": "dist/cola.css"
		concat:
			"3rd":
				files:
					"dist/3rd.js": sources.lib.js

			cola:
				files:
					"dist/cola.js": ["dist/cola-core.js", "dist/cola-widget.js"]

		cssmin:
			target:
				files: [
					{
						expand: true
						cwd: 'dist'
						src: ['cola.css', 'semantic.css']
						dest: 'dist'
						ext: '.min.css'
					}
				]
		compress:
			js:
				options:
					mode: 'gzip'
				files: [
					{
						expand: true
						cwd: "dist"
						src: [
							'cola.js'
							'cola-widget.js'
							'cola-core.js'
							'3rd.js'
							'semantic.js'
						]
						dest: 'dist/gzip'
						ext: '.gz.js'
					}
				]
			css:
				options:
					mode: 'gzip'
				files: [
					{
						expand: true
						cwd: "dist"
						src: [
							'cola.css'
							'semantic.css'
						]
						dest: 'dist/gzip'
						ext: '.gz.css'
					}
				]

	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-less"
	grunt.loadNpmTasks "grunt-mocha-test"
	grunt.loadNpmTasks "grunt-contrib-qunit"
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-yaml"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-contrib-copy"
	grunt.loadNpmTasks "grunt-contrib-clean"
	grunt.loadNpmTasks "grunt-contrib-connect"
	grunt.loadNpmTasks "grunt-cola-ui-build"
	grunt.loadNpmTasks "grunt-contrib-concat"
	grunt.loadNpmTasks 'grunt-contrib-rename'
	grunt.loadNpmTasks 'grunt-contrib-cssmin'
	grunt.loadNpmTasks 'grunt-contrib-compress'

	grunt.registerTask "mochaTask", ["mochaTest"]
	grunt.registerTask "qunitTask", ["connect:testServer", "qunit"]
	grunt.registerTask "test", ["mochaTask", "qunitTask"]

	grunt.registerTask "compile", ["clean:dev", "coffee:dev", "less:dev", "copy:libs"]
	grunt.registerTask "api", ["yamlToDoc", "copy:apiResources"]
	grunt.registerTask "all", ["clean", "coffee", "less", "mochaTest", "uglify", "copy"]
	grunt.registerTask "w", ["watch"]
	grunt.registerTask "build", ["clean:build", "cola-ui-clean", "coffee:cola-core", "coffee:cola-widget",
								 "less:build", "cola-ui-license", "concat",
								 "clean:core-widget", "copy:semantic",
								 "uglify:build",
								 "cssmin",
#								 "compress",
								 "clean:workTemp"]