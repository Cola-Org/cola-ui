$.xCreate.templateProcessors.push (template) ->
	if template instanceof cola.Widget
		dom = template.getDom()
		dom.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")
		return dom
	return

$.xCreate.attributeProcessor["c-widget"] = ($dom, attrName, attrValue, context) ->
	return unless attrValue
	if typeof attrValue == "string"
		$dom.attr(attrName, attrValue)
	else if context
		configKey = cola.uniqueId()
		$dom.attr("c-widget-config", configKey)
		widgetConfigs = context.widgetConfigs
		if !widgetConfigs
			context.widgetConfigs = widgetConfigs = {}
		widgetConfigs[configKey] = attrValue
	return

cola.xRender.nodeProcessors.push (node, context) ->
	if node instanceof cola.Widget
		widget = node
	else if node.$type
		widget = cola.widget(node, context.namespace)
	if widget
		dom = widget.getDom()
		dom.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")
	return dom

cola.Model::widgetConfig = (id, config) ->
	if arguments.length == 1
		if typeof id == "string"
			return @_widgetConfig?[id]
		else
			config = id
			@widgetConfig(k, v) for k, v of config
	else
		@_widgetConfig ?= {}
		@_widgetConfig[id] = config
	return

ALIAS_REGEXP = new RegExp("\\$default", "g")

_findWidgetConfig = (scope, name) ->
	while scope
		widgetConfig = scope._widgetConfig?[name]
		if widgetConfig then break
		scope = scope.parent
	return widgetConfig

_compileWidgetDom = (dom, widgetType) ->
	if not widgetType.attributes._inited or not widgetType.events._inited
		cola.preprocessClass(widgetType)

	config =
		$constr: widgetType

	removeAttrs = null
	for attr in dom.attributes
		attrName = attr.name
		if attrName.indexOf("c-") is 0
			prop = attrName.slice(2)
			if widgetType.attributes.$has(prop) and prop isnt "class"
				if prop is "bind"
					config[prop] = attr.value
				else
					config[prop] = cola._compileExpression(attr.value)

				removeAttrs ?= []
				removeAttrs.push(attrName)
			else
				isEvent = widgetType.events.$has(prop)
				if not isEvent and prop.indexOf("on") is 0
					if widgetType.events.$has(prop.slice(2))
						isEvent = true
						prop = prop.slice(2)

				if isEvent
					config[prop] = cola._compileExpression(attr.value)
					removeAttrs ?= []
					removeAttrs.push(attrName)
		else
			prop = attrName
			if widgetType.attributes.$has(prop)
				config[prop] = attr.value
			else
				isEvent = widgetType.events.$has(prop)
				if not isEvent and prop.indexOf("on") is 0
					if widgetType.events.$has(prop.slice(2))
						isEvent = true
						prop = prop.slice(2)
						
						removeAttrs ?= []
						removeAttrs.push(attrName)

				if isEvent
					config[prop] = attr.value

	if removeAttrs
		dom.removeAttribute(attr) for attr in removeAttrs
	return config

_compileWidgetAttribute = (scope, dom, context) ->
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
				if p.charCodeAt(0) == 35
					importName = p.substring(1)
				else if p == "$type" and typeof v == "string" and v.charCodeAt(0) == 35 # `#`
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

cola._userDomCompiler.$.push((scope, dom, attr, context) ->
	return null if cola.util.userData(dom, cola.constants.DOM_ELEMENT_KEY)
	return null unless dom.nodeType is 1

	if dom.id
		jsonConfig = _findWidgetConfig(scope, dom.id)

	parentWidget = context.parentWidget
	tagName = dom.tagName

	configKey = dom.getAttribute("c-widget-config")
	if configKey
		dom.removeAttribute("c-widget-config")
		config = context.widgetConfigs?[configKey]
	else
		config = _compileWidgetAttribute(scope, dom, context)
		if not config
			widgetType = parentWidget?.childTagNames?[tagName]
			widgetType ?= WIDGET_TAGS_REGISTRY[tagName]
			if widgetType
				config = _compileWidgetDom(dom, widgetType)
	return null unless config or jsonConfig

	config ?= {}
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
	config.$constr = context.parentWidget = constr

	if cola.util.isCompatibleType(cola.AbstractLayer, constr) and config.lazyRender
		cola.util.userData(dom, cola.constants.DOM_SKIP_CHILDREN, true)

	return (scope, dom) ->
		context.parentWidget = parentWidget
		config.dom = dom
		oldScope = cola.currentScope
		cola.currentScope = scope
		try
			widget = cola.widget(config)
			return widget
		finally
			cola.currentScope = oldScope
)

cola.registerTypeResolver "widget", (config) ->
	return unless config
	if config.$constructor and cola.util.isSuperClass(cola.Widget, config.$constructor)
		return config.$constructor
	if config.$type
		return cola[cola.util.capitalize(config.$type)]
	return

cola.registerType("widget", "_default", cola.Widget)

cola.widget = (config, namespace, model) ->
	return null unless config
	if typeof config == "string"
		ele = window[config]
		return null unless ele
		if ele.nodeType
			widget = cola.util.userData(ele, cola.constants.DOM_ELEMENT_KEY)
			if model and widget._scope isnt model
				widget = null
			return if widget instanceof cola.Widget then widget else null
		else
			group = []
			for e in ele
				widget = cola.util.userData(e, cola.constants.DOM_ELEMENT_KEY)
				if widget instanceof cola.Widget and (not model or widget._scope is model)
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
		else if config.nodeType == 1
			widget = cola.util.userData(config, cola.constants.DOM_ELEMENT_KEY)
			if model and widget._scope isnt model
				widget = null
			return if widget instanceof cola.Widget then widget else null
		else
			constr = config.$constr or cola.resolveType(namespace or "widget", config, cola.Widget)
			if model and not config.scope
				config.scope = model
			return new constr(config)

cola.findWidget = (dom, type) ->
	if type and typeof type == "string"
		typeName = type
		type = WIDGET_TAGS_REGISTRY[typeName]
		type = cola.resolveType("widget", { $type: typeName }) unless type
		return null unless type

	if dom instanceof cola.Widget
		dom = dom.getDom()

	find = (win, dom, type) ->
		parentDom = dom.parentNode
		while parentDom
			dom = parentDom
			widget = cola.util.userData(dom, cola.constants.DOM_ELEMENT_KEY)
			if widget
				if not type or widget instanceof type
					return widget
			parentDom = dom.parentNode

		if win.parent
			try
				parentFrames = win.parent.jQuery("iframe,frame")
			catch
				# do nothing

			if parentFrames
				frame = null
				parentFrames.each () ->
					if @contentWindow is win
						frame = @
						return false

				if frame
					widget = find(win.parent, frame, type)
		return widget

	return find(window, dom, type)

cola.Model::widget = (config) -> cola.widget(config, null, @)

###
User Widget
###

WIDGET_TAGS_REGISTRY = {}

_extendWidget = (superCls, definition) ->
	cls = (config) ->
		if not cls.attributes._inited or not cls.events._inited
			cola.preprocessClass(cls)

		if definition.create then @on("create", definition.create)
		if definition.destroy then @on("destroy", definition.destroy)
		if definition.initDom then @on("initDom", (self, arg) => @initDom(arg.dom))
		if definition.refreshDom then @on("refreshDom", (self, arg) => @refreshDom(arg.dom))

		@on("attributeChange", (self, arg) =>
			attr = arg.attribute
			@_widgetModel.data._onDataMessage(["@" + attr], cola.constants.MESSAGE_PROPERTY_CHANGE, {})
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
	cls.parentWidget = definition.parentWidget if definition.parentWidget

	cls.attributes = definition.attributes or {}

	cls.attributes.widgetModel =
		readOnly: true
		getter: () -> @_widgetModel

	cls.attributes.template =
		readOnlyAfterCreate: true

	if definition.events then cls.events = definition.events

	if definition.template
		template = definition.template
		if typeof template is "string" and template.match(/^\#[\w\-\$]*$/)
			template = document.getElementById(template.substring(1))
			if template
				definition.template = template.innerHTML
				$fly(template).remove()

		cls.attributes.template =
			defaultValue: definition.template

	cls::_createDom = () ->
		if @_template
			dom = cola.xRender(@_template or {}, @_widgetModel)
			@_domCreated = true
			return dom
		else
			return superCls::_createDom.apply(@)

	cls::_initDom = (dom) ->
		superCls::_initDom.call(@, dom)
		template = @_template
		if template and not @_domCreated
			templateDom = @xRender(template)
			if templateDom
				for attr in templateDom.attributes
					attrName = attr.name
					if attrName isnt "style"
						dom.setAttribute(attrName, attr.value) if not dom.hasAttribute(attrName)

				for cssName of templateDom.style
					dom.style[cssName] = templateDom.style[cssName] if dom.style[cssName] is ""

				while templateDom.firstChild
					dom.appendChild(templateDom.firstChild)
		return

	cls::xRender = (template, context) -> cola.xRender(template, @_widgetModel, context)

	for prop, def of definition
		if definition.hasOwnProperty(prop) and typeof def is "function"
			cls::[prop] = def

	return cls

cola.defineWidget = (type, definition) ->
	if not cola.util.isSuperClass(cola.Widget, type)
		definition = type
		type = cola.TemplateWidget

	if definition
		type = _extendWidget(type, definition)

	tagName = type.tagName?.toUpperCase()
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

###
Template
###

TEMP_TEMPLATE = null

cola.TemplateSupport =
	_templateSupport: true

	destroy: () ->
		if @_templates
			delete @_templates[name] for name of @_templates
		return

	_parseTemplates: () ->
		return unless @_dom
		child = @_dom.firstChild
		while child
			if child.nodeName == "TEMPLATE"
				@_regTemplate(child)
			child = child.nextSibling
		@_regDefaultTempaltes()
		return

	_trimTemplate: (dom) ->
		child = dom.firstChild
		while child
			next = child.nextSibling
			if child.nodeType == 3
				if $.trim(child.nodeValue) == ""
					dom.removeChild(child)
			child = next
		return

	_regTemplate: (name, template) ->
		if arguments.length == 1
			template = name
			if template.nodeType
				name = template.getAttribute("name")
			else
				name = template.name
		@_templates ?= {}
		@_templates[name or "default"] = template
		return

	_regDefaultTempaltes: () ->
		for name, template of @constructor.TEMPLATES
			if @_templates?.hasOwnProperty(name) or !template
				continue
			@_regTemplate(name, template)
		return

	_getTemplate: (name = "default", defaultName) ->
		return null unless @_templates
		template = @_templates[name]
		if !template and defaultName
			name = defaultName
			template = @_templates[name]

		if template and !template._trimed
			if template.nodeType
				if template.nodeName == "TEMPLATE"
					if !template.firstChild
						html = template.innerHTML
						if html
							TEMP_TEMPLATE ?= document.createElement("div")
							template = TEMP_TEMPLATE
							template.innerHTML = html
					@_trimTemplate(template)
					if template.firstChild == template.lastChild
						template = template.firstChild
					else
						templs = []
						child = template.firstChild
						while child
							templs.push(child)
							child = child.nextSibling
						template = templs
				@_templates[name] = template
			else
				@_doms ?= {}
				template = $.xCreate(template, @_doms)
				if @_doms.widgetConfigs
					@_templateContext ?= {}
					if @_templateContext.widgetConfigs
						widgetConfigs = @_templateContext.widgetConfigs
						for k, c of @_doms.widgetConfigs
							widgetConfigs[k] = c
					else
						@_templateContext.widgetConfigs = @_doms.widgetConfigs
				@_templates[name] = template
			template._trimed = true

		return template

	_cloneTemplate: (template, supportMultiNodes) ->
		if template instanceof Array
			if supportMultiNodes and template.length > 1
				fragment = document.createDocumentFragment()
				fragment.appendChild(templ.cloneNode(true)) for templ in template
				return fragment
			else
				return template[0].cloneNode(true)
		else
			return template.cloneNode(true)

cola.DataWidgetMixin =
	_dataWidget: true

	_bindSetter: (bindStr) ->
		return if @_bind == bindStr

		if @_bindInfo
			bindInfo = @_bindInfo
			if @_watchingPaths
				for path in @_watchingPaths
					@_scope.data.unbind(path.join("."), @_bindProcessor)
			delete @_bindInfo

		@_bind = bindStr

		if bindStr and @_scope
			@_bindInfo = bindInfo = {}

			bindInfo.expression = expression = cola._compileExpression(bindStr)
			if expression.repeat or expression.setAlias
				throw new cola.Exception("Expression \"#{bindStr}\" must be a simple expression.")
			if (expression.type == "MemberExpression" or expression.type == "Identifier") and not expression.hasCallStatement and not expression.convertors
				bindInfo.isWriteable = true
				i = bindStr.lastIndexOf(".")
				if i > 0
					bindInfo.entityPath = bindStr.substring(0, i)
					bindInfo.property = bindStr.substring(i + 1)
				else
					bindInfo.entityPath = null
					bindInfo.property = bindStr

			if !@_bindProcessor
				@_bindProcessor = bindProcessor = {
					_processMessage: (bindingPath, path, type, arg) =>
						if @_filterDataMessage
							if not @_filterDataMessage(path, type, arg)
								return
						else
							unless cola.constants.MESSAGE_REFRESH <= type <= cola.constants.MESSAGE_CURRENT_CHANGE or @_watchingMoreMessage
								return

						if @_bindInfo.watchingMoreMessage
							cola.util.delay(@, "processMessage", 100, () ->
								if @_processDataMessage
									@_processDataMessage(@_bindInfo.watchingPaths[0],
										cola.constants.MESSAGE_REFRESH, {})
								else
									@_refreshBindingValue()
								return
							)
						else
							if @_processDataMessage
								@_processDataMessage(path, type, arg)
							else
								@_refreshBindingValue()
						return
				}

			paths = expression.paths
			if not paths and expression.hasCallStatement
				paths = ["**"]
				bindInfo.watchingMoreMessage = expression.hasCallStatement or expression.convertors

			if paths
				@_watchingPaths = paths
				for p, i in paths
					@_scope.data.bind(p, bindProcessor)
					paths[i] = p.split(".")

				if @_processDataMessage
					@_processDataMessage(null, cola.constants.MESSAGE_REFRESH, {})
				else
					@_refreshBindingValue()
		return

	destroy: () ->
		if @_watchingPaths
			for path in @_watchingPaths
				@_scope.data.unbind(path.join("."), @_bindProcessor)
		return

	readBindingValue: (dataCtx) ->
		return unless @_bindInfo?.expression
		dataCtx ?= {}
		return @_bindInfo.expression.evaluate(@_scope, "async", dataCtx)

	writeBindingValue: (value) ->
		return unless @_bindInfo?.expression
		if !@_bindInfo.isWriteable
			throw new cola.Exception("Expression \"#{@_bind}\" is not writable.")
		@_scope.set(@_bind, value)
		return

	getBindingProperty: () ->
		return unless @_bindInfo?.expression and @_bindInfo.isWriteable
		return @_scope.data.getProperty(@_bind)

	getBindingDataType: () ->
		return unless @_bindInfo?.expression and @_bindInfo.isWriteable
		return @_scope.data.getDataType(@_bind)

	_isRootOfTarget: (changedPath, targetPath) ->
		if !changedPath or !targetPath then return true
		if targetPath instanceof Array
			targetPaths = targetPath
			for targetPath in targetPaths
				isRoot = true
				for part, i in changedPath
					if part != targetPath[i]
						isRoot = false
						break
				if isRoot then return true
			return false
		else
			for part, i in changedPath
				if part != targetPath[i]
					return false
			return true

cola.DataItemsWidgetMixin =
	_dataItemsWidget: true
	_alias: "item"

	_bindSetter: (bindStr) ->
		return if @_bind == bindStr

		@_bind = bindStr
		@_itemsRetrieved = false

		delete @_simpleBindPath
		if bindStr
			expression = cola._compileExpression(bindStr, "repeat")
			if not expression.repeat
				throw new cola.Exception("Expression \"#{bindStr}\" must be a repeat expression.")
			@_alias = expression.alias

			if (expression.type is "MemberExpression" or expression.type is "Identifier") and not expression.hasCallStatement and not expression.convertors
				@_simpleBindPath = expression.paths[0]

		@_itemsScope.setExpression(expression)
		return

	constructor: () ->
		@_itemsScope = itemsScope = new cola.ItemsScope(@_scope)

		itemsScope.onItemsRefresh = (arg) => @_onItemsRefresh(arg)
		itemsScope.onItemRefresh = (arg) => @_onItemRefresh(arg)
		itemsScope.onItemInsert = (arg) => @_onItemInsert(arg)
		itemsScope.onItemRemove = (arg) => @_onItemRemove(arg)
		itemsScope.onItemsLoadingStart = (arg) => @_onItemsLoadingStart?(arg)
		itemsScope.onItemsLoadingEnd = (arg) => @_onItemsLoadingEnd?(arg)
		if @_onCurrentItemChange
			itemsScope.onCurrentItemChange = (arg) => @_onCurrentItemChange(arg)

	_getItems: () ->
		if !@_itemsRetrieved
			@_itemsRetrieved = true
			@_itemsScope.retrieveItems()
		return {
			items: @_itemsScope.items
			originItems: @_itemsScope.originItems
		}

	_getBindDataType: () ->
		items = @_getItems().originItems
		if items
			if items instanceof cola.EntityList
				dataType = items.dataType
			else if items instanceof Array and items.length
				item = items[0]
				if item and item instanceof cola.Entity
					dataType = item.dataType
		else if @_simpleBindPath
			dataType = @_scope.data.getDataType(@_simpleBindPath)
		return dataType