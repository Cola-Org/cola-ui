#IMPORT_BEGIN
if exports?
	cola = require("./util")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

tagSplitter = " "

doMergeDefinitions = (definitions, mergeDefinitions, overwrite) ->
	return if definitions is mergeDefinitions
	for name, mergeDefinition of mergeDefinitions
		if definitions.$has(name)
			definition = definitions[name]
			if definition and mergeDefinition
				for prop of mergeDefinition
					if overwrite or not definition.hasOwnProperty(prop) then definition[prop] = mergeDefinition[prop]
			else
				definitions[name] = mergeDefinition
		else
			definitions[name] = mergeDefinition
	return

hasDefinition = (name) -> @hasOwnProperty(name.toLowerCase())
getDefinition = (name) -> @[name.toLowerCase()]

cola.preprocessClass = (classType) ->
	return unless not classType.attributes._inited or not classType.events._inited

	superType = classType.__super__?.constructor
	if superType
		if superType and (not superType.attributes._inited or not superType.events._inited)
			cola.preprocessClass(superType)

		# merge attributes
		# TODO: 此处可以考虑预先计算出有无含默认值设置的属性，以便在对象创建时提高性能
		attributes = classType.attributes
		if not attributes._inited
			attributes._inited = true

			for name, definition of attributes
				realName = name.toLowerCase()
				if name isnt realName
					definition ?= {}
					definition.name = name
					attributes[realName] = definition
					delete attributes[name]

			attributes.$has = hasDefinition
			attributes.$get = getDefinition

			doMergeDefinitions(attributes, superType.attributes, false)

		# merge events
		events = classType.events
		if not events._inited
			events._inited = true

			for name, definition of events
				realName = name.toLowerCase()
				if name isnt realName
					events[realName] = definition
					delete events[name]

			events.$has = hasDefinition
			events.$get = getDefinition

			doMergeDefinitions(events, superType.events, false)
	return

class cola.Element
	@mixin: (classType, mixin) ->
		for name, member of mixin
			if name is "attributes"
				mixinAttributes = member
				if mixinAttributes
					attributes = classType.attributes ?= {}
					doMergeDefinitions(attributes, mixinAttributes, true)
			else if name is "events"
				mixInEvents = member
				if mixInEvents
					events = classType.events ?= {}
					doMergeDefinitions(events, mixInEvents, true)
			else if name is "constructor"
				if not classType._constructors
					classType._constructors = [ member ]
				else
					classType._constructors.push(member)
			else if name is "destroy"
				if not classType._destructors
					classType._destructors = [ member ]
				else
					classType._destructors.push(member)
			else
				classType.prototype[name] = member
		return

	@attributes:
		model:
			readOnly: true
			getter: () -> @_scope

		tag:
			getter: ->
				return if @_tag then @_tag.join(tagSplitter) else null
			setter: (tag) ->
				cola.tagManager.unreg(t, @) for t in @_tag if @_tag
				if tag
					@_tag = ts = tag.split(tagSplitter)
					cola.tagManager.reg(t, @) for t in ts
				else
					@_tag = null
				return

		userdata:
			getter: () -> @_userData
			setter: (data) ->
				@_userData = data
				return

	@events:
		create: null
		attributeChange: null
		destroy: null

	constructor: (config) ->
		classType = @constructor
		if not classType.attributes._inited or not classType.events._inited
			cola.preprocessClass(classType)

		@_constructing = true
		@_scope = config?.scope or cola.currentScope

		attrConfigs = classType.attributes
		for attr, attrConfig of attrConfigs
			if attrConfig?.defaultValue != undefined
				if attrConfig.setter
					attrConfig.setter.call(@, attrConfig.defaultValue, attr)
				else
					@["_" + (attrConfig?.name or attr)] = attrConfig.defaultValue

		if classType._constructors
			for constructor in classType._constructors
				constructor.call(@)

		if config then @set(config, true)
		@fire("create", @)
		delete @_constructing

	destroy: ()->
		classType = @constructor
		if classType._destructors
			for destructor in classType._destructors
				destructor.call(@)

		if @_elementAttrBindings
			for p, elementAttrBinding of @_elementAttrBindings
				elementAttrBinding.destroy()

		@fire("destroy", @)
		@_set("tag", null) if @_tag
		return

	get: (attr, ignoreError) ->
		if attr.indexOf(".") > -1
			paths = attr.split(".")
			obj = @
			for path in paths
				if obj instanceof cola.Element
					obj = obj._get(path, ignoreError)
				else if typeof obj.get is "function"
					obj = obj.get(path)
				else
					obj = obj[path]
				if not obj? then break
			return obj
		else
			return @_get(attr, ignoreError)

	_get: (attr, ignoreError) ->
		if not @constructor.attributes.$has(attr)
			if ignoreError then return
			throw new cola.Exception("Unrecognized Attribute \"#{attr}\".")

		attrConfig = @constructor.attributes[attr.toLowerCase()]
		if attrConfig?.getter
			return attrConfig.getter.call(@, attr)
		else
			return @["_" + attr]

	set: (attr, value, ignoreError) ->
		if typeof attr is "string"
# set(string, any)
			if attr.indexOf(".") > -1
				paths = attr.split(".")
				obj = @
				for path, i in paths
					if obj instanceof cola.Element
						obj = obj._get(path, ignoreError)
					else
						obj = obj[path]
					if not obj? then break
					if i >= (paths.length - 2) then break

				if not obj? and not ignoreError
					throw new cola.Exception("Cannot set attribute \"#{path[0...i].join(".")}\" of undefined.")

				if obj instanceof cola.Element
					obj._set(paths[paths.length - 1], value, ignoreError)
				else if typeof obj.set is "function"
					obj.set(paths[paths.length - 1], value)
				else
					obj[paths[paths.length - 1]] = value
			else
				@_set(attr, value, ignoreError)
		else
# set(object, ignoreError)
			config = attr
			ignoreError = value
			for attr of config
				@set(attr, config[attr], ignoreError)
		return @

	_set: (attr, value, ignoreError) ->
		if typeof value is "string" and @_scope
			if value.charCodeAt(0) is 123 # `{`
				parts = cola._compileText(@_scope, value)
				if parts?.length > 0
					value = parts[0]

		if @constructor.attributes.$has(attr)
			attrConfig = @constructor.attributes[attr.toLowerCase()]
			if attrConfig
				if attrConfig.name
					attr = attrConfig.name
				if attrConfig.readOnly
					if ignoreError then return
					throw new cola.Exception("Attribute \"#{attr}\" is readonly.")

				if not @_constructing and attrConfig.readOnlyAfterCreate
					if ignoreError then return
					throw new cola.Exception("Attribute \"#{attr}\" cannot be changed after create.")
		else if value
			eventName = attr
			i = eventName.indexOf(":")
			if i > 0 then eventName = eventName.substring(0, i)
			if @constructor.events.$has(eventName)
				if value instanceof cola.Expression
					expression = value
					scope = @_scope
					@on(attr, (self, arg) ->
						expression.evaluate(scope, "never", {
							vars:
								$self: self
								$arg: arg
								$dom: arg.dom
								$event: arg.event
						})
						return
					, ignoreError)
					return
				else if typeof value is "function"
					@on(attr, value)
					return
				else if typeof value is "string"
					action = @_scope?.action(value)
					if action
						@on(attr, action)
						return

			if ignoreError then return
			throw new cola.Exception("Unrecognized Attribute \"#{attr}\".")

		@_doSet(attr, attrConfig, value)

		if @_eventRegistry
			if @getListeners("attributeChange")
				@fire("attributeChange", @, { attribute: attr })
		return

	_doSet: (attr, attrConfig, value) ->
		if not @_duringBindingRefresh and @_elementAttrBindings
			elementAttrBinding = @_elementAttrBindings[attr]
			if elementAttrBinding
				elementAttrBinding.destroy()
				delete @_elementAttrBindings[attr]

		if value instanceof cola.Expression and cola.currentScope
			expression = value
			scope = cola.currentScope
			if expression.isStatic
				value = expression.evaluate(scope, "never")
			else
				elementAttrBinding = new cola.ElementAttrBinding(@, attr, expression, scope)

				@_elementAttrBindings ?= {}
				elementAttrBindings = @_elementAttrBindings
				if elementAttrBindings
					elementAttrBindings[attr] = elementAttrBinding
				value = elementAttrBinding.evaluate()

		if attrConfig
			if attrConfig.type is "boolean"
				if value? and typeof value isnt "boolean"
					value = value is "true"
			else if attrConfig.type is "number"
				if value? and typeof value isnt "number"
					value = +value or 0

			if attrConfig.enum and attrConfig.enum.indexOf(value) < 0
				throw new cola.Exception("The value \"#{value}\" of attribute \"#{attr}\" is out of range.")

			if attrConfig.setter
				attrConfig.setter.call(@, value, attr)
				return

		@["_" + (attrConfig?.name or attr)] = value
		return

	_on: (eventName, listener, alias, once) ->
		eventName = eventName.toLowerCase()
		eventConfig = @constructor.events[eventName]

		if @_eventRegistry
			listenerRegistry = @_eventRegistry[eventName]
		else
			@_eventRegistry = {}

		if not listenerRegistry
			@_eventRegistry[eventName] = listenerRegistry = {}

		if once
			listenerRegistry.onceListeners ?= []
			listenerRegistry.onceListeners.push(listener)

		listeners = listenerRegistry.listeners
		aliasMap = listenerRegistry.aliasMap
		if listeners
			if eventConfig?.singleListener and listeners.length
				throw new cola.Exception("Multi listeners is not allowed for event \"#{eventName}\".")

			if alias and aliasMap?[alias] > -1 then cola.off(eventName + ":" + alias)
			listeners.push(listener)
			i = listeners.length - 1
		else
			listenerRegistry.listeners = listeners = [ listener ]
			i = 0

		if alias
			if not aliasMap
				listenerRegistry.aliasMap = aliasMap = {}
			aliasMap[alias] = i
		return

	on: (eventName, listener, once) ->
		i = eventName.indexOf(":")
		if i > 0
			alias = eventName.substring(i + 1)
			eventName = eventName.substring(0, i)

		if not @constructor.events.$has(eventName)
			throw new cola.Exception("Unrecognized event \"#{eventName}\".")

		if typeof listener isnt "function"
			throw new cola.Exception("Invalid event listener.")

		@_on(eventName, listener, alias, once)
		return @

	one: (eventName, listener) ->
		@on(eventName, listener, true)

	_off: (eventName, listener, alias) ->
		eventName = eventName.toLowerCase()
		listenerRegistry = @_eventRegistry[eventName]
		return @ unless listenerRegistry

		listeners = listenerRegistry.listeners
		return @ unless listeners and listeners.length

		i = -1
		if alias or listener
			if alias
				aliasMap = listenerRegistry.aliasMap
				i = aliasMap?[alias]

				if i > -1
					delete aliasMap?[alias]
					listener = listeners[i]
					listeners.splice(i, 1)
			else if listener
				i = listeners.indexOf(listener)
				if i > -1
					listeners.splice(i, 1)

					aliasMap = listenerRegistry.aliasMap
					if aliasMap
						for alias of aliasMap
							if aliasMap[alias] is listener
								delete aliasMap[alias]
								break

			if listenerRegistry.onceListeners and listener
				onceListeners = listenerRegistry.onceListeners
				i = onceListeners.indexOf(listener)
				if i > -1
					onceListeners.splice(i, 1)
					if not onceListeners.length
						delete listenerRegistry.onceListeners
		else
			delete listenerRegistry.listeners
			delete listenerRegistry.aliasMap
		return

	off: (eventName, listener) ->
		return @ unless @_eventRegistry

		i = eventName.indexOf(":")
		if i > 0
			alias = eventName.substring(i + 1)
			eventName = eventName.substring(0, i)

		@_off(eventName, listener, alias)
		return @

	getListeners: (eventName) ->
		return @_eventRegistry?[eventName.toLowerCase()]?.listeners

	fire: (eventName, self, arg) ->
		return unless @_eventRegistry

		eventName = eventName.toLowerCase()
		result = undefined
		listenerRegistry = @_eventRegistry[eventName]
		if listenerRegistry
			listeners = listenerRegistry.listeners
			if listeners
				if arg
					arg.model = @_scope
				else
					arg = { model: @_scope }

				oldScope = cola.currentScope
				cola.currentScope = @_scope
				try
					for listener in listeners
						if typeof listener is "function"
							argsMode = listener._argsMode
							if not listener._argsMode
								argsMode = cola.util.parseListener(listener)
							if argsMode is 1
								retValue = listener.call(self, self, arg)
							else
								retValue = listener.call(self, arg, self)
						else if typeof listener is "string"
							retValue = do() => eval(listener)

						if retValue isnt undefined then result = retValue
						if retValue is false then break
				finally
					cola.currentScope = oldScope

				if listenerRegistry.onceListeners
					onceListeners = listenerRegistry.onceListeners.slice()
					delete listenerRegistry.onceListeners
					@off(eventName, listener) for listener in onceListeners

		return result

class cola.Definition extends cola.Element
	@attributes:
		name:
			readOnly: true

	constructor: (config) ->
		if config?.name
			@_name = config.name
			scope = config?.scope or cola.currentScope
			if scope
				scope.data.regDefinition(@)
		super(config)

###
    Element Group
###
cola.Element.createGroup = (elements, model) ->
	if model
		elements = []
		for ele in elements
			if ele._scope && not ele._model
				scope = ele._scope
				while scope
					if scope instanceof cola.Scope
						ele._model = scope
						break
					scope = scope.parent
			if ele._model is model then elements.push(ele)
	else
		elements = if elements then elements.slice(0) else []

	elements.set = (attr, value, ignoreError) ->
		element.set(attr, value, ignoreError) for element in elements
		return @
	elements.on = (eventName, listener, once) ->
		element.on(eventName, listener, once) for element in elements
		return @
	elements.off = (eventName) ->
		element.off(eventName) for element in elements
		return @
	return elements

###
    Tag Manager
###

cola.tagManager =
	registry: {}

	reg: (tag, element) ->
		elements = @registry[tag]
		if elements
			elements.push(element)
		else
			@registry[tag] = [ element ]
		return

	unreg: (tag, element) ->
		if element
			elements = @registry[tag]
			if elements
				i = elements.indexOf(element)
				if i > -1
					if i is 0 and elements.length is 1
						delete @registry[tag]
					else
						elements.splice(i, 1)
		else
			delete @registry[tag]
		return

	find: (tag) ->
		return @registry[tag]

cola.tag = (tag) ->
	elements = cola.tagManager.find(tag)
	return cola.Element.createGroup(elements)

###
    Type Registry
###

typeRegistry = {}

cola.registerType = (namespace, typeName, constructor) ->
	holder = typeRegistry[namespace] or typeRegistry[namespace] = {}
	holder[typeName] = constructor
	return

cola.registerTypeResolver = (namespace, typeResolver) ->
	holder = typeRegistry[namespace] or typeRegistry[namespace] = {}
	holder._resolvers ?= []
	holder._resolvers.push(typeResolver)
	return

cola.resolveType = (namespace, config, baseType) ->
	constructor = null
	holder = typeRegistry[namespace]
	if holder
		constructor = holder[config?.$type or "_default"]
		if not constructor and holder._resolvers
			for resolver in holder._resolvers
				constructor = resolver(config)
				if constructor
					if baseType and not cola.util.isCompatibleType(baseType, constructor)
						throw new cola.Exception("Incompatiable class type.")
					break
		return constructor
	return

cola.create = (namespace, config, baseType) ->
	if typeof config is "string"
		config = {
			$type: config
		}
	constr = cola.resolveType(namespace, config, baseType)
	return new constr(config)