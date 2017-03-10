class cola.WidgetDataModel extends cola.AbstractDataModel
	constructor: (model, @widget) ->
		super(model)

	get: (path, loadMode, context) ->
		if path.charCodeAt(0) is 64 # `@`
			return @model.parent?.data.get(path.substring(1), loadMode, context)
		else
			return @widget.get(path)

	set: (path, value) ->
		if path.charCodeAt(0) is 64 # `@`
			@model.parent?.data.set(path.substring(1), value)
		else
			@widget.set(path, value)
			@onDataMessage(path.split("."), cola.constants.MESSAGE_PROPERTY_CHANGE, {})
		return

	_bind: (path, processor) ->
		if path[0].charCodeAt(0) is 64 # `@`
			@model.bindToParent(path)
		return super(path, processor)

	processMessage: (bindingPath, path, type, arg) ->
		innerPath = path.slice(0)
		innerPath[0] = "@" + innerPath[0]
		@onDataMessage(innerPath, type, arg)

		entity = arg.entity or arg.entityList
		if entity
			for attr, value of @widget._entityProps
				isParent = false
				e = entity
				while e
					if e is value
						isParent = true
						break
					e = e.parent

				if isParent
					targetPath = value.getPath()
					if targetPath?.length
						relativePath = path.slice(targetPath.length)
						@onDataMessage([attr].concat(relativePath), type, arg)
		return

	getDataType: (path) ->
		if path.charCodeAt(0) is 64 # `@`
			return @model.parent?.data.getDataType(path.substring(1))
		else
			return null

	getProperty: (path) ->
		if path.charCodeAt(0) is 64 # `@`
			return @model.parent?.data.getProperty(path.substring(1))
		else
			return null

	flush: (name, loadMode) ->
		if path.charCodeAt(0) is 64 # `@`
			@model.parent?.data.getDataType(name.substring(1), loadMode)
		return @

class cola.WidgetModel extends cola.SubScope
	repeatNotification: true

	constructor: (@widget, @parent) ->
		widget = @widget
		@data = new cola.WidgetDataModel(@, widget)

		@action = (name) ->
			method = widget[name]
			if method instanceof Function
				return () -> method.apply(widget, arguments)
			return widget._scope.action(name)

	destroy: () ->
		@unbindToParent()
		return super()

	bindToParent: (path) ->
		return if @allPathBinded or not @parent

		path = path.join(".").substring(1)
		if path is "**"
			@allPathBinded = true
			@unbindToParent()
			@parent.data.bind(path, @)
			@pathMap = {path: true}
		else
			@pathMap ?= {}
			if not @pathMap[path]
				@pathMap[path] = true
				@parent.data.bind(path, @)
				@pathMap[path] = true
		return

	unbindToParent: () ->
		return unless @parent and @pathMap
		for path of @pathMap
			@parent.data.unbind(path, @)
		return

	processMessage: (bindingPath, path, type, arg) ->
		if @messageTimestamp >= arg.timestamp then return
		return @data.processMessage(bindingPath, path, type, arg)

class cola.TemplateWidget extends cola.Widget