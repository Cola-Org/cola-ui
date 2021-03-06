sources = require "./sources"
targetDir = ""
module.exports = (grunt) ->
	pkg = grunt.file.readJSON "package.json"
	grunt.initConfig
		pkg: pkg
		clean:
			build: ["dest/work", "dist"]
			workTemp: ["dest/work/cola"]
			dev: ["dest/dev"]
			"core-widget": ["dist/cola-widget.js"]
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
					"dest/dev/i18n/zh/cola.js": sources.i18n["zh"]

			"cola-core":
				options:
					sourceMap: false
					join: true
					process: (content, srcpath)->
						console.log("replace version")
						return content.replace("${version}", '#{pkg.version}');

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
			i18n:
				options:
					sourceMap: false
					join: true
				files:
					"dist/i18n/en/cola.js": sources.i18n["en"]
					"dist/i18n/zh/cola.js": sources.i18n["zh"]
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
			deploy:
				expand: true
				cwd: "dist"
				src: ["./**"]
				dest: targetDir

		uglify:
			options:
				expand: true
				preserveComments: "some"
			build:
				files: [
					{
						expand: true
						cwd: "dist"
						src: "**/*.js"
						dest: "dist"
						ext: ".min.js"
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
		yamlToDoc:
			api:
				options:
					output: "api"
					header: "Cola UI API-v#{pkg.version}"
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
/*! Cola - v#{pkg.version} (#{grunt.template.today('yyyy-mm-dd HH:MM:ss')})
 * Copyright (C) 2015-2017 Benny Bao & Alex Tong.
 * Licensed under the MIT license */

"""
			build:
				files:
					"dist/cola-core.js": "dist/cola-core.js"
					"dist/cola-widget.js": "dist/cola-widget.js"
					"dist/cola.css": "dist/cola.css"
		concat:
			"3rd-core":
				files:
					"dist/3rd-core.js": sources["lib-core"].js
			"3rd":
				files:
					"dist/3rd.js": sources.lib.js
			cola:
				files:
					"dist/cola.js": ["dist/cola-core.js", "dist/cola-widget.js"]
			all:
				files:
					"dist/all/javascript.js": ["dist/3rd.js", "dist/semantic.js", "dist/cola.js"]
					"dist/all/css.js": ["dist/semantic.css", "dist/cola.css"]
		cssmin:
			target:
				files: [
					{
						expand: true
						cwd: "dist"
						src: ["cola.css", "semantic.css"]
						dest: "dist"
						ext: ".min.css"
					}
				]
		compress:
			js:
				options:
					mode: "gzip"
				files: [
					{
						expand: true
						cwd: "dist"
						src: [
							"cola.js"
							"cola-widget.js"
							"cola-core.js"
							"3rd.js"
							"3rd-core.js"
							"semantic.js"
						]
						dest: "dist/gzip"
						ext: ".gz.js"
					}
				]
			css:
				options:
					mode: "gzip"
				files: [
					{
						expand: true
						cwd: "dist"
						src: [
							"cola.css"
							"semantic.css"
						]
						dest: "dist/gzip"
						ext: ".gz.css"
					}
				]
		replace:
			version:
				src: ["dist/cola.js", "dist/cola-core.js"],
				overwrite: true,
				replacements: [{
					from: '${version}',
					to: "#{pkg.version}.#{grunt.template.today('yymmddHHMMss')}"
				}]

	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-less"
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-yaml"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-contrib-copy"
	grunt.loadNpmTasks "grunt-contrib-clean"
	grunt.loadNpmTasks "grunt-cola-ui-build"
	grunt.loadNpmTasks "grunt-contrib-concat"
	grunt.loadNpmTasks "grunt-contrib-rename"
	grunt.loadNpmTasks "grunt-contrib-cssmin"
	grunt.loadNpmTasks "grunt-contrib-compress"
	grunt.loadNpmTasks "grunt-text-replace";

	grunt.registerTask "mochaTask", ["mochaTest"]
	grunt.registerTask "qunitTask", ["connect:testServer", "qunit"]
	grunt.registerTask "test", ["mochaTask", "qunitTask"]

	grunt.registerTask "compile", ["clean:dev", "coffee:dev", "less:dev", "copy:libs"]
	grunt.registerTask "api", ["yamlToDoc", "copy:apiResources"]
	grunt.registerTask "all", ["clean", "coffee", "less", "mochaTest", "uglify", "copy"]
	grunt.registerTask "w", ["watch"]
	grunt.registerTask "build", ["clean:build", "cola-ui-clean", "coffee:cola-core", "coffee:cola-widget",
		"coffee:i18n",
		"less:build",
		"cola-ui-license",
		"concat:3rd-core",
		"concat:3rd",
		"concat:cola",
		"clean:core-widget",
		"copy:semantic",
		"uglify:build",
		"cssmin",
#		 "compress",
		"clean:workTemp", "replace:version"]
	grunt.registerTask "concat-all", ["build", "concat:all"]
	if targetDir
		grunt.registerTask "deploy", ["copy:deploy"]