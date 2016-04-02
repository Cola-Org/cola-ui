class cola.WidgetDataModel extends cola.AbstractDataModel
	constructor: (@model, @widget) ->

	get: (path, loadMode, context) -> @widget.get(path)

	set: () ->
	flush: () ->

class cola.WidgetModel extends cola.Scope
	constructor: (@widget) ->
		@data = new cola.WidgetDataModel(@, @widget)

		widget = @widget
		@action = (name) ->
			method = widget[name]
			if method instanceof Function
				return () -> method.apply(widget, arguments)
			return cola.defaultAction[name]

	destroy: () ->
		@data.destroy?()
		return

class cola.TemplateWidget extends cola.Widget

	@ATTRIBUTES:
		template:
			readOnlyAfterCreate: true

	constructor: (config) ->
		@_widgetModel = new cola.WidgetModel(@)
		super(config)

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

				for childNode in templateDom.childNodes
					dom.appendChild(childNode)
		return