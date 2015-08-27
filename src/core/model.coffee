#IMPORT_BEGIN
if exports?
	cola = require("./action")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

###
Model and Scope
###

_RESERVE_NAMES =
	self: null
	arg: null

cola.model = (name, model) ->
	if arguments.length == 2
		if model
			if cola.model[name]
				throw new cola.I18nException("cola.error.duplicateModelName", name)
			cola.model[name] = model
		else
			model = cola.removeModel(name)
		return model
	else
		return cola.model[name]

cola.removeModel = (name) ->
	model = cola.model[name]
	delete cola.model[name]
	return model

class cola.AbstractModel
	get: (path, loadMode, context) ->
		return @data.get(path, loadMode, context)

	set: (path, data, context) ->
		@data.set(path, data, context)
		return @

	describe: (property, config) ->
		return @data.describe(property, config)

	dataType: (name) ->
		if typeof name == "string"
			dataType = @data.getDefinition(name)
			return if dataType instanceof cola.DataType then dataType else null
		else if name
			if name instanceof Array
				for dataType in name
					if not (dataType instanceof cola.DataType)
						dataType = new cola.EntityDataType(dataType)
					@data.regDefinition(dataType)
			else
				dataType = name
				if not (dataType instanceof cola.DataType)
					dataType = new cola.EntityDataType(dataType)
				@data.regDefinition(dataType)
			return

	getDefinition: (name) ->
		return @data.getDefinition(name)

	flushAsync: (name, callback) ->
		@data.flushAsync(name, callback)
		return @

	flushSync: (name) ->
		return @data.flushSync(name)

	disableObservers: () ->
		@data.disableObservers()
		return @

	enableObservers: () ->
		@data.enableObservers()
		return @

class cola.Model extends cola.AbstractModel
	constructor: (name, parent) ->
		if name instanceof cola.Model
			parent = name
			name = undefined

		if name
			@name = name
			cola.model(name, @)

		if parent and typeof parent == "string"
			parentName = parent
			parent = cola.model(parentName)
		@parent = parent if parent

		@data = new cola.DataModel(@)

		@action = (name, action) ->
			store = @action
			if arguments.length == 1
				if typeof name == "string"
					scope = @
					while store
						fn = store[name]
						if fn
							return fn.action or fn
						scope = scope.parent
						break unless scope
						store = scope.action
				else if name and typeof name == "object"
					config = name
					for n, a of config
						@action(n, a)
				return null
			else
				if action
					if typeof action == "function"
						fn = action
					else if !(action instanceof cola.Action)
						config = action
						action = cola.create("action", config, cola.Action)
						fn = () ->
							return action.execute.apply(action, arguments)
						fn = fn.bind(store)
						fn.action = action
					fn.isWrapper = true
					store[name] = fn
				else
					delete store[name]
				return @

	destroy: () ->
		cola.removeModel(@name) if @name
		@data.destroy?()
		return

class cola.SubScope extends cola.AbstractModel

	watchPath: (path) ->
		return if @_watchAllMessages or @_watchPath == path

		@_unwatchPath()

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

	_unwatchPath: () ->
		return unless @_watchPath
		path = @_watchPath
		delete @_watchPath
		parent = @parent
		if parent
			if path instanceof Array
				for p in path
					parent.data.unbind(p, @)
			else
				parent.data.unbind(path, @)
		return

	watchAllMessages: () ->
		return if @_watchAllMessages
		@_watchAllMessages = true
		@_unwatchPath()
		parent = @parent
		if parent
			parent.data.bind("**", @)
			parent.watchAllMessages?()
		return

	destroy: () ->
		if @parent
			if @_watchAllMessages
				@parent.data.unbind("**", @)
			else if @_watchPath
				@_unwatchPath()
		return

class cola.AliasScope extends cola.SubScope
	constructor: (@parent, expression) ->
		if expression and typeof expression.path == "string" and not expression.hasCallStatement and not expression.convertors
			dataType = @parent.data.getDataType(expression.path)

		@data = new cola.AliasDataModel(@, expression.alias, dataType)
		@action = @parent.action

		@expression = expression
		if !expression.path and expression.hasCallStatement
			@watchAllMessages()
		else
			@watchPath(expression.path)

	destroy: () ->
		super()
		@data.destroy()
		return

	repeatNotification: true

	_processMessage: (bindingPath, path, type, arg) ->
		if @messageTimestamp >= arg.timestamp then return
		@data._processMessage(bindingPath, path, type, arg)
		return

class cola.ItemScope extends cola.SubScope
	constructor: (@parent, alias) ->
		@data = new cola.AliasDataModel(@, alias, @parent?.dataType)
		@action = @parent.action

	watchPath: () ->

	watchAllMessages: () ->
		@parent?.watchAllMessages?()
		return

	_processMessage: (bindingPath, path, type, arg) ->
		return @data._processMessage(bindingPath, path, type, arg)

class cola.ItemsScope extends cola.SubScope
	constructor: (parent, expression) ->
		@setParent(parent)
		@setExpression(expression)

	setParent: (parent) ->
		if @parent
			if @_watchAllMessages
				@parent.data.unbind("**", @)
			else if @_watchPath
				@_unwatchPath()

		@parent = parent
		@data = parent.data
		@action = parent.action

		if @_watchAllMessages
			parent.data.bind("**", @)
		else if @_watchPath
			@watchPath(@_watchPath)
		return

	setExpression: (expression) ->
		@expression = expression
		if expression
			@alias = expression.alias
			if typeof expression.path == "string"
				@expressionPath = [expression.path.split(".")]
			else if expression.path instanceof Array
				paths = []
				for path in expression.path
					paths.push(path.split("."))
				@expressionPath = paths

			if !expression.path and expression.hasCallStatement
				@watchAllMessages()
			else
				@watchPath(expression.path)
		else
			@alias = "item"
			@expressionPath = []

		if expression and typeof expression.path == "string" and not expression.hasCallStatement and not expression.convertors
			@dataType = @parent.data.getDataType(expression.path)
		return

	setItems: (items, originItems...) ->
		@_setItems(items, originItems...)
		return

	retrieveItems: () ->
		if @_retrieveItems
			return @_retrieveItems()

		if @expression
			dataCtx = {}
			items = @expression.evaluate(@parent, "auto", dataCtx)
			@_setItems(items, dataCtx.originData)
		return

	_setItems: (items, originItems...) ->
		@items = items
		if originItems and originItems.length == 1
			@originItems = originItems[0]
		else
			@originItems = originItems
			@originItems._multiItems = true

		targetPath = null
		if originItems
			for it in originItems
				if it and it instanceof cola.EntityList
					targetPath ?= []
					targetPath.push(it.getPath())
		if targetPath
			@targetPath = targetPath.concat(@expressionPath)
		else
			@targetPath = @expressionPath
		return

	refreshItems: () ->
		@retrieveItems()
		@onItemsRefresh?()
		return

	refreshItem: (arg) ->
		arg.itemsScope = @
		@onItemRefresh?(arg)
		return

	insertItem: (arg) ->
		arg.itemsScope = @
		@onItemInsert?(arg)
		return

	removeItem: (arg) ->
		arg.itemsScope = @
		@onItemRemove?(arg)
		return

	changeCurrentItem: (arg) ->
		arg.itemsScope = @
		@onCurrentItemChange?(arg)
		return

	resetItemScopeMap: () ->
		@itemScopeMap = {}
		return

	getItemScope: (item) ->
		itemId = cola.Entity._getEntityId(item)
		return @itemScopeMap[itemId]

	regItemScope: (itemId, itemScope) ->
		@itemScopeMap[itemId] = itemScope
		return

	unregItemScope: (itemId) ->
		delete @itemScopeMap[itemId]
		return

	findItemDomBinding: (item) ->
		itemScopeMap = @itemScopeMap
		items = @items
		originItems = @originItems
		multiOriginItems = originItems?._multiItems
		if items or originItems
			while item
				if item instanceof cola.Entity
					matched = (item._parent == items)
					if !matched and originItems
						if multiOriginItems
							for oi in originItems
								if item._parent == oi
									matched = true
									break
						else
							matched = (item._parent == originItems)
					if matched
						itemId = cola.Entity._getEntityId(item)
						return if itemId then itemScopeMap[itemId] else null
				item = item._parent
		return null

	isRootOfTarget: (changedPath, targetPath) ->
		if !targetPath then return false
		if !changedPath then return true
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

	repeatNotification: true

	_processMessage: (bindingPath, path, type, arg) ->
		if @messageTimestamp >= arg.timestamp then return
		allProcessed = @processItemsMessage(bindingPath, path, type, arg)

		if allProcessed
			@messageTimestamp = arg.timestamp
		else if @itemScopeMap
			itemScope = @findItemDomBinding(arg.entity or arg.entityList)
			if itemScope
				itemScope._processMessage(bindingPath, path, type, arg)
			else
				for id, itemScope of @itemScopeMap
					itemScope._processMessage(bindingPath, path, type, arg)
		return

	isOriginItems: (items) ->
		return false unless @originItems
		return true if @originItems == items

		if @originItems instanceof Array and @originItems._multiItems
			for originItems in @originItems
				if originItems == items
					return true
		return false

	processItemsMessage: (bindingPath, path, type, arg)->
		targetPath = if @targetPath then @targetPath.concat(@expressionPath) else @expressionPath
		if type == cola.constants.MESSAGE_REFRESH
			if @isRootOfTarget(path, targetPath)
				@refreshItems()
				allProcessed = true

		else if type == cola.constants.MESSAGE_DATA_CHANGE # or type == cola.constants.MESSAGE_STATE_CHANGE
			if @isRootOfTarget(path, targetPath)
				@refreshItems()
				allProcessed = true
			else
				parent = arg.entity?._parent
				if parent == @items or @isOriginItems(arg.parent)
					@refreshItem(arg)

		else if type == cola.constants.MESSAGE_CURRENT_CHANGE
			if arg.entityList == @items or @isOriginItems(arg.entityList)
				@onCurrentItemChange?(arg)
			else if @isRootOfTarget(path, targetPath)
				@refreshItems()
				allProcessed = true

		else if type == cola.constants.MESSAGE_INSERT
			if arg.entityList == @items
				@insertItem(arg)
				allProcessed = true
			else if @isOriginItems(arg.entityList)
				@retrieveItems()
				@insertItem(arg)
				allProcessed = true

		else if type == cola.constants.MESSAGE_REMOVE
			if arg.entityList == @items
				@removeItem(arg)
				allProcessed = true
			else if @isOriginItems(arg.entityList)
				items = @items
				if items instanceof Array
					i = items.indexOf(arg.entity)
					if i > -1 then items.splice(i, 1)
				@removeItem(arg)
				allProcessed = true

		return allProcessed

###
DataModel
###

class cola.AbstractDataModel
	constructor: (@model) ->
		@disableObserverCount = 0

	get: (path, loadMode, context) ->
		if not path
			return @_getRootData() or @model.parent?.get()

		if @_aliasMap
			i = path.indexOf('.')
			firstPart = if i > 0 then path.substring(0, i) else path
			aliasHolder = @_aliasMap[firstPart]
			if aliasHolder
				aliasData = aliasHolder.data
				if i > 0
					if typeof loadMode == "function"
						loadMode = "auto"
						callback = loadMode
					return cola.Entity._evalDataPath(aliasData, path.substring(i + 1), false, loadMode, callback,
						context)
				else
					return aliasData

		rootData = @_rootData
		if rootData?
			if @model.parent
				i = path.indexOf('.')
				if i > 0
					prop = path.substring(0, i)
				else
					prop = path

				if rootData.hasValue(prop)
					return rootData.get(path, loadMode, context)
				else
					return @model.parent.data.get(path, loadMode, context)
			else
				return rootData.get(path, loadMode, context)
		else
			return @model.parent?.data.get(path, loadMode, context)

	set: (path, data, context) ->
		if path
			rootData = @_getRootData()
			if typeof path == "string"
				i = path.indexOf('.')
				if i > 0
					firstPart = path.substring(0, i)
					if @_aliasMap
						aliasHolder = @_aliasMap[firstPart]
						if aliasHolder
							if aliasHolder.data
								cola.Entity._setValue(aliasHolder.data, path.substring(i + 1), data, context)
							else
								throw new cola.I18nException("cola.error.setData", path)
							return @

					if @model.parent
						if rootData.hasValue(firstPart)
							rootData.set(path, data, context)
						else
							@model.parent.data.set(path, data, context)
					else
						rootData.set(path, data, context)
				else
					@_set(path, data, context)
			else
				data = path
				for p of data
					@set(p, data[p], context)
		return @

	_set: (prop, data, context) ->
		rootData = @_rootData
		hasValue = rootData.hasValue(prop)

		if @_aliasMap?[prop]
			oldAliasHolder = @_aliasMap[prop]
			if oldAliasHolder.data != data
				oldAliasData = oldAliasHolder.data
				delete @_aliasMap[prop]
				@unbind(oldAliasHolder.bindingPath, oldAliasHolder)

		if data? # 判断是数据还是数据声明
			if data.$provider or data.$dataType
				if data.$provider
					provider = new cola.Provider(data.$provider)

				rootDataType = rootData.dataType
				property = rootDataType.getProperty(prop)
				property ?= rootDataType.addProperty(property: prop)

				property.set("provider", provider) if provider
				property.set("dataType", data.$dataType) if data.$dataType

		if !provider or hasValue
			if data and (data instanceof cola.Entity or data instanceof cola.EntityList) and data._parent and data != rootData._data[prop] # is alias
				@_aliasMap ?= {}

				path = data.getPath("always")
				dataModel = @
				@_aliasMap[prop] = aliasHolder = {
					data: data
					path: path
					bindingPath: path.slice(0).concat("**")
					_processMessage: (bindingPath, path, type, arg) ->
						relativePath = path.slice(@path.length)
						dataModel._onDataMessage([prop].concat(relativePath), type, arg)
						return
				}
				@bind(aliasHolder.bindingPath, aliasHolder)
				@_onDataMessage([prop], cola.constants.MESSAGE_DATA_CHANGE, {
					entity: rootData
					property: prop
					oldValue: oldAliasData
					value: data
				})
			else
				rootData.set(prop, data, context)
		return

	flushAsync: (name, callback) ->
		@_rootData?.flushAsync(name, callback)
		return @

	flushSync: (name) ->
		return @_rootData?.flushSync(name)

	bind: (path, processor) ->
		if !@bindingRegistry
			@bindingRegistry =
				__path: ""
				__processorMap: {}

		if typeof path == "string"
			path = path.split(".")

		if path
			if @_bind(path, processor, false)
				@_bind(path, processor, true)
		return @

	_bind: (path, processor, nonCurrent) ->
		node = @bindingRegistry
		if path
			for part in path
				if !nonCurrent and part.charCodeAt(0) == 33 # `!`
					hasNonCurrent = true
					part = part.substring(1)

				subNode = node[part]
				if !subNode?
					nodePath = if !node.__path then part else (node.__path + "." + part)
					node[part] = subNode =
						__path: nodePath
						__processorMap: {}
				node = subNode

			processor.id ?= cola.uniqueId()
			node.__processorMap[processor.id] = processor
		return hasNonCurrent

	unbind: (path, processor) ->
		if !@bindingRegistry then return

		if typeof path == "string"
			path = path.split(".")

		if path
			if @_unbind(path, processor, false)
				@_unbind(path, processor, true)
		return @

	_unbind: (path, processor, nonCurrent) ->
		node = @bindingRegistry
		for part in path
			if !nonCurrent and part.charCodeAt(0) == 33 # `!`
				hasNonCurrent = true
				part = part.substring(1)
			node = node[part]
			if !node? then break

		delete node.__processorMap[processor.id] if node?
		return hasNonCurrent

	disableObservers: () ->
		if @disableObserverCount < 0 then @disableObserverCount = 1 else @disableObserverCount++
		return @

	enableObservers: () ->
		if @disableObserverCount < 1 then @disableObserverCount = 0 else @disableObserverCount--
		return @

	isObserversDisabled: () ->
		return @disableObserverCount > 0

	_onDataMessage: (path, type, arg = {}) ->
		return unless @bindingRegistry
		return if @isObserversDisabled()

		oldScope = cola.currentScope
		cola.currentScope = @
		try
			arg.timestamp = cola.sequenceNo() unless arg.timestamp
			if path
				node = @bindingRegistry
				lastIndex = path.length - 1
				for part, i in path
					if i == lastIndex then anyPropNode = node["*"]
					@_processDataMessage(anyPropNode, path, type, arg) if anyPropNode
					anyChildNode = node["**"]
					@_processDataMessage(anyChildNode, path, type, arg) if anyChildNode

					node = node[part]
					break unless node
			else
				node = @bindingRegistry
				anyPropNode = node["*"]
				@_processDataMessage(anyPropNode, path, type, arg) if anyPropNode
				anyChildNode = node["**"]
				@_processDataMessage(anyChildNode, path, type, arg) if anyChildNode

			@_processDataMessage(node, path, type, arg, true) if node
		finally
			cola.currentScope = oldScope
		return

	_processDataMessage: (node, path, type, arg, notifyChildren) ->
		processorMap = node.__processorMap
		for id, processor of processorMap
			if !(processor.timestamp >= arg.timestamp) or processor.repeatNotification
				processor.timestamp = arg.timestamp
				processor._processMessage(node.__path, path, type, arg)

		if notifyChildren
			notifyChildren2 = !(cola.constants.MESSAGE_EDITING_STATE_CHANGE <= type <= cola.constants.MESSAGE_VALIDATION_STATE_CHANGE) and !(cola.constants.MESSAGE_LOADING_START <= type <= cola.constants.MESSAGE_LOADING_END)

			if type is cola.constants.MESSAGE_CURRENT_CHANGE
				type = cola.constants.MESSAGE_REFRESH

			for part, subNode of node
				if subNode and (part == "**" or notifyChildren2) and part != "__processorMap" and part != "__path"
					@_processDataMessage(subNode, path, type, arg, true)
		return

class cola.DataModel extends cola.AbstractDataModel

	_getRootData: () ->
		if !@_rootData?
			@_rootDataType ?= new cola.EntityDataType()
			@_rootData = rootData = new cola.Entity(@_rootDataType)
			rootData.state = cola.Entity.STATE_NEW
			dataModel = @
			rootData._setListener(
				onMessage: (path, type, arg) ->
					dataModel._onDataMessage(path, type, arg)
			)
		return @_rootData

	describe: (property, config) ->
		@_getRootData()
		if typeof property is "string"
			propertyDef = @_rootDataType?.getProperty(property)
			if config
				if not propertyDef
					propertyDef = @_rootDataType.addProperty(property: property)

				if typeof config is "string"
					dataType = @getDefinition(config)
					if not dataType
						throw new cola.I18nException("cola.error.unrecognizedDataType", config)
					propertyDef.set("dataType", dataType)
				else
					propertyDef.set(config)
		else if property
			config = property
			for propertyName, propertyConfig of config
				@describe(propertyName, propertyConfig)
		return

	getProperty: (path) ->
		return @_rootDataType?.getProperty(path)

	getDataType: (path) ->
		property = @getProperty(path)
		dataType = property?.get("dataType")
		return dataType

	getDefinition: (name) ->
		definition = @_definitionStore?[name]
		definition ?= cola.DataType.defaultDataTypes[name]
		return definition

	regDefinition: (definition) ->
		name = definition._name
		if !name
			throw new cola.I18nException("cola.error.attributeValueRequired", "name")

		if definition._scope and definition._scope != @model
			throw new cola.I18nException("cola.error.objectNotFree", "DataType(#{definition._name})", "Model")

		store = @_definitionStore
		if !store?
			@_definitionStore = store = {}
		else if store[name]
			throw new cola.I18nException("cola.error.duplicateDefinitionName", cola.error.duplicateDefinitionName)

		store[name] = definition
		return @

	unregDefinition: (name) ->
		if @_definitionStore
			definition = @_definitionStore[name]
			delete @_definitionStore[name]
		return definition

class cola.AliasDataModel extends cola.AbstractDataModel
	constructor: (@model, @alias, @dataType) ->
		parentModel = @model.parent
		while parentModel
			if parentModel.data
				@parent = parentModel.data
				break
			parentModel = parentModel.parent

	getTargetData: () ->
		return @_targetData

	setTargetData: (data, silence) ->
		oldData = @_targetData
		return if oldData == data

		@_targetData = data

		if data and (data instanceof cola.Entity or data instanceof cola.EntityList)
			@_targetPath = data.getPath()

		if !silence
			@_onDataMessage([@alias], cola.constants.MESSAGE_DATA_CHANGE, {
				entity: null
				property: @alias
				value: data
				oldValue: oldData
			})
		return

	describe: (property, config) ->
		if property == @alias
			return super(property, config)
		else
			return @parent.describe(property, config)

	getDataType: (path) ->
		i = path.indexOf(".")
		if i > 0
			if path.substring(0, i) == @alias
				if @dataType
					property = @dataType?.getProperty(path.substring(i + 1))
					dataType = property?.get("dataType")
				return dataType
			else
				return @parent.getDataType(path)
		else if path == @alias
			return @dataType
		else
			return @parent.getDataType(path)

	getDefinition: (name) ->
		return @parent.getDefinition(name)

	regDefinition: (definition) ->
		return @parent.regDefinition(definition)

	unregDefinition: (definition) ->
		return @parent.unregDefinition(definition)

	_bind: (path, processor, nonCurrent) ->
		hasNonCurrent = super(path, processor, nonCurrent)
		i = path.indexOf(".")
		if i > 0
			if path.substring(0, i) != @alias
				@model.watchAllMessages()
		else if path != @alias
			@model.watchAllMessages()
		return hasNonCurrent

	_processMessage: (bindingPath, path, type, arg) ->
		@_onDataMessage(path, type, arg)

		targetPath = @_targetPath
		if targetPath?.length
			matching = true

			for targetPart, i in targetPath
				part = path[i]
				if part and part.charCodeAt(0) == 33 # `!`
					part = part.substring(1)
				if part != targetPart
					matching = false
					break

			if matching
				relativePath = path.slice(targetPath.length)
				@_onDataMessage([@alias].concat(relativePath), type, arg)
		return

	get: (path, loadMode, context) ->
		alias = @alias
		aliasLen = alias.length
		if path.substring(0, aliasLen) == alias
			c = path.charCodeAt(aliasLen)
			if c == 46 # `.`
				if path.indexOf(".") > 0
					targetData = @_targetData
					if targetData instanceof cola.Entity
						return targetData.get(path.substring(aliasLen + 1), loadMode, context)
					else if targetData and typeof targetData == "object"
						return targetData[path.substring(aliasLen + 1)]
			else if isNaN(c)
				return @_targetData
		return @parent.get(path, loadMode, context)

	set: (path, data, context) ->
		alias = @alias
		aliasLen = alias.length
		if path.substring(0, aliasLen) == alias
			c = path.charCodeAt(aliasLen)
			if c == 46 # `.`
				if path.indexOf(".") > 0
					@_targetData?.set(path.substring(aliasLen + 1), data, context)
					return @
			else if isNaN(c)
				@setTargetData(data)
				return @
		@parent.set(path, data, context)
		return @

	dataType: (path) ->
		return @parent.dataType(path)

	regDefinition: (name, definition) ->
		@parent.regDefinition(name, definition)
		return @

	unregDefinition: (name) ->
		return @parent.unregDefinition(name)

	flushAsync: (path, callback) ->
		alias = @alias
		if path.substring(0, alias.length) == alias
			c = path.charCodeAt(1)
			if c == 46 # `.`
				@_targetData?.flushAsync(path.substring(alias.length + 1), callback)
				return @
			else if isNaN(c)
				@_targetData?.flushAsync(callback)
				return @
		@parent.flushAsync(path, callback)
		return @

	flushSync: (path) ->
		alias = @alias
		if path.substring(0, alias.length) == alias
			c = path.charCodeAt(1)
			if c == 46 # `.`
				return @_targetData?.flushSync(path.substring(alias.length + 1))
			else if isNaN(c)
				return @_targetData?.flushSync()
		return @parent.flushSync(path)

	disableObservers: () ->
		@parent.disableObservers()
		return @

	enableObservers: () ->
		@parent.enableObservers()
		return @

	isObserversDisabled: () ->
		return @parent.isObserversDisabled()

###
Root Model
###
new cola.Model(cola.constants.DEFAULT_PATH)

###
Function
###

cola.data = (config) ->
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
		if typeof dataType == "string"
			name = dataType
			dataType = cola.currentScope.dataType(name)
			if !dataType
				throw new cola.I18nException("cola.error.unrecognizedDataType", name)
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
	constructor: (@element, @attr, @expression, scope) ->
		@scope = scope
		@path = path = @expression.path
		if !path and @expression.hasCallStatement
			@path = path = "**"
			@watchingMoreMessage = @expression.hasCallStatement or @expression.convertors

		if path
			if typeof path == "string"
				scope.data.bind(path, @)
			else
				for p in path
					scope.data.bind(p, @)

	destroy: () ->
		path = @path
		if path
			scope = @scope
			if typeof path == "string"
				scope.data.unbind(path, @)
			else
				for p in path
					@scope.data.unbind(p, @)
		return

	_processMessage: (bindingPath, path, type)->
		if cola.constants.MESSAGE_REFRESH <= type <= cola.constants.MESSAGE_CURRENT_CHANGE or @watchingMoreMessage
			@refresh()
		return

	evaluate: (dataCtx) ->
		dataCtx ?= {}
		return @expression.evaluate(@scope, "auto", dataCtx)

	_refresh: () ->
		value = @evaluate(@attr)
		element = @element
		element._duringBindingRefresh = true
		try
			element.set(@attr, value)
		finally
			element._duringBindingRefresh = false
		return

	refresh: () ->
		return unless @_refresh
		if @delay
			cola.util.delay(@, "refresh", 100, () ->
				@_refresh()
				return
			)
		else
			@_refresh()
		return