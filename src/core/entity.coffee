#IMPORT_BEGIN
if exports?
	cola = require("./data-type")
	require("./service")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

getEntityPath = (markNoncurrent) ->
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

	constructor: (dataType, data) ->
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

	get: (prop, loadMode = "auto", context) ->
		if typeof loadMode == "function"
			loadMode = "auto"
			callback = loadMode

		if prop.indexOf(".") > 0
			return _evalDataPath(@, prop, false, loadMode, callback, context)
		else
			return @_get(prop, loadMode, callback, context)

	_get: (prop, loadMode, callback, context) ->
		loadData = (provider) ->
			retValue = undefined
			providerInvoker = provider.getInvoker(@)
			if loadMode == "always"
				retValue = providerInvoker.invokeSync()
				retValue = @_set(prop, retValue)
				if retValue and (retValue instanceof cola.EntityList or retValue instanceof cola.Entity)
					retValue._providerInvoker = providerInvoker
			else
				if context
					context.unloaded = true
					context.providerInvokers ?= []
					context.providerInvokers.push(providerInvoker)
				if loadMode == "auto"
					@_data[prop] = providerInvoker
					providerInvoker.invokeAsync(
						complete: (success, result) =>
							if @_data[prop] != providerInvoker then success = false
							if success
								result = @_set(prop, result)
								retValue = result
								if result and (result instanceof cola.EntityList or result instanceof cola.Entity)
									result._providerInvoker = providerInvoker
								if callback
									cola.callback(callback, success, result)
							else
								@_set(prop, null)
							return
					)
			return retValue

		property = @dataType?.getProperty(prop)

		value = @_data[prop]
		if value == undefined
			if property
				if property instanceof cola.BaseProperty
					provider = property.get("provider")
					context?.unloaded = true
					if provider and loadMode != "never"
						value = loadData.call(@, provider)
				else if property instanceof cola.ComputeProperty
					value = property.compute(@)
		else if value instanceof cola.Provider
			value = loadData.call(@, value)
		else if value instanceof cola.AjaxServiceInvoker
			if loadMode == "always"
				value = providerInvoker.invokeSync()
				if callback
					providerInvoker = value
					providerInvoker.invokeAsync(
						complete: (success, result) =>
							if success
								cola.callback(callback, true, @_data[prop])
							else
								cola.callback(callback, false, result)
							return
					)
				value = undefined
			if context
				context.unloaded = true
				context.providerInvokers ?= []
				context.providerInvokers.push(providerInvoker)
		else if callback
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
		result = cola.DataType.jsonToEntity(value, dataType, aggregated)
		if result and provider
			result.pageSize = provider._pageSize
			result._providerInvoker = provider.getInvoker(@)
		return result

	_set: (prop, value) ->
		oldValue = @_data[prop]

		property = @dataType?.getProperty(prop)
		if property and property instanceof cola.ComputeProperty
			throw new cola.I18nException("cola.error.setData", prop)

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
								throw new cola.I18nException("cola.error.unmatchedDataType", expectedType,
									actualType)
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
# do nothing
					else
						value = @_jsonToEntity(value, null, false, provider)
				changed = oldValue != value
		else
			changed = oldValue != value

		if changed
			if property and property instanceof cola.BaseProperty
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
					throw new cola.I18nException("cola.error.dataAttached", prop)

				value._parent = @
				value._parentProperty = prop
				value._setListener(@_listener)
				value._onPathChange()
				@_mayHasSubEntity = true

			@timestamp = cola.sequenceNo()
			if @_disableWriteObservers == 0
				@_notify(cola.constants.MESSAGE_DATA_CHANGE, {
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

	getText: (prop, loadMode = "auto", callback, context) ->
		if typeof loadMode == "function"
			loadMode = "auto"
			callback = loadMode

		i = prop.lastIndexOf(".")
		if i > 0
			part1 = prop.substring(0, i)
			part2 = prop.substring(i + 1)

			if callback
				@get(part1, loadMode, {
					complete: (success, entity) ->
						if success
							if entity
								if typeof entity._getText == "function"
									entity._getText(part2, loadMode, callback)
								else
									text = entity[path]
									cola.callback(callback, true, (if text? then text + "" else ""))
							else
								cola.callback(callback, true, "")
						else
							cola.callback(callback, false, entity)
						return
				}, context)
			else
				entity = @get(part1, loadMode, null, context)
				if entity
					if typeof entity._getText == "function"
						return entity._getText(part2, null, null, context)
					else
						text = entity[path] + ""
						return if text? then text + "" else ""
		else
			return @_getText(prop, loadMode, callback, context)

	_getText: (prop, loadMode, callback, context) ->
		if callback
			dataType = @dataType
			@_get(prop, loadMode, {
				complete: (success, value) ->
					if success
						if value?
							property = dataType?.getProperty(prop)
							propertyDataType = property?._dataType
							if propertyDataType
								text = propertyDataType.toText(value, property._format)
							else
								text = if value? then value + "" else ""
						cola.callback(callback, true, text or "")
					else
						cola.callback(callback, false, value)
					return
			}, context)
			return ""
		else
			value = @_get(prop, loadMode, null, context)
			if value?
				property = @dataType?.getProperty(prop)
				propertyDataType = property?._dataType
				if propertyDataType
					return propertyDataType.toText(value, property._format)
				else
					return if value? then value + "" else ""
			else
				return ""

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
			throw new cola.I18nException("cola.error.unmatchedDataType", "Object", "Array")

		property = @dataType?.getProperty(prop)
		propertyDataType = property?._dataType
		if propertyDataType and !(propertyDataType instanceof cola.EntityDataType)
			throw new cola.I18nException("cola.error.unmatchedDataType", "cola.EntityDataType",
				propertyDataType._name)

		if property?._aggregated
			entityList = @_get(prop, "never")
			if !entityList?
				entityList = new cola.EntityList(propertyDataType)

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
			throw new cola.I18nException("cola.error.unmatchedDataType", "Object", "Array")

		brother = new _Entity(@dataType, data)
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

	reset: () ->
		delete @_oldData
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

	getPath: getEntityPath

	flushAsync: (property, callback) ->
		propertyDef = @getPprovider(property)
		if !propertyDef?.provider?
			throw new cola.I18nException("cola.error.providerUndefined")

		@_set(property, undefined)

		notifyArg = {
			entity: @
			property: property
		}
		@_notify(cola.constants.MESSAGE_LOADING_START, notifyArg)
		return @_get(property, {
			complete: (success, result) =>
				cola.callback(callback, success, result)
				@_notify(cola.constants.MESSAGE_LOADING_END, notifyArg)
		})

	flushSync = (property) ->
		propertyDef = @getPprovider(property)
		if !propertyDef?.provider?
			throw new cola.I18nException("cola.error.providerUndefined")

		@_set(property, undefined)
		return @_get(property)

	_setListener: (listener) ->
		return if @_listener == listener
		@_listener = listener
		if @_mayHasSubEntity
			data = @_data
			for p, value of data
				if value and (value instanceof _Entity or value instanceof _EntityList)
					value._setListener(listener)
		return

	_onPathChange: () ->
		delete @_pathCache
		if @_mayHasSubEntity
			data = @_data
			for p , value of data
				if value and (value instanceof _Entity or value instanceof _EntityList)
					value._onPathChange()
		return

	disableObservers = () ->
		if @_disableObserverCount < 0 then @_disableObserverCount = 1 else @_disableObserverCount++
		return @

	enableObservers = () ->
		if @_disableObserverCount < 1 then @_disableObserverCount = 0 else @_disableObserverCount--
		return @

	_notify: (type, arg) ->
		if @_disableObserverCount is 0
			path = @getPath(true)
			if (type is cola.constants.MESSAGE_DATA_CHANGE or type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE) and arg.property
				if path
					path = path.concat(arg.property)
				else
					path = [arg.property]
			@_doNotify(path, type, arg)
		return

	_doNotify: (path, type, arg) ->
		@_listener?.onMessage(path, type, arg)
		return

	_validate: (prop) ->
		property = @dataType.getProperty(prop)
		if property and property instanceof cola.BaseProperty
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
					@_validate(property._name)
					@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @, property: property._name})

		keyMessage = @_messageHolder?.getKeyMessage()
		if (oldKeyMessage or keyMessage) and oldKeyMessage isnt keyMessage
			@_notify(cola.constants.MESSAGE_VALIDATION_STATE_CHANGE, {entity: @})
		return keyMessage

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

	clearMessages: (prop) ->
		@_messageHolder?.clear(prop)
		return @

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
		if !(json instanceof Array)
			throw new cola.I18nException("cola.error.unmatchedDataType", "Array", "Object")

		dataType = entityList.dataType
		for data in json
			entity = new _Entity(dataType, data)
			@_insertElement(entity)

		entityList.totalEntityCount = rawJson.$entityCount if rawJson.$entityCount?
		if entityList.totalEntityCount?
			entityList.pageCount = parseInt((entityList.totalEntityCount + entityList.pageSize - 1) / entityList.pageSize)
			entityList.pageCountDetermined = true

		entityList.entityCount += json.length

		entityList._notify(cola.constants.MESSAGE_REFRESH, {
			entityList: entityList
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

		entity._setListener(entityList._listener)
		entity._onPathChange()
		@entityCount++ if entity.state != _Entity.STATE_DELETED
		return

	_removeElement: (entity) ->
		super(entity)
		delete entity._page
		delete entity._parent
		entity._setListener(null)
		entity._onPathChange()
		@entityCount-- if entity.state != _Entity.STATE_DELETED
		return

	_clearElements: () ->
		entity = @_first
		while entity
			delete entity._page
			delete entity._parent
			entity._setListener(null)
			entity._onPathChange()
			entity = entity._next
		@entityCount = 0
		super()
		return

	loadData: (callback) ->
		providerInvoker = @entityList._providerInvoker
		if providerInvoker
			pageSize = @entityList.pageSize
			providerInvoker.invokerOptions.data.from = pageSize * (@pageNo - 1) if pageSize > 1 and @pageNo > 1
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

# full, no-count, append
	pageMode: "append"
	pageSize: 0
	pageNo: 1
	pageCount: 1

	_disableObserverCount: 0

# totalEntityCount
#_parent
#_parentProperty
#_providerInvoker

	constructor: (dataType) ->
		@id = cola.uniqueId()
		@timestamp = cola.sequenceNo()
		@dataType = dataType

	fillData: (array) ->
		page = @_findPage(@pageNo)
		page ?= new Page(@, @pageNo)
		@_insertElement(page, "begin")
		page.initData(array)
		return

	_setListener: (listener) ->
		return if @_listener == listener
		@_listener = listener

		page = @_first
		if !page then return

		next = page._first
		while page
			if next
				next._setListener(listener)
				next = next._next
			else
				page = page._next
				next = page?._first
		return

	_setCurrentPage: (page) ->
		@_currentPage = page
		@pageNo = page?.pageNo or 1
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
		if entity and entity._parent != @
			throw new cola.I18nException("cola.error.entityNotBelongToEntityList")

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
		if entity and entity._parent != @
			throw new cola.I18nException("cola.error.entityNotBelongToEntityList")

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

	_loadPage: (pageNo, setCurrent, callback) ->
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
			else
				if setCurrent then @setCurrent(null)
				page = @_createPage(pageNo)
				if callback
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

	loadPage: (pageNo, callback) ->
		return @_loadPage(pageNo, false, callback)

	gotoPage: (pageNo, callback) ->
		if pageNo < 1
			pageNo = 1
		else if @pageCountDetermined and pageNo > @pageCount
			pageNo = @pageCount
		return @_loadPage(pageNo, true, callback)

	firstPage: (callback) ->
		@gotoPage(1, callback)
		return @

	previousPage: (callback) ->
		pageNo = @pageNo - 1
		if pageNo < 1 then pageNo = 1
		@gotoPage(pageNo, callback)
		return @

	nextPage: (callback) ->
		pageNo = @pageNo + 1
		if @pageCountDetermined and pageNo > @pageCount then pageNo = @pageCount
		@gotoPage(pageNo, callback)
		return @

	lastPage: (callback) ->
		@gotoPage(@pageCount, callback)
		return @

	insert: (entity, insertMode, refEntity) ->
		if insertMode == "before" or insertMode == "after"
			if refEntity and refEntity._parent != @
				throw new cola.I18nException("cola.error.entityNotBelongToEntityList")

			refEntity = @current
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
				throw new cola.I18nException("cola.error.dataAttached", @._parentProperty or "Unknown")
		else
			entity = new _Entity(@dataType, entity)
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

		if entity._parent != @
			throw new cola.I18nException("cola.error.entityNotBelongToEntityList")

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

		if entity and entity._parent != @
			throw new cola.I18NException("cola.error.entityNotBelongToEntityList")

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

	disableObservers = () ->
		if @_disableObserverCount < 0 then @_disableObserverCount = 1 else @_disableObserverCount++
		return @

	enableObservers = () ->
		if @_disableObserverCount < 1 then @_disableObserverCount = 0 else @_disableObserverCount--
		return @

	_notify: (type, arg) ->
		if @_disableObserverCount == 0
			@_listener?.onMessage(@getPath(true), type, arg)
		return

	_doFlush: (callback) ->
		if !@_providerInvoker?
			throw new cola.I18nException("cola.error.providerUndefined")
		@_reset()
		page = @_findPage(@pageNo)
		if !page then @_createPage(@pageNo)

		if callback
			notifyArg = {
				entityList: @
			}
			@_notify(cola.constants.MESSAGE_LOADING_START, notifyArg)
			page.loadData(
				complete: (success, result)  =>
					cola.callback(callback, success, result)
					@_notify(cola.constants.MESSAGE_LOADING_END, notifyArg)
			)
		else
			page.loadData()
		return

	flushAsync: (callback) ->
		@_doFlush(callback)
		return @

	flushSync: () ->
		@_doFlush()
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
			else if not pageNo
				page = page._next
				next = page?._first
		return @

	getPath: getEntityPath

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
			throw new cola.I18nException("cola.error.setData", path)
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
			@keyMessage["$"] = keyMessage
		else
			@keyMessage = {}
			@propertyMessages = {}
		return

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

cola.each = (collection, fn) ->
	if collection instanceof cola.EntityList
		collection.each(fn)
	else if collection instanceof Array
		if typeof collection.each == "function"
			collection.each(fn)
		else
			collection.forEach(fn)
	return