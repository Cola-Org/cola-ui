###
dirty tree
###

cola.util.dirtyTree = (data, options) ->
	return undefined unless data
	context = options?.context or {}
	context.entityMap = {}
	context.messages = {}
	return _extractDirtyTree(data, context, options or {})

_processEntity = (entity, context, options) ->
	toJSONOptions =
		simpleValue: true
		entityId: options.entityId or true
		state: true
		oldData: options.oldData

	if not options.ignoreValidation and entity.state isnt cola.Entity.STATE_DELETED
		entity.validate()
		messages = entity.findMessages()
		if messages
			for message in messages
				context.messages[message.type] ?= []
				context.messages[message.type].push(message)

	if entity.state isnt cola.Entity.STATE_NONE
		json = entity.toJSON(toJSONOptions)

	data = entity._data
	for prop, val of data
		if prop.charCodeAt(0) is 36 # `$`
			continue
		if val and (val instanceof cola.Entity or val instanceof cola.EntityList)
			context.parentProperty = prop
			val = _extractDirtyTree(val, context, options)
			if val?
				json ?= entity.toJSON(toJSONOptions)
				json[prop] = val

	if json?
		context.entityMap[entity.id] = entity

	return json

_processEntityList = (entityList, context, options) ->
	entities = []
	page = entityList._first
	if page
		next = page._first
		while page
			if next
				json = _processEntity(next, context, options)
				if json? then entities.push(json)
				next = next._next
			else
				page = page._next
				next = page?._first
	return if entities.length then entities else null

_extractDirtyTree = (data, context, options) ->
	if data instanceof cola.EntityList
		return _processEntityList(data, context, options)
	else
		return _processEntity(data, context, options)

cola.util.update = (url, data, options = {}) ->
	context = options.context = options.context or {}
	if data and (data instanceof cola.Entity or data instanceof cola.EntityList)
		data = cola.util.dirtyTree(data, options)

	if not options.ignoreValidation
		if context.messages.error
			deferred = $.Deferred().reject(messages: context.messages)

	if not deferred
		if options.preProcessor
			data = options.preProcessor(data, options)

		if data or options.alwaysExecute
			deferred = $.ajax(
				url: url
				type: options.method or "post"
				contentType: options.contentType or "application/json"
				dataType: "json"
				data: JSON.stringify(data)
				options: options
			).done (responseData) ->
				if context
					if options.postProcessor
						return options.postProcessor(responseData, options)

					if responseData?.entityMap
						for entityId, entityDiff of responseData.entityMap
							state = null
							entity = context.entityMap[entityId]
							if entityDiff
								if entityDiff.data
									for p, v of entityDiff.data
										entity._set(p, v, true)
								state = entityDiff.state

							if state
								if state is cola.Entity.STATE_DELETED or
									(state is cola.Entity.STATE_NONE and entity.state is cola.Entity.STATE_DELETED)
										if entity._page
											entity._page._removeElement(entity)
										else if entity.parent
											entity.parent._set(entity._parentProperty, null, true)
								else
									entity.setState(state)
							else
								if entity.state is cola.Entity.STATE_DELETED
									entity._page?._removeElement(entity)
								else
									entity.setState(cola.Entity.STATE_NONE)
					else
						for entityId, entity of context.entityMap
							if entity.state is cola.Entity.STATE_DELETED
								entity._page?._removeElement(entity)
							else
								entity.setState(cola.Entity.STATE_NONE)

				return responseData.result
		else
			deferred = $.Deferred().reject("NO_DATA")

	deferred.fail (error) ->
		return if options.silence
		setTimeout(() =>
			return if @errorProcessed

			if error is "NO_DATA"
				console.warn(cola.resource("cola.data.noDataSubmit"))
				cola.NotifyTipManager.warning(
					message: cola.resource("cola.data.noDataSubmit")
					showDuration: 5000
				)
			else if error.responseJSON
				console.error(error.responseJSON)
				cola.NotifyTipManager.error(
					message: cola.resource("cola.data.validateErrorTitle")
#					description: cola.resource("cola.data.validateErrorMessage", error.responseJSON.description)
					showDuration: 5000
				)
			else if error.messages?.error
				console.error(error.messages.error)
				cola.NotifyTipManager.error(
					message: cola.resource("cola.data.validateErrorTitle")
					description: cola.resource("cola.data.validateErrorMessage", error.messages.error.length)
					showDuration: 5000
				)
			else
				console.error(error)
				cola.NotifyTipManager.error(
					message: cola.resource("cola.data.validateErrorTitle")
					showDuration: 5000
				)
			return
		, 0)
		return

	return deferred

cola.util.autoUpdate = (url, model, path, options = {}) ->
	delay = options.delay or 5000

	autoUpdateHanlder =
		_doneHandlers: [],
		_failHandlers: [],

		_updateTimerId: 0,
		dirty: false

		schedule: () ->
			if @_updateTimerId
				clearTimeout(@_updateTimerId)
				@_updateTimerId = 0

			@dirty = true
			@_updateTimerId = setTimeout(() =>
				@updateIfNecessary()
				return
			, delay)
			return

		updateIfNecessary: () ->
			if @dirty
				@dirty = false
				@_updateTimerId = 0
				data = model.get(path, "never")
				if data
					self = @
					cola.util.update(url, data, options).done((result) =>
						retVal = @_notify("done", result)
						return retVal
					).fail((error) ->
						if error is "NO_DATA"
							@errorProcessed = true
						else
							self._notify("fail", error)
						return
					)
				return true
			return false

		_notify: (type, result) ->
			for handler in @["_" + type + "Handlers"]
				retVal = handler(result)
				if retVal isnt undefined
					result = retVal
			return result

		done: (fn) ->
			@_doneHandlers.push(fn)
			return @

		fail: (fn) ->
			@_failHandlers.push(fn)
			return @

	model.watch path + ".**", (messagePath, type) ->
		if type is cola.constants.MESSAGE_PROPERTY_CHANGE or
		  type is cola.constants.MESSAGE_INSERT or
		  type is cola.constants.MESSAGE_REMOVE
			autoUpdateHanlder.schedule()
		return

	return autoUpdateHanlder
