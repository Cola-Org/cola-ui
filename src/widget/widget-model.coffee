class cola.WidgetDataModel extends cola.AbstractDataModel
	constructor: (@model, @widget) ->

	get: (path, loadMode, context) -> @widget.get(path)


