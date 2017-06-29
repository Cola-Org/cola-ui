
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
		child = @_dom.firstElementChild
		while child
			if child.nodeName == "TEMPLATE"
				@regTemplate(child)
			child = child.nextElementSibling
		@_regDefaultTempaltes()
		return

	_trimTemplate: (dom) ->
		child = dom.firstChild
		while child
			next = child.nextSibling
			if child.nodeType == 3	# TEXT
				if $.trim(child.nodeValue) == ""
					dom.removeChild(child)
			child = next
		return

	regTemplate: (name, template) ->
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
			@regTemplate(name, template)
		return

	trimTemplate: (template) ->
		if template.nodeType
			if template.nodeName == "TEMPLATE"
				if not template.firstChild
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
		template._trimed = true
		return template

	getTemplate: (name = "default", defaultName) ->
		return null unless @_templates
		template = @_templates[name]
		if not template and defaultName
			name = defaultName
			template = @_templates[name]

		if not template and typeof name is "string" and name.match(/^\#[\w\-\$]*$/)
			template = cola.util.getGlobalTemplate(name)

		if template and not template._trimed
			template = @trimTemplate(template)

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
		return if @_bind is bindStr

		if @_bindInfo
			bindInfo = @_bindInfo
			if @_watchingPaths
				for path in @_watchingPaths
					@_scope.data.unbind(path.join("."), @_bindProcessor)
			delete @_bindInfo

		@_bind = bindStr

		if bindStr and @_scope
			@_bindInfo = bindInfo = {}

			bindInfo.expression = expression = cola._compileExpression(@_scope, bindStr)
			bindInfo.writeable = expression.writeable

			if expression.repeat or expression.setAlias
				throw new cola.Exception("Expression \"#{bindStr}\" must be a simple expression.")
			if bindInfo.writeable
				i = bindStr.lastIndexOf(".")
				if i > 0
					bindInfo.entityPath = bindStr.substring(0, i)
					bindInfo.property = bindStr.substring(i + 1)
				else
					bindInfo.entityPath = null
					bindInfo.property = bindStr

			if not @_bindProcessor
				@_bindProcessor = {
					processMessage: (bindingPath, path, type, arg) =>
						if @_filterDataMessage
							if not @_filterDataMessage(path, type, arg)
								return
						else
							unless cola.constants.MESSAGE_REFRESH <= type <= cola.constants.MESSAGE_CURRENT_CHANGE or @_watchingMoreMessage
								return

						if @_bindInfo.watchingMoreMessage
							cola.util.delay(@, "processMessage", 100, () ->
								if @_processDataMessage
									@_processDataMessage(@_bindInfo.watchingPaths[0], cola.constants.MESSAGE_REFRESH, {})
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
			bindInfo.watchingMoreMessage = not paths and expression.hasComplexStatement and not expression.hasDefinedPath

			if paths
				@_watchingPaths = watchingPaths = []
				for p, i in paths
					@_scope.data.bind(p, @_bindProcessor)
					watchingPaths[i] = p.split(".")

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
		if !@_bindInfo.writeable
			throw new cola.Exception("Expression \"#{@_bind}\" is not writable.")
		@_scope.set(@_bind, value)
		return

	getBindingProperty: () ->
		return unless @_bindInfo?.expression and @_bindInfo.writeable
		return @_scope.data.getProperty(@_bind)

	getBindingDataType: () ->
		return unless @_bindInfo?.expression and @_bindInfo.writeable
		return @_scope.data.getDataType(@_bind)

cola.DataItemsWidgetMixin =
	_dataItemsWidget: true
	_alias: "item"

	_bindSetter: (bindStr) ->
		return if @_bind == bindStr

		@_bind = bindStr
		@_itemsRetrieved = false

		if bindStr
			expression = cola._compileExpression(@_scope, bindStr, "repeat")
			if not expression.repeat
				throw new cola.Exception("Expression \"#{bindStr}\" must be a repeat expression.")
			@_alias = expression.alias

			if expression.writeable
				@_simpleBindPath = expression.writeablePath

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
		if not @_itemsRetrieved
			@_itemsRetrieved = true
			@_itemsScope.retrieveData()
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