sources =
	coffee:
		core: [
			"src/core/namespace.coffee"
			"src/core/util.coffee"
			"src/core/base.coffee"
			"src/i18n/en/cola.coffee"
			"src/core/ajax.coffee"
			"src/core/element.coffee"
			"src/core/date.coffee"
			"src/core/expression.coffee"
			"src/core/service.coffee"

			"src/dorado/support.coffee"
			"src/dorado/data-type.coffee"
			"src/dorado/entity.coffee"

			"src/core/model.coffee"

			"src/dorado/model.coffee"

			"src/core/action.coffee"
			"src/core/dom-util.coffee"
			"src/core/loader.coffee"
			"src/core/dom-feature.coffee"
			"src/core/dom-binding.coffee"
			"src/core/dom-template.coffee"
		]
	lib:
		js: [
			"src/lib/number-formatter.js"
			"src/lib/xdate.js"
			"src/lib/jsep.js"
		]

module?.exports = sources