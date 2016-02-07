_Entity_getEntityPath = (markNoncurrent) ->
	if !markNoncurrent and @_pathCache then return @_pathCache

	parent = @parent
	if !parent? then return

	path = []
	self = @
	while parent?
		if parent instanceof cola.EntityList then lastEntity = self
		part = self.parentProperty
		if part
			if markNoncurrent and self instanceof cola.EntityList
				if markNoncurrent == "always" or lastEntity and self.current != lastEntity
					path.push("!" + part)
				else
					path.push(part)
			else
				path.push(part)
		self = parent
		parent = parent.parent
	path = path.reverse()
	if !markNoncurrent then @_pathCache = path
	return path

_Entity_setListener = (listener) ->
	@_setObserver(
		entityMessageReceived: (messageCode, arg) ->
			listenerArg = arg

			if messageCode is dorado.Entity._MESSAGE_DATA_CHANGED
				type = cola.constants.MESSAGE_PROPERTY_CHANGE
				path = arg.entity.getPath(true)

			else if messageCode is dorado.Entity._MESSAGE_ENTITY_STATE_CHANGED
				type = cola.constants.MESSAGE_EDITING_STATE_CHANGE
				listenerArg =
					entity: arg.entity
					state: if arg.state is dorado.Entity.STATE_MOVED then dorado.Entity.STATE_MODIFIED else arg.state
				path = arg.entity.getPath(true)

			else if messageCode is dorado.Entity._MESSAGE_REFRESH_ENTITY
				type = cola.constants.MESSAGE_VALIDATION_STATE_CHANGE
				path = arg.entity.getPath(true)
			else if messageCode is dorado.Entity._MESSAGE_CURRENT_CHANGED
				type = cola.constants.MESSAGE_CURRENT_CHANGE
				arg.current = arg.newCurrent
				path = arg.entity.getPath(true)

			else if messageCode is dorado.Entity._MESSAGE_DELETED
				type = cola.constants.MESSAGE_REMOVE
				path = arg.entity.getPath(true)
			else if messageCode is dorado.Entity._MESSAGE_INSERTED
				type = cola.constants.MESSAGE_INSERT
				path = arg.entity.getPath(true)

			else if messageCode is dorado.Entity._MESSAGE_LOADING_START
				type = cola.constants.MESSAGE_LOADING_START
				path = arg.entityList.getPath(true)
			else if messageCode is dorado.Entity._MESSAGE_LOADING_END
				type = cola.constants.MESSAGE_LOADING_END
				path = arg.entityList.getPath(true)

			else
				type = cola.constants.MESSAGE_REFRESH
				path = (arg.entity or arg.entityList).getPath(true)

			if arg.property
				if path
					path = path.concat(arg.property)
				else
					path = [arg.property]

			listener.onMessage(path, type, listenerArg)
			return
	)
	return

# Entity

cola.Entity = dorado.Entity

cola.Entity::_setListener = _Entity_setListener
cola.Entity::getPath = _Entity_getEntityPath

cola.Entity::hasValue = (property) ->
	return @.get(property) isnt undefined

# EntityList

cola.EntityList = dorado.EntityList

cola.EntityList::_setListener = _Entity_setListener
cola.EntityList::getPath = _Entity_getEntityPath