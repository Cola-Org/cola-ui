_destroyDomBinding = (node, data) ->
	domBinding = data[cola.constants.DOM_BINDING_KEY]
	domBinding?.destroy()
	return

class cola._DomBinding
	constructor: (dom, @scope, features) ->
		@dom = dom
		@$dom = $(dom)

		if features
			for f in features
				@addFeature(f)

		cola.util.userData(dom, cola.constants.DOM_BINDING_KEY, @)
		cola.util.onNodeDispose(dom, _destroyDomBinding)

	destroy: () ->
		_features = @features
		if _features
			i = _features.length - 1
			while i >= 0
				@unbindFeature(_features[i])
				i--

		delete @dom
		delete @$dom
		return

	addFeature: (feature) ->
		feature.id ?= cola.uniqueId()
		feature.init?(@)

		if not @features
			@features = [feature]
		else
			@features.push(feature)

		@bindFeature(feature) if not feature.ignoreBind
		return

	removeFeature: (feature) ->
		features = @features
		if features
			i = features.indexOf(feature)
			features.splice(i, 1) if i > -1

			@unbindFeature(feature) if not feature.ignoreBind
		return

	bindFeature: (feature) ->
		return unless feature.processMessage
		paths = feature.paths
		if paths
			@bind(path, feature) for path in paths
		return

	unbindFeature: (feature) ->
		return unless feature.processMessage
		paths = feature.paths
		if paths
			@unbind(path, feature) for path in paths
		return

	bind: (path, feature) ->
		pipe = {
			path: path
			processMessage: (bindingPath, path, type, arg) =>
				if not feature.disabled
					feature.processMessage(@, bindingPath, path, type, arg)
					if feature.disabled then pipe.disabled = true
				else
					pipe.disabled = true
				return
		}
		@scope.data.bind(path, pipe)

		holder = @[feature.id]
		if not holder
			@[feature.id] = [pipe]
		else
			holder.push(pipe)
		return

	unbind: (path, feature) ->
		holder = @[feature.id]
		return unless holder
		for p, i in holder
			if p.path is path
				@scope.data.unbind(path, holder[i])
				holder.splice(i, 1)
				break
		if not holder.length then delete @[feature.id]
		return

	refresh: (force) ->
		if @features
			for f in @features
				f.refresh(@, force)
		return

	clone: (dom, scope) ->
		return new @constructor(dom, scope, @features, true)

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
			cola.util.onNodeDispose(headerNode, _destroyDomBinding)

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
			@scope.data.processMessage("**", path, type, arg)
		return

	refresh: () ->
		return if @isTemplate
		return super()

	remove: () ->
		if !@isTemplate
			@$dom.remove()
		return