###
BindingFeature
###

class cola._BindingFeature
	init: () -> return

class cola._ExpressionFeature extends cola._BindingFeature
	constructor: (@expression) ->
		if @expression
			@isStatic = @expression.isStatic
			@isDyna = @expression.isDyna
			@paths = @expression.paths or []
			if not @paths.length and @expression.hasCallStatement
				@paths = ["**"]
				if not @isStatic then @delay = true
				@watchingMoreMessage = not @expression.hasDefinedPath

	evaluate: (domBinding, dynaExpressionOnly, dataCtx = {}, loadMode = "async") ->
		scope = domBinding.scope

		dataCtx.vars ?= {}
		dataCtx.vars.$dom = domBinding.dom

		if dynaExpressionOnly and @dynaExpression
			result = @dynaExpression.evaluate(scope, loadMode, dataCtx)
		else
			result = @expression.evaluate(scope, loadMode, dataCtx)

			if @isDyna and dataCtx.dynaExpression
				@dynaExpression = dataCtx.dynaExpression
				if @dynaExpression.raw isnt @dynaExpressionStr
					@dynaExpressionStr = @dynaExpression.raw

				if not @ignoreBind
					if @dynaPaths
						for path in @dynaPaths
							domBinding.unbind(path, @)

					paths = @dynaExpression.paths
					if paths
						for path in paths
							if @paths.indexOf(path) < 0
								if not @dynaPaths
									@dynaPaths = [path]
								else
									@dynaPaths.push(path)
								domBinding.bind(path, @)
		return result

	refresh: (domBinding, force, dynaExpressionOnly, dataCtx = {}) ->
		return unless @_refresh
		if @delay and not force
			cola.util.delay(domBinding, "refresh", 100, () =>
				@_refresh(domBinding, dynaExpressionOnly, dataCtx)
				if @isStatic and not dataCtx.unloaded
					@disabled = true
				return
			)
		else
			@_refresh(domBinding, dynaExpressionOnly, dataCtx)
			if @isStatic and not dataCtx.unloaded
				@disabled = true
		return

class cola._AliasFeature extends cola._ExpressionFeature
	ignoreBind: true

	constructor: (expression) ->
		super(expression)
		@alias = expression.alias

	init: (domBinding) ->
		domBinding.scope = new cola.AliasScope(domBinding.scope, @expression)
		domBinding.subScopeCreated = true
		return

	_refresh: (domBinding, dynaExpressionOnly, dataCtx)->
		data = @evaluate(domBinding, dynaExpressionOnly, dataCtx)
		domBinding.scope.data.setTargetData(data)
		return

class cola._RepeatFeature extends cola._ExpressionFeature
	ignoreBind: true

	constructor: (expression) ->
		super(expression)
		@alias = expression.alias

	init: (domBinding) ->
		domBinding.scope = scope = new cola.ItemsScope(domBinding.scope, if @isDyna then null else @expression)

		scope.onItemsRefresh = () =>
			@onItemsRefresh(domBinding)
			return

		scope.onCurrentItemChange = (arg) ->
			$fly(domBinding.currentItemDom).removeClass(cola.constants.COLLECTION_CURRENT_CLASS) if domBinding.currentItemDom
			if arg.current and domBinding.itemDomBindingMap
				itemId = cola.Entity._getEntityId(arg.current)
				if itemId
					currentItemDomBinding = domBinding.itemDomBindingMap[itemId]
					if (currentItemDomBinding)
						currentItemDom = currentItemDomBinding.dom
						$fly(currentItemDom).addClass(cola.constants.COLLECTION_CURRENT_CLASS)
					else
						@onItemsRefresh(domBinding)
						return
			domBinding.currentItemDom = currentItemDom
			return

		scope.onItemInsert = (arg) =>
			headDom = domBinding.dom
			tailDom = cola.util.userData(headDom, cola.constants.REPEAT_TAIL_KEY)
			templateDom = cola.util.userData(headDom, cola.constants.REPEAT_TEMPLATE_KEY)

			entity = arg.entity
			itemsScope = arg.itemsScope
			insertMode = arg.insertMode
			if not insertMode or insertMode == "end"
				index = arg.entityList.entityCount
			else if insertMode == "begin"
				index = 1
			else if insertMode == "before"
				refItemScope = itemsScope.getItemScope(arg.refEntity)
				index = refItemScope?.data.getIndex()
			else if insertMode == "after"
				refItemScope = itemsScope.getItemScope(arg.refEntity)
				index = refItemScope?.data.getIndex() + 1

			itemDom = @createNewItem(domBinding, templateDom, domBinding.scope, entity, index)

			if !insertMode or insertMode == "end"
				$fly(tailDom).before(itemDom)
			else
				if insertMode == "begin"
					$fly(headDom).after(itemDom)
				else if domBinding.itemDomBindingMap
					refEntityId = cola.Entity._getEntityId(arg.refEntity)
					if refEntityId
						refDom = domBinding.itemDomBindingMap[refEntityId]?.dom
						if refDom
							if insertMode == "before"
								$fly(refDom).before(itemDom)
							else
								$fly(refDom).after(itemDom)

				for id, iScope of itemsScope.itemScopeMap
					i = iScope.data.getIndex()
					if i >= index and iScope.data.getTargetData() isnt entity
						iScope.data.setIndex(i + 1)
			return

		scope.onItemRemove = (arg) ->
			entity = arg.entity
			itemsScope = arg.itemsScope

			itemId = cola.Entity._getEntityId(entity)
			if itemId
				itemScope = itemsScope.getItemScope(entity)

				itemDomBinding = domBinding.itemDomBindingMap[itemId]
				if itemDomBinding
					itemsScope.unregItemScope(itemId)
					itemDomBinding.remove()
					delete domBinding.currentItemDom if itemDomBinding.dom == domBinding.currentItemDom

				if itemScope
					index = itemScope.data.getIndex()
					if index < arg.entityList.entityCount
						for id, iScope of itemsScope.itemScopeMap
							i = iScope.data.getIndex()
							if i > index then iScope.data.setIndex(i - 1)
			return

		domBinding.subScopeCreated = true
		return

	_refresh: (domBinding, dynaExpressionOnly, dataCtx) ->
		if @isDyna and not dynaExpressionOnly
			@evaluate(domBinding, dynaExpressionOnly, dataCtx)
			domBinding.scope.setExpression(@dynaExpression)

		domBinding.scope.retrieveData()
		domBinding.scope.refreshItems()
		return

	onItemsRefresh: (domBinding) ->
		scope = domBinding.scope

		items = scope.items
		originItems = scope.originItems

		if items and not (items instanceof cola.EntityList) and not (items instanceof Array)
			throw new cola.Exception("Expression \"#{@expression}\" must bind to EntityList or Array.")

		if items isnt domBinding.items or (items and items.timestamp isnt domBinding.timestamp)
			domBinding.items = items
			domBinding.timestamp = items?.timestamp or 0

			headDom = domBinding.dom
			tailDom = cola.util.userData(headDom, cola.constants.REPEAT_TAIL_KEY)
			templateDom = cola.util.userData(headDom, cola.constants.REPEAT_TEMPLATE_KEY)
			if not tailDom
				tailDom = document.createComment("Repeat Tail |" + headDom.nodeValue.split("|")[1])
				$fly(headDom).after(tailDom)
				cola.util.userData(headDom, cola.constants.REPEAT_TAIL_KEY, tailDom)
			currentDom = headDom

			documentFragment = null
			if items
				domBinding.itemDomBindingMap = {}
				scope.resetItemScopeMap()

				$fly(domBinding.currentItemDom).removeClass(cola.constants.COLLECTION_CURRENT_CLASS) if domBinding.currentItemDom
				cola.each items, (item, i) =>
					if not item? then return

					itemDom = currentDom.nextSibling
					if itemDom is tailDom then itemDom = null

					if itemDom
						itemDomBinding = cola.util.userData(itemDom, cola.constants.DOM_BINDING_KEY)
						itemScope = itemDomBinding.scope
						if typeof item is "object"
							itemId = cola.Entity._getEntityId(item)
						else
							itemId = cola.uniqueId()
						scope.regItemScope(itemId, itemScope)
						itemDomBinding.itemId = itemId
						domBinding.itemDomBindingMap[itemId] = itemDomBinding
						itemScope.data.setTargetData(item)
						itemScope.data.setIndex(i + 1)
					else
						itemDom = @createNewItem(domBinding, templateDom, scope, item, i + 1)
						$fly(tailDom).before(itemDom)

					if item is (items.current or originItems?.current)
						$fly(itemDom).addClass(cola.constants.COLLECTION_CURRENT_CLASS)
						domBinding.currentItemDom = itemDom

					currentDom = itemDom
					return

			if not documentFragment
				itemDom = currentDom.nextSibling
				while itemDom and itemDom isnt tailDom
					currentDom = itemDom
					itemDom = currentDom.nextSibling
					$fly(currentDom).remove()
			else
				$fly(tailDom).before(documentFragment)
		return

	createNewItem: (repeatDomBinding, templateDom, scope, item, index) ->
		itemScope = new cola.ItemScope(scope, @alias)
		itemScope.data.setTargetData(item, true)
		itemScope.data.setIndex(index, true)

		itemDom = templateDom.cloneNode(true)

		@deepCloneNodeData(itemDom, itemScope, false)
		templateDomBinding = cola.util.userData(templateDom, cola.constants.DOM_BINDING_KEY)
		domBinding = templateDomBinding.clone(itemDom, itemScope)
		@refreshItemDomBinding(itemDom, itemScope)

		if typeof item is "object"
			itemId = cola.Entity._getEntityId(item)
		else
			itemId = cola.uniqueId()
		scope.regItemScope(itemId, itemScope)
		domBinding.itemId = itemId
		repeatDomBinding.itemDomBindingMap[itemId] = domBinding
		return itemDom

	deepCloneNodeData: (node, scope, cloneDomBinding) ->
		store = cola.util.userData(node)
		if store
			clonedStore = {}
			for k, v of store
				if k is cola.constants.DOM_BINDING_KEY
					if cloneDomBinding
						v = v.clone(node, scope)
				else if k.substring(0, 2) is "__"
					continue
				clonedStore[k] = v
			cola.util.userData(node, clonedStore)

		child = node.firstChild
		while child
			if child.nodeType isnt 3 and not child.hasAttribute?(cola.constants.IGNORE_DIRECTIVE)
				@deepCloneNodeData(child, scope, true)
			child = child.nextSibling
		return

	refreshItemDomBinding: (dom, itemScope) ->
		domBinding = cola.util.userData(dom, cola.constants.DOM_BINDING_KEY)
		if domBinding
			domBinding.refresh()
			itemScope = domBinding.subScope or domBinding.scope
			if domBinding instanceof cola._RepeatDomBinding
				currentDom = cola.util.userData(domBinding.dom, cola.constants.REPEAT_TAIL_KEY)

		child = dom.firstChild
		while child
			if child.nodeType isnt 3 and !child.hasAttribute?(cola.constants.IGNORE_DIRECTIVE)
				child = @refreshItemDomBinding(child, itemScope)
			child = child.nextSibling

		initializers = cola.util.userData(dom, cola.constants.DOM_INITIALIZER_KEY)
		if initializers
			initializer(itemScope, dom) for initializer in initializers
			cola.util.removeUserData(dom, cola.constants.DOM_INITIALIZER_KEY)
		return currentDom or dom

class cola._WatchFeature extends cola._BindingFeature
	constructor: (@action, @paths) ->
		@watchingMoreMessage = true

	processMessage: (domBinding, bindingPath)->
		if not @isDyna or @dynaPaths?.indexOf(bindingPath) >= 0
			@refresh(domBinding)
		return

	refresh: (domBinding) ->
		action = domBinding.scope.action(@action)
		if not action
			throw new cola.Exception("No action named \"#{@action}\" found.")
		action(domBinding.dom, domBinding.scope)
		return

class cola._EventFeature extends cola._ExpressionFeature
	ignoreBind: true

	constructor: (@expression, @event) ->

	init: (domBinding) ->
		domBinding.$dom.on(@event, (evt) =>
			oldScope = cola.currentScope
			cola.currentScope = domBinding.scope
			try
				return @evaluate(domBinding, false, {
					vars:
						$event: evt
				}, "never")
			finally
				cola.currentScope = oldScope
		)
		return

class cola._DomFeature extends cola._ExpressionFeature
	writeBack: (domBinding, value) ->
		return unless @expression?.writeable
		paths = if @isDyna then @dynaPaths else @paths
		if paths and paths.length is 1
			@ignoreMessage = true
			domBinding.scope.set(paths[0], value)
			@ignoreMessage = false
		return

	processMessage: (domBinding, bindingPath, path, type, arg)->
		if cola.constants.MESSAGE_REFRESH <= type <= cola.constants.MESSAGE_CURRENT_CHANGE or @watchingMoreMessage
			@refresh(domBinding, false, @dynaPaths?.indexOf(bindingPath) >= 0)
		return

	_refresh: (domBinding, dynaExpressionOnly, dataCtx)->
		return if @ignoreMessage
		value = @evaluate(domBinding, dynaExpressionOnly, dataCtx)
		@_doRender(domBinding, value)
		return

class cola._DomAttrFeature extends cola._DomFeature
	constructor: (expression, @attr) ->
		super(expression)

	_doRender: (domBinding, value) ->
		if value instanceof Date
			defaultDateFormat = cola.setting("defaultDateFormat")
			if defaultDateFormat
				value = cola.defaultAction.formatDate(value, defaultDateFormat)

		attr = @attr
		if attr == "text"
			cola.util.setText(domBinding.dom, if value? then value else "")
		else if attr == "html"
			domBinding.$dom.html(if value? then value else "")
		else
			domBinding.$dom.attr(attr, if value? then value else "")
		return

class cola._DomStylePropFeature extends cola._DomFeature
	constructor: (expression, @prop) ->
		super(expression)

	_doRender: (domBinding, value) ->
		domBinding.$dom.css(@prop, value)
		return

class cola._DomClassFeature extends cola._DomFeature
	constructor: (expression) ->
		super(expression)

	_doRender: (domBinding, value) ->
		if @_lastClassName
			domBinding.$dom.removeClass(@_lastClassName)
		if value
			domBinding.$dom.addClass(value)
			@_lastClassName = value
		return

class cola._DomToggleClassFeature extends cola._DomFeature
	constructor: (expression, @className) ->
		super(expression)

	_doRender: (domBinding, value) ->
		domBinding.$dom[if value then "addClass" else "removeClass"](@className)
		return

class cola._TextBoxFeature extends cola._DomFeature
	init: (domBinding) ->
		feature = @
		domBinding.$dom.on "input", () ->
			feature.writeBack(domBinding, @value)
			return
		super()
		return

	_doRender: (domBinding, value)->
		domBinding.dom.value = if value? then value else ""
		return

class cola._CheckboxFeature extends cola._DomFeature
	init: (domBinding) ->
		feature = @
		domBinding.$dom.on("click", () ->
			feature.writeBack(domBinding, @checked)
			return
		)
		super()
		return

	_doRender: (domBinding, value)->
		checked = cola.DataType.defaultDataTypes.boolean.parse(value)
		domBinding.dom.checked = checked
		return

class cola._RadioFeature extends cola._DomFeature
	init: (domBinding) ->
		domBinding.$dom.on("click", () ->
			checked = this.checked
			if checked then @writeBack(domBinding, checked)
			return
		)
		super()
		return

	_doRender: (domBinding, value)->
		domBinding.dom.checked = (value == domBinding.dom.value)
		return

class cola._SelectFeature extends cola._DomFeature
	init: (domBinding) ->
		feature = @
		domBinding.$dom.on("change", () ->
			value = @options[@selectedIndex]
			feature.writeBack(domBinding, value?.value)
			return
		)
		super()
		return

	_doRender: (domBinding, value)->
		domBinding.dom.value = value
		return

class cola._DisplayFeature extends cola._DomFeature
	_doRender: (domBinding, value)->
		domBinding.dom.style.display = if value then "" else "none"
		return

class cola._SelectOptionsFeature extends cola._DomFeature
	_doRender: (domBinding, optionValues)->
		return unless optionValues instanceof Array or optionValues instanceof cola.EntityList

		options = domBinding.dom.options
		if optionValues instanceof cola.EntityList
			options.length = optionValues.entityCount
		else
			options.length = optionValues.length

		cola.each optionValues, (optionValue, i) ->
			option = options[i]
			if cola.util.isSimpleValue(optionValue)
				$fly(option).removeAttr("value").text(optionValue)
			else if optionValue instanceof cola.Entity
				$fly(option).attr("value",
					optionValue.get("value") or optionValue.get("key")).text(optionValue.get("text") or optionValue.get("name"))
			else
				$fly(option).attr("value",
					optionValue.value or optionValue.key).text(optionValue.text or optionValue.name)
			return
		return