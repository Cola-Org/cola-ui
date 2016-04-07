#IMPORT_BEGIN
if exports?
	cola = require("./data-type")
	require("./service")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

_getEntityPath = (markNoncurrent) ->
	if !markNoncurrent and @_pathCache then return @_pathCache

	parent = @_parent
	if !parent? then return

	path = []
	self = @
	while parent?
		if parent instanceof _EntityList then lastEntity = self
		part = self._parentProperty
		if part
			if markNoncurrent and self instanceof _EntityList
				if markNoncurrent == "always" or lastEntity and self.current != lastEntity
					path.push("!" + part)
				else
					path.push(part)
			else
				path.push(part)
		self = parent
		parent = parent._parent
	path = path.reverse()
	if !markNoncurrent then @_pathCache = path
	return path

_watch = (path, watcher) ->
	if path instanceof Function
		watcher = path
		path = "*"
	@_watchers ?= {}

	holder = @_watchers[path]
	if not holder
		@_watchers[path] =
			path: path.split(".")
			watchers: [watcher]
	else
		holder.watchers.push(watcher)
	return

_unwatch = (path, watcher) ->
	return unless @_watchers
	if path instanceof Function
		watcher = path
		path = "*"

	watchers = @_watchers
	if not watcher
		delete watchers[path]
	else
		holder = watchers[path]
		if holder
			for w, i in holder.watchers
				if w is watcher
					holder.watchers.splice(i, 1)
					break

			if not holder.watchers.length
				delete watchers[path]
	return

_triggerWatcher = (path, type, arg) ->
	if @_watchers
		for p, holder of @_watchers
			shouldTrigger = false
			if p is "**"
				shouldTrigger = true
			else if p is "*"
				shouldTrigger = path.length < 2
			else
				pv = holder.path
				if pv.length >= path.length
					shouldTrigger = true
					for s, i in pv
						if i is pv.length - 1
							if s is "**"
								break
							else if s is "*"
								shouldTrigger = i is path.length - 1
								break

						if s isnt path[i]
							shouldTrigger = false
							break

			if shouldTrigger
				for watch in holder.watchers
					watch.call(@, path, type, arg)

	if @_parent
		path.unshift(@_parentProperty) if @_parentProperty
		@_parent._triggerWatcher(path, type, arg)
	return

_matchValue = (value, propFilter) ->
	if propFilter.strict
		if not propFilter.caseSensitive and typeof propFilter.value == "string"
			return (value + "").toLowerCase() == propFilter.value
		else
			return value == propFilter.value
	else
		if not propFilter.caseSensitive
			return (value + "").toLowerCase().indexOf(propFilter.value) > -1
		else
			return (value + "").indexOf(propFilter.value) > -1

cola._filterCollection = (collection, criteria, caseSensitive, strict) ->
	return collection unless collection and criteria

	if cola.util.isSimpleValue(criteria)
		if not caseSensitive then criteria = (criteria + "").toLowerCase()
		criteria =
			"$": {
				value: criteria
				caseSensitive: caseSensitive
				strict: strict
			}

	if typeof criteria == "object"
		for prop, propFilter of criteria
			if typeof propFilter == "string"
				criteria[prop] = {
					value: propFilter.toLowerCase()
					caseSensitive: caseSensitive
					strict: strict
				}
			else
				propFilter.caseSensitive ?= caseSensitive
				if not propFilter.caseSensitive and typeof propFilter.value == "string"
					propFilter.value = propFilter.value.toLowerCase()

				propFilter.strict ?= strict
				if not propFilter.strict
					propFilter.value = if propFilter.value then propFilter.value + "" else ""

		filtered = []
		filtered.$origin = collection.$origin or collection
		cola.each collection, (item) ->
			matches = false

			if cola.util.isSimpleValue(item)
				if criteria.$
					matches = _matchValue(v, criteria.$)
			else
				for prop, propFilter of criteria
					if prop == "$"
						if item instanceof cola.Entity
							data = item._data
						else
							data = item

						for p, v of data
							if _matchValue(v, propFilter)
								matches = true
								break
						if matches then break
					else if item instanceof cola.Entity
						if _matchValue(item.get(prop), propFilter)
							matches = true
							break
					else
						if _matchValue(item[prop], propFilter)
							matches = true
							break
			if matches
				filtered.push(item)
			return
		return filtered
	else if typeof criteria == "function"
		filtered = []
		filtered.$origin = collection.$origin or collection
		cola.each collection, (item) ->
			filtered.push(item) if criteria(item, caseSensitive, strict)
			return
		return filtered
	else
		return collection

cola._sortCollection = (collection, comparator, caseSensitive) ->
	return null unless collection
	return collection if not comparator? or comparator == "$none"

	if collection instanceof cola.EntityList
		origin = collection
		collection = collection.toArray()
		collection.$origin = origin

	if comparator
		if comparator == "$reverse"
			return collection.reverse();
		else if typeof comparator == "string"
			comparatorProps = []
			for part in comparator.split(",")
				c = part.charCodeAt(0)
				propDesc = false
				if c == 43 # `+`
					prop = part.substring(1)
				else if c == 45 # `-`
					prop = part.substring(1)
					propDesc = true
				else
					prop = part
				comparatorProps.push(prop: prop, desc: propDesc)

			comparator = (item1, item2) ->
				for comparatorProp in comparatorProps
					value1 = null
					value2 = null
					prop = comparatorProp.prop
					if prop
						if prop == "$random"
							return Math.random() * 2 - 1
						else
							if item1 instanceof cola.Entity
								value1 = item1.get(prop)
							else if cola.util.isSimpleValue(item1)
								value1 = item1
							else
								value1 = item1[prop]
							if !caseSensitive and typeof value1 == "string"
								value1 = value1.toLowerCase()

							if item2 instanceof cola.Entity
								value2 = item2.get(prop)
							else if cola.util.isSimpleValue(item2)
								value2 = item2
							else
								value2 = item2[prop]
							if !caseSensitive and typeof value2 == "string"
								value2 = value2.toLowerCase()

							result = 0
							if !value1? then result = -1
							else if !value2? then result = 1
							else if value1 > value2 then result = 1
							else if value1 < value2 then result = -1
							if result != 0
								return if comparatorProp.desc then (0 - result) else result
					else
						result = 0
						if !item1? then result = -1
						else if !item2? then result = 1
						else if item1 > item2 then result = 1
						else if item1 < item2 then result = -1
						if result != 0
							return if comparatorProp.desc then (0 - result) else result
				return 0
	else
		comparator = (item1, item2) ->
			result = 0
			if !caseSensitive
				if typeof item1 == "string" then item1 = item1.toLowerCase()
				if typeof item2 == "string" then item2 = item2.toLowerCase()
			if !item1? then result = -1
			else if !item2? then result = 1
			else if item1 > item2 then result = 1
			else if item1 < item2 then result = -1
			return result

	comparatorFunc = (item1, item2) ->
		return comparator(item1, item2)
	return collection.sort(comparatorFunc)

############################

class cola.Entity

	@STATE_NONE: "none"
	@STATE_NEW: "new"
	@STATE_MODIFIED: "modified"
	@STATE_DELETED: "deleted"

	state: @STATE_NONE

	_disableObserverCount: 0
	_disableWriteObservers: 0

#_parent
#_parentProperty
#_providerInvoker
#_disableWriteObservers

	constructor: (data, dataType) ->
		@id = cola.uniqueId()
		@timestamp = cola.sequenceNo()
		@dataType = dataType
		@_data = {}
		if data?
			@_disableWriteObservers++
			@set(data)
			@_disableWriteObservers--

	hasValue: (prop) ->
		return @_data.hasOwnProperty(prop) or @dataType?.getProperty(prop)?

	get: (prop, loadMode = "async", context) ->
		if loadMode and (typeof loadMode == "function" or typeof loadMode == "object")
			callback = loadMode
			loadMode = "async"

		if prop.indexOf(".") > 0
			return _evalDataPath(@, prop, false, loadMode, callback, context)
		else
			return @_get(prop, loadMode, callback, context)

	_get: (prop, loadMode, callback, context) ->
		loadData = (provider) ->
			retValue = undefined
			providerInvoker = provider.getInvoker(@)
			if loadMode == "sync"
				retValue = providerInvoker.invokeSync()
				retValue = @_set(prop, retValue)
				if retValue and (retValue instanceof cola.EntityList or retValue instanceof cola.Entity)
					retValue._providerInvoker = providerInvoker
			else if loadMode == "async"
				if context
					context.unloaded = true
					context.providerInvokers ?= []
					context.providerInvokers.push(providerInvoker)

				@_data[prop] = providerInvoker
				notifyArg = {
					data: @
					property: prop
				}
				@_notify(cola.constants.MESSAGE_LOADING_START, notifyArg)
				providerInvoker.invokeAsync(
					complete: (success, result) =>
						@_notify(cola.constants.MESSAGE_LOADING_END, notifyArg)

						if @_data[prop] != providerInvoker then success = false
						if success
							result = @_set(prop, result)
							retValue = result
							if result and (result instanceof cola.EntityList or result instanceof cola.Entity)
								result._providerInvoker = providerInvoker
						else
							@_set(prop, null)
						if callback
							cola.callback(callback, success, result)
						return
				)
			else
				cola.callback(callback, true, undefined)
			return retValue

		property = @dataType?.getProperty(prop)

		value = @_data[prop]
		if value == undefined
			if property
				provider = property.get("provider")
				context?.unloaded = true
				if provider and provider._loadMode is "lazy"
					value = loadData.call(@, provider)
					callbackProcessed = true
		else if value instanceof cola.Provider
			value = loadData.call(@, value)
			callbackProcessed = true
		else if value instanceof cola.AjaxServiceInvoker
			providerInvoker = value
			if loadMode == "sync"
				value = providerInvoker.invokeSync()
				value = @_set(prop, value)
			else if loadMode == "async"
				if callback then providerInvoker.callbacks.push(callback)
				callbackProcessed = true
				value = undefined
			else
				value = undefined

			if context
				context.unloaded = true
				context.providerInvokers ?= []
				context.providerInvokers.push(providerInvoker)

		if callback and not callbackProcessed
			cola.callback(callback, true, value)
		return value

	set: (prop, value, context) ->
		if typeof prop == "string"
			_setValue(@, prop, value, context)
		else if prop and (typeof prop == "object")
			config = prop
			for prop of config
				if prop.charAt(0) == "$" then continue
				@set(prop, config[prop])
		return @

	_jsonToEntity: (value, dataType, aggregated, provider) ->
		result = cola.DataType.jsonToEntity(value, dataType, aggregated, provider?._pageSize)
		if result and provider
			result._providerInvoker = provider.getInvoker(@)
		return result

	_set: (prop, value) ->
		oldValue = @_data[prop]

		property = @dataType?.getProperty(prop)
		if value?
			if value instanceof cola.Provider
				changed = (oldValue != undefined)
			else
				if property
					dataType = property._dataType
					provider = property._provider

				if dataType
					if value?
						if dataType instanceof cola.StringDataType and typeof value != "string" or dataType instanceof cola.BooleanDataType and typeof value != "boolean" or dataType instanceof cola.NumberDataType and typeof value != "number" or dataType instanceof cola.DateDataType and !(value instanceof Date)
							value = dataType.parse(value)
						else if dataType instanceof cola.EntityDataType
							matched = true
							if value instanceof _Entity
								matched = value.dataType == dataType and !property._aggregated
							else if value instanceof _EntityList
								matched = value.dataType == dataType and property._aggregated
							else
								value = @_jsonToEntity(value, dataType, property._aggregated, provider)

							if !matched
								expectedType = dataType.get("name")
								actualType = value.dataType?.get("name") or "undefined"
								if property._aggregated then expectedType = "[#{expectedType}]"
								if value instanceof cola.EntityList then actualType = "[#{actualType}]"
								throw new cola.Exception("Unmatched DataType. expect \"#{expectedType}\" but \"#{actualType}\".")
						else
							value = dataType.parse(value)
				else if typeof value == "object" and value?
					if value instanceof Array
						convert = true
						if value.length > 0
							item = value[0]
							if cola.util.isSimpleValue(item) then convert = false
						value = @_jsonToEntity(value, null, true, provider) if convert
					else if value.hasOwnProperty("$data")
						value = @_jsonToEntity(value, null, true, provider)
					else if value instanceof Date
					else
						value = @_jsonToEntity(value, null, false, provider)
				changed = oldValue != value
		else
			changed = oldValue != value

		if changed
			if property
				if property._validators and property._rejectInvalidValue
					messages = null
					for validator in property._validators
						if value? or validator instanceof cola.RequiredValidator
							unless validator._disabled and validator instanceof cola.AsyncValidator and validator.get("async")
								message = validator.validate(value)
								if message
									messages ?= []
									if message instanceof Array
										Array::push.apply(messages, message)
									else
										messages.push(message)
					if messages
						for message in messages
							if message is VALIDATION_ERROR
								throw new cola.Exception(message.text)

			if @_disableWriteObservers == 0
				if oldValue? and (oldValue instanceof _Entity or oldValue instanceof _EntityList)
					delete oldValue._parent
					delete oldValue._parentProperty
				if @state == _Entity.STATE_NONE then @setState(_Entity.STATE_MODIFIED)

			@_data[prop] = value

			if value? and (value instanceof _Entity or value instanceof _EntityList)
				if value._parent and value._parent != @
					throw new cola.Exception("Entity/EntityList is already belongs to another owner. \"#{prop}\"")

				value._parent = @
				value._parentProperty = prop
				value._setObserver(@_observer)
				value._onPathChange()
				@_mayHasSubEntity = true

			@timestamp = cola.sequenceNo()
			if @_disableWriteObservers == 0
				@_notify(cola.constants.MESSAGE_PROPERTY_CHANGE, {
					entity: @
					property: prop
					value: value
					oldValue: oldValue
				})

			if messages != undefined
				@_messageHolder?.clear(prop)
				@addMessage(prop, messages)

				if value?
					for validator in property._validators
						if not validator._disabled and validator instanceof cola.AsyncValidator and validator.get("async")
							validator.validate(value, (message) =>
								if message then @addMessage(prop, message)
								return
							)
			else
				@validate(prop)
		return value

	remove: () ->
		if @_parent
			if @_parent instanceof _EntityList
				@_parent.remove(@)
			else
				@setState(_Entity.STATE_DELETED)
				@_parent.set(@_parentProperty, null)
		else
			@setState(_Entity.STATE_DELETED)
		return @

	createChild: (prop, data) ->
		if data and data instanceof Array
			throw new cola.Exception("Unmatched DataType. expect \"Object\" but \"Array\".")

		property = @dataType?.getProperty(prop)
		propertyDataType = property?._dataType
		if propertyDataType and !(propertyDataType instanceof cola.EntityDataType)
			throw new cola.Exception("Unmatched DataType. expect \"cola.EntityDataType\" but \"#{propertyDataType._name}\".")

		if property?._aggregated
			entityList = @_get(prop, "never")
			if !entityList?
				entityList = new cola.EntityList(null, propertyDataType)

				provider = property._provider
				if provider
					entityList.pageSize = provider._pageSize
					entityList._providerInvoker = provider.getInvoker(@)

				@_disableWriteObservers++
				@_set(prop, entityList)
				@_disableWriteObservers--
			return entityList.insert(data)
		else
			return @_set(prop, data)

	createBrother: (data) ->
		if data and data instanceof Array
			throw new cola.Exception("Unmatched DataType. expect \"Object\" but \"Array\".")

		brother = new _Entity(data, @dataType)
		brother.setState(_Entity.STATE_NEW)
		parent = @_parent
		if parent and parent instanceof _EntityList
			parent.insert(brother)
		return brother

	setState: (state) ->
		return @ if @state == state

		if @state == _Entity.STATE_NONE and state == _Entity.STATE_MODIFIED
			@_storeOldData()

		oldState = @state
		@state = state

		@_notify(cola.constants.MESSAGE_EDITING_STATE_CHANGE, {
			entity: @
			oldState: oldState
			state: state
		})
		return @

	_storeOldData: () ->
		return if @_oldData

		data = @_data
		oldData = @_oldData = {}
		for p, value of data
			if value and (value instanceof _Entity or value instanceof _EntityList)
				continue
			oldData[p] = value
		return

	getOldValue: (prop) ->
		return @_oldData?[prop]

	reset: (prop) ->
		if prop
			@_set(prop, undefined)
			@clearMessages(prop)
		else
			@disableObservers()
			data = @_data
			for prop, value of data
				if value != undefined
					delete data[prop]
			@resetState()
			@enableObservers()
			@_notify(cola.constants.MESSAGE_REFRESH, {data: @})
		return @

	resetState: () ->
		delete @_oldData
		@clearMessages()
		@setState(_Entity.STATE_NONE)
		return @

	getDataType: (path) ->
		if path
			dataType = @dataType
			if dataType
				parts = path.split(".")
				for part in parts
					property = dataType.getProperty?(part)
					if !property? then break
					dataType = property.get("dataType")
					if !dataType? then break
		else
			dataType = @dataType

		if !dataType?
			data = @get(path)
			dataType = data?.dataType
		return dataType

	getPath: _getEntityPath

	flush: (property, loadMode = "async") ->
		propertyDef = @dataType.getProperty(property)
		provider = propertyDef?._provider
		if not provider
			throw new cola.Exception("Provider undefined.")

		@_set(property, undefined)

		if loadMode and (typeof loadMode == "function" or typeof loadMode == "object")
			callback = loadMode
			loadMode = "async"

		oldLoadMode = provider._loadMode
		provider._loadMode = "lazy"
		try
			return @_get(property, loadMode, {
				complete: (success, result) =>
					cola.callback(callback, success, result)
					return
			})
		finally
			provider._loadMode = oldLoadMode
		return

	_setObserver: (observer) ->
		return if @_observer == observer
		@_observer = observer
		if @_mayHasSubEntity
			data = @_data
			for p, value of data
				if value and (value instanceof _Entity or value instanceof _EntityList)
					value._setObserver(observer)
		return

	watch: _watch
	unwatch: _unwatch
	_triggerWatcher: _triggerWatcher

	_onPathChange: () ->
		delete @_pathCache
		if @_mayHasSubEntity
			data = @_data
			for p , value of data
				if value and (value instanceof _Entity or value instanceof _EntityList)
					value._onPathChange()
		return

	disableObservers: () ->
		if @_disableObserverCount < 0 then @_disableObserverCount = 1 else @_disableObserverCount++
		return @

	enableObservers: () ->
		if @_disableObserverCount < 1 then @_disableObserverCount = 0 else @_disableObserverCount--
		return @

	notifyObservers: () ->
		@_notify(cola.constants.MESSAGE_REFRESH, { data: @ })
		return @

	_notify: (type, arg) ->
		if @_disableObserverCount is 0
			path = @getPath(true)

			if (type is cola.constants.MESSAGE_PROPERTY_CHANGE or type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE or type is cola.constants.MESSAGE_LOADING_START or type is cola.constants.MESSAGE_LOADING_END) and arg.property
				if path
					path = path.concat(arg.property)
				else
					path = [arg.property]
			@_doNotify(path, type, arg)

			if type is cola.constants.MESSAGE_PROPERTY_CHANGE or type is cola.constants.MESSAGE_REFRESH
				@_triggerWatcher([arg.property or "*"], type, arg)
		return

	_doNotify: (path, type, arg) ->
		@_observer?.onMessage(path, type, arg)
		return

	_validate: (prop) ->
		property = @dataType.getProperty(prop)
		if property
			if property._validators
				data = @_data[prop]
				if data and (data instanceof cola.Provider or data instanceof cola.AjaxServiceInvoker)
					return

				for validator in property._validators
					if not validator._disabled
						if validator instanceof cola.AsyncValidator and validator.get("async")
							validator.validate(data, (message) =>
								if message then @addMessage(prop, message)
								return
							)
						else
							message = validator.validate(data)
							if message
								@_addMessage(prop, message)
								messageChanged = true
		return messageChanged

	validate: (prop) ->
		if  @_messageHolder
			oldKeyMessage = @_messageHolder.getKeyMessage()
			@_messageHolder.clear(prop)

		if @dataType
			if prop
				@_validate(prop)
				@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @, property: prop})
			else
				for property in @dataType.getProperties().elements
					@_validate(property._property)
					@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @, property: property._property})

		keyMessage = @_messageHolder?.getKeyMessage()
		if (oldKeyMessage or keyMessage) and oldKeyMessage isnt keyMessage
			@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @})
		return not (keyMessage?.type is VALIDATION_ERROR)

	_addMessage: (prop, message) ->
		messageHolder = @_messageHolder
		if not messageHolder
			@_messageHolder = messageHolder = new _Entity.MessageHolder()
		if message instanceof Array
			for m in message
				if messageHolder.add(prop, m) then topKeyChanged = true
		else
			if messageHolder.add(prop, message) then topKeyChanged = true
		return topKeyChanged

	addMessage: (prop, message) ->
		if arguments.length is 1
			message = prop
			prop = "$"
		if prop is "$"
			@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @})
		else
			topKeyChanged = @_addMessage(prop, message)
			@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @, property: prop})
			if topKeyChanged then @_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @})
		return @

	getKeyMessage: (prop) ->
		return @_messageHolder?.getKeyMessage(prop)

	getMessages: (prop) ->
		return @_messageHolder?.getMessages(prop)

	clearMessages: (prop) ->
		return @ unless @_messageHolder
		if prop
			hasPropMessage = @_messageHolder.getKeyMessage(prop)
		topKeyChanged = @_messageHolder.clear(prop)
		if hasPropMessage then @_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @, property: prop})
		if topKeyChanged then @_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @})
		return @

	findMessages: (prop, type) ->
		return @_messageHolder?.findMessages(prop, type)

	toJSON: (options) ->
		state = options?.state or false
		oldData = options?.oldData or false

		data = @_data
		json = {}
		for prop, value of data
			if value
				if value instanceof cola.AjaxServiceInvoker
					continue
				else if value instanceof _Entity or value instanceof _EntityList
					value = value.toJSON(options)
			json[prop] = value

		if state then json.$state = @state
		if oldData and @_oldData
			json.$oldData = @_oldData
		return json

class LinkedList
	_size: 0

	_insertElement: (element, insertMode, refEntity) ->
		if !@_first
			@_first = @_last = element
		else
			if !insertMode || insertMode == "end"
				element._previous = @_last
				@_last._next = element
				@_last = element
			else if insertMode == "before"
				previous = refEntity._previous
				previous?._next = element
				refEntity._previous = element
				element._previous = previous
				element._next = refEntity
				if @_first == refEntity then @_first = element
			else if insertMode == "after"
				next = refEntity._next
				next?._previous = element
				refEntity._next = element
				element._previous = refEntity
				element._next = next
				if @_last == refEntity then @_last = element
			else if insertMode == "begin"
				element._next = @_first
				@_first._previous = element
				@_first = element
		element._page = @
		@_size++
		return

	_removeElement: (element) ->
		previous = element._previous
		next = element._next
		previous?._next = next;
		next?._previous = previous;
		if @_first == element then @_first = next
		if @_last == element then @_last = previous
		@_size++
		return

	_clearElements: () ->
		@_first = @_last = null
		@_size = 0
		return

class Page extends LinkedList
	loaded: false
	entityCount: 0

	constructor: (@entityList, @pageNo) ->

	initData: (json) ->
		rawJson = json
		entityList = @entityList

		if json.hasOwnProperty("$data") then json = rawJson.$data
		if not (json instanceof Array)
			throw new cola.Exception("Unmatched DataType. expect \"Array\" but \"Object\".")

		dataType = entityList.dataType
		for data in json
			entity = new _Entity(data, dataType)
			@_insertElement(entity)

		entityList.totalEntityCount = rawJson.$entityCount if rawJson.$entityCount?
		if entityList.totalEntityCount?
			if entityList.pageSize
				entityList.pageCount = parseInt((entityList.totalEntityCount + entityList.pageSize - 1) / entityList.pageSize)
			entityList.pageCountDetermined = true

		entityList.entityCount += json.length
		entityList.timestamp = cola.sequenceNo()

		entityList._notify(cola.constants.MESSAGE_REFRESH, {
			data: entityList
		})
		return

	_insertElement: (entity, insertMode, refEntity) ->
		super(entity, insertMode, refEntity)

		entityList = @entityList
		entity._page = @
		entity._parent = entityList
		delete entity._parentProperty

		if !@dontAutoSetCurrent and !entityList.current?
			if entity.state != _Entity.STATE_DELETED
				entityList.current = entity
				entityList._setCurrentPage(entity._page)

		entity._setObserver(entityList._observer)
		entity._onPathChange()
		@entityCount++ if entity.state != _Entity.STATE_DELETED
		return

	_removeElement: (entity) ->
		super(entity)
		delete entity._page
		delete entity._parent
		entity._setObserver(null)
		entity._onPathChange()
		@entityCount-- if entity.state != _Entity.STATE_DELETED
		return

	_clearElements: () ->
		entity = @_first
		while entity
			delete entity._page
			delete entity._parent
			entity._setObserver(null)
			entity._onPathChange()
			entity = entity._next
		@entityCount = 0
		super()
		return

	loadData: (callback) ->
		providerInvoker = @entityList._providerInvoker
		if providerInvoker
			providerInvoker.pageSize = @entityList.pageSize
			providerInvoker.pageNo = @pageNo
			if callback
				providerInvoker.invokeAsync(
					complete: (success, result) =>
						if success then @initData(result)
						cola.callback(callback, success, result)
				)
			else
				result = providerInvoker.invokeSync()
				@initData(result)
		return

class cola.EntityList extends LinkedList
	current: null
	entityCount: 0

	pageMode: "append"
	pageSize: 0
	pageNo: 1
	pageCount: 1

	_disableObserverCount: 0

# totalEntityCount
#_parent
#_parentProperty
#_providerInvoker

	constructor: (array, dataType) ->
		@id = cola.uniqueId()
		@timestamp = cola.sequenceNo()
		@dataType = dataType
		if array then @fillData(array)

	fillData: (array) ->
		page = @_findPage(@pageNo)
		page ?= new Page(@, @pageNo)
		@_insertElement(page, "begin")
		page.initData(array)
		return

	_setObserver: (observer) ->
		return if @_observer == observer
		@_observer = observer

		page = @_first
		if !page then return

		next = page._first
		while page
			if next
				next._setObserver(observer)
				next = next._next
			else
				page = page._next
				next = page?._first
		return

	watch: _watch
	unwatch: _unwatch
	_triggerWatcher: _triggerWatcher

	_setCurrentPage: (page) ->
		@_currentPage = page
		@pageNo = page?.pageNo or 1
		@timestamp = cola.sequenceNo()
		return

	_onPathChange: () ->
		delete @_pathCache

		page = @_first
		if !page then return

		next = page._first
		while page
			if next
				next._onPathChange()
				next = next._next
			else
				page = page._next
				next = page?._first
		return

	_findPrevious: (entity) ->
		return if entity and entity._parent != @

		if entity
			page = entity._page
			previous = entity._previous
		else
			page = @_last
			previous = page._last

		while page
			if previous
				if previous.state != _Entity.STATE_DELETED
					return previous
				else
					previous = previous._previous
			else
				page = page._previous
				previous = page?._last
		return

	_findNext: (entity) ->
		return if entity and entity._parent != @

		if entity
			page = entity._page
			next = entity._next
		else
			page = @_first
			next = page._first

		while page
			if next
				if next.state != _Entity.STATE_DELETED
					return next
				else
					next = next._next
			else
				page = page._next
				next = page?._first
		return

	_findPage: (pageNo) ->
		if pageNo < 1 then return null
		if pageNo > @pageCount
			if @pageCountDetermined or pageNo > (@pageCount + 1)
				return null

		page = @_currentPage or @_first
		if !page then return null

		if page.pageNo == pageNo
			return page
		else if page.pageNo < pageNo
			page = page._next
			while page?
				if page.pageNo == pageNo
					return page
				else if page.pageNo > pageNo
					break
				page = page._next
		else
			page = page._previous
			while page?
				if page.pageNo == pageNo
					return page
				else if page.pageNo < pageNo
					break
				page = page._previous
		return null

	_createPage: (pageNo) ->
		if pageNo < 1 then return null
		if pageNo > @pageCount
			if @pageCountDetermined or pageNo > (@pageCount + 1)
				return null

		insertMode = "end"
		refPage = @_currentPage or @_first
		if refPage
			if refPage.page == pageNo - 1
				insertMode = "after"
			else if refPage.page == pageNo + 1
				insertMode = "before"
			else
				page = @_last
				while page
					if page.pageNo < pageNo
						refPage = page
						insertMode = "after"
						break
					page = page._previous

		page = new Page(@, pageNo)
		@_insertElement(page, insertMode, refPage)
		return page

	hasNextPage: () ->
		pageNo = @pageNo + 1
		return not @pageCountDetermined or pageNo <= @pageCount

	_loadPage: (pageNo, setCurrent, loadMode = "async") ->
		if loadMode and (typeof loadMode == "function" or typeof loadMode == "object")
			callback = loadMode
			loadMode = "async"

		page = @_findPage(pageNo)
		if page != @_currentPage
			if page
				@_setCurrentPage(page)
				if setCurrent
					entity = page._first
					while entity
						if entity.state != _Entity.STATE_DELETED
							@setCurrent(entity)
							break;
						entity = entity._next

				cola.callback(callback, true)
			else if loadMode isnt "never"
				if setCurrent then @setCurrent(null)
				page = @_createPage(pageNo)
				if loadMode is "async"
					page.loadData(
						complete: (success, result) =>
							if success
								@_setCurrentPage(page)
								if page.entityCount and @pageCount < pageNo
									@pageCount = pageNo
							cola.callback(callback, success, result)
							return
					)
				else
					page.loadData()
					@_setCurrentPage(page)
					cola.callback(callback, true)
		return @

	loadPage: (pageNo, loadMode) ->
		return @_loadPage(pageNo, false, loadMode)

	gotoPage: (pageNo, loadMode) ->
		if pageNo < 1
			pageNo = 1
		else if @pageCountDetermined and pageNo > @pageCount
			pageNo = @pageCount
		return @_loadPage(pageNo, true, loadMode)

	firstPage: (loadMode) ->
		@gotoPage(1, loadMode)
		return @

	previousPage: (loadMode) ->
		pageNo = @pageNo - 1
		if pageNo < 1 then pageNo = 1
		@gotoPage(pageNo, loadMode)
		return @

	nextPage: (loadMode) ->
		pageNo = @pageNo + 1
		if @pageCountDetermined and pageNo > @pageCount then pageNo = @pageCount
		@gotoPage(pageNo, loadMode)
		return @

	lastPage: (loadMode) ->
		@gotoPage(@pageCount, loadMode)
		return @

	insert: (entity, insertMode, refEntity) ->
		if insertMode == "before" or insertMode == "after"
			if refEntity and refEntity._parent != @
				refEntity = null
			refEntity ?= @current
			if refEntity then page = refEntity._page
		else if @pageMode == "append"
			if insertMode == "end"
				page = @_last
			else if insertMode == "begin"
				page = @_first

		if !page
			page = @_currentPage
			if !page
				@gotoPage(1)
				page = @_currentPage

		if entity instanceof _Entity
			if entity._parent and entity._parent != @
				throw new cola.Exception("Entity is already belongs to another owner. \"#{@._parentProperty or "Unknown"}\".")
		else
			entity = new _Entity(entity, @dataType)
			entity.setState(_Entity.STATE_NEW)

		page.dontAutoSetCurrent = true
		page._insertElement(entity, insertMode, refEntity)
		page.dontAutoSetCurrent = false

		if entity.state != _Entity.STATE_DELETED then @entityCount++

		@timestamp = cola.sequenceNo()
		@_notify(cola.constants.MESSAGE_INSERT, {
			entityList: @
			entity: entity
			insertMode: insertMode
			refEntity: refEntity
		})

		if !@current then @setCurrent(entity)
		return entity

	remove: (entity, detach) ->
		if !entity?
			entity = @current
			if !entity? then return undefined

		return undefined if entity._parent != @

		if entity == @current
			changeCurrent = true
			newCurrent = @_findNext(entity)
			if !newCurrent then newCurrent = @_findPrevious(entity)

		page = entity._page
		if detach
			page._removeElement(entity)
			@entityCount--
		else if entity.state == _Entity.STATE_NEW
			entity.setState(_Entity.STATE_DELETED)
			page._removeElement(entity)
			@entityCount--
		else if entity.state != _Entity.STATE_DELETED
			entity.setState(_Entity.STATE_DELETED)
			@entityCount--

		@timestamp = cola.sequenceNo()
		@_notify(cola.constants.MESSAGE_REMOVE, {
			entityList: @
			entity: entity
		})

		@setCurrent(newCurrent) if changeCurrent
		return entity

	setCurrent: (entity) ->
		if @current == entity or entity?.state == cola.Entity.STATE_DELETED then return @

		return @ if entity and entity._parent != @

		oldCurrent = @current
		oldCurrent._onPathChange() if oldCurrent

		@current = entity

		if entity
			@_setCurrentPage(entity._page)
			entity._onPathChange()

		@_notify(cola.constants.MESSAGE_CURRENT_CHANGE, {
			entityList: @
			current: entity
			oldCurrent: oldCurrent
		})
		return @

	first: () ->
		entity = @_findNext()
		if entity
			@setCurrent(entity)
			return entity
		else
			return @current

	previous: () ->
		entity = @_findPrevious(@current)
		if entity
			@setCurrent(entity)
			return entity
		else
			return @current

	next: () ->
		entity = @_findNext(@current)
		if entity
			@setCurrent(entity)
			return entity
		else
			return @current

	last: () ->
		entity = @_findPrevious()
		if entity
			@setCurrent(entity)
			return entity
		else
			return @current

	_reset: () ->
		@current = null
		@entityCount = 0
		@pageNo = 1
		@pageCount = 1

		page = @_first
		while page
			page._clearElements()
			page = page._next

		@timestamp = cola.sequenceNo()
		return @

	disableObservers: () ->
		if @_disableObserverCount < 0 then @_disableObserverCount = 1 else @_disableObserverCount++
		return @

	enableObservers: () ->
		if @_disableObserverCount < 1 then @_disableObserverCount = 0 else @_disableObserverCount--
		return @

	notifyObservers: () ->
		@_notify(cola.constants.MESSAGE_REFRESH, { data: @ })
		return @

	_notify: (type, arg) ->
		if @_disableObserverCount == 0
			@_observer?.onMessage(@getPath(true), type, arg)

			if type is cola.constants.MESSAGE_CURRENT_CHANGE or type is cola.constants.MESSAGE_INSERT or type is cola.constants.MESSAGE_REMOVE
				@_triggerWatcher(["*"], type, arg)
		return

	flush: (loadMode) ->
		if !@_providerInvoker?
			throw new cola.Exception("Provider undefined.")

		if loadMode and (typeof loadMode == "function" or typeof loadMode == "object")
			callback = loadMode
			loadMode = "async"

		@_reset()
		page = @_findPage(@pageNo)
		if !page then @_createPage(@pageNo)

		if loadMode is "async"
			notifyArg = {
				data: @
			}
			@_notify(cola.constants.MESSAGE_LOADING_START, notifyArg)
			page.loadData(
				complete: (success, result)  =>
					cola.callback(callback, success, result)
					@_notify(cola.constants.MESSAGE_LOADING_END, notifyArg)
			)
		else
			page.loadData()
		return @

	each: (fn, options) ->
		page = @_first
		return @ unless page

		if options?
			if typeof options == "boolean"
				deleted = options
			else
				deleted = options.deleted
				pageNo = options.pageNo
				if not pageNo and options.currentPage
					pageNo = @pageNo

		if pageNo > 1
			page = @_findPage(pageNo)
			return @ unless page

		next = page._first
		i = 0
		while page
			if next
				if deleted or next.state != _Entity.STATE_DELETED
					if fn.call(@, next, i++) == false then break
				next = next._next
			else if page and not pageNo
				page = page._next
				next = page?._first
			else
				break
		return @

	getPath: _getEntityPath

	toJSON: (options) ->
		deleted = options?.deleted

		array = []
		page = @_first
		if page
			next = page._first
			while page
				if next
					if deleted or next.state != _Entity.STATE_DELETED
						array.push(next.toJSON(options))
					next = next._next
				else
					page = page._next
					next = page?._first
		return array

	toArray: () ->
		array = []
		page = @_first
		if page
			next = page._first
			while page
				if next
					if next.state != _Entity.STATE_DELETED
						array.push(next)
					next = next._next
				else
					page = page._next
					next = page?._first
		return array

	filter: (criteria) ->
		return cola._filterCollection(@, criteria)

	where: (criteria) ->
		return cola._filterCollection(@, criteria, true, true)

	find: (criteria) ->
		return null unless criteria

		if cola.util.isSimpleValue(criteria)
			criteria =
				"$": {
					value: criteria
					caseSensitive: true
					strict: true
				}

		result = null
		if typeof criteria == "object"
			for prop, propFilter of criteria
				if typeof propFilter == "string"
					criteria[prop] = {
						value: propFilter.toLowerCase()
						caseSensitive: true
						strict: true
					}
				else
					propFilter.caseSensitive ?= true
					propFilter.strict ?= true

			cola.each @, (item) ->
				matches = false

				if cola.util.isSimpleValue(item)
					if criteria.$
						matches = _matchValue(v, criteria.$)
				else
					for prop, propFilter of criteria
						if prop == "$"
							if item instanceof cola.Entity
								data = item._data
							else
								data = item

							for p, v of data
								if _matchValue(v, propFilter)
									matches = true
									break
							if matches then break
						else if item instanceof cola.Entity
							if _matchValue(item.get(prop), propFilter)
								matches = true
								break
						else
							if _matchValue(item[prop], propFilter)
								matches = true
								break
				if matches then result = item
				return
		else if typeof criteria == "function"
			filtered = []
			filtered.$origin = collection.$origin or collection
			cola.each collection, (item) ->
				if criteria(item) then result = item
				return
		return result

############################

_Entity = cola.Entity
_EntityList = cola.EntityList

_Entity._evalDataPath = _evalDataPath = (data, path, noEntityList, loadMode, callback, context) ->
	if path
		parts = path.split(".")
		lastIndex = parts.length - 1
		for part, i in parts
			returnCurrent = false
			if i == 0 and data instanceof _EntityList
				if part == "#"
					data = data.current
				else
					data = data[part]
			else
				isLast = (i == lastIndex)
				if !noEntityList
					if !isLast
						returnCurrent = true
					if part.charCodeAt(part.length - 1) == 35 # '#'
						returnCurrent = true
						part = part.substring(0, part.length - 1)

				if data instanceof _Entity
					if typeof data._get == "function"
						data = data._get(part, loadMode, callback, context)
					else

					if data and data instanceof _EntityList
						if noEntityList or returnCurrent
							data = data.current
				else
					data = data[part]
			if !data? then break
	return data

_Entity._setValue = _setValue = (entity, path, value, context) ->
	i = path.lastIndexOf(".")
	if i > 0
		part1 = path.substring(0, i)
		part2 = path.substring(i + 1)
		entity = _evalDataPath(entity, part1, true, "never", context)

		if entity? and !(entity instanceof _EntityList)
			if entity instanceof cola.AjaxServiceInvoker
				entity = undefined
			else if typeof entity._set == "function"
				entity._set(part2, value)
			else
				entity[part2] = value
		else
			throw new cola.Exception("Cannot set value to EntityList \"#{path}\".")
	else if typeof entity._set == "function"
		entity._set(path, value)
	else
		entity[path] = value
	return

_Entity._getEntityId = (entity) ->
	return null unless entity
	if entity instanceof cola.Entity
		return entity.id
	else if typeof entity == "object"
		entity._id ?= cola.uniqueId()
		return entity._id

VALIDATION_NONE = "none"
VALIDATION_INFO = "info"
VALIDATION_WARN = "warning"
VALIDATION_ERROR = "error"

TYPE_SEVERITY =
	VALIDATION_INFO: 1
	VALIDATION_WARN: 2
	VALIDATION_ERROR: 4

class cola.Entity.MessageHolder
	constructor: () ->
		@keyMessage = {}
		@propertyMessages = {}

	compare: (message1, message2) ->
		return (TYPE_SEVERITY[message1.type] or 0) - (TYPE_SEVERITY[message2.type] or 0)

	add: (prop, message) ->
		messages = @propertyMessages[prop]
		if not messages
			@propertyMessages[prop] = [message]
		else
			messages.push(message)

		isTopKey = (prop is "$")
		if keyMessage
			if @compare(message, keyMessage) > 0
				@keyMessage[prop] = message
				topKeyChanged = isTopKey
		else
			@keyMessage[prop] = message
			topKeyChanged = isTopKey

		if not topKeyChanged and not isTopKey
			keyMessage = @keyMessage["$"]
			if keyMessage
				if @compare(message, keyMessage) > 0
					@keyMessage["$"] = message
					topKeyChanged = true
			else
				@keyMessage["$"] = message
				topKeyChanged = true
		return topKeyChanged

	clear: (prop) ->
		if prop
			delete @propertyMessages[prop]
			delete @keyMessage[prop]

			for p, messages of @propertyMessages
				for message in messages
					if not keyMessage
						keyMessage = message
					else if @compare(message, keyMessage) > 0
						keyMessage = message
					else
						continue
					if keyMessage.type is VALIDATION_ERROR
						break
			topKeyChanged = @keyMessage["$"] != keyMessage
			if topKeyChanged then @keyMessage["$"] = keyMessage
		else
			topKeyChanged = true
			@keyMessage = {}
			@propertyMessages = {}
		return topKeyChanged

	getMessages: (prop = "$") ->
		return @propertyMessages[prop]

	getKeyMessage: (prop = "$") ->
		return @keyMessage[prop]

	findMessages: (prop, type) ->
		if prop
			ms = @propertyMessages[prop]
			if type
				messages = []
				for m in ms
					if m.type is type then messages.push(m)
			else
				messages = ms
		else
			messages = []
			for p, ms of @propertyMessages
				for m in ms
					if not type or m.type is type then messages.push(m)
		return messages

###
Functions
###

cola.each = (collection, fn, options) ->
	if collection instanceof cola.EntityList
		collection.each(fn, options)
	else if collection instanceof Array
		if typeof collection.each == "function"
			collection.each(fn)
		else
			cola.util.each(collection, fn)
	return