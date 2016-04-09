_destroyDomBinding = (node, data) ->
	domBinding = data[cola.constants.DOM_BINDING_KEY]
	domBinding?.destroy()
	return

class cola._DomBinding
	constructor: (dom, @scope, feature) ->
		@dom = dom
		@$dom = $(dom)

		if feature
			if feature instanceof Array
				for f in feature
					@addFeature(f)
			else
				@addFeature(feature)

		cola.util.userData(dom, cola.constants.DOM_BINDING_KEY, @)
		cola.util.onNodeRemoved(dom, _destroyDomBinding)

	destroy: () ->
		_feature = @feature
		if _feature
			if _feature instanceof Array
				for feature in _feature
					@unbindFeature(feature)
			else
				@unbindFeature(_feature)

		delete @dom
		delete @$dom
		return

	bindFeature: (feature) ->
		return unless feature._processMessage

		path = feature.path
		if path
			if typeof path == "string"
				@bind(path, feature)
			else
				for p in path
					@bind(p, feature)
		return

	unbindFeature: (feature) ->
		return unless feature._processMessage

		path = feature.path
		if path
			if typeof path == "string"
				@unbind(path, feature)
			else
				for p in path
					@unbind(p, feature)
		return

	addFeature: (feature) ->
		feature.id ?= cola.uniqueId()
		feature.init?(@)

		if !@feature
			@feature = feature
		else if @feature instanceof Array
			@feature.push(feature)
		else
			@feature = [@feature, feature]

		@bindFeature(feature)
		return

	removeFeature: (feature) ->
		_feature = @feature
		if _feature
			if _feature == feature
				delete @feature
				if _feature.length == 1
					delete @feature
			else
				i = _feature.indexOf(feature)
				_feature.splice(i, 1) if i > -1
			@unbindFeature(feature)
		return

	bind: (path, feature) ->
		pipe = {
			_processMessage: (bindingPath, path, type, arg) =>
				if not feature.disabled
					feature._processMessage(@, bindingPath, path, type, arg)
					if feature.disabled then pipe.disabled = true
				else
					pipe.disabled = true
				return
		}
		@scope.data.bind(path, pipe)
		@[feature.id] = pipe
		return

	unbind: (path, feature) ->
		pipe = @[feature.id]
		delete @[feature.id]
		@scope.data.unbind(path, pipe)
		return

	refresh: (force) ->
		feature = @feature
		if feature instanceof Array
			f.refresh(@, force) for f in feature
		else if feature
			feature.refresh(@, force) 
		return

	clone: (dom, scope) ->
		return new @constructor(dom, scope, @feature, true)

class cola._AliasDomBinding extends cola._DomBinding
	destroy: () ->
		super()
		@scope.destroy() if @subScopeCreated
		return

class cola._RepeatDomBinding extends cola._DomBinding
	constructor: (dom, scope, feature, clone) ->
		if clone
			super(dom, scope, feature)
		else
			@scope = scope
			headerNode = document.createComment("Repeat Head ")
			cola._ignoreNodeRemoved = true
			dom.parentNode.replaceChild(headerNode, dom)
			cola.util.cacheDom(dom)
			cola._ignoreNodeRemoved = false
			@dom = headerNode

			cola.util.userData(headerNode, cola.constants.DOM_BINDING_KEY, @)
			cola.util.userData(headerNode, cola.constants.REPEAT_TEMPLATE_KEY, dom)
			cola.util.onNodeRemoved(headerNode, _destroyDomBinding)

			repeatItemDomBinding = new cola._RepeatItemDomBinding(dom, null)
			repeatItemDomBinding.repeatDomBinding = @
			repeatItemDomBinding.isTemplate = true

			if feature
				if feature instanceof Array
					for f in feature
						if f instanceof cola._RepeatFeature
							@addFeature(f)
						else
							repeatItemDomBinding.addFeature(f)
				else
					if feature instanceof cola._RepeatFeature
						@addFeature(feature)
					else
						repeatItemDomBinding.addFeature(feature)

	destroy: () ->
		super()
		@scope.destroy() if @subScopeCreated
		delete @currentItemDom
		return

class cola._RepeatItemDomBinding extends cola._AliasDomBinding
	destroy: () ->
		super()
		if !@isTemplate
			delete @repeatDomBinding.itemDomBindingMap?[@itemId]
		return

	clone: (dom, scope) ->
		cloned = super(dom, scope)
		cloned.repeatDomBinding = @repeatDomBinding
		return cloned

	bind: (path, feature) ->
		return if @isTemplate
		return super(path, feature)

	bindFeature: (feature) ->
		return if @isTemplate
		return super(feature)

	processDataMessage: (path, type, arg) ->
		if !@isTemplate
			@scope.data._processMessage("**", path, type, arg)
		return

	refresh: () ->
		return if @isTemplate
		return super()

	remove: () ->
		if !@isTemplate
			@$dom.remove()
		return