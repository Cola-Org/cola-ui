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
		$dom.attr("widget-config", configKey)
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

cola._userDomCompiler.widget = () -> return

ALIAS_REGEXP = new RegExp("\\$default", "g")

_findWidgetConfig = (scope, name) ->
	while scope
		widgetConfig = scope._widgetConfig?[name]
		if widgetConfig then break
		scope = scope.parent
	return widgetConfig

cola._userDomCompiler.$.push((scope, dom, context) ->
	return null if cola.util.userData(dom, cola.constants.DOM_ELEMENT_KEY)

	if dom.id
		jsonConfig = _findWidgetConfig(scope, dom.id)

	configKey = dom.getAttribute("widget-config")
	if configKey
		dom.removeAttribute("widget-config")
		config = context.widgetConfigs?[configKey]
	else
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

	return null unless config or jsonConfig

	config ?= {}
	if jsonConfig
		config[k] = v for k, v of jsonConfig

	if typeof config is "string"
		config = {
			$type: config
		}
	oldParentConstr = context.constr
	constr = cola.resolveType((oldParentConstr?.CHILDREN_TYPE_NAMESPACE or "widget"), config, cola.Widget)
	config.$constr = context.constr = constr

	if cola.util.isCompatibleType(cola.AbstractLayer, constr) and config.lazyRender
		cola.util.userData(dom, cola.constants.DOM_SKIP_CHILDREN, true)

	return (scope, dom) ->
		context.constr = oldParentConstr
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
	return unless config and config.$type
	return cola[cola.util.capitalize(config.$type)]

cola.registerType("widget", "_default", cola.Widget)

cola.widget = (config, namespace) ->
	return null unless config
	if typeof config == "string"
		ele = window[config]
		return null unless ele
		if ele.nodeType
			widget = cola.util.userData(ele, cola.constants.DOM_ELEMENT_KEY)
			return if widget instanceof cola.Widget then widget else null
		else
			group = []
			for e in ele
				widget = cola.util.userData(e, cola.constants.DOM_ELEMENT_KEY)
				group.push(widget) if widget instanceof cola.Widget
			return if group.length then cola.Element.createGroup(group) else null
	else
		if config instanceof Array
			group = []
			for c in config
				group.push(cola.widget(c))
			return cola.Element.createGroup(group)
		else if config.nodeType == 1
			widget = cola.util.userData(config, cola.constants.DOM_ELEMENT_KEY)
			return if widget instanceof cola.Widget then widget else null
		else
			constr = config.$constr or cola.resolveType(namespace or "widget", config, cola.Widget)
			return new constr(config)

cola.findWidget = (dom, type) ->
	if type and typeof type == "string"
		type = cola.resolveType("widget", {$type: type})
		return null unless type

	while dom
		widget = cola.util.userData(dom, cola.constants.DOM_ELEMENT_KEY)
		if widget
			if not type or widget instanceof type
				return widget
		dom = dom.parentNode
	return null

TEMP_TEMPLATE = null

cola.TemplateSupport =
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
	_bindSetter: (bindStr) ->
		return if @_bindStr == bindStr

		if @_bindInfo
			bindInfo = @_bindInfo
			if @_watchingPaths
				for path in @_watchingPaths
					@_scope.data.unbind(path.join("."), @_bindProcessor)
			delete @_bindInfo

		@_bindStr = bindStr

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

			path = expression.path
			if !path
				if expression.hasCallStatement
					path = "**"
					bindInfo.watchingMoreMessage = expression.hasCallStatement or expression.convertors
			else
				if typeof expression.path == "string"
					bindInfo.expressionPaths = [expression.path.split(".")]
				if expression.path instanceof Array
					paths = []
					for p in expression.path
						paths.push(p.split("."))
					bindInfo.expressionPaths = paths

			if path
				if typeof path == "string"
					paths = [path]
				else
					paths = path

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

	_readBindingValue: (dataCtx) ->
		return unless @_bindInfo?.expression
		dataCtx ?= {}
		return @_bindInfo.expression.evaluate(@_scope, "async", dataCtx)

	_writeBindingValue: (value) ->
		return unless @_bindInfo?.expression
		if !@_bindInfo.isWriteable
			throw new cola.Exception("Expression \"#{@_bindStr}\" is not writable.")
		@_scope.set(@_bindStr, value)
		return

	_getBindingProperty: () ->
		return unless @_bindInfo?.expression and @_bindInfo.isWriteable
		return @_scope.data.getProperty(@_bindStr)

	_getBindingDataType: () ->
		return unless @_bindInfo?.expression and @_bindInfo.isWriteable
		return @_scope.data.getDataType(@_bindStr)

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
	_alias: "item"

	_bindSetter: (bindStr) ->
		return if @_bindStr == bindStr

		@_bindStr = bindStr
		@_itemsRetrieved = false

		if bindStr and @_scope
			expression = cola._compileExpression(bindStr, "repeat")
			if !expression.repeat
				throw new cola.Exception("Expression \"#{bindStr}\" must be a repeat expression.")
			@_alias = expression.alias
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

_getEntityId = cola.Entity._getEntityId

class cola.ItemsView extends cola.Widget
	@ATTRIBUTES:
		allowNoCurrent:
			type:"boolean"
			defaultValue: true
		currentItem:
			getter: () ->
				if @_currentItemDom
					item = cola.util.userData(@_currentItemDom, "item")
				return item
			setter: (currentItem) ->
				if currentItem
					currentItemDom = @_itemDomMap[_getEntityId(currentItem)]
				@_setCurrentItemDom(currentItemDom)
				return

		highlightCurrentItem:
			type: "boolean"

	@EVENTS:
		getItemTemplate: null
		renderItem: null
		itemClick: null
		itemDoubleClick: null
		itemPress: null

	_doSet: (attr, attrConfig, value) ->
		if attrConfig?.refreshItems
			attrConfig.refreshDom = true
			@_refreshItemsScheduled = true
		return super(attr, attrConfig, value)

	_createDom: ()->
		@_doms ?= {}
		dom = $.xCreate({
			tagName: "div"
			content:
				tagName: "ul"
				contextKey: "itemsWrapper"
		}, @_doms)
		return dom

	_parseDom: (dom)->
		return unless dom
		@_doms ?= {}
		child = dom.firstChild
		while child
			next = child.nextSibling
			nodeName = child.nodeName
			if !itemsWrapper and nodeName == "UL"
				itemsWrapper = child
			else if nodeName == "TEMPLATE"
				@_regTemplate(child)
			else
				dom.removeChild(child)
			child = next

		if !itemsWrapper
			itemsWrapper = document.createElement("ul")
			dom.appendChild(itemsWrapper)
		@_doms.itemsWrapper = itemsWrapper
		return

	_initDom: (dom) ->
		@_regDefaultTempaltes()
		@_templateContext ?= {}

		$itemsWrapper = $fly(@_doms.itemsWrapper)
		$itemsWrapper.addClass("items")
		.delegate(".item", "click", (evt) => @_onItemClick(evt))
		.delegate(".item", "dblclick", (evt) => @_onItemDoubleClick(evt))

		if @_onItemsWrapperScroll
			$itemsWrapper.on("scroll", (evt) =>
				@_onItemsWrapperScroll(evt)
				return true
			)

		@_$dom = $(dom)
		return

	getItems: () ->
		return @_realItems

	_doRefreshDom: ()->
		return unless @_dom
		super()
		if @_refreshItemsScheduled
			delete @_refreshItemsScheduled
			@_refreshItems()
		return

	_getItemType: (item) ->
		type = @fire("getItemTemplate", @, { item: item })
		return type if type

		if item?.isDataWrapper
			return item._data?._itemType or "default"
		else
			return item._itemType or "default"

	_onItemsRefresh: () ->
		return @_refreshItems()

	_onItemInsert: (arg) ->
		if @_realItems == @_realOriginItems
			@_refreshEmptyItemDom()

			item = arg.entity
			itemType = @_getItemType(item)
			itemsWrapper = @_doms.itemsWrapper
			insertMode = arg.insertMode
			if !insertMode or insertMode == "end"
				itemDom = @_createNewItem(itemType, item)
				@_refreshItemDom(itemDom, item)
				$fly(itemsWrapper).append(itemDom)
			else if insertMode == "begin"
				itemDom = @_createNewItem(itemType, item)
				@_refreshItemDom(itemDom, item)
				$fly(itemsWrapper.firstChild).before(itemDom)
			else if @_itemDomMap
				refEntityId = _getEntityId(arg.refEntity)
				if refEntityId
					refDom = @_itemDomMap[refEntityId]?
					if refDom
						itemDom = @_createNewItem(itemType, item)
						@_refreshItemDom(itemDom, item)
						if insertMode == "before"
							$fly(refDom).before(itemDom)
						else
							$fly(refDom).after(itemDom)
		else
			@_refreshItems()
		return

	_onItemRemove: (arg) ->
		itemId = _getEntityId(arg.entity)
		if itemId
			arg.itemsScope.unregItemScope(itemId)

			itemDom = @_itemDomMap[itemId]
			delete @_itemDomMap[itemId]
			if itemDom
				$fly(itemDom).remove()
				@_currentItemDom = null if itemDom == @_currentItemDom

		@_refreshEmptyItemDom()
		return

	_showLoadingTip: () ->
		$loaderContainer = @_$loaderContainer
		if not $loaderContainer
			$itemsWrapper = $fly(@_doms.itemsWrapper)
			$itemsWrapper.xAppend(
				class: "loader-container protected"
				content:
					class: "ui loader"
			)
			@_$loaderContainer = $loaderContainer = $itemsWrapper.find(">.loader-container");
		else
			$loaderContainer.remove()
			$loaderContainer.appendTo(@_doms.itemsWrapper)

		$loaderContainer.addClass("active")
		return

	_hideLoadingTip: () ->
		@_$loaderContainer?.removeClass("active")
		return

	_onItemsLoadingStart: (arg) ->
		@_showLoadingTip()
		return

	_onItemsLoadingEnd: (arg) ->
		@_hideLoadingTip()
		return

	_setCurrentItemDom: (currentItemDom) ->
		if @_currentItemDom
			$fly(@_currentItemDom).removeClass(cola.constants.COLLECTION_CURRENT_CLASS)
		@_currentItemDom = currentItemDom
		if currentItemDom and @_highlightCurrentItem
			$fly(currentItemDom).addClass(cola.constants.COLLECTION_CURRENT_CLASS)
		return

	_onCurrentItemChange: (arg) ->
		if arg.current and @_itemDomMap
			itemId = _getEntityId(arg.current)
			if itemId
				currentItemDom = @_itemDomMap[itemId]
				if not currentItemDom
					@_refreshItems()
					return
		@_setCurrentItemDom(currentItemDom)
		return

	_refreshItems: () ->
		if !@_dom
			@_refreshItemsScheduled = true
			return
		@_doRefreshItems(@_doms.itemsWrapper)

	_doRefreshItems: (itemsWrapper) ->
		@_itemDomMap ?= {}

		ret = @_getItems()
		items = ret.items
		#		isSameItems = (@_realOriginItems or @_realItems) is (ret.originItems or items)
		@_realOriginItems = ret.originItems

		if @_convertItems and items
			items = @_convertItems(items)
		@_realItems = items

		if items
			documentFragment = null
			nextItemDom = itemsWrapper.firstChild
			currentItem = items.current

			if @_currentItemDom
				if !currentItem
					currentItem = cola.util.userData(@_currentItemDom, "item")
				$fly(@_currentItemDom).removeClass(cola.constants.COLLECTION_CURRENT_CLASS)
				delete @_currentItemDom
			@_currentItem = currentItem

			@_itemsScope.resetItemScopeMap()

			@_refreshEmptyItemDom?()

			lastItem = null
			cola.each(items, (item) =>
				lastItem = item
				itemType = @_getItemType(item)

				if nextItemDom
					while nextItemDom
						if nextItemDom._itemType == itemType
							break
						else
							_nextItemDom = nextItemDom.nextSibling
							if not cola.util.hasClass(nextItemDom, "protected")
								itemsWrapper.removeChild(nextItemDom)
							nextItemDom = _nextItemDom
					itemDom = nextItemDom
					if nextItemDom
						nextItemDom = nextItemDom.nextSibling
				else
					itemDom = null

				if itemDom
					@_refreshItemDom(itemDom, item)
				else
					itemDom = @_createNewItem(itemType, item)
					@_refreshItemDom(itemDom, item)
					documentFragment ?= document.createDocumentFragment()
					documentFragment.appendChild(itemDom)
				return
			, { currentPage: @_currentPageOnly })

			if nextItemDom
				itemDom = nextItemDom
				while itemDom
					nextItemDom = itemDom.nextSibling
					if not cola.util.hasClass(itemDom, "protected")
						itemsWrapper.removeChild(itemDom)
						delete @_itemDomMap[itemDom._itemId] if itemDom._itemId
					itemDom = nextItemDom

			delete @_currentItem
			if @_currentItemDom and @_highlightCurrentItem
				$fly(@_currentItemDom).addClass(cola.constants.COLLECTION_CURRENT_CLASS)

			if documentFragment
				itemsWrapper.appendChild(documentFragment)

			if not @_currentPageOnly and @_autoLoadPage and (items is @_realOriginItems or not @_realOriginItems) and items instanceof cola.EntityList and items.pageSize > 0
				currentPageNo = lastItem?._page?.pageNo
				if currentPageNo and (currentPageNo < items.pageCount or not items.pageCountDetermined)
					if not @_loadingNextPage and itemsWrapper.scrollHeight == itemsWrapper.clientHeight and itemsWrapper.scrollTop = 0
						@_showLoadingTip()
						items.loadPage(currentPageNo + 1, () =>
							@_hideLoadingTip()
							return
						)
					else
						$fly(itemsWrapper).xAppend(
							class: "tail-padding"
							content:
								class: "ui loader"
						)
		return


	_refreshItemDom: (itemDom, item, parentScope = @_itemsScope) ->
		if item == @_currentItem
			@_currentItemDom = itemDom
		else if !@_currentItemDom and !@_allowNoCurrent
			@_currentItemDom = itemDom

		if item?.isDataWrapper
			originItem = item
			item = item._data
		else
			originItem = item

		if typeof item == "object"
			itemId = _getEntityId(item)

		alias = item._alias
		if !alias
			alias = originItem?._alias
			alias ?= @_alias
		@_templateContext.defaultPath = @_getDefaultBindPath?(originItem) or alias

		itemScope = cola.util.userData(itemDom, "scope")
		oldScope = cola.currentScope
		try
			if !itemScope
				itemScope = new cola.ItemScope(parentScope, alias)
				cola.currentScope = itemScope
				itemScope.data.setTargetData(item, true)
				cola.util.userData(itemDom, "scope", itemScope)
				cola.util.userData(itemDom, "item", originItem)
				@_doRefreshItemDom?(itemDom, item, itemScope)
				cola.xRender(itemDom, itemScope, @_templateContext)
			else
				cola.currentScope = itemScope
				if itemScope.data.getTargetData() != item
					delete @_itemDomMap[itemDom._itemId] if itemDom._itemId
					if itemScope.data.alias != alias
						throw new cola.Exception("Repeat alias mismatch. Expect \"#{itemScope.alias}\" but \"#{alias}\".")
					cola.util.userData(itemDom, "item", originItem)
					itemScope.data.setTargetData(item)
				@_doRefreshItemDom?(itemDom, item, itemScope)
			parentScope.regItemScope(itemId, itemScope) if itemId

			if @getListeners("renderItem")
				@fire("renderItem", @, {
					item: originItem
					dom: itemDom
					scope: itemScope
				})
		finally
			cola.currentScope = oldScope

		if itemId
			itemDom._itemId = itemId
			@_itemDomMap[itemId] = itemDom
		return itemScope

	refreshItem: (item) ->
		itemId = _getEntityId(item)
		itemDom = @_itemDomMap[itemId]
		if itemDom
			@_doRefreshItemDom?(itemDom, item, @_itemsScope)
		return

	_onItemRefresh: (arg) ->
		item = arg.entity
		if typeof item == "object"
			@refreshItem(item)
		return

	_findItemDom: (target) ->
		while target
			if target._itemType
				itemDom = target
				break
			target = target.parentNode
		return itemDom

	_onItemClick: (evt) ->
		itemDom = evt.currentTarget
		return unless itemDom

		item = cola.util.userData(itemDom, "item")
		if itemDom._itemType == "default"
			if item
				if @_changeCurrentItem and item._parent instanceof cola.EntityList
					item._parent.setCurrent(item)
				else
					@_setCurrentItemDom(itemDom)

		@fire("itemClick", @, {
			event: evt
			item: item
			dom: itemDom
		})
		return

	_onItemDoubleClick: (evt) ->
		itemDom = evt.currentTarget
		return unless itemDom
		item = cola.util.userData(itemDom, "item")
		@fire("itemDoubleClick", @, {
			event: evt
			item: item
			dom: itemDom
		})
		return

	_bindEvent: (eventName) ->
		if eventName == "itemPress"
			@_on("press", (self, arg) =>
				itemDom = @_findItemDom(arg.event.target)
				if itemDom
					arg.itemDom = itemDom
					arg.item = cola.util.userData(itemDom, "item")
					@fire("itemPress", list, arg)
				return
			)
			return
		else
			return super(eventName)

cola.Element.mixin(cola.ItemsView, cola.TemplateSupport)
cola.Element.mixin(cola.ItemsView, cola.DataItemsWidgetMixin)