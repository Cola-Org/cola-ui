###
dirty tree
###

cola.util.dirtyTree = (data, options, context) ->
	return undefined unless data

	context ?= {}
	context.entityMap = {}
	return _extractDirtyTree(data, context, options or {})

_processEntity = (entity, context, options) ->
	toJSONOptions =
		simpleValue: true
		entityId: options.entityId
		state: true
		oldData: options.oldData

	if entity.state isnt _Entity.STATE_NONE
		json = entity.toJSON(toJSONOptions)

	data = entity._data
	for prop, value of data
		if prop.charCodeAt(0) is 36 # `$`
			continue

		if value and (value instanceof _Entity or value instanceof _EntityList)
			context.parentProperty = prop
			value = _extractDirtyTree(value, context)

			if value is null then json = entity.toJSON(toJSONOptions)
			json[prop] = value

	if json isnt null
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
				if json isnt null then entities.push(json)
				next = next._next
			else
				page = page._next
				next = page?._first
	return if entities.length then entities else null

_extractDirtyTree = (data, context, options) ->
	context.isList = value instanceof _EntityList
	if context.isList
		return _processEntityList(data, context, options)
	else
		return _processEntity(data, context, options)

cola.util.update = (url, data, options = {}) ->
	if data and (data instanceof _Entity or data instanceof _EntityList)
		context = {}
		data = cola.util.dirtyTree(data, options, context)

	return $.ajax(
		url: url
		type: options.method or "post"
		contentType: options.contentType or "application/json"
		data: JSON.stringify(data)
	  	options: options
	).then (responseData) ->
		if context
			# TODO
			for syncInfo in responseData.syncInfos
				entity = context.entityMap[syncInfo.entityId]
				if syncInfo.data
					for p, v of syncInfo.data
						entity._set(p, v, true)
				entity.setState(syncInfo.state)
		return responseData.result
