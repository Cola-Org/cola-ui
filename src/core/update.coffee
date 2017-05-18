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
		entityId: options.entityId or true
		state: true
		oldData: options.oldData

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
	if data and (data instanceof cola.Entity or data instanceof cola.EntityList)
		context = {}
		data = cola.util.dirtyTree(data, options, context)

	if data or options.alwaysExecute
		return $.ajax(
			url: url
			type: options.method or "post"
			contentType: options.contentType or "application/json"
			dataType: "json"
			data: JSON.stringify(data)
			options: options
		).then (responseData) ->
			if context
				for entityId, entityDiff of responseData.entityMap
					state = null
					entity = context.entityMap[entityId]
					if entityDiff
						if entityDiff.data
							for p, v of entityDiff.data
								entity._set(p, v, true)
						state = entityDiff.state

					if state
						entity.setState(state)
					else if entity.state is cola.Entity.STATE_DELETED
						entity._page?._removeElement(entity)
					else
						entity.setState(cola.Entity.STATE_NONE)

			return responseData.result
	else
		return $.Deferred().reject("NO_DATA")
