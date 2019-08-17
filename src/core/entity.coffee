_getEntityPath = ()->
	if @_pathCache then return @_pathCache

	parent = @parent
	if not parent? then return

	path = []
	self = @
	while parent?
		part = self._parentProperty
		if part then path.push(part)
		self = parent
		parent = parent.parent
	@_pathCache = path = path.reverse()
	return path

_watch = (path, watcher)->
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

_unwatch = (path, watcher)->
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

_triggerWatcher = (path, type, arg)->
	if @_watchers
		for p, holder of @_watchers
			shouldTrigger = false
			if p is "**"
				shouldTrigger = true
			else if p is "*"
				shouldTrigger = path.length is holder.path.length
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

	if @parent
		path.unshift(@_parentProperty) if @_parentProperty
		@parent._triggerWatcher(path, type, arg)
	return

_matchValue = (value, propFilter)->
	if propFilter.strict
		if not propFilter.caseSensitive and typeof propFilter.value is "string"
			return (value + "").toLowerCase() is propFilter.value
		else
			return value is propFilter.value
	else
		if not propFilter.caseSensitive
			return (value + "").toLowerCase().indexOf(propFilter.value) > -1
		else
			return (value + "").indexOf(propFilter.value) > -1

cola._trimCriteria = (criteria, option = {})->
	return criteria if not criteria?

	if cola.util.isSimpleValue(criteria)
		if not option.caseSensitive then criteria = (criteria + "").toLowerCase()
		criteria =
			"$": {
				value: criteria
				caseSensitive: option.caseSensitive
				strict: option.strict
			}
	else if typeof criteria is "object"
		for prop, propFilter of criteria
			if typeof propFilter is "string"
				if not option.caseSensitive then propFilter = (propFilter + "").toLowerCase()
				criteria[prop] = {
					value: propFilter
					caseSensitive: option.caseSensitive
					strict: option.strict
				}
			else
				propFilter.caseSensitive ?= option.caseSensitive
				if not propFilter.caseSensitive and typeof propFilter.value is "string"
					propFilter.value = propFilter.value.toLowerCase()

				propFilter.strict ?= option.strict
				if not propFilter.strict
					propFilter.value = if propFilter.value then propFilter.value + "" else ""
	return criteria

_filterCollection = (collection, criteria, option = {})->
	return null unless collection

	filtered = []
	filtered.$origin = collection.$origin or collection

	if not option.mode
		if collection instanceof cola.EntityList or collection[0] instanceof cola.Entity
			option.mode = "entity"
		else
			option.mode = "json"

	cola.each(collection, (item)->
		children = if option.deep then [] else null
		if not criteria? or _filterEntity(item, criteria, option, children)
			filtered.push(item)
			if option.one then return false

		if children
			Array::push.apply(filtered, children)
		return
	)
	return filtered

_filterEntity = (entity, criteria, option = {}, children)->
	_searchChildren = (value)->
		if option.mode is "entity"
			if value instanceof cola.EntityList
				r = _filterCollection(value, criteria, option)
				Array::push.apply(children, r)
			else if value instanceof cola.Entity
				r = []
				_filterEntity(value, criteria, option, r)
				Array::push.apply(children, r)

		else
			if value instanceof Array
				r = _filterCollection(value, criteria, option)
				Array::push.apply(children, r)
			else if typeof value is "object" and not (value instanceof Date)
				r = []
				_filterEntity(value, criteria, option, r)
				Array::push.apply(children, r)
		return

	return false unless entity

	if not option.mode
		option.mode = if entity instanceof cola.Entity then "entity" else "json"

	matches = true
	if criteria?
		if typeof criteria is "object"
			if cola.util.isSimpleValue(entity)
				if criteria.$
					matches = _matchValue(v, criteria.$)
			else
				for prop, propFilter of criteria
					data = null
					if prop is "$"
						matches = false
						if option.mode is "entity"
							data = entity._data
						else
							data = entity

						m = false
						for p, v of data
							if _matchValue(v, propFilter)
								m = true
								break

						if m
							matches = true
							break

					else if option.mode is "entity"
						if not _matchValue(entity.get(prop), propFilter)
							matches = false
							break unless children

					else
						if not _matchValue(entity[prop], propFilter)
							matches = false
							break unless children

		else if typeof criteria is "function"
			matches = criteria(entity, option)

	if children and (not option.one or not matches)
		if not data?
			if option.mode is "entity"
				data = entity._data
			else
				data = entity
		for p, v of data
			_searchChildren(v)

	return matches

_sortCollection = (collection, comparator, caseSensitive)->
	return null unless collection
	return collection if not comparator? or comparator is "$none"

	if collection instanceof cola.EntityList
		origin = collection
		collection = collection.toArray()
		collection.$origin = origin

	if comparator
		if comparator is "$reverse"
			return collection.reverse()
		else if typeof comparator is "string"
			comparatorProps = []
			for part in comparator.split(",")
				c = part.charCodeAt(0)
				propDesc = false
				if c is 43 # `+`
					prop = part.substring(1)
				else if c is 45 # `-`
					prop = part.substring(1)
					propDesc = true
				else
					prop = part
				comparatorProps.push(prop: prop, desc: propDesc)

			comparator = (item1, item2)->
				for comparatorProp in comparatorProps
					value1 = null
					value2 = null
					prop = comparatorProp.prop
					if prop
						if prop is "$random"
							return Math.random() * 2 - 1
						else
							if item1 instanceof cola.Entity
								value1 = item1.get(prop)
							else if cola.util.isSimpleValue(item1)
								value1 = item1
							else
								value1 = item1[prop]
							if not caseSensitive and typeof value1 is "string"
								value1 = value1.toLowerCase()

							if item2 instanceof cola.Entity
								value2 = item2.get(prop)
							else if cola.util.isSimpleValue(item2)
								value2 = item2
							else
								value2 = item2[prop]
							if not caseSensitive and typeof value2 is "string"
								value2 = value2.toLowerCase()

							result = 0
							if not value1? then result = -1 else if not value2? then result = 1 else if value1 > value2 then result = 1 else if value1 < value2 then result = -1
							if result isnt 0
								return if comparatorProp.desc then (0 - result) else result
					else
						result = 0
						if not item1? then result = -1 else if not item2? then result = 1 else if item1 > item2 then result = 1 else if item1 < item2 then result = -1
						if result isnt 0
							return if comparatorProp.desc then (0 - result) else result
				return 0
	else
		comparator = (item1, item2)->
			result = 0
			if not caseSensitive
				if typeof item1 is "string" then item1 = item1.toLowerCase()
				if typeof item2 is "string" then item2 = item2.toLowerCase()
			if not item1? then result = -1 else if not item2? then result = 1 else if item1 > item2 then result = 1 else if item1 < item2 then result = -1
			return result

	comparatorFunc = (item1, item2)->
		return comparator(item1, item2)
	return collection.sort(comparatorFunc)

############################

class cola.Entity

	@STATE_NONE: "NONE"
	@STATE_NEW: "NEW"
	@STATE_MODIFIED: "MODIFIED"
	@STATE_DELETED: "DELETED"

	state: @STATE_NONE

	_disableObserverCount: 0
	_disableWriteObservers: 0
	_disableValidatorsCount: 0

#_parent
#_parentProperty
#_providerInvoker
#_disableWriteObservers

	constructor: (data, dataType)->
		@id = cola.uniqueId()
		@timestamp = cola.sequenceNo()
		@dataType = dataType

		_data = {}
		if dataType
			for property in dataType.getProperties().elements
				if property._defaultValue?
					_data[property._property] = property._defaultValue
		@_data = _data

		if data?
			@_disableWriteObservers++
			for prop, value of data
				@_set(prop, value, null, true)
			@_disableWriteObservers--

			if data.$state then @state = data.$state else if data.state$ then @state = data.state$ # Deprecated

			if data.$disableValidatiors then @_disableValidatorsCount = 1

		if dataType
			dataType.fire("entityCreate", dataType, {entity: @})

	hasValue: (prop)->
		return @_data.hasOwnProperty(prop) or @dataType?.getProperty(prop)?

	get: (prop, loadMode = "async", context)->
		if typeof loadMode is "function" or typeof loadMode is "object"
			callback = loadMode
			loadMode = "async"

		if prop.indexOf(".") > 0 or prop.indexOf("#") >= 0
			return _evalDataPath(@, prop, false, loadMode, callback, context)
		else
			return @_get(prop, loadMode, callback, context)

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

	_get: (prop, loadMode, callback, context)->
		property = @dataType?.getProperty(prop)

		loadData = (provider)->
			retValue = undefined
			if not loaded
				providerInvoker = provider.getInvoker(
					expressionData: @
					parentData: @
					property: prop
				)

				if not @_isRootData and property._skipLoading is "smart"
					parameter = providerInvoker.invokerOptions.data
					skip = not parameter?
					if not skip and parameter and typeof parameter is "object"
						hasValidParameter = false
						for p, v of parameter
							if not parameter.hasOwnProperty(p) or cola.constants._SYS_PARAMS.indexOf(p) >= 0
								continue
							if v
								hasValidParameter = true
								break
						skip = not hasValidParameter

					if skip and providerInvoker.invokerOptions.url is provider._url
						if property._multiple
							@_set(prop, [], null, null, true)
							retValue = @_data[prop]
						loaded = true

			if not loaded
				if loadMode is "sync"
					if property?.getListeners("beforeLoad")
						if property.fire("beforeLoad", property, {
							entity: @
							property: prop
						}) is false
							loaded = true

					if not loaded
						retValue = providerInvoker.invokeSync((result)=>
							result = @_set(prop, result, null, null, true)
							if result and (result instanceof cola.EntityList or result instanceof cola.Entity)
								result._providerInvoker = providerInvoker

							if property?.getListeners("load")
								property.fire("load", property, {
									entity: @
									property: prop
								})
							return result
						)

				else if loadMode is "async"
					if property?.getListeners("beforeLoad")
						if property.fire("beforeLoad", property, {
							entity: @
							property: prop
						}) is false
							loaded = true

					if not loaded
						notifyArg = {
							data: @
							property: prop
						}
						completed = false
						dfd = providerInvoker.invokeAsync((result)=>
							result = @_set(prop, result, null, null, true)
							if result and (result instanceof cola.EntityList or result instanceof cola.Entity)
								result._providerInvoker = providerInvoker

							if property?.getListeners("load")
								property.fire("load", property, {
									entity: @
									property: prop
								})
							return result
						).always(()=>
							completed = true
							@_notify(cola.constants.MESSAGE_LOADING_END, notifyArg)
							return
						)
						if not completed then @_data[prop] = dfd
						@_notify(cola.constants.MESSAGE_LOADING_START, notifyArg)

						if context
							context.unloaded = true
							context.deferreds ?= []
							context.deferreds.push(dfd)

			return cola.util.createDeferredIf(dfd, retValue)

		value = @_data[prop]

		if property?.getListeners("read")
			value = property.fire("read", property, {
				entity: @
				property: prop
				value: value
			})
			cola.callback(callback, true, value)
			return value

		if value is undefined
			if property
				provider = property.get("provider")
				context?.unloaded = !!provider
				if loadMode isnt "never" and provider and provider._loadMode isnt "manual"
					dfd = loadData.call(@, provider).done((result)->
						value = result
						cola.callback(callback, true, result)
						return
					).fail((error)->
						cola.callback(callback, false, error)
						return
					)
					callbackProcessed = true

		else if typeof value is "object" and value and value.done and value.fail
			dfd = value
			value = undefined
			if callback
				dfd.done((result)->
					cola.callback(callback, true, result)
					return
				).fail((error)->
					cola.callback(callback, false, error)
					return
				)
				callbackProcessed = true

			if context
				context.unloaded = true
				context.deferreds ?= []
				context.deferreds.push(dfd)

		if callback and not callbackProcessed
			cola.callback(callback, true, value)
		return value

	set: (prop, value, dataType, context)->
		if typeof prop is "string"
			_setValue(@, prop, value, dataType, context)
		else if prop and (typeof prop is "object")
			config = prop
			for prop, val of config
				@set(prop, val, dataType, context)
		return @

	_jsonToEntity: (value, dataType, multiple)->
		providerInvoker = value?.$providerInvoker
		result = cola.DataType.jsonToEntity(value, dataType, multiple, providerInvoker?.pageSize)
		if result and providerInvoker
			result._providerInvoker = providerInvoker
		return result

	_set: (prop, value, dataType, context, ignoreState)->
		oldValue = @_data[prop]
		isSpecialProp = prop.charCodeAt(0) is 36 # `$`

		property = @dataType?.getProperty(prop)
		if value?
			if value instanceof cola.Provider
				changed = (oldValue != undefined)
			else
				if property
					if not dataType
						dataType = property._dataType
					provider = property._provider

				if typeof dataType is "string"
					dataType = @_dataModel.definition(dataType)

				if dataType
					if value?
						if dataType instanceof cola.StringDataType and typeof value isnt "string" or dataType instanceof cola.BooleanDataType and
						  typeof value isnt "boolean" or dataType instanceof cola.NumberDataType and typeof value isnt "number" or dataType instanceof cola.DateDataType and not (value instanceof Date)
							value = dataType.parse(value)
						else if dataType instanceof cola.EntityDataType
							matched = true
							if value instanceof _Entity
								matched = value.dataType is dataType and not property._multiple
							else if value instanceof _EntityList
								matched = value.dataType is dataType and property._multiple isnt false
							else if property._multiple or value instanceof Array or value.hasOwnProperty("$data") or value.hasOwnProperty("data$")
								value = @_jsonToEntity(value, dataType, true)
							else
								value = new _Entity(value, dataType)

							if not matched
								expectedType = dataType.get("name")
								actualType = value.dataType?.get("name") or "undefined"
								if property._multiple then expectedType = "[#{expectedType}]"
								if value instanceof cola.EntityList then actualType = "[#{actualType}]"
								throw new cola.Exception("Unmatched DataType. expect \"#{expectedType}\" but \"#{actualType}\".")
						else
							value = dataType.parse(value)

#if dataType instanceof cola.NumberDataType and (value is Number.MIN_SAFE_INTEGER or value
# is Number.MAX_SAFE_INTEGER)
#	throw new cola.Exception(cola.resource("cola.validator.error.number", value))
				else if typeof value is "object" and value? and not isSpecialProp
					if value instanceof Array
						convert = true
						if value.length > 0
							item = value[0]
							if cola.util.isSimpleValue(item) then convert = false
						value = @_jsonToEntity(value, null, true) if convert
					else if value.hasOwnProperty("$data") or value.hasOwnProperty("data$")
						value = @_jsonToEntity(value, null, true)
					else if value instanceof Date
# do nothing
					else unless value instanceof _Entity or value instanceof _EntityList
						value = @_jsonToEntity(value, null, false)

				#if cola.consoleOpened and cola.debugLevel > 9
				#	setTimeout(()=>
				#		if @getPath() and value.getPath?()
				#			path = value.getPath().join(".")
				#			cola.Entity._warnedDataPaths ?= {}
				#			if not cola.Entity._warnedDataPaths[path]
				#				cola.Entity._warnedDataPaths[path] = true
				#				console.warn("No 'DataType' found for path: " + path)
				#		return
				#	, 0)

				changed = oldValue isnt value
		else
			changed = oldValue isnt value

		if changed
			if property?.getListeners("beforeWrite")
				if property.fire("beforeWrite", property, {
					entity: @
					property: prop,
					oldValue: oldValue
					value: value
				}) is false
					return

			if @dataType?.getListeners("beforeDataChange")
				if @dataType.fire("beforeDataChange", @dataType, {
					entity: @
					property: prop,
					oldValue: oldValue
					value: value
				}) is false
					return

			if not ignoreState and property?._validators
				messages = null
				for validator in property._validators
					if value? or validator instanceof cola.RequiredValidator
						if not validator._disabled and validator instanceof cola.AsyncValidator and validator.get("async")
							message = validator.validate(value, @)
							if message
								messages ?= []
								if message instanceof Array
									Array::push.apply(messages, message)
								else
									messages.push(message)
				if messages
					for message in messages
						if message is "error"
							throw new cola.Exception(message.text)

			if @_disableWriteObservers is 0 and not isSpecialProp
				if oldValue? and (oldValue instanceof _Entity or oldValue instanceof _EntityList)
					oldValue._setDataModel(null)
					delete oldValue.parent
					delete oldValue._parentProperty
				if not ignoreState and @state is _Entity.STATE_NONE
					@setState(_Entity.STATE_MODIFIED)

			if property?.getListeners("write")
				arg =
					entity: @
					property: prop,
					oldValue: oldValue
					value: value
				property.fire("write", property, arg)
				value = arg.value
			@_data[prop] = value

			if not isSpecialProp and value? and (value instanceof _Entity or value instanceof _EntityList)
				if value.parent and value.parent isnt @
					throw new cola.Exception("Entity/EntityList is already belongs to another owner. \"#{prop}\"")

				value.parent = @
				value._parentProperty = prop
				value._setDataModel(@_dataModel)
				value._onPathChange()
				@_mayHasSubEntity = true

			@timestamp = cola.sequenceNo()

			if not ignoreState and not @_disableValidatorsCount and property?._validators
				if messages?
					@_messageHolder?.clear(prop)
					@addMessage(prop, messages)

					if value?
						for validator in property._validators
							if not validator._disabled and validator instanceof cola.AsyncValidator and validator.get("async")
								validator.validate(value, @, (message)=>
									if message
										message.entity = @
										message.property = prop
										@addMessage(prop, message)
									return
								)
				else
					@validate(prop)

			if @_disableWriteObservers is 0
				@_notify(cola.constants.MESSAGE_PROPERTY_CHANGE, {
					entity: @
					property: prop
					value: value
					oldValue: oldValue
				})

			if @dataType?.getListeners("dataChange")
				@dataType.fire("dataChange", @dataType, {
					entity: @
					property: prop,
					oldValue: oldValue
					value: value
				})
		return value

	remove: (detach)->
		parent = @parent
		if parent
			if parent instanceof _EntityList
				parent.remove(@, detach)
			else
				if @setState(_Entity.STATE_DELETED)
					parent.set(@_parentProperty, null)
		else
			@setState(_Entity.STATE_DELETED)
		return @

	insert: (prop, data)->
		if data and data instanceof Array
			throw new cola.Exception("Unmatched DataType. expect \"Object\" but \"Array\".")

		property = @dataType?.getProperty(prop)
		propertyDataType = property?._dataType
		if propertyDataType and not (propertyDataType instanceof cola.EntityDataType)
			throw new cola.Exception("Unmatched DataType. expect \"cola.EntityDataType\" but \"#{propertyDataType._name}\".")

		entityList = @_get(prop, "never")
		if not entityList?
			entityList = new cola.EntityList(null, propertyDataType)
			provider = property._provider
			if provider
				entityList.pageSize = provider._pageSize
				entityList._providerInvoker = provider.getInvoker(
					expressionData: @
					parentData: entityList)

			@_disableWriteObservers++
			@_set(prop, entityList)
			@_disableWriteObservers--
		return entityList.insert(data)

	createChild: (prop, data)->
		if data and data instanceof Array
			throw new cola.Exception("Unmatched DataType. expect \"Object\" but \"Array\".")

		property = @dataType?.getProperty(prop)
		propertyDataType = property?._dataType
		if propertyDataType and not (propertyDataType instanceof cola.EntityDataType)
			throw new cola.Exception("Unmatched DataType. expect \"cola.EntityDataType\" but \"#{propertyDataType._name}\".")

		oldValue = @_get(prop, "never")
		if property?._multiple or oldValue instanceof cola.EntityList
			entityList = oldValue
			if not entityList?
				entityList = new cola.EntityList(null, propertyDataType)

				provider = property._provider
				if provider
					entityList.pageSize = provider._pageSize
					entityList._providerInvoker = provider.getInvoker(
						expressionData: @
						parentData: entityList)

				@_disableWriteObservers++
				@_set(prop, entityList)
				@_disableWriteObservers--
			return entityList.insert(data)
		else
			child = new _Entity(data, propertyDataType)
			@_set(prop, child)
			return child

	createBrother: (data)->
		if data and data instanceof Array
			throw new cola.Exception("Unmatched DataType. expect \"Object\" but \"Array\".")

		brother = new _Entity(data, @dataType)
		brother.setState(_Entity.STATE_NEW)
		parent = @parent
		if parent and parent instanceof _EntityList
			parent.insert(brother)
		return brother

	setCurrent: (cascade)->
		if cascade
			node = @
			parent = node.parent
			while parent
				if parent instanceof _EntityList
					parent.setCurrent(node)
				node = parent
				parent = node.parent
		else
			parent = @parent
			if parent and parent instanceof _EntityList
				parent.setCurrent(@)
		return @

	setState: (state)->
		return true if @state is state

		parent = @parent
		if state is _Entity.STATE_DELETED
			if @dataType?.fire("beforeEntityRemove", @dataType, {entity: @, parent: parent}) is false
				return false

		if @state is _Entity.STATE_NONE and state is _Entity.STATE_MODIFIED
			@_storeOldData()

		oldState = @state
		@state = state

		@_notify(cola.constants.MESSAGE_EDITING_STATE_CHANGE, {
			entity: @
			oldState: oldState
			state: state
		})

		if state is _Entity.STATE_DELETED
			@dataType?.fire("entityRemove", @dataType, {entity: @, parent: parent})
		return true

	_storeOldData: ()->
		return if @_oldData

		data = @_data
		oldData = @_oldData = {}
		for p, value of data
			if value and (value instanceof _Entity or value instanceof _EntityList)
				continue
			oldData[p] = value
		return

	getOldValue: (prop)->
		return @_oldData?[prop]

	reset: (prop)->
		if prop
			@_set(prop, undefined)
			@clearMessages(prop)
		else
			@disableObservers()
			data = @_data
			for prop, value of data
				if value isnt undefined
					delete data[prop]
			@resetState()
			@enableObservers()
			@_notify(cola.constants.MESSAGE_REFRESH, {data: @})
		return @

	cancel: (prop)->
		data = @_data
		if prop
			if data.hasOwnProperty(prop)
				@_set(prop, @_oldData[prop])
				@clearMessages(prop)
		else
			if @_oldData
				@disableObservers()
				for prop of data
					if data.hasOwnProperty(prop)
						@_set(prop, @_oldData[prop])
				@resetState()
				@enableObservers()
				@_notify(cola.constants.MESSAGE_REFRESH, {data: @})
			else
				@resetState()
		return @

	resetState: ()->
		delete @_oldData
		@clearMessages()
		@setState(_Entity.STATE_NONE)
		return @

	getDataType: (path)->
		if path
			dataType = @dataType
			if dataType
				parts = path.split(".")
				for part in parts
					property = dataType.getProperty?(part)
					if not property? then break
					dataType = property.get("dataType")
					if not dataType? then break
		else
			dataType = @dataType

		if not dataType?
			data = @get(path)
			dataType = data?.dataType
		return dataType

	getPath: _getEntityPath

	flush: (property, loadMode = "async")->
		propertyDef = @dataType.getProperty(property)
		provider = propertyDef?._provider
		if not provider
			throw new cola.Exception("Provider undefined.")

		@_set(property, undefined)

		if loadMode and (typeof loadMode is "function" or typeof loadMode is "object")
			callback = loadMode
			loadMode = "async"

		dfd = $.Deferred()
		oldLoadMode = provider._loadMode
		provider._loadMode = "lazy"
		try
			@_get(property, loadMode, {
				complete: (success, result)->
					cola.callback(callback, success, result)
					if success
						dfd.resolve(result)
					else
						dfd.reject(result)
			})
		finally
			provider._loadMode = oldLoadMode
		return dfd

	_setDataModel: (dataModel)->
		return if @_dataModel is dataModel

		if @_dataModel
			@_dataModel.onEntityDetach(@)

		@_dataModel = dataModel

		if dataModel
			dataModel.onEntityAttach(@)

		if @_mayHasSubEntity
			data = @_data
			for p, value of data
				if value and (value instanceof _Entity or value instanceof _EntityList) and
				  p.charCodeAt(0) isnt 36    # `$`
					value._setDataModel(dataModel)
		return

	watch: _watch
	unwatch: _unwatch
	_triggerWatcher: _triggerWatcher

	_onPathChange: ()->
		delete @_pathCache
		if @_mayHasSubEntity
			data = @_data
			for p, value of data
				if value and (value instanceof _Entity or value instanceof _EntityList)
					value._onPathChange()
		return

	disableObservers: ()->
		if @_disableObserverCount < 0 then @_disableObserverCount = 1 else @_disableObserverCount++
		return @

	enableObservers: ()->
		if @_disableObserverCount < 1 then @_disableObserverCount = 0 else @_disableObserverCount--
		return @

	disableValidators: ()->
		if @_disableValidatorsCount < 0 then @_disableValidatorsCount = 1 else @_disableValidatorsCount++
		return @

	enableValidators: ()->
		if @_disableValidatorsCount < 1 then @_disableValidatorsCount = 0 else @_disableValidatorsCount--
		return @

	notifyObservers: ()->
		@_notify(cola.constants.MESSAGE_REFRESH, {data: @})
		return @

	_notify: (type, arg)->
		if @_disableObserverCount is 0
			delete arg.timestamp
			path = @getPath()

			if (type is cola.constants.MESSAGE_PROPERTY_CHANGE or type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE or type is cola.constants.MESSAGE_LOADING_START or type is cola.constants.MESSAGE_LOADING_END) and arg.property
				if path
					path = path.concat(arg.property)
				else
					path = [arg.property]
			@_doNotify(path, type, arg)

			if type is cola.constants.MESSAGE_PROPERTY_CHANGE or type is cola.constants.MESSAGE_REFRESH
				@_triggerWatcher([arg.property or "*"], type, arg)
		return

	_doNotify: (path, type, arg)->
		arg.originPath = path
		@_dataModel?.onDataMessage(path, type, arg)
		return

	_validate: (prop)->
		property = @dataType.getProperty(prop)
		if property
			if property._validators
				data = @_data[prop]
				if data and (data instanceof cola.Provider or data instanceof cola.ProviderInvoker)
					return

				for validator in property._validators
					if not validator._disabled
						if validator instanceof cola.AsyncValidator and validator.get("async")
							validator.validate(data, @, (message)=>
								if message
									message.entity = @
									message.property = prop
									@addMessage(prop, message)
								return
							)
						else
							message = validator.validate(data, @)
							if message
								message.entity = @
								message.property = prop
								messageChanged = @_addMessage(prop, message) or messageChanged
		return messageChanged

	validate: (prop)->
		if @_messageHolder
			oldKeyMessage = @_messageHolder.getKeyMessage()

		if @dataType
			messageChanged = @_messageHolder?.clear(prop)
			if prop
				if @_validate(prop) or messageChanged
					@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {
						entity: @
						property: prop
					})
			else
				for property in @dataType.getProperties().elements
					if @_validate(property._property) or messageChanged
						@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {
							entity: @
							property: property._property
						})

		else if @_messageHolder
			if prop
				if @_messageHolder.clear(prop)
					@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @, property: prop})
			else
				messages = @_messageHolder.getMessages()
				@_messageHolder.clear()
				for p in messages
					@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @, property: p})

		keyMessage = @_messageHolder?.getKeyMessage()
		if (oldKeyMessage or keyMessage) and oldKeyMessage isnt keyMessage
			@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @})

		return not (keyMessage?.type is "error")

	_addMessage: (prop, message)->
		messageHolder = @_messageHolder
		if not messageHolder
			@_messageHolder = messageHolder = new _Entity.MessageHolder()
		if message instanceof Array
			for m in message
				messageHolder.add(prop, m)
				changed = true
		else
			messageHolder.add(prop, message)
			changed = true
		return changed

	addMessage: (prop, message)->
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

	getKeyMessage: (prop)->
		return @_messageHolder?.getKeyMessage(prop)

	getMessages: (prop)->
		return @_messageHolder?.getMessages(prop)

	clearMessages: (prop, force)->
		if typeof prop is "boolean"
			force = prop
			prop = undefined

		return @ unless @_messageHolder
		if prop
			hasPropMessage = @_messageHolder.getKeyMessage(prop)
		topKeyChanged = @_messageHolder.clear(prop, force)
		if hasPropMessage then @_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @, property: prop})
		if topKeyChanged then @_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @})
		return @

	findMessages: (prop, type)->
		return @_messageHolder?.findMessages(prop, type)

	toJSON: (options)->
		entityId = options?.entityId or false
		state = options?.state or false
		dataType = options?.dataType or false
		oldData = options?.oldData or false
		specialProperties = options?.specialProperties or false
		simpleValue = options?.simpleValue or false
		nullValue = if options?.nullValue? then options.nullValue else true

		data = @_data
		json = {}
		for prop, value of data
			c = prop.charCodeAt(0)
			if c is 36 or c is 95 # `$` or `_`
				if not specialProperties
					continue
				else if specialProperties is '$' and c is 95
					continue
				else if specialProperties is '_' and c is 36
					continue

			if value
				if value instanceof cola.ProviderInvoker
					continue
				else if (value instanceof _Entity or value instanceof _EntityList)
					if simpleValue then continue
					value = value.toJSON(options)

			continue if value is undefined
			continue if value is null and not nullValue

			json[prop] = value

		if entityId then json.entityId$ = @id
		if state then json.state$ = @state
		if dataType and @dataType?._name then json.dataType$ = @dataType?._name
		if oldData and @_oldData
			json.oldData$ = @_oldData
		return json

class Page extends Array
	loaded: false
	entityCount: 0

	constructor: (@entityList, @pageNo)->

	initData: (json)->
		rawJson = json
		entityList = @entityList

		if json.hasOwnProperty("$data")
			json = rawJson.$data
		else if json.hasOwnProperty("data$")    # Deprecated
			json = rawJson.data$

		if json and not (json instanceof Array)
			throw new cola.Exception("Unmatched DataType. expect \"Array\" but \"Object\".")

		if json?.length
			dataType = entityList.dataType

			@_dontChangeCurrent = true
			try
				for data in json
					entity = new _Entity(data, dataType)
					@insert(entity)
			finally
				delete @_dontChangeCurrent

			if rawJson.$entityCount?
				entityList.totalEntityCount = rawJson.$entityCount
			else if rawJson.entityCount$?    # Deprecated
				entityList.totalEntityCount = rawJson.entityCount$

			if entityList.totalEntityCount?
				entityList.pageCountDetermined = true

			entityList.entityCount += json.length

			if not entityList.current and @length
				for entity, i in entity
					if entity.state isnt _Entity.STATE_DELETED
						entityList.setCurrent(entity)
						page.hotIndex = i
						break

			entityList.timestamp = cola.sequenceNo()

			entityList._notify(cola.constants.MESSAGE_REFRESH, {
				data: entityList
			})
		else
			entityList.totalEntityCount = entityList.entityCount
			entityList.pageCountDetermined = true
		return

	insert: (entity, index)->
		if 0 <= index < @length
			@splice(index, 0, entity)
		else
			index = @length
			@push(entity)
		@hotIndex = index

		entityList = @entityList
		entity._page = @
		entity.parent = entityList
		delete entity._parentProperty

		if not @_dontChangeCurrent and not entityList.current
			if entity.state isnt _Entity.STATE_DELETED
				entityList._setCurrentPage(entity._page, false)
				entityList.setCurrent(entity)

		entity._setDataModel(entityList._dataModel)
		entity._onPathChange()
		if entity.state isnt _Entity.STATE_DELETED
			@entityCount++
			@totalEntityCount++
		return

	remove: (entity)->
		index = @indexOf(entity)
		if index >= 0
			@splice(index, 1)
			if index is @hotIndex
				if index is @length - 1
					@hotIndex--
			else if index < @hotIndex
				@hotIndex--

			delete entity._page
			entity._parent = entity.parent
			delete entity.parent
			entity._setDataModel(null)
			entity._onPathChange()
			if entity.state isnt _Entity.STATE_DELETED
				@entityCount--
				@totalEntityCount--
		return

	clear: ()->
		i = @length - 1
		while i >= 0
			entity = @[i]
			delete entity._page
			entity._parent = entity.parent
			delete entity.parent
			entity._setDataModel(null)
			entity._onPathChange()
			i--
		@splice(0, @length)
		@entityCount = 0
		@hotIndex = 0
		return

	loadData: (loadMode)->
		providerInvoker = @entityList._providerInvoker
		if providerInvoker
			providerInvoker.pageSize = @entityList.pageSize
			providerInvoker.pageNo = @pageNo
			if loadMode is "sync"
				result = providerInvoker.invokeSync((result)=>
					@initData(result)
					return
				)
			else
				dfd = providerInvoker.invokeAsync((result)=>
					@initData(result)
					return
				)
		return cola.util.createDeferredIf(dfd, result)

class cola.EntityList
	current: null
	entityCount: 0

	pageSize: 0
	pageNo: 1
	pageCount: 1

	_pageCount: 0
	_disableObserverCount: 0

# totalEntityCount
# _parent
# _parentProperty
# _providerInvoker

	constructor: (array, dataType)->
		@id = cola.uniqueId()
		@timestamp = cola.sequenceNo()
		@dataType = dataType
		if array then @fillData(array)

	_insertElement: (element, insertMode, refEntity)->
		if not @_first
			@_first = @_last = element
		else
			if not insertMode or insertMode is "end"
				element._previous = @_last
				delete element._next
				@_last._next = element
				@_last = element
			else if insertMode is "before"
				previous = refEntity._previous
				previous?._next = element
				refEntity._previous = element
				element._previous = previous
				element._next = refEntity
				if @_first is refEntity then @_first = element
			else if insertMode is "after"
				next = refEntity._next
				next?._previous = element
				refEntity._next = element
				element._previous = refEntity
				element._next = next
				if @_last is refEntity then @_last = element
			else if insertMode is "begin"
				delete element._previous
				element._next = @_first
				@_first._previous = element
				@_first = element
		element._page = @
		@_pageCount++
		return

	_removeElement: (element)->
		previous = element._previous
		next = element._next
		previous?._next = next
		next?._previous = previous
		if @_first is element then @_first = next
		if @_last is element then @_last = previous
		@_pageCount--
		return

	_clearElements: ()->
		@_first = @_last = null
		@_pageCount = 0
		return

	fillData: (array)->
		page = @findPage(@pageNo)
		if not page
			page = new Page(@, @pageNo)
			@_insertElement(page, "begin")
		page.initData(array)

		if not @current
			for entity in page
				if entity.state isnt _Entity.STATE_DELETED
					@setCurrent(entity)
					break
		return

	setTotalEntityCount: (count)->
		@pageCountDetermined = true
		@totalEntityCount = count
		@pageCount = Math.ceil(count / @pageSize)
		@timestamp = cola.sequenceNo()
		@_notify(cola.constants.MESSAGE_REFRESH, {
			data: @
		})

	_setDataModel: (dataModel)->
		return if @_dataModel is dataModel
		@_dataModel = dataModel

		page = @_first
		if not page then return

		while page
			for entity in page
				entity._setDataModel(dataModel)
			page = page._next
		return

	watch: _watch
	unwatch: _unwatch
	_triggerWatcher: _triggerWatcher

	_setCurrentPage: (page, setCurrent)->
		@_currentPage = page
		@pageNo = page?.pageNo or 1
		@timestamp = cola.sequenceNo()

		if setCurrent
			for entity in page
				if entity.state isnt _Entity.STATE_DELETED
					@setCurrent(entity)
					break
		return

	_onPathChange: ()->
		delete @_pathCache

		page = @_first
		if not page then return

		while page
			for entity in page
				entity._onPathChange()
			page = page._next
		return

	_findPrevious: (entity)->
		if not entity or entity.parent is @
			if entity
				page = entity._page
				if page[page.hotIndex] is entity
					index = page.hotIndex
				else
					index = page.indexOf(entity)
			else
				page = @_last
				index = page.length

			while page
				while index > 0
					entity = page[--index]
					if entity.state isnt _Entity.STATE_DELETED
						return [entity, index]

				page = page._previous
				index = page?.length
		return []

	_findNext: (entity)->
		if not entity or entity.parent is @
			if entity
				page = entity._page
				if page[page.hotIndex] is entity
					index = page.hotIndex
				else
					index = page.indexOf(entity)
			else
				page = @_first
				index = -1

			while page
				lastIndex = page.length - 1
				while index < lastIndex
					entity = page[++index]
					if entity.state isnt _Entity.STATE_DELETED
						return [entity, index]

				page = page._next
				index = -1
		return []

	findPage: (pageNo)->
		if pageNo < 1 then return null
		if pageNo > @pageCount
			if @pageCountDetermined or pageNo > (@pageCount + 1)
				return null

		page = @_currentPage or @_first
		if not page then return null

		if page.pageNo is pageNo
			return page
		else if page.pageNo < pageNo
			page = page._next
			while page?
				if page.pageNo is pageNo
					return page
				else if page.pageNo > pageNo
					break
				page = page._next
		else
			page = page._previous
			while page?
				if page.pageNo is pageNo
					return page
				else if page.pageNo < pageNo
					break
				page = page._previous
		return null

	_createPage: (pageNo)->
		if pageNo < 1 then return null
		if pageNo > @pageCount
			if @pageCountDetermined or pageNo > (@pageCount + 1)
				return null

		insertMode = "end"
		refPage = @_currentPage or @_first
		if refPage
			if refPage.page is pageNo - 1
				insertMode = "after"
			else if refPage.page is pageNo + 1
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

	hasNextPage: ()->
		pageNo = @pageNo + 1
		return not @pageCountDetermined or pageNo <= @pageCount

	_loadPage: (pageNo, setCurrent, loadMode = "async")->
		if loadMode and (typeof loadMode is "function" or typeof loadMode is "object")
			callback = loadMode
			loadMode = "async"

		page = @findPage(pageNo)
		if page isnt @_currentPage
			if page
				@_setCurrentPage(page, setCurrent)
			else if loadMode isnt "never"
				if setCurrent then @setCurrent(null)
				page = @_createPage(pageNo)
				if page
					if loadMode isnt "sync" and not @_currentPage
						@_setCurrentPage(page, setCurrent)

					@_dontAutoSetCurrent++
					dfd = page.loadData(loadMode).done((result)=>
						@_dontAutoSetCurrent--
						if page.entityCount and @pageCount < pageNo
							@pageCount = pageNo
						if @_currentPage isnt page
							@_setCurrentPage(page, setCurrent)
						return
					)
		return cola.util.createDeferredIf(dfd).done(()->
			cola.callback(callback, true)
			return
		)

	loadPage: (pageNo, loadMode)->
		return @_loadPage(pageNo, false, loadMode)

	gotoPage: (pageNo, loadMode)->
		if pageNo < 1
			pageNo = 1
		else if @pageCountDetermined and pageNo > @pageCount
			pageNo = @pageCount
		return @_loadPage(pageNo, true, loadMode)

	firstPage: (loadMode)-> @gotoPage(1, loadMode)

	previousPage: (loadMode)->
		pageNo = @pageNo - 1
		if pageNo < 1 then pageNo = 1
		return @gotoPage(pageNo, loadMode)

	nextPage: (loadMode)->
		pageNo = @pageNo + 1
		if @pageCountDetermined and pageNo > @pageCount then pageNo = @pageCount
		return @gotoPage(pageNo, loadMode)

	lastPage: (loadMode)-> @gotoPage(@pageCount, loadMode)

	insert: (entity, insertMode, refEntity)->
		if isFinite(insertMode)
			index = +insertMode
		else if insertMode is "before" or insertMode is "after"
			if refEntity and refEntity.parent isnt @
				refEntity = null
			refEntity ?= @current
			if refEntity
				page = refEntity._page
				index = page.indexOf(refEntity)
				if insertMode is "after"
					index++
		else
			if insertMode is "end"
				page = @_last
				index = page.length
			else if insertMode is "begin"
				page = @_first
				index = 0

		if not page
			page = @_currentPage
			if not page
				@gotoPage(1)
				page = @_currentPage

		if entity instanceof _Entity
			if entity.parent and entity.parent isnt @
				throw new cola.Exception("Entity is already belongs to another owner. \"#{@._parentProperty or "Unknown"}\".")
			if entity.state is _Entity.STATE_DELETED
				entity.setState(_Entity.STATE_NONE)
		else
			entity = new _Entity(entity, @dataType)
			entity.setState(_Entity.STATE_NEW)

		if @dataType and @dataType.getListeners("beforeEntityInsert")
			if @dataType.fire("beforeEntityInsert", @dataType, {
				entityList: @
				entity: entity
			}) is false
				return null

		page._dontChangeCurrent = true
		page.insert(entity, index)
		page._dontChangeCurrent = false

		if entity.state isnt _Entity.STATE_DELETED then @entityCount++

		@timestamp = cola.sequenceNo()
		@_notify(cola.constants.MESSAGE_INSERT, {
			entityList: @
			entity: entity
			insertMode: insertMode
			refEntity: refEntity
		})

		if @dataType and @dataType.getListeners("entityInsert")
			@dataType.fire("entityInsert", @dataType, {
				entityList: @
				entity: entity
			})

		if not @_dontChangeCurrent and not @current
			@setCurrent(entity)
			if 0 <= index < entity._page.length
				entity._page.hotIndex = index
		return entity

	remove: (entity, detach)->
		if not entity?
			entity = @current

		return undefined if entity.parent isnt @

		if @dataType and @dataType.getListeners("beforeEntityDelete")
			if @dataType.fire("beforeEntityDelete", @dataType, {
				entityList: @
				entity: entity
			}) is false
				return null

		if entity is @current
			changeCurrent = true
			ret = @_findNext(entity)
			if not ret.length then ret = @_findPrevious(entity)
			[newCurrent, newCurrentIndex] = ret

		page = entity._page
		if detach
			page.remove(entity)
			@entityCount--
		else if entity.state is _Entity.STATE_NEW
			if entity.setState(_Entity.STATE_DELETED) is false
				return null
			page.remove(entity)
			@entityCount--
		else if entity.state isnt _Entity.STATE_DELETED
			if entity.setState(_Entity.STATE_DELETED) is false
				return null
			@entityCount--

		@timestamp = cola.sequenceNo()
		@_notify(cola.constants.MESSAGE_REMOVE, {
			entityList: @
			entity: entity
		})

		if @dataType and @dataType.getListeners("entityDelete")
			@dataType.fire("entityDelete", @dataType, {
				entityList: @
				entity: entity
			})

		if changeCurrent
			@setCurrent(newCurrent)
			if newCurrent
				newCurrent._page.hotIndex = newCurrentIndex
		return entity

	empty: ()->
		@_reset()
		@_notify(cola.constants.MESSAGE_REFRESH, {data: @})
		return @

	setCurrent: (entity)->
		if @current is entity or entity?.state is cola.Entity.STATE_DELETED
			return @

		if entity and entity.parent isnt @
			throw new cola.Exception("The entity is not belongs to this EntityList.")

		oldCurrent = @current
		oldCurrent._onPathChange() if oldCurrent

		if @dataType and @dataType.getListeners("beforeCurrentChange")
			if @dataType.fire("beforeCurrentChange", @dataType, {
				entityList: @
				oldCurrent: oldCurrent
				current: entity
			}) is false
				return @

		@current = entity

		if entity
			page = entity._page
			@_setCurrentPage(page)
			if page[page.hotIndex] isnt entity
				page.hotIndex = page.indexOf(entity)
			entity._onPathChange()

		@_notify(cola.constants.MESSAGE_CURRENT_CHANGE, {
			entityList: @
			current: entity
			oldCurrent: oldCurrent
		})

		if @dataType and @dataType.getListeners("currentChange")
			@dataType.fire("currentChange", @dataType, {
				entityList: @
				oldCurrent: oldCurrent
				current: entity
			})
		return @

	first: ()->
		[entity, index] = @_findNext()
		if entity
			@setCurrent(entity)
			entity._page.hotIndex = index
			return entity
		else
			return @current

	previous: ()->
		[entity, index] = @_findPrevious(@current)
		if entity
			@setCurrent(entity)
			entity._page.hotIndex = index
			return entity
		else
			return @current

	next: ()->
		[entity, index] = @_findNext(@current)
		if entity
			@setCurrent(entity)
			entity._page.hotIndex = index
			return entity
		else
			return @current

	last: ()->
		[entity, index] = @_findPrevious()
		if entity
			@setCurrent(entity)
			entity._page.hotIndex = index
			return entity
		else
			return @current

	getFirst: ()->
		[entity, index] = @_findNext()
		return entity

	getPrevious: ()->
		[entity, index] = @_findPrevious(@current)
		return entity

	getNext: ()->
		[entity, index] = @_findNext(@current)
		return entity

	getLast: ()->
		[entity, index] = @_findPrevious()
		return entity

	hasPrevious: ()->
		return @_findPrevious(@current).length > 0

	hasNext: ()->
		return @_findNext(@current).length > 0

	_reset: ()->
		@current = null
		@entityCount = 0
		@pageNo = 1
		@pageCount = 1

		page = @_first
		while page
			page.clear()
			page = page._next

		delete @_currentPage
		delete @_first
		delete @_last

		@timestamp = cola.sequenceNo()
		return @

	disableObservers: ()->
		if @_disableObserverCount < 0 then @_disableObserverCount = 1 else @_disableObserverCount++
		return @

	enableObservers: ()->
		if @_disableObserverCount < 1 then @_disableObserverCount = 0 else @_disableObserverCount--
		return @

	notifyObservers: ()->
		@_notify(cola.constants.MESSAGE_REFRESH, {data: @})
		return @

	_notify: (type, arg)->
		if @_disableObserverCount is 0
			path = @getPath()
			arg.originPath = path
			@_dataModel?.onDataMessage(path, type, arg)

			if type is cola.constants.MESSAGE_CURRENT_CHANGE or type is cola.constants.MESSAGEinsert or type is cola.constants.MESSAGE_REMOVE
				@_triggerWatcher(["*"], type, arg)
		return

	each: (fn, options)->
		page = @_first
		return @ unless page

		if options?
			if typeof options is "boolean"
				deleted = options
			else
				deleted = options.deleted
				pageNo = options.pageNo
				if not pageNo and options.currentPage
					pageNo = @pageNo

		if pageNo > 1
			page = @findPage(pageNo)
			return @ unless page

		i = 0
		while page
			for entity in page
				if deleted or entity.state isnt _Entity.STATE_DELETED
					if fn.call(@, entity, i++) is false then break
			if not pageNo
				page = page._next
			else
				break
		return @

	getPath: _getEntityPath

	toJSON: (options)->
		deleted = options?.deleted

		array = []
		page = @_first
		while page
			for entity in page
				if deleted or entity.state isnt _Entity.STATE_DELETED
					array.push(entity.toJSON(options))
			page = page._next
		return array

	toArray: ()->
		array = []
		page = @_first
		while page
			for entity in page
				if entity.state isnt _Entity.STATE_DELETED
					array.push(entity)
			page = page._next
		return array

	filter: (criteria, option)->
		criteria = cola._trimCriteria(criteria, option)
		return _filterCollection(@, criteria, option)

	where: (criteria, option = {})->
		if option.caseSensitive is undefined then option.caseSensitive = true
		if option.strict is undefined then option.strict = true
		criteria = cola._trimCriteria(criteria, option)
		return _filterCollection(@, criteria, option)

	find: (criteria, option = {})->
		option.one = true
		result = cola.util.where(@, criteria, option)
		return result?[0]

############################

_Entity = cola.Entity
_EntityList = cola.EntityList

_Entity._evalDataPath = _evalDataPath = (data, path, noEntityList, loadMode, callback, context = {})->
	parts = path.split(".")
	lastIndex = parts.length - 1

	evalPart = (data, parts, i)->
		part = parts[i]
		returnCurrent = false
		if i is 0 and data instanceof _EntityList
			if part is "#"
				data = data.current
			else
				data = data[part]
		else
			isLast = (i is lastIndex)
			if part.charCodeAt(part.length - 1) is 35 # '#'
				returnCurrent = true
				part = part.substring(0, part.length - 1)
			else
				if not noEntityList and not isLast
					returnCurrent = true

			if data instanceof _Entity
				data = data._get(part, loadMode, {
					complete: (success, result)->
						if success
							if result and result instanceof _EntityList
								if noEntityList or returnCurrent
									result = result.current

							if result? and not isLast
								evalPart(result, parts, i + 1)
							else
								cola.callback(callback, true, result)
						else
							cola.callback(callback, false, result)
						return
				}, context)
				return
			else
				data = data[part]

		if data? and not isLast
			evalPart(data, parts, i + 1)
		else
			cola.callback(callback, true, data)
		return

	if not callback
		for part, i in parts
			returnCurrent = false
			if i is 0 and data instanceof _EntityList
				if part is "#"
					data = data.current
				else
					data = data[part]
			else
				if part.charCodeAt(part.length - 1) is 35 # '#'
					returnCurrent = true
					part = part.substring(0, part.length - 1)
				else
					isLast = (i is lastIndex)
					if not noEntityList and not isLast
						returnCurrent = true

				if data instanceof _Entity
					result = data._get(part, loadMode, null, context)
					if result is undefined and context.unloaded
						evalPart(data, parts, i)
						data = result
						break

					data = result
					if data and data instanceof _EntityList
						if noEntityList or returnCurrent
							data = data.current
				else
					data = data[part]
			if not data? then break
		return data
	else
		evalPart(data, parts, 0)
		return

_Entity._setValue = _setValue = (entity, path, value, dataType, context)->
	i = path.lastIndexOf(".")
	if i > 0
		part1 = path.substring(0, i)
		part2 = path.substring(i + 1)
		entity = _evalDataPath(entity, part1, true, "never", context)

		if not entity?
			throw new cola.Exception("Cannot set value to #{entity}.")

		if not (entity instanceof _EntityList)
			if entity instanceof cola.ProviderInvoker
				entity = undefined
			else if typeof entity._set is "function"
				entity._set(part2, value, dataType)
			else
				entity[part2] = value
		else
			throw new cola.Exception("Cannot set value to EntityList \"#{path}\".")
	else if typeof entity._set is "function"
		entity._set(path, value, dataType)
	else
		entity[path] = value
	return

_Entity._getEntityId = (entity)->
	return null unless entity
	if entity instanceof cola.Entity
		return entity.id
	else if typeof entity is "object"
		entity._id ?= cola.uniqueId()
		return entity._id

TYPE_SEVERITY =
	info: 1
	warn: 2
	error: 4

class cola.Entity.MessageHolder
	constructor: ()->
		@keyMessage = {}
		@propertyMessages = {}

	compare: (message1, message2)->
		return (TYPE_SEVERITY[message1.type] or 0) - (TYPE_SEVERITY[message2.type] or 0)

	add: (prop, message)->
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

	clear: (prop, force)->
		if not force
			if prop
				messages = @propertyMessages[prop]
				if messages
					topKeyMessage = @keyMessage[$]
					@propertyMessages[prop] = newMessages = []
					for message in messages
						if message.sticky
							newMessages.push(message)
							if not keyMessage or @compare(message, keyMessage) > 0
								keyMessage = message

				changed = (newMessages?.length or 0) < (messages?.length or 0)
				@keyMessage[prop] = keyMessage

				for p, keyMessage of @keyMessage
					if p is "$" then continue
					if not topKeyMessage
						topKeyMessage = keyMessage
					else if keyMessage and @compare(keyMessage, topKeyMessage) > 0
						topKeyMessage = keyMessage

				@keyMessage["$"] = topKeyMessage
			else
				for prop of @propertyMessages
					if @clear(prop, force)
						changed = true
				if @clear("$", force)
					changed = true
		else
			if prop
				changed = !!@propertyMessages[prop]
				delete @propertyMessages[prop]
				delete @keyMessage[prop]
			else
				changed = !!@keyMessage["$"]
				@keyMessage = {}
				@propertyMessages = {}
		return changed

	getMessages: (prop = "$")->
		return @propertyMessages[prop]

	getKeyMessage: (prop = "$")->
		return @keyMessage[prop]

	findMessages: (prop, type)->
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

class cola.Iterable
	each: -> return

cola.each = (collection, fn, options)->
	if collection instanceof cola.EntityList
		collection.each(fn, options)
	else if collection instanceof Array
		if typeof collection.each is "function"
			collection.each(fn)
		else
			cola.util.each(collection, fn)
	else if collection instanceof cola.Iterable
		collection.each(fn)
	return

###
util
###

cola.util.filter = (data, criteria, option)->
	criteria = cola._trimCriteria(criteria, option)
	return _filterCollection(data, criteria, option)

cola.util.where = (data, criteria, option = {})->
	if option.caseSensitive is undefined then option.caseSensitive = true
	if option.strict is undefined then option.strict = true
	criteria = cola._trimCriteria(criteria, option)
	return _filterCollection(data, criteria, option)

cola.util.find = (data, criteria, option = {})->
	option.one = true
	result = cola.util.where(data, criteria, option)
	return result?[0]

cola.util.sort = (collection, comparator, caseSensitive)->
	return _sortCollection(collection, comparator, caseSensitive)

cola.util.flush = (data, loadMode)->
	if data instanceof cola.Entity or data instanceof cola.EntityList
		if data.parent instanceof cola.Entity and data._parentProperty
			return data.parent.flush(data._parentProperty, loadMode)
	return

###
index
###

class cola.EntityIndex
	constructor: (@data, @property, @option = {})->
		@model = model = @data._dataModel?.model
		if not model
			throw new cola.Exception("The Entity or EntityList is not belongs to any Model.")

		@tree = @option.tree
		@isCollection = @data instanceof cola.EntityList
		if not @tree and not @isCollection
			throw new cola.Exception("Can not build index for single Entity.")

		@index = {}
		@idMap = {}
		@buildIndex()

		model.data.addEntityListener(@)

		@data._indexMap ?= {}
		@data._indexMap[@property] = @
		return

	buildIndex: ()->
		data = @data
		if data instanceof cola.Entity
			@_buildIndexForEntity(data)
		else if data instanceof cola.EntityList
			@_buildIndexForEntityList(data)
		return

	_buildIndexForEntityList: (entityList)->
		entityList.each (entity)=>
			@_buildIndexForEntity(entity)
			return
		return

	_buildIndexForEntity: (entity)->
		value = entity.get(@property)
		@index[value + ""] = entity
		@idMap[entity.id] = true

		if @tree
			if typeof @tree is "string"
				childProperty = @tree
			else
				childProperty = null

			data = entity._data
			for p, v of data
				if childProperty and p isnt childProperty
					continue
				if v
					if v instanceof cola.Entity
						@_buildIndexForEntity(v)
					else if v instanceof cola.EntityList
						@_buildIndexForEntityList(v)
		return

	onEntityAttach: (entity)->
		if @tree
			p = entity
			while p
				if p is @data
					valid = true
					break
				p = p.parent
		else if @isCollection
			valid = entity.parent is @data
		else
			valid = entity is @data

		if valid
			value = entity.get(@property)
			@idMap[entity.id] = value
			@index[value + ""] = entity
		return

	onEntityDetach: (entity)->
		if @idMap.hasOwnProperty(entity.id)
			value = @idMap[entity.id]
			delete @idMap[entity.id]
			if @index[value + ""] is entity
				delete @index[value + ""]
		return

	update: (entity)->
		@onEntityDetach(entity)
		@onEntityAttach(entity)
		return

	find: (value)->
		return @index[value + ""]

	destroy: ()->
		@model.data.removeEntityListener(@)
		delete @data._indexMap?[@property]
		return

cola.util.buildIndex = (data, property, option)->
	index = data._indexMap?[property]
	return index or new cola.EntityIndex(data, property, option)