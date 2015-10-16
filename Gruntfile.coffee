sources = require "./sources"
module.exports = (grunt) ->
	grunt.initConfig
		pkg: grunt.file.readJSON "package.json"
		clean:
			build: ["dest/work", "dest/publish"]
			workTemp: ["dest/work/cola"]
			dev: ["dest/dev"]
			"core-widget": [
				"dest/publish/cola-core.js"
				"dest/publish/cola-widget.js"
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
					"dest/publish/cola-core.js": [
						"dest/work/cola/coffee/cola.coffee"
					]
			"cola-widget":
				options:
					sourceMap: false
					join: true
				files:
					"dest/publish/cola-widget.js": [
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
					"dest/publish/cola.css": sources.less.cola
		copy:
			libs:
				expand: true
				cwd: "src"
				src: ["lib/**"]
				dest: "dest/dev"

			semantic:
				expand: true
				cwd: "src/lib/semantic-ui"
				src: ["themes/**", "semantic.css"]
				dest: "dest/publish"

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
						expand: true,
						cwd: 'dest/publish',
						src: '**/*.js'
						dest: 'dest/publish/min'
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
/*! Cola UI - v1.0.0
 * Copyright (c) 2002-2016 BSTEK Corp. All rights reserved.
 *
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html)
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 *
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */
"""
			js:
				files:
					"dest/publish/cola-core.js": "dest/publish/cola-core.js"
					"dest/publish/cola-widget.js": "dest/publish/cola-widget.js"
		concat:
			"3rd":
				files:
					"dest/publish/3rd.js": sources.lib.js
			cola:
				files:
					"dest/publish/cola.js": ["dest/publish/cola-core.js", "dest/publish/cola-widget.js"]
		rename:
			main:
				files: [
					{
						src: ['dest/publish/semantic.css']
						dest: 'dest/publish/3rd.css'
					}
				]
		cssmin:
			target:
				files: [
					{
						expand: true
						cwd: 'dest/publish'
						src: ['cola.css', '3rd.css']
						dest: 'dest/publish/min'
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
						cwd: "dest/publish"
						src: [
							'cola.js'
							'cola-widget.js'
							'cola-core.js'
							'3rd.js'
						]
						dest: 'dest/publish/gzip'
						ext: '.gz.js'
					}
				]
			css:
				options:
					mode: 'gzip'
				files: [
					{
						expand: true
						cwd: "dest/publish"
						src: [
							'cola.css'
							'3rd.css'
						]
						dest: 'dest/publish/gzip'
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
	                             "clean:core-widget", "copy:semantic", "rename",
								 #"uglify:build", "cssmin", "compress",
	                             "clean:workTemp"]