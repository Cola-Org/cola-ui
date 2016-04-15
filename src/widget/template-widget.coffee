class cola.WidgetDataModel extends cola.AbstractDataModel
	constructor: (model, @widget) ->
		super(model)

	get: (path, loadMode, context) ->
		if path.charCodeAt(0) is 64 # `@`
			return @widget.get(path.substring(1))
		else
			return @model.parent?.data.get(path, loadMode, context)

	set: (path, value) ->
		if path.charCodeAt(0) is 64 # `@`
			@widget.set(path.substring(1), value)
			@_onDataMessage(path.split("."), cola.constants.MESSAGE_PROPERTY_CHANGE, {})
		else
			@model.parent?.data.set(path, value)
		return

	_processMessage: (bindingPath, path, type, arg) ->
		@_onDataMessage(path, type, arg)
		return

	getDataType: (path) ->
		if path.charCodeAt(0) is 64 # `@`
			return null
		else
			return @model.parent?.data.getDataType(path)

	getProperty: (path) ->
		if path.charCodeAt(0) is 64 # `@`
			return null
		else
			return @model.parent?.data.getDataType(path)

	flush: (name, loadMode) ->
		if path.charCodeAt(0) isnt 64 # `@`
			@model.parent?.data.getDataType(name, loadMode)
		return @

class cola.WidgetModel extends cola.SubScope
	constructor: (@widget, @parent) ->
		widget = @widget
		@data = new cola.WidgetDataModel(@, widget)
		@parent?.data.bind("**", @)

		@action = (name) ->
			method = widget[name]
			if method instanceof Function
				return () -> method.apply(widget, arguments)
			return cola.defaultAction[name]

	_processMessage: (bindingPath, path, type, arg) ->
		if @messageTimestamp >= arg.timestamp then return
		return @data._processMessage(bindingPath, path, type, arg)

class cola.TemplateWidget extends cola.Widget

	@attributes:
		template:
			readOnlyAfterCreate: true

	constructor: (config) ->
		@_widgetModel = new cola.WidgetModel(@, config?.scope or cola.currentScope)
		super(config)

	set: (attr, value, ignoreError) ->
		super(attr, value, ignoreError)
		if typeof attr is "string" and @constructor.attributes.$has(attr)
			@_widgetModel.data._onDataMessage(attr.split("."), cola.constants.MESSAGE_PROPERTY_CHANGE, {})
		return @

	_createDom: () ->
		if @_template
			dom = cola.xRender(@_template or {}, @_widgetModel)
			@_domCreated = true
			return dom
		else
			return super()

	_initDom: (dom) ->
		super(dom)
		if @_template and not @_domCreated
			templateDom = cola.xRender(@_template or {}, @_widgetModel)
			if templateDom
				for attr in dom.attributes
					attrName = attr.name
					if not attrName is "style"
						dom.setAttribute(attrName, attr.value) if not dom.hasAttribute(attrName)

				for cssName of templateDom.style
					dom.style[cssName] = templateDom.style[cssName] if dom.style[cssName] is ""

				while templateDom.firstChild
					dom.appendChild(templateDom.firstChild)
		return