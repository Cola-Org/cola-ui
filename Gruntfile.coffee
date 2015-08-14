sources = require "./sources"
module.exports = (grunt) ->
	grunt.initConfig
		pkg: grunt.file.readJSON "package.json"
		clean:
			build: ["dest/work", "dest/publish"]
			workTemp: ["dest/work/cola"]
		coffee:
			core:
				options:
					sourceMap: false
					join: true
				files:
					"dest/cola.js": sources.coffee.core
			widget:
				options:
					sourceMap: false
					join: true
				files:
					"dest/widget/widget.js": sources.coffee.widget
					"dest/widget/base.js": sources.coffee.base
					"dest/widget/edit.js": sources.coffee.edit
					"dest/widget/layout.js": sources.coffee.layout
					"dest/widget/collection.js": sources.coffee.collection
					"dest/widget/list.js": sources.coffee.list

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
			widget:
				options:
					sourceMap: false
					join: true
				files:
					"dest/skins/default/cola.css": sources.less.cola
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
				dest: "dest"

			semantic:
				expand: true
				cwd: "src/lib/semantic-ui"
				src: ["themes/**", "semantic.css"]
				dest: "dest/publish"

			docResources:
				expand: true
				cwd: "node_modules/grunt-cola-build"
				src: ["resources/**"]
				dest: "doc"

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
			doc:
				files: [
					expand: true
					cwd: "src"
					src: ["**/*.yaml", "!i18n/**/*.yaml"]
					dest: "doc"
				]
			i18n:
				options:
					space: 4
				files: [
					expand: true
					cwd: "src"
					src: ["i18n/**/*.yaml"]
					dest: "dest"
				]
		watch:
			coffee:
				files: ["src/**/*.coffee"]
				tasks: "coffee"
			less:
				files: ["src/**/*.less"]
				tasks: "less"
			libs:
				files: ["src/lib/**"]
				tasks: "copy:libs"
		connect:
			testServer:
				options:
					port: 9001
					base: "."
		yamlToDoc:
			doc:
				options:
					output: "doc"
				files: [
					{
						expand: true
						cwd: "src"
						src: ["**/*.yaml", "!i18n/**/*.yaml"]
						dest: "doc"
					}
				]

		"cola-clean":
			core:
				files:
					"dest/work/cola/coffee/cola.coffee": sources.coffee.core
			widget:
				files:
					"dest/work/cola/coffee/widget.coffee": sources.coffee.widgetAll
		"cola-license":
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
		replace:
			example:
				src: ['src/**/*.coffee', 'src/**/*.less', 'src/**/*.yaml', 'test/**/*.*', 'sample/**/*.js','sample/**/*.html','sample/**/*.css','sample/**/*.json']
				overwrite: true
				replacements: [{
					from: 'dorado'
					to: 'cola'
				}]

	grunt.loadNpmTasks 'grunt-text-replace'
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
	grunt.registerTask "compile", ["coffee", "less"]
	grunt.registerTask "doc", ["yamlToDoc", "copy:docResources"]
	grunt.registerTask "all", ["clean", "coffee", "less", "mochaTest", "uglify", "copy"]
	grunt.registerTask "w", ["watch"]
	grunt.registerTask "build", ["clean:build", "cola-clean", "coffee:cola-core", "coffee:cola-widget",
								 "less:build", "cola-license", "concat",
								 "copy:semantic", "rename", "uglify:build", "cssmin", "compress", "clean:workTemp"]