###
Model and Scope
###

cola.model = (name, model)->
	if arguments.length is 2
		if model
			if cola.model.models[name]
				throw new cola.Exception("Duplicated model name \"#{name}\".")
			cola.model.models[name] = model

			if name is cola.constants.DEFAULT_PATH
				window?.modelRoot = model
		else
			model = cola.removeModel(name)
		return model
	else
		return cola.model.models[name or cola.constants.DEFAULT_PATH]

cola.model.models = {}

cola.removeModel = (name)->
	model = cola.model.models[name]
	delete cola.model.models[name]
	return model

class cola.Scope

	destroy: ()->
		if @_childScopes
			for child in @_childScopes
				child.destroy()
			delete @_childScopes
		return

	_getAction: (name)->
		fn = @action[name]
		fn ?= @parent?._getAction(name)
		return fn

	get: (path, loadMode, context)->
		if typeof path is "string" and path.substring(0, 8) is "$parent." and @parent
			return @parent.get(path.substring(8), loadMode, context)
		else
			return @data.get(path, loadMode, context)

	getAsync: (prop, callback, context)->
		return $.Deferred (dfd)=>
			@get(prop, {
				complete: (success, value)->
					if not typeof callback is "string"
						cola.callback(callback)

					if success
						dfd.resolve(value)
					else
						dfd.reject(value)
					return
			}, context)

	set: (path, data, context)->
		if typeof path is "string" and path.substring(0, 8) is "$parent." and @parent
			@parent.set(path.substring(8), data, context)
		else
			@data.set(path, data, context)
		return @

	insert: (prop, data)->
		return @data.insert(prop, data)

	describe: (property, config)->
		return @data.describe(property, config)

	dataType: (name)->
		if typeof name is "string"
			dataType = @data.definition(name)
			return if dataType instanceof cola.DataType then dataType else null
		else if name
			if name instanceof Array
				for dataType in name
					if not (dataType instanceof cola.DataType)
						if dataType.lazy isnt false
							dataType = new cola.EntityDataType(dataType)
							if dataType.name
								@data.regDefinition(dataType.name, dataType)
			else
				dataType = name
				if not (dataType instanceof cola.DataType)
					if dataType.lazy isnt false
						dataType = new cola.EntityDataType(dataType)
						if dataType.name
							@data.regDefinition(dataType.name, dataType)
						return dataType
			return @

	definition: (name)->
		return @data.definition(name)

	flush: (name, loadMode)->
		return cola.util.wrapDeferredWith(@, @data.flush(name, loadMode))

	disableObservers: ()->
		@data.disableObservers()
		if @_childScopes
			for childScope in @_childScopes
				childScope.disableObservers()
		return @

	enableObservers: ()->
		@data.enableObservers()
		if @_childScopes
			for childScope in @_childScopes
				childScope.enableObservers()
		return @

	notifyObservers: (path)->
		@data.notifyObservers(path)
		return @

	watch: (path, fn)->
		processor =
			processMessage: (bindingPath, path, type, arg)->
				fn(path, type, arg)
				return

		if path instanceof Array
			for p in path
				@data.bind(p, processor)
		else
			@data.bind(path, processor)
		return @

	hasExBinding: ()->
		return @_hasExBinding

	setHasExBinding: (hasExBinding)->
		return if @_hasExBinding is hasExBinding
		@_hasExBinding = hasExBinding
		@parent?.setHasExBinding(true) if hasExBinding
		return

	registerChild: (childScope)->
		@_childScopes ?= []
		@_childScopes.push(childScope)
		@data.bind("**", childScope)
		return

	unregisterChild: (childScope)->
		return unless @_childScopes

		@data.unbind("**", childScope)
		i = @_childScopes.indexOf(childScope)
		if i >= 0
			@_childScopes.splice(i, 1)
		return

class cola.Model extends cola.Scope
	repeatNotification: true

	constructor: (name, parent)->
		cola.currentScope ?= @

		if name instanceof cola.Scope
			parent = name
			name = undefined

		if name
			@name = name
			cola.model(name, @)

		if parent and typeof parent is "string"
			parentName = parent
			parent = cola.model(parentName)

		@parent = parent
		@setHasExBinding(true)

		@data = new cola.DataModel(@)

		parent?.registerChild(@)

		@action = (name, action)->
			store = @action
			if arguments.length is 1
				if typeof name is "string"
					return @_getAction(name) or cola.defaultAction[name]
				else if name and typeof name is "object"
					config = name
					for n, a of config
						@action(n, a)
				return null
			else
				if action
					store[name] = action
				else
					delete store[name]
				return @

	destroy: ()->
		@parent?.unregisterChild(@)
		cola.removeModel(@name) if @name
		@data.destroy?()
		return

	processMessage: (bindingPath, path, type, arg)->
		return @data.onDataMessage(path, type, arg)

	$: (selector)->
		@_$doms ?= $(@_doms)
		return @_$doms.find(selector)

	tag: (tag)->
		filtered = []
		elements = cola.tagManager.find(tag)
		for element in elements
			scope = element._scope
			while scope
				if scope is @
					filtered.push(element)
					break
				scope = scope.parent
		return cola.Element.createGroup(filtered)

class cola.SubScope extends cola.Scope
	repeatNotification: true

	constructor: (@parent, expressions)->
		@action = @parent.action
		@parent.registerChild(@)
		if expressions
			@setExpressions(expressions)

	destroy: ()->
		if @parent then @unwatchPath()
		@data?.destroy?()
		return

	setExpressions: (expressions)->
		return unless expressions

		@data = new cola.SubDataModel(@)
		@aliasExpressions = {}
		@aliasPaths = {}

		for expression in expressions
			@aliasExpressions[expression.alias] = expression

			if not expression.paths and expression.hasComplexStatement and not expression.hasDefinedPath
				@aliasPaths = null
				break
			else if expression.paths
				for path in expression.paths
					if path is "**"
						@aliasPaths = null
						break
					@aliasPaths[path] = null
			@data.addAlias(expression.alias, expression.writeablePath)

		if @aliasPaths
			for path of @aliasPaths
				@watchPath(path)
		else
			@watchAllMessages()
		return

	watchPath: (path)->
		return if @_watchAllMessages or @_watchPath is path

		if path
			@_watchPath = paths = []
			parent = @parent
			if path instanceof Array
				for p in path
					p = p + ".**"
					paths.push(p)
					parent?.data.bind(p, @)
			else
				path = path + ".**"
				paths.push(path)
				parent?.data.bind(path, @)
		else
			delete @_watchPath
		return

	unwatchPath: ()->
		return unless @_watchPath
		path = @_watchPath
		delete @_watchPath
		parent = @parent
		if parent and path
			if path instanceof Array
				for p in path
					parent.data.unbind(p, @)
			else
				parent.data.unbind(path, @)
		return

	watchAllMessages: ()->
		return if @_watchAllMessages
		@_watchAllMessages = true
		@unwatchPath()
		parent = @parent
		if parent
			@_watchPath = [ "**" ]
			parent.data.bind("**", @)
			parent.watchAllMessages?()
		return

	evaluate: (expression, scope, loadMode = "async", dataCtx = {})->
		return expression?.evaluate(scope, loadMode, dataCtx)

	setAliasTargetData: (alias, data)->
		@data.setAliasTargetData(alias, data)
		return

	retrieveAliasData: (alias)->
		cola.util.cancelDelay(@, "retrieve")

		data = @evaluate(@aliasExpressions[alias], @)
		@setAliasTargetData(alias, data)
		return

	isParentOfTarget: (expressionPaths, changedPath)->
		if not expressionPaths?.length then return false
		if not changedPath then return true

		for targetPath in expressionPaths
			isParent = true
			for part, i in changedPath
				targetPart = targetPath[i]

				if targetPart and targetPart.charCodeAt(targetPart.length - 1) is 35 # '#'
					targetPart = targetPart.substring(0, targetPart.length - 1)

				if part isnt targetPart
					if targetPart is "**" then continue
					else if targetPart is "*"
						if i is changedPath.length - 1 then continue
					isParent = false
					break

			if isParent then return true
		return false

	isParentOf: (parent, child) ->
		while child
			if child.parent is parent
				return true
			child = child.parent
		return false

	processMessage: (bindingPath, path, type, arg)->
		# 如果@aliasExpressions为空是不应该进入此方法的
		if @messageTimestamp >= arg.timestamp then return
		@_processMessage(bindingPath, path, type, arg)

		@data?.onDataMessage(path, type, arg)
		return

	_processMessage: (bindingPath, path, type, arg)->
		# 如果@aliasExpressions为空是不应该进入此方法的
		if type is cola.constants.MESSAGE_REFRESH or type is cola.constants.MESSAGE_CURRENT_CHANGE or
		  type is cola.constants.MESSAGE_CURRENT_CHANGE or type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE or
		  type is cola.constants.MESSAGE_REMOVE
			for alias, expression of @aliasExpressions
				if not expression.paths and expression.hasComplexStatement and not expression.hasDefinedPath
					cola.util.delay(@, "retrieve", 100, ()=>
						@retrieveAliasData(alias)
						return
					)
				else
					isParent = @isParentOfTarget(expression.splittedPaths, path)
					if isParent
						@retrieveAliasData(alias)
		return

class cola.ItemScope extends cola.SubScope
	constructor: (parent, @alias)->
		super(parent)
		@data = new cola.ItemDataModel(@, @alias, @parent?.dataType)
		@action = @parent.action
		parent.registerChild(@)

	watchPath: ()->

	processMessage: (bindingPath, path, type, arg)->
		return @data.onDataMessage(path, type, arg)

class cola.ItemsScope extends cola.SubScope

	constructor: (parent, expression)->
		@itemScopeMap = {}
		@setParent(parent)
		@setExpression(expression)

	setExpression: (expression)->
		@expression = expression
		@alias = if expression then expression.alias else "item"
		@expressionPaths = []

		if expression
			if expression.paths
				for path in @expression.splittedPaths
					@expressionPaths.push(path)

			if not expression.paths and expression.hasComplexStatement and not expression.hasDefinedPath
				@watchAllMessages()
			else
				@watchPath(expression.paths)
		else
			@unwatchPath()
		return

	addAuxExpression: (expression)->
		@expressionPaths ?= []
		if expression.paths
			for path in @expression.splittedPaths
				@expressionPaths.push(path)

		if not expression.paths and expression.hasComplexStatement and not expression.hasDefinedPath
			@watchAllMessages()
		else
			@watchPath(expression.paths)
		return

	registerChild: (itemScope)->
		return unless itemScope.data
		item = itemScope.data.getItemData()
		if item instanceof cola.Entity
			itemId = cola.Entity._getEntityId(item)
			@regItemScope(itemId, itemScope)
		return

	unregisterChild: (itemScope)->
		item = itemScope.data.getItemData()
		if typeof item is "object"
			itemId = cola.Entity._getEntityId(item)
			@unregItemScope(itemId)
		return

	getItemScope: (item)->
		itemId = cola.Entity._getEntityId(item)
		return @itemScopeMap[itemId]

	regItemScope: (itemId, itemScope)->
		@itemScopeMap[itemId] = itemScope
		return

	unregItemScope: (itemId)->
		delete @itemScopeMap[itemId]
		return

	disableObservers: ()->
		for key, childScope of @itemScopeMap
			childScope.disableObservers()
		return @

	enableObservers: ()->
		for key, childScope of @itemScopeMap
			childScope.enableObservers()
		return @

	notifyObservers: (path)->
		for key, childScope of @itemScopeMap
			childScope.notifyObservers(path)
		return @

	setParent: (parent)->
		if @parent then @unwatchPath()

		@parent = parent
		@data = parent.data
		@action = parent.action

		if @_watchAllMessages
			@watchAllMessages()
		else if @_watchPath
			@watchPath(@_watchPath)
		return

	setItems: (items)->
		@_setItems(items)
		return

	retrieveData: ()->
		cola.util.cancelDelay(@, "retrieve")

		if @_retrieveItems
			@_retrieveItems()
		else if @expression
			items = @evaluate(@expression, @parent)
			@setItems(items)
		return

	_setItems: (items)->
		@items = items
		@originItems = if items instanceof Array then items.$origin else null
		return

	refreshItems: ()->
		@onItemsRefresh?()
		return

	refreshItem: (arg)->
		arg.itemsScope = @
		@onItemRefresh?(arg)
		return

	insertItem: (arg)->
		arg.itemsScope = @
		@onItemInsert?(arg)
		return

	removeItem: (arg)->
		arg.itemsScope = @
		@onItemRemove?(arg)
		return

	itemsLoadingStart: (arg)->
		arg.itemsScope = @
		@onItemsLoadingStart?(arg)

	itemsLoadingEnd: (arg)->
		arg.itemsScope = @
		@onItemsLoadingEnd?(arg)

	changeCurrentItem: (arg)->
		arg.itemsScope = @
		@onCurrentItemChange?(arg)
		return

	findItemDomBinding: (item)->
		itemScopeMap = @itemScopeMap
		items = @items
		originItems = @originItems
		multiOriginItems = originItems?._multiItems
		if items or originItems
			while item
				if item instanceof cola.Entity
					matched = ((item.parent or item._parent) is items)
					if not matched and originItems
						if multiOriginItems
							for oi in originItems
								if (item.parent or item._parent) is oi
									matched = true
									break
						else
							matched = ((item.parent or item._parent) is originItems)
					if matched
						itemId = cola.Entity._getEntityId(item)
						return if itemId then itemScopeMap[itemId] else null
				item = (item.parent or item._parent)
		return null

	processMessage: (bindingPath, path, type, arg)->
		if @messageTimestamp >= arg.timestamp then return
		allProcessed = @_processMessage(bindingPath, path, type, arg)

		if @itemScopeMap
			itemScope = @findItemDomBinding(arg.data or arg.entity)
			if itemScope
				itemScope.processMessage(bindingPath, path, type, arg)
			else if @hasExBinding()
				for id, itemScope of @itemScopeMap
					if itemScope.hasExBinding()
						itemScope.processMessage(bindingPath, path, type, arg)

		if allProcessed
			@messageTimestamp = arg.timestamp
		return

	isOriginItems: (items)->
		return false unless @originItems
		return true if @originItems is items

		if @originItems instanceof Array and @originItems._multiItems
			for originItems in @originItems
				if originItems is items
					return true
		return false

	isChildOfOriginItems: (items)->
		return false unless @originItems
		return true if @originItems is items

		if @originItems instanceof Array and @originItems._multiItems
			for originItems in @originItems
				if originItems is items
					return true
		return false

	isWatchPathPreciseMatch: (changedPath)->
		expressionPaths = @expressionPaths

		if not expressionPaths.length then return false
		if not changedPath then return true

		if expressionPaths.length - changedPath.length < 2
			for targetPath in expressionPaths
				isMatch = true
				for part, i in changedPath
					targetPart = targetPath[i]
					if part isnt targetPart
						isMatch = false
						break

				if isMatch and expressionPaths.length > changedPath.length
					targetPart = expressionPaths[expressionPaths.length - 1]
					if targetPart isnt "*" or targetPart isnt "**"
						isMatch = false

				if isMatch then return true
		return false

	findRelativeItem: (child, deepth = 2)->
		items = @originItems or @items
		return unless items

		i = 0
		item = null
		while child
			if child.parent is items and i < deepth
				item = child
				break
			child = child.parent
			i++
		return item

	_processMessage: (bindingPath, path, type, arg)->
		if @onMessage?(path, type, arg) is false
			return true

		if type is cola.constants.MESSAGE_REFRESH
			if arg.originType is cola.constants.MESSAGE_CURRENT_CHANGE and
			  (arg.entityList is @items or @isOriginItems(arg.entityList))
				@onCurrentItemChange?(arg)
			else if @isParentOfTarget(@expressionPaths, path)
				@retrieveData()
				@refreshItems()
				allProcessed = true
			else
				processMoreMessage = true

		else if type is cola.constants.MESSAGE_PROPERTY_CHANGE or type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE
			if @isParentOfTarget(@expressionPaths, path)
				@retrieveData()
				@refreshItems()
				allProcessed = true
			else
				entity = @findRelativeItem(arg.entity)
				if entity
					@refreshItem(entity: entity)
				else
					processMoreMessage = true

		else if type is cola.constants.MESSAGE_CURRENT_CHANGE
			if arg.entityList is @items or @isOriginItems(arg.entityList)
				@onCurrentItemChange?(arg)
			else if @isParentOfTarget(@expressionPaths, path)
				@retrieveData()
				@refreshItems()
				allProcessed = true
			else
				processMoreMessage = true

		else if type is cola.constants.MESSAGE_INSERT
			if arg.entityList is @items
				@insertItem(arg)
				allProcessed = true
			else if @isOriginItems(arg.entityList)
				@insertItem(arg)
				allProcessed = true
			else if @isWatchPathPreciseMatch(path, @expressionPaths)
				@retrieveData()
				@refreshItems()
				allProcessed = true
			else
				processMoreMessage = true

		else if type is cola.constants.MESSAGE_REMOVE
			if arg.entityList is @items
				@removeItem(arg)
				allProcessed = true
			else if @isOriginItems(arg.entityList) or @isWatchPathPreciseMatch(path, @expressionPaths)
				items = @items
				if items instanceof Array
					i = items.indexOf(arg.entity)
					if i > -1 then items.splice(i, 1)
				@removeItem(arg)
				allProcessed = true
			else
				processMoreMessage = true

		else if type is cola.constants.MESSAGE_LOADING_START
			if @isParentOfTarget(@expressionPaths, path) then @itemsLoadingStart(arg)

		else if type is cola.constants.MESSAGE_LOADING_END
			if @isParentOfTarget(@expressionPaths, path) then @itemsLoadingEnd(arg)

		if processMoreMessage and @expression
			if not @expressionPaths? and @expression.hasComplexStatement and not @expression.hasDefinedPath
				cola.util.delay(@, "retrieve", 100, ()=>
					@retrieveData()
					@refreshItems()
					return
				)
		return allProcessed

###
DataModel
###

class cola.AbstractDataModel
	disableObserverCount: 0

	constructor: (model)->
		return unless model
		@model = model
		parentModel = model.parent
		while parentModel
			if parentModel.data
				@parent = parentModel.data
				break
			parentModel = parentModel.parent

	get: (path, loadMode, context)->
		if not path
			return @_getRootData() or @parent?.get()

		if @_shortcutMap
			i = path.indexOf('.')
			firstPart = if i > 0 then path.substring(0, i) else path

			if firstPart.charCodeAt(firstPart.length - 1) is 35 # '#'
				returnCurrent = true
				firstPart = firstPart.substring(0, firstPart.length - 1)

			shortcutHolder = @_shortcutMap[firstPart]
			if shortcutHolder
				aliasData = shortcutHolder.data

				if aliasData and aliasData instanceof _EntityList and returnCurrent
					aliasData = aliasData.current

				if i > 0
					if loadMode and (typeof loadMode is "function" or typeof loadMode is "object")
						loadMode = "async"
						callback = loadMode
					return cola.Entity._evalDataPath(aliasData, path.substring(i + 1), false, loadMode, callback,
					  context)
				else
					return aliasData

		rootData = @_rootData
		if rootData?
			if @parent
				i = path.indexOf('.')
				if i > 0
					prop = path.substring(0, i)
				else
					prop = path

				if prop.charCodeAt(prop.length - 1) is 35 # '#'
					prop = prop.substring(0, prop.length - 1)

				if rootData.hasValue(prop)
					return rootData.get(path, loadMode, context)
				else
					return @parent.get(path, loadMode, context)
			else
				return rootData.get(path, loadMode, context)
		else
			return @parent?.get(path, loadMode, context)

	set: (path, data, context)->
		if path
			rootData = @_getRootData()
			if typeof path is "string"
				if path.charCodeAt(0) is 64 # `@`
					firstPart = if i > 0 then path.substring(0, i) else path
					firstPart = @get(firstPart.substring(1))
					path = firstPart + if i > 0 then path.substring(i + 1) else ""

				i = path.indexOf('.')
				if i > 0
					firstPart = path.substring(0, i)
					if @_shortcutMap
						shortcutHolder = @_shortcutMap[firstPart]
						if shortcutHolder
							if shortcutHolder.data
								cola.Entity._setValue(shortcutHolder.data, path.substring(i + 1), data, context)
							else
								throw new cola.Exception("Cannot set value to \"#{path}\"")
							return @

					if @parent
						if rootData.hasValue(firstPart)
							rootData.set(path, data, context)
						else
							@parent.set(path, data, context)
					else
						rootData.set(path, data, context)
				else
					@_set(path, data, context)
			else
				data = path
				for p of data
					@set(p, data[p], context)
		return @

	_set: (prop, data, context)->
		rootData = @_rootData
		hasValue = rootData.hasValue(prop)

		if @_shortcutMap?[prop]
			oldShortcutData = @_shortcutMap?[prop]?.data
			@removeShortcut(prop)
			if not data or not (data instanceof cola.Entity or data instanceof cola.EntityList) or
			  not data.parent or data is rootData._data[prop] # is not alias
				@onDataMessage([ prop ], cola.constants.MESSAGE_PROPERTY_CHANGE, {
					entity: @_rootData
					property: prop
					oldValue: oldShortcutData
					value: data
				})

		if data? # 判断是数据还是数据声明
			if data.$provider or data.$dataType
				if data.$provider
					provider = new cola.Provider(data.$provider)

				rootDataType = rootData.dataType
				property = rootDataType.getProperty(prop)
				property ?= rootDataType.addProperty(property: prop)

				property.set("provider", provider) if provider
				property.set("dataType", data.$dataType) if data.$dataType

		if not provider or hasValue
			if data and (data instanceof cola.Entity or data instanceof cola.EntityList) and data.parent and data isnt rootData._data[prop] # is alias
				@addShortcut(prop, data)
			else
				rootData.set(prop, data, context)
		return

	addShortcut: (shortcut, data)->
		@_shortcutMap ?= {}
		path = data.getPath("always")
		oldShortcutData = @_shortcutMap?[shortcut]?.data

		dataModel = @
		@_shortcutMap[shortcut] = shortcutHolder = {
			data: data
			path: if path instanceof Array then path.join(".") else path
			splittedPath: if path instanceof Array then path else path.split(".")
			bindingPath: path.slice(0).concat("**")
			processMessage: (bindingPath, path, type, arg)->
				relativePath = path.slice(@splittedPath.length)
				dataModel.onDataMessage([ shortcut ].concat(relativePath), type, arg)
				return
		}
		@bind(shortcutHolder.bindingPath, shortcutHolder)
		@onDataMessage([ shortcut ], cola.constants.MESSAGE_PROPERTY_CHANGE, {
			entity: @_rootData
			property: shortcut
			oldValue: oldShortcutData
			value: data
		})
		return

	removeShortcut: (shortcut)->
		if @_shortcutMap?[shortcut]
			oldAliasHolder = @_shortcutMap[shortcut]
			delete @_shortcutMap[shortcut]
			@unbind(oldAliasHolder.bindingPath, oldAliasHolder)
		return

	insert: (prop, data)->
		return @_rootData.insert(prop, data)

	reset: (name)->
		@_rootData?.reset(name)
		return @

	flush: (name, loadMode)->
		return cola.util.wrapDeferredWith(@, @_rootData?.flush(name, loadMode))

	bind: (path, processor)->
		if not @bindingRegistry
			@bindingRegistry =
				__path: ""
				__processorMap: {}

		if typeof path is "string"
			path = path.split(".")

		if path then @_bind(path, processor)
		return @

	_bind: (path, processor)->
		node = @bindingRegistry
		if path
			for part in path
				if part.charCodeAt(part.length - 1) is 35 # `#`
					part = part.substring(0, part.length - 1)

				subNode = node[part]
				if not subNode?
					nodePath = if not node.__path then part else (node.__path + "." + part)
					node[part] = subNode =
						__path: nodePath
						__processorMap: {}
				node = subNode

			#if path.length > 1 and cola.consoleOpened and cola.debugLevel > 9
			#	if path[path.length - 1].indexOf("*") >= 0
			#		path = path.slice(0, path.length - 1)
			#	if path.length > 1
			#		joinedPath = path.join(".")
			#		cola.Entity._warnedBindPaths ?= {}
			#		if not cola.Entity._warnedBindPaths[joinedPath] and not @getProperty(joinedPath)
			#			cola.Entity._warnedBindPaths[joinedPath] = true
			#			console.warn("Binding path may be illegal: " + joinedPath)

			processor.id ?= cola.uniqueId()
			node.__processorMap[processor.id] = processor
		return

	unbind: (path, processor)->
		if not @bindingRegistry then return

		if typeof path is "string"
			path = path.split(".")

		if path then @_unbind(path, processor)
		return @

	_unbind: (path, processor)->
		node = @bindingRegistry
		for part in path
			if part.charCodeAt(part.length - 1) is 35 # `#`
				part = part.substring(0, part.length - 1)

			node = node[part]
			if not node? then break

		delete node.__processorMap[processor.id] if node?

	disableObservers: ()->
		if @disableObserverCount < 0 then @disableObserverCount = 1 else @disableObserverCount++
		return @

	enableObservers: ()->
		if @disableObserverCount < 1 then @disableObserverCount = 0 else @disableObserverCount--
		return @

	notifyObservers: (path)->
		if path
			data = @get(path, "never")
		else
			data = @_rootData
		data?.notifyObservers?()
		return @

	onDataMessage: (path, type, arg = {})->
		return unless @bindingRegistry
		return if @disableObserverCount > 0
		return @_onDataMessage(path, type, arg)

	_onDataMessage: (path, type, arg = {})->
		oldScope = cola.currentScope
		cola.currentScope = @
		try
			arg.timestamp ?= cola.sequenceNo()
			node = @bindingRegistry
			if node
				if path
					lastIndex = path.length - 1
					for part, i in path
						if i is lastIndex
							anyPropNode = node["*"]
							@processDataMessage(anyPropNode, path, type, arg) if anyPropNode

						anyChildNode = node["**"]
						@processDataMessage(anyChildNode, path, type, arg) if anyChildNode

						node = node[part]
						break unless node
				else
					anyPropNode = node["*"]
					@processDataMessage(anyPropNode, null, type, arg) if anyPropNode

					anyChildNode = node["**"]
					@processDataMessage(anyChildNode, null, type, arg) if anyChildNode

				@processDataMessage(node, path, type, arg, true) if node
		finally
			cola.currentScope = oldScope
		return

	processDataMessage: (node, path, type, arg, notifyChildren)->
		processorMap = node.__processorMap
		for id, processor of processorMap
			if not processor.disabled and (not (processor.timestamp >= arg.timestamp) or processor.repeatNotification)
				processor.timestamp = arg.timestamp
				processor.processMessage(node.__path, path, type, arg)

		if notifyChildren
			notifyChildren2 = type isnt cola.constants.MESSAGE_EDITING_STATE_CHANGE and not (cola.constants.MESSAGE_LOADING_START <= type <= cola.constants.MESSAGE_LOADING_END)

			if notifyChildren2 and type is cola.constants.MESSAGE_CURRENT_CHANGE
				type = cola.constants.MESSAGE_REFRESH
				arg = $.extend({
					originType: cola.constants.MESSAGE_CURRENT_CHANGE
				}, arg)

			for part, subNode of node
				if subNode and (part is "**" or notifyChildren2) and part isnt "__processorMap" and part isnt "__path"
					@processDataMessage(subNode, path, type, arg, true)
		return

	getAbsolutePath: (path)->
		return path unless path
		i = path.lastIndexOf(".")
		if i > 0
			entityPath = path.substring(0, i)
			property = path.substring(i + 1)
			entity = @get(entityPath, "never")
			if entity
				entityPath = entity.getPath?()
				if entityPath
					entityPath.push(property)
					path = entityPath.join(".")
		return path

class cola.DataModel extends cola.AbstractDataModel

	_createRootData: (rootDataType)->
		entity = new cola.Entity(null, rootDataType)
		entity._isRootData = true
		return entity

	_getRootData: ()->
		if not @_rootData?
			@_rootDataType ?= new cola.EntityDataType()
			@_rootData = rootData = @_createRootData(@_rootDataType)
			rootData.state = cola.Entity.STATE_NONE
			dataModel = @
			rootData._setDataModel(dataModel)
		return @_rootData

	describe: (property, config)->
		@_getRootData()
		if typeof property is "string"
			propertyDef = @_rootDataType?.getProperty(property)
			if config
				if not propertyDef
					propertyDef = @_rootDataType.addProperty(property: property)

				if typeof config is "string"
					dataType = @definition(config)
					if not dataType
						throw new cola.Exception("Unrecognized DataType \"#{config}\".")
					propertyDef.set("dataType", dataType)
				else if config instanceof cola.DataType
					propertyDef.set("dataType", config)
				else
					propertyDef.set(config)
		else if property
			config = property
			for propertyName, propertyConfig of config
				@describe(propertyName, propertyConfig)
		return

	getProperty: (path)->
		if @_rootDataType
			i = path.indexOf(".")
			if i > 0
				path1 = path.substring(0, i)
				path2 = path.substring(i + 1)
				if path1.charCodeAt(path1.length - 1) is 35 # `#`
					path1 = path1.substring(0, path1.length - 1)
				holder = @_shortcutMap?[path1]
				if holder
					return @getProperty(holder.path + "." + path2)
			else
				path1 = null
				path2 = path
				if path2.charCodeAt(path2.length - 1) is 35 # `#`
					path2 = path1.substring(0, path2.length - 1)
				holder = @_shortcutMap?[path2]
				if holder
					return @getProperty(holder.path)

			if path1
				dataType = @_rootDataType.getProperty(path1)?.get("dataType")
			else
				dataType = @_rootDataType

			if dataType instanceof cola.EntityDataType
				return dataType.getProperty(path2)
			else
				return null
		else
			return @parent?.getProperty(path)

	getDataType: (path)->
		property = @getProperty(path)
		dataType = property?.get("dataType")
		return dataType

	definition: (name)->
		definition = @_definitionStore?[name]
		if definition
			if not (definition instanceof cola.Definition)
				definition = new cola.EntityDataType(definition)
				@_definitionStore[name] = definition

		if not definition and @model.parent
			definition = @model.parent.data.definition(name)

		if not definition
			definition = cola.DataType.defaultDataTypes[name]
		return definition

	regDefinition: (name, definition)->
		if name instanceof cola.Definition
			definition = name
			name = name._name

		if not name
			throw new cola.Exception("Attribute \"name\" cannot be emtpy.")

		if definition._scope and definition._scope isnt @model
			throw new cola.Exception("DataType(#{definition._name}) is already belongs to anthor Model.")

		store = @_definitionStore
		if not store?
			@_definitionStore = store = {}
		else if store[name]
			throw new cola.Exception("Duplicated Definition name \"#{name}\".")

		store[name] = definition
		return @

	unregDefinition: (name)->
		if @_definitionStore
			definition = @_definitionStore[name]
			delete @_definitionStore[name]
		return definition

	addEntityListener: (listener)->
		@_entityListeners ?= []
		@_entityListeners.push(listener)
		return

	removeEntityListener: (listener)->
		return unless @_entityListeners
		if listener
			i = @_entityListeners.indexOf(listener)
			if i > -1
				@_entityListeners.splice(i, 1)
		return

	onEntityAttach: (entity)->
		if @_entityListeners
			for listener in  @_entityListeners
				listener.onEntityAttach(entity)
		return

	onEntityDetach: (entity)->
		if @_entityListeners
			for listener in  @_entityListeners
				listener.onEntityDetach(entity)
		return

class cola.SubDataModel extends cola.AbstractDataModel

	constructor: (model)->
		super(model)
		@_aliasMap = {}

	definition: (name)->
		return @parent.definition(name)

	regDefinition: (definition)->
		return @parent.regDefinition(definition)

	unregDefinition: (definition)->
		return @parent.unregDefinition(definition)

	dataType: (name)->
		return @parent.dataType(name)

	addAlias: (alias, path)->
		@_aliasMap[alias] =
			data: undefined
			alias: alias
			path: path
			splittedPath: path?.split(".") or []
		return

	getAliasTargetData: (alias)->
		return @_aliasMap[alias].data

	setAliasTargetData: (alias, data, silence)->
		holder = @_aliasMap[alias]
		oldData = holder.data
		holder.data = data

		if data instanceof cola.Entity or data instanceof cola.EntityList
			holder.dataType = data.dataType

		if not silence
			@onDataMessage([ alias ], cola.constants.MESSAGE_PROPERTY_CHANGE, {
				entity: null
				property: alias
				value: data
				oldValue: oldData
			})
		return

	describe: (property, config)->
		if @_aliasMap[property]
			return super(property, config)
		else
			return @parent.describe(property, config)

	getProperty: (path)->
		i = path.indexOf(".")
		if i > 0
			path1 = path.substring(0, i)
			if path1.charCodeAt(path1.length - 1) is 35 # `#`
				path1 = path1.substring(0, path1.length - 1)
			holder = @_aliasMap[path1]
			if holder?.path
				path = holder.path + path.substring(i)
		else
			if path.charCodeAt(path.length - 1) is 35 # `#`
				path = path1.substring(0, path.length - 1)
			holder = @_aliasMap[path]
			if holder?.path
				path = holder.path
		return @parent.getProperty(path)

	_isExBindingPath: (path)->
		return not @_aliasMap[path[0]]

	_bind: (path, processor)->
		super(path, processor)

		if not @_exBindingProcessed and @_isExBindingPath(path)
			@_exBindingProcessed = true
			@model.setHasExBinding(true)
			@model.watchAllMessages()
		return

	get: (path, loadMode, context)->
		if path
			i = path.indexOf(".")
			if i > 0
				holder = @_aliasMap[path.substring(0, i)]
				if holder
					data = holder.data
					if data instanceof cola.Entity
						return data.get(path.substring(i + 1), loadMode, context)
					else if data and typeof data is "object"
						return data[path.substring(i + 1)]
				else
					return @parent.get(path, loadMode, context)
			else
				holder = @_aliasMap[path]
				if holder
					return holder.data
				else
					return @parent.get(path, loadMode, context)
		else
			return @parent.get(path, loadMode, context)

	set: (path, data, context)->
		i = path.indexOf(".")
		if i > 0
			holder = @_aliasMap[path.substring(0, i)]
			if holder
				holder.data?.set(path.substring(i + 1), data, context)
			else
				@parent.set(path, data, context)
		else
			holder = @_aliasMap[path]
			if holder
				@parent.set(holder.path, data, context)
			else
				@parent.set(path, data, context)
		return @

	flush: (path, loadMode)->
		i = path.indexOf(".")
		if i > 0
			holder = @_aliasMap[path.substring(0, i)]
			if holder
				dfd = holder.data?.flush(path.substring(i + 1), loadMode)
			else
				dfd = @parent.flush(path, loadMode)
		else
			holder = @_aliasMap[path]
			if holder
				path = holder.path
			if path
				dfd = @parent.flush(path, loadMode)
		return cola.util.wrapDeferredWith(@, dfd)

	onDataMessage: (path, type, arg)->
		super(path, type, arg)

		isChildData = (data, targetData)->
			isChild = false
			while data
				if data is targetData
					isChild = true
					break
				data = data.parent or data._parent
			return isChild

		data = arg.data or arg.entityList or arg.entity
		for alias, holder of @_aliasMap
			if data is null or isChildData(data, holder.data)
				if path.length >= holder.splittedPath.length
					matches = true
					for part, i in holder.splittedPath
						if part isnt path[i]
							matches = false
							break

					if matches
						aliasSubPath = [].concat(holder.alias, path.slice(holder.splittedPath.length))
						@_onDataMessage(aliasSubPath, type, arg)
		return

class cola.ItemDataModel extends cola.SubDataModel

	constructor: (model, @alias, @dataType)->
		super(model)

	getItemData: ()->
		return @_itemData

	setItemData: (data, silence)->
		return if oldData is data

		itemsScope = @model.parent
		if not (itemsScope instanceof cola.ItemsScope)
			itemsScope = null

		oldData = @_itemData
		if typeof oldData is "object" and itemsScope
			if itemsScope.getItemScope(oldData) is @model
				itemId = cola.Entity._getEntityId(oldData)
				itemsScope.unregItemScope(itemId)

		@_itemData = data

		if data instanceof cola.Entity and itemsScope
			itemId = cola.Entity._getEntityId(data)
			itemsScope.regItemScope(itemId, @model)

		if typeof data is "object" or data instanceof cola.EntityList
			@dataType = data.dataType

		if not silence and @alias
			@onDataMessage([ @alias ], cola.constants.MESSAGE_PROPERTY_CHANGE, {
				entity: null
				property: @alias
				value: data
				oldValue: oldData
			})
		return

	getProperty: (path)->
		i = path.indexOf(".")
		if i > 0
			if path.substring(0, i) is @alias
				dataType = if @_itemData instanceof cola.Entity or @_itemData instanceof cola.EntityList then @_itemData.dataType else null
				dataType ?= @dataType
				if dataType instanceof cola.EntityDataType
					return dataType.getProperty(path.substring(i + 1))
				else
					return null
			else
				return @parent.getProperty(path)
		else if path is @alias
			dataType = if @_itemData instanceof cola.Entity or @_itemData instanceof cola.EntityList then @_itemData.dataType else null
			return dataType or @dataType
		else
			return @parent.getProperty(path)

	getDataType: (path)->
		if path is @alias
			return @dataType
		else
			property = @getProperty(path)
			return property?.get("dataType")

	_isExBindingPath: (path)->
		firstPart = path[0]
		return @alias isnt firstPart isnt @alias and firstPart isnt cola.constants.REPEAT_INDEX

	getIndex: ()-> @_index
	setIndex: (index, silence)->
		@_index = index
		if not silence
			@onDataMessage([ cola.constants.REPEAT_INDEX ], cola.constants.MESSAGE_PROPERTY_CHANGE, {
				entity: null
				property: cola.constants.REPEAT_INDEX
				value: index
			})
		return

	get: (path, loadMode, context)->
		if path is cola.constants.REPEAT_INDEX
			return @getIndex()
		else
			alias = @alias
			aliasLen = alias.length
			if path?.substring(0, aliasLen) is alias
				c = path.charCodeAt(aliasLen)
				if c is 46 # `.`
					if path.indexOf(".") > 0
						itemData = @_itemData
						if itemData instanceof cola.Entity
							return itemData.get(path.substring(aliasLen + 1), loadMode, context)
						else if itemData and typeof itemData is "object"
							return itemData[path.substring(aliasLen + 1)]
				else if isNaN(c)
					return @_itemData
			return @parent.get(path, loadMode, context)

	set: (path, data, context)->
		if path is cola.constants.REPEAT_INDEX or path is @alias
			throw new cola.Exception("Can not set \"#{path}\" of ItemScope.")

		alias = @alias
		aliasLen = alias.length
		if path.substring(0, aliasLen) is alias
			c = path.charCodeAt(aliasLen)
			if c is 46 # `.`
				if path.indexOf(".") > 0
					@_itemData?.set(path.substring(aliasLen + 1), data, context)
					return @
			else if isNaN(c)
				throw new cola.Exception("Can not change \"#{alias}\" of ItemScope.")

		@parent.set(path, data, context)
		return @

	onDataMessage: (path, type, arg)->
		super(path, type, arg)

		if @_itemData
			itemData = @_itemData
			entity = arg.data or arg.entityList or arg.entity
			while entity
				if entity is itemData
					isChild = true
					break
				entity = entity.parent

			if isChild
				relativePath = arg.originPath.slice(itemData.getPath().length)
				super([ @alias ].concat(relativePath), type, arg)
		return

###
Root Model
###
new cola.Model(cola.constants.DEFAULT_PATH)

###
Function
###

cola.data = (config)->
	return config unless config
	if config.provider
		provider = config.provider
	else
		provider = {}
		for k, v of config
			if k != "dataType"
				provider[k] = v

	dataType = config.dataType
	if dataType
		if typeof dataType is "string"
			name = dataType
			dataType = cola.currentScope.dataType(name)
			if not dataType
				throw new cola.Exception("Unrecognized DataType \"#{name}\".")
		else if not (dataType instanceof cola.DataType)
			dataType = new cola.EntityDataType(dataType)

	return {
		$dataType: dataType
		$provider: provider
	}

###
Element binding
###

class cola.ElementAttrBinding
	constructor: (@element, @attr, @expression, scope)->
		@scope = scope
		@paths = @expression.paths or []
		@watchingMoreMessage = not @paths.length and @expression.hasComplexStatement and not @expression.hasDefinedPath

		for path in @paths
			scope.data.bind(path, @)

	destroy: ()->
		paths = @paths
		if paths
			for path in paths
				@scope.data.unbind(path, @)
		return

	processMessage: (bindingPath, path, type)->
		return if @element._freezedCount > 0
		if cola.constants.MESSAGE_REFRESH <= type <= cola.constants.MESSAGE_CURRENT_CHANGE or @watchingMoreMessage
			@refresh()
		return

	evaluate: (dataCtx)->
		return @expression.evaluate(@scope, "async", dataCtx)

	_refresh: ()->
		value = @evaluate()
		element = @element
		element._duringBindingRefresh = true
		try
			element.set(@attr, value)
		finally
			element._duringBindingRefresh = false
		return

	refresh: ()->
		return unless @_refresh
		if @delay
			cola.util.delay(@, "refresh", 100, ()->
				@_refresh()
				return
			)
		else
			@_refresh()
		return