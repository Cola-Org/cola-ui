$.xCreate.templateProcessors.push (template, context)->
	if template instanceof cola.Widget
		widget = template
	else if template.$type
		widget = cola.widget(template, context?.namespace)

	if widget instanceof cola.Widget
		dom = widget.getDom()
		dom.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")
	return dom

_getElementConfig = (dom)->
	dom._config ?= {}
	return dom._config

cola.xCreate.attributeProcessor["$"] = (dom, attrName, attrValue, context)->
	return unless attrValue
	if typeof attrValue is "function"
		if context?.xRenderMode
			config = _getElementConfig(dom)
			config.events ?= {}
			config.events[attrName] = attrValue
			return false
	else if typeof attrValue is "object"
		config = _getElementConfig(dom)
		config[attrName] = attrValue
		return false
	return true

cola.xCreate.attributeProcessor["c-widget"] = (dom, attrName, attrValue, context)->
	return unless attrValue
	if typeof attrValue is "object"
		if context
			config = _getElementConfig(dom)
			$.extend(config, attrValue)
		return
	return true

cola.Model::widgetConfig = (id, config)->
	if arguments.length is 1
		if typeof id is "string"
			return @_widgetConfig?[id]
		else
			config = id
			@widgetConfig(k, v) for k, v of config
	else
		@_widgetConfig ?= {}
		@_widgetConfig[id] = config
	return

cola.Model::widget = (config)-> cola.widget(config, null, @)

ALIAS_REGEXP = new RegExp("\\$default", "g")

_findWidgetConfig = (scope, name)->
	while scope
		widgetConfig = scope._widgetConfig?[name]
		if widgetConfig then break
		scope = scope.parent
	return widgetConfig

_compileWidgetDom = (scope, dom, widgetType, config = {}, context)->
	if not widgetType.attributes._inited or not widgetType.events._inited
		cola.preprocessClass(widgetType)

	config.$constr = widgetType

	removeAttrs = null
	for attr in dom.attributes
		attrName = attr.name
		if attrName.indexOf("c-") is 0
			attrValue = attr.value
			if context.defaultPath
				attrValue = attrValue.replace(ALIAS_REGEXP, context.defaultPath)

			prop = attrName.slice(2)
			if widgetType.attributes.$has(prop) and prop isnt "class"
				if prop is "bind"
					config[prop] = attrValue
				else
					config[prop] = cola._compileExpression(scope, attrValue)

				removeAttrs ?= []
				removeAttrs.push(attrName)
			else
				isEvent = widgetType.events.$has(prop)
				if not isEvent and prop.indexOf("on") is 0
					if widgetType.events.$has(prop.slice(2))
						isEvent = true
						prop = prop.slice(2)

				if isEvent
					config[prop] = cola._compileExpression(scope, attr.value)
					removeAttrs ?= []
					removeAttrs.push(attrName)
		else
			attrValue = attr.value
			if context.defaultPath and attrName is "bind"
				attrValue = attrValue.replace(ALIAS_REGEXP, context.defaultPath)

			prop = attrName
			if widgetType.attributes.$has(prop)
				config[prop] = attrValue
			else
				isEvent = widgetType.events.$has(prop)
				if not isEvent and prop.indexOf("on") is 0
					if widgetType.events.$has(prop.slice(2))
						isEvent = true
						prop = prop.slice(2)

						removeAttrs ?= []
						removeAttrs.push(attrName)

				if isEvent
					config[prop] = attrValue

	if removeAttrs
		dom.removeAttribute(attr) for attr in removeAttrs
	return config

_compileWidgetAttribute = (scope, dom, context)->
	widgetConfigStr = dom.getAttribute("c-widget")
	if widgetConfigStr
		dom.removeAttribute("c-widget")
		if context.defaultPath
			widgetConfigStr = widgetConfigStr.replace(ALIAS_REGEXP, context.defaultPath)

		config = cola.util.parseStyleLikeString(widgetConfigStr, "$type")
		if config
			importNames = null
			for p, v of config
				importName = null
				if p.charCodeAt(0) is 64 # `@`
					importName = p.substring(1)
				else if p is "$type" and typeof v is "string" and v.charCodeAt(0) is 35 # `#`
					importName = v.substring(1)
				if importName
					delete config[p]
					importNames ?= []
					importNames.push(importName)

			if importNames
				for importName in importNames
					importConfig = _findWidgetConfig(scope, importName)
					if importConfig
						config[ip] = iv for ip, iv of importConfig
	return config

cola._userDomCompiler.$.push((scope, dom, context)->
	return null if cola.util.userData(dom, cola.constants.DOM_ELEMENT_KEY)
	return null unless dom.nodeType is 1

	if dom.id
		jsonConfig = _findWidgetConfig(scope, dom.id)

	parentWidget = context.parentWidget
	tagName = dom.tagName

	config = _compileWidgetAttribute(scope, dom, context)
	if not config or (not config.$type and not config.$constr)
		widgetType = parentWidget?.childTagNames?[tagName]
		widgetType ?= WIDGET_TAGS_REGISTRY[tagName]
		if widgetType
			config = _compileWidgetDom(scope, dom, widgetType, config, context)

	if context?.xRenderMode
		elementConfig = dom._config
		if elementConfig
			delete dom._config

	if not config and not jsonConfig
		if elementConfig
			if elementConfig.events
				for eventName, handler of elementConfig.events
					$fly(dom).on(eventName, handler)
		return null

	config ?= {}
	if elementConfig
		for k, v of elementConfig
			if k isnt "events" then config[k] = v
	if jsonConfig
		for k, v of jsonConfig
			if not config.hasOwnProperty(k) then config[k] = v

	if typeof config is "string"
		config = {
			$type: config
		}

	if config.$constr instanceof Function
		constr = config.$constr
	else
		constr = cola.resolveType((parentWidget?.CHILDREN_TYPE_NAMESPACE or "widget"), config, cola.Widget)
	config.$constr = constr

	return (scope, dom)->
		config.dom = dom
		oldScope = cola.currentScope
		cola.currentScope = scope
		try
			widget = cola.widget(config)

			if elementConfig
				if elementConfig.events
					for eventName, handler of elementConfig.events
						if widget.constructor.events.$has(eventName)
							widget.on(eventName, handler)
						else
							$fly(dom).on(eventName, handler)

			return widget
		finally
			cola.currentScope = oldScope
)

cola._userDomCompiler.$startContent.push((scope, dom, context, childContext)->
	widget = cola.util.userData(dom, cola.constants.DOM_ELEMENT_KEY)
	if widget
		childContext.parentWidget = widget.constructor
)

cola.registerTypeResolver "widget", (config)->
	return unless config
	if config.$constructor and cola.util.isSuperClass(cola.Widget, config.$constructor)
		return config.$constructor
	if config.$type and typeof config.$type is "string"
		typeName = config.$type
		type = cola[cola.util.capitalize(typeName)]
		return type if type

		if typeName.indexOf(".") > 0
			parts = typeName.split(".")
			pkg = cola
			for part, i in parts
				if i is parts.length - 1
					return pkg[cola.util.capitalize(part)]
				else
					pkg = pkg[part]
					break unless pkg
	return

cola.registerType("widget", "_default", cola.Widget)

cola.widget = (config, namespace, model)->
	return null unless config

	isSubWidget = (widget)->
		match = false
		widgetModel = widget._scope
		while widgetModel
			if widgetModel is model
				match = true
				break
			widgetModel = widgetModel.parent
		return match

	if typeof config is "string"
		ele = window[config]
		return null unless ele
		if ele.nodeType
			widget = cola.util.userData(ele, cola.constants.DOM_ELEMENT_KEY)
			if model and not isSubWidget(widget) then widget = null
			return widget
		else
			group = []
			for e in ele
				widget = cola.util.userData(e, cola.constants.DOM_ELEMENT_KEY)
				if widget instanceof cola.Widget and (not model or isSubWidget(widget))
					group.push(widget)
			if not group.length
				return null
			else if group.length is 1
				return group[0]
			else
				return cola.Element.createGroup(group)
	else
		if config instanceof Array
			group = []
			for c in config
				group.push(cola.widget(c, namespace, model))
			return cola.Element.createGroup(group)
		else if config.nodeType
			if config.nodeType is 1
				widget = cola.util.userData(config, cola.constants.DOM_ELEMENT_KEY)
				if model and not isSubWidget(widget)
					widget = null
				return if widget instanceof cola.Widget then widget else null
			else
				return null
		else
			constr = config.$constr or cola.resolveType(namespace or "widget", config, cola.Widget)
			if model and not config.scope
				config.scope = model
			return new constr(config)

cola.findWidget = (dom, typeName, parentWindow)->
	getType = (win, typeName)->
		type = win.cola.resolveType("widget", { $type: typeName }) unless type
		return type

	if typeof typeName is "function"
		type = typeName
	else
		type = getType(window, typeName)

	if dom instanceof cola.Widget
		dom = dom.getDom()

	find = (win, dom, type)->
		parentDom = dom.parentNode
		while parentDom
			dom = parentDom
			widget = win.cola.util.userData(dom, win.cola.constants.DOM_ELEMENT_KEY)
			if widget
				if not type or widget instanceof type
					return widget
			parentDom = dom.parentNode

		if parentWindow and win.parent
			try
				parentFrames = win.parent.$("iframe,frame")
			catch
			# do nothing

			if parentFrames
				frame = null
				parentFrames.each ()->
					if @contentWindow is win
						frame = @
						return false

				if frame
					type = getType(win.parent, typeName)
					if type
						widget = find(win.parent, frame, type)
		return widget

	return find(window, dom, type)

###
User Widget
###

WIDGET_TAGS_REGISTRY = {}

_extendWidget = (superCls, definition)->
	cls = (config)->
		if not cls.attributes._inited or not cls.events._inited
			cola.preprocessClass(cls)

		if definition.create then @on("create", definition.create)
		if definition.destroy then @on("destroy", definition.destroy)
		if definition.initDom then @on("initDom", (self, arg)=> @initDom(arg.dom))
		if definition.refreshDom then @on("refreshDom", (self, arg)=> @refreshDom(arg.dom))

		@on("attributeChange", (self, arg)=>
			attr = arg.attribute
			@_widgetModel.data.onDataMessage([ attr ], cola.constants.MESSAGE_PROPERTY_CHANGE, {})
			value = @_get(attr)
			if value and (value instanceof cola.Entity or value instanceof cola.EntityList)
				@_entityProps[attr] = value
			else
				delete @_entityProps[attr]
			return
		)

		@_entityProps = {}
		@_widgetModel = new cola.WidgetModel(@, config?.scope or cola.currentScope)
		cls.__super__.constructor.call(@, config)
		return

	`extend(cls, superCls)`

	cls.tagName = definition.tagName?.toUpperCase() or ""
	cls.className = definition.className or superCls.className or ""
	cls.parentWidget = definition.parentWidget if definition.parentWidget

	cls.attributes = definition.attributes or {}

	cls.attributes.widgetModel =
		readOnly: true
		getter: ()-> @_widgetModel

	cls.attributes.template =
		readOnlyAfterCreate: true

	if definition.events then cls.events = definition.events

	if definition.template
		template = definition.template
		if typeof template is "string" and template.match(/^\#[\w\-\$]*$/)
			template = cola.util.getGlobalTemplate(template.substring(1))
		else if template and typeof template is "object" and template.nodeType
			template = template.outerHTML

		cls.attributes.template =
			defaultValue: template

	cls::_createDom = ()->
		if @_template
			@_domCreated = true

			template = @_template
			if template
				template = cola.xRender(template, @_widgetModel)

			dom = cola.xCreate({
				tagName: @constructor.tagName or "DIV"
				class: "ui " + (@constructor.className or "")
				content: template
			})
			return dom
		else if cls.parentWidget
			return cls.parentWidget::_createDom.call(@)
		else
			return cola.RenderableElement::_createDom.apply(@)

	cls::_initDom = (dom)->
		if cls.parentWidget
			cls.parentWidget::_initDom.call(@, dom)

		template = @_template
		if template and not @_domCreated
			templateDom = @xRender(template)
			if templateDom?.nodeType is 11    # fragment
				templateDom = templateDom.firstElementChild

			if templateDom
				if templateDom.attributes
					for attr in templateDom.attributes
						attrName = attr.name
						if attrName is "class"
							$fly(dom).addClass(attr.value)
						else if attrName isnt "style"
							dom.setAttribute(attrName, attr.value) if not dom.hasAttribute(attrName)

				for cssName of templateDom.style
					dom.style[cssName] = templateDom.style[cssName] if dom.style[cssName] is ""

				while templateDom.firstChild
					dom.appendChild(templateDom.firstChild)
		return

	cls::xRender = (template, context)-> cola.xRender(template, @_widgetModel, context)

	for prop, def of definition
		if definition.hasOwnProperty(prop) and typeof def is "function"
			cls::[prop] = def

	return cls

cola.defineWidget = (parentType, definition)->
	type = parentType
	if not cola.util.isSuperClass(cola.Widget, type)
		definition = type
		type = cola.TemplateWidget

	if definition
		type = _extendWidget(type, definition)

	tagNames = type.tagName?.toUpperCase()
	if tagNames
		for tagName in tagNames.split(/[\s,;]/)
			if tagName and type.parentWidget
				childTagNames = type.parentWidget.childTagNames
				if not childTagNames
					type.parentWidget.childTagNames = childTagNames = {}
				if childTagNames[tagName]
					throw new cola.Exception("Tag name \"#{tagName}\" is already registered in \"#{type.parentWidget.tagName}\".")
				childTagNames[tagName] = type
			else if tagName
				if WIDGET_TAGS_REGISTRY[tagName]
					throw new cola.Exception("Tag name \"#{tagName}\" is already registered.")
				WIDGET_TAGS_REGISTRY[tagName] = type

	return type

cola.registerWidget = cola.defineWidget